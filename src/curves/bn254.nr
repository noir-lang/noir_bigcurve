use dep::bignum::{BigNum, fields::bn254Fq::BNParams as BN254_Fq_Params};

use crate::BigCurve;
use crate::CurveParamsTrait;

use crate::curve_jac;
use crate::curve_jac::JTranscript;
use crate::curve_jac::AffineTranscript;
use crate::curve_jac::CurveJ;
use crate::scalar_field::ScalarField;
use crate::PointTable;

type Fq = BigNum<3, BN254_Fq_Params>;

struct BN254_Curve_Params {
}

impl CurveParamsTrait<BigNum<3, BN254_Fq_Params>> for BN254_Curve_Params  {
    fn one() -> [BigNum<3, BN254_Fq_Params>; 2] {
        let mut one: Fq = BigNum::new();
        one.limbs[0] = 1;
        let mut two = one;
        two.limbs[0] = 2;
        [one, two]
    }

    // hash some unique string into an ecc point like “BLS12-381 Offset Generator”
    fn offset_generator() -> [BigNum<3, BN254_Fq_Params>; 2] {
        [
            BigNum { limbs: [0xf30f376a22bd3695abf4dcdfed66c6, 0x80d7bbcaebb13bbabfc30184f59912, 0x0cfb] },
            BigNum { limbs: [0xe53572d644c1e06f80ab52ef02fa2f, 0xa40d9e20debde026e47f8bfc4d3c41, 0x07f6] }
        ]
    }

    // offset_generator_final = offset_generator * 2^((NScalarSlices - 1) * 4)
    // we hardcode NScalarSlices to 64 so it’s offset_generator * (2^252)
    // i.e. it’s the offset_generator once it’s been passed through an MSM
    fn offset_generator_final() -> [BigNum<3, BN254_Fq_Params>; 2] {
        [
            BigNum { limbs: [0x0b672a3489895d47157f096e077348, 0x29f5f5b786660171ae9ad36f6db594, 0x15f1] },
            BigNum { limbs: [0x6e4553aa3ae998fcd27ca8a17188ef, 0xb3193f7f0a731913174831ca905feb, 0x21ff] }
        ]
    }

    fn a() -> BigNum<3, BN254_Fq_Params> {
        BigNum { limbs: [0,0,0]}
    }

    fn b() -> BigNum<3, BN254_Fq_Params> {
        BigNum { limbs: [3,0,0]}
    }
}

type BN254_Point = BigCurve<Fq, BN254_Curve_Params>;
type BN254_Point_J = CurveJ<Fq, BN254_Curve_Params>;

fn main(x: Field) {
    let mut foo: [Field; 6] = [0; 6];
    foo[0] = x;
    for i in 1..6 {
        foo[i] = foo[i-1] * x;
    }
    let P: BN254_Point = BigCurve {
        x: BigNum { limbs: [foo[0], foo[1], foo[2]] },
        y: BigNum { limbs: [foo[3], foo[4], foo[5]] },
        is_infinity: false
    };

    let scalar: ScalarField<64> = ScalarField::from(x); // p - 2 ? 
    let transcript = __get_mul_transcript(CurveJ::from(P), scalar);
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
    // let mut expected: BN254_Point = BigCurve {
    //     x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
    //     y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] }
    // };
    // expected.y = BigNum::new() - expected.y;
    // assert(result == expected);
    // let scalar2: ScalarField<64> = ScalarField::from(x * x); // p - 2 ? 
    // let transcript2 = get_transcript(CurveJ { x: Q.x, y: Q.y, z: BigNum::one() }, scalar);
    // let result = Q.mul_with_hint(scalar2, transcript2);
    // // -2
    // let mut expected: BN254_Point = BigCurve {
    //     x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
    //     y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] }
    // };
    // expected.y = BigNum::new() - expected.y;
    // assert(result.x.eq(expected.x));
    // assert(result.y.eq(expected.y));
}

unconstrained fn __get_msm_transcript(
    P: BN254_Point_J,
    Q: BN254_Point_J,
    scalar1: ScalarField<64>,
    scalar2: ScalarField<64>
) -> [AffineTranscript<Fq>; 399] {
    let s = (CurveJ::__msm([P, Q], [scalar1, scalar2]));
    let ff = s.1;
    // println(f"let transcript: AffineTranscript<N, Params> = {ff}");
    ff.as_array()
}

unconstrained fn __get_mul_transcript(
    P: BN254_Point_J,
    scalar: ScalarField<64>
) -> [AffineTranscript<Fq>; 326] {
    let res = P.__mul(scalar);
    let transcript = res.1;
    // println(f"let transcript: AffineTranscript<N, Params> = {transcript}");
    // let ff = transcript.len();
    // println(f"transcript len = {ff}");
    transcript.as_array()
}

#[test]
fn test_mul() {
    let P: BN254_Point = BigCurve::one();

    let scalar: ScalarField<64> = ScalarField::from(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff); // r - 2

    let transcript = __get_mul_transcript(CurveJ::from(P), scalar);

    let result = P.mul_with_hint(scalar, transcript);

    // -2
    let mut expected: BN254_Point = BigCurve {
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
    let P: BN254_Point = BigCurve {
        x: BigNum { limbs: [0x0b672a3489895d47157f096e077348, 0x29f5f5b786660171ae9ad36f6db594, 0x15f1] },
        y: BigNum { limbs: [0x6e4553aa3ae998fcd27ca8a17188ef, 0xb3193f7f0a731913174831ca905feb, 0x21ff] },
        is_infinity: false
    };
    // let Q_inv: BN254_Point = BigCurve {
    //     x: BigNum { limbs: [0x0b672a3489895d47157f096e077348, 0x29f5f5b786660171ae9ad36f6db594, 0x15f1] },
    //     y: BigNum { limbs: [0x13253dbe36e0f43f4e0f6e370b7458, 0x9b59a1b295b69f3d2e6e4fb6c7fdac, 0x0e64] },
    //     is_infinity: false
    // };
    let Q: BN254_Point = BigCurve {
        x: BigNum { limbs: [0x0b672a3489895d47157f096e077348, 0x29f5f5b786660171ae9ad36f6db594, 0x15f1] },
        y: BigNum { limbs: [0x6e4553aa3ae998fcd27ca8a17188ef, 0xb3193f7f0a731913174831ca905feb, 0x21ff] },
        is_infinity: false
    };

    let R: BN254_Point = P.sub(Q);
    // println(f"R = {R}");
    assert(R.is_infinity == true);
}

#[test]
fn test_mul_by_0() {
    let P: BN254_Point = BigCurve::one();

    let scalar: ScalarField<64> = ScalarField::from(0); // r - 2

    let foo: Field = ScalarField::into(scalar);
    assert(foo == 0);
    let transcript = __get_mul_transcript(CurveJ::from(P), scalar);

    let result = P.mul_with_hint(scalar, transcript);
    // println(f"RESULT = {result}");
    // -2
    assert(result.is_infinity == true);
}

#[test]
fn test_mul_a_point_at_infinity() {
    let P: BN254_Point = BigCurve::point_at_infinity();

    let scalar: ScalarField<64> = ScalarField::from(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff); // r - 2

    let transcript = __get_mul_transcript(CurveJ::from(P), scalar);

    let result = P.mul_with_hint(scalar, transcript);
    // println(f"RESULT = {result}");
    // -2
    assert(result.is_infinity == true);
}

// // N.B. cannot test because stack too deep!
// #[test]
// fn test_linear_expression() {
//     let One: BN254_Point = BigCurve::one();
//     let Two: BN254_Point = BigCurve {
//         x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
//         y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
//         is_infinity: false
//     };

//     let p_minus_2 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff; // r - 2
//     let p_minus_6 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffffb; // r - 6
//     let scalar2: ScalarField<64> = ScalarField::from(p_minus_2);
//     let scalar6: ScalarField<64> = ScalarField::from(p_minus_6);

//     let result = BigCurve::evaluate_linear_expression([One], [scalar2], []);
//     let expected = Two.neg();
//     assert(result == expected);
// }

// // N.B. cannot test because stack too deep!
// #[test]
// fn test_msm() {
//     let One: BN254_Point = BigCurve::one();
//     let Two: BN254_Point = BigCurve {
//         x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
//         y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
//         is_infinity: false
//     };

//     let p_minus_2 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff; // r - 2
//     let p_minus_6 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffffb; // r - 6
//     let scalar2: ScalarField<64> = ScalarField::from(p_minus_2);
//     let scalar6: ScalarField<64> = ScalarField::from(p_minus_6);

//     let transcript = get_msm_transcript(CurveJ::from(One), CurveJ::from(Two), scalar6, scalar2);
//     let result = BigCurve::msm_with_hint([One, Two.neg()], [scalar6, scalar2], transcript);
//     let expected = Two.neg();
//     assert(result == expected);
// }


unconstrained fn __evaluate_mul(
    P: BN254_Point_J, // P
    s: ScalarField<64>, // -1
    neg_P: BN254_Point_J, // P
    P_sub_2P: BN254_Point_J, // P - 2P
) -> bool {
    let sP = (P.__mul(s)); // -P 
    assert(sP.0.eq(neg_P)); // -P = neg_P
    P_sub_2P.eq(sP.0) // P - 2P = -P
}

#[test]
fn test_mul_jac() {
    let scalar_multiplier = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000; // r - 1
    let P: BN254_Point_J = CurveJ::one();

    // -1
    let s: ScalarField<64> = ScalarField::from(scalar_multiplier);

    // P - 2P
    let P_sub_2P = P.__incomplete_add(P.__dbl().0.__neg()).0;

    // -P
    let neg_P = P.__neg();

    // Can't call `mul` in a constrained fn, because it is an unconstrained fn which returns a slice.
    assert(__evaluate_mul(P, s, neg_P, P_sub_2P));
}

unconstrained fn __test_msm_jac_impl(scalars: [ScalarField<64>; 2]) {
    let One: BN254_Point_J = CurveJ::one();
    let Two: BN254_Point_J = CurveJ {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        z: BigNum::one(),
        is_infinity: false
    };
    let result = CurveJ::__msm([One, Two.__neg()], scalars);
    let expected = Two.__neg();
    assert(result.0 == expected);
}

#[test]
fn test_msm_jac() {
    let p_minus_2 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff; // r - 2
    let p_minus_6 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffffb; // r - 6
    let scalar2: ScalarField<64> = ScalarField::from(p_minus_2);
    let scalar6: ScalarField<64> = ScalarField::from(p_minus_6);

    __test_msm_jac_impl([scalar6, scalar2]);
}

#[test]
fn test_add_dbl() {
    let P: BN254_Point_J = CurveJ::one();
    let lhs = ((P.__dbl().0).__dbl()).0;
    let rhs = P.__dbl().0.__incomplete_add(P).0.__incomplete_add(P).0;
    assert(lhs == rhs);
}

#[test]
fn test_transcript() {
    let P: BN254_Point_J = CurveJ::one();

    let P2 = P.__dbl();

    let Z_inverse = P2.1.z3.__invmod();

    let lambda = P2.1.lambda_numerator.__mul(Z_inverse);

    let lhs = (lambda.__add(lambda)).__mul(P.y);
    let rhs = (P.x.__add(P.x).__add(P.x)).__mul(P.x);

    assert(lhs.eq(rhs));

    let X2 = P2.1.x3;
    let Y2 = P2.1.y3;
    let ZZ = Z_inverse.__mul(Z_inverse);
    let ZZZ = ZZ.__mul(Z_inverse);

    let x2 = X2.__mul(ZZ);
    let y2 = Y2.__mul(ZZZ);

    // ### test add transcript
    let P3 = P.__incomplete_add(P2.0);
    let Z_inverse = P3.1.z3.__invmod();

    let lambda = P3.1.lambda_numerator.__mul(Z_inverse);

    let x1 = P.x;
    let y1 = P.y;

    let lhs = lambda.__mul(x2.__sub(x1));
    let rhs = y2.__sub(y1);
    assert(lhs.eq(rhs));
}

#[test]
fn test_double_with_hint() {
    let P: BN254_Point_J = CurveJ::one();

    let P2 = P.__dbl();

    let P_affine: BN254_Point = BigCurve::one();

    let Z_inverse = P2.1.z3.__invmod();

    let lambda = P2.1.lambda_numerator.__mul(Z_inverse);

    let X3 = P2.1.x3;
    let Y3 = P2.1.y3;
    let ZZ = Z_inverse.__mul(Z_inverse);
    let ZZZ = ZZ.__mul(Z_inverse);

    let x3 = X3.__mul(ZZ);
    let y3 = Y3.__mul(ZZZ);

    let transcript: AffineTranscript<Fq> = AffineTranscript { lambda, x3, y3 };
    let P2_affine = P_affine.double_with_hint(transcript);

    assert(P2_affine.x.eq(x3));
    assert(P2_affine.y.eq(y3));
}

#[test]
fn test_incomplete_add_with_hint() {
    let P: BN254_Point_J = CurveJ::one();

    // Q = 2P
    let Q_affine: BN254_Point = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        is_infinity: false
    };
    let Q = CurveJ::from(Q_affine);
    let R = P.__incomplete_add(Q);

    let P_affine: BN254_Point = BigCurve::one();

    let Z_inverse = R.1.z3.__invmod();

    let lambda = R.1.lambda_numerator.__mul(Z_inverse);

    let X3 = R.1.x3;
    let Y3 = R.1.y3;
    let ZZ = Z_inverse.__mul(Z_inverse);
    let ZZZ = ZZ.__mul(Z_inverse);

    let x3 = X3.__mul(ZZ);
    let y3 = Y3.__mul(ZZZ);

    let transcript: AffineTranscript<Fq> = AffineTranscript { lambda, x3, y3 };
    let P2_affine = P_affine.incomplete_add_with_hint(Q_affine, transcript);

    assert(P2_affine.x.eq(x3));
    assert(P2_affine.y.eq(y3));

    let P: BN254_Point_J = CurveJ::one();

    let lhs = P.__dbl().0.__dbl().0;
    let rhs = P.__dbl().0.__incomplete_add(P).0.__incomplete_add(P).0;
    assert(lhs.eq(rhs));
}

#[test]
fn test_add() {
    let P: BN254_Point = BigCurve::one();

    // Q = 2P
    let Q: BN254_Point = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        is_infinity: false
    };

    let result = CurveJ::from(P.add(Q));

    let P_j = CurveJ::from(P);
    let Q_j = CurveJ::from(Q);
    let expected = P_j.__add(Q_j).0;

    assert(result.eq(expected));

    // doubling
    let Q: BN254_Point = BigCurve::one();

    let result = CurveJ::from(P.add(Q));
    let expected = P_j.__dbl().0;
    assert(result.eq(expected));

    // infinity
    let Q = P.neg();
    let result = CurveJ::from(P.add(Q));
    let expected = CurveJ::__point_at_infinity();
    assert(result.eq(expected));

    // lhs infinity
    let P: BN254_Point = BigCurve::point_at_infinity();
    let result = CurveJ::from(P.add(Q));
    let expected = CurveJ::from(Q);
    assert(result.eq(expected));

    // rhs infinity
    let result = CurveJ::from(Q.add(P));
    assert(result.eq(expected));

    // both infinity
    let Q: BN254_Point = BigCurve::point_at_infinity();
    let result = CurveJ::from(Q.add(P));
    let expected = CurveJ::__point_at_infinity();
    assert(result.eq(expected));
}

#[test]
fn test_sub() {
    let P: BN254_Point = BigCurve::one();

    // Q = 2P
    let Q: BN254_Point = BigCurve {
        x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
        y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] },
        is_infinity: false
    };

    let result = CurveJ::from(P.sub(Q));

    let P_j = CurveJ::from(P);
    let Q_j = CurveJ::from(Q);
    let expected = P_j.__sub(Q_j).0;

    assert(result.eq(expected));

    // doubling
    let Q: BN254_Point = BigCurve::one();

    let result = CurveJ::from(P.sub(Q.neg()));
    let expected = P_j.__dbl().0;
    assert(result.eq(expected));

    // infinity
    let result = CurveJ::from(P.sub(Q));
    let expected = CurveJ::__point_at_infinity();
    assert(result.eq(expected));

    // lhs infinity
    let P: BN254_Point = BigCurve::point_at_infinity();
    let result = CurveJ::from(P.sub(Q));
    let expected = CurveJ::from(Q.neg());
    assert(result.eq(expected));

    // rhs infinity
    let result = CurveJ::from(Q.sub(P));
    let expected = expected.__neg();
    assert(result.eq(expected));

    // both infinity
    let Q: BN254_Point = BigCurve::point_at_infinity();
    let result = CurveJ::from(Q.sub(P));
    let expected = CurveJ::__point_at_infinity();
    assert(result.eq(expected));
}

#[test]
fn test_make_table() {
    let P: BN254_Point_J = CurveJ::one();

    let mut transcript: [JTranscript<Fq>] = &[];
    let T: curve_jac::PointTable<Fq> = curve_jac::PointTable::__new(P);
    for i in 0..8 {
        transcript = transcript.push_back(T.transcript[i]);
    }

    let mut inverses: [Fq; 8] = [BigNum::new(); 8];

    for i in 0..8 {
        inverses[i] = transcript[i].z3;
    }

    inverses = BigNum::__batch_invert(inverses);

    let mut affine_transcript: [AffineTranscript<Fq>; 8] = [AffineTranscript::new(); 8];
    for i in 0..8 {
        let z_inv = inverses[i];

        let lambda = transcript[i].lambda_numerator.__mul(z_inv);
        let zz = z_inv.__mul(z_inv);
        let zzz = zz.__mul(z_inv);
        let x3 = transcript[i].x3.__mul(zz);
        let y3 = transcript[i].y3.__mul(zzz);
        affine_transcript[i] = AffineTranscript{ lambda, x3, y3 };
    }

    let P_affine: BN254_Point = BigCurve::one();

    let affine_point_table: PointTable<Fq> = PointTable::new_with_hint(P_affine, affine_transcript);

    for i in 0..8 {
        let point: BN254_Point = affine_point_table.get(i);
        point.validate_on_curve();
    }
}

// #[test]
// fn test_ScalarField_BigNum_conversion() {
//     assert(BNParams::modulus_bits() == 254);
//     let expected: Fq = BigNum::__derive_from_seed([1, 2, 3, 4]);
//     let scalar: ScalarField<64> = ScalarField::from_bignum(expected);
//     let result: Fq = scalar.into_bignum();
//     assert(result.limbs == expected.limbs);
// }
