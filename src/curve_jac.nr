use dep::bignum::ArrayX;
use dep::bignum::BigNum;
use dep::bignum::BNExpressionInput;
use dep::bignum::BigNumParamsTrait;
// use dep::bignum::BigNumParams;
use dep::bignum::U60Repr;
use crate::scalar_field::ScalarField;

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
struct CurveJ<let N: u32, Params> {
    x: BigNum<N, Params>,
    y: BigNum<N, Params>,
    z: BigNum<N, Params>,
}

/**
 * @brief A transcript of a group operation in Jacobian coordinates
 * x3, y3, z3 = the output of the group operation
 * lambda_numerator = numerator of the `lambda` term (the denominator is assumed to be z3)
 **/
struct JTranscript<let N: u32, Params> {
    lambda_numerator: BigNum<N, Params>,
    x3: BigNum<N, Params>,
    y3: BigNum<N, Params>,
    z3: BigNum<N, Params>
}

impl<let N: u32, Params> JTranscript<N, Params> {
    // gib gib
    unconstrained fn new() -> Self {
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
struct AffineTranscript<let N: u32, Params> {
    lambda: BigNum<N, Params>,
    x3: BigNum<N, Params>,
    y3: BigNum<N, Params>
}

/**
 * @brief construct a sequence of AffineTranscript objects from a sequence of Jacobian transcript objects
 **/
impl<let N: u32, Params> AffineTranscript<N, Params> {
    fn new() -> Self {
        AffineTranscript { lambda: BigNum::new(), x3: BigNum::new(), y3: BigNum::new() }
    }
    unconstrained fn from_jacobian_transcript(j_tx: [JTranscript<N, Params>]) -> [AffineTranscript<N, Params>] where Params: BigNumParamsTrait<N> {
        let mut result: [AffineTranscript<N, Params>] = &[];

        let mut inverses: [BigNum<N, Params>] = &[];
        for i in 0..j_tx.len() {
            inverses = inverses.push_back(j_tx[i].z3);
        }

        // tadaa
        batch_invert(&mut inverses);

        for i in 0..j_tx.len() {
            let z_inv = inverses[i];
            let zz = z_inv.__mulmod(z_inv);
            let zzz = zz.__mulmod(z_inv);
            let lambda = j_tx[i].lambda_numerator.__mulmod(z_inv);
            let x3 = j_tx[i].x3.__mulmod(zz);
            let y3 = j_tx[i].y3.__mulmod(zzz);
            result = result.push_back(AffineTranscript { lambda, x3, y3 });
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
struct PointTable<let N: u32, Params> {
    x: [[Field; N]; 16],
    y: [[Field; N]; 16],
    z: [[Field; N]; 16],
    transcript: [JTranscript<N, Params>; 8]
}

impl<let N: u32, Params> PointTable<N, Params> {
    /**
     * @brief make a new PointTable from an input point
     * @description we use "windowed non-adjacent form" representation 
     * to reduce the number of group operations required for the table
     * [-15P, -13P, ..., 15P] requires 8 group operations
     * [0, P, ..., 15P] requires 14 group operations.
     * group operations are expensive!
     **/
    unconstrained fn new(P: CurveJ<N, Params>) -> Self where Params: BigNumParamsTrait<N> {
        let mut result = PointTable { x: [[0; N]; 16], y: [[0; N]; 16], z: [[0; N]; 16], transcript: [JTranscript::new(); 8] };
        let op = P.dbl();
        let D2 = op.0;
        result.transcript[0] = op.1;
        result.x[7] = P.x.limbs;
        result.y[7] = P.y.__negate().limbs;
        result.z[7] = P.z.limbs;
        result.x[8] = P.x.limbs;
        result.y[8] = P.y.limbs;
        result.z[8] = P.z.limbs;
        let mut A = P;
        for i in 1..8 {
            let op = D2.incomplete_add(A);
            A = op.0;
            result.transcript[i] = op.1;
            result.x[8+i] = A.x.limbs;
            result.y[8+i] = A.y.limbs;
            result.z[8+i] = A.z.limbs;
            result.x[7-i] = A.x.limbs;
            result.y[7-i] = A.y.__negate().limbs;
            result.z[7-i] = A.z.limbs;
        }

        result
    }

    /**
     * @brief get a value out of the lookup table
     * @description if the backend has an efficient implementation of memory lookups,
     * this will be very efficient (~18 constraints for 256-bit curves using the barretenberg backend)
     **/
    unconstrained fn get(self, idx: u8) -> CurveJ<N, Params> where Params: BigNumParamsTrait<N> {
        let x: BigNum<N, Params> = BigNum { limbs: self.x[idx] };
        let y: BigNum<N, Params> = BigNum { limbs: self.y[idx] };
        let z: BigNum<N, Params> = BigNum { limbs: self.z[idx] };
        CurveJ { x, y, z }
    }
}

/**
 * @brief are two Jacobian points equal?
 * @description only really used in tests for now.
 **/
impl<let N: u32, Params> std::cmp::Eq for CurveJ<N, Params> {
    fn eq(self, other: Self) -> bool where Params: BigNumParamsTrait<N> {
        let z1 = self.z;
        let z2 = other.z;
        let z1z1 = z1.__mulmod(z1);
        let z1z1z1 = z1z1.__mulmod(z1);
        let z2z2 = z2.__mulmod(z2);
        let z2z2z2 = z2z2.__mulmod(z2);

        let x_lhs = self.x.__mulmod(z2z2);
        let x_rhs = other.x.__mulmod(z1z1);
        let y_lhs = self.y.__mulmod(z2z2z2);
        let y_rhs = other.y.__mulmod(z1z1z1);
        (x_lhs.limbs == x_rhs.limbs) & (y_lhs.limbs == y_rhs.limbs)
    }
}

/**
 * @brief negate a point
 **/
impl<let N: u32, Params> std::ops::Neg for CurveJ<N, Params> {
    fn neg(self) -> Self where Params: BigNumParamsTrait<N> {
        CurveJ { x: self.x, y: self.y.__negate(), z: self.z }
    }
}

impl<let N: u32, Params> CurveJ<N, Params> {

    unconstrained fn new() -> Self {
        CurveJ { x: BigNum::new(), y: BigNum::new(), z: BigNum::new() }
    }

    /**
     * @brief Add two points together.
     * @description Only uses incomplete formulae.
     * With our use of offset generators, we should never need to handle edge cases.
     * (when constraining operations, we simply assert the input x-coordinates are not equal)
     * @note This method minimizes the number of calls to `compute_quadratic_expression`,
     * which is NOT the same as minimizing the number of multiplications.
     **/
    unconstrained fn incomplete_add(
        self,
        p2: CurveJ<N, Params>
    ) -> (CurveJ<N, Params>, JTranscript<N, Params>) where Params: BigNumParamsTrait<N> {
        // TODO: once we have linear expressions as unconstrained fns, replace this with something that has no addmods, submods
        let X1 = self.x;
        let X2 = p2.x;
        let Y1 = self.y;
        let Y2 = p2.y;
        let Z1 = self.z;
        let Z2 = p2.z;
        let Z2Z2 = Z2.__mulmod(Z2);
        let Z1Z1 = Z1.__mulmod(Z1);
        let Z2Z2Z2 = Z2Z2.__mulmod(Z2);
        let Z1Z1Z1 = Z1Z1.__mulmod(Z1);
        let U1 = X1.__mulmod(Z2Z2);
        let U2 = X2.__mulmod(Z1Z1);
        let S1 = Y1.__mulmod(Z2Z2Z2);
        let S2 = Y2.__mulmod(Z1Z1Z1);
        let R = S2.__submod(S1);

        let (_, PP): (BigNum<N, Params>, BigNum<N, Params> ) = BigNum::__compute_quadratic_expression_no_borrow([[U2, U1]], [[false, true]], [[U2, U1]], [[false, true]], [], []);

        let (_, X3): (BigNum<N, Params>, BigNum<N, Params> ) = BigNum::__compute_quadratic_expression_no_borrow(
            [[BigNum::new(), PP], [R, BigNum::new()]],
            [[false, true], [false, false]],
            [[U1, U2], [R, BigNum::new()]],
            [[false, false], [false, false]],
            [],
            []
        );

        let (_, U1S2_minus_U2S1): (BigNum<N, Params>, BigNum<N, Params> ) = BigNum::__compute_quadratic_expression_no_borrow(
            [[U1], [U2]],
            [[false], [true]],
            [[S2], [S1]],
            [[false], [false]],
            [],
            []
        );
        let (_, Y3): (BigNum<N, Params>, BigNum<N, Params> ) = BigNum::__compute_quadratic_expression_no_borrow(
            [[PP], [X3]],
            [[false], [false]],
            [[U1S2_minus_U2S1], [R]],
            [[false], [true]],
            [],
            []
        );
        let Z1Z2 = Z1.__mulmod(Z2);
        let (_, Z3): (BigNum<N, Params>, BigNum<N, Params> ) = BigNum::__compute_quadratic_expression_no_borrow(
            [[Z1Z2, BigNum::new()]],
            [[false, false]],
            [[U2, U1]],
            [[false, true]],
            [],
            []
        );
        (CurveJ { x: X3, y: Y3, z: Z3 }, JTranscript { lambda_numerator: R, x3: X3, y3: Y3, z3: Z3 })
    }

    /**
     * @brief Double a point
     * @note This method minimizes the number of calls to `compute_quadratic_expression`,
     * which is NOT the same as minimizing the number of multiplications.
     **/
    unconstrained fn dbl(self) -> (Self, JTranscript<N, Params>) where Params: BigNumParamsTrait<N> {
        let X1 = self.x;
        let Y1 = self.y;
        let Z1 = self.z;

        let (_, YY_mul_2): (BigNum<N, Params>, BigNum<N, Params> ) = BigNum::__compute_quadratic_expression_no_borrow([[Y1]], [[false]], [[Y1, Y1]], [[false, false]], [], []);
        let (_, XX_mul_3): (BigNum<N, Params>, BigNum<N, Params> ) = BigNum::__compute_quadratic_expression_no_borrow(
            [[X1]],
            [[false]],
            [[X1, X1, X1]],
            [[false, false, false]],
            [],
            []
        );
        let (_, D): (BigNum<N, Params>, BigNum<N, Params> ) = BigNum::__compute_quadratic_expression_no_borrow([[X1, X1]], [[false, false]], [[YY_mul_2]], [[false]], [], []);
        let (_, X3): (BigNum<N, Params>, BigNum<N, Params> ) = BigNum::__compute_quadratic_expression_no_borrow(
            [[XX_mul_3]],
            [[false]],
            [[XX_mul_3]],
            [[false]],
            [D, D],
            [true, true]
        );
        let (_, Y3): (BigNum<N, Params>, BigNum<N, Params> ) = BigNum::__compute_quadratic_expression_no_borrow(
            [[XX_mul_3], [YY_mul_2]],
            [[false], [true]],
            [[D, X3], [YY_mul_2, YY_mul_2]],
            [[false, true], [false, false]],
            [],
            []
        );
        let (_, Z3): (BigNum<N, Params>, BigNum<N, Params> ) = BigNum::__compute_quadratic_expression_no_borrow([[Y1]], [[false]], [[Z1, Z1]], [[false, false]], [], []);
        (
            CurveJ { x: X3, y: Y3, z: Z3 }, JTranscript { lambda_numerator: XX_mul_3, x3: X3, y3: Y3, z3: Z3 }
        )
    }

    /**
     * @brief Perform an ecc scalar multiplication and output the generated AffineTranscript
     **/
    unconstrained fn mul<let NScalarSlices: u32>(
        self,
        scalar: ScalarField<NScalarSlices>
    ) -> (Self, [AffineTranscript<N, Params>]) where Params: BigNumParamsTrait<N> {
        let mut transcript: [JTranscript<N, Params>] = &[];
        let T: PointTable<N, Params> = PointTable::new(self);
        for i in 0..8 {
            transcript = transcript.push_back(T.transcript[i]);
        }
        let mut accumulator = T.get(scalar.base4_slices[0]);

        for i in 1..NScalarSlices {
            for _ in 0..4 {
                let op = accumulator.dbl();
                accumulator = op.0;
                transcript = transcript.push_back(op.1);
            }
            let op = accumulator.incomplete_add(T.get(scalar.base4_slices[i]));
            transcript = transcript.push_back(op.1);
            accumulator = op.0;
        }

        if scalar.skew {
            let op = accumulator.incomplete_add(self.neg());
            transcript = transcript.push_back(op.1);
            accumulator = op.0;
        } else {
            transcript = transcript.push_back(JTranscript::new());
        }

        let affine_transcript: [AffineTranscript<N, Params>] = AffineTranscript::from_jacobian_transcript(transcript);

        // let mut inverses: [BigNum<N, Params>] = &[];

        // for i in 0..(9 + (NScalarSlices - 1) * 5) {
        //     inverses = inverses.push_back(transcript[i].z3);
        // }
        // println(f"inverting");

        // let ff = inverses[0];
        // println(f"FIRST INVERSE = {ff}");
        // batch_invert(&mut inverses);
        // let ff = inverses[0];

        // println(f"BATCH OUTPUT FIRST INVERSE = {ff}");

        // let mut affine_transcript: [AffineTranscript<N, Params>] = &[];
        // let ff = affine_transcript.len();
        // println(f"AFFINE TX LENGTH = {ff}");
        // for i in 0..(9 + (NScalarSlices - 1) * 5) {
        //     println(f"j = {i}");
        //     let z_inv = inverses[i];

        //     let lambda = transcript[i].lambda_numerator.__mulmod(z_inv);
        //     let zz = z_inv.__mulmod(z_inv);
        //     let zzz = zz.__mulmod(z_inv);
        //     let x3 = transcript[i].x3.__mulmod(zz);
        //     let y3 = transcript[i].y3.__mulmod(zzz);
        //     affine_transcript = affine_transcript.push_back(AffineTranscript{ lambda, x3, y3 });
        // }
        (accumulator, affine_transcript)
    }
}

// TODO: this should probably be in bignum
unconstrained pub fn batch_invert<let N: u32, Params>(x: &mut [BigNum<N, Params>]) where Params: BigNumParamsTrait<N> {
    let mut accumulator: BigNum<N, Params> = BigNum::one();

    let mut temporaries: [BigNum<N, Params>] = &[];
    for i in 0..x.len() {
        temporaries = temporaries.push_back(accumulator);
        if (x[i].__is_zero() == false) {
            accumulator = accumulator.__mulmod(x[i]);
        }
    }

    accumulator = accumulator.__invmod();
    let mut T0: BigNum<N, Params> = BigNum::new();
    for i in 0..x.len() {
        let idx = x.len() - 1 - i;
        if (x[idx].__is_zero() == false) {
            T0 = accumulator.__mulmod(temporaries[idx]);
            accumulator = accumulator.__mulmod(x[idx]);
            x[idx] = T0;
        }
    }
}

// TODO: this should probably be in bignum
unconstrained pub fn batch_invert_arr<let N: u32, Params, let S: u64>(mut x: [BigNum<N, Params>; S]) -> [BigNum<N, Params>; S] where Params: BigNumParamsTrait<N> {
    let mut accumulator: BigNum<N, Params> = BigNum::one();

    let mut temporaries: [BigNum<N, Params>] = &[];
    for i in 0..x.len() {
        temporaries = temporaries.push_back(accumulator);
        if (x[i].__is_zero() == false) {
            accumulator = accumulator.__mulmod(x[i]);
        }
    }

    accumulator = accumulator.__invmod();
    let mut T0: BigNum<N, Params> = BigNum::new();
    for i in 0..x.len() {
        let idx = x.len() - 1 - i;
        if (x[idx].__is_zero() == false) {
            T0 = accumulator.__mulmod(temporaries[idx]);
            accumulator = accumulator.__mulmod(x[idx]);
            x[idx] = T0;
        }
    }
    x
}
