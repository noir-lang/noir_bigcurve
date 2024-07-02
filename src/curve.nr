use dep::bignum::ArrayX;
use dep::bignum::BigNum;
use dep::bignum::BigNumParamsTrait;
// use dep::bignum::BigNumParams;
use dep::bignum::U60Repr;

use crate::scalar_field::ScalarField;

use crate::curve_jac::AffineTranscript;

use dep::bignum::BigNumTrait;

/**
 * @brief Implements an elliptic curve instantiated over a prime field that is NOT the circuit's native field
 **/
struct BigCurve<BigNum> {
    x: BigNum,
    y: BigNum
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
struct PointTable<BigNum> {
    x: [BigNum; 16],
    y: [BigNum; 16],
}

impl<BigNum> PointTable<BigNum> where BigNum: BigNumTrait {
    /**
     * @brief Construct a PointTable from an input point and an AffineTranscript that contains required modular inverses
     * (see `CurveJ::mul` for an example of how AffineTranscript objects are generated/used)
     **/
    fn new_with_hint(P: BigCurve<BigNum>, transcript: [AffineTranscript<BigNum>; 8]) -> Self {
        let mut result = PointTable { x: [BigNum::new(); 16], y: [BigNum::new(); 16] };

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
    fn get(self, idx: u8) -> BigCurve<BigNum> {
        BigCurve { x: self.x[idx], y: self.y[idx] }
    }
}

/**
 * @brief are two Affine points equal?
 **/
impl<BigNum> std::cmp::Eq for BigCurve<BigNum> where BigNum: BigNumTrait {
    fn eq(self, other: Self) -> bool {
        std::cmp::Eq::eq(self.x, other.x) & std::cmp::Eq::eq(self.y, other.y)
    }
}

impl<BigNum> BigCurve<BigNum> where BigNum: BigNumTrait {
    /**
    * @brief negate a point
    **/
    fn neg(self) -> Self {
        BigCurve { x: self.x, y: self.y.neg() }
    }
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
    fn incomplete_add_with_hint(self, other: Self, transcript: AffineTranscript<BigNum>) -> Self where {
        let x1: BigNum = self.x;
        let y1: BigNum = self.y;
        let x2: BigNum = other.x;
        let y2: BigNum = other.y;
        let lambda: BigNum = transcript.lambda;
        let x3: BigNum = transcript.x3;
        let y3: BigNum = transcript.y3;

        // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed BigNum objects!
        x3.validate_in_range();
        y3.validate_in_range();
        lambda.validate_in_range();

        // no incomplete Weierstrass shenanigans here
        x1.assert_is_not_equal(x2);

        // validate the provided value of `lambda` is correct
        BigNum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x2, x1]],
            [[false, true]],
            [y2, y1],
            [true, false]
        );

        // validate the provided value of `x3` is correct
        BigNum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[lambda]],
            [[false]],
            [x3, x2, x1],
            [true, true, true]
        );

        // validate the provided value of `y3` is correct
        BigNum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x3, x1]],
            [[false, true]],
            [y3, y1],
            [false, false]
        );

        BigCurve { x: x3, y: y3 }
    }

    fn incomplete_subtract_with_hint(self, other: Self, transcript: AffineTranscript<BigNum>) -> Self where {
        let x1: BigNum = self.x;
        let y1: BigNum = self.y;
        let x2: BigNum = other.x;
        let y2: BigNum = other.y;
        let lambda: BigNum = transcript.lambda;
        let x3: BigNum = transcript.x3;
        let y3: BigNum = transcript.y3;

        // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed BigNum objects!
        x3.validate_in_range();
        y3.validate_in_range();
        lambda.validate_in_range();

        // no incomplete Weierstrass shenanigans here
        x1.assert_is_not_equal(x2);

        // validate the provided value of `lambda` is correct
        BigNum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x2, x1]],
            [[false, true]],
            [y2, y1],
            [false, false]
        );

        // validate the provided value of `x3` is correct
        BigNum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[lambda]],
            [[false]],
            [x3, x2, x1],
            [true, true, true]
        );

        // validate the provided value of `y3` is correct
        BigNum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x3, x1]],
            [[false, true]],
            [y3, y1],
            [false, false]
        );

        BigCurve { x: x3, y: y3 }
    }

    /**
     * @brief Double a point, using an AffineTranscript that contains inverses and output witnesses
     * @note This method minimizes the number of calls to `evalute_quadratic_expression`,
     * which is NOT the same as minimizing the number of multiplications.
     **/
    fn double_with_hint(self, transcript: AffineTranscript<BigNum>) -> Self where {
        let x1: BigNum = self.x;
        let y1: BigNum = self.y;
        let lambda: BigNum = transcript.lambda;
        let x3: BigNum = transcript.x3;
        let y3: BigNum = transcript.y3;

        // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed BigNum objects!
        x3.validate_in_range();
        y3.validate_in_range();
        lambda.validate_in_range();

        // validate the provided value of `lambda` is correct
        BigNum::evaluate_quadratic_expression(
            [[x1, x1, x1], [y1, y1, BigNum::new()]],
            [[false, false, false], [false, false, false]],
            [[x1], [lambda]],
            [[false], [true]],
            [],
            []
        );

        // validate the provided value of `x3` is correct
        BigNum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[lambda]],
            [[false]],
            [x3, x1, x1],
            [true, true, true]
        );

        // validate the provided value of `y3` is correct
        BigNum::evaluate_quadratic_expression(
            [[lambda]],
            [[false]],
            [[x3, x1]],
            [[false, true]],
            [y3, y1],
            [false, false]
        );

        BigCurve { x: x3, y: y3 }
    }

    /**
     * @brief Perform an ecc scalar multiplication, given an [AffineTranscript] generated via unconstrained functions
     **/
    fn mul_with_hint<let NScalarSlices: u32, let NTranscriptSlices: u32>(
        self,
        scalar: ScalarField<NScalarSlices>,
        transcript: [AffineTranscript<BigNum>; NTranscriptSlices]
    ) -> Self {
        // Compute a 4-bit lookup table of multiples of P
        let T: PointTable<BigNum> = PointTable::new_with_hint(
            self,
            [
            transcript[0], transcript[1], transcript[2], transcript[3], transcript[4], transcript[5], transcript[6], transcript[7]
        ]
        );

        // Init the accumulator from the most significant scalar slice
        let mut accumulator = T.get(scalar.base4_slices[0]);

        // Perform the "double and add" algorithm but in steps of 4 bits, using the lookup table T to extract 4-bit multiples of P
        for i in 1..NScalarSlices {
            accumulator = accumulator.double_with_hint(transcript[3 + 5 * i]);
            accumulator = accumulator.double_with_hint(transcript[4 + 5 * i]);
            accumulator = accumulator.double_with_hint(transcript[5 + 5 * i]);
            accumulator = accumulator.double_with_hint(transcript[6 + 5 * i]);
            accumulator = accumulator.incomplete_add_with_hint(T.get(scalar.base4_slices[i]), transcript[7 + 5 * i]);
        }

        // windowed non-adjacent form can only represent odd scalar values.
        // if value is even, the result will be off by one and we need to subtract the input point
        if (scalar.skew) {
            accumulator = accumulator.incomplete_subtract_with_hint(self.neg(), transcript[3 + 5 * NScalarSlices]);
        }

        accumulator
    }
}
