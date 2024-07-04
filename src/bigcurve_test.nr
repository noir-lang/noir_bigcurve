use dep::bignum::BigNum;

use crate::BigCurve;
use crate::CurveParamsTrait;

use crate::curve_jac;
use crate::curve_jac::JTranscript;
use crate::curve_jac::AffineTranscript;
use crate::curve_jac::CurveJ;
use crate::scalar_field::ScalarField;
use crate::PointTable;

use dep::bignum::fields::bn254Fq::BNParams as BNParams;

type Fq = BigNum<3, BNParams>;
struct BN254Params {
}

impl CurveParamsTrait<BigNum<3, BNParams>> for BN254Params  {
    fn one() -> [BigNum<3, BNParams>; 2] {
        let mut one: Fq = BigNum::new();
        one.limbs[0] = 1;
        let mut two = one;
        two.limbs[0] = 2;
        [one, two]
    }

    fn offset_generator() -> [BigNum<3, BNParams>; 2] {
        [
            BigNum { limbs: [0xf30f376a22bd3695abf4dcdfed66c6, 0x80d7bbcaebb13bbabfc30184f59912, 0x0cfb] },
            BigNum { limbs: [0xe53572d644c1e06f80ab52ef02fa2f, 0xa40d9e20debde026e47f8bfc4d3c41, 0x07f6] }
        ]
    }

    fn offset_generator_final() -> [BigNum<3, BNParams>; 2] {
        [
            BigNum { limbs: [0x0b672a3489895d47157f096e077348, 0x29f5f5b786660171ae9ad36f6db594, 0x15f1] },
            BigNum { limbs: [0x6e4553aa3ae998fcd27ca8a17188ef, 0xb3193f7f0a731913174831ca905feb, 0x21ff] }
        ]
    }

    fn b() -> BigNum<3, BNParams> {
        BigNum { limbs: [3,0,0]}
    }

    fn a() -> BigNum<3, BNParams> {
        BigNum { limbs: [0,0,0]}
    }
}

type BN254 = BigCurve<Fq, BN254Params>;
type BN254J = CurveJ<Fq, BN254Params>;

fn main(x: Field) {
    let mut foo: [Field; 12] = [0; 12];
    foo[0] = x;
    for i in 1..12 {
        foo[i] = foo[i-1]* x;
    }
    let P: BN254 = BigCurve {
        x: BigNum { limbs: [foo[0], foo[1], foo[2]] },
        y: BigNum { limbs: [foo[3], foo[4], foo[5]] },
        is_infinity: false
    };

    let scalar: ScalarField<64> = ScalarField::from(x); // p - 2 ? 
    let transcript = get_transcript(CurveJ::from(P), scalar);
    // 30768
    // 31020
    let mut A = P;
    for i in 0..101 {
        for j in 0..3 {
            std::as_witness(transcript[i].lambda.limbs[j]);
            std::as_witness(transcript[i].x3.limbs[j]);
            std::as_witness(transcript[i].y3.limbs[j]);
        }
        A = A.double_with_hint(transcript[i]);
    }
    // println(f"{A}");
    // let result = P.mul_with_hint(scalar, transcript);
    // // -2
    // let mut expected: BN254 = BigCurve {
    //     x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
    //     y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] }
    // };
    // expected.y = BigNum::new() - expected.y;
    // assert(result == expected);
    // let scalar2: ScalarField<64> = ScalarField::from(x * x); // p - 2 ? 
    // let transcript2 = get_transcript(CurveJ { x: Q.x, y: Q.y, z: BigNum::one() }, scalar);
    // let result = Q.mul_with_hint(scalar2, transcript2);
    // // -2
    // let mut expected: BN254 = BigCurve {
    //     x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
    //     y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] }
    // };
    // expected.y = BigNum::new() - expected.y;
    // assert(result.x.eq(expected.x));
    // assert(result.y.eq(expected.y));
}

unconstrained fn evaluate_mul(P: BN254J, scalar: ScalarField<64>, Q: BN254J, K: BN254J) -> bool {
    let s = (P.mul(scalar));
    assert(s.0.eq(K.neg()));
    Q.eq(s.0)
}

unconstrained fn get_msm_transcript(
    P: BN254J,
    Q: BN254J,
    scalar1: ScalarField<64>,
    scalar2: ScalarField<64>
) -> [AffineTranscript<Fq>; 399] {
    let s = (CurveJ::msm([P, Q], [scalar1, scalar2]));
    let ff = s.1;
    println(f"let transcript: AffineTranscript<N, Params> = {ff}");
    ff.as_array()
}

unconstrained fn get_transcript(P: BN254J, scalar: ScalarField<64>) -> [AffineTranscript<Fq>; 326] {
    let res = P.mul(scalar);
    let transcript = res.1;
    println(f"let transcript: AffineTranscript<N, Params> = {transcript}");
    let ff = transcript.len();
    println(f"transcript len = {ff}");
    transcript.as_array()
}

#[test]
fn test_mul() {
    let P: BN254 = BigCurve::one();

    let scalar: ScalarField<64> = ScalarField::from(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff); // p - 2

    let transcript = get_transcript(CurveJ::from(P), scalar);

    let result = P.mul_with_hint(scalar, transcript);

    // -2
    let mut expected: BN254 = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        is_infinity: false
    };
    expected.y = BigNum::new() - expected.y;
    assert(result.x.eq(expected.x));
    assert(result.y.eq(expected.y));
}

#[test]
fn test_offset_foo() {
    let P = BigCurve {
        x: BigNum { limbs: [0x0b672a3489895d47157f096e077348, 0x29f5f5b786660171ae9ad36f6db594, 0x15f1] },
        y: BigNum { limbs: [0x6e4553aa3ae998fcd27ca8a17188ef, 0xb3193f7f0a731913174831ca905feb, 0x21ff] },
        is_infinity: false
    };
    let Q_inv = BigCurve {
        x: BigNum { limbs: [0x0b672a3489895d47157f096e077348, 0x29f5f5b786660171ae9ad36f6db594, 0x15f1] },
        y: BigNum { limbs: [0x13253dbe36e0f43f4e0f6e370b7458, 0x9b59a1b295b69f3d2e6e4fb6c7fdac, 0x0e64] },
        is_infinity: false
    };
    let Q= BigCurve {
        x: BigNum { limbs: [0x0b672a3489895d47157f096e077348, 0x29f5f5b786660171ae9ad36f6db594, 0x15f1] },
        y: BigNum { limbs: [0x6e4553aa3ae998fcd27ca8a17188ef, 0xb3193f7f0a731913174831ca905feb, 0x21ff] },
        is_infinity: false
    };

    let R: BN254 = P.sub(Q);
    println(f"R = {R}");
    assert(R.is_infinity == true);
}

#[test]
fn test_mul_by_0() {
    let P: BN254 = BigCurve::one();

    let scalar: ScalarField<64> = ScalarField::from(0); // p - 2

    let foo: Field = ScalarField::into(scalar);
    assert(foo == 0);
    let transcript = get_transcript(CurveJ::from(P), scalar);

    let result = P.mul_with_hint(scalar, transcript);
    println(f"RESULT = {result}");
    // -2
    assert(result.is_infinity == true);
}

#[test]
fn test_mul_a_point_at_infinity() {
    let P: BN254 = BigCurve::point_at_infinity();

    let scalar: ScalarField<64> = ScalarField::from(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff); // p - 2

    let transcript = get_transcript(CurveJ::from(P), scalar);

    let result = P.mul_with_hint(scalar, transcript);
    println(f"RESULT = {result}");
    // -2
    assert(result.is_infinity == true);
}

// N.B. cannot test because stack too deep!
#[test]
fn test_linear_expression() {
    let One: BN254 = BigCurve::one();
    let Two: BN254 = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        is_infinity: false
    };

    let p_minus_2 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff; // p - 2
    let p_minus_6 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffffb; // p - 6
    let scalar2: ScalarField<64> = ScalarField::from(p_minus_2);
    let scalar6: ScalarField<64> = ScalarField::from(p_minus_6);

    let result = BigCurve::evaluate_linear_expression([One], [scalar2], []);
    let expected = Two.neg();
    assert(result == expected);
}

// N.B. cannot test because stack too deep!
#[test]
fn test_msm() {
    let One: BN254 = BigCurve::one();
    let Two: BN254 = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        is_infinity: false
    };

    let p_minus_2 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff; // p - 2
    let p_minus_6 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffffb; // p - 6
    let scalar2: ScalarField<64> = ScalarField::from(p_minus_2);
    let scalar6: ScalarField<64> = ScalarField::from(p_minus_6);

    let transcript = get_msm_transcript(CurveJ::from(One), CurveJ::from(Two), scalar6, scalar2);
    let result = BigCurve::msm_with_hint([One, Two.neg()], [scalar6, scalar2], transcript);
    let expected = Two.neg();
    assert(result == expected);
}

#[test]
fn test_mul_jac() {
    let scalar_multiplier = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000; // p - 1
    let P: BN254J = CurveJ::one();

    let scalar: ScalarField<64> = ScalarField::from(scalar_multiplier);

    let expected = P.incomplete_add(P.dbl().0.neg()).0;
    let result = evaluate_mul(P, scalar, expected, P);
    assert(result == true);
}

unconstrained fn test_msm_jac_impl(scalars: [ScalarField<64>; 2]) {
    let One: BN254J = CurveJ::one();
    let Two: BN254J = CurveJ {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        z: BigNum::one(),
        is_infinity: false
    };
    let result = CurveJ::msm([One, Two.neg()], scalars);
    let expected = Two.neg();
    assert(result.0 == expected);
}

#[test]
fn test_msm_jac() {
    let p_minus_2 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff; // p - 2
    let p_minus_6 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffffb; // p - 6
    let scalar2: ScalarField<64> = ScalarField::from(p_minus_2);
    let scalar6: ScalarField<64> = ScalarField::from(p_minus_6);

    test_msm_jac_impl([scalar6, scalar2]);
}

#[test]
fn test_add_dbl() {
    let P: BN254J = CurveJ::one();
    let lhs = ((P.dbl().0).dbl()).0;
    let rhs = P.dbl().0.incomplete_add(P).0.incomplete_add(P).0;
    assert(lhs == rhs);
}

#[test]
fn test_transcript() {
    let P: BN254J = CurveJ::one();

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
    let P: BN254J = CurveJ::one();

    let P2 = P.dbl();

    let P_affine: BN254 = BigCurve::one();

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
    let P: BN254J = CurveJ::one();

    // Q = 2P
    let Q_affine: BN254 = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        is_infinity: false
    };
    let Q = CurveJ::from(Q_affine);
    let R = P.incomplete_add(Q);

    let P_affine: BN254 = BigCurve::one();

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

    let P: BN254J = CurveJ::one();

    let lhs = P.dbl().0.dbl().0;
    let rhs = P.dbl().0.incomplete_add(P).0.incomplete_add(P).0;
    assert(lhs.eq(rhs));
}

#[test]
fn test_add() {
    let P: BN254 = BigCurve::one();

    // Q = 2P
    let Q: BN254 = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        is_infinity: false
    };

    let result = CurveJ::from(P.add(Q));

    let P_j = CurveJ::from(P);
    let Q_j = CurveJ::from(Q);
    let expected = P_j.add(Q_j).0;

    assert(result.eq(expected));

    // doubling
    let Q: BN254 = BigCurve::one();

    let result = CurveJ::from(P.add(Q));
    let expected = P_j.dbl().0;
    assert(result.eq(expected));

    // infinity
    let Q = P.neg();
    let result = CurveJ::from(P.add(Q));
    let expected = CurveJ::point_at_infinity();
    assert(result.eq(expected));

    // lhs infinity
    let P: BN254 = BigCurve::point_at_infinity();
    let result = CurveJ::from(P.add(Q));
    let expected = CurveJ::from(Q);
    assert(result.eq(expected));

    // rhs infinity
    let result = CurveJ::from(Q.add(P));
    assert(result.eq(expected));

    // both infinity
    let Q: BN254 = BigCurve::point_at_infinity();
    let result = CurveJ::from(Q.add(P));
    let expected = CurveJ::point_at_infinity();
    assert(result.eq(expected));
}

#[test]
fn test_sub() {
    let P: BN254 = BigCurve::one();

    // Q = 2P
    let Q: BN254 = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        is_infinity: false
    };

    let result = CurveJ::from(P.sub(Q));

    let P_j = CurveJ::from(P);
    let Q_j = CurveJ::from(Q);
    let expected = P_j.sub(Q_j).0;

    assert(result.eq(expected));

    // doubling
    let Q: BN254 = BigCurve::one();

    let result = CurveJ::from(P.sub(Q.neg()));
    let expected = P_j.dbl().0;
    assert(result.eq(expected));

    // infinity
    let result = CurveJ::from(P.sub(Q));
    let expected = CurveJ::point_at_infinity();
    assert(result.eq(expected));

    // lhs infinity
    let P: BN254 = BigCurve::point_at_infinity();
    let result = CurveJ::from(P.sub(Q));
    let expected = CurveJ::from(Q.neg());
    assert(result.eq(expected));

    // rhs infinity
    let result = CurveJ::from(Q.sub(P));
    let expected = expected.neg();
    assert(result.eq(expected));

    // both infinity
    let Q: BN254 = BigCurve::point_at_infinity();
    let result = CurveJ::from(Q.sub(P));
    let expected = CurveJ::point_at_infinity();
    assert(result.eq(expected));
}

unconstrained fn compute_inverses(x: [Fq; 8]) -> [Fq; 8] {
    let mut fff= x.as_slice();
    BigNum::__batch_invert(&mut fff);
    fff.as_array()
}

#[test]
fn test_make_table() {
    let P: BN254J = CurveJ::one();

    let mut transcript: [JTranscript<Fq>] = &[];
    let T: curve_jac::PointTable<Fq> = curve_jac::PointTable::new(P);
    for i in 0..8 {
        transcript = transcript.push_back(T.transcript[i]);
    }

    let mut inverses: [Fq; 8] = [BigNum::new(); 8];

    for i in 0..8 {
        inverses[i] = transcript[i].z3;
    }

    let ff = inverses[0];
    inverses = compute_inverses(inverses);

    let mut affine_transcript: [AffineTranscript<Fq>; 8] = [AffineTranscript::new(); 8];
    for i in 0..8 {
        let z_inv = inverses[i];

        let lambda = transcript[i].lambda_numerator.__mulmod(z_inv);
        let zz = z_inv.__mulmod(z_inv);
        let zzz = zz.__mulmod(z_inv);
        let x3 = transcript[i].x3.__mulmod(zz);
        let y3 = transcript[i].y3.__mulmod(zzz);
        affine_transcript[i] = AffineTranscript{ lambda, x3, y3 };
    }

    let P_affine: BN254 = BigCurve::one();

    let affine_point_table: PointTable<Fq> = PointTable::new_with_hint(P_affine, affine_transcript);
}

#[test]
fn test_ScalarField_BigNum_conversion() {
    let expected: Fq = BigNum::__derive_from_seed([1, 2, 3, 4]);
    let scalar: ScalarField<64> = ScalarField::from_bignum(expected);
    let result: Fq = scalar.into_bignum();
    assert(result.limbs == expected.limbs);
}
