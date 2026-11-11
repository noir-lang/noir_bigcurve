use crate::{BigCurve, ScalarField};
use crate::internal::evaluate_linear_expression_preserving_selected_offset;
use bignum::BigNum;

// The library's offset generator serves as a known-good initial offset. With two
// scalar windows the result keeps `[16]initial_offset`, which the tests compute
// with ordinary group operations.
fn sixteen_times<BN: BigNum, P: BigCurve<BN>>(point: P) -> P {
    let mut result = point;
    for _ in 0..4 {
        result = result + result;
    }
    result
}

fn check_selected_offset<BN: BigNum, P: BigCurve<BN>>() {
    let p = P::one();
    let initial_offset = P::offset_generator();
    let correction = sixteen_times(initial_offset);
    let three = ScalarField::<2>::from(std::hint::black_box(3 as Field));
    let result =
        evaluate_linear_expression_preserving_selected_offset([p], [three], [], initial_offset);
    assert(result == correction + (p + p + p));
    // The caller removes the offset with the complete `-`.
    assert(result - correction == p + p + p);
    let with_add_point = evaluate_linear_expression_preserving_selected_offset(
        [p],
        [three],
        [p + p],
        initial_offset,
    );
    assert(with_add_point - correction == p + p + p + p + p);
    // Multiplication terms that sum to infinity leave only the offset, and the
    // caller's correction cancels it.
    let zero = ScalarField::<2>::zero();
    let cancelled =
        evaluate_linear_expression_preserving_selected_offset([p], [zero], [], initial_offset);
    assert((cancelled - correction).is_infinity());
}

#[test]
fn test_selected_offset_bn254() {
    check_selected_offset::<bignum::BN254_Fq, crate::BN254>();
}

#[test]
fn test_selected_offset_secp256r1() {
    check_selected_offset::<bignum::Secp256r1_Fq, crate::Secp256r1>();
}

#[test]
fn test_selected_offset_bls381() {
    check_selected_offset::<bignum::BLS12_381_Fq, crate::BLS12_381>();
}

#[test]
fn test_selected_offset_zero_and_infinity_inputs() {
    let p = crate::BN254::one();
    let initial_offset = crate::BN254::offset_generator();
    let points = [p, crate::BN254::point_at_infinity()];
    let scalars = [ScalarField::<1>::zero(), ScalarField::<1>::from(7)];
    let result = evaluate_linear_expression_preserving_selected_offset(
        points,
        scalars,
        [crate::BN254::point_at_infinity()],
        initial_offset,
    );
    assert(result == initial_offset);
}

#[test(should_fail_with = "MSM initial offset must be finite")]
fn test_selected_offset_rejects_infinity_offset() {
    let _ = evaluate_linear_expression_preserving_selected_offset(
        [crate::BN254::one()],
        [ScalarField::<1>::from(1)],
        [],
        crate::BN254::point_at_infinity(),
    );
}

/// With scalar 1 the skew bit is false, so the replay's skew step does not
/// subtract `G`, but it still checks that the accumulator and `G` have distinct
/// x-coordinates. From the initial offset `-2G` the accumulator is `-G` at that
/// step, and the check fails.
#[test(should_fail_with = "assert_is_not_equal fail")]
fn test_selected_offset_rejects_offset_colliding_at_unused_skew_step() {
    let p = crate::BN254::one();
    let bad = -(p + p);
    let scalar = ScalarField::<1>::from(std::hint::black_box(1 as Field));
    let _ = evaluate_linear_expression_preserving_selected_offset([p], [scalar], [], bad);
}

// The `has_no_witness` tests in this file fail in witness generation, not at a
// constraint: BigNum's `evaluate_quadratic_expression` first calls an
// unconstrained hint for the quotient, and that hint asserts the relation is
// divisible by the modulus before any constraint is evaluated. They show an
// honest prover has no witness for the input; a plain test cannot reach the
// constraint itself. Each is paired with a control that passes.

/// Replays `1 * G` from the offset generator with `y_offset` added to its y.
fn replay_from_offset_with_y_offset(y_offset: bignum::BN254_Fq) -> crate::BN254 {
    let honest = crate::BN254::offset_generator();
    let initial_offset =
        crate::BN254::from_coordinates_unsafe(honest.x(), honest.y() + y_offset, false);
    evaluate_linear_expression_preserving_selected_offset(
        [crate::BN254::one()],
        [ScalarField::<1>::from(1)],
        [],
        std::hint::black_box(initial_offset),
    )
}

#[test]
fn test_on_curve_finite_offset_control() {
    let result = replay_from_offset_with_y_offset(bignum::BN254_Fq::zero());
    assert(result == crate::BN254::offset_generator() + crate::BN254::one());
}

/// Differs from the control only in the initial offset's y: the on-curve
/// relation for the initial offset has no witness.
#[test(should_fail_with = "Failed to solve brillig function")]
fn test_off_curve_finite_offset_has_no_witness() {
    let _ = replay_from_offset_with_y_offset(bignum::BN254_Fq::one());
}

/// The same for the all-zero coordinates tagged finite.
#[test(should_fail_with = "Failed to solve brillig function")]
fn test_zero_coordinate_finite_offset_has_no_witness() {
    let z = bignum::BN254_Fq::zero();
    let bad = crate::BN254::from_coordinates_unsafe(z, z, false);
    let _ = evaluate_linear_expression_preserving_selected_offset(
        [crate::BN254::one()],
        [ScalarField::<1>::from(1)],
        [],
        std::hint::black_box(bad),
    );
}
