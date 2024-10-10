use dep::bignum::{BigNum, fields::{bls12_381Fq::BLS12_381_Fq_Params, bls12_381Fr::BLS12_381_Fr_Params}};

use crate::BigCurve;
use crate::CurveParamsTrait;

use crate::curve_jac;
use crate::curve_jac::JTranscript;
use crate::curve_jac::AffineTranscript;
use crate::curve_jac::CurveJ;
use crate::scalar_field::ScalarField;
use crate::PointTable;

type Fq = BigNum<4, BLS12_381_Fq_Params>;
type Fr = BigNum<3, BLS12_381_Fr_Params>;

struct BLS12_381_Curve_Params {
}

impl CurveParamsTrait<BigNum<4, BLS12_381_Fq_Params>> for BLS12_381_Curve_Params {
    // Generator:
    // https://github.com/zcash/librustzcash/blob/6e0364cd42a2b3d2b958a54771ef51a8db79dd29/pairing/src/bls12_381/README.md#generators
    // https://hackmd.io/@benjaminion/bls12-381#Generators
    fn one() -> [BigNum<4, BLS12_381_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0x55e83ff97a1aeffb3af00adb22c6bb, 0x8c4f9774b905a14e3a3f171bac586c, 0xa73197d7942695638c4fa9ac0fc368, 0x17f1d3
                ]
            },
            BigNum {
                limbs: [
                    0x3cc744a2888ae40caa232946c5e7e1, 0xe095d5d00af600db18cb2c04b3edd0, 0x81e3aaa0f1a09e30ed741d8ae4fcf5, 0x8b3f4
                ]
            }
        ]
    }

    // TODO: See sage for derivation `BLS12_381_E.gens()`. It's perhaps not the best "nothing up my sleeve" generator, but it is on the curve, and works for now...
    fn offset_generator() -> [BigNum<4, BLS12_381_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0x442fbd0ad62391acc555c722aea803, 0x874b86b63ecf19360c2b6d0929bb71, 0x78bb8da22c7570f7dc170e554d728b, 0x38e40
                ]
            },
            BigNum {
                limbs: [
                    0x2ea24532fc73e4d7584bb0fa458df4, 0xc92ed9753fb9e1b8819f3a605248e5, 0x8b7b998bb4f0c34146feb9d46b28ef, 0xbec32
                ]
            }
        ]
    }

    fn offset_generator_final() -> [BigNum<4, BLS12_381_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0xbf1e24769d991bf33870bd69d363ea, 0x2b423528162b0d76359c3da6ca2eea, 0xee96e3f32399f07455b37847f7acd5, 0x43fdb
                ]
            },
            BigNum {
                limbs: [
                    0x25925f2a055349541935f8c7a32590, 0xb37639973145c0eff2ffab0b9cbbf3, 0x8cb4e9e6329b89a2c7ab6063948b68, 0x1168d5
                ]
            }
        ]
    }

    fn a() -> BigNum<4, BLS12_381_Fq_Params> {
        BigNum { limbs: [0, 0, 0, 0] }
    }

    fn b() -> BigNum<4, BLS12_381_Fq_Params> {
        BigNum { limbs: [4, 0, 0, 0] }
    }
}

type BLS12_381_Point = BigCurve<Fq, BLS12_381_Curve_Params>;
type BLS12_381_Point_J = CurveJ<Fq, BLS12_381_Curve_Params>;

fn main(x: Field) {
    let mut foo: [Field; 8] = [0; 8];
    foo[0] = x;
    for i in 1..8 {
        foo[i] = foo[i-1]* x;
    }
    let P: BLS12_381_Point = BigCurve {
        x: BigNum { limbs: [foo[0], foo[1], foo[2], foo[3]] },
        y: BigNum { limbs: [foo[4], foo[5], foo[6], foo[7]] },
        is_infinity: false
    };

    // 255-bit scalar field for BLS12_381 => 64 nibbles.
    let scalar: ScalarField<64> = ScalarField::from(x); // p - 2 ? 
    let transcript = unsafe {
        __get_mul_transcript(CurveJ::from(P), scalar)
    };
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
    // let mut expected: BLS12_381_Point = BigCurve {
    //     x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
    //     y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] }
    // };
    // expected.y = BigNum::new() - expected.y;
    // assert(result == expected);
    // let scalar2: ScalarField<64> = ScalarField::from(x * x); // p - 2 ? 
    // let transcript2 = __get_mul_transcript(CurveJ { x: Q.x, y: Q.y, z: BigNum::one() }, scalar);
    // let result = Q.mul_with_hint(scalar2, transcript2);
    // // -2
    // let mut expected: BLS12_381_Point = BigCurve {
    //     x: BigNum { limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306] },
    //     y: BigNum { limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed] }
    // };
    // expected.y = BigNum::new() - expected.y;
    // assert(result.x.eq(expected.x));
    // assert(result.y.eq(expected.y));
}

unconstrained fn __evaluate_mul(P: BLS12_381_Point_J, scalar: ScalarField<64>, Q: BLS12_381_Point_J, K: BLS12_381_Point_J) -> bool {
    let s = (P.__mul(scalar));
    assert(s.0.eq(K.__neg()));
    Q.eq(s.0)
}

unconstrained fn __get_msm_transcript(
    P: BLS12_381_Point_J,
    Q: BLS12_381_Point_J,
    scalar1: ScalarField<64>,
    scalar2: ScalarField<64>
) -> [AffineTranscript<Fq>; 399] {
    let s = (CurveJ::__msm([P, Q], [scalar1, scalar2]));
    s.1
}

unconstrained fn __get_mul_transcript(P: BLS12_381_Point_J, scalar: ScalarField<64>) -> [AffineTranscript<Fq>; 326] {
    let res = P.__mul(scalar);
    let transcript = res.1;
    // println(f"let transcript: AffineTranscript<N, Params> = {transcript}");
    // let ff = transcript.len();
    // println(f"transcript len = {ff}");
    transcript.as_array()
}

#[test]
fn test_mul() {
    let P: BLS12_381_Point = BigCurve::one();

    let scalar_fr: Fr = BigNum { limbs: [0xbda402fffe5bfefffffffeffffffff, 0xa753299d7d483339d80809a1d80553, 0x73ed] };
    let scalar: ScalarField<64> = ScalarField::from_bignum(scalar_fr); // r - 2

    let transcript = unsafe {
        __get_mul_transcript(CurveJ::from(P), scalar)
    };

    let result = P.mul_with_hint(scalar, transcript); // (r - 2) * P

    // -2
    let mut expected: BLS12_381_Point = BigCurve {
        x: BigNum {
            limbs: [
                0x8f75bb8f1c7c42c39a8c5529bf0f4e, 0xdb309128012543902d0ac358a62ae2, 0xea904d67468808c8eb50a9450c9721, 0x572cb
            ]
        },
        y: BigNum {
            limbs: [
                0x552629e43d42e3ff7877e6868b0d83, 0xcb96d142e5d6ff5199ed9511eb9d2, 0x5d8db972f7281e0142cbae1e9f41bd, 0x39674
            ]
        },
        is_infinity: false
    };
    // expected.y = BigNum::new() - expected.y;
    assert(result.x.eq(expected.x));
    assert(result.y.eq(expected.y));
}

#[test]
fn test_offset_foo() {
    let P: BLS12_381_Point = BigCurve::offset_generator_final(); // It can be any point, really.

    let R: BLS12_381_Point = P.sub(P);
    // println(f"R = {R}");
    assert(R.is_infinity == true);
}

#[test]
fn test_mul_by_0() {
    let P: BLS12_381_Point = BigCurve::one();

    let scalar: ScalarField<64> = ScalarField::from(0); // p - 2

    let foo: Field = ScalarField::into(scalar);
    assert(foo == 0);
    let transcript = unsafe {
        __get_mul_transcript(CurveJ::from(P), scalar)
    };

    let result = P.mul_with_hint(scalar, transcript);
    // println(f"RESULT = {result}");
    // -2
    assert(result.is_infinity == true);
}

#[test]
fn test_mul_a_point_at_infinity() {
    let P: BLS12_381_Point = BigCurve::point_at_infinity();

    let scalar: ScalarField<64> = ScalarField::from(0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff); // p - 2

    let transcript = unsafe {
        __get_mul_transcript(CurveJ::from(P), scalar)
    };

    let result = P.mul_with_hint(scalar, transcript);
    // println(f"RESULT = {result}");
    // -2
    assert(result.is_infinity == true);
}

// THIS TEST FAILS
#[test]
fn test_linear_expression() {
    let One: BLS12_381_Point = BigCurve::one();
    let Two: BLS12_381_Point = BigCurve {
        x: BigNum {
            limbs: [
                0x8f75bb8f1c7c42c39a8c5529bf0f4e, 0xdb309128012543902d0ac358a62ae2, 0xea904d67468808c8eb50a9450c9721, 0x572cb
            ]
        },
        y: BigNum {
            limbs: [
                0x56d9d4cd16bd1bba86881979749d28, 0x3ecb8670e461f73bb9021d5fd76a4c, 0x8cabc673a322fda673779d8e3822ba, 0x166a9d
            ]
        },
        is_infinity: false
    };

    let r_minus_2_fr: Fr = BigNum { limbs: [0xbda402fffe5bfefffffffeffffffff, 0xa753299d7d483339d80809a1d80553, 0x73ed] };
    let scalar2: ScalarField<64> = ScalarField::from_bignum(r_minus_2_fr); // r - 2

    let r_minus_6_fr: Fr = BigNum { limbs: [0xbda402fffe5bfefffffffefffffffb, 0xa753299d7d483339d80809a1d80553, 0x73ed] };
    let scalar6: ScalarField<64> = ScalarField::from_bignum(r_minus_6_fr); // r - 6

    let expected = Two.neg();

    let result = BigCurve::evaluate_linear_expression([One, Two.neg()], [scalar6, scalar2], []);

    assert(result == expected);
}

#[test]
fn test_msm() {
    let One: BLS12_381_Point = BigCurve::one();
    let Two: BLS12_381_Point = BigCurve {
        x: BigNum {
            limbs: [
                0x8f75bb8f1c7c42c39a8c5529bf0f4e, 0xdb309128012543902d0ac358a62ae2, 0xea904d67468808c8eb50a9450c9721, 0x572cb
            ]
        },
        y: BigNum {
            limbs: [
                0x56d9d4cd16bd1bba86881979749d28, 0x3ecb8670e461f73bb9021d5fd76a4c, 0x8cabc673a322fda673779d8e3822ba, 0x166a9d
            ]
        },
        is_infinity: false
    };

    let r_minus_2_fr: Fr = BigNum { limbs: [0xbda402fffe5bfefffffffeffffffff, 0xa753299d7d483339d80809a1d80553, 0x73ed] };
    let scalar2: ScalarField<64> = ScalarField::from_bignum(r_minus_2_fr); // r - 2

    let r_minus_6_fr: Fr = BigNum { limbs: [0xbda402fffe5bfefffffffefffffffb, 0xa753299d7d483339d80809a1d80553, 0x73ed] };
    let scalar6: ScalarField<64> = ScalarField::from_bignum(r_minus_6_fr); // r - 6

    let transcript = unsafe {
        __get_msm_transcript(CurveJ::from(One), CurveJ::from(Two.neg()), scalar6, scalar2)
    };

    let result = BigCurve::msm_with_hint([One, Two.neg()], [scalar6, scalar2], transcript);

    let expected = Two.neg();

    assert(result == expected);
}

#[test]
fn test_mul_jac() {
    let P: BLS12_381_Point_J = CurveJ::one();

    let scalar_fr: Fr = BigNum { limbs: [0xbda402fffe5bfeffffffff00000000, 0xa753299d7d483339d80809a1d80553, 0x73ed] }; // r - 1
    let scalar: ScalarField<64> = ScalarField::from_bignum(scalar_fr); // r - 1

    let expected = unsafe {
        P.__incomplete_add(P.__dbl().0.__neg()).0
    }; // P + -2P = -P
    let result = unsafe {
        __evaluate_mul(P, scalar, expected, P)
    };
    assert(result == true);
}

fn __test_msm_jac_impl(scalars: [ScalarField<64>; 2]) {
    let One: BLS12_381_Point_J = CurveJ::one();
    let Two: BLS12_381_Point_J = CurveJ {
        x: BigNum {
            limbs: [
                0x8f75bb8f1c7c42c39a8c5529bf0f4e, 0xdb309128012543902d0ac358a62ae2, 0xea904d67468808c8eb50a9450c9721, 0x572cb
            ]
        },
        y: BigNum {
            limbs: [
                0x56d9d4cd16bd1bba86881979749d28, 0x3ecb8670e461f73bb9021d5fd76a4c, 0x8cabc673a322fda673779d8e3822ba, 0x166a9d
            ]
        },
        z: BigNum::one(),
        is_infinity: false
    };
    let result = unsafe {
        CurveJ::__msm([One, Two.__neg()], scalars)
    };
    let expected = unsafe {
        Two.__neg()
    };
    assert(result.0 == expected);
}

#[test]
fn test_msm_jac() {
    let r_minus_2_fr: Fr = BigNum { limbs: [0xbda402fffe5bfefffffffeffffffff, 0xa753299d7d483339d80809a1d80553, 0x73ed] };
    let r_minus_2_scalar: ScalarField<64> = ScalarField::from_bignum(r_minus_2_fr); // r - 2

    let r_minus_6_fr: Fr = BigNum { limbs: [0xbda402fffe5bfefffffffefffffffb, 0xa753299d7d483339d80809a1d80553, 0x73ed] };
    let r_minus_6_scalar: ScalarField<64> = ScalarField::from_bignum(r_minus_6_fr); // r - 6

    unsafe {
        __test_msm_jac_impl([r_minus_6_scalar, r_minus_2_scalar]);
    }
}

#[test]
fn test_add_dbl() {
    let P: BLS12_381_Point_J = CurveJ::one();
    let lhs = unsafe {
        ((P.__dbl().0).__dbl()).0
    };
    let rhs = unsafe {
        P.__dbl().0.__incomplete_add(P).0.__incomplete_add(P).0
    };
    assert(lhs == rhs);
}

#[test]
fn test_transcript() {
    let P: BLS12_381_Point_J = CurveJ::one();

    let P2 = unsafe {
        P.__dbl()
    };

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
    let P: BLS12_381_Point_J = CurveJ::one();

    let P2 = unsafe {
        P.__dbl()
    };

    let P_affine: BLS12_381_Point = BigCurve::one();

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
    let P: BLS12_381_Point_J = CurveJ::one();

    // Q = 2P
    let Q_affine: BLS12_381_Point = BigCurve {
        x: BigNum {
            limbs: [
                0x8f75bb8f1c7c42c39a8c5529bf0f4e, 0xdb309128012543902d0ac358a62ae2, 0xea904d67468808c8eb50a9450c9721, 0x572cb
            ]
        },
        y: BigNum {
            limbs: [
                0x56d9d4cd16bd1bba86881979749d28, 0x3ecb8670e461f73bb9021d5fd76a4c, 0x8cabc673a322fda673779d8e3822ba, 0x166a9d
            ]
        },
        is_infinity: false
    };
    let Q = CurveJ::from(Q_affine);
    let R = unsafe {
        P.__incomplete_add(Q)
    };

    let P_affine: BLS12_381_Point = BigCurve::one();

    let Z_inverse = unsafe {
        R.1.z3.__invmod()
    };

    let lambda = R.1.lambda_numerator.__mul(Z_inverse);

    let X3 = R.1.x3;
    let Y3 = R.1.y3;
    let ZZ = unsafe {
        Z_inverse.__mul(Z_inverse)
    };
    let ZZZ = unsafe {
        ZZ.__mul(Z_inverse)
    };

    let x3 = X3.__mul(ZZ);
    let y3 = Y3.__mul(ZZZ);

    let transcript: AffineTranscript<Fq> = AffineTranscript { lambda, x3, y3 };
    let P2_affine = P_affine.incomplete_add_with_hint(Q_affine, transcript);

    assert(P2_affine.x.eq(x3));
    assert(P2_affine.y.eq(y3));

    let P: BLS12_381_Point_J = CurveJ::one();

    let lhs = unsafe {
        P.__dbl().0.__dbl().0
    };
    let rhs = unsafe {
        P.__dbl().0.__incomplete_add(P).0.__incomplete_add(P).0
    };
    assert(lhs.eq(rhs));
}

#[test]
fn test_add() {
    let P: BLS12_381_Point = BigCurve::one();

    // Two_P = 2P
    let Two_P: BLS12_381_Point = BigCurve {
        x: BigNum {
            limbs: [
                0x8f75bb8f1c7c42c39a8c5529bf0f4e, 0xdb309128012543902d0ac358a62ae2, 0xea904d67468808c8eb50a9450c9721, 0x572cb
            ]
        },
        y: BigNum {
            limbs: [
                0x56d9d4cd16bd1bba86881979749d28, 0x3ecb8670e461f73bb9021d5fd76a4c, 0x8cabc673a322fda673779d8e3822ba, 0x166a9d
            ]
        },
        is_infinity: false
    };

    let mut result = CurveJ::from(P.add(Two_P)); // 3P_j

    let P_j = CurveJ::from(P);
    let Two_P_j = CurveJ::from(Two_P);
    let mut expected = unsafe {
        P_j.__add(Two_P_j).0
    }; // 3P_j

    assert(result.eq(expected));

    let Two_P_j_unconstrained = P_j.__add(P_j);
    let Two_P_j_dbl_unconstrained = P_j.__dbl();

    // let Three_P = P.add(P.add(P));
    // let Three_P_alt = P.add(Two_P);
    // let P_plus_P = P.add(P);
    // println(f"P: {P}");
    // println(f"P+P: {P_plus_P}");
    // println(f"Two_P: {Two_P}");

    let Two_P_alt = P + P;
    assert(Two_P.eq(Two_P_alt));

    // doubling
    let Q: BLS12_381_Point = BigCurve::one(); // P

    // THIS DOUBLING BREAKS!!!
    result = CurveJ::from(P.add(Q)); // 2P_j
    expected = unsafe { P_j.__dbl().0 }; // 2P_j
    assert(result.eq(expected));

    // // infinity
    let Neg_P = P.neg();
    result = CurveJ::from(P.add(Neg_P)); // 0_j
    expected = unsafe { CurveJ::__point_at_infinity() };
    assert(result.eq(expected));

    // lhs infinity
    let Inf: BLS12_381_Point = BigCurve::point_at_infinity();
    result = CurveJ::from(Inf.add(Neg_P));
    expected = CurveJ::from(Neg_P);
    assert(result.eq(expected));

    // rhs infinity
    result = CurveJ::from(Neg_P.add(Inf));
    assert(result.eq(expected));

    // both infinity
    let Inf2: BLS12_381_Point = BigCurve::point_at_infinity();
    result = CurveJ::from(Inf.add(Inf2));
    expected = unsafe { CurveJ::__point_at_infinity() };
    assert(result.eq(expected));
}

#[test]
fn test_sub() {
    let P: BLS12_381_Point = BigCurve::one();

    let Two_P: BLS12_381_Point = BigCurve {
        x: BigNum {
            limbs: [
                0x8f75bb8f1c7c42c39a8c5529bf0f4e, 0xdb309128012543902d0ac358a62ae2, 0xea904d67468808c8eb50a9450c9721, 0x572cb
            ]
        },
        y: BigNum {
            limbs: [
                0x56d9d4cd16bd1bba86881979749d28, 0x3ecb8670e461f73bb9021d5fd76a4c, 0x8cabc673a322fda673779d8e3822ba, 0x166a9d
            ]
        },
        is_infinity: false
    };

    let result = CurveJ::from(P.sub(Two_P));

    let P_j = CurveJ::from(P);
    let Two_P_j = CurveJ::from(Two_P);
    let expected = unsafe {
        P_j.__sub(Two_P_j).0
    };

    assert(result.eq(expected));

    // doubling
    let Q: BLS12_381_Point = BigCurve::one(); // P

    let result = CurveJ::from(P.sub(Q.neg()));
    let expected = unsafe {
        P_j.__dbl().0
    };
    assert(result.eq(expected));

    // infinity
    let result = CurveJ::from(P.sub(Q));
    let expected = unsafe {
        CurveJ::__point_at_infinity()
    };
    assert(result.eq(expected));

    // lhs infinity
    let P: BLS12_381_Point = BigCurve::point_at_infinity();
    let result = CurveJ::from(P.sub(Q));
    let expected = CurveJ::from(Q.neg());
    assert(result.eq(expected));

    // rhs infinity
    let result = CurveJ::from(Q.sub(P));
    let expected = unsafe {
        expected.__neg()
    };
    assert(result.eq(expected));

    // both infinity
    let Q: BLS12_381_Point = BigCurve::point_at_infinity();
    let result = CurveJ::from(Q.sub(P));
    let expected = unsafe {
        CurveJ::__point_at_infinity()
    };
    assert(result.eq(expected));
}

#[test]
fn test_make_table() {
    let P: BLS12_381_Point_J = CurveJ::one();

    let mut transcript: [JTranscript<Fq>] = &[];
    let T: curve_jac::PointTable<Fq> = unsafe {
        curve_jac::PointTable::__new(P)
    };
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

    let P_affine: BLS12_381_Point = BigCurve::one();

    let affine_point_table: PointTable<Fq> = PointTable::new_with_hint(P_affine, affine_transcript);

    for i in 0..8 {
        let point: BLS12_381_Point = affine_point_table.get(i);
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
