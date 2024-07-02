use dep::bignum::BigNum;

mod scalar_field;
mod curve;
mod curve_jac;
mod test_data;

use crate::curve::BigCurve;
use crate::curve_jac::JTranscript;
use crate::curve_jac::AffineTranscript;
use crate::curve_jac::CurveJ;
use crate::scalar_field::ScalarField;

use dep::bignum::fields::bn254Fq::BNParams as BNParams;

type Fq = BigNum<3, BNParams>;

fn main(x: Field) {
    //   let two = BigNum::one().__addmod(BigNum::one());
    let mut foo: [Field; 12] = [0; 12];
    foo[0] = x;
    for i in 1..12 {
        foo[i] = foo[i-1]* x;
    }
    let P: BigCurve<Fq> = BigCurve { x: BigNum { limbs: [foo[0], foo[1], foo[2]] }, y: BigNum { limbs: [foo[3], foo[4], foo[5]] } };
    let Q: BigCurve<Fq> = BigCurve { x: BigNum { limbs: [foo[6], foo[7], foo[8]] }, y: BigNum { limbs: [foo[9], foo[10], foo[11]] } };

    let scalar: ScalarField<64> = ScalarField::from(x); // p - 2 ? 
    let transcript = get_transcript(CurveJ { x: P.x, y: P.y, z: BigNum::one() }, scalar);

    // let mut A = P;
    // for i in 0..101 {
    //     for j in 0..3 {
    //         std::as_witness(transcript[i].lambda.limbs[j]);
    //         std::as_witness(transcript[i].x3.limbs[j]);
    //         std::as_witness(transcript[i].y3.limbs[j]);
    //     }
    //     A = A.incomplete_add_with_hint(P, transcript[i]);
    // }
    // println(f"{A}");
    let result = P.mul_with_hint(scalar, transcript);
    // -2
    let mut expected: BigCurve<Fq> = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] }
    };
    expected.y = BigNum::new() - expected.y;
    assert(result == expected);

    let scalar2: ScalarField<64> = ScalarField::from(x * x); // p - 2 ? 
    let transcript2 = get_transcript(CurveJ { x: Q.x, y: Q.y, z: BigNum::one() }, scalar);
    let result = Q.mul_with_hint(scalar2, transcript2);
    // -2
    let mut expected: BigCurve<Fq> = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] }
    };
    expected.y = BigNum::new() - expected.y;
    assert(result.x.eq(expected.x));
    assert(result.y.eq(expected.y));
}

unconstrained fn foo(P: CurveJ<Fq>, scalar: ScalarField<64>, Q: CurveJ<Fq>, K: CurveJ<Fq>) -> bool {
    let s = (P.mul(scalar));
    let ff = s.0;
    println(f"let transcript: AffineTranscript<N, Params> = {ff}");
    assert(s.0.eq(K.neg()));
    Q.eq(s.0)
}

unconstrained fn get_transcript(P: CurveJ<Fq>, scalar: ScalarField<64>) -> [AffineTranscript<Fq>; 324] {
    let res = P.mul(scalar);
    let transcript = res.1;
    println(f"let transcript: AffineTranscript<N, Params> = {transcript}");
    let ff = transcript.len();
    println(f"transcript len = {ff}");
    transcript.as_array()
}

#[test]
fn test_mul() {
    let two = BigNum::one().__addmod(BigNum::one());
    let P: BigCurve<Fq> = BigCurve { x: BigNum::one(), y: two };

    let scalar: ScalarField<64> = ScalarField::from(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff); // p - 2
    let transcript = test_data::get_transcript();

    let result = P.mul_with_hint(scalar, transcript);

    // -2
    let mut expected: BigCurve<Fq> = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] }
    };
    expected.y = BigNum::new() - expected.y;
    assert(result.x.eq(expected.x));
    assert(result.y.eq(expected.y));
}

// MUL RESULT = CurveJ { x: BigNum { limbs: [0xa47823fd000eda1bbfc18418eb3d99, 0x0ca4f07e34bbe4f5b1033127aa8d86, 0x04c1] }, 
// y: BigNum { limbs: [0x11528374493623ffae4630c74901df, 0x4db72e5c95274f7137872f19e6baa8, 0x068a] }, 
// z: BigNum { limbs: [0xae338287d1de4127e865f3f095cf8a, 0x109f23b240924ec0446d8f7aacbe49, 0x2448] } }
// -P = CurveJ { x: BigNum { limbs: [0x5f10, 0x00, 0x00] }, y: BigNum { limbs: [0x73db80, 0x00, 0x00] }, z: BigNum { limbs: [0x816a916871ca8d3c208c16d87cfcab, 0x4e72e131a029b85045b68181585d97, 0x3064] } }
// P = CurveJ { x: BigNum { limbs: [0x01, 0x00, 0x00] }, y: BigNum { limbs: [0x02, 0x00, 0x00] }, z: BigNum { limbs: [0x01, 0x00, 0x00] } }
#[test]
fn test_mul_jac() {
    let scalar_multiplier = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000; // p - 1
    let two = BigNum::one().__addmod(BigNum::one());
    let P: CurveJ<Fq> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };

    let scalar: ScalarField<64> = ScalarField::from(scalar_multiplier);

    let expected = P.incomplete_add(P.dbl().0.neg()).0;
    let result = foo(P, scalar, expected, P);
    assert(result == true);
}

#[test]
fn test_add_dbl() {
    let two = BigNum::one().__addmod(BigNum::one());

    let P: CurveJ<Fq> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };
    let lhs = ((P.dbl().0).dbl()).0;
    let rhs = P.dbl().0.incomplete_add(P).0.incomplete_add(P).0;
    assert(lhs == rhs);
}

#[test]
fn test_transcript() {
    let two = BigNum::one().__addmod(BigNum::one());

    let P: CurveJ<Fq> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };

    let P2 = P.dbl();

    let Z_inverse = P2.1.z3.__invmod();

    let lambda = P2.1.lambda_numerator.__mulmod(Z_inverse);

    let lhs = (lambda.__addmod(lambda)).__mulmod(P.y);
    let rhs = (P.x.__addmod(P.x).__addmod(P.x)).__mulmod(P.x);

    assert(lhs.eq(rhs));

    let X2 = P2.1.x3;
    let Y2 = P2.1.y3;
    let ZZ = Z_inverse.__mulmod(Z_inverse);
    let ZZZ = ZZ.__mulmod(Z_inverse);

    let x2 = X2.__mulmod(ZZ);
    let y2 = Y2.__mulmod(ZZZ);

    // ### test add transcript
    let P3 = P.incomplete_add(P2.0);
    let Z_inverse = P3.1.z3.__invmod();

    let lambda = P3.1.lambda_numerator.__mulmod(Z_inverse);

    let x1 = P.x;
    let y1 = P.y;

    let lhs = lambda.__mulmod(x2.__submod(x1));
    let rhs = y2.__submod(y1);
    assert(lhs.eq(rhs));
}

#[test]
fn test_double_with_hint() {
    let two = BigNum::one().__addmod(BigNum::one());

    let P: CurveJ<Fq> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };

    let P2 = P.dbl();

    let P_affine: BigCurve<Fq> = BigCurve { x: P.x, y: P.y };

    let Z_inverse = P2.1.z3.__invmod();

    let lambda = P2.1.lambda_numerator.__mulmod(Z_inverse);

    let X3 = P2.1.x3;
    let Y3 = P2.1.y3;
    let ZZ = Z_inverse.__mulmod(Z_inverse);
    let ZZZ = ZZ.__mulmod(Z_inverse);

    let x3 = X3.__mulmod(ZZ);
    let y3 = Y3.__mulmod(ZZZ);

    let transcript: AffineTranscript<Fq> = AffineTranscript { lambda, x3, y3 };
    let P2_affine = P_affine.double_with_hint(transcript);

    assert(P2_affine.x.eq(x3));
    assert(P2_affine.y.eq(y3));
}

#[test]
fn test_incomplete_add_with_hint() {
    let two = BigNum::one().__addmod(BigNum::one());

    let P: CurveJ<Fq> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };

    // Q = 2P
    let Q: CurveJ<Fq> = CurveJ {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        z: BigNum::one()
    };

    let R = P.incomplete_add(Q);

    let P_affine: BigCurve<Fq> = BigCurve { x: P.x, y: P.y };
    let Q_affine: BigCurve<Fq> = BigCurve { x: Q.x, y: Q.y };

    let Z_inverse = R.1.z3.__invmod();

    let lambda = R.1.lambda_numerator.__mulmod(Z_inverse);

    let X3 = R.1.x3;
    let Y3 = R.1.y3;
    let ZZ = Z_inverse.__mulmod(Z_inverse);
    let ZZZ = ZZ.__mulmod(Z_inverse);

    let x3 = X3.__mulmod(ZZ);
    let y3 = Y3.__mulmod(ZZZ);

    let transcript: AffineTranscript<Fq> = AffineTranscript { lambda, x3, y3 };
    let P2_affine = P_affine.incomplete_add_with_hint(Q_affine, transcript);

    assert(P2_affine.x.eq(x3));
    assert(P2_affine.y.eq(y3));
    let two = BigNum::one().__addmod(BigNum::one());

    let P: CurveJ<Fq> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };

    let lhs = P.dbl().0.dbl().0;
    let rhs = P.dbl().0.incomplete_add(P).0.incomplete_add(P).0;
    assert(lhs.eq(rhs));
}

unconstrained fn make_inverses(inverses: [Fq; 8]) -> [Fq; 8] {
    let mut result: [Fq; 8] = [BigNum::new(); 8];
    for i in 0..8 {
        result[i] = inverses[i];
    }
    result
}

unconstrained fn invert_temp(x: [Fq; 8]) -> [Fq; 8] {
    let mut fff= x.as_slice();
    BigNum::__batch_invert(&mut fff);
    fff.as_array()
}

#[test]
fn test_make_table() {
    let two = BigNum::one().__addmod(BigNum::one());
    let P: CurveJ<Fq> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };

    let mut transcript: [curve_jac::JTranscript<Fq>] = &[];
    let T: curve_jac::PointTable<Fq> = curve_jac::PointTable::new(P);
    for i in 0..8 {
        transcript = transcript.push_back(T.transcript[i]);
    }

    let mut inverses: [Fq; 8] = [BigNum::new(); 8];

    for i in 0..8 {
        inverses[i] = transcript[i].z3;
    }
    println(f"inverting");

    let ff = inverses[0];
    inverses = invert_temp(inverses);

    let mut affine_transcript: [AffineTranscript<Fq>; 8] = [AffineTranscript::new(); 8];
    let ff = affine_transcript.len();
    println(f"AFFINE TX LENGTH = {ff}");
    for i in 0..8 {
        println(f"j = {i}");
        let z_inv = inverses[i];

        let lambda = transcript[i].lambda_numerator.__mulmod(z_inv);
        let zz = z_inv.__mulmod(z_inv);
        let zzz = zz.__mulmod(z_inv);
        let x3 = transcript[i].x3.__mulmod(zz);
        let y3 = transcript[i].y3.__mulmod(zzz);
        affine_transcript[i] = AffineTranscript{ lambda, x3, y3 };
    }

    let P_affine: BigCurve<Fq> = BigCurve { x: P.x, y: P.y };

    let affine_point_table: curve::PointTable<Fq> = curve::PointTable::new_with_hint(P_affine, affine_transcript);
}
