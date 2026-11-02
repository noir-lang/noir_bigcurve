use crate::{BigCurve, ScalarField};
use crate::internal::{evaluate_linear_expression_preserving_selected_offset, find_safe_msm_offset};
use bignum::BigNum;

fn check_selected_offset<BN: BigNum, P: BigCurve<BN>>() {
    let p = P::one();
    let origin = P::offset_generator();
    let scalar = ScalarField::<2>::from(std::hint::black_box(3 as Field));
    let actual = evaluate_linear_expression_preserving_selected_offset([p], [scalar], [], origin);
    // Independent complete group operations establish the retained offset.
    let mut retained = origin;
    for _ in 0..4 {
        retained = retained + retained;
    }
    let three = p + p + p;
    assert(actual == retained + three);
    // The final complete addition must admit cancellation and equality.
    let cancelled =
        evaluate_linear_expression_preserving_selected_offset([p], [scalar], [-actual], origin);
    assert(cancelled.is_infinity());
    let doubled =
        evaluate_linear_expression_preserving_selected_offset([p], [scalar], [actual], origin);
    assert(doubled == actual + actual);
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
fn test_selected_offset_search_skips_colliding_candidate() {
    let p = crate::BN254::one();
    let scalar = ScalarField::<1>::from(std::hint::black_box(1 as Field));
    let offsets = [p, crate::BN254::offset_generator()];
    // Safety: index is used only by a constrained array lookup, followed by replay.
    let index = unsafe { find_safe_msm_offset([p], [scalar], offsets) };
    assert_eq(index, 1);
    let result =
        evaluate_linear_expression_preserving_selected_offset([p], [scalar], [], offsets[index]);
    assert(result == offsets[index] + p);
}

#[test]
fn test_selected_offset_zero_and_infinity_inputs() {
    let p = crate::BN254::one();
    let origin = crate::BN254::offset_generator();
    let points = [p, crate::BN254::point_at_infinity()];
    let scalars = [ScalarField::<1>::zero(), ScalarField::<1>::from(7)];
    let result = evaluate_linear_expression_preserving_selected_offset(
        points,
        scalars,
        [crate::BN254::point_at_infinity()],
        origin,
    );
    assert(result == origin);
}

#[test(should_fail)]
fn test_selected_offset_rejects_infinity_origin() {
    let _result = evaluate_linear_expression_preserving_selected_offset(
        [crate::BN254::one()],
        [ScalarField::<1>::from(1)],
        [],
        crate::BN254::point_at_infinity(),
    );
}

#[test(should_fail)]
fn test_selected_offset_search_rejects_exhausted_candidates() {
    let p = crate::BN254::one();
    let scalar = ScalarField::<1>::from(1);
    // Safety: this tests only witness-search failure, not constraint soundness.
    let _index = unsafe { find_safe_msm_offset([p], [scalar], [p]) };
}

#[test]
fn test_false_skew_collision_is_skipped() {
    let p = crate::BN254::one();
    let bad = -(p + p);
    let offsets = [bad, crate::BN254::offset_generator()];
    let scalar = ScalarField::<1>::from(std::hint::black_box(1 as Field));
    // Safety: constrained array lookup followed by the checked replay.
    let index = unsafe { find_safe_msm_offset([p], [scalar], offsets) };
    assert_eq(index, 1);
    let result =
        evaluate_linear_expression_preserving_selected_offset([p], [scalar], [], offsets[index]);
    assert(result == offsets[index] + p);
}

#[test(should_fail)]
fn test_false_skew_collision_replay_rejects() {
    let p = crate::BN254::one();
    let bad = -(p + p);
    let scalar = ScalarField::<1>::from(std::hint::black_box(1 as Field));
    let result = evaluate_linear_expression_preserving_selected_offset([p], [scalar], [], bad);
    assert(result == -p);
}

#[test(should_fail)]
fn test_off_curve_finite_origin_rejects() {
    let z = bignum::BN254_Fq::zero();
    let bad = crate::BN254::from_coordinates_unsafe(z, z, false);
    let result = evaluate_linear_expression_preserving_selected_offset(
        [crate::BN254::one()],
        [ScalarField::<1>::from(1)],
        [],
        bad,
    );
    assert(!result.is_infinity());
}

fn bls377_torsion_inputs() -> (crate::BLS12_377, crate::BLS12_377, crate::BLS12_377) {
    let p = crate::BLS12_377::one();
    let origin = crate::BLS12_377::offset_generator();
    let torsion = crate::BLS12_377::from_coordinates(
        -bignum::BLS12_377_Fq::one(),
        bignum::BLS12_377_Fq::zero(),
        false,
    );
    let before_additions = origin + p;
    let addend = torsion - before_additions;
    (origin, torsion, addend)
}

#[test]
fn test_torsion_final_addition_control() {
    let (origin, torsion, addend) = bls377_torsion_inputs();
    let result = evaluate_linear_expression_preserving_selected_offset(
        [crate::BLS12_377::one()],
        [ScalarField::<1>::from(1)],
        [addend],
        origin,
    );
    assert(result == torsion);
}

#[test(should_fail)]
fn test_torsion_final_doubling_rejects() {
    let (origin, torsion, addend) = bls377_torsion_inputs();
    let result = evaluate_linear_expression_preserving_selected_offset(
        [crate::BLS12_377::one()],
        [ScalarField::<1>::from(1)],
        [addend, torsion],
        origin,
    );
    assert(result.is_infinity());
}
