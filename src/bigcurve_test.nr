use dep::bignum::BigNum;

use crate::BigCurve;

use crate::curve_jac;
use crate::curve_jac::AffineTranscript;
use crate::curve_jac::CurveJ;
use crate::curve_jac::JTranscript;
use crate::curves::bn254::{BN254, BN254Params, BN254Scalar};
use crate::PointTable;
use crate::scalar_field::ScalarField;
type Fq = BigNum<3, 254, BN254_Fq_Params>;

type BN254J = CurveJ<Fq, BN254Params>;

fn main(x: Field) {
    let mut foo: [Field; 12] = [0; 12];
    foo[0] = x;
    for i in 1..12 {
        foo[i] = foo[i - 1] * x;
    }
    let P: BN254 = BigCurve {
        x: BigNum { limbs: [foo[0], foo[1], foo[2]] },
        y: BigNum { limbs: [foo[3], foo[4], foo[5]] },
        is_infinity: false,
    };

    let scalar: ScalarField<64> = ScalarField::from(x); // p - 2 ?
    let transcript = unsafe { get_transcript(CurveJ::from(P), scalar) };
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
}

unconstrained fn evaluate_mul(P: BN254J, scalar: ScalarField<64>, Q: BN254J, K: BN254J) -> bool {
    let s = (P.mul(scalar));
    assert(s.0.eq(K.neg()));
    Q.eq(s.0)
}

unconstrained fn get_transcript(P: BN254J, scalar: ScalarField<64>) -> [AffineTranscript<Fq>; 326] {
    let res = P.mul(scalar);
    let transcript = res.1;
    transcript.as_array()
}

#[test]
fn test_mul() {
    let P: BN254 = BigCurve::one();

    let scalar: ScalarField<64> = ScalarField::from(
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff,
    ); // p - 2
    let transcript = unsafe { get_transcript(CurveJ::from(P), scalar) };

    let result = P.mul_with_hint(scalar, transcript);

    // -2
    let mut expected: BN254 = BigCurve {
        x: BigNum {
            limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306],
        },
        y: BigNum {
            limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed],
        },
        is_infinity: false,
    };
    expected.y = BigNum::new() - expected.y;
    assert(result.x == expected.x);
    assert(result.y == expected.y);
}

#[test]
fn test_offset_foo() {
    let P = BigCurve {
        x: BigNum {
            limbs: [0x0b672a3489895d47157f096e077348, 0x29f5f5b786660171ae9ad36f6db594, 0x15f1],
        },
        y: BigNum {
            limbs: [0x6e4553aa3ae998fcd27ca8a17188ef, 0xb3193f7f0a731913174831ca905feb, 0x21ff],
        },
        is_infinity: false,
    };
    let Q = BigCurve {
        x: BigNum {
            limbs: [0x0b672a3489895d47157f096e077348, 0x29f5f5b786660171ae9ad36f6db594, 0x15f1],
        },
        y: BigNum {
            limbs: [0x6e4553aa3ae998fcd27ca8a17188ef, 0xb3193f7f0a731913174831ca905feb, 0x21ff],
        },
        is_infinity: false,
    };

    let R: BN254 = P.sub(Q);
    assert(R.is_infinity == true);
}

#[test]
fn test_mul_by_0() {
    let P: BN254 = BigCurve::one();

    let scalar: ScalarField<64> = ScalarField::from(0); // p - 2
    let foo: Field = ScalarField::into(scalar);
    assert(foo == 0);
    let transcript = unsafe { get_transcript(CurveJ::from(P), scalar) };

    let result = P.mul_with_hint(scalar, transcript);
    assert(result.is_infinity == true);
}

#[test]
fn test_mul_a_point_at_infinity() {
    let P: BN254 = BigCurve::point_at_infinity();

    let scalar: ScalarField<64> = ScalarField::from(
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff,
    ); // p - 2
    let transcript = unsafe { get_transcript(CurveJ::from(P), scalar) };

    let result = P.mul_with_hint(scalar, transcript);
    assert(result.is_infinity == true);
}

#[test]
fn test_mul_jac() {
    let scalar_multiplier = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000; // p - 1
    let P: BN254J = CurveJ::one();

    let scalar: ScalarField<64> = ScalarField::from(scalar_multiplier);

    let expected = unsafe { P.incomplete_add(P.dbl().0.neg()).0 };
    let result = unsafe { evaluate_mul(P, scalar, expected, P) };
    assert(result == true);
}

unconstrained fn test_msm_jac_impl(scalars: [ScalarField<64>; 2]) {
    let One: BN254J = CurveJ::one();
    let Two: BN254J = CurveJ {
        x: BigNum {
            limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306],
        },
        y: BigNum {
            limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed],
        },
        z: BigNum::one(),
        is_infinity: false,
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

    unsafe {
        test_msm_jac_impl([scalar6, scalar2]);
    }
}

#[test]
fn test_add_dbl() {
    let P: BN254J = CurveJ::one();
    let lhs = unsafe { ((P.dbl().0).dbl()).0 };
    let rhs = unsafe { P.dbl().0.incomplete_add(P).0.incomplete_add(P).0 };
    assert(lhs == rhs);
}

#[test]
fn test_transcript() {
    unsafe {
        let P: BN254J = CurveJ::one();

        let P2 = unsafe { P.dbl() };

        let Z_inverse = P2.1.z3.__invmod();

        let lambda = P2.1.lambda_numerator.__mul(Z_inverse);

        let lhs = (lambda.__add(lambda)).__mul(P.y);
        let rhs = (P.x.__add(P.x).__add(P.x)).__mul(P.x);

        assert(lhs == rhs);

        let X2 = P2.1.x3;
        let Y2 = P2.1.y3;
        let ZZ = Z_inverse.__mul(Z_inverse);
        let ZZZ = ZZ.__mul(Z_inverse);

        let x2 = X2.__mul(ZZ);
        let y2 = Y2.__mul(ZZZ);

        // ### test add transcript
        let P3 = unsafe { P.incomplete_add(P2.0) };
        let Z_inverse = P3.1.z3.__invmod();

        let lambda = P3.1.lambda_numerator.__mul(Z_inverse);

        let x1 = P.x;
        let y1 = P.y;

        let lhs = lambda.__mul(x2.__sub(x1));
        let rhs = y2.__sub(y1);

        assert(lhs == rhs);
    }
}

#[test]
fn test_double_with_hint() {
    unsafe {
        let P: BN254J = CurveJ::one();

        let P2 = unsafe { P.dbl() };

        let P_affine: BN254 = BigCurve::one();

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

        assert(P2_affine.x == x3);
        assert(P2_affine.y == y3);
    }
}

#[test]
fn test_incomplete_add_with_hint() {
    unsafe {
        let P: BN254J = CurveJ::one();

        // Q = 2P
        let Q_affine: BN254 = BigCurve {
            x: BigNum {
                limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306],
            },
            y: BigNum {
                limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed],
            },
            is_infinity: false,
        };
        let Q = CurveJ::from(Q_affine);
        let R = unsafe { P.incomplete_add(Q) };

        let P_affine: BN254 = BigCurve::one();

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

        assert(P2_affine.x == x3);
        assert(P2_affine.y == y3);

        let P: BN254J = CurveJ::one();

        let lhs = unsafe { P.dbl().0.dbl().0 };
        let rhs = unsafe { P.dbl().0.incomplete_add(P).0.incomplete_add(P).0 };
        assert(lhs == rhs);
    }
}

#[test]
fn test_add() {
    unsafe {
        let P: BN254 = BigCurve::one();

        // Q = 2P
        let Q: BN254 = BigCurve {
            x: BigNum {
                limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306],
            },
            y: BigNum {
                limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed],
            },
            is_infinity: false,
        };

        let result = CurveJ::from(P.add(Q));

        let P_j = CurveJ::from(P);
        let Q_j = CurveJ::from(Q);
        let expected = unsafe { P_j.add(Q_j).0 };

        assert(result.eq(expected));

        // doubling
        let Q: BN254 = BigCurve::one();

        let result = CurveJ::from(P.add(Q));
        let expected = unsafe { P_j.dbl().0 };
        assert(result.eq(expected));

        // infinity
        let Q = P.neg();
        let result = CurveJ::from(P.add(Q));
        let expected = unsafe { CurveJ::point_at_infinity() };
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
        let expected = unsafe { CurveJ::point_at_infinity() };
        assert(result.eq(expected));
    }
}

#[test]
fn test_sub() {
    unsafe {
        let P: BN254 = BigCurve::one();

        // Q = 2P
        let Q: BN254 = BigCurve {
            x: BigNum {
                limbs: [0x7816a916871ca8d3c208c16d87cfd3, 0x44e72e131a029b85045b68181585d9, 0x0306],
            },
            y: BigNum {
                limbs: [0xa6a449e3538fc7ff3ebf7a5a18a2c4, 0x738c0e0a7c92e7845f96b2ae9c0a68, 0x15ed],
            },
            is_infinity: false,
        };

        let result = CurveJ::from(P.sub(Q));

        let P_j = CurveJ::from(P);
        let Q_j = CurveJ::from(Q);
        let expected = unsafe { P_j.sub(Q_j).0 };

        assert(result.eq(expected));

        // doubling
        let Q: BN254 = BigCurve::one();

        let result = CurveJ::from(P.sub(Q.neg()));
        let expected = unsafe { P_j.dbl().0 };
        assert(result.eq(expected));

        // infinity
        let result = CurveJ::from(P.sub(Q));
        let expected = unsafe { CurveJ::point_at_infinity() };
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
        let expected = unsafe { CurveJ::point_at_infinity() };
        assert(result.eq(expected));
    }
}

#[test]
fn test_make_table() {
    unsafe {
        let P: BN254J = CurveJ::one();

        let mut transcript: [JTranscript<Fq>] = &[];
        let T: curve_jac::PointTable<Fq> = unsafe { curve_jac::PointTable::new(P) };
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
            affine_transcript[i] = AffineTranscript { lambda, x3, y3 };
        }

        let P_affine: BN254 = BigCurve::one();

        let affine_point_table: PointTable<Fq> =
            PointTable::new_with_hint(P_affine, affine_transcript);

        for i in 0..8 {
            let point: BN254 = affine_point_table.get(i);
            point.validate_on_curve();
        }
    }
}

use dep::bignum::fields::bn254Fq::BN254_Fq_Params;

use crate::curves::bls12_377::{BLS12_377, BLS12_377Fr, BLS12_377Scalar};
use crate::curves::bls12_381::{BLS12_381, BLS12_381Fr, BLS12_381Scalar};
use crate::curves::mnt4_753::{MNT4_753, MNT4_753Fr, MNT4_753Scalar};
use crate::curves::mnt6_753::{MNT6_753, MNT6_753Fr, MNT6_753Scalar};
use crate::curves::pallas::{Pallas, PallasFr, PallasScalar};
use crate::curves::secp256k1::{Secp256k1, Secp256k1Fr, Secp256k1Scalar};
use crate::curves::secp256r1::{Secp256r1, Secp256r1Fr, Secp256r1Scalar};
use crate::curves::secp384r1::{Secp384r1, Secp384r1Fr, Secp384r1Scalar};
use crate::curves::vesta::{Vesta, VestaFr, VestaScalar};

//comptime fn
comptime fn make_test(
    f: StructDefinition,
    Curve: Quoted,
    Fr: Quoted,
    ScalarType: Quoted,
) -> Quoted {
    let k = f.name();
    let mut offset_generator_test: Quoted = quote {};
    // hacky workaround because we don't have a defined BN254Fr BigNum instance (assumption is the circuit field is BN254 :o)
    if (!Curve.eq(quote {BN254})) {
        offset_generator_test = quote {#[test]
fn test_offset_generators() {
    let one: $Curve = BigCurve::one();
    let negone: $Fr = BigNum::one().neg();
    let scalar: $ScalarType  = ScalarField::from_bignum(negone);
    let final = one.mul(scalar);
    assert(final.eq(one.neg()));
}};
    } else {
        offset_generator_test = quote {#[test]
fn test_offset_generators() {
    let one: $Curve = BigCurve::one();
    let scalar: $ScalarType  = ScalarField::from(-1);
    let final = one.mul(scalar);
    assert(final.eq(one.neg()));
}};
    }
    quote {
impl $k {
$offset_generator_test

#[test]
    fn test_num_scalar_slices_in_scalar_field() {
        let x: $Fr = BigNum::new();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        let scalar: $ScalarType = ScalarField::zero();
        let expected = scalar.len();
        assert(scalar_slices == expected);

    }


#[test]
fn test_hash_to_curve() {

    let r: $Curve = BigCurve::hash_to_curve("hello world".as_bytes());
    r.validate_on_curve();
}



#[test]
fn test_msm() {

    // (p-4)[X] + (p-5)[-X] = [X]
    let mut four: $Fr = BigNum::new();
    four.limbs[0] = 4;
    let p_minus_4_fr: $Fr = BigNum::modulus() - four;
    let p_minus_4: $ScalarType = ScalarField::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BigNum::one();
    let p_minus_5: $ScalarType = ScalarField::from_bignum(p_minus_5_fr);

    let mut scalars: [$ScalarType; 2] = [p_minus_4, p_minus_5];

    let A: $Curve = BigCurve::one();
    let B = A.neg();
    let mut points: [$Curve; 2] = [A, B];
    // -4.[1] -5.[-1] + [1] = [0]
    let result: $Curve = BigCurve::evaluate_linear_expression(points, scalars, [BigCurve::one().neg()]);
    assert(result.is_infinity);
}
}
}
}
