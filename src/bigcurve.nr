use crate::curve_jac::types::AffineTranscript;
use crate::scalar_field::ScalarField;
use bignum::BigNum;

use std::ops::{Add, Neg, Sub};

/// Compile-time parameters for a Short Weierstrass curve `y^2 = x^3 + a*x + b`.
///
/// Stores the curve coefficients, a canonical generator, and the two offset generators
/// used to avoid edge cases in incomplete addition formulas.
pub struct BigCurveParams<BN> {
    pub a: BN,
    pub b: BN,
    pub offset_generator: [BN; 2],
    pub offset_generator_final: [BN; 2],
    pub one: [BN; 2],
}

/// The core trait for elliptic curve arithmetic over a non-native field.
///
/// Represents a point on a Short Weierstrass curve `y^2 = x^3 + a*x + b` where the
/// base field is modeled by `BN: BigNum` (not the circuit's native field).
///
/// # Two-phase architecture
///
/// Expensive operations (`mul`, `Add`, `Sub`, `evaluate_linear_expression`) follow a
/// two-phase pattern:
///   1. **Unconstrained**: compute the result in Jacobian coordinates (fast, no constraints)
///   2. **Constrained**: verify the result in affine coordinates using `evaluate_quadratic_expression`
///
/// Offset generators are added before computation and subtracted after, ensuring the
/// incomplete addition formulas never encounter edge cases (equal or inverse points).
///
/// # Implementing a new curve
///
/// Use the `#[derive_curve_impl]` comptime attribute on a struct with fields
/// `x: BN`, `y: BN`, `is_infinity: bool` to auto-generate all trait methods
/// and operator impls (`Add`, `Sub`, `Neg`, `Eq`).
pub trait BigCurve<BN: BigNum>: Eq + Add + Sub + Neg {
    /// Returns the x-coordinate of the point.
    fn x(self) -> BN;

    /// Returns the y-coordinate of the point.
    fn y(self) -> BN;

    /// Returns the `a` coefficient of the curve equation `y^2 = x^3 + a*x + b`.
    fn a() -> BN;

    /// Returns the `b` coefficient of the curve equation `y^2 = x^3 + a*x + b`.
    fn b() -> BN;

    /// Construct a point from affine coordinates and an infinity flag.
    fn from_coordinates(x: BN, y: BN, is_infinity: bool) -> Self;

    /// Returns the point at infinity (the identity element of the curve group).
    fn point_at_infinity() -> Self;

    /// Returns true if the point is the point at infinity.
    fn is_infinity(self) -> bool;

    /// Returns the canonical generator point of the curve.
    fn one() -> Self;

    /// Returns the initial offset generator, added before scalar multiplication.
    ///
    /// Derived deterministically from `hash_to_curve("bigcurve offset generator")`.
    fn offset_generator() -> Self;

    /// Returns the final offset generator, subtracted after scalar multiplication.
    ///
    /// Equals `2^{4*(NScalarSlices-1)} * offset_generator`, matching the total
    /// number of doublings in the wNAF loop.
    fn offset_generator_final() -> Self;

    /// Validate that the point lies on the curve (constrained).
    ///
    /// Checks `y^2 == x^3 + a*x + b` via `evaluate_quadratic_expression`.
    /// Points at infinity are accepted unconditionally.
    fn validate_on_curve(self);

    /// Scalar multiplication: compute `scalar * self` (constrained).
    ///
    /// Uses wNAF with a 4-bit window. The scalar must be encoded as a `ScalarField`.
    fn mul<let NScalarSlices: u32>(self, scalar: ScalarField<NScalarSlices>) -> Self;

    /// Hash an arbitrary byte seed to a point on the curve (constrained).
    ///
    /// Uses try-and-increment with Poseidon2 hashing.
    fn hash_to_curve<let N: u32>(seed: [u8; N]) -> Self;

    /// Compute `sum_i(mul_scalars[i] * mul_points[i]) + sum_j(add_points[j])` (constrained).
    ///
    /// The most general operation: combines MSM with plain point additions.
    fn evaluate_linear_expression<let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>(
        mul_points: [Self; NMuls],
        mul_scalars: [ScalarField<NScalarSlices>; NMuls],
        add_points: [Self; NAdds],
    ) -> Self;
}

/// Comptime macro that generates `BigCurve` trait impl and operator overloads for a curve struct.
///
/// Applied via `#[derive_curve_impl(FieldType, PARAMS)]` on a struct with fields
/// `x: FieldType`, `y: FieldType`, `is_infinity: bool`.
///
/// Generates: `BigCurve` impl, `Add`, `Sub`, `Neg`, `Eq`.
pub comptime fn derive_curve_impl(
    struct_def: TypeDefinition,
    field_type: Quoted,
    params: Quoted,
) -> Quoted {
    let typ = struct_def.as_type();
    let CurveJ = quote { $crate::curve_jac::types::CurveJ };
    let AffineTranscript = quote { $crate::curve_jac::types::AffineTranscript };

    quote {
        impl $crate::BigCurve<$field_type> for $typ {
            fn x(self) -> $field_type {
                self.x
            }

            fn y(self) -> $field_type {
                self.y
            }

            fn a() -> $field_type {
                $params.a
            }

            fn b() -> $field_type {
                $params.b
            }   

            fn is_infinity(self) -> bool {
                self.is_infinity
            }

            fn from_coordinates(x: $field_type, y: $field_type, is_infinity: bool) -> Self {
                Self { x, y, is_infinity }
            }

            fn point_at_infinity() -> Self {
                Self { 
                    x: $field_type::zero(), 
                    y: $field_type::zero(), 
                    is_infinity: true 
                }
            }

            fn offset_generator() -> Self {
                let result: [$field_type; 2] = $params.offset_generator;
                Self { 
                    x: result[0], 
                    y: result[1], 
                    is_infinity: false 
                }
            }

            fn offset_generator_final() -> Self {
                let result: [$field_type; 2] = $params.offset_generator_final;
                Self { 
                    x: result[0], 
                    y: result[1], 
                    is_infinity: false 
                }
            }

            fn one() -> Self {
                let result: [$field_type; 2] = $params.one;
                Self { 
                    x: result[0], 
                    y: result[1], 
                    is_infinity: false 
                }
            }

            fn validate_on_curve(self) {
                // Point at infinity is trivially on the curve; substitute a valid point for the check
                let one: Self = Self::one();
                let x: $field_type = if self.is_infinity { one.x } else { self.x };
                let y: $field_type = if self.is_infinity { one.y } else { self.y };
                let xx = std::ops::Mul::mul(x, x);
                // (xx + a) * x - y*y + b = 0  i.e.  x^3 + a*x + b - y^2 = 0
                $crate::internal::evaluate_quadratic_expression(
                    [[xx, $params.a], [y, $field_type::zero()]],
                    [[false, false], [false, false]],
                    [[x], [y]],
                    [[false], [true]],
                    [$params.b],
                    [false],
                );
            }

            fn mul<let NScalarSlices: u32>(self, scalar: ScalarField<NScalarSlices>) -> Self {
                // Safety: transcript is verified step-by-step in mul_with_hint
                let transcript: [$AffineTranscript<$field_type>; (NScalarSlices * 5) + 6] =
                    unsafe { $crate::internal::get_mul_transcript::<NScalarSlices, $field_type, $typ>(self, scalar) };
                $crate::internal::mul_with_hint::<NScalarSlices, (NScalarSlices * 5) + 6, $field_type, $typ>(self, scalar, transcript)
            }

            fn hash_to_curve<let N: u32>(seed: [u8; N]) -> Self {
                let r = $crate::utils::hash_to_curve::hash_to_curve::<$field_type, N>(seed, $params.a, $params.b);
                Self { x: r.0, y: r.1, is_infinity: false }
            }

            fn evaluate_linear_expression<let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>(
                mul_points: [Self; NMuls],
                mul_scalars: [ScalarField<NScalarSlices>; NMuls],
                add_points: [Self; NAdds],
            ) -> Self {
                $crate::internal::evaluate_linear_expression::<$field_type,$typ, _, _, _>(mul_points, mul_scalars, add_points)
            }}

            // Complete addition with full edge-case handling (generates witness via Jacobian intermediates)
            impl std::ops::Add for $typ {
                fn add(self, other: Self) -> Self {
                    let lhsJ = $CurveJ::<$field_type, $typ>::from(self);
                    let rhsJ = $CurveJ::<$field_type, $typ>::from(other);
                    // Safety: Jacobian result verified via add_with_hint constraints
                    let (result_jac, j_transcript) = unsafe { lhsJ.add(rhsJ) };
                    // Safety: affine conversion verified inside add_with_hint
                    let transcript = unsafe { $crate::curve_jac::types::AffineTranscript::from_j(j_transcript) };
                    if std::runtime::is_unconstrained() {
                        $typ::from_coordinates(transcript.x3, transcript.y3, result_jac.is_infinity)
                    } else {
                        $crate::internal::add_with_hint::<$field_type, $typ>(self, other, transcript)           
                    }
                }
            }

            impl std::cmp::Eq for $typ {
                fn eq(self, other: Self) -> bool {
                    let coords_equal =
                        self.x.eq(other.x) & self.y.eq(other.y) & !self.is_infinity & !other.is_infinity;
                    let infinity = self.is_infinity & other.is_infinity;
                    coords_equal | infinity
                }
            }

            impl std::ops::Sub for $typ {
                fn sub(self, other: Self) -> Self {
                    let lhsJ = $CurveJ::<$field_type, $typ>::from(self);
                    let rhsJ = $CurveJ::<$field_type, $typ>::from(other);
                    // Safety: Jacobian result verified via sub_with_hint constraints
                    let (result_jac, j_transcript) = unsafe { lhsJ.sub(rhsJ) };
                    // Safety: affine conversion verified inside sub_with_hint
                    let transcript = unsafe { $crate::curve_jac::types::AffineTranscript::from_j(j_transcript) };
                    if std::runtime::is_unconstrained() {
                        $typ::from_coordinates(transcript.x3, transcript.y3, result_jac.is_infinity)
                    } else {
                        $crate::internal::sub_with_hint::<$field_type, $typ>(self, other, transcript)
                    }
                }
            }

            impl std::ops::Neg for $typ {
                fn neg(self) -> Self {
                    Self { 
                        x: self.x, 
                        y: std::ops::Neg::neg(self.y), 
                        is_infinity: self.is_infinity 
                    }
                }
            }        
    }
}
