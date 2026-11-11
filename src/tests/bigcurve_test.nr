use bignum::BigNum;
use bignum::BN254_Fq;
use bignum::MNT6_753_Fq;
use bignum::Secp256r1_Fq;
use std::ops::{Add, Neg, Sub};

use crate::bigcurve::BigCurve;
use crate::curve_jac;
use crate::curve_jac::types::AffineTranscript;
use crate::curve_jac::types::CurveJ;
use crate::curve_jac::types::JTranscript;
use crate::curves::bls12_377::{BLS12_377, BLS12_377_Fq};
use crate::curves::bn254::{BN254, BN254J, BN254Scalar};
use crate::curves::mnt6_753::MNT6_753;
use crate::curves::secp256r1::{Secp256r1, Secp256r1J};
use crate::ops::point_table::PointTable;
use crate::scalar_field::ScalarField;

// ------------------------------ HELPERS ------------------------------

unconstrained fn evaluate_mul(P: BN254J, scalar: ScalarField<64>, Q: BN254J, K: BN254J) -> bool {
    let s: (CurveJ<BN254_Fq, BN254>, [AffineTranscript<BN254_Fq>; 326]) = (P.mul(scalar));
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

/// BN254 generator doubled: Q = 2 * G
fn bn254_double_generator() -> BN254 {
    BN254 {
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
    }
}

/// Compute the affine add transcript for P + Q in Jacobian coordinates
unconstrained fn add_transcript(P_affine: BN254, Q_affine: BN254) -> AffineTranscript<BN254_Fq> {
    let P = BN254J::from(P_affine);
    let Q = BN254J::from(Q_affine);
    AffineTranscript::from_j(P.incomplete_add(Q).1)
}

/// Compute the affine subtract transcript for P - Q in Jacobian coordinates
unconstrained fn sub_transcript(P_affine: BN254, Q_affine: BN254) -> AffineTranscript<BN254_Fq> {
    let P = BN254J::from(P_affine);
    let Q = BN254J::from(Q_affine);
    AffineTranscript::from_j(P.sub(Q).1)
}

unconstrained fn msm_jac_impl(scalars: [ScalarField<64>; 2]) {
    let One = BN254J::one();
    let Two = BN254J::from(bn254_double_generator());
    let result = BN254J::msm([One, Two.neg()], scalars);
    let expected = Two.neg();
    assert(result.0 == expected);
}

// ------------------------------ JACOBIAN ARITHMETIC TESTS ------------------------------

#[test]
fn add_dbl() {
    // Safety: test code
    let P = unsafe { BN254J::one() };
    // Safety: test code
    let lhs = unsafe { ((P.dbl().0).dbl()).0 };
    // Safety: test code
    let rhs = unsafe { P.dbl().0.incomplete_add(P).0.incomplete_add(P).0 };
    assert(lhs == rhs);
}

#[test]
fn dbl_transcript_has_correct_lambda() {
    // Safety: test code
    unsafe {
        let P = BN254J::one();

        let P2 = P.dbl();

        let Z_inverse = P2.1.z3.__invmod();

        let lambda = P2.1.lambda_numerator.__mul(&Z_inverse);

        let lhs = (lambda.__add(&lambda)).__mul(&P.y);
        let rhs = (P.x.__add(&P.x).__add(&P.x)).__mul(&P.x);

        assert(lhs == rhs);
    }
}

#[test]
fn add_transcript_has_correct_lambda() {
    // Safety: test code
    unsafe {
        let P = BN254J::one();

        let P2 = P.dbl();

        let Z_inverse = P2.1.z3.__invmod();
        let ZZ = Z_inverse.__mul(&Z_inverse);
        let ZZZ = ZZ.__mul(&Z_inverse);

        let x2 = P2.1.x3.__mul(&ZZ);
        let y2 = P2.1.y3.__mul(&ZZZ);

        let P3 = P.incomplete_add(P2.0);
        let Z_inverse = P3.1.z3.__invmod();

        let lambda = P3.1.lambda_numerator.__mul(&Z_inverse);

        let lhs = lambda.__mul(&x2.__sub(&P.x));
        let rhs = y2.__sub(&P.y);

        assert(lhs == rhs);
    }
}

#[test]
fn double_with_hint() {
    // Safety: test code
    unsafe {
        let P = BN254J::one();

        let P2 = P.dbl();

        let P_affine = BN254::one();

        let Z_inverse = P2.1.z3.__invmod();

        let lambda = P2.1.lambda_numerator.__mul(&Z_inverse);

        let X3 = P2.1.x3;
        let Y3 = P2.1.y3;
        let ZZ = Z_inverse.__mul(&Z_inverse);
        let ZZZ = ZZ.__mul(&Z_inverse);

        let x3 = X3.__mul(&ZZ);
        let y3 = Y3.__mul(&ZZZ);

        let transcript: AffineTranscript<BN254_Fq> = AffineTranscript { lambda, x3, y3 };
        let P2_affine =
            crate::ops::affine::double_with_hint::<BN254_Fq, BN254>(P_affine, transcript);

        assert(P2_affine.x == x3);
        assert(P2_affine.y == y3);
    }
}

#[test]
fn double_with_hint_secp256r1() {
    // Safety: test code
    unsafe {
        let P = Secp256r1J::one();

        let P2 = P.dbl();

        let P_affine = Secp256r1::one();

        let Z_inverse = P2.1.z3.__invmod();

        let lambda = P2.1.lambda_numerator.__mul(&Z_inverse);

        let X3 = P2.1.x3;
        let Y3 = P2.1.y3;
        let ZZ = Z_inverse.__mul(&Z_inverse);
        let ZZZ = ZZ.__mul(&Z_inverse);

        let x3 = X3.__mul(&ZZ);
        let y3 = Y3.__mul(&ZZZ);

        let transcript: AffineTranscript<Secp256r1_Fq> = AffineTranscript { lambda, x3, y3 };
        let P2_affine =
            crate::ops::affine::double_with_hint::<Secp256r1_Fq, Secp256r1>(P_affine, transcript);

        assert(P2_affine.x == x3);
        assert(P2_affine.y == y3);
    }
}

#[test]
fn incomplete_add_with_hint() {
    // Safety: test code
    unsafe {
        let P = BN254J::one();

        // Q = 2P
        let Q_affine = bn254_double_generator();

        let Q = BN254J::from(Q_affine);
        let R = P.incomplete_add(Q);

        let P_affine = BN254::one();

        let Z_inverse = R.1.z3.__invmod();

        let lambda = R.1.lambda_numerator.__mul(&Z_inverse);

        let X3 = R.1.x3;
        let Y3 = R.1.y3;
        let ZZ = Z_inverse.__mul(&Z_inverse);
        let ZZZ = ZZ.__mul(&Z_inverse);

        let x3 = X3.__mul(&ZZ);
        let y3 = Y3.__mul(&ZZZ);

        let transcript: AffineTranscript<BN254_Fq> = AffineTranscript { lambda, x3, y3 };
        let P2_affine = crate::ops::affine::incomplete_add_with_hint::<BN254_Fq, BN254>(
            P_affine,
            Q_affine,
            transcript,
        );

        assert(P2_affine.x == x3);
        assert(P2_affine.y == y3);
    }
}

#[test]
fn incomplete_add_matches_repeated_doubling() {
    // 4P via doubling == P + P + P + P via incomplete_add
    // Safety: test code
    unsafe {
        let P = BN254J::one();

        let lhs = P.dbl().0.dbl().0;
        let rhs = P.dbl().0.incomplete_add(P).0.incomplete_add(P).0;
        assert(lhs == rhs);
    }
}

#[test]
fn conditional_incomplete_add_returns_sum_when_predicate_true() {
    let P_affine = BN254::one();
    let Q_affine = bn254_double_generator();
    // Safety: test code
    let transcript = unsafe { add_transcript(P_affine, Q_affine) };

    let result = crate::ops::affine::conditional_incomplete_add_with_hint::<BN254_Fq, BN254>(
        P_affine,
        Q_affine,
        true,
        transcript,
    );
    assert(result.x == transcript.x3);
    assert(result.y == transcript.y3);
}

#[test]
fn conditional_incomplete_add_returns_lhs_when_predicate_false() {
    let P_affine = BN254::one();
    let Q_affine = bn254_double_generator();
    // Safety: test code
    let transcript = unsafe { add_transcript(P_affine, Q_affine) };

    let result = crate::ops::affine::conditional_incomplete_add_with_hint::<BN254_Fq, BN254>(
        P_affine,
        Q_affine,
        false,
        transcript,
    );
    assert(result.x == P_affine.x);
    assert(result.y == P_affine.y);
}

#[test]
fn conditional_incomplete_subtract_returns_difference_when_predicate_true() {
    let P_affine = BN254::one();
    let Q_affine = bn254_double_generator();
    // Safety: test code
    let transcript = unsafe { sub_transcript(P_affine, Q_affine) };

    let result = crate::ops::affine::conditional_incomplete_subtract_with_hint::<BN254_Fq, BN254>(
        P_affine,
        Q_affine,
        true,
        transcript,
    );
    assert(result.x == transcript.x3);
    assert(result.y == transcript.y3);
}

#[test]
fn conditional_incomplete_subtract_returns_lhs_when_predicate_false() {
    let P_affine = BN254::one();
    let Q_affine = bn254_double_generator();
    // Safety: test code
    let transcript = unsafe { sub_transcript(P_affine, Q_affine) };

    let result = crate::ops::affine::conditional_incomplete_subtract_with_hint::<BN254_Fq, BN254>(
        P_affine,
        Q_affine,
        false,
        transcript,
    );
    assert(result.x == P_affine.x);
    assert(result.y == P_affine.y);
}

// ------------------------------ POINT TABLE TESTS ------------------------------

#[test]
fn make_table() {
    // Safety: test code
    unsafe {
        let P: BN254J = BN254J::one();

        let mut transcript: [JTranscript<BN254_Fq>] = @[];
        let T: curve_jac::point_table::PointTable<BN254_Fq> =
            curve_jac::point_table::PointTable::new(P);
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

            let lambda = transcript[i].lambda_numerator.__mul(&z_inv);
            let zz = z_inv.__mul(&z_inv);
            let zzz = zz.__mul(&z_inv);
            let x3 = transcript[i].x3.__mul(&zz);
            let y3 = transcript[i].y3.__mul(&zzz);
            affine_transcript[i] = AffineTranscript { lambda, x3, y3 };
        }

        let P_affine = BN254::one();

        let affine_point_table: PointTable<BN254_Fq> =
            PointTable::<BN254_Fq>::new_with_hint::<BN254>(P_affine, affine_transcript);

        for i in 0..8 {
            let point: BN254 = affine_point_table.get::<BN254>(i);
            point.validate_on_curve();
        }
    }
}

// ------------------------------ SCALAR MULTIPLICATION TESTS ------------------------------

#[test]
fn mul() {
    let P = BN254::one();

    let scalar: ScalarField<64> = ScalarField::from(
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff,
    ); // p - 2
    // Safety: test code
    let transcript = unsafe { get_transcript(BN254J::from(P), scalar) };

    let result = crate::ops::msm::mul_with_hint::<64, 326, BN254_Fq, BN254>(P, scalar, transcript);

    // -2G
    let mut expected = bn254_double_generator();
    expected.y = BigNum::zero() - expected.y;
    assert(result.x == expected.x);
    assert(result.y == expected.y);
}

#[test]
fn mul_by_0() {
    let P = BN254::one();

    let scalar: ScalarField<64> = ScalarField::from(0);
    let foo: Field = ScalarField::into(scalar);
    assert(foo == 0);
    // Safety: test code
    let transcript = unsafe { get_transcript(BN254J::from(P), scalar) };

    let result = crate::ops::msm::mul_with_hint::<64, 326, BN254_Fq, BN254>(P, scalar, transcript);
    assert(result.is_infinity == true);
}

#[test]
fn mul_a_point_at_infinity() {
    let P = BN254::point_at_infinity();

    let scalar: ScalarField<64> = ScalarField::from(
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff,
    ); // p - 2
    // Safety: test code
    let transcript = unsafe { get_transcript(BN254J::from(P), scalar) };

    let result = crate::ops::msm::mul_with_hint::<64, 326, BN254_Fq, BN254>(P, scalar, transcript);
    assert(result.is_infinity == true);
}

#[test]
fn mul_jac() {
    let scalar_multiplier = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000; // p - 1
    // Safety: test code
    let P: CurveJ<BN254_Fq, BN254> = unsafe { BN254J::one() };

    let scalar: ScalarField<64> = ScalarField::from(scalar_multiplier);

    // Safety: test code
    let expected = unsafe { P.incomplete_add(P.dbl().0.neg()).0 };
    // Safety: test code
    let result = unsafe { evaluate_mul(P, scalar, expected, P) };
    assert(result == true);
}

#[test]
fn msm_jac() {
    let p_minus_2 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff; // p - 2
    let p_minus_6 = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593effffffb; // p - 6
    let scalar2: ScalarField<64> = ScalarField::from(p_minus_2);
    let scalar6: ScalarField<64> = ScalarField::from(p_minus_6);

    // Safety: test code
    unsafe {
        msm_jac_impl([scalar6, scalar2]);
    }
}

// ------------------------------ ADDITION TESTS ------------------------------

#[test]
fn constrained_add_distinct_points() {
    // Safety: test code
    unsafe {
        let P = BN254::one();
        let Q = bn254_double_generator();

        let result = BN254J::from(P.add(Q));

        let P_j = BN254J::from(P);
        let Q_j = BN254J::from(Q);
        let expected = P_j.add(Q_j).0;

        assert(result.eq(expected));
    }
}

#[test]
fn constrained_add_doubling() {
    // Safety: test code
    unsafe {
        let P = BN254::one();
        let Q = BN254::one();

        let result = BN254J::from(P.add(Q));
        let expected = BN254J::from(P).dbl().0;
        assert(result.eq(expected));
    }
}

#[test]
fn constrained_add_inverse_points() {
    // Safety: test code
    unsafe {
        let P = BN254::one();
        let Q = P.neg();
        let result = BN254J::from(P.add(Q));
        let expected = BN254J::point_at_infinity();
        assert(result.eq(expected));
    }
}

#[test]
fn constrained_add_lhs_infinity() {
    let P = BN254::point_at_infinity();
    let Q = BN254::one();
    let result = BN254J::from(P.add(Q));
    let expected = BN254J::from(Q);
    assert(result.eq(expected));
}

#[test]
fn constrained_add_rhs_infinity() {
    let P = BN254::one();
    let Q = BN254::point_at_infinity();
    let result = BN254J::from(P.add(Q));
    let expected = BN254J::from(P);
    assert(result.eq(expected));
}

#[test]
fn constrained_add_both_infinity() {
    // Safety: test code
    unsafe {
        let P = BN254::point_at_infinity();
        let Q = BN254::point_at_infinity();
        let result = BN254J::from(P.add(Q));
        let expected = BN254J::point_at_infinity();
        assert(result.eq(expected));
    }
}

#[test]
unconstrained fn unconstrained_add() {
    let P = BN254::one();
    let Q = bn254_double_generator();

    let result = BN254J::from(P.add(Q));

    let P_j = BN254J::from(P);
    let Q_j = BN254J::from(Q);
    let expected = P_j.add(Q_j).0;

    assert(result.eq(expected));
}

#[test]
unconstrained fn unconstrained_add_doubling() {
    // P + P
    let P = BN254::one();
    let Q = BN254::one();
    let P_j = BN254J::from(P);
    let result = BN254J::from(P.add(Q));
    let expected = P_j.dbl().0;
    assert(result.eq(expected));
}

#[test]
unconstrained fn unconstrained_add_lhs_infinity() {
    let P = BN254::point_at_infinity();
    let Q = BN254::one();
    let result = BN254J::from(P.add(Q));
    let expected = BN254J::from(Q);
    assert(result.eq(expected));
}

#[test]
unconstrained fn unconstrained_add_rhs_infinity() {
    let P = BN254::one();
    let Q = BN254::point_at_infinity();
    let result = BN254J::from(P.add(Q));
    let expected = BN254J::from(P);
    assert(result.eq(expected));
}

#[test]
unconstrained fn unconstrained_add_inverse_points() {
    let P = BN254::one();
    let Q = P.neg();
    let result = BN254J::from(P.add(Q));
    let expected = BN254J::point_at_infinity();
    assert(result.eq(expected));
}

#[test]
unconstrained fn unconstrained_add_both_infinity() {
    let P = BN254::point_at_infinity();
    let Q = BN254::point_at_infinity();
    let result = BN254J::from(P.add(Q));
    let expected = BN254J::point_at_infinity();
    assert(result.eq(expected));
}

// ------------------------------ SUBTRACTION TESTS ------------------------------

#[test]
fn constrained_sub_distinct_points() {
    // Safety: test code
    unsafe {
        let P = BN254::one();
        let Q = bn254_double_generator();

        let result = BN254J::from(P.sub(Q));

        let P_j = BN254J::from(P);
        let Q_j = BN254J::from(Q);
        let expected = P_j.sub(Q_j).0;

        assert(result.eq(expected));
    }
}

#[test]
fn constrained_sub_doubling() {
    // P - (-P) = 2P
    // Safety: test code
    unsafe {
        let P = BN254::one();
        let Q = BN254::one();

        let result = BN254J::from(P.sub(Q.neg()));
        let expected = BN254J::from(P).dbl().0;
        assert(result.eq(expected));
    }
}

#[test]
fn constrained_sub_equal_points() {
    // P - P = infinity
    // Safety: test code
    unsafe {
        let P = BN254::one();
        let Q = BN254::one();
        let result = BN254J::from(P.sub(Q));
        let expected = BN254J::point_at_infinity();
        assert(result.eq(expected));
    }
}

#[test]
fn constrained_sub_lhs_infinity() {
    let P = BN254::point_at_infinity();
    let Q = BN254::one();
    let result = BN254J::from(P.sub(Q));
    let expected = BN254J::from(Q.neg());
    assert(result.eq(expected));
}

#[test]
fn constrained_sub_rhs_infinity() {
    let P = BN254::one();
    let Q = BN254::point_at_infinity();
    let result = BN254J::from(P.sub(Q));
    let expected = BN254J::from(P);
    assert(result.eq(expected));
}

#[test]
fn constrained_sub_both_infinity() {
    // Safety: test code
    unsafe {
        let P = BN254::point_at_infinity();
        let Q = BN254::point_at_infinity();
        let result = BN254J::from(P.sub(Q));
        let expected = BN254J::point_at_infinity();
        assert(result.eq(expected));
    }
}

#[test]
unconstrained fn unconstrained_sub() {
    let P = BN254::one();
    let Q = bn254_double_generator();

    let result = BN254J::from(P.sub(Q));

    let P_j = BN254J::from(P);
    let Q_j = BN254J::from(Q);
    let expected = P_j.sub(Q_j).0;

    assert(result.eq(expected));
}

#[test]
unconstrained fn unconstrained_sub_doubling() {
    // doubling
    let P = BN254::one();
    let Q = BN254::one();

    let result = BN254J::from(P.sub(Q.neg()));
    let P_j = BN254J::from(P);
    let expected = P_j.dbl().0;
    assert(result.eq(expected));
}

#[test]
unconstrained fn unconstrained_sub_lhs_infinity() {
    let P = BN254::point_at_infinity();
    let Q = BN254::one();
    let result = BN254J::from(P.sub(Q));
    let expected = BN254J::from(Q.neg());
    assert(result.eq(expected));
}

#[test]
unconstrained fn unconstrained_sub_rhs_infinity() {
    let P = BN254::one();
    let Q = BN254::point_at_infinity();
    let result = BN254J::from(P.sub(Q));
    let expected = BN254J::from(P);
    assert(result.eq(expected));
}

#[test]
unconstrained fn unconstrained_sub_equal_points() {
    // P - P = infinity
    let P = BN254::one();
    let Q = BN254::one();
    let result = BN254J::from(P.sub(Q));
    let expected = BN254J::point_at_infinity();
    assert(result.eq(expected));
}

#[test]
unconstrained fn unconstrained_sub_both_infinity() {
    let P = BN254::point_at_infinity();
    let Q = BN254::point_at_infinity();
    let result = BN254J::from(P.sub(Q));
    let expected = BN254J::point_at_infinity();
    assert(result.eq(expected));
}

// ------------------------------ REGRESSION TESTS ------------------------------

#[test]
fn offset_foo() {
    let P = BN254 {
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
    let Q = BN254 {
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
fn bigcurve_sub_with_hint() {
    let accumulator = MNT6_753 {
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
    let offset_generator = MNT6_753 {
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
    let result = crate::ops::affine::sub_with_hint::<MNT6_753_Fq, MNT6_753>(
        accumulator,
        offset_generator,
        transcript,
    );
    assert(result.is_infinity);
}

#[test]
fn test_hash_to_curve_regression() {
    let P: BN254 =
        crate::utils::hash_to_curve::hash_to_curve_point::<BN254_Fq, BN254, 3>([0, 1, 2]);
    let Q: BN254 =
        crate::utils::hash_to_curve::hash_to_curve_point::<BN254_Fq, BN254, 4>([0, 1, 2, 3]);
    assert(P != Q);
}

// ------------------------------ POSSIBLE COMPLETENESS ISSUES TESTS ------------------------------

/// Incomplete addition: -offset_generator collides with the accumulator
/// at the first step of the wNAF loop, triggering the x1 != x2 assertion.
#[test(should_fail_with = "assert_is_not_equal fail")]
fn test_mul_edgecase() {
    let scalar: BN254Scalar = BN254Scalar::from(1);
    let P: BN254 = -BN254::offset_generator();
    let result: BN254 = P.mul(scalar);
    assert(result == P);
}

/// Incomplete addition: +offset_generator collides with the accumulator
/// at the first step of the wNAF loop, triggering the x1 != x2 assertion.
#[test(should_fail_with = "assert_is_not_equal fail")]
fn test_mul_edgecase_1() {
    let scalar: BN254Scalar = BN254Scalar::from(1);
    let P: BN254 = BN254::offset_generator();
    let result: BN254 = P.mul(scalar);
    assert(result == P);
}

/// Incomplete addition: a crafted scalar and point produce an accumulator
/// collision deeper in the wNAF loop, triggering the x1 != x2 assertion.
#[test(should_fail_with = "assert_is_not_equal fail")]
fn test_mul_edgecase_2() {
    let scalar: BN254Scalar = BN254Scalar::from(
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff,
    ); // p - 2
    let k: BN254Scalar = BN254Scalar::from(3);
    let P: BN254 = -(BN254::offset_generator().mul(k));
    let _: BN254 = P.mul(scalar);
}

// Two-torsion points (y == 0) exist on BLS12-377 because its cofactor is even.
// The tangent-slope relation `lambda * 2*y - 3*x^2 - a = 0` used for doubling has
// no solution there, so `double_with_hint` and the doubling branch of
// `add_with_hint` cannot be satisfied for such a point.
//
// The two `has_no_witness` tests below fail in witness generation, not at a
// constraint: BigNum's `evaluate_quadratic_expression` first calls an
// unconstrained hint for the quotient, and that hint asserts the relation is
// divisible by the modulus before any constraint is evaluated. They show an
// honest prover has no witness; `test_two_torsion_tangent_is_degenerate` states
// why none exists. Each is paired with a generator control that takes the same
// path with y != 0 and passes.

fn bls12_377_two_torsion_point() -> BLS12_377 {
    BLS12_377::from_coordinates(-BLS12_377_Fq::one(), BLS12_377_Fq::zero(), false)
}

/// A doubling transcript for `point` with slope `lambda`: `x3 = lambda^2 - 2*x`
/// and `y3 = lambda * (x - x3) - y`. These satisfy the two output relations of
/// `double_with_hint` for any `lambda`, leaving only the tangent-slope relation
/// to decide.
fn tangent_transcript(point: BLS12_377, lambda: BLS12_377_Fq) -> AffineTranscript<BLS12_377_Fq> {
    let x3 = lambda * lambda - point.x() - point.x();
    let y3 = lambda * (point.x() - x3) - point.y();
    AffineTranscript { lambda, x3, y3 }
}

#[test]
fn test_two_torsion_input_is_on_curve() {
    let point = bls12_377_two_torsion_point();
    assert(!point.is_infinity());
    assert(point.y() == BLS12_377_Fq::zero());
}

/// At y == 0 the tangent-slope relation reads `lambda * 0 == 3*x^2 + a`, and the
/// right-hand side is non-zero, so no `lambda` satisfies it.
#[test]
fn test_two_torsion_tangent_is_degenerate() {
    let s = bls12_377_two_torsion_point();
    assert(s.y() + s.y() == BLS12_377_Fq::zero());
    let rhs = s.x() * s.x() * BLS12_377_Fq::from(3) + BLS12_377::a();
    assert(!(rhs == BLS12_377_Fq::zero()));
}

/// Control: with y != 0 the slope `(3*x^2 + a) / (2*y)` exists, and both
/// `double_with_hint` and `add` of a point with itself accept it.
#[test]
fn test_doubling_generator_control() {
    let g = std::hint::black_box(BLS12_377::one());
    let numerator = g.x() * g.x() * BLS12_377_Fq::from(3) + BLS12_377::a();
    let lambda = numerator / (g.y() + g.y());
    let doubled = crate::ops::affine::double_with_hint::<BLS12_377_Fq, BLS12_377>(
        g,
        tangent_transcript(g, lambda),
    );
    assert(!doubled.is_infinity());
    assert(doubled == g.add(g));
}

/// `double_with_hint` on a two-torsion point. The transcript's outputs are
/// consistent with its slope, so only the tangent-slope relation is
/// unsatisfied; the slope value is arbitrary because none works.
#[test(should_fail_with = "Failed to solve brillig function")]
fn test_double_with_hint_two_torsion_has_no_witness() {
    let s = std::hint::black_box(bls12_377_two_torsion_point());
    let _ = crate::ops::affine::double_with_hint::<BLS12_377_Fq, BLS12_377>(
        s,
        tangent_transcript(s, BLS12_377_Fq::one()),
    );
}

/// Adding a two-torsion point to itself takes the doubling branch of
/// `add_with_hint`, with the same unsatisfiable tangent-slope relation.
#[test(should_fail_with = "Failed to solve brillig function")]
fn test_add_two_torsion_to_itself_has_no_witness() {
    let s = std::hint::black_box(bls12_377_two_torsion_point());
    let _ = s.add(s);
}

// ------------------------------ SUBGROUP MEMBERSHIP TESTS ------------------------------

/// The BLS12-377 generator is in G1, so r * G == O.
#[test]
fn test_validate_in_subgroup_valid_point() {
    let generator: BLS12_377 = BLS12_377::one();
    generator.validate_in_subgroup();
}

// Every curve's generator lies in G1, so these catch a wrong `r - 1` passed to
// `derive_curve_impl`.
#[test]
fn test_validate_in_subgroup_generator_bls12_381() {
    crate::curves::bls12_381::BLS12_381::one().validate_in_subgroup();
}

#[test]
fn test_validate_in_subgroup_generator_bn254() {
    crate::curves::bn254::BN254::one().validate_in_subgroup();
}

#[test]
fn test_validate_in_subgroup_generator_mnt4_753() {
    crate::curves::mnt4_753::MNT4_753::one().validate_in_subgroup();
}

#[test]
fn test_validate_in_subgroup_generator_mnt6_753() {
    crate::curves::mnt6_753::MNT6_753::one().validate_in_subgroup();
}

#[test]
fn test_validate_in_subgroup_generator_pallas() {
    crate::curves::pallas::Pallas::one().validate_in_subgroup();
}

#[test]
fn test_validate_in_subgroup_generator_vesta() {
    crate::curves::vesta::Vesta::one().validate_in_subgroup();
}

#[test]
fn test_validate_in_subgroup_generator_secp256k1() {
    crate::curves::secp256k1::Secp256k1::one().validate_in_subgroup();
}

#[test]
fn test_validate_in_subgroup_generator_secp256r1() {
    crate::curves::secp256r1::Secp256r1::one().validate_in_subgroup();
}

#[test]
fn test_validate_in_subgroup_generator_secp384r1() {
    crate::curves::secp384r1::Secp384r1::one().validate_in_subgroup();
}

/// A point on BLS12-377 but not in G1 must fail the subgroup check.
/// x = 0x1826f69df0c099ec7c933639b7890b13b24189349fe88dd9aa3fef17dfffd7253f375e0c92fc9b0e9578bd044702c41
/// y = 0x9710823084bbe87e44527dc337c21ea1bc73fc65928adca328a6cb3f1894b007d108f0e42d78bf4d7adad5122779f3
#[test(should_fail_with = "Point is not in the prime-order subgroup")]
fn test_validate_in_subgroup_invalid_point() {
    let x: BLS12_377_Fq = BLS12_377_Fq::from_le_bytes([
        0x41, 0x2c, 0x70, 0x44, 0xd0, 0x8b, 0x57, 0xe9, 0xb0, 0xc9, 0x2f, 0xc9, 0xe0, 0x75, 0xf3,
        0x53, 0x72, 0xfd, 0xff, 0x7d, 0xf1, 0xfe, 0xa3, 0x9a, 0xdd, 0x88, 0xfe, 0x49, 0x93, 0x18,
        0x24, 0x3b, 0xb1, 0x90, 0x78, 0x9b, 0x63, 0x33, 0xc9, 0xc7, 0x9e, 0x9, 0xc, 0xdf, 0x69,
        0x6f, 0x82, 0x1,
    ]);
    let y: BLS12_377_Fq = BLS12_377_Fq::from_le_bytes([
        0xf3, 0x79, 0x27, 0x12, 0xd5, 0xda, 0x7a, 0x4d, 0xbf, 0x78, 0x2d, 0xe4, 0xf0, 0x8, 0xd1,
        0x7, 0xb0, 0x94, 0x18, 0x3f, 0xcb, 0xa6, 0x28, 0xa3, 0xdc, 0x8a, 0x92, 0x65, 0xfc, 0x73,
        0xbc, 0xa1, 0x1e, 0xc2, 0x37, 0xc3, 0x7d, 0x52, 0x44, 0x7e, 0xe8, 0xbb, 0x84, 0x30, 0x82,
        0x10, 0x97, 0x0,
    ]);
    let P: BLS12_377 = BLS12_377::from_coordinates(x, y, false);
    P.validate_in_subgroup();
}

#[test]
fn test_curvej_eq() {
    let g = std::hint::black_box(BN254::one());
    let gj = BN254J::from(g);
    let neg_gj = BN254J::from(-g);
    // Safety: test code; the doubled point is only an input to the constrained Eq.
    let two_gj = unsafe { gj.dbl().0 };
    let two_g_affine = BN254J::from(g + g);
    let o = BN254J::from(BN254::point_at_infinity());
    assert(gj == gj);
    assert(!(gj == neg_gj));
    // Same point with Z != 1 against Z = 1.
    assert(two_gj == two_g_affine);
    assert(!(two_gj == gj));
    assert(o == o);
    assert(!(o == gj));
    assert(!(gj == o));
}

#[test]
fn test_curvej_eq_ignores_tagged_infinity_payload() {
    let junk = std::hint::black_box(BN254_Fq::from_limbs_unsafe(
        [0xffffffffffffffffffffffffffffffff; 3],
    ));
    // The checked affine constructor deliberately ignores infinity coordinates.
    let tagged = BN254J::from(BN254::from_coordinates(junk, junk, true));
    let zero = BN254J::from(BN254::point_at_infinity());
    let g = BN254J::from(std::hint::black_box(BN254::one()));
    assert(tagged == zero);
    assert(zero == tagged);
    assert(!(tagged == g));
    assert(!(g == tagged));
}

/// Compares the BN254 generator (Z = 1) against a copy in which one coordinate
/// (0 = x, 1 = y, 2 = z) has a limb above the 120-bit limb range, with the
/// malformed point on the chosen side of `==`.
///
/// The Brillig multiplication hint accepts such a limb. The constrained BigNum
/// `mul` range-checks its operands, so an `eq` built from it fails here; an
/// `eq` computed by hints alone returns a bool instead.
fn curvej_eq_with_out_of_range_limb(coordinate: u32, malformed_on_lhs: bool) -> bool {
    let junk = std::hint::black_box(BN254_Fq::from_limbs_unsafe([1 << 125, 0, 0]));
    let g = BN254J::from(std::hint::black_box(BN254::one()));
    let mut p = g;
    if coordinate == 0 {
        p.x = junk;
    } else if coordinate == 1 {
        p.y = junk;
    } else {
        p.z = junk;
    }
    if malformed_on_lhs {
        p == g
    } else {
        g == p
    }
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_curvej_eq_range_checks_lhs_x() {
    let _ = curvej_eq_with_out_of_range_limb(0, true);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_curvej_eq_range_checks_lhs_y() {
    let _ = curvej_eq_with_out_of_range_limb(1, true);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_curvej_eq_range_checks_lhs_z() {
    let _ = curvej_eq_with_out_of_range_limb(2, true);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_curvej_eq_range_checks_rhs_x() {
    let _ = curvej_eq_with_out_of_range_limb(0, false);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_curvej_eq_range_checks_rhs_y() {
    let _ = curvej_eq_with_out_of_range_limb(1, false);
}

#[test(should_fail_with = "call to assert_max_bit_size")]
fn test_curvej_eq_range_checks_rhs_z() {
    let _ = curvej_eq_with_out_of_range_limb(2, false);
}

/// A point tagged finite with Z = 0 is the Jacobian encoding of infinity: it
/// equals `O` and other Z = 0 points, and no finite point.
#[test]
fn test_curvej_eq_zero_z_is_infinity() {
    let zero = std::hint::black_box(BN254_Fq::zero());
    let one = std::hint::black_box(BN254_Fq::one());
    let g = BN254J::from(std::hint::black_box(BN254::one()));
    let o = BN254J::from(BN254::point_at_infinity());
    // The all-zero placeholder returned by `CurveJ::new()`.
    let placeholder: BN254J = CurveJ { x: zero, y: zero, z: zero, is_infinity: false };
    let zero_z: BN254J = CurveJ { x: one, y: one, z: zero, is_infinity: false };

    assert(!(placeholder == g));
    assert(!(g == placeholder));
    assert(!(zero_z == g));
    assert(!(g == zero_z));

    assert(placeholder == o);
    assert(o == placeholder);
    assert(zero_z == o);
    assert(o == zero_z);
    assert(placeholder == zero_z);
    assert(zero_z == placeholder);
}

/// Doubling a point of order two gives Z3 = 2*Y*Z = 0 with the finite tag.
#[test]
fn test_curvej_eq_doubled_two_torsion_is_infinity() {
    let s = std::hint::black_box(BLS12_377::from_coordinates(
        -BLS12_377_Fq::one(),
        BLS12_377_Fq::zero(),
        false,
    ));
    let sj: CurveJ<BLS12_377_Fq, BLS12_377> = CurveJ::from(s);
    // Safety: test code; the doubled point is only an input to the constrained Eq.
    let doubled = unsafe { sj.dbl().0 };
    let o: CurveJ<BLS12_377_Fq, BLS12_377> = CurveJ::from(BLS12_377::point_at_infinity());
    assert(!doubled.is_infinity);
    assert(doubled == o);
    assert(o == doubled);
    assert(!(doubled == sj));
    assert(!(sj == doubled));
}

fn p256_point_with_zero_x() -> Secp256r1 {
    Secp256r1::from_coordinates(
        Secp256r1_Fq::zero(),
        Secp256r1_Fq::from_limbs([
            0x1c2af31dae871728bf856a174f93f4,
            0x5c780e2f83d72433bd5d84a06bb654,
            0x6648,
        ]),
        false,
    )
}

#[test]
fn test_add_infinity_and_point_with_zero_x() {
    let q = std::hint::black_box(p256_point_with_zero_x());
    let o = Secp256r1::point_at_infinity();
    let lhs = o + q;
    let rhs = q + o;
    assert(!lhs.is_infinity);
    assert(lhs == q);
    assert(!rhs.is_infinity);
    assert(rhs == q);
}

#[test]
fn test_sub_infinity_and_point_with_zero_x() {
    let q = std::hint::black_box(p256_point_with_zero_x());
    let o = Secp256r1::point_at_infinity();
    assert((o - q) == -q);
    assert((q - o) == q);
}

#[test]
fn test_add_sub_non_canonical_infinity() {
    let g = std::hint::black_box(BN254::one());
    // (g.x, -g.y): x equal and y different, the add inverse-point pattern.
    let o_add = BN254::from_coordinates(g.x, -g.y, true);
    let sum_lhs = o_add + g;
    let sum_rhs = g + o_add;
    assert(!sum_lhs.is_infinity & !sum_rhs.is_infinity);
    assert(sum_lhs == g);
    assert(sum_rhs == g);
    // (g.x, g.y): x and y equal, the sub inverse-point pattern.
    let o_sub = BN254::from_coordinates(g.x, g.y, true);
    let diff_lhs = o_sub - g;
    let diff_rhs = g - o_sub;
    assert(!diff_lhs.is_infinity & !diff_rhs.is_infinity);
    assert(diff_lhs == -g);
    assert(diff_rhs == g);
    // Two infinity inputs still give the canonical point at infinity.
    let both = o_add + o_sub;
    assert(both.is_infinity);
    assert(both.x == BN254_Fq::zero());
    assert(both.y == BN254_Fq::zero());
}

#[test]
unconstrained fn test_unconstrained_add_infinity_and_point_with_zero_x() {
    let q = p256_point_with_zero_x();
    let o = Secp256r1::point_at_infinity();
    let lhs = o + q;
    let rhs = q + o;
    assert(!lhs.is_infinity);
    assert(lhs == q);
    assert(!rhs.is_infinity);
    assert(rhs == q);
}

#[test]
unconstrained fn test_unconstrained_sub_infinity_and_point_with_zero_x() {
    let q = p256_point_with_zero_x();
    let o = Secp256r1::point_at_infinity();
    assert((o - q) == -q);
    assert((q - o) == q);
}

#[test]
unconstrained fn test_unconstrained_add_sub_non_canonical_infinity() {
    let g = BN254::one();
    // (g.x, -g.y): x equal and y different, the add inverse-point pattern.
    let o_add = BN254::from_coordinates(g.x, -g.y, true);
    let sum_lhs = o_add + g;
    let sum_rhs = g + o_add;
    assert(!sum_lhs.is_infinity & !sum_rhs.is_infinity);
    assert(sum_lhs == g);
    assert(sum_rhs == g);
    // (g.x, g.y): x and y equal, the sub inverse-point pattern.
    let o_sub = BN254::from_coordinates(g.x, g.y, true);
    let diff_lhs = o_sub - g;
    let diff_rhs = g - o_sub;
    assert(!diff_lhs.is_infinity & !diff_rhs.is_infinity);
    assert(diff_lhs == -g);
    assert(diff_rhs == g);
    // Two infinity inputs still give the canonical point at infinity.
    let both = o_add + o_sub;
    assert(both.is_infinity);
    assert(both.x == BN254_Fq::zero());
    assert(both.y == BN254_Fq::zero());
}

// -G = (1, q - 2), canonical.
fn negative_generator() -> BN254 {
    BN254::from_coordinates(
        BN254_Fq::one(),
        BN254_Fq::from_limbs([
            671967750576550571863734675757137221,
            407329191355489184324853464957476247,
            12388,
        ]),
        false,
    )
}

// The BN254 generator with y = q + 2: a bounded alias of (1, 2) admitted by
// checked construction, since the curve equation is checked modulo q.
fn generator_with_bounded_alias_y() -> BN254 {
    let mut y = BN254_Fq::modulus().get_limbs();
    y[0] += 2;
    BN254::from_coordinates(BN254_Fq::one(), BN254_Fq::from_limbs(y), false)
}

#[test]
fn test_negation_hint_accepts_bounded_alias() {
    let g = std::hint::black_box(generator_with_bounded_alias_y());
    // Safety: exercise witness generation only, then compare with a checked reference.
    let hinted = unsafe { BN254J::from(g).neg() };
    assert_eq(hinted.x.get_limbs(), g.x().get_limbs());
    assert(hinted.y == negative_generator().y());
    assert(!hinted.is_infinity);
    // Safety: exercise the infinity hint only, then check its coordinates and tag.
    let infinity = unsafe { BN254J::from(BN254::point_at_infinity()).neg() };
    assert(infinity.is_infinity);
    assert(infinity.y == BN254_Fq::zero());
}

#[test]
fn test_point_table_hint_accepts_bounded_alias() {
    let p = BN254J::from(generator_with_bounded_alias_y());
    // Safety: the checked alias is on curve; verify the returned hint below.
    let t = unsafe { crate::curve_jac::point_table::PointTable::new(p) };
    // Safety: table lookup is a hint; checked modular equality follows.
    let neg: BN254J = unsafe { t.get(7) };
    assert(neg == BN254J::from(-BN254::one()));
}

#[test]
fn test_point_table_accepts_bounded_alias() {
    let p = generator_with_bounded_alias_y();
    // Safety: independently generate the canonical control transcript.
    let t = unsafe { crate::curve_jac::point_table::PointTable::new(BN254J::from(BN254::one())) };
    // Safety: the constrained table validates the transcript.
    let transcript = unsafe { AffineTranscript::from_jacobian_transcript(t.transcript) };
    let table = PointTable::new_with_hint(p, transcript);
    assert(table.get::<BN254>(7) == -BN254::one());
}

#[test]
fn test_point_table_accepts_bounded_alias_hints() {
    let g = std::hint::black_box(BN254::one());
    // Safety: a canonical independent transcript for the fixed generator.
    let t = unsafe { crate::curve_jac::point_table::PointTable::new(BN254J::from(g)) };
    // Safety: hint values are validated by the constrained table below.
    let mut transcript = unsafe { AffineTranscript::from_jacobian_transcript(t.transcript) };
    let expected_y = -transcript[2].y3;
    let mut limbs = transcript[2].y3.get_limbs();
    let q = BN254_Fq::modulus().get_limbs();
    let mut carry: u128 = 0;
    for i in 0..3 {
        let sum = limbs[i] + q[i] + carry;
        limbs[i] = sum & ((1 << 120) - 1);
        carry = sum >> 120;
    }
    let alias = BN254_Fq::from_limbs(limbs);
    alias.validate_in_range();
    assert(alias == transcript[2].y3);
    transcript[2].y3 = alias;
    let table = PointTable::new_with_hint(g, transcript);
    assert(table.get::<BN254>(5).y() == expected_y);
}

/// Builds the constrained generator table from an honest transcript with
/// `lambda_offset` added to one slope.
fn generator_point_table_with_lambda_offset(lambda_offset: BN254_Fq) -> PointTable<BN254_Fq> {
    let g = std::hint::black_box(BN254::one());
    // Safety: independently generated canonical transcript.
    let t = unsafe { crate::curve_jac::point_table::PointTable::new(BN254J::from(g)) };
    // Safety: the constrained table validates the transcript.
    let mut transcript = unsafe { AffineTranscript::from_jacobian_transcript(t.transcript) };
    transcript[2].lambda = transcript[2].lambda + lambda_offset;
    PointTable::new_with_hint(g, transcript)
}

/// Control for the test below: the unmodified transcript is accepted.
#[test]
fn test_point_table_accepts_honest_transcript() {
    let table = generator_point_table_with_lambda_offset(BN254_Fq::zero());
    assert(table.get::<BN254>(8) == BN254::one());
    assert(table.get::<BN254>(7) == -BN254::one());
}

/// With one slope off by one the table's addition relation has no witness.
/// This fails in witness generation, not at a constraint: BigNum's quotient
/// hint asserts the relation is divisible by the modulus before any constraint
/// is evaluated. It differs from the control above only in the offset.
#[test(should_fail_with = "Failed to solve brillig function")]
fn test_point_table_corrupted_lambda_has_no_witness() {
    let _ = generator_point_table_with_lambda_offset(BN254_Fq::one());
}

#[test]
fn test_mul_accepts_bounded_alias() {
    let g = std::hint::black_box(generator_with_bounded_alias_y());
    let s: ScalarField<64> = ScalarField::from(1 as Field);
    assert(g.mul(s) == BN254::one());
}

// -2G, canonical.
fn negative_double_generator() -> BN254 {
    BN254::from_coordinates(
        BN254_Fq::from_limbs([
            623535232566935105136899006107471827,
            357765073405947042246255106629928409,
            774,
        ]),
        BN254_Fq::from_limbs([
            1135942298659705583010493357529258627,
            1136602398624662810299021592591356718,
            6774,
        ]),
        false,
    )
}

#[test]
fn test_sub_accepts_bounded_alias() {
    let p = negative_generator();
    let g = generator_with_bounded_alias_y();
    assert(p - g == negative_double_generator());
}
