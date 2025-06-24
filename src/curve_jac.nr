use bignum::BigNum;

use crate::scalar_field::ScalarField;
use super::BigCurve;

/// CurveJ represents a Short Weierstrass elliptic curve using Jacobian coordinates.
///
/// # Representation
/// - **Jacobian form:** (X, Y, Z)
/// - **Affine form:** (x, y)
/// - **Relation:** x = X / Z^2, y = Y / Z^3
///
/// # Purpose
/// This class is designed to speed up witness generation when optimally constraining elliptic curve operations.
///
/// # Motivation
/// - Constraints are best constructed in affine coordinates due to fewer field multiplications (3 vs ~14 for Jacobian).
/// - However, affine coordinates require one modular inverse per group operation, which is expensive over a non-native field (~2D multiplications, where D is the field bit-width).
///
/// # Solution
/// - Perform all computations in unconstrained functions using Jacobian coordinates (no inverses required).
/// - Record each ECC operation in a `JTranscript` object.
/// - Use a Montgomery Batch Inverse to compute all required inverses at once when evaluating with affine arithmetic.
/// - This reduces the number of modular inverses from ~256 or 320 (depending on the curve) to just one.
///
/// # Note
/// This approach is complex but necessary due to the high cost of generating modular inverses for witness generation.
pub struct CurveJ<B, BigCurve> {
    pub(crate) x: B,
    pub(crate) y: B,
    pub(crate) z: B,
    pub(crate) is_infinity: bool,
}

/// A transcript of a group operation in Jacobian coordinates.
///
/// # Fields
/// - `x3`, `y3`, `z3`: The output coordinates of the group operation in Jacobian form.
/// - `lambda_numerator`: The numerator of the `lambda` term used in the group operation.
///   (The denominator is assumed to be `z3`.)
pub struct JTranscript<B> {
    pub(crate) lambda_numerator: B,
    pub(crate) x3: B,
    pub(crate) y3: B,
    pub(crate) z3: B,
}

impl<B> JTranscript<B>
where
    B: BigNum,
{
    unconstrained fn new() -> Self {
        JTranscript { lambda_numerator: B::zero(), x3: B::zero(), y3: B::zero(), z3: B::zero() }
    }
}

/// A transcript of a group operation in Affine coordinates.
///
/// # Fields
/// - `x3`, `y3`: The output coordinates of the group operation.
/// - `lambda`: The gradient of the line that passes through the input points of the group operation.
///
/// # Details
/// - For addition: `lambda = (y2 - y1) / (x2 - x1)`
/// - For doubling: `lambda = (3 * x1 * x1) / (2 * y1)`
///
/// # Optimization
/// If you have an array of `JTranscript` objects, you can convert them into `AffineTranscript` objects using only one modular inverse.
pub struct AffineTranscript<B> {
    pub(crate) lambda: B,
    pub(crate) x3: B,
    pub(crate) y3: B,
}

impl<B> AffineTranscript<B>
where
    B: BigNum,
{
    pub(crate) fn new() -> Self {
        AffineTranscript { lambda: B::zero(), x3: B::zero(), y3: B::zero() }
    }

    pub(crate) unconstrained fn from_j(j_tx: JTranscript<B>) -> Self {
        AffineTranscript::from_jacobian_transcript([j_tx])[0]
    }

    pub unconstrained fn from_j_with_hint(j_tx: JTranscript<B>, inverse: B) -> AffineTranscript<B> {
        let z_inv = inverse;
        let zz = z_inv.__mul(z_inv);
        let zzz = zz.__mul(z_inv);
        let lambda = j_tx.lambda_numerator.__mul(z_inv);
        let x3 = j_tx.x3.__mul(zz);
        let y3 = j_tx.y3.__mul(zzz);
        AffineTranscript { x3, y3, lambda }
    }

    unconstrained fn from_jacobian_transcript<let NumEntries: u32>(
        j_tx: [JTranscript<B>; NumEntries],
    ) -> [AffineTranscript<B>; NumEntries] {
        let mut result: [AffineTranscript<B>; NumEntries] = [AffineTranscript::new(); NumEntries];

        let mut inverses: [B; NumEntries] = [B::zero(); NumEntries];
        for i in 0..j_tx.len() {
            inverses[i] = j_tx[i].z3;
        }

        // tadaa
        let inverses: [B; NumEntries] = bignum::bignum::batch_invert(inverses);

        for i in 0..j_tx.len() {
            let z_inv = inverses[i];
            let zz = z_inv.__mul(z_inv);
            let zzz = zz.__mul(z_inv);
            let lambda = j_tx[i].lambda_numerator.__mul(z_inv);
            let x3 = j_tx[i].x3.__mul(zz);
            let y3 = j_tx[i].y3.__mul(zzz);
            result[i] = AffineTranscript { lambda, x3, y3 };
        }
        result
    }
}

/// A lookup table used for scalar multiplications using windowed non-adjacent form (WNAF).
///
/// The scalar multiplier is sliced into 4-bit chunks, each represented in WNAF (values in the range [-15, -13, ..., 15]).
/// A table `T` is computed containing point multiples corresponding to these 4-bit WNAF values: `T = ([-15[P], -13[P], ..., 15[P]])`.
///
/// The accumulator is initialized with `T[most significant WNAF slice]`.
/// For each remaining slice (starting from the most significant), the accumulator is doubled 4 times,
/// then `T[slice[i]]` is added to the accumulator.
///
/// For small multiscalar multiplications (fewer than 512 points), this approach minimizes the number of addition operations.
pub struct PointTable<B> {
    x: [B; 16],
    y: [B; 16],
    z: [B; 16],
    pub(crate) transcript: [JTranscript<B>; 8],
}

impl<B> PointTable<B>
where
    B: BigNum,
{
    pub(crate) fn empty() -> Self {
        PointTable {
            x: [B::zero(); 16],
            y: [B::zero(); 16],
            z: [B::zero(); 16],
            transcript: [unsafe { JTranscript::new() }; 8],
        }
    }
    /**
     * @brief make a new PointTable from an input point
     * @description we use "windowed non-adjacent form" representation 
     * to reduce the number of group operations required for the table
     * [-15P, -13P, ..., 15P] requires 8 group operations
     * [0, P, ..., 15P] requires 14 group operations.
     * group operations are expensive!
     **/
    pub(crate) unconstrained fn new<Curve>(P: CurveJ<B, Curve>) -> Self
    where
        Curve: BigCurve<B>,
    {
        let mut result = PointTable {
            x: [B::zero(); 16],
            y: [B::zero(); 16],
            z: [B::zero(); 16],
            transcript: [JTranscript::new(); 8],
        };
        let op = P.dbl();
        let D2 = op.0;

        result.transcript[0] = op.1;
        result.x[7] = P.x;
        result.y[7] = P.y.__neg();
        result.z[7] = P.z;
        result.x[8] = P.x;
        result.y[8] = P.y;
        result.z[8] = P.z;
        let mut A = P;
        for i in 1..8 {
            let op = D2.incomplete_add(A);
            A = op.0;
            result.transcript[i] = op.1;
            result.x[8 + i] = A.x;
            result.y[8 + i] = A.y;
            result.z[8 + i] = A.z;
            result.x[7 - i] = A.x;
            result.y[7 - i] = A.y.__neg();
            result.z[7 - i] = A.z;
        }

        result
    }

    /**
     * @brief get a value out of the lookup table
     **/
    pub(crate) unconstrained fn get<BigCurve>(self, idx: u32) -> CurveJ<B, BigCurve> {
        CurveJ { x: self.x[idx], y: self.y[idx], z: self.z[idx], is_infinity: false }
    }
}

/**
 * @brief construct from BigCurve
 **/
impl<B, P> std::convert::From<P> for CurveJ<B, P>
where
    B: BigNum,
    P: BigCurve<B>,
{
    fn from(affine_point: P) -> Self {
        CurveJ {
            x: affine_point.x(),
            y: affine_point.y(),
            z: B::one(),
            is_infinity: affine_point.is_infinity(),
        }
    }
}

/**
 * @brief are two Jacobian points equal?
 * @description only really used in tests for now.
 **/
impl<B, BigCurve> std::cmp::Eq for CurveJ<B, BigCurve>
where
    B: BigNum,
    BigCurve: BigCurve<B>,
{
    fn eq(self, other: Self) -> bool {
        // if x == y then (X1 / Z1 * Z1 = X2 / Z2 * Z2)
        //            and (Y1 / Z1 * Z1 * Z1 = Y2 / Z2 * Z2 * Z2)
        let mut points_equal = false;
        unsafe {
            // we can check this by validating that:
            // X1 * Z2 * Z2 == X2 * Z1 * Z1
            // Y1 * Z2 * Z2 * Z2 == Y2 * Z1 * Z1 * Z1
            let z1 = self.z;
            let z2 = other.z;
            let z1z1 = z1.__mul(z1);
            let z1z1z1 = z1z1.__mul(z1);
            let z2z2 = z2.__mul(z2);
            let z2z2z2 = z2z2.__mul(z2);

            let x_lhs = self.x.__mul(z2z2);
            let x_rhs = other.x.__mul(z1z1);
            let y_lhs = self.y.__mul(z2z2z2);
            let y_rhs = other.y.__mul(z1z1z1);
            let lhs_infinity = self.is_infinity;
            let rhs_infinity = other.is_infinity;
            let both_not_infinity = !(lhs_infinity & rhs_infinity);
            let both_infinity = !both_not_infinity;

            points_equal = (x_lhs.eq(x_rhs) & y_lhs.eq(y_rhs)) & both_not_infinity;
            points_equal = points_equal | both_infinity;
        }
        points_equal
    }
}

impl<B, Curve> CurveJ<B, Curve>
where
    B: BigNum,
    Curve: BigCurve<B>,
{
    /**
     * @brief negate a point
     **/
    pub(crate) fn neg(self) -> Self {
        CurveJ { x: self.x, y: self.y.neg(), z: self.z, is_infinity: self.is_infinity }
    }

    pub(crate) unconstrained fn new() -> Self {
        CurveJ { x: B::zero(), y: B::zero(), z: B::zero(), is_infinity: false }
    }

    pub(crate) unconstrained fn point_at_infinity() -> Self {
        CurveJ { x: B::zero(), y: B::zero(), z: B::zero(), is_infinity: true }
    }

    pub(crate) unconstrained fn sub(self, p2: Self) -> (Self, JTranscript<B>) {
        self.add(p2.neg())
    }

    pub(crate) unconstrained fn add(self, p2: Self) -> (Self, JTranscript<B>) {
        let X1 = self.x;
        let X2 = p2.x;
        let Y1 = self.y;
        let Y2 = p2.y;
        let Z1 = self.z;
        let Z2 = p2.z;
        let Z2Z2 = Z2.__mul(Z2);
        let Z1Z1 = Z1.__mul(Z1);
        let Z2Z2Z2 = Z2Z2.__mul(Z2);
        let Z1Z1Z1 = Z1Z1.__mul(Z1);
        let U1 = X1.__mul(Z2Z2);
        let U2 = X2.__mul(Z1Z1);
        let S1 = Y1.__mul(Z2Z2Z2);
        let S2 = Y2.__mul(Z1Z1Z1);
        // let R = S2.__submod(S1);
        // x1*z2*z2 == x2*z1*z1 => U2 == U2
        let x_equal_predicate = U2.eq(U1);
        let y_equal_predicate = S2.eq(S1);
        let lhs_infinity = self.is_infinity;
        let rhs_infinity = p2.is_infinity;
        let double_predicate =
            x_equal_predicate & y_equal_predicate & !lhs_infinity & !rhs_infinity;
        let add_predicate = !x_equal_predicate & !lhs_infinity & !rhs_infinity;
        let infinity_predicate =
            (x_equal_predicate & !y_equal_predicate) | (lhs_infinity & rhs_infinity);
        let mut result: (Self, JTranscript<B>) = (CurveJ::new(), JTranscript::new());
        if (double_predicate) {
            result = self.dbl();
        } else if (add_predicate) {
            result = self.incomplete_add(p2);
        } else if (infinity_predicate) {
            result = (CurveJ::point_at_infinity(), JTranscript::new());
        } else if (lhs_infinity & !rhs_infinity) {
            result = (p2, JTranscript::new());
        } else if (rhs_infinity & !lhs_infinity) {
            result = (self, JTranscript::new());
        }
        result
        // let (_, PP): (B, B ) = B::compute_quadratic_expression([[U2, U1]], [[false, true]], [[U2, U1]], [[false, true]], [], []);
        // let (_, X3): (B, B ) = B::compute_quadratic_expression(
        //     [[B::zero(), PP], [R, B::zero()]],
        //     [[false, true], [false, false]],
        //     [[U1, U2], [R, B::zero()]],
        //     [[false, false], [false, false]],
        //     [],
        //     []
        // );
        // let (_, U1S2_minus_U2S1): (B, B ) = B::compute_quadratic_expression(
        //     [[U1], [U2]],
        //     [[false], [true]],
        //     [[S2], [S1]],
        //     [[false], [false]],
        //     [],
        //     []
        // );
        // let (_, Y3): (B, B ) = B::compute_quadratic_expression(
        //     [[PP], [X3]],
        //     [[false], [false]],
        //     [[U1S2_minus_U2S1], [R]],
        //     [[false], [true]],
        //     [],
        //     []
        // );
        // let Z1Z2 = Z1.__mulmod(Z2);
        // let (_, Z3): (B, B ) = B::compute_quadratic_expression(
        //     [[Z1Z2, B::zero()]],
        //     [[false, false]],
        //     [[U2, U1]],
        //     [[false, true]],
        //     [],
        //     []
        // );
        // (
        //     CurveJ { x: X3, y: Y3, z: Z3, is_infinity: false }, JTranscript { lambda_numerator: R, x3: X3, y3: Y3, z3: Z3 }
        // )
    }

    /**
     * @brief Add two points together.
     * @description Only uses incomplete formulae.
     * With our use of offset generators, we should never need to handle edge cases.
     * (when constraining operations, we simply assert the input x-coordinates are not equal)
     * @note This method minimizes the number of calls to `compute_quadratic_expression`,
     * which is NOT the same as minimizing the number of multiplications.
     **/
    pub(crate) unconstrained fn incomplete_add(self, p2: Self) -> (Self, JTranscript<B>) {
        let X1 = self.x;
        let X2 = p2.x;
        let Y1 = self.y;
        let Y2 = p2.y;
        let Z1 = self.z;
        let Z2 = p2.z;
        let Z2Z2 = Z2.__mul(Z2);
        let Z1Z1 = Z1.__mul(Z1);
        let Z2Z2Z2 = Z2Z2.__mul(Z2);
        let Z1Z1Z1 = Z1Z1.__mul(Z1);
        let U1 = X1.__mul(Z2Z2);
        let U2 = X2.__mul(Z1Z1);
        let S1 = Y1.__mul(Z2Z2Z2);
        let S2 = Y2.__mul(Z1Z1Z1);
        let R = S2.__sub(S1);

        let (_, PP): (B, B) = bignum::bignum::compute_quadratic_expression(
            [[U2, U1]],
            [[false, true]],
            [[U2, U1]],
            [[false, true]],
            [],
            [],
        );
        let (_, X3): (B, B) = bignum::bignum::compute_quadratic_expression(
            [[B::zero(), PP], [R, B::zero()]],
            [[false, true], [false, false]],
            [[U1, U2], [R, B::zero()]],
            [[false, false], [false, false]],
            [],
            [],
        );

        let (_, U1S2_minus_U2S1): (B, B) = bignum::bignum::compute_quadratic_expression(
            [[U1], [U2]],
            [[false], [true]],
            [[S2], [S1]],
            [[false], [false]],
            [],
            [],
        );
        let (_, Y3): (B, B) = bignum::bignum::compute_quadratic_expression(
            [[PP], [X3]],
            [[false], [false]],
            [[U1S2_minus_U2S1], [R]],
            [[false], [true]],
            [],
            [],
        );
        let Z1Z2 = Z1.__mul(Z2);
        let (_, Z3): (B, B) = bignum::bignum::compute_quadratic_expression(
            [[Z1Z2, B::zero()]],
            [[false, false]],
            [[U2, U1]],
            [[false, true]],
            [],
            [],
        );
        (
            CurveJ { x: X3, y: Y3, z: Z3, is_infinity: false },
            JTranscript { lambda_numerator: R, x3: X3, y3: Y3, z3: Z3 },
        )
    }

    unconstrained fn conditional_incomplete_add(
        self,
        p2: Self,
        predicate: bool,
    ) -> (Self, JTranscript<B>) {
        let mut operand_output = self.incomplete_add(p2);
        let result = CurveJ::conditional_select(operand_output.0, self, predicate);
        (result, operand_output.1)
    }
    /**
     * @brief Double a point
     * @note This method minimizes the number of calls to `compute_quadratic_expression`,
     * which is NOT the same as minimizing the number of multiplications.
     **/
    pub(crate) unconstrained fn dbl(self) -> (Self, JTranscript<B>) {
        let X1 = self.x;
        let Y1 = self.y;
        let Z1 = self.z;
        let (_, YY_mul_2): (B, B) = bignum::bignum::compute_quadratic_expression(
            [[Y1]],
            [[false]],
            [[Y1, Y1]],
            [[false, false]],
            [],
            [],
        );
        let mut (_, XX_mul_3): (B, B) = bignum::bignum::compute_quadratic_expression(
            [[X1]],
            [[false]],
            [[X1, X1, X1]],
            [[false, false, false]],
            [],
            [],
        );

        if (Curve::a().get_limb(0) != 0) {
            let ZZ = Z1.__mul(Z1);
            let AZZZZ = ZZ.__mul(ZZ).__mul(Curve::a());
            XX_mul_3 = XX_mul_3.__add(AZZZZ);
        }
        let (_, D): (B, B) = bignum::bignum::compute_quadratic_expression(
            [[X1, X1]],
            [[false, false]],
            [[YY_mul_2]],
            [[false]],
            [],
            [],
        );
        let mut (_, X3): (B, B) = bignum::bignum::compute_quadratic_expression(
            [[XX_mul_3]],
            [[false]],
            [[XX_mul_3]],
            [[false]],
            [D, D],
            [true, true],
        );
        let (_, Y3): (B, B) = bignum::bignum::compute_quadratic_expression(
            [[XX_mul_3], [YY_mul_2]],
            [[false], [true]],
            [[D, X3], [YY_mul_2, YY_mul_2]],
            [[false, true], [false, false]],
            [],
            [],
        );
        // 3XX * (D - X3) - 8YYYY
        let (_, Z3): (B, B) = bignum::bignum::compute_quadratic_expression(
            [[Y1]],
            [[false]],
            [[Z1, Z1]],
            [[false, false]],
            [],
            [],
        );
        (
            CurveJ { x: X3, y: Y3, z: Z3, is_infinity: false },
            JTranscript { lambda_numerator: XX_mul_3, x3: X3, y3: Y3, z3: Z3 },
        )
    }

    pub(crate) fn offset_generator() -> Self {
        let result = Curve::offset_generator();
        Self { x: result.x(), y: result.y(), z: B::one(), is_infinity: false }
    }

    pub(crate) fn offset_generator_final() -> Self {
        let result = Curve::offset_generator_final();
        Self { x: result.x(), y: result.y(), z: B::one(), is_infinity: false }
    }

    pub(crate) fn one() -> Self {
        let result = Curve::one();
        Self { x: result.x(), y: result.y(), z: B::one(), is_infinity: false }
    }

    pub(crate) fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self {
        let mut result = rhs;
        if (predicate) {
            result = lhs;
        }
        result
    }
    /**
     * @brief Perform an ecc scalar multiplication and output the generated AffineTranscript
     **/
    pub(crate) unconstrained fn mul<let NScalarSlices: u32>(
        self,
        scalar: ScalarField<NScalarSlices>,
    ) -> (Self, [AffineTranscript<B>; 5 * NScalarSlices + 6]) {
        let mut transcript: [JTranscript<B>; NScalarSlices * 5 + 6] =
            [JTranscript::new(); NScalarSlices * 5 + 6];

        let input: Self = CurveJ::conditional_select(CurveJ::one(), self, self.is_infinity);
        let scalar: ScalarField<NScalarSlices> =
            ScalarField::conditional_select(ScalarField::zero(), scalar, self.is_infinity);
        let mut ptr: u32 = 0;
        let T = PointTable::new(input);
        for i in 0..8 {
            transcript[ptr] = T.transcript[i];
            ptr += 1;
        }

        let mut accumulator: Self = CurveJ::offset_generator();
        let op = accumulator.incomplete_add(T.get(scalar.base4_slices[0] as u32));
        transcript[ptr] = op.1;
        ptr += 1;
        accumulator = op.0;
        for i in 1..NScalarSlices {
            for _ in 0..4 {
                let op = accumulator.dbl();
                accumulator = op.0;
                transcript[ptr] = op.1;
                ptr += 1;
            }
            let op = accumulator.incomplete_add(T.get(scalar.base4_slices[i] as u32));
            transcript[ptr] = op.1;
            ptr += 1;
            accumulator = op.0;
        }

        let op = accumulator.conditional_incomplete_add(input.neg(), scalar.skew);
        transcript[ptr] = op.1;
        accumulator = op.0;
        ptr += 1;

        let op = accumulator.sub(CurveJ::offset_generator_final());
        transcript[ptr] = op.1;
        ptr += 1;
        accumulator = op.0;

        let affine_transcript: [AffineTranscript<B>; 5 * NScalarSlices + 6] =
            AffineTranscript::from_jacobian_transcript(transcript);

        (accumulator, affine_transcript)
    }
    /**
     * @brief Perform an ecc scalar multiplication and output the generated AffineTranscript
     **/
    unconstrained fn msm_partial<let Size: u32, let NScalarSlices: u32, let TranscriptEntries: u32>(
        points: [Self; Size],
        scalars: [ScalarField<NScalarSlices>; Size],
    ) -> (Self, [JTranscript<B>; TranscriptEntries])/*(Self, [JTranscript<B>; NScalarSlices * Size + NScalarSlices * 4 + Size * 9 - 3]) */
{
        let mut transcript: [JTranscript<B>; TranscriptEntries] =
            [JTranscript::new(); TranscriptEntries];
        let mut tables: [PointTable<B>; Size] = [PointTable::empty(); Size];

        let mut _inputs: [Self; Size] = [CurveJ::new(); Size];
        let mut _scalars: [ScalarField<NScalarSlices>; Size] = [ScalarField::zero(); Size];
        for i in 0..Size {
            _inputs[i] =
                CurveJ::conditional_select(CurveJ::one(), points[i], points[i].is_infinity);
            _scalars[i] = ScalarField::conditional_select(
                ScalarField::zero(),
                scalars[i],
                points[i].is_infinity,
            );
        }
        let points = _inputs;
        let scalars = _scalars;
        let mut ptr: u32 = 0;
        for i in 0..Size {
            tables[i] = PointTable::new(points[i]);
            for j in 0..8 {
                transcript[ptr] = tables[i].transcript[j];
                ptr += 1;
            }
        }

        let mut accumulator: Self = CurveJ::offset_generator();
        let op = accumulator.incomplete_add(tables[0].get(scalars[0].base4_slices[0] as u32));
        transcript[ptr] = op.1;
        ptr += 1;
        accumulator = op.0;

        for i in 1..Size {
            let op = accumulator.incomplete_add(tables[i].get(scalars[i].base4_slices[0] as u32));
            transcript[ptr] = op.1;
            ptr += 1;
            accumulator = op.0;
        }
        for i in 1..NScalarSlices {
            for _ in 0..4 {
                let op = accumulator.dbl();
                accumulator = op.0;
                transcript[ptr] = op.1;
                ptr += 1;
            }
            for j in 0..Size {
                let op =
                    accumulator.incomplete_add(tables[j].get(scalars[j].base4_slices[i] as u32));
                transcript[ptr] = op.1;
                ptr += 1;
                accumulator = op.0;
            }
        }

        for i in 0..Size {
            let op = accumulator.conditional_incomplete_add(points[i].neg(), scalars[i].skew);
            transcript[ptr] = op.1;
            accumulator = op.0;
            ptr += 1;
        }

        (accumulator, transcript)
    }

    /**
     * @brief Perform an ecc scalar multiplication and output the generated AffineTranscript
     **/
    pub(crate) unconstrained fn msm<let Size: u32, let NScalarSlices: u32>(
        mut points: [Self; Size],
        mut scalars: [ScalarField<NScalarSlices>; Size],
    ) -> (Self, [AffineTranscript<B>; NScalarSlices * Size + NScalarSlices * 4 + Size * 9 - 3]) {
        let mut (accumulator, transcript): (Self, [JTranscript<B>; NScalarSlices * Size + NScalarSlices * 4 + Size * 9 - 3]) =
            CurveJ::msm_partial(points, scalars);
        let op = accumulator.sub(CurveJ::offset_generator_final());
        transcript[73 * Size + 252] = op.1;
        accumulator = op.0;
        let affine_transcript: [AffineTranscript<B>; NScalarSlices * Size + NScalarSlices * 4 + Size * 9 - 3] =
            AffineTranscript::from_jacobian_transcript(transcript);

        (accumulator, affine_transcript)
    }

    pub(crate) unconstrained fn compute_linear_expression_transcript<let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>(
        mut mul_points: [Curve; NMuls],
        mut scalars: [ScalarField<NScalarSlices>; NMuls],
        mut add_points: [Curve; NAdds],
    ) -> (Self, [AffineTranscript<B>; NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 + NAdds - 3]) {
        let mut mul_j: [CurveJ<B, Curve>; NMuls] = [CurveJ::new(); NMuls];
        let mut add_j: [CurveJ<B, Curve>; NAdds] = [CurveJ::new(); NAdds];
        for i in 0..NMuls {
            mul_j[i] = CurveJ::<B, Curve>::from(mul_points[i]);
        }
        for i in 0..NAdds {
            add_j[i] = CurveJ::from(add_points[i]);
        }

        let mut (accumulator, transcript): (Self, [JTranscript<B>; NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 + NAdds - 3]) =
            CurveJ::msm_partial(mul_j, scalars);
        let mut transcript_ptr: u32 = NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 - 4;
        for i in 0..NAdds {
            let op = accumulator.conditional_incomplete_add(add_j[i], !add_j[i].is_infinity);
            transcript[transcript_ptr] = op.1;
            accumulator = op.0;
            transcript_ptr += 1;
        }

        let op = accumulator.sub(CurveJ::offset_generator_final());
        transcript[transcript_ptr] = op.1;
        accumulator = op.0;
        let affine_transcript: [AffineTranscript<B>; NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 + NAdds - 3] =
            AffineTranscript::from_jacobian_transcript(transcript);

        (accumulator, affine_transcript)
    }
}
