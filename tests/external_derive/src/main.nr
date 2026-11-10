use bigcurve::{BigCurve, BN254Scalar, ScalarField};
use bigcurve::curves::bn254::{BN254_Fq, BN254_PARAMS};
use bignum::BigNum;

// A real downstream type: the macro must not name private implementation modules.
#[bigcurve::derive_curve_impl(
    quote { BN254_Fq },
    quote { BN254_PARAMS },
    quote { BN254Scalar::from(-1) },
)]
pub struct ExternalCurve {
    pub x: BN254_Fq,
    pub y: BN254_Fq,
    pub is_infinity: bool,
}

fn main() {
    let generator = ExternalCurve::one();
    let doubled = generator + generator;
    assert(doubled == doubled_reference());
    assert((generator - generator).is_infinity());
}

#[test]
fn external_derive_equal_opposite_infinity() {
    let g = std::hint::black_box(ExternalCurve::one());
    let zero = ExternalCurve::point_at_infinity();
    assert(g + g == doubled_reference());
    assert((g - g).is_infinity());
    assert((g + (-g)).is_infinity());
    assert(g + zero == g);
    assert(zero + g == g);
    assert((zero + zero).is_infinity());
}

#[test(should_fail)]
fn external_derive_wrong_output_rejects() {
    assert(
        std::hint::black_box(ExternalCurve::one()) + ExternalCurve::one() == ExternalCurve::one(),
    );
}

fn doubled_reference() -> ExternalCurve {
    ExternalCurve::from_coordinates(
        BN254_Fq::from_limbs([
            0x7816a916871ca8d3c208c16d87cfd3,
            0x44e72e131a029b85045b68181585d9,
            0x306,
        ]),
        BN254_Fq::from_limbs([
            0xa6a449e3538fc7ff3ebf7a5a18a2c4,
            0x738c0e0a7c92e7845f96b2ae9c0a68,
            0x15ed,
        ]),
        false,
    )
}
