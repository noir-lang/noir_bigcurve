use dep::bignum::ArrayX;
use dep::bignum::BigNum;
use dep::bignum::BNExpressionInput;
use dep::bignum::BigNumParamsTrait;
// use dep::bignum::BigNumParams;
use dep::bignum::U60Repr;
use crate::scalar_field::ScalarField;

struct CurveJ<N, Params> {
    x: BigNum<N, Params>,
    y: BigNum<N, Params>,
    z: BigNum<N, Params>,
}

struct PointTable<N, Params> {
    x: [[Field; N]; 16],
    y: [[Field; N]; 16],
    z: [[Field; N]; 16],
    transcript: [Tx<N, Params>; 8]
}

struct Tx<N, Params> {
    lambda_numerator: BigNum<N, Params>,
    lambda_denominator: BigNum<N, Params>,
    x3: BigNum<N, Params>,
    y3: BigNum<N, Params>,
    z3: BigNum<N, Params>
}
impl<N, Params> Tx<N, Params> {
    fn new() -> Self {
        Tx {
            lambda_numerator: BigNum::new(),
            lambda_denominator: BigNum::new(),
            x3: BigNum::new(),
            y3: BigNum::new(),
            z3: BigNum::new()
        }
    }
}

struct AffineTranscript<N, Params> {
    lambda: BigNum<N, Params>,
    x3: BigNum<N, Params>,
    y3: BigNum<N, Params>
}

impl<N, Params> PointTable<N, Params> {
    fn new(P: CurveJ<N, Params>) -> Self where Params: BigNumParamsTrait<N> {
        let mut result = PointTable { x: [[0; N]; 16], y: [[0; N]; 16], z: [[0; N]; 16], transcript: [Tx::new(); 8] };

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
            let op = D2.add(A);
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

    fn get(self, idx: u8) -> CurveJ<N, Params> where Params: BigNumParamsTrait<N> {
        let x: BigNum<N, Params> = BigNum { limbs: self.x[idx] };
        let y: BigNum<N, Params> = BigNum { limbs: self.y[idx] };
        let z: BigNum<N, Params> = BigNum { limbs: self.z[idx] };
        CurveJ { x, y, z }
    }
}

impl<N, Params> std::cmp::Eq for CurveJ<N, Params> where Params: BigNumParamsTrait<N> {
    fn eq(self, other: Self) -> bool {
        // x = X/ZZ
        // y = Y/ZZZ

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
        (x_lhs == x_rhs) & (y_lhs == y_rhs)
    }
}
impl<N, Params> CurveJ<N, Params> {
    fn new() -> Self {
        CurveJ { x: BigNum::new(), y: BigNum::new(), z: BigNum::new() }
    }

    fn neg(self) -> Self where Params: BigNumParamsTrait<N> {
        CurveJ { x: self.x, y: self.x.__negate(), z: self.z }
    }
    fn add(
        self,
        p2: CurveJ<N, Params>
    ) -> (CurveJ<N, Params>, Tx<N, Params>) where Params: BigNumParamsTrait<N> {
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
        let P = U2.__submod(U1);
        let R = S2.__submod(S1);
        let PP = P.__mulmod(P);
        let RR = R.__mulmod(R);

        let X3 = RR.__submod((U1.__addmod(U2).__mulmod(PP)));
        let Y3 = R.__mulmod(U1.__mulmod(PP).__submod(X3)).__submod(S1.__mulmod(PP.__mulmod(P)));
        let Z3 = Z1.__mulmod(Z2).__mulmod(P);
        (
            CurveJ { x: X3, y: Y3, z: Z3 }, Tx { lambda_numerator: R, lambda_denominator: Z3, x3: X3, y3: Y3, z3: Z3 }
        )
    }

    fn dbl(self) -> (Self, Tx<N, Params>) where Params: BigNumParamsTrait<N> {
        // TODO: once we have linear expressions as unconstrained fns, replace this with something that has no addmods, submods
        let X1 = self.x;
        let Y1 = self.y;
        let Z1 = self.z;
        let A = X1.__mulmod(X1);
        let B = Y1.__mulmod(Y1);
        let C = B.__mulmod(B);
        let mut D = X1.__addmod(B);
        D = D.__mulmod(D).__submod(A).__submod(C);
        D = D.__addmod(D);
        let E = A.__addmod(A).__addmod(A);
        let F = E.__mulmod(E);
        let X3 = F.__submod(D.__addmod(D));
        let mut C8 = C.__addmod(C);
        C8 = C8.__addmod(C8);
        C8 = C8.__addmod(C8);
        let Y3 = E.__mulmod(D.__submod(X3)).__submod(C8);
        let mut Z3 = Y1.__mulmod(Z1);
        Z3 = Z3.__addmod(Z3);
        (
            CurveJ { x: X3, y: Y3, z: Z3 }, Tx { lambda_numerator: A, lambda_denominator: Z3, x3: X3, y3: Y3, z3: Z3 }
        )
    }

    unconstrained fn mul<NScalarSlices>(
        self,
        scalar: ScalarField<NScalarSlices>
    ) -> (Self, [AffineTranscript<N, Params>]) where Params: BigNumParamsTrait<N> {
        let mut transcript: [Tx<N, Params>] = &[];
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
            let op = accumulator.add(T.get(scalar.base4_slices[i]));
            transcript = transcript.push_back(op.1);
            accumulator = op.0;
        }

        if scalar.skew {
            let op = accumulator.add(self.neg());
            transcript = transcript.push_back(op.1);
            accumulator = op.0;
        } else {
            transcript = transcript.push_back(Tx::new());
        }

        let mut inverses: [BigNum<N, Params>] = &[];

        for i in 0..(9 + (NScalarSlices - 1) * 5) {
            inverses = inverses.push_back(transcript[i].lambda_denominator);
            inverses = inverses.push_back(transcript[i].z3);
        }

        batch_invert(&mut inverses);

        let mut affine_transcript: [AffineTranscript<N, Params>] = &[];
        for i in 0..(9 + (NScalarSlices - 1) * 5) {
            let lambda = transcript[i].lambda_numerator * inverses[2 * i];
            let z_inv = inverses[2 * i + 1];
            let zz = z_inv.__mulmod(z_inv);
            let zzz = zz.__mulmod(z_inv);
            let x3 = transcript[i].x3 * zz;
            let y3 = transcript[i].y3 * zzz;
            affine_transcript = affine_transcript.push_back(AffineTranscript{ lambda, x3, y3 });
        }
        (accumulator, affine_transcript)
    }
}

fn batch_invert<N, Params>(x: &mut [BigNum<N, Params>]) where Params: BigNumParamsTrait<N> {
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
            T0 = accumulator.__mulmod(temporaries[i]);
            accumulator = accumulator.__mulmod(x[i]);
            x[idx] = T0;
        }
    }
}
