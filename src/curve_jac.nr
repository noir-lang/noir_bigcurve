use dep::bignum::BigNum;
use dep::bignum::BigNumTrait;
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
struct CurveJ<BigNum> {
    x: BigNum,
    y: BigNum,
    z: BigNum,
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
    unconstrained fn from_jacobian_transcript(j_tx: [JTranscript<BigNum>]) -> [AffineTranscript<BigNum>] {
        let mut result: [AffineTranscript<BigNum>] = &[];

        let mut inverses: [BigNum] = &[];
        for i in 0..j_tx.len() {
            inverses = inverses.push_back(j_tx[i].z3);
        }

        // tadaa
        BigNum::__batch_invert(&mut inverses);

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
            transcript: [JTranscript::new(); 8]
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
    unconstrained fn new(P: CurveJ<BigNum>) -> Self {
        let mut result = PointTable {
            x: [BigNum::new(); 16],
            y: [BigNum::new(); 16],
            z: [BigNum::new(); 16],
            transcript: [JTranscript::new(); 8]
        };
        let op = P.dbl();
        let D2 = op.0;
        result.transcript[0] = op.1;
        result.x[7] = P.x;
        result.y[7] = P.y.__negate();
        result.z[7] = P.z;
        result.x[8] = P.x;
        result.y[8] = P.y;
        result.z[8] = P.z;
        let mut A = P;
        for i in 1..8 {
            let op = D2.incomplete_add(A);
            A = op.0;
            result.transcript[i] = op.1;
            result.x[8+i] = A.x;
            result.y[8+i] = A.y;
            result.z[8+i] = A.z;
            result.x[7-i] = A.x;
            result.y[7-i] = A.y.__negate();
            result.z[7-i] = A.z;
        }

        result
    }

    /**
     * @brief get a value out of the lookup table
     **/
    unconstrained fn get(self, idx: u8) -> CurveJ<BigNum> {
        CurveJ { x: self.x[idx], y: self.y[idx], z: self.z[idx] }
    }
}

/**
 * @brief are two Jacobian points equal?
 * @description only really used in tests for now.
 **/
impl<BigNum> std::cmp::Eq for CurveJ<BigNum> where BigNum: BigNumTrait {
    fn eq(self, other: Self) -> bool {
        // if x == y then (X1 / Z1 * Z1 = X2 / Z2 * Z2)
        //            and (Y1 / Z1 * Z1 * Z1 = Y2 / Z2 * Z2 * Z2)

        // we can check this by validating that:
        // X1 * Z2 * Z2 == X2 * Z1 * Z1
        // Y1 * Z2 * Z2 * Z2 == Y2 * Z1 * Z1 * Z1
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
        x_lhs.eq(x_rhs) & y_lhs.eq(y_rhs)
    }
}

impl<BigNum> CurveJ<BigNum> where BigNum: BigNumTrait {
    /**
     * @brief negate a point
     **/
    fn neg(self) -> Self {
        CurveJ { x: self.x, y: self.y.__negate(), z: self.z }
    }

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
    unconstrained fn incomplete_add(self, p2: CurveJ<BigNum>) -> (CurveJ<BigNum>, JTranscript<BigNum>) {
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
        let Z1Z2 = Z1.__mulmod(Z2);
        let (_, Z3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
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
    unconstrained fn dbl(self) -> (Self, JTranscript<BigNum>) {
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
        let (_, X3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression(
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
        let (_, Z3): (BigNum, BigNum ) = BigNum::__compute_quadratic_expression([[Y1]], [[false]], [[Z1, Z1]], [[false, false]], [], []);
        (
            CurveJ { x: X3, y: Y3, z: Z3 }, JTranscript { lambda_numerator: XX_mul_3, x3: X3, y3: Y3, z3: Z3 }
        )
    }

    /**
     * @brief Perform an ecc scalar multiplication and output the generated AffineTranscript
     **/
    unconstrained fn mul<let NScalarSlices: u32>(self, scalar: ScalarField<NScalarSlices>) -> (Self, [AffineTranscript<BigNum>]) {
        let mut transcript: [JTranscript<BigNum>] = &[];
        let T = PointTable::new(self);
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

        let affine_transcript: [AffineTranscript<BigNum>] = AffineTranscript::from_jacobian_transcript(transcript);

        (accumulator, affine_transcript)
    }

    /**
     * @brief Perform an ecc scalar multiplication and output the generated AffineTranscript
     **/
    unconstrained fn msm<let Size: u32, let NScalarSlices: u32>(
        points: [Self; Size],
        scalars: [ScalarField<NScalarSlices>; Size]
    ) -> (Self, [AffineTranscript<BigNum>]) {
        let mut transcript: [JTranscript<BigNum>] = &[];
        let mut tables: [PointTable<BigNum>; Size] = [PointTable::empty(); Size];

        for i in 0..Size {
            tables[i] = PointTable::new(points[i]);
            for j in 0..8 {
                transcript = transcript.push_back(tables[i].transcript[j]);
            }
        }

        let mut accumulator = tables[0].get(scalars[0].base4_slices[0]);
        for i in 1..Size {
            let op = accumulator.incomplete_add(tables[i].get(scalars[i].base4_slices[0]));
            transcript = transcript.push_back(op.1);
            accumulator = op.0;
        }
        for i in 1..NScalarSlices {
            for _ in 0..4 {
                let op = accumulator.dbl();
                accumulator = op.0;
                transcript = transcript.push_back(op.1);
            }
            for j in 0..Size {
                let op = accumulator.incomplete_add(tables[j].get(scalars[j].base4_slices[i]));
                transcript = transcript.push_back(op.1);
                accumulator = op.0;
            }
        }

        for i in 0..Size {
            if scalars[i].skew {
                let op = accumulator.incomplete_add(points[i].neg());
                transcript = transcript.push_back(op.1);
                accumulator = op.0;
            } else {
                transcript = transcript.push_back(JTranscript::new());
            }
        }

        let affine_transcript: [AffineTranscript<BigNum>] = AffineTranscript::from_jacobian_transcript(transcript);

        (accumulator, affine_transcript)
    }
}

// TODO: this should probably be in bignum
unconstrained pub fn batch_invert<BigNum>(x: &mut [BigNum]) where BigNum: BigNumTrait {
    let mut accumulator: BigNum = BigNum::one();

    let mut temporaries: [BigNum] = &[];
    for i in 0..x.len() {
        temporaries = temporaries.push_back(accumulator);
        if (x[i].__is_zero() == false) {
            accumulator = accumulator.__mulmod(x[i]);
        }
    }

    accumulator = accumulator.__invmod();
    let mut T0: BigNum = BigNum::new();
    for i in 0..x.len() {
        let idx = x.len() - 1 - i;
        if (x[idx].__is_zero() == false) {
            T0 = accumulator.__mulmod(temporaries[idx]);
            accumulator = accumulator.__mulmod(x[idx]);
            x[idx] = T0;
        }
    }
}
