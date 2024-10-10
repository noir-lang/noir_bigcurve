use dep::bignum::BigNum;
use dep::bignum::BigNumTrait;
use crate::scalar_field::ScalarField;
use crate::CurveParamsTrait;
use crate::BigCurve;
/**
 * @brief CurveJ represents a Short Weierstrass elliptic curve using Jacobian coordinates.
 *        representation in Jacobian form is X, Y, Z
 *        representation in affine form is x, y
 *        relation between both is: x = X / Z^2  , y = Y / Z^3
 *
 * @description The purpose of this class is to speed up witness generation when optimally constraining ecc operations
 *              When constructing constraints, we want to work in AFFINE coordinates,
 *              because of the smaller number of field multiplications (3 muls vs ~14 for Jacobian)
 *              HOWEVER, when working in affine coordinates, 1 modular inverse must be computed per group operation.
 *              This is VERY TIME CONSUMING TO DO when generating witnesses, as this is a modular inverse over a non-native field.
 *              This costs approximately 2D multiplications, where D is the bit-width of the curve field.
 *
 *              To solve this problem, we perform the ENTIRE COMPUTATION in unconstrained functions using JACOBIAN coordiantes
 *              (which don't require inverses). We record each ECC op performed in a JTranscript object
 *              We then compute a Montgomery Batch Inverse to compute ALL of the inverses we require when evaluating using affine arithmetic.
 *              i.e. we compute 1 modular inverse instead of ~256 or 320 depending on the elliptic curve.
 *              Yes, this is an extremely complex solution to a simple problem. Such is life. Inverses are expensive to generate witnesses for.
 **/
struct CurveJ<BigNum, CurveParams> {
    x: BigNum,
    y: BigNum,
    z: BigNum,
    is_infinity: bool
}

/**
 * @brief A transcript of a group operation in Jacobian coordinates
 * x3, y3, z3 = the output of the group operation
 * lambda_numerator = numerator of the `lambda` term (the denominator is assumed to be z3)
 **/
struct JTranscript<BigNum> {
    lambda_numerator: BigNum,
    x3: BigNum,
    y3: BigNum,
    z3: BigNum
}

impl<BigNum> JTranscript<BigNum> where BigNum: BigNumTrait {
    unconstrained fn __new() -> Self {
        JTranscript { lambda_numerator: BigNum::new(), x3: BigNum::new(), y3: BigNum::new(), z3: BigNum::new() }
    }
}

/**
 * @brief A transcript of a group operation in Affine coordinates
 * x3, y3 = the output of the group operation
 * lambda = gradient of the line that passes through input points of group operation
 * For addition, lambda = (y2 - y1) / (x2 - x1)
 * For doubling, lambda = (3 * x1 * x1) / (2 * y1)
 * If we have an array of JTranscript objects, we can turn them into AffineTranscript objects with only 1 modular inverse
 **/
struct AffineTranscript<BigNum> {
    lambda: BigNum,
    x3: BigNum,
    y3: BigNum
}

/**
 * @brief construct a sequence of AffineTranscript objects from a sequence of Jacobian transcript objects
 **/
impl<BigNum> AffineTranscript<BigNum> where BigNum: BigNumTrait {
    fn new() -> Self {
        AffineTranscript { lambda: BigNum::new(), x3: BigNum::new(), y3: BigNum::new() }
    }

    unconstrained fn __from_j(j_tx: JTranscript<BigNum>) -> Self {
        AffineTranscript::__from_jacobian_transcript([j_tx])[0]
    }

    unconstrained pub fn __from_j_with_hint(j_tx: JTranscript<BigNum>, inverse: BigNum) -> AffineTranscript<BigNum> {
        let z_inv = inverse;
        let zz = z_inv.__mul(z_inv);
        let zzz = zz.__mul(z_inv);
        let lambda = j_tx.lambda_numerator.__mul(z_inv);
        let x3 = j_tx.x3.__mul(zz);
        let y3 = j_tx.y3.__mul(zzz);
        AffineTranscript { x3, y3, lambda }
    }

    unconstrained fn __from_jacobian_transcript<let NumEntries: u32>(j_tx: [JTranscript<BigNum>; NumEntries]) -> [AffineTranscript<BigNum>; NumEntries] {
        let mut result: [AffineTranscript<BigNum>; NumEntries] = [AffineTranscript::new(); NumEntries];

        let mut inverses: [BigNum; NumEntries] = [BigNum::new(); NumEntries];
        for i in 0..j_tx.len() {
            inverses[i] = j_tx[i].z3;
        }

        // tadaa
        let inverses: [BigNum; NumEntries] = BigNum::__batch_invert(inverses);

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
    z: [BigNum; 16],
    transcript: [JTranscript<BigNum>; 8]
}

impl<BigNum> PointTable<BigNum> where BigNum: BigNumTrait {
    fn empty() -> Self {
        PointTable {
            x: [BigNum::new(); 16],
            y: [BigNum::new(); 16],
            z: [BigNum::new(); 16],
            transcript: [unsafe {
                JTranscript::__new()
            }; 8]
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
    unconstrained fn __new<CurveParams>(P: CurveJ<BigNum, CurveParams>) -> Self where CurveParams: CurveParamsTrait<BigNum> {
        let mut result = PointTable {
            x: [BigNum::new(); 16],
            y: [BigNum::new(); 16],
            z: [BigNum::new(); 16],
            transcript: [JTranscript::__new(); 8]
        };
        let op = P.__dbl();
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
            let op = D2.__incomplete_add(A);
            A = op.0;
            result.transcript[i] = op.1;
            result.x[8+i] = A.x;
            result.y[8+i] = A.y;
            result.z[8+i] = A.z;
            result.x[7-i] = A.x;
            result.y[7-i] = A.y.__neg();
            result.z[7-i] = A.z;
        }

        result
    }

    /**
     * @brief get a value out of the lookup table
     **/
    unconstrained fn __get<CurveParams>(
        self,
        idx: u8
    ) -> CurveJ<BigNum, CurveParams> where CurveParams: CurveParamsTrait<BigNum> {
        CurveJ { x: self.x[idx], y: self.y[idx], z: self.z[idx], is_infinity: false }
    }
}

/**
 * @brief construct from BigCurve
 **/
impl<BigNum, CurveParams> std::convert::From<BigCurve<BigNum, CurveParams>> for CurveJ<BigNum, CurveParams> where BigNum: BigNumTrait, CurveParams: CurveParamsTrait<BigNum> {
    fn from(affine_point: BigCurve<BigNum, CurveParams>) -> Self {
        CurveJ { x: affine_point.x, y: affine_point.y, z: BigNum::one(), is_infinity: affine_point.is_infinity }
    }
}

/**
 * @brief are two Jacobian points equal?
 * @description only really used in tests for now.
 **/
impl<BigNum, CurveParams> std::cmp::Eq for CurveJ<BigNum, CurveParams> where BigNum: BigNumTrait, CurveParams: CurveParamsTrait<BigNum> {
    fn eq(self, other: Self) -> bool {
        // if x == y then (X1 / Z1 * Z1 = X2 / Z2 * Z2)
        //            and (Y1 / Z1 * Z1 * Z1 = Y2 / Z2 * Z2 * Z2)

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

        let mut points_equal = (x_lhs.eq(x_rhs) & y_lhs.eq(y_rhs)) & both_not_infinity;
        points_equal = points_equal | both_infinity;
        points_equal
    }
}

impl<BigNum, CurveParams> CurveJ<BigNum, CurveParams> where BigNum: BigNumTrait, CurveParams: CurveParamsTrait<BigNum> {
    /**
     * @brief negate a point
     **/
    unconstrained fn __neg(self) -> Self {
        CurveJ { x: self.x, y: self.y.__neg(), z: self.z, is_infinity: self.is_infinity }
    }

    unconstrained fn __new() -> Self {
        CurveJ { x: BigNum::new(), y: BigNum::new(), z: BigNum::new(), is_infinity: false }
    }

    unconstrained fn __point_at_infinity() -> Self {
        CurveJ { x: BigNum::new(), y: BigNum::new(), z: BigNum::new(), is_infinity: true }
    }

    unconstrained fn __sub(self, p2: Self) -> (Self, JTranscript<BigNum>) {
        self.__add(p2.__neg())
    }

    unconstrained fn __add(self, p2: Self) -> (Self, JTranscript<BigNum>) {
        // TODO: once we have linear expressions as unconstrained fns, replace this with something that has no addmods, submods
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
        let double_predicate = x_equal_predicate & y_equal_predicate & !lhs_infinity & !rhs_infinity;
        let add_predicate = !x_equal_predicate & !lhs_infinity & !rhs_infinity;
        let infinity_predicate = (x_equal_predicate & !y_equal_predicate) | (lhs_infinity & rhs_infinity);
        let mut result: (Self, JTranscript<BigNum>) = (CurveJ::__new(), JTranscript::__new());
        if (double_predicate) {
            result = self.__dbl();
        } else if (add_predicate) {
            result = self.__incomplete_add(p2);
        } else if (infinity_predicate) {
            result = (CurveJ::__point_at_infinity(), JTranscript::__new() );
        } else if (lhs_infinity & !rhs_infinity) {
            result = (p2, JTranscript::__new());
        } else if (rhs_infinity & !lhs_infinity) {
            result = (self, JTranscript::__new());
        }
        result
        // let (_, PP): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression([[U2, U1]], [[false, true]], [[U2, U1]], [[false, true]], [], []);
        // let (_, X3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
        //     [[BigNum::new(), PP], [R, BigNum::new()]],
        //     [[false, true], [false, false]],
        //     [[U1, U2], [R, BigNum::new()]],
        //     [[false, false], [false, false]],
        //     [],
        //     []
        // );
        // let (_, U1S2_minus_U2S1): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
        //     [[U1], [U2]],
        //     [[false], [true]],
        //     [[S2], [S1]],
        //     [[false], [false]],
        //     [],
        //     []
        // );
        // let (_, Y3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
        //     [[PP], [X3]],
        //     [[false], [false]],
        //     [[U1S2_minus_U2S1], [R]],
        //     [[false], [true]],
        //     [],
        //     []
        // );
        // let Z1Z2 = Z1.__mulmod(Z2);
        // let (_, Z3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
        //     [[Z1Z2, BigNum::new()]],
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
    unconstrained fn __incomplete_add(self, p2: Self) -> (Self, JTranscript<BigNum>) {
        // TODO: once we have linear expressions as unconstrained fns, replace this with something that has no addmods, submods
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

        let (_, PP): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression([[U2, U1]], [[false, true]], [[U2, U1]], [[false, true]], [], []);

        let (_, X3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
            [[BigNum::new(), PP], [R, BigNum::new()]],
            [[false, true], [false, false]],
            [[U1, U2], [R, BigNum::new()]],
            [[false, false], [false, false]],
            [],
            []
        );

        let (_, U1S2_minus_U2S1): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
            [[U1], [U2]],
            [[false], [true]],
            [[S2], [S1]],
            [[false], [false]],
            [],
            []
        );
        let (_, Y3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
            [[PP], [X3]],
            [[false], [false]],
            [[U1S2_minus_U2S1], [R]],
            [[false], [true]],
            [],
            []
        );
        let Z1Z2 = Z1.__mul(Z2);
        let (_, Z3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
            [[Z1Z2, BigNum::new()]],
            [[false, false]],
            [[U2, U1]],
            [[false, true]],
            [],
            []
        );

        (
            CurveJ { x: X3, y: Y3, z: Z3, is_infinity: false }, JTranscript { lambda_numerator: R, x3: X3, y3: Y3, z3: Z3 }
        )
    }

    /**
     * @brief Double a point
     * @note This method minimizes the number of calls to `compute_quadratic_expression`,
     * which is NOT the same as minimizing the number of multiplications.
     **/
    unconstrained fn __dbl(self) -> (Self, JTranscript<BigNum>) {
        let X1 = self.x;
        let Y1 = self.y;
        let Z1 = self.z;

        let (_, YY_mul_2): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression([[Y1]], [[false]], [[Y1, Y1]], [[false, false]], [], []);
        let (_, XX_mul_3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
            [[X1]],
            [[false]],
            [[X1, X1, X1]],
            [[false, false, false]],
            [],
            []
        );
        let (_, D): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression([[X1, X1]], [[false, false]], [[YY_mul_2]], [[false]], [], []);
        let mut (_, X3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
            [[XX_mul_3]],
            [[false]],
            [[XX_mul_3]],
            [[false]],
            [D, D],
            [true, true]
        );
        let (_, Y3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
            [[XX_mul_3], [YY_mul_2]],
            [[false], [true]],
            [[D, X3], [YY_mul_2, YY_mul_2]],
            [[false, true], [false, false]],
            [],
            []
        );
        // TODO: tidy this up and make more efficient?!
        if (CurveParams::a().get_limb(0) != 0) {
            let ZZ = Z1.mul(Z1);
            let AZZZZ = ZZ.mul(ZZ).mul(CurveParams::a());
            X3 = X3.add(AZZZZ);
        }
        let (_, Z3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression([[Y1]], [[false]], [[Z1, Z1]], [[false, false]], [], []);
        (
            CurveJ { x: X3, y: Y3, z: Z3, is_infinity: false }, JTranscript { lambda_numerator: XX_mul_3, x3: X3, y3: Y3, z3: Z3 }
        )
    }

    fn offset_generator() -> Self {
        let result = CurveParams::offset_generator();
        Self { x: result[0], y: result[1], z: BigNum::one(), is_infinity: false }
    }

    fn offset_generator_final() -> Self {
        let result = CurveParams::offset_generator_final();
        Self { x: result[0], y: result[1], z: BigNum::one(), is_infinity: false }
    }

    fn one() -> Self {
        let result = CurveParams::one();
        Self { x: result[0], y: result[1], z: BigNum::one(), is_infinity: false }
    }

    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self {
        let mut result = rhs;
        if (predicate) {
            result = lhs;
        }
        result
    }
    /**
     * @brief Perform an ecc scalar multiplication and output the generated AffineTranscript
     **/
    unconstrained fn __mul<let NScalarSlices: u32>(
        self,
        scalar: ScalarField<NScalarSlices>
    ) -> (Self, [AffineTranscript<BigNum>]) {
        let mut transcript: [JTranscript<BigNum>; NScalarSlices * 5 + 6] = [JTranscript::__new(); NScalarSlices * 5 + 6];

        let input: Self = CurveJ::conditional_select(CurveJ::one(), self, self.is_infinity);
        let scalar: ScalarField<NScalarSlices> = ScalarField::conditional_select(ScalarField::zero(), scalar, self.is_infinity);
        let mut ptr: u32 = 0;
        let T = PointTable::__new(input);
        for i in 0..8 {
            transcript[ptr] = T.transcript[i];
            ptr += 1;
        }

        let mut accumulator: Self = CurveJ::offset_generator();
        let op = accumulator.__incomplete_add(T.__get(scalar.base4_slices[0]));
        transcript[ptr] = op.1;
        ptr += 1;
        accumulator = op.0;
        for i in 1..NScalarSlices {
            for _ in 0..4 {
                let op = accumulator.__dbl();
                accumulator = op.0;
                transcript[ptr] = op.1;
                ptr += 1;
            }
            let op = accumulator.__incomplete_add(T.__get(scalar.base4_slices[i]));
            transcript[ptr] = op.1;
            ptr += 1;
            accumulator = op.0;
        }

        if scalar.skew {
            let op = accumulator.__incomplete_add(input.__neg());
            transcript[ptr] = op.1;
            ptr += 1;
            accumulator = op.0;
        } else {
            transcript[ptr] = JTranscript::__new();
            ptr += 1;
        }

        let op = accumulator.__sub(CurveJ::offset_generator_final());
        transcript[ptr] = op.1;
        ptr += 1;
        accumulator = op.0;

        let affine_transcript: [AffineTranscript<BigNum>] = AffineTranscript::__from_jacobian_transcript(transcript);

        (accumulator, affine_transcript)
    }
    /**
     * @brief Perform an ecc scalar multiplication and output the generated AffineTranscript
     **/
    unconstrained fn __msm_partial<let Size: u32, let NScalarSlices: u32>(
        mut points: [Self; Size],
        mut scalars: [ScalarField<NScalarSlices>; Size]
    ) -> (Self, [JTranscript<BigNum>; NScalarSlices * Size + NScalarSlices * 4 + Size * 9 - 3]) {
        let mut transcript: [JTranscript<BigNum>; NScalarSlices * Size + NScalarSlices * 4 + Size * 9 - 3] = [JTranscript::__new(); NScalarSlices * Size + NScalarSlices * 4 + Size * 9 - 3];
        let mut tables: [PointTable<BigNum>; Size] = [PointTable::empty(); Size];

        let mut _inputs: [Self; Size] = [CurveJ::__new(); Size];
        let mut  _scalars: [ScalarField<NScalarSlices>; Size] = [ScalarField::new(); Size];
        for i in 0..Size {
            _inputs[i] = CurveJ::conditional_select(CurveJ::one(), points[i], points[i].is_infinity);
            _scalars[i] = ScalarField::conditional_select(ScalarField::zero(), scalars[i], points[i].is_infinity);
        }
        points = _inputs;
        scalars = _scalars;
        let mut ptr: u32 = 0;
        for i in 0..Size {
            tables[i] = PointTable::__new(points[i]);
            for j in 0..8 {
                transcript[ptr] = tables[i].transcript[j];
                ptr += 1;
            }
        }

        let mut accumulator: Self = CurveJ::offset_generator();
        let op = accumulator.__incomplete_add(tables[0].__get(scalars[0].base4_slices[0]));
        transcript[ptr] = op.1;
        ptr += 1;
        accumulator = op.0;

        for i in 1..Size {
            let op = accumulator.__incomplete_add(tables[i].__get(scalars[i].base4_slices[0]));
            transcript[ptr] = op.1;
            ptr += 1;
            accumulator = op.0;
        }
        for i in 1..NScalarSlices {
            for _ in 0..4 {
                let op = accumulator.__dbl();
                accumulator = op.0;
                transcript[ptr] = op.1;
                ptr += 1;
            }
            for j in 0..Size {
                let op = accumulator.__incomplete_add(tables[j].__get(scalars[j].base4_slices[i]));
                transcript[ptr] = op.1;
                ptr += 1;
                accumulator = op.0;
            }
        }

        for i in 0..Size {
            if scalars[i].skew {
                let op = accumulator.__incomplete_add(points[i].__neg());
                transcript[ptr] = op.1;
                ptr += 1;
                accumulator = op.0;
            } else {
                transcript[ptr] = JTranscript::__new();
                ptr += 1;
            }
        }

        (accumulator, transcript)
    }

    /**
     * @brief Perform an ecc scalar multiplication and output the generated AffineTranscript
     **/
    unconstrained fn __msm<let Size: u32, let NScalarSlices: u32>(
        mut points: [Self; Size],
        mut scalars: [ScalarField<NScalarSlices>; Size]
    ) -> (Self, [AffineTranscript<BigNum>; NScalarSlices * Size + NScalarSlices * 4 + Size * 9 - 3]) {
        let mut (accumulator, transcript): (Self, [JTranscript<BigNum>; NScalarSlices * Size + NScalarSlices * 4 + Size * 9 - 3]) = CurveJ::__msm_partial(points, scalars);
        let op = accumulator.__sub(CurveJ::offset_generator_final());
        transcript[73 * Size + 252] = op.1;
        accumulator = op.0;
        let affine_transcript: [AffineTranscript<BigNum>; NScalarSlices * Size + NScalarSlices * 4 + Size * 9 - 3] = AffineTranscript::__from_jacobian_transcript(transcript);

        (accumulator, affine_transcript)
    }

    unconstrained fn __compute_linear_expression_transcript<let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>(
        mul_points: [BigCurve<BigNum, CurveParams>; NMuls],
        mul_scalars: [ScalarField<NScalarSlices>; NMuls],
        add_points: [BigCurve<BigNum, CurveParams>; NAdds]
    ) -> AffineLinearExpressionTranscript<BigNum, NScalarSlices, NMuls, NAdds> {
        let mut mul_j: [CurveJ<BigNum, CurveParams>; NMuls] = [CurveJ::__new(); NMuls];
        let mut add_j: [CurveJ<BigNum, CurveParams>; NAdds] = [CurveJ::__new(); NAdds];
        for i in 0..NMuls {
            mul_j[i] = CurveJ::from(mul_points[i]);
        }
        for i in 0..NAdds {
            add_j[i] = CurveJ::from(add_points[i]);
        }

        let mut jacobian_transcript: LinearExpressionTranscript<BigNum,NScalarSlices,NMuls,NAdds> = LinearExpressionTranscript {
            table_transcript: [[JTranscript::__new(); 8]; NMuls],
            msm_double_transcript: [[JTranscript::__new(); 4]; NScalarSlices],
            msm_add_transcript: [[JTranscript::__new(); NMuls]; NScalarSlices],
            skew_transcript: [JTranscript::__new(); NMuls],
            add_transcript: [JTranscript::__new(); NAdds],
            offset_generator_transcript: JTranscript::__new()
        };

        // #####
        let mut tables: [PointTable<BigNum>; NMuls] = [PointTable::empty(); NMuls];

        let mut _inputs: [Self; NMuls] = [CurveJ::__new(); NMuls];
        let mut  _scalars: [ScalarField<NScalarSlices>; NMuls] = [ScalarField::new(); NMuls];
        for i in 0..NMuls {
            _inputs[i] = CurveJ::conditional_select(CurveJ::one(), mul_j[i], mul_j[i].is_infinity);
            _scalars[i] = ScalarField::conditional_select(ScalarField::zero(), mul_scalars[i], mul_j[i].is_infinity);
        }
        let points = _inputs;
        let scalars = _scalars;

        for i in 0..NMuls {
            tables[i] = PointTable::__new(points[i]);
            for j in 0..8 {
                jacobian_transcript.table_transcript[i][j] = tables[i].transcript[j];
            }
        }

        let mut accumulator: Self = CurveJ::offset_generator();
        let op = accumulator.__incomplete_add(tables[0].__get(scalars[0].base4_slices[0]));
        jacobian_transcript.msm_add_transcript[0][0] = op.1;
        accumulator = op.0;

        for i in 1..NMuls {
            let op = accumulator.__incomplete_add(tables[i].__get(scalars[i].base4_slices[0]));
            jacobian_transcript.msm_add_transcript[0][i] = op.1;
            accumulator = op.0;
        }
        for i in 1..NScalarSlices {
            for j in 0..4 {
                let op = accumulator.__dbl();
                accumulator = op.0;
                jacobian_transcript.msm_double_transcript[i-1][j] = op.1;
            }
            for j in 0..NMuls {
                let op = accumulator.__incomplete_add(tables[j].__get(scalars[j].base4_slices[i]));
                jacobian_transcript.msm_add_transcript[i][j] = op.1;
                accumulator = op.0;
            }
        }

        for i in 0..NMuls {
            let op = accumulator.__incomplete_add(points[i].__neg());
            if scalars[i].skew {
                jacobian_transcript.skew_transcript[i] = op.1;
                accumulator = op.0;
            } else {
                jacobian_transcript.skew_transcript[i] = op.1;
            }
        }

        for i in 0..NAdds {
            let op = accumulator.__incomplete_add(add_j[i]);
            jacobian_transcript.add_transcript[i] = op.1;
            accumulator = op.0;
        }

        let op = accumulator.__sub(CurveJ::offset_generator_final());
        jacobian_transcript.offset_generator_transcript = op.1;
        accumulator = op.0;

        let affine_transcript: AffineLinearExpressionTranscript<BigNum, NScalarSlices, NMuls, NAdds> = AffineLinearExpressionTranscript::__from_jtranscript(jacobian_transcript);
        affine_transcript
    }
}

struct LinearExpressionTranscript<BigNum, let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>{
    table_transcript: [[JTranscript<BigNum>; 8]; NMuls],
    msm_double_transcript: [[JTranscript<BigNum>; 4]; NScalarSlices],
    msm_add_transcript: [[JTranscript<BigNum>; NMuls]; NScalarSlices],
    skew_transcript: [JTranscript<BigNum>; NMuls],
    add_transcript: [JTranscript<BigNum>; NAdds],
    offset_generator_transcript: JTranscript<BigNum>
}

struct AffineLinearExpressionTranscript<BigNum, let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>{
    table_transcript: [[AffineTranscript<BigNum>; 8]; NMuls],
    msm_double_transcript: [[AffineTranscript<BigNum>; 4]; NScalarSlices - 1],
    msm_add_transcript: [[AffineTranscript<BigNum>; NMuls]; NScalarSlices],
    skew_transcript: [AffineTranscript<BigNum>; NMuls],
    add_transcript: [AffineTranscript<BigNum>; NAdds],
    offset_generator_transcript: AffineTranscript<BigNum>
}

impl<BigNum, let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>  AffineLinearExpressionTranscript<BigNum,NScalarSlices,NMuls,NAdds> where BigNum: BigNumTrait {

    unconstrained fn __from_jtranscript(jtranscript: LinearExpressionTranscript<BigNum,  NScalarSlices,  NMuls,  NAdds>) -> Self {
        let mut inverses: [BigNum; NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 - 3] = [BigNum::new(); NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 - 3];

        let mut ptr: u32 = 0;
        for i in 0..NMuls {
            for j in 0..8 {
                inverses[ptr] = jtranscript.table_transcript[i][j].z3;
                ptr += 1;
            }
        }
        for i in 0..NMuls {
            inverses[ptr] = jtranscript.msm_add_transcript[0][i].z3;
            ptr += 1;
        }
        for i in 1..NScalarSlices {
            for j in 0..4 {
                inverses[ptr] = jtranscript.msm_double_transcript[i-1][j].z3;
                ptr += 1;
            }

            for j in 0..NMuls {
                inverses[ptr] = jtranscript.msm_add_transcript[i][j].z3;
                ptr += 1;
            }
        }

        for i in 0..NMuls {
            inverses[ptr] = jtranscript.skew_transcript[i].z3;
            ptr += 1;
        }
        for i in 0..NAdds {
            inverses[ptr] = jtranscript.add_transcript[i].z3;
            ptr += 1;
        }
        inverses[ptr] = jtranscript.offset_generator_transcript.z3;
        ptr += 1;
        let inverses = BigNum::__batch_invert(inverses);

        let mut result: AffineLinearExpressionTranscript<BigNum, NScalarSlices,NMuls,NAdds> = AffineLinearExpressionTranscript {
            table_transcript: [[AffineTranscript::new(); 8]; NMuls],
            msm_double_transcript: [[AffineTranscript::new(); 4]; NScalarSlices - 1],
            msm_add_transcript: [[AffineTranscript::new(); NMuls]; NScalarSlices],
            skew_transcript: [AffineTranscript::new(); NMuls],
            add_transcript: [AffineTranscript::new(); NAdds],
            offset_generator_transcript: AffineTranscript::new()
        };

        let mut it = 0;
        for i in 0..NMuls {
            for j in 0..8 {
                result.table_transcript[i][j] = AffineTranscript::__from_j_with_hint(jtranscript.table_transcript[i][j], inverses[it]);
                it+=1;
            }
        }
        for i in 0..NMuls {
            result.msm_add_transcript[0][i] = AffineTranscript::__from_j_with_hint(jtranscript.msm_add_transcript[0][i], inverses[it]);
            it+=1;
        }
        for i in 1..NScalarSlices {
            for j in 0..4 {
                result.msm_double_transcript[i-1][j] = AffineTranscript::__from_j_with_hint(jtranscript.msm_double_transcript[i-1][j], inverses[it]);
                it+=1;
            }

            for j in 0..NMuls {
                result.msm_add_transcript[i][j] = AffineTranscript::__from_j_with_hint(jtranscript.msm_add_transcript[i][j], inverses[it]);
                it+=1;
            }
        }

        for i in 0..NMuls {
            result.skew_transcript[i] = AffineTranscript::__from_j_with_hint(jtranscript.skew_transcript[i], inverses[it]);
            it+=1;
        }
        for i in 0..NAdds {
            result.add_transcript[i] = AffineTranscript::__from_j_with_hint(jtranscript.add_transcript[i], inverses[it]);
            it+=1;
        }

        result.offset_generator_transcript = AffineTranscript::__from_j_with_hint(jtranscript.offset_generator_transcript, inverses[it]);

        result
    }
}
