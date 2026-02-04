mod benchmarks;
mod tests;

mod data;

mod bigcurve;
mod scalar_field;

// Free functions and other utils, called by the BigCurve structs
pub(crate) mod utils;
pub(crate) mod ops;
pub(crate) mod curve_jac;

// Internal functions required by derive macros for external crates
// Exported through the `internal` submodule to make it clear they are not
// intended for direct use by end users
pub mod internal {}

//// Re-export affine PointTable so tests and external callers can use crate::PointTable
//pub(crate) use crate::ops::point_table::PointTable;
//
//// Re-export ops so derive macro and tests can use crate::add_with_hint, crate::mul_with_hint, etc.
//pub(crate) use crate::ops::affine::{
//    add_with_hint, double_with_hint, incomplete_add_with_hint, sub_with_hint,
//    conditional_incomplete_add_with_hint, conditional_incomplete_subtract_with_hint,
//};
//pub(crate) use crate::ops::msm::{
//    evaluate_linear_expression, get_mul_transcript, mul_with_hint,
//};

// Re-export the main structs so that users on't have to specify the paths
pub use bigcurve::BigCurve;
pub use bigcurve::BigCurveParams;
pub use bigcurve::derive_curve_impl;
pub use scalar_field::ScalarField;

// Pre-defined curves and `BigCurve`s for people to use:
pub mod curves;

// Re-export the pre-defied bigcurve types, for easier access:
pub use curves::bls12_377::BLS12_377;
pub use curves::bls12_381::BLS12_381;
pub use curves::bn254::BN254;
pub use curves::mnt4_753::MNT4_753;
pub use curves::mnt6_753::MNT6_753;
pub use curves::pallas::Pallas;
pub use curves::secp256k1::Secp256k1;
pub use curves::secp256r1::Secp256r1;
pub use curves::secp384r1::Secp384r1;
pub use curves::vesta::Vesta;
