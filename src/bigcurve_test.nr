use std::ops::{Add, Neg, Sub};

use bignum::BigNum;

use crate::{BigCurve, BigCurveTrait};
use crate::curve_jac;
use crate::curve_jac::AffineTranscript;
use crate::curve_jac::CurveJ;
use crate::curve_jac::JTranscript;
use crate::curves::bls12_377::{BLS12_377, BLS12_377Scalar};
use crate::curves::bls12_381::{BLS12_381, BLS12_381Scalar};
use crate::curves::bn254::{BN254, BN254Params, BN254Scalar};
use crate::curves::brainpoolP192r1::{BrainpoolP192r1, BrainpoolP192r1Scalar};
use crate::curves::brainpoolP192t1::{BrainpoolP192t1, BrainpoolP192t1Scalar};
use crate::curves::brainpoolP224r1::{BrainpoolP224r1, BrainpoolP224r1Scalar};
use crate::curves::brainpoolP224t1::{BrainpoolP224t1, BrainpoolP224t1Scalar};
use crate::curves::brainpoolP256r1::{BrainpoolP256r1, BrainpoolP256r1Scalar};
use crate::curves::brainpoolP256t1::{BrainpoolP256t1, BrainpoolP256t1Scalar};
use crate::curves::brainpoolP384r1::{BrainpoolP384r1, BrainpoolP384r1Scalar};
use crate::curves::brainpoolP384t1::{BrainpoolP384t1, BrainpoolP384t1Scalar};
use crate::curves::brainpoolP512r1::{BrainpoolP512r1, BrainpoolP512r1Scalar};
use crate::curves::brainpoolP512t1::{BrainpoolP512t1, BrainpoolP512t1Scalar};
use crate::curves::mnt4_753::{MNT4_753, MNT4_753Scalar};
use crate::curves::mnt6_753::{MNT6_753, MNT6_753Scalar};
use crate::curves::pallas::{Pallas, PallasScalar};
use crate::curves::secp192r1::{Secp192r1, Secp192r1Scalar};
use crate::curves::secp224r1::{Secp224r1, Secp224r1Scalar};
use crate::curves::secp256k1::{Secp256k1, Secp256k1Scalar};
use crate::curves::secp256r1::{Secp256r1, Secp256r1Scalar};
use crate::curves::secp384r1::{Secp384r1, Secp384r1Scalar};
use crate::curves::secp521r1::{Secp521r1, Secp521r1Scalar};

use crate::curves::vesta::{Vesta, VestaScalar};
use crate::PointTable;
use crate::scalar_field::{ScalarField, ScalarFieldTrait};

use bignum::BLS12_377_Fr;
use bignum::BLS12_381_Fr;
use bignum::BN254_Fq;
use bignum::BrainpoolP192r1_Fr;
use bignum::BrainpoolP192t1_Fr;
use bignum::BrainpoolP224r1_Fr;
use bignum::BrainpoolP224t1_Fr;
use bignum::BrainpoolP256r1_Fr;
use bignum::BrainpoolP256t1_Fr;
use bignum::BrainpoolP384r1_Fr;
use bignum::BrainpoolP384t1_Fr;
use bignum::BrainpoolP512r1_Fr;
use bignum::BrainpoolP512t1_Fr;
use bignum::MNT4_753_Fr;
use bignum::{MNT6_753_Fq, MNT6_753_Fr};
use bignum::Pallas_Fr;
use bignum::Secp192r1_Fr;
use bignum::Secp224r1_Fr;
use bignum::Secp256k1_Fr;
use bignum::Secp256r1_Fr;
use bignum::Secp384r1_Fr;
use bignum::Secp521r1_Fr;
use bignum::Vesta_Fr;
type BN254J = CurveJ<BN254_Fq, BN254Params>;

fn main(x: u128) {
    let mut foo: [u128; 12] = [0; 12];
    foo[0] = x;
    for i in 1..12 {
        foo[i] = foo[i - 1] * x;
    }
    let P: BN254 = BigCurve {
        x: BN254_Fq::from_limbs([foo[0], foo[1], foo[2]]),
        y: BN254_Fq::from_limbs([foo[3], foo[4], foo[5]]),
        is_infinity: false,
    };

    let scalar: ScalarField<64> = ScalarField::from(x as Field); // p - 2 ?
    let transcript = unsafe { get_transcript(CurveJ::from(P), scalar) };
    // 30768
    // 31020
    let mut A = P;
    for i in 0..101 {
        for j in 0..3 {
            std::as_witness(transcript[i].lambda.get_limb(j) as Field);
            std::as_witness(transcript[i].x3.get_limb(j) as Field);
            std::as_witness(transcript[i].y3.get_limb(j) as Field);
        }
        A = A.double_with_hint(transcript[i]);
    }
}

unconstrained fn evaluate_mul(P: BN254J, scalar: ScalarField<64>, Q: BN254J, K: BN254J) -> bool {
    let s = (P.mul(scalar));
    assert(s.0.eq(K.neg()));
    Q.eq(s.0)
}

unconstrained fn get_transcript(
    P: BN254J,
    scalar: ScalarField<64>,
) -> [AffineTranscript<BN254_Fq>; 326] {
    let (_, transcript) = P.mul(scalar);
    transcript
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
        x: BN254_Fq::from_limbs([
            0x7816a916871ca8d3c208c16d87cfd3,
            0x44e72e131a029b85045b68181585d9,
            0x0306,
        ]),
        y: BN254_Fq::from_limbs([
            0xa6a449e3538fc7ff3ebf7a5a18a2c4,
            0x738c0e0a7c92e7845f96b2ae9c0a68,
            0x15ed,
        ]),
        is_infinity: false,
    };
    expected.y = BigNum::zero() - expected.y;
    assert(result.x == expected.x);
    assert(result.y == expected.y);
}

#[test]
fn test_offset_foo() {
    let P = BigCurve {
        x: BN254_Fq::from_limbs([
            0x0b672a3489895d47157f096e077348,
            0x29f5f5b786660171ae9ad36f6db594,
            0x15f1,
        ]),
        y: BN254_Fq::from_limbs([
            0x6e4553aa3ae998fcd27ca8a17188ef,
            0xb3193f7f0a731913174831ca905feb,
            0x21ff,
        ]),
        is_infinity: false,
    };
    let Q = BigCurve {
        x: BN254_Fq::from_limbs([
            0x0b672a3489895d47157f096e077348,
            0x29f5f5b786660171ae9ad36f6db594,
            0x15f1,
        ]),
        y: BN254_Fq::from_limbs([
            0x6e4553aa3ae998fcd27ca8a17188ef,
            0xb3193f7f0a731913174831ca905feb,
            0x21ff,
        ]),
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
        x: BN254_Fq::from_limbs([
            0x7816a916871ca8d3c208c16d87cfd3,
            0x44e72e131a029b85045b68181585d9,
            0x0306,
        ]),
        y: BN254_Fq::from_limbs([
            0xa6a449e3538fc7ff3ebf7a5a18a2c4,
            0x738c0e0a7c92e7845f96b2ae9c0a68,
            0x15ed,
        ]),
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

        let P2 = P.dbl();

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
        let P3 = P.incomplete_add(P2.0);
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

        let P2 = P.dbl();

        let P_affine: BN254 = BigCurve::one();

        let Z_inverse = P2.1.z3.__invmod();

        let lambda = P2.1.lambda_numerator.__mul(Z_inverse);

        let X3 = P2.1.x3;
        let Y3 = P2.1.y3;
        let ZZ = Z_inverse.__mul(Z_inverse);
        let ZZZ = ZZ.__mul(Z_inverse);

        let x3 = X3.__mul(ZZ);
        let y3 = Y3.__mul(ZZZ);

        let transcript: AffineTranscript<BN254_Fq> = AffineTranscript { lambda, x3, y3 };
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
            x: BN254_Fq::from_limbs([
                0x7816a916871ca8d3c208c16d87cfd3,
                0x44e72e131a029b85045b68181585d9,
                0x0306,
            ]),
            y: BN254_Fq::from_limbs([
                0xa6a449e3538fc7ff3ebf7a5a18a2c4,
                0x738c0e0a7c92e7845f96b2ae9c0a68,
                0x15ed,
            ]),
            is_infinity: false,
        };
        let Q = CurveJ::from(Q_affine);
        let R = P.incomplete_add(Q);

        let P_affine: BN254 = BigCurve::one();

        let Z_inverse = R.1.z3.__invmod();

        let lambda = R.1.lambda_numerator.__mul(Z_inverse);

        let X3 = R.1.x3;
        let Y3 = R.1.y3;
        let ZZ = Z_inverse.__mul(Z_inverse);
        let ZZZ = ZZ.__mul(Z_inverse);

        let x3 = X3.__mul(ZZ);
        let y3 = Y3.__mul(ZZZ);

        let transcript: AffineTranscript<BN254_Fq> = AffineTranscript { lambda, x3, y3 };
        let P2_affine = P_affine.incomplete_add_with_hint(Q_affine, transcript);

        assert(P2_affine.x == x3);
        assert(P2_affine.y == y3);

        let P: BN254J = CurveJ::one();

        let lhs = P.dbl().0.dbl().0;
        let rhs = P.dbl().0.incomplete_add(P).0.incomplete_add(P).0;
        assert(lhs == rhs);
    }
}

#[test]
fn test_add() {
    unsafe {
        let P: BN254 = BigCurve::one();

        // Q = 2P
        let Q: BN254 = BigCurve {
            x: BN254_Fq::from_limbs([
                0x7816a916871ca8d3c208c16d87cfd3,
                0x44e72e131a029b85045b68181585d9,
                0x0306,
            ]),
            y: BN254_Fq::from_limbs([
                0xa6a449e3538fc7ff3ebf7a5a18a2c4,
                0x738c0e0a7c92e7845f96b2ae9c0a68,
                0x15ed,
            ]),
            is_infinity: false,
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
}

#[test]
fn test_sub() {
    unsafe {
        let P: BN254 = BigCurve::one();

        // Q = 2P
        let Q: BN254 = BigCurve {
            x: BN254_Fq::from_limbs([
                0x7816a916871ca8d3c208c16d87cfd3,
                0x44e72e131a029b85045b68181585d9,
                0x0306,
            ]),
            y: BN254_Fq::from_limbs([
                0xa6a449e3538fc7ff3ebf7a5a18a2c4,
                0x738c0e0a7c92e7845f96b2ae9c0a68,
                0x15ed,
            ]),
            is_infinity: false,
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
}

#[test]
fn test_make_table() {
    unsafe {
        let P: BN254J = CurveJ::one();

        let mut transcript: [JTranscript<BN254_Fq>] = &[];
        let T: curve_jac::PointTable<BN254_Fq> = curve_jac::PointTable::new(P);
        for i in 0..8 {
            transcript = transcript.push_back(T.transcript[i]);
        }

        let mut inverses: [BN254_Fq; 8] = [BN254_Fq::zero(); 8];

        for i in 0..8 {
            inverses[i] = transcript[i].z3;
        }

        inverses = bignum::bignum::batch_invert(inverses);

        let mut affine_transcript: [AffineTranscript<BN254_Fq>; 8] = [AffineTranscript::new(); 8];
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

        let affine_point_table: PointTable<BN254_Fq> =
            PointTable::new_with_hint(P_affine, affine_transcript);

        for i in 0..8 {
            let point: BN254 = affine_point_table.get(i);
            point.validate_on_curve();
        }
    }
}

#[test]
fn test_bls12_377_offset_generators() {
    let one = BLS12_377::one();
    let negone = BLS12_377_Fr::one().neg();
    let scalar = BLS12_377Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_bls12_381_offset_generators() {
    let one = BLS12_381::one();
    let negone = BLS12_381_Fr::one().neg();
    let scalar = BLS12_381Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_bn254_offset_generators() {
    let one = BN254::one();
    let scalar = BN254Scalar::from(-1);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_mnt4_753_offset_generators() {
    let one = MNT4_753::one();
    let negone = MNT4_753_Fr::one().neg();
    let scalar = MNT4_753Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_mnt6_753_offset_generators() {
    let one = MNT6_753::one();
    let negone = MNT6_753_Fr::one().neg();
    let scalar = MNT6_753Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_pallas_offset_generators() {
    let one = Pallas::one();
    let negone = Pallas_Fr::one().neg();
    let scalar = PallasScalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_secp256k1_offset_generators() {
    let one = Secp256k1::one();
    let negone = Secp256k1_Fr::one().neg();
    let scalar = Secp256k1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_secp256r1_offset_generators() {
    let one = Secp256r1::one();
    let negone = Secp256r1_Fr::one().neg();
    let scalar = Secp256r1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_secp384r1_offset_generators() {
    let one = Secp384r1::one();
    let negone = Secp384r1_Fr::one().neg();
    let scalar = Secp384r1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_secp521r1_offset_generators() {
    let one = Secp521r1::one();
    let negone = Secp521r1_Fr::one().neg();
    let scalar = Secp521r1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_brainpoolP256r1_offset_generators() {
    let one = BrainpoolP256r1::one();
    let negone = BrainpoolP256r1_Fr::one().neg();
    let scalar = BrainpoolP256r1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_brainpoolP256t1_offset_generators() {
    let one = BrainpoolP256t1::one();
    let negone = BrainpoolP256t1_Fr::one().neg();
    let scalar = BrainpoolP256t1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_brainpoolP384r1_offset_generators() {
    let one = BrainpoolP384r1::one();
    let negone = BrainpoolP384r1_Fr::one().neg();
    let scalar = BrainpoolP384r1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_brainpoolP384t1_offset_generators() {
    let one = BrainpoolP384t1::one();
    let negone = BrainpoolP384t1_Fr::one().neg();
    let scalar = BrainpoolP384t1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_brainpoolP512r1_offset_generators() {
    let one = BrainpoolP512r1::one();
    let negone = BrainpoolP512r1_Fr::one().neg();
    let scalar = BrainpoolP512r1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_brainpoolP512t1_offset_generators() {
    let one = BrainpoolP512t1::one();
    let negone = BrainpoolP512t1_Fr::one().neg();
    let scalar = BrainpoolP512t1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_vesta_offset_generators() {
    let one = Vesta::one();
    let negone = Vesta_Fr::one().neg();
    let scalar = VestaScalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_secp192r1_offset_generators() {
    let one = Secp192r1::one();
    let negone = Secp192r1_Fr::one().neg();
    let scalar = Secp192r1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_secp224r1_offset_generators() {
    let one = Secp224r1::one();
    let negone = Secp224r1_Fr::one().neg();
    let scalar = Secp224r1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_brainpoolP192t1_offset_generators() {
    let one = BrainpoolP192t1::one();
    let negone = BrainpoolP192t1_Fr::one().neg();
    let scalar = BrainpoolP192t1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_brainpoolP192r1_offset_generators() {
    let one = BrainpoolP192r1::one();
    let negone = BrainpoolP192r1_Fr::one().neg();
    let scalar = BrainpoolP192r1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_brainpoolP224t1_offset_generators() {
    let one = BrainpoolP224t1::one();
    let negone = BrainpoolP224t1_Fr::one().neg();
    let scalar = BrainpoolP224t1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_brainpoolP224r1_offset_generators() {
    let one = BrainpoolP224r1::one();
    let negone = BrainpoolP224r1_Fr::one().neg();
    let scalar = BrainpoolP224r1Scalar::from_bignum(negone);
    let final = one.mul(scalar);

    assert(final.eq(one.neg()));
}

#[test]
fn test_bls12_377_num_scalar_slices_in_scalar_field() {
    let x = BLS12_377_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BLS12_377Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_bls12_381_num_scalar_slices_in_scalar_field() {
    let x = BLS12_381_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BLS12_381Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_bn254_num_scalar_slices_in_scalar_field() {
    let x = BN254_Fq::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BN254Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_mnt4_753_num_scalar_slices_in_scalar_field() {
    let x = MNT4_753_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = MNT4_753Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_mnt6_753_num_scalar_slices_in_scalar_field() {
    let x = MNT6_753_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = MNT6_753Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_pallas_num_scalar_slices_in_scalar_field() {
    let x = Pallas_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = PallasScalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_secp256k1_num_scalar_slices_in_scalar_field() {
    let x = Secp256k1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = Secp256k1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_secp256r1_num_scalar_slices_in_scalar_field() {
    let x = Secp256r1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = Secp256r1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_secp384r1_num_scalar_slices_in_scalar_field() {
    let x = Secp384r1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = Secp384r1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_secp521r1_num_scalar_slices_in_scalar_field() {
    let x = Secp521r1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = Secp521r1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_brainpoolP256r1_num_scalar_slices_in_scalar_field() {
    let x = BrainpoolP256r1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BrainpoolP256r1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_brainpoolP256t1_num_scalar_slices_in_scalar_field() {
    let x = BrainpoolP256t1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BrainpoolP256t1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_brainpoolP384r1_num_scalar_slices_in_scalar_field() {
    let x = BrainpoolP384r1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BrainpoolP384r1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_brainpoolP384t1_num_scalar_slices_in_scalar_field() {
    let x = BrainpoolP384t1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BrainpoolP384t1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_brainpoolP512r1_num_scalar_slices_in_scalar_field() {
    let x = BrainpoolP512r1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BrainpoolP512r1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_brainpoolP512t1_num_scalar_slices_in_scalar_field() {
    let x = BrainpoolP512t1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BrainpoolP512t1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_vesta_num_scalar_slices_in_scalar_field() {
    let x = Vesta_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = VestaScalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_secp192r1_num_scalar_slices_in_scalar_field() {
    let x = Secp192r1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = Secp192r1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_secp224r1_num_scalar_slices_in_scalar_field() {
    let x = Secp224r1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = Secp224r1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_brainpoolP192r1_num_scalar_slices_in_scalar_field() {
    let x = BrainpoolP192r1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BrainpoolP192r1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_brainpoolP192t1_num_scalar_slices_in_scalar_field() {
    let x = BrainpoolP192t1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BrainpoolP192t1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_brainpoolP224r1_num_scalar_slices_in_scalar_field() {
    let x = BrainpoolP224r1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BrainpoolP224r1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_brainpoolP224t1_num_scalar_slices_in_scalar_field() {
    let x = BrainpoolP224t1_Fr::zero();
    let max_wnaf_bits = x.modulus_bits() + 1;
    let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
    let scalar = BrainpoolP224t1Scalar::zero();

    assert(scalar_slices == scalar.len());
}

#[test]
fn test_bls12_377_hash_to_curve() {
    let r = BLS12_377::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_bls12_381_hash_to_curve() {
    let r = BLS12_381::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_bn254_hash_to_curve() {
    let r = BN254::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_mnt4_753_hash_to_curve() {
    let r = MNT4_753::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_mnt6_753_hash_to_curve() {
    let r = MNT6_753::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_pallas_hash_to_curve() {
    let r = Pallas::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_secp256k1_hash_to_curve() {
    let r = Secp256k1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_secp256r1_hash_to_curve() {
    let r = Secp256r1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_secp384r1_hash_to_curve() {
    let r = Secp384r1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_secp521r1_hash_to_curve() {
    let r = Secp521r1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_brainpoolP256r1_hash_to_curve() {
    let r = BrainpoolP256r1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_brainpoolP256t1_hash_to_curve() {
    let r = BrainpoolP256t1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_brainpoolP384r1_hash_to_curve() {
    let r = BrainpoolP384r1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_brainpoolP384t1_hash_to_curve() {
    let r = BrainpoolP384t1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_brainpoolP512r1_hash_to_curve() {
    let r = BrainpoolP512r1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_brainpoolP512t1_hash_to_curve() {
    let r = BrainpoolP512t1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_vesta_hash_to_curve() {
    let r = Vesta::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_secp192r1_hash_to_curve() {
    let r = Secp192r1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_secp224r1_hash_to_curve() {
    let r = Secp224r1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_brainpoolP192r1_hash_to_curve() {
    let r = BrainpoolP192r1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_brainpoolP192t1_hash_to_curve() {
    let r = BrainpoolP192t1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_brainpoolP224r1_hash_to_curve() {
    let r = BrainpoolP224r1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_brainpoolP224t1_hash_to_curve() {
    let r = BrainpoolP224t1::hash_to_curve("hello world".as_bytes());

    r.validate_on_curve();
}

#[test]
fn test_bls12_377_msm() {
    let mut four = BLS12_377_Fr::zero();
    four.set_limb(0, 4);
    let p_minus_4_fr = BLS12_377_Fr::modulus() - four;
    let p_minus_4 = BLS12_377Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BLS12_377_Fr::one();
    let p_minus_5 = BLS12_377Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BLS12_377::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BLS12_377::evaluate_linear_expression(points, scalars, [BLS12_377::one().neg()]);

    assert(result.is_infinity);
}

#[test]
fn test_bls12_381_msm() {
    let four = BLS12_381_Fr::from(4);
    let p_minus_4_fr = BLS12_381_Fr::modulus() - four;
    let p_minus_4 = BLS12_381Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BLS12_381_Fr::one();
    let p_minus_5 = BLS12_381Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BLS12_381::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BLS12_381::evaluate_linear_expression(points, scalars, [BLS12_381::one().neg()]);

    assert(result.is_infinity);
}

#[test]
fn test_bn254_msm() {
    let four = BN254_Fq::from(4);
    let p_minus_4_fr = BN254_Fq::modulus() - four;
    let p_minus_4 = BN254Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BN254_Fq::one();
    let p_minus_5 = BN254Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BN254::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BN254::evaluate_linear_expression(points, scalars, [BN254::one().neg()]);

    assert(result.is_infinity);
}

#[test]
fn test_mnt4_753_msm() {
    let mut four = MNT4_753_Fr::from(4);
    let p_minus_4_fr = MNT4_753_Fr::modulus() - four;
    let p_minus_4 = MNT4_753Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - MNT4_753_Fr::one();
    let p_minus_5 = MNT4_753Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = MNT4_753::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = MNT4_753::evaluate_linear_expression(points, scalars, [MNT4_753::one().neg()]);

    assert(result.is_infinity);
}

#[test]
fn test_mnt6_753_msm() {
    let mut four = MNT6_753_Fr::from(4);

    let p_minus_4_fr = MNT6_753_Fr::modulus() - four;
    let p_minus_4 = MNT6_753Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - MNT6_753_Fr::one();
    let p_minus_5 = MNT6_753Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = MNT6_753::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = MNT6_753::evaluate_linear_expression(points, scalars, [MNT6_753::one().neg()]);

    assert(result.is_infinity);
}

#[test]
fn test_pallas_msm() {
    let mut four = Pallas_Fr::from(4);
    let p_minus_4_fr = Pallas_Fr::modulus() - four;
    let p_minus_4 = PallasScalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - Pallas_Fr::one();
    let p_minus_5 = PallasScalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = Pallas::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = Pallas::evaluate_linear_expression(points, scalars, [Pallas::one().neg()]);

    assert(result.is_infinity);
}

#[test]
fn test_secp256k1_msm() {
    let four = Secp256k1_Fr::from(4);
    let p_minus_4_fr = Secp256k1_Fr::modulus() - four;
    let p_minus_4 = Secp256k1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - Secp256k1_Fr::one();
    let p_minus_5 = Secp256k1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = Secp256k1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = Secp256k1::evaluate_linear_expression(points, scalars, [Secp256k1::one().neg()]);

    assert(result.is_infinity);
}

#[test]
fn test_secp256r1_msm() {
    let four = Secp256r1_Fr::from(4);
    let p_minus_4_fr = Secp256r1_Fr::modulus() - four;
    let p_minus_4 = Secp256r1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - Secp256r1_Fr::one();
    let p_minus_5 = Secp256r1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = Secp256r1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = Secp256r1::evaluate_linear_expression(points, scalars, [Secp256r1::one().neg()]);

    assert(result.is_infinity);
}

#[test]
fn test_secp384r1_msm() {
    let four = Secp384r1_Fr::from(4);
    let p_minus_4_fr = Secp384r1_Fr::modulus() - four;
    let p_minus_4 = Secp384r1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - Secp384r1_Fr::one();
    let p_minus_5 = Secp384r1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = Secp384r1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = Secp384r1::evaluate_linear_expression(points, scalars, [Secp384r1::one().neg()]);

    assert(result.is_infinity);
}

#[test]
fn test_secp521r1_msm() {
    let four = Secp521r1_Fr::from(4);
    let p_minus_4_fr = Secp521r1_Fr::modulus() - four;
    let p_minus_4 = Secp521r1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - Secp521r1_Fr::one();
    let p_minus_5 = Secp521r1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = Secp521r1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = Secp521r1::evaluate_linear_expression(points, scalars, [Secp521r1::one().neg()]);

    assert(result.is_infinity);
}

#[test]
fn test_brainpoolP256r1_msm() {
    let four = BrainpoolP256r1_Fr::from(4);
    let p_minus_4_fr = BrainpoolP256r1_Fr::modulus() - four;
    let p_minus_4 = BrainpoolP256r1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BrainpoolP256r1_Fr::one();
    let p_minus_5 = BrainpoolP256r1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BrainpoolP256r1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BrainpoolP256r1::evaluate_linear_expression(
        points,
        scalars,
        [BrainpoolP256r1::one().neg()],
    );

    assert(result.is_infinity);
}

#[test]
fn test_brainpoolP256t1_msm() {
    let four = BrainpoolP256t1_Fr::from(4);
    let p_minus_4_fr = BrainpoolP256t1_Fr::modulus() - four;
    let p_minus_4 = BrainpoolP256t1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BrainpoolP256t1_Fr::one();
    let p_minus_5 = BrainpoolP256t1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BrainpoolP256t1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BrainpoolP256t1::evaluate_linear_expression(
        points,
        scalars,
        [BrainpoolP256t1::one().neg()],
    );

    assert(result.is_infinity);
}

#[test]
fn test_brainpoolP384r1_msm() {
    let four = BrainpoolP384r1_Fr::from(4);
    let p_minus_4_fr = BrainpoolP384r1_Fr::modulus() - four;
    let p_minus_4 = BrainpoolP384r1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BrainpoolP384r1_Fr::one();
    let p_minus_5 = BrainpoolP384r1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BrainpoolP384r1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BrainpoolP384r1::evaluate_linear_expression(
        points,
        scalars,
        [BrainpoolP384r1::one().neg()],
    );

    assert(result.is_infinity);
}

#[test]
fn test_brainpoolP384t1_msm() {
    let four = BrainpoolP384t1_Fr::from(4);
    let p_minus_4_fr = BrainpoolP384t1_Fr::modulus() - four;
    let p_minus_4 = BrainpoolP384t1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BrainpoolP384t1_Fr::one();
    let p_minus_5 = BrainpoolP384t1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BrainpoolP384t1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BrainpoolP384t1::evaluate_linear_expression(
        points,
        scalars,
        [BrainpoolP384t1::one().neg()],
    );

    assert(result.is_infinity);
}

#[test]
fn test_brainpoolP512r1_msm() {
    let four = BrainpoolP512r1_Fr::from(4);
    let p_minus_4_fr = BrainpoolP512r1_Fr::modulus() - four;
    let p_minus_4 = BrainpoolP512r1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BrainpoolP512r1_Fr::one();
    let p_minus_5 = BrainpoolP512r1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BrainpoolP512r1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BrainpoolP512r1::evaluate_linear_expression(
        points,
        scalars,
        [BrainpoolP512r1::one().neg()],
    );

    assert(result.is_infinity);
}

#[test]
fn test_brainpoolP512t1_msm() {
    let four = BrainpoolP512t1_Fr::from(4);
    let p_minus_4_fr = BrainpoolP512t1_Fr::modulus() - four;
    let p_minus_4 = BrainpoolP512t1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BrainpoolP512t1_Fr::one();
    let p_minus_5 = BrainpoolP512t1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BrainpoolP512t1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BrainpoolP512t1::evaluate_linear_expression(
        points,
        scalars,
        [BrainpoolP512t1::one().neg()],
    );

    assert(result.is_infinity);
}

#[test]
fn test_vesta_msm() {
    let four = Vesta_Fr::from(4);
    let p_minus_4_fr = Vesta_Fr::modulus() - four;
    let p_minus_4 = VestaScalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - Vesta_Fr::one();
    let p_minus_5 = VestaScalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = Vesta::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = Vesta::evaluate_linear_expression(points, scalars, [Vesta::one().neg()]);

    assert(result.is_infinity);
}

#[test]
fn test_secp192r1_msm() {
    let four = Secp192r1_Fr::from(4);
    let p_minus_4_fr = Secp192r1_Fr::modulus() - four;
    let p_minus_4 = Secp192r1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - Secp192r1_Fr::one();
    let p_minus_5 = Secp192r1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = Secp192r1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = Secp192r1::evaluate_linear_expression(points, scalars, [Secp192r1::one().neg()]);
    assert(result.is_infinity);
}

#[test]
fn test_secp224r1_msm() {
    let four = Secp224r1_Fr::from(4);
    let p_minus_4_fr = Secp224r1_Fr::modulus() - four;
    let p_minus_4 = Secp224r1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - Secp224r1_Fr::one();
    let p_minus_5 = Secp224r1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = Secp224r1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = Secp224r1::evaluate_linear_expression(points, scalars, [Secp224r1::one().neg()]);
    assert(result.is_infinity);
}

#[test]
fn test_brainpoolP192r1_msm() {
    let four = BrainpoolP192r1_Fr::from(4);
    let p_minus_4_fr = BrainpoolP192r1_Fr::modulus() - four;
    let p_minus_4 = BrainpoolP192r1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BrainpoolP192r1_Fr::one();
    let p_minus_5 = BrainpoolP192r1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BrainpoolP192r1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BrainpoolP192r1::evaluate_linear_expression(
        points,
        scalars,
        [BrainpoolP192r1::one().neg()],
    );

    assert(result.is_infinity);
}

#[test]
fn test_brainpoolP192t1_msm() {
    let four = BrainpoolP192t1_Fr::from(4);
    let p_minus_4_fr = BrainpoolP192t1_Fr::modulus() - four;
    let p_minus_4 = BrainpoolP192t1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BrainpoolP192t1_Fr::one();
    let p_minus_5 = BrainpoolP192t1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BrainpoolP192t1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BrainpoolP192t1::evaluate_linear_expression(
        points,
        scalars,
        [BrainpoolP192t1::one().neg()],
    );

    assert(result.is_infinity);
}

#[test]
fn test_brainpoolP224r1_msm() {
    let four = BrainpoolP224r1_Fr::from(4);
    let p_minus_4_fr = BrainpoolP224r1_Fr::modulus() - four;
    let p_minus_4 = BrainpoolP224r1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BrainpoolP224r1_Fr::one();
    let p_minus_5 = BrainpoolP224r1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BrainpoolP224r1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BrainpoolP224r1::evaluate_linear_expression(
        points,
        scalars,
        [BrainpoolP224r1::one().neg()],
    );

    assert(result.is_infinity);
}

#[test]
fn test_brainpoolP224t1_msm() {
    let four = BrainpoolP224t1_Fr::from(4);
    let p_minus_4_fr = BrainpoolP224t1_Fr::modulus() - four;
    let p_minus_4 = BrainpoolP224t1Scalar::from_bignum(p_minus_4_fr);
    let p_minus_5_fr = p_minus_4_fr - BrainpoolP224t1_Fr::one();
    let p_minus_5 = BrainpoolP224t1Scalar::from_bignum(p_minus_5_fr);
    let mut scalars = [p_minus_4, p_minus_5];
    let a = BrainpoolP224t1::one();
    let b = a.neg();
    let mut points = [a, b];

    let result = BrainpoolP224t1::evaluate_linear_expression(
        points,
        scalars,
        [BrainpoolP224t1::one().neg()],
    );

    assert(result.is_infinity);
}

#[test]
fn test_bigcurve_sub_with_hint() {
    let accumulator: MNT6_753 = BigCurve {
        x: MNT6_753_Fq::from_limbs([
            0x5b6ad7b65e3a86239c2efbdb300b8d,
            0x7d06f1a94609f8e4eb48c998d1571d,
            0x95a74f11f2fb5be7544da5c184e38d,
            0x600f8f2fdcd5e802342ebe03c3787f,
            0xc3fa8f3f017c7aed50e1a14b78f3b3,
            0xe7f3b2638fa13f65670c15eb006e99,
            0x016389a6fb,
        ]),
        y: MNT6_753_Fq::from_limbs([
            0x42eb137506b02f7665ebbe0211b768,
            0x814148c3996475176b11c4db1d356a,
            0xf97e6cd350259b5456471a2237553f,
            0x5c822035f3f7c21fc2e6f9aac5945a,
            0xa319d0923fc0ac9db23b819dcb7371,
            0xa4186459f74d57db479c998a5db03a,
            0x7f824db1,
        ]),
        is_infinity: false,
    };
    let offset_generator: MNT6_753 = BigCurve {
        x: MNT6_753_Fq::from_limbs([
            0x5b6ad7b65e3a86239c2efbdb300b8d,
            0x7d06f1a94609f8e4eb48c998d1571d,
            0x95a74f11f2fb5be7544da5c184e38d,
            0x600f8f2fdcd5e802342ebe03c3787f,
            0xc3fa8f3f017c7aed50e1a14b78f3b3,
            0xe7f3b2638fa13f65670c15eb006e99,
            0x016389a6fb,
        ]),
        y: MNT6_753_Fq::from_limbs([
            0x42eb137506b02f7665ebbe0211b768,
            0x814148c3996475176b11c4db1d356a,
            0xf97e6cd350259b5456471a2237553f,
            0x5c822035f3f7c21fc2e6f9aac5945a,
            0xa319d0923fc0ac9db23b819dcb7371,
            0xa4186459f74d57db479c998a5db03a,
            0x7f824db1,
        ]),
        is_infinity: false,
    };
    let transcript: AffineTranscript<MNT6_753_Fq> = AffineTranscript {
        lambda: MNT6_753_Fq::from_limbs([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        x3: MNT6_753_Fq::from_limbs([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
        y3: MNT6_753_Fq::from_limbs([0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
    };
    let result = accumulator.sub_with_hint(offset_generator, transcript);
    assert(result.is_infinity);
}
