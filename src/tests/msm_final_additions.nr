use crate::{BigCurve, evaluate_linear_expression_complete};
use crate::curve_jac::types::AffineTranscript;
use crate::scalar_field::ScalarField;
use bignum::{BigNum, BN254_Fq as Fq};

// Before its final additions the accumulator is F + sum(s_i P_i) plus earlier
// add points, where F = offset_generator_final is public. An add point equal to
// that accumulator or its inverse is therefore easy to construct.
fn exceptional_inputs<BN: BigNum, P: BigCurve<BN>, let NScalarSlices: u32>() -> (P, ScalarField<NScalarSlices>, P) {
    let p = P::one();
    let scalar = ScalarField::<NScalarSlices>::from(std::hint::black_box(3 as Field));
    let before_additions = P::offset_generator_final() + (p + p + p);
    (p, scalar, before_additions)
}

fn check_complete_accepts_exceptional<BN: BigNum, P: BigCurve<BN>, let NScalarSlices: u32>() {
    let (p, scalar, before_additions) = exceptional_inputs::<BN, P, NScalarSlices>();
    let f = P::offset_generator_final();
    // Independent complete group operations give the expected results.
    let cancelled = evaluate_linear_expression_complete([p], [scalar], [-before_additions]);
    assert(cancelled == -f);
    let doubled = evaluate_linear_expression_complete([p], [scalar], [before_additions]);
    assert(doubled == (before_additions + before_additions) - f);
    // The second add point cancels the accumulator left by the first.
    let q = p + p;
    let pair = evaluate_linear_expression_complete([p], [scalar], [q, -(before_additions + q)]);
    assert(pair == -f);
}

fn check_both_agree_on_ordinary_inputs<BN: BigNum, P: BigCurve<BN>, let NScalarSlices: u32>() {
    let p = P::one();
    let scalars = [
        ScalarField::<NScalarSlices>::from(std::hint::black_box(5 as Field)),
        ScalarField::<NScalarSlices>::from(std::hint::black_box(7 as Field)),
    ];
    let adds = [p + p, P::point_at_infinity(), p];
    // 5P + 7(2P) + 2P + P = 22P, by repeated complete addition.
    let mut expected = P::point_at_infinity();
    for _ in 0..22 {
        expected = expected + p;
    }
    assert(P::evaluate_linear_expression([p, p + p], scalars, adds) == expected);
    assert(evaluate_linear_expression_complete([p, p + p], scalars, adds) == expected);
}

#[test]
fn test_complete_final_additions_accept_exceptional_bn254() {
    check_complete_accepts_exceptional::<bignum::BN254_Fq, crate::BN254, crate::curves::bn254::BN254_SCALAR_SLICES>();
}

#[test]
fn test_complete_final_additions_accept_exceptional_secp256r1() {
    check_complete_accepts_exceptional::<bignum::Secp256r1_Fq, crate::Secp256r1, crate::curves::secp256r1::SECP256r1_SCALAR_SLICES>();
}

#[test]
fn test_complete_final_additions_accept_exceptional_bls381() {
    check_complete_accepts_exceptional::<bignum::BLS12_381_Fq, crate::BLS12_381, crate::curves::bls12_381::BLS12_381_SCALAR_SLICES>();
}

#[test]
fn test_final_additions_agree_on_ordinary_inputs_bn254() {
    check_both_agree_on_ordinary_inputs::<bignum::BN254_Fq, crate::BN254, crate::curves::bn254::BN254_SCALAR_SLICES>();
}

#[test]
fn test_final_additions_agree_on_ordinary_inputs_secp256r1() {
    check_both_agree_on_ordinary_inputs::<bignum::Secp256r1_Fq, crate::Secp256r1, crate::curves::secp256r1::SECP256r1_SCALAR_SLICES>();
}

#[test(should_fail_with = "assert_is_not_equal")]
fn test_incomplete_final_addition_rejects_cancellation() {
    let (p, scalar, before_additions) = exceptional_inputs::<bignum::BN254_Fq, crate::BN254, crate::curves::bn254::BN254_SCALAR_SLICES>();
    let _ = crate::BN254::evaluate_linear_expression([p], [scalar], [-before_additions]);
}

#[test(should_fail_with = "assert_is_not_equal")]
fn test_incomplete_final_addition_rejects_equality() {
    let (p, scalar, before_additions) = exceptional_inputs::<bignum::BN254_Fq, crate::BN254, crate::curves::bn254::BN254_SCALAR_SLICES>();
    let _ = crate::BN254::evaluate_linear_expression([p], [scalar], [before_additions]);
}

// Soundness of the incomplete formula at the exceptional input. For P == Q the
// chord constraint lambda * (x2 - x1) = y2 - y1 reads 0 = 0, so any lambda with a
// matching (x3, y3) satisfies all three relations; only the distinct-x guard
// stops such a forged result. These tests pin that the guard, not chance,
// rejects it, including for the bounded alias x + MOD of the same point.
fn forged_equal_point_transcript() -> AffineTranscript<Fq> {
    let (x1, y1) = (Fq::one(), Fq::from(2));
    let lambda = Fq::from(5);
    let x3 = lambda * lambda - x1 - x1;
    let y3 = Fq::zero() - lambda * (x3 - x1) - y1;
    AffineTranscript { lambda, x3, y3 }
}

fn generator_x_alias() -> crate::BN254 {
    let mut x = Fq::modulus().get_limbs();
    x[0] += 1;
    crate::BN254::from_coordinates(Fq::from_limbs(std::hint::black_box(x)), Fq::from(2), false)
}

#[test]
fn test_forged_equal_point_transcript_satisfies_chord_relations() {
    let t = forged_equal_point_transcript();
    let (x1, y1) = (Fq::one(), Fq::from(2));
    assert(t.lambda * (x1 - x1) == y1 - y1);
    assert(t.lambda * t.lambda == t.x3 + x1 + x1);
    assert(t.lambda * (t.x3 - x1) + t.y3 + y1 == Fq::zero());
    // The forged output is not the true double.
    let g = crate::BN254::one();
    assert(crate::BN254::from_coordinates_unsafe(t.x3, t.y3, false) != g + g);
}

#[test(should_fail_with = "assert_is_not_equal")]
fn test_incomplete_add_guard_rejects_forged_equal_point() {
    let g = crate::BN254::one();
    let _ = crate::ops::affine::incomplete_add_with_hint(
        g,
        g,
        std::hint::black_box(forged_equal_point_transcript()),
    );
}

#[test(should_fail_with = "assert_is_not_equal")]
fn test_incomplete_add_guard_rejects_forged_equal_point_alias() {
    let g = crate::BN254::one();
    let _ = crate::ops::affine::incomplete_add_with_hint(
        g,
        generator_x_alias(),
        std::hint::black_box(forged_equal_point_transcript()),
    );
}

#[test(should_fail)]
fn test_complete_add_rejects_forged_equal_point() {
    let g = crate::BN254::one();
    let _ = crate::ops::affine::add_with_hint(
        g,
        g,
        std::hint::black_box(forged_equal_point_transcript()),
    );
}
