use crate::bigcurve::BigCurve;
use crate::curve_jac::types::AffineTranscript;
use crate::curves::bn254::BN254;
use bignum::{BigNum, BN254_Fq as Fq};

// Build 2G, 3G and the chord transcript with field arithmetic, independently
// of the curve addition implementation and its Jacobian hint generator.
fn reference() -> (BN254, BN254, AffineTranscript<Fq>) {
    let one = Fq::one();
    let two = Fq::from(2);
    let tangent = Fq::from(3) / Fq::from(4);
    let x2 = tangent * tangent - two;
    let y2 = tangent * (one - x2) - two;
    let lambda = (y2 - two) / (x2 - one);
    let x3 = lambda * lambda - one - x2;
    let y3 = lambda * (one - x3) - two;
    (
        BN254::from_coordinates(x2, y2, false), BN254::from_coordinates(x3, y3, false),
        AffineTranscript { lambda, x3, y3 },
    )
}

fn checked_generator_alias(alias_x: bool, alias_y: bool) -> BN254 {
    let mut x = Fq::one().get_limbs();
    let mut y = Fq::from(2).get_limbs();
    if alias_x {
        x = Fq::modulus().get_limbs();
        x[0] += 1;
    }
    if alias_y {
        y = Fq::modulus().get_limbs();
        y[0] += 2;
    }
    BN254::from_coordinates(
        Fq::from_limbs(std::hint::black_box(x)),
        Fq::from_limbs(std::hint::black_box(y)),
        false,
    )
}

#[test]
fn test_complete_add_accepts_bounded_aliases_both_orders() {
    for aliases in [[true, false], [false, true], [true, true]] {
        let p = checked_generator_alias(aliases[0], aliases[1]);
        let (q, expected, _) = std::hint::black_box(reference());
        assert(p + q == expected);
        assert(q + p == expected);
    }
}

#[test]
fn test_complete_add_independent_transcript_both_orders() {
    for aliases in [[true, false], [false, true], [true, true]] {
        let p = checked_generator_alias(aliases[0], aliases[1]);
        let (q, expected, transcript) = std::hint::black_box(reference());
        let lhs = crate::ops::affine::add_with_hint(p, q, transcript);
        let rhs = crate::ops::affine::add_with_hint(q, p, transcript);
        assert(lhs == expected);
        assert(rhs == expected);
    }
}

/// Adds the alias generator to 2G through `add_with_hint`, using the reference
/// transcript with the given offsets added to its slope and output x.
fn add_alias_with_transcript_offsets(lambda_offset: Fq, x3_offset: Fq) -> BN254 {
    let p = checked_generator_alias(true, true);
    let (q, _, mut transcript) = reference();
    transcript.lambda = transcript.lambda + lambda_offset;
    transcript.x3 = transcript.x3 + x3_offset;
    crate::ops::affine::add_with_hint(p, q, std::hint::black_box(transcript))
}

// The two `has_no_witness` tests below differ from this control only in the
// offset. They fail in witness generation, not at a constraint: BigNum's
// quotient hint asserts each relation is divisible by the modulus before any
// constraint is evaluated. They show the altered transcript has no witness on
// alias inputs; a plain test cannot reach the constraint itself.
#[test]
fn test_complete_add_accepts_unmodified_transcript() {
    let (_, expected, _) = reference();
    assert(add_alias_with_transcript_offsets(Fq::zero(), Fq::zero()) == expected);
}

#[test(should_fail_with = "Failed to solve brillig function")]
fn test_complete_add_corrupted_lambda_has_no_witness() {
    let _ = add_alias_with_transcript_offsets(Fq::one(), Fq::zero());
}

#[test(should_fail_with = "Failed to solve brillig function")]
fn test_complete_add_corrupted_output_has_no_witness() {
    let _ = add_alias_with_transcript_offsets(Fq::zero(), Fq::one());
}

/// An alias of the same point takes the doubling branch of `add`, and the
/// inverse branch of `sub`.
#[test]
fn test_complete_add_alias_of_same_point_doubles() {
    let g = std::hint::black_box(BN254::one());
    let ga = checked_generator_alias(true, true);
    let two = g + g;
    assert(g + ga == two);
    assert(ga + g == two);
    assert((g - ga).is_infinity());
}
