pub mod scalar_field;
pub(crate) mod curve_jac;
mod test_data;
mod bigcurve_test;
pub(crate) mod utils;
pub(crate) mod curves;

use bignum::BigNum;

use crate::curve_jac::AffineTranscript;
use crate::curve_jac::CurveJ;
use crate::scalar_field::ScalarField;
use crate::utils::hash_to_curve::hash_to_curve;

use scalar_field::ScalarFieldTrait;

/**
 * @brief Implements an elliptic curve instantiated over a prime field that is NOT the circuit's native field
 **/
pub struct BigCurve<B, CurveParams> {
    pub x: B,
    pub y: B,
    pub is_infinity: bool,
}

pub trait CurveParamsTrait<B: BigNum> {
    fn offset_generator() -> [B; 2];
    fn offset_generator_final() -> [B; 2];
    fn one() -> [B; 2];
    fn b() -> B;
    fn a() -> B;
}

/**
 * @brief A lookup table we use when performing scalar multiplications.
 * @description We slice scalar multiplier into 4 bit chunks represented
 * in windowed non-adjacent form ([-15, -13, ..., 15])
 * We compute a table of point multiples that map to the 4-bit WNAF values T = ([-15[P], -13[P], ..., 15[P]])
 * We set an accumulator to equal T[most significant WNAF slice]
 * We then iterate over our remaining bit slices (starting with most significant slice)
 * For each iteration `i` we double the accumulator 4 times and then add `T[slice[i]]` into the accumulator.
 * For small multiscalar multiplications (i.e. <512 points) this produces the minimal number of addition operations.
 **/
struct PointTable<B> {
    x: [B; 16],
    y: [B; 16],
}

impl<B: BigNum> PointTable<B> {
    pub(crate) fn empty() -> Self {
        PointTable { x: [B::zero(); 16], y: [B::zero(); 16] }
    }

    /**
     * @brief Construct a PointTable from an input point and an AffineTranscript that contains required modular inverses
     * (see `CurveJ::mul` for an example of how AffineTranscript objects are generated/used)
     **/
    pub(crate) fn new_with_hint<CurveParams>(
        P: BigCurve<B, CurveParams>,
        transcript: [AffineTranscript<B>; 8],
    ) -> Self
    where
        CurveParams: CurveParamsTrait<B>,
    {
        let mut result = PointTable { x: [B::zero(); 16], y: [B::zero(); 16] };

        let D2 = P.double_with_hint(transcript[0]);

        result.x[8] = P.x;
        result.y[8] = P.y;
        result.x[7] = P.x;
        result.y[7] = (P.y.neg());

        let mut A = P;
        for i in 1..8 {
            A = D2.incomplete_add_with_hint(A, transcript[i]);
            result.x[8 + i] = A.x;
            result.y[8 + i] = A.y;
            result.x[7 - i] = A.x;
            result.y[7 - i] = (A.y.neg());
        }
        result
    }

    /**
     * @brief get a value out of the lookup table
     * @description if the backend has an efficient implementation of memory lookups,
     * this will be very efficient (~12 constraints for 256-bit curves using the barretenberg backend)
     **/
    pub(crate) fn get<CurveParams>(self, idx: u32) -> BigCurve<B, CurveParams> {
        BigCurve { x: self.x[idx], y: self.y[idx], is_infinity: false }
    }
}

pub trait BigCurveTrait {
    fn neg(self) -> Self;
    fn point_at_infinity() -> Self;
    fn offset_generator() -> Self;
    fn offset_generator_final() -> Self;
    fn one() -> Self;
    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self;
    fn validate_on_curve(self);
    fn mul<let NScalarSlices: u32>(self, scalar: ScalarField<NScalarSlices>) -> Self;
    fn hash_to_curve<let N: u32>(seed: [u8; N]) -> Self;
}

impl<B, CurveParams> BigCurveTrait for BigCurve<B, CurveParams>
where
    CurveParams: CurveParamsTrait<B>,
    B: BigNum,
{

    fn hash_to_curve<let N: u32>(seed: [u8; N]) -> Self {
        let r = hash_to_curve::<B, N>(seed, CurveParams::a(), CurveParams::b());
        BigCurve { x: r.0, y: r.1, is_infinity: false }
    }

    /**
    * @brief negate a point
    **/
    fn neg(self) -> Self {
        BigCurve { x: self.x, y: self.y.neg(), is_infinity: self.is_infinity }
    }

    fn point_at_infinity() -> Self {
        BigCurve { x: B::zero(), y: B::zero(), is_infinity: true }
    }

    fn offset_generator() -> Self {
        let result = CurveParams::offset_generator();
        Self { x: result[0], y: result[1], is_infinity: false }
    }

    fn offset_generator_final() -> Self {
        let result = CurveParams::offset_generator_final();
        Self { x: result[0], y: result[1], is_infinity: false }
    }

    fn one() -> Self {
        let result = CurveParams::one();
        Self { x: result[0], y: result[1], is_infinity: false }
    }

    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self {
        let x = bignum::bignum::conditional_select(lhs.x, rhs.x, predicate);
        let y = bignum::bignum::conditional_select(lhs.y, rhs.y, predicate);
        let is_infinity = (
            (lhs.is_infinity as Field - rhs.is_infinity as Field) * predicate as Field
                + rhs.is_infinity as Field
        ) as bool;
        BigCurve { x, y, is_infinity }
    }

    fn validate_on_curve(self) {
        // if is point at infinity, we're on the curve.
        // In this case just sub in a valid point for the x/y coordinates we are about to test
        let one: Self = BigCurve::one();
        let x: B = bignum::bignum::conditional_select(one.x, self.x, self.is_infinity);
        let y: B = bignum::bignum::conditional_select(one.y, self.y, self.is_infinity);
        let xx = x.mul(x); // hmm?
        //  xxx - yy + ax + b = 0
        // (xx + a) * x - y*y + b = 0
        // validate the provided value of `y3` is correct
        bignum::bignum::evaluate_quadratic_expression(
            [[xx, CurveParams::a()], [y, B::zero()]],
            [[false, false], [false, false]],
            [[x], [y]],
            [[false], [true]],
            [CurveParams::b()],
            [false],
        );
    }

    /// 64 * 5 = 320
    // Expensive witness generation! Avoid if possible
    pub fn mul<let NScalarSlices: u32>(self, scalar: ScalarField<NScalarSlices>) -> Self {
        let transcript: [AffineTranscript<B>; (NScalarSlices * 5) + 6] =
            unsafe { BigCurve::get_mul_transcript(self, scalar) };

        self.mul_with_hint(scalar, transcript)
    }
}

impl<B, CurveParams> BigCurve<B, CurveParams>
where
    CurveParams: CurveParamsTrait<B>,
    B: BigNum,
{

    /**
     * @brief Add two points together, using an AffineTranscript that contains inverses and output witnesses
     * @description Only uses incomplete formulae.
     * With our use of offset generators, an HONEST PROVER should never need to handle edge cases.
     * Therefore we can sacrifice completeness for cheap soundness. Instead of handling edge cases,
     * we simply assert that they do not exist by validating x2 != x1
     * @note This method minimizes the number of calls to `evaluate_quadratic_expression`,
     * which is NOT the same as minimizing the number of multiplications.
     * The expensive operation in BigNum is the modular reduction.
     * e.g. (a * b + c * d = e mod p) is not much more expensive than (a * b = c mod p)
     **/
    fn incomplete_add_with_hint(self, other: Self, transcript: AffineTranscript<B>) -> Self {
        let x1: B = self.x;
        let y1: B = self.y;
        let x2: B = other.x;
        let y2: B = other.y;
        let lambda: B = transcript.lambda;
        let x3: B = transcript.x3;
        let y3: B = transcript.y3;

        // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed B objects!
        x3.validate_in_range();
        y3.validate_in_range();
        lambda.validate_in_range();

        // no incomplete Weierstrass shenanigans here
        x1.assert_is_not_equal(x2);

        // validate the provided value of `lambda` is correct
        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x2, x1]],
            [[false, true]],
            [y2, y1],
            [true, false],
        );

        // validate the provided value of `x3` is correct
        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[lambda]],
            [[false]],
            [x3, x2, x1],
            [true, true, true],
        );

        // validate the provided value of `y3` is correct
        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x3, x1]],
            [[false, true]],
            [y3, y1],
            [false, false],
        );

        BigCurve { x: x3, y: y3, is_infinity: false }
    }

    fn add_with_hint(self, other: Self, transcript: AffineTranscript<B>) -> Self {
        let mut x1: B = self.x;
        let mut y1: B = self.y;
        let mut x2: B = other.x;
        let mut y2: B = other.y;
        let lambda: B = transcript.lambda;
        let x3: B = transcript.x3;
        let y3: B = transcript.y3;

        // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed B objects!
        x3.validate_in_range();
        y3.validate_in_range();
        lambda.validate_in_range();

        // TODO: we can probably optimize this boolean flag jenga mess
        let x_equal_predicate = x2.eq(x1);
        let y_equal_predicate = y2.eq(y1);
        let double_predicate = x_equal_predicate | (self.is_infinity | other.is_infinity); // if x1 == x2, evaluate double operation. If y1 = -y2 then we set all input/output parameters to be 0
        let infinity_predicate =
            (x_equal_predicate & !y_equal_predicate) | (self.is_infinity & other.is_infinity);
        let evaluate_group_operation_predicate: bool =
            !infinity_predicate & !self.is_infinity & !other.is_infinity;

        // If we are skipping the evaluation of a group operation (x2 == x1, y2 == -y1 OR any input points are at infinity),
        // set input operands to 0!
        x1 = bignum::bignum::conditional_select(x1, B::zero(), evaluate_group_operation_predicate);
        y1 = bignum::bignum::conditional_select(y1, B::zero(), evaluate_group_operation_predicate);
        x2 = bignum::bignum::conditional_select(x2, B::zero(), evaluate_group_operation_predicate);
        y2 = bignum::bignum::conditional_select(y2, B::zero(), evaluate_group_operation_predicate);

        // lambda * 2y - 3x * x = 0
        // or
        // lambda * (x2 - x1) - (y2 - y1) = 0
        let product_1_rhs_t0 = bignum::bignum::conditional_select(y1, x2, double_predicate);
        let product_1_rhs_t1 = bignum::bignum::conditional_select(y1, x1.neg(), double_predicate);
        let product_2_lhs_t0 = bignum::bignum::conditional_select(x1, B::one(), double_predicate);
        let product_2_rhs_t0 = bignum::bignum::conditional_select(x1, y2, double_predicate);
        let product_2_rhs_t1 = bignum::bignum::conditional_select(x1, y1.neg(), double_predicate);
        let product_2_rhs_t2 = bignum::bignum::conditional_select(x1, B::zero(), double_predicate);

        // validate the provided value of `lambda` is correct
        // if double: lambda * (y1 + y1) + x1 * (-x1 -x1 -x1) - a = 0 => lambda * 2y - 3x*x = 0
        // if add:    lambda * (x2 - x1) + 1 * (-y2 + y1) = 0 => lambda * (x2 - x1) - (y2 - y1) = 0
        let mut a_term = bignum::bignum::conditional_select(
            CurveParams::a(),
            B::zero(),
            x_equal_predicate & y_equal_predicate & !self.is_infinity & !other.is_infinity,
        );

        bignum::bignum::evaluate_quadratic_expression(
            [[lambda], [product_2_lhs_t0]],
            [[false], [false]],
            [
                [product_1_rhs_t0, product_1_rhs_t1, B::zero()],
                [product_2_rhs_t0, product_2_rhs_t1, product_2_rhs_t2],
            ],
            [[false, false, false], [true, true, true]],
            [a_term],
            [true],
        );

        // x3 = lambda * lambda - x2 - x1
        // if double, then x2 = x1 so we good
        // TODO(MW): TEMPORARY - some nargo executes in a-p fail if these logs don't exist
        // There is definitely a better solution I haven't thought of
        println("x3");
        println(x3);
        println(lambda * lambda - x2 - x1);
        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[lambda]],
            [[false]],
            [x3, x2, x1],
            [true, true, true],
        );

        // y3 = lambda * (x1 - x3) - y1
        println("y3");
        println(y3);
        println(lambda * (x1 - x3) - y1);
        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x3, x1]],
            [[false, true]],
            [y3, y1],
            [false, false],
        );

        let output_is_lhs = other.is_infinity & !self.is_infinity;
        let output_is_rhs = self.is_infinity & !other.is_infinity;
        let mut x_out =
            bignum::bignum::conditional_select(x3, x1, evaluate_group_operation_predicate);
        x_out = bignum::bignum::conditional_select(self.x, x_out, output_is_lhs);
        x_out = bignum::bignum::conditional_select(other.x, x_out, output_is_rhs);
        x_out = bignum::bignum::conditional_select(B::zero(), x_out, infinity_predicate);
        let mut y_out =
            bignum::bignum::conditional_select(y3, y1, evaluate_group_operation_predicate);
        y_out = bignum::bignum::conditional_select(self.y, y_out, output_is_lhs);
        y_out = bignum::bignum::conditional_select(other.y, y_out, output_is_rhs);
        y_out = bignum::bignum::conditional_select(B::zero(), y_out, infinity_predicate);

        let conditional_select = |a: bool, b: bool, predicate: bool| {
            ((a as Field - b as Field) * predicate as Field + b as Field) as bool
        };

        let mut infinity_out = conditional_select(false, true, evaluate_group_operation_predicate);
        infinity_out = conditional_select(true, infinity_out, infinity_predicate);
        infinity_out = conditional_select(self.is_infinity, infinity_out, output_is_lhs);
        infinity_out = conditional_select(other.is_infinity, infinity_out, output_is_rhs);

        let result: Self = BigCurve { x: x_out, y: y_out, is_infinity: infinity_out };
        result
    }

    fn sub_with_hint(self, other: Self, transcript: AffineTranscript<B>) -> Self {
        let mut x1: B = self.x;
        let mut y1: B = self.y;
        let mut x2: B = other.x;
        let mut y2: B = other.y;
        let lambda: B = transcript.lambda;
        let x3: B = transcript.x3;
        let y3: B = transcript.y3;

        // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed B objects!
        x3.validate_in_range();
        y3.validate_in_range();
        lambda.validate_in_range();

        let x_equal_predicate = x2.eq(x1);
        let y_equal_predicate = y2.eq(y1) == false;
        let double_predicate = x_equal_predicate | (self.is_infinity | other.is_infinity); // if x1 == x2, evaluate double operation. If y1 = -y2 then we set all input/output parameters to be 0
        let infinity_predicate: bool =
            (x_equal_predicate & !y_equal_predicate) | (self.is_infinity & other.is_infinity);
        let evaluate_group_operation_predicate: bool =
            !infinity_predicate & !self.is_infinity & !other.is_infinity;
        // If we are skipping the evaluation of a group operation (x2 == x1, y2 == -y1 OR any input points are at infinity),
        // set input operands to 0!
        x1 = bignum::bignum::conditional_select(x1, B::zero(), evaluate_group_operation_predicate);
        y1 = bignum::bignum::conditional_select(y1, B::zero(), evaluate_group_operation_predicate);
        x2 = bignum::bignum::conditional_select(x2, B::zero(), evaluate_group_operation_predicate);
        y2 = bignum::bignum::conditional_select(y2, B::zero(), evaluate_group_operation_predicate);

        // lambda * 2y - 3x*x = 0
        // 3 x * x - lambda * 2y
        // lambda * (x2 - x1) - (y2 - y1) = 0
        // y1 - (y2.neg()) - lambda * (x1 - x2) = 0
        // y1 + y2 - lambda * (x1 - x2) = 0
        // 3 * x * x - lambda * 2 * y
        let product_1_rhs_t0 = bignum::bignum::conditional_select(y1, x2.neg(), double_predicate);
        let product_1_rhs_t1 = bignum::bignum::conditional_select(y1, x1, double_predicate);
        let product_2_lhs_t0 = bignum::bignum::conditional_select(x1, B::one(), double_predicate);
        let product_2_rhs_t0 = bignum::bignum::conditional_select(x1, y2, double_predicate);
        let product_2_rhs_t1 = bignum::bignum::conditional_select(x1, y1, double_predicate);
        let product_2_rhs_t2 = bignum::bignum::conditional_select(x1, B::zero(), double_predicate);

        // validate the provided value of `lambda` is correct
        // if double: -lambda * (y1 + y1) + x1 * (x1 x1 x1) + a= 0 => lambda * 2y - 3x*x = 0
        // if add:    -lambda * (x1 - x2) + 1 * (y2 + y1) = 0 => lambda * (x2 - x1) - (-y2 - y1) = 0
        let mut a_term = bignum::bignum::conditional_select(
            CurveParams::a(),
            B::zero(),
            x_equal_predicate & y_equal_predicate & !self.is_infinity & !other.is_infinity,
        );

        bignum::bignum::evaluate_quadratic_expression(
            [[lambda], [product_2_lhs_t0]],
            [[true], [false]],
            [
                [product_1_rhs_t0, product_1_rhs_t1, B::zero()],
                [product_2_rhs_t0, product_2_rhs_t1, product_2_rhs_t2],
            ],
            [[false, false, false], [false, false, false]],
            [a_term],
            [false],
        );

        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[lambda]],
            [[false]],
            [x3, x2, x1],
            [true, true, true],
        );

        // y3 = lambda * (x1 - x3) - y1
        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x3, x1]],
            [[false, true]],
            [y3, y1],
            [false, false],
        );

        let output_is_lhs = other.is_infinity & !self.is_infinity;
        let output_is_rhs = self.is_infinity & !other.is_infinity;
        let mut x_out =
            bignum::bignum::conditional_select(x3, x1, evaluate_group_operation_predicate);
        x_out = bignum::bignum::conditional_select(self.x, x_out, output_is_lhs);
        x_out = bignum::bignum::conditional_select(other.x, x_out, output_is_rhs);
        x_out = bignum::bignum::conditional_select(B::zero(), x_out, infinity_predicate);
        let mut y_out =
            bignum::bignum::conditional_select(y3, y1, evaluate_group_operation_predicate);
        y_out = bignum::bignum::conditional_select(self.y, y_out, output_is_lhs);
        y_out = bignum::bignum::conditional_select(other.y.neg(), y_out, output_is_rhs);
        y_out = bignum::bignum::conditional_select(B::zero(), y_out, infinity_predicate);

        let conditional_select = |a: bool, b: bool, predicate: bool| {
            ((a as Field - b as Field) * predicate as Field + b as Field) as bool
        };

        let mut infinity_out = conditional_select(false, true, evaluate_group_operation_predicate);
        infinity_out = conditional_select(true, infinity_out, infinity_predicate);
        infinity_out = conditional_select(self.is_infinity, infinity_out, output_is_lhs);
        infinity_out = conditional_select(other.is_infinity, infinity_out, output_is_rhs);

        let result: Self = BigCurve { x: x_out, y: y_out, is_infinity: infinity_out };
        result
    }

    fn incomplete_subtract_with_hint(self, other: Self, transcript: AffineTranscript<B>) -> Self {
        let x1: B = self.x;
        let y1: B = self.y;
        let x2: B = other.x;
        let y2: B = other.y;
        let lambda: B = transcript.lambda;
        let x3: B = transcript.x3;
        let y3: B = transcript.y3;

        // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed BigNum objects!
        x3.validate_in_range();
        y3.validate_in_range();
        lambda.validate_in_range();

        // no incomplete Weierstrass shenanigans here
        x1.assert_is_not_equal(x2);

        // validate the provided value of `lambda` is correct
        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x2, x1]],
            [[false, true]],
            [y2, y1],
            [false, false],
        );

        // validate the provided value of `x3` is correct
        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[lambda]],
            [[false]],
            [x3, x2, x1],
            [true, true, true],
        );

        // validate the provided value of `y3` is correct
        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x3, x1]],
            [[false, true]],
            [y3, y1],
            [false, false],
        );

        BigCurve { x: x3, y: y3, is_infinity: false }
    }

    fn conditional_incomplete_add_with_hint(
        self,
        other: Self,
        predicate: bool,
        transcript: AffineTranscript<B>,
    ) -> Self {
        let operand_output = self.incomplete_add_with_hint(other, transcript);
        let result = BigCurve::conditional_select(operand_output, self, predicate);
        result
    }

    fn conditional_incomplete_subtract_with_hint(
        self,
        other: Self,
        predicate: bool,
        transcript: AffineTranscript<B>,
    ) -> Self {
        let operand_output = self.incomplete_subtract_with_hint(other, transcript);
        let result = BigCurve::conditional_select(operand_output, self, predicate);
        result
    }

    /**
     * @brief Double a point, using an AffineTranscript that contains inverses and output witnesses
     * @note This method minimizes the number of calls to `evalute_quadratic_expression`,
     * which is NOT the same as minimizing the number of multiplications.
     **/
    fn double_with_hint(self, transcript: AffineTranscript<B>) -> Self {
        let x1: B = self.x;
        let y1: B = self.y;
        let lambda: B = transcript.lambda;
        let x3: B = transcript.x3;
        let y3: B = transcript.y3;

        // TODO: HANDLE CURVES WHERE A != 0
        // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed B objects!
        x3.validate_in_range();
        y3.validate_in_range();
        lambda.validate_in_range();

        // -lambda * 2y + 3*x*x + a = 0
        // validate the provided value of `lambda` is correct
        // n.b. if CurveParams::a() == 0, its inclusion shouldn't cost extra constraints...I thnk
        bignum::bignum::evaluate_quadratic_expression(
            [[x1, x1, x1], [y1, y1, B::zero()]],
            [[false, false, false], [false, false, false]],
            [[x1], [lambda]],
            [[false], [true]],
            [CurveParams::a()],
            [false],
        );

        // validate the provided value of `x3` is correct
        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[lambda]],
            [[false]],
            [x3, x1, x1],
            [true, true, true],
        );

        // validate the provided value of `y3` is correct
        bignum::bignum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x3, x1]],
            [[false, true]],
            [y3, y1],
            [false, false],
        );

        BigCurve { x: x3, y: y3, is_infinity: false }
    }

    /**
     * @brief Perform an ecc scalar multiplication, given an [AffineTranscript] generated via unconstrained functions
     **/
    fn mul_with_hint<let NScalarSlices: u32, let NTranscriptSlices: u32>(
        self,
        scalar: ScalarField<NScalarSlices>,
        transcript: [AffineTranscript<B>; NTranscriptSlices],
    ) -> Self {
        // Compute a 4-bit lookup table of multiples of P
        let input: Self = BigCurve::conditional_select(BigCurve::one(), self, self.is_infinity);
        let scalar: ScalarField<NScalarSlices> =
            ScalarField::conditional_select(ScalarField::zero(), scalar, self.is_infinity);

        let T: PointTable<B> = PointTable::new_with_hint(
            input,
            [
                transcript[0],
                transcript[1],
                transcript[2],
                transcript[3],
                transcript[4],
                transcript[5],
                transcript[6],
                transcript[7],
            ],
        );

        // Init the accumulator from the most significant scalar slice
        let mut accumulator: Self = BigCurve::offset_generator();
        let mut accumulator = accumulator.incomplete_add_with_hint(
            T.get(scalar.base4_slices[0] as u32),
            transcript[3 + 5],
        );

        // Perform the "double and add" algorithm but in steps of 4 bits, using the lookup table T to extract 4-bit multiples of P
        for i in 1..NScalarSlices {
            accumulator = accumulator.double_with_hint(transcript[4 + 5 * i]);
            accumulator = accumulator.double_with_hint(transcript[5 + 5 * i]);
            accumulator = accumulator.double_with_hint(transcript[6 + 5 * i]);
            accumulator = accumulator.double_with_hint(transcript[7 + 5 * i]);
            accumulator = accumulator.incomplete_add_with_hint(
                T.get(scalar.base4_slices[i] as u32),
                transcript[8 + 5 * i],
            );
        }

        // windowed non-adjacent form can only represent odd scalar values.
        // if value is even, the result will be off by one and we need to subtract the input point
        accumulator = accumulator.conditional_incomplete_subtract_with_hint(
            input,
            scalar.skew,
            transcript[4 + 5 * NScalarSlices],
        );

        accumulator = accumulator.sub_with_hint(
            BigCurve::offset_generator_final(),
            transcript[5 + 5 * NScalarSlices],
        );
        accumulator
    }

    // TODO: offset generators
    //       conditional subtract, conditional add
    //
    /**
     * @brief Perform an ecc scalar multiplication, given an [AffineTranscript] generated via unconstrained functions
     **/
    fn msm_with_hint_internal<let Size: u32, let NScalarSlices: u32, let NTranscriptSlices: u32>(
        mut points: [Self; Size],
        mut scalars: [ScalarField<NScalarSlices>; Size],
        transcript: [AffineTranscript<B>; NTranscriptSlices],
    ) -> Self {
        // Compute a 4-bit lookup table of multiples of P
        let mut _inputs: [Self; Size] = [BigCurve::one(); Size];
        let mut _scalars: [ScalarField<NScalarSlices>; Size] = [ScalarField::zero(); Size];
        for i in 0..Size {
            _inputs[i] =
                BigCurve::conditional_select(BigCurve::one(), points[i], points[i].is_infinity);
            _scalars[i] = ScalarField::conditional_select(
                ScalarField::zero(),
                scalars[i],
                points[i].is_infinity,
            );
        }
        points = _inputs;
        scalars = _scalars;

        let mut tables: [PointTable<B>; Size] = [PointTable::empty(); Size];
        for i in 0..Size {
            let mut table_transcript: [AffineTranscript<B>; 8] = [AffineTranscript::new(); 8];
            for j in 0..8 {
                table_transcript[j] = transcript[i * 8 + j];
            }
            tables[i] = PointTable::new_with_hint(points[i], table_transcript);
        }

        // Init the accumulator from the most significant scalar slice
        let mut accumulator: Self = BigCurve::offset_generator();
        let mut accumulator = accumulator.incomplete_add_with_hint(
            tables[0].get(scalars[0].base4_slices[0] as u32),
            transcript[8 * Size],
        );

        for i in 1..Size {
            accumulator = accumulator.incomplete_add_with_hint(
                tables[i].get(scalars[i].base4_slices[0] as u32),
                transcript[8 * Size + i],
            );
        }

        // Perform the "double and add" algorithm but in steps of 4 bits, using the lookup table T to extract 4-bit multiples of P
        for i in 1..NScalarSlices {
            accumulator = accumulator.double_with_hint(transcript[9 * Size + (4 + Size) * (i - 1)]);
            accumulator =
                accumulator.double_with_hint(transcript[9 * Size + (4 + Size) * (i - 1) + 1]);
            accumulator =
                accumulator.double_with_hint(transcript[9 * Size + (4 + Size) * (i - 1) + 2]);
            accumulator =
                accumulator.double_with_hint(transcript[9 * Size + (4 + Size) * (i - 1) + 3]);

            for j in 0..Size {
                accumulator = accumulator.incomplete_add_with_hint(
                    tables[j].get(scalars[j].base4_slices[i] as u32),
                    transcript[9 * Size + (4 + Size) * (i - 1) + 4 + j],
                );
            }
        }

        // 9 * Size + (4 + Size) * (NScalarSlices - 1) - 1
        // 9 + 5 * NScalarSlices - 6
        // windowed non-adjacent form can only represent odd scalar values.
        // if value is even, the result will be off by one and we need to subtract the input point
        for i in 0..Size {
            accumulator = accumulator.conditional_incomplete_subtract_with_hint(
                points[i],
                scalars[i].skew,
                transcript[9 * Size + (4 + Size) * (NScalarSlices - 1) + i],
            );
        }

        accumulator
    }

    fn msm_with_hint<let Size: u32, let NScalarSlices: u32, let NTranscriptSlices: u32>(
        mut points: [Self; Size],
        mut scalars: [ScalarField<NScalarSlices>; Size],
        transcript: [AffineTranscript<B>; NTranscriptSlices],
    ) -> Self {
        let mut accumulator = BigCurve::msm_with_hint_internal(points, scalars, transcript);
        accumulator = accumulator.sub_with_hint(
            BigCurve::offset_generator_final(),
            transcript[10 * Size + (4 + Size) * (NScalarSlices - 1)],
        );
        accumulator
    }

    unconstrained fn get_mul_transcript<let NScalarSlices: u32>(
        P: Self,
        scalar: ScalarField<NScalarSlices>,
    ) -> [AffineTranscript<B>; 6 + NScalarSlices * 5] {
        CurveJ::from(P).mul(scalar).1
    }

    pub fn msm<let NScalarSlices: u32, let NMuls: u32>(
        mul_points: [Self; NMuls],
        mul_scalars: [ScalarField<NScalarSlices>; NMuls],
    ) -> Self {
        BigCurve::evaluate_linear_expression(mul_points, mul_scalars, [])
    }

    pub fn evaluate_linear_expression<let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>(
        mul_points: [Self; NMuls],
        mul_scalars: [ScalarField<NScalarSlices>; NMuls],
        add_points: [Self; NAdds],
    ) -> Self {
        let transcript: [AffineTranscript<B>; NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 + NAdds - 3] = unsafe {
            CurveJ::compute_linear_expression_transcript(mul_points, mul_scalars, add_points).1
        };
        let mut _inputs: [Self; NMuls] = [BigCurve::one(); NMuls];
        let mut _scalars: [ScalarField<NScalarSlices>; NMuls] = [ScalarField::zero(); NMuls];
        for i in 0..NMuls {
            _inputs[i] = BigCurve::conditional_select(
                BigCurve::one(),
                mul_points[i],
                mul_points[i].is_infinity,
            );
            _scalars[i] = ScalarField::conditional_select(
                ScalarField::zero(),
                mul_scalars[i],
                mul_points[i].is_infinity,
            );
        }
        let msm_points = _inputs;
        let scalars = _scalars;

        let mut tables: [PointTable<B>; NMuls] = [PointTable::empty(); NMuls];
        for i in 0..NMuls {
            let mut table_transcript: [AffineTranscript<B>; 8] = [AffineTranscript::new(); 8];
            for j in 0..8 {
                table_transcript[j] = transcript[i * 8 + j];
            }
            tables[i] = PointTable::new_with_hint(msm_points[i], table_transcript);
        }

        // Init the accumulator from the most significant scalar slice
        let mut accumulator: Self = BigCurve::offset_generator();
        let mut accumulator = accumulator.incomplete_add_with_hint(
            tables[0].get(scalars[0].base4_slices[0] as u32),
            transcript[8 * NMuls],
        );
        for i in 1..NMuls {
            accumulator = accumulator.incomplete_add_with_hint(
                tables[i].get(scalars[i].base4_slices[0] as u32),
                transcript[8 * NMuls + i],
            );
        }

        // Perform the "double and add" algorithm but in steps of 4 bits, using the lookup table T to extract 4-bit multiples of P
        for i in 1..NScalarSlices {
            accumulator =
                accumulator.double_with_hint(transcript[9 * NMuls + (4 + NMuls) * (i - 1)]);
            accumulator =
                accumulator.double_with_hint(transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 1]);
            accumulator =
                accumulator.double_with_hint(transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 2]);
            accumulator =
                accumulator.double_with_hint(transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 3]);
            for j in 0..NMuls {
                accumulator = accumulator.incomplete_add_with_hint(
                    tables[j].get(scalars[j].base4_slices[i] as u32),
                    transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 4 + j],
                );
            }
        }

        // 9 * Size + (4 + Size) * (NScalarSlices - 1) - 1
        // 9 + 5 * NScalarSlices - 6
        // windowed non-adjacent form can only represent odd scalar values.
        // if value is even, the result will be off by one and we need to subtract the input point
        for i in 0..NMuls {
            accumulator = accumulator.conditional_incomplete_subtract_with_hint(
                msm_points[i],
                scalars[i].skew,
                transcript[9 * NMuls + (4 + NMuls) * (NScalarSlices - 1) + i],
            );
        }

        for i in 0..NAdds {
            accumulator = accumulator.conditional_incomplete_add_with_hint(
                add_points[i],
                !add_points[i].is_infinity,
                transcript[10 * NMuls + (4 + NMuls) * (NScalarSlices - 1) + i],
            );
        }

        accumulator = accumulator.sub_with_hint(
            BigCurve::offset_generator_final(),
            transcript[NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 + NAdds - 4],
        );

        accumulator
    }
}

impl<B, CurveParams> std::ops::Add for BigCurve<B, CurveParams>
where
    CurveParams: CurveParamsTrait<B>,
    B: BigNum,
{
    // Expensive witness generation! Avoid if possible
    fn add(self, other: Self) -> Self {
        let lhsJ = CurveJ::from(self);
        let rhsJ = CurveJ::from(other);

        let transcript = unsafe { AffineTranscript::from_j(lhsJ.add(rhsJ).1) };

        self.add_with_hint(other, transcript)
    }
}

impl<B, CurveParams> std::ops::Sub for BigCurve<B, CurveParams>
where
    CurveParams: CurveParamsTrait<B>,
    B: BigNum,
{
    // Expensive witness generation! Avoid if possible
    fn sub(self, other: Self) -> Self {
        let lhsJ = CurveJ::from(self);
        let rhsJ = CurveJ::from(other);

        let transcript = unsafe { AffineTranscript::from_j(lhsJ.sub(rhsJ).1) };

        self.sub_with_hint(other, transcript)
    }
}

/**
 * @brief are two Affine points equal?
 **/
impl<B, CurveParams> std::cmp::Eq for BigCurve<B, CurveParams>
where
    B: BigNum,
{
    fn eq(self, other: Self) -> bool {
        let coords_equal =
            self.x.eq(other.x) & self.y.eq(other.y) & !self.is_infinity & !other.is_infinity;
        let infinity = self.is_infinity & other.is_infinity;
        coords_equal | infinity
    }
}
