pub mod scalar_field;
pub(crate) mod curve_jac;
mod test_data;
mod bigcurve_test;
pub(crate) mod utils;
pub(crate) mod curves;

use bignum::BigNum;

use crate::curve_jac::AffineTranscript;
use crate::scalar_field::ScalarField;
use std::ops::{Add, Neg, Sub};

/// Implements an elliptic curve over a prime field that is not the circuit's native field.

pub struct BigCurveParams<B> {
    pub a: B,
    pub b: B,
    pub offset_generator: [B; 2],
    pub offset_generator_final: [B; 2],
    pub one: [B; 2],
}

pub trait BigCurve<B: BigNum>: Eq + Add + Sub + Neg {
    /// Returns the x-coordinate of the point.
    fn x(self) -> B;

    /// Returns the y-coordinate of the point.
    fn y(self) -> B;

    /// Returns the a-coordinate of the curve.
    fn a() -> B;

    /// Returns the b-coordinate of the curve.
    fn b() -> B;

    /// Creates a point from its coordinates.
    fn from_coordinates(x: B, y: B, is_infinity: bool) -> Self;

    /// Returns the point at infinity (the identity element of the curve group).
    fn point_at_infinity() -> Self;

    /// Returns true if the point is the point at infinity.
    fn is_infinity(self) -> bool;

    /// Returns the canonical generator point of the curve.
    fn one() -> Self;

    /// Returns a generator point offset by a fixed value (implementation-specific).
    fn offset_generator() -> Self;

    /// Returns the final offset generator point (implementation-specific).
    fn offset_generator_final() -> Self;

    /// Validates that the point lies on the curve. May panic or fail if invalid.
    fn validate_on_curve(self);

    /// Multiplies the point by a scalar value, returning the resulting point.
    fn mul<let NScalarSlices: u32>(self, scalar: ScalarField<NScalarSlices>) -> Self;

    /// Hashes the provided `seed` to a point on the curve.
    fn hash_to_curve<let N: u32>(seed: [u8; N]) -> Self;

    /// Evaluates a linear expression involving multiple points and scalars, returning the resulting point.
    fn evaluate_linear_expression<let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>(
        mul_points: [Self; NMuls],
        mul_scalars: [ScalarField<NScalarSlices>; NMuls],
        add_points: [Self; NAdds],
    ) -> Self;
}

pub(crate) comptime fn derive_curve_impl(
    struct_def: TypeDefinition,
    field_type: Quoted,
    params: Quoted,
) -> Quoted {
    let typ = struct_def.as_type();
    quote {
        impl crate::BigCurve<$field_type> for $typ {
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
                // if is point at infinity, we're on the curve.
                // In this case just sub in a valid point for the x/y coordinates we are about to test
                let one: Self = Self::one();
                let x: $field_type = if self.is_infinity { one.x } else { self.x };
                let y: $field_type = if self.is_infinity { one.y } else { self.y };
                let xx = std::ops::Mul::mul(x, x);
                //  xxx - yy + ax + b = 0
                // (xx + a) * x - y*y + b = 0
                // validate the provided value of `y3` is correct
                bignum::bignum::evaluate_quadratic_expression(
                    [[xx, $params.a], [y, $field_type::zero()]],
                    [[false, false], [false, false]],
                    [[x], [y]],
                    [[false], [true]],
                    [$params.b],
                    [false],
                );
            }

            fn mul<let NScalarSlices: u32>(self, scalar: ScalarField<NScalarSlices>) -> Self {
                let transcript: [crate::curve_jac::AffineTranscript<$field_type>; (NScalarSlices * 5) + 6] =
                    unsafe { crate::get_mul_transcript::<NScalarSlices, $field_type, $typ>(self, scalar) };
                crate::mul_with_hint::<NScalarSlices, (NScalarSlices * 5) + 6, $field_type, $typ>(self, scalar, transcript)
            }

            fn hash_to_curve<let N: u32>(seed: [u8; N]) -> Self {
                let r = crate::utils::hash_to_curve::hash_to_curve::<$field_type, N>(seed, $params.a, $params.b);
                Self { x: r.0, y: r.1, is_infinity: false }
            }

            fn evaluate_linear_expression<let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>(
                mul_points: [Self; NMuls],
                mul_scalars: [ScalarField<NScalarSlices>; NMuls],
                add_points: [Self; NAdds],
            ) -> Self {
                let transcript: [crate::curve_jac::AffineTranscript<$field_type>; NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 + NAdds - 3] = unsafe {
                    crate::curve_jac::CurveJ::<$field_type, $typ>::compute_linear_expression_transcript(mul_points, mul_scalars, add_points).1
};
                let mut _inputs: [Self; NMuls] = [crate::BigCurve::one(); NMuls];
                let mut _scalars: [crate::scalar_field::ScalarField<NScalarSlices>; NMuls] = [crate::ScalarField::zero(); NMuls];
                for i in 0..NMuls {
                    let (input, scalar) = if mul_points[i].is_infinity {
                        (crate::BigCurve::one(), crate::scalar_field::ScalarField::zero())
                    } else {
                        (mul_points[i], mul_scalars[i])
                    };
                    _inputs[i] = input;
                    _scalars[i] = scalar;
                }
                let msm_points = _inputs;
                let scalars = _scalars;

                let mut tables: [crate::PointTable<$field_type>; NMuls] = [crate::PointTable::empty(); NMuls];
                for i in 0..NMuls {
                    let mut table_transcript: [crate::curve_jac::AffineTranscript<$field_type>; 8] = [crate::curve_jac::AffineTranscript::new(); 8];
                    for j in 0..8 {
                        table_transcript[j] = transcript[i * 8 + j];
                    }
                    tables[i] = crate::PointTable::<$field_type>::new_with_hint::<$typ>(msm_points[i], table_transcript);
                }

                // Init the accumulator from the most significant scalar slice
                let mut accumulator: Self = crate::BigCurve::offset_generator();
                let mut accumulator = crate::incomplete_add_with_hint::<$field_type, $typ>(accumulator,
                    tables[0].get::<$typ>(scalars[0].base4_slices[0] as u32),
                    transcript[8 * NMuls],
                );
                for i in 1..NMuls {
                    accumulator = crate::incomplete_add_with_hint::<$field_type, $typ>(accumulator,
                        tables[i].get::<$typ>(scalars[i].base4_slices[0] as u32),
                        transcript[8 * NMuls + i],
                    );
                }

                // Perform the "double and add" algorithm but in steps of 4 bits, using the lookup table T to extract 4-bit multiples of P
                for i in 1..NScalarSlices {
                    accumulator =
                        crate::double_with_hint::<$field_type, $typ>(accumulator, transcript[9 * NMuls + (4 + NMuls) * (i - 1)]);
                    accumulator =
                        crate::double_with_hint::<$field_type, $typ>(accumulator, transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 1]);
                    accumulator =
                        crate::double_with_hint::<$field_type, $typ>(accumulator, transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 2]);
                    accumulator =
                        crate::double_with_hint::<$field_type, $typ>(accumulator, transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 3]);
                    for j in 0..NMuls {
                        accumulator = crate::incomplete_add_with_hint::<$field_type, $typ>(accumulator,
                            tables[j].get::<$typ>(scalars[j].base4_slices[i] as u32),
                            transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 4 + j],
                        );
                    }
                }

                // 9 * Size + (4 + Size) * (NScalarSlices - 1) - 1
                // 9 + 5 * NScalarSlices - 6
                // windowed non-adjacent form can only represent odd scalar values.
                // if value is even, the result will be off by one and we need to subtract the input point
                for i in 0..NMuls {
                    accumulator = crate::conditional_incomplete_subtract_with_hint::<$field_type, $typ>(accumulator,
                        msm_points[i],
                        scalars[i].skew,
                        transcript[9 * NMuls + (4 + NMuls) * (NScalarSlices - 1) + i],
                    );
                }

                for i in 0..NAdds {
                    accumulator = crate::conditional_incomplete_add_with_hint::<$field_type, $typ>(
                        accumulator,
                        add_points[i],
                        !add_points[i].is_infinity,
                        transcript[10 * NMuls + (4 + NMuls) * (NScalarSlices - 1) + i],
                    );
                }

                accumulator = crate::sub_with_hint::<$field_type, $typ>(
                    accumulator,
                    crate::BigCurve::offset_generator_final(),
                    transcript[NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 + NAdds - 4],
                );


                accumulator
            }}

            // Expensive witness generation! Avoid if possible
            impl std::ops::Add for $typ {
                fn add(self, other: Self) -> Self {
                    let lhsJ = crate::curve_jac::CurveJ::<$field_type, $typ>::from(self);
                    let rhsJ = crate::curve_jac::CurveJ::<$field_type, $typ>::from(other);

                    let transcript = unsafe { crate::curve_jac::AffineTranscript::from_j(lhsJ.add(rhsJ).1) };

                    crate::add_with_hint::<$field_type, $typ>(self,other, transcript)
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
                    let lhsJ = crate::curve_jac::CurveJ::<$field_type, $typ>::from(self);
                    let rhsJ = crate::curve_jac::CurveJ::<$field_type, $typ>::from(other);

                    let transcript = unsafe { crate::curve_jac::AffineTranscript::from_j(lhsJ.sub(rhsJ).1) };

                    crate::sub_with_hint::<$field_type, $typ>(self, other, transcript)
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

/// Doubles a point using an `AffineTranscript` that contains inverses and output witnesses.
///
/// This method is optimized to minimize the number of calls to `evaluate_quadratic_expression`,
/// which is not necessarily the same as minimizing the number of multiplications.
pub(crate) fn double_with_hint<B: BigNum, P: BigCurve<B>>(
    point: P,
    transcript: AffineTranscript<B>,
) -> P {
    let x1 = point.x();
    let y1 = point.y();
    let lambda = transcript.lambda;
    let x3 = transcript.x3;
    let y3 = transcript.y3;

    // TODO: HANDLE CURVES WHERE A != 0
    // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed B objects!
    x3.validate_in_range();
    y3.validate_in_range();
    lambda.validate_in_range();

    // -lambda * 2y + 3*x*x + a = 0
    // validate the provided value of `lambda` is correct
    // n.b. if CurveParams::a() == 0, its inclusion shouldn't cost extra constraints...I thnk
    bignum::bignum::evaluate_quadratic_expression(
        [[x1, x1, x1], [y1, y1, B::zero()]],
        [[false, false, false], [false, false, false]],
        [[x1], [lambda]],
        [[false], [true]],
        [P::a()],
        [false],
    );

    // validate the provided value of `x3` is correct
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[lambda]],
        [[false]],
        [x3, x1, x1],
        [true, true, true],
    );

    // validate the provided value of `y3` is correct
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[x3, x1]],
        [[false, true]],
        [y3, y1],
        [false, false],
    );

    P::from_coordinates(x3, y3, false)
}

/// Adds two points together using an `AffineTranscript` that contains inverses and output witnesses.
///
/// Only incomplete formulae are used. With the use of offset generators, an honest prover should never
/// need to handle edge cases. Therefore, completeness is sacrificed for cheap soundness: instead of
/// handling edge cases, the function asserts that they do not exist by validating `x2 != x1`.
///
/// This method minimizes the number of calls to `evaluate_quadratic_expression`, which is not the same
/// as minimizing the number of multiplications. The expensive operation in `BigNum` is the modular
/// reduction. For example, `(a * b + c * d = e mod p)` is not much more expensive than `(a * b = c mod p)`.
pub(crate) fn incomplete_add_with_hint<B: BigNum, P: BigCurve<B>>(
    point: P,
    other: P,
    transcript: AffineTranscript<B>,
) -> P {
    let x1: B = point.x();
    let y1: B = point.y();
    let x2: B = other.x();
    let y2: B = other.y();
    let lambda: B = transcript.lambda;
    let x3: B = transcript.x3;
    let y3: B = transcript.y3;

    // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed B objects!
    x3.validate_in_range();
    y3.validate_in_range();
    lambda.validate_in_range();

    // no incomplete Weierstrass shenanigans here
    x1.assert_is_not_equal(x2);

    // validate the provided value of `lambda` is correct
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[x2, x1]],
        [[false, true]],
        [y2, y1],
        [true, false],
    );

    // validate the provided value of `x3` is correct
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[lambda]],
        [[false]],
        [x3, x2, x1],
        [true, true, true],
    );

    // validate the provided value of `y3` is correct
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[x3, x1]],
        [[false, true]],
        [y3, y1],
        [false, false],
    );

    P::from_coordinates(x3, y3, false)
}

/// Multiplies a point by a scalar field value, returning the resulting point.
pub fn msm<P: BigCurve<B>, B: BigNum, let NScalarSlices: u32, let NMuls: u32>(
    mul_points: [P; NMuls],
    mul_scalars: [ScalarField<NScalarSlices>; NMuls],
) -> P {
    let add_points: [P; 0] = [];
    P::evaluate_linear_expression(mul_points, mul_scalars, add_points)
}

// TODO: offset generators
//       conditional subtract, conditional add
//
/**
    * @brief Perform an ecc scalar multiplication, given an [AffineTranscript] generated via unconstrained functions
    **/
fn msm_with_hint_internal<let Size: u32, let NScalarSlices: u32, let NTranscriptSlices: u32, B: BigNum, P: BigCurve<B>>(
    mut points: [P; Size],
    mut scalars: [ScalarField<NScalarSlices>; Size],
    transcript: [AffineTranscript<B>; NTranscriptSlices],
) -> P {
    // Compute a 4-bit lookup table of multiples of P
    let mut _inputs: [P; Size] = [P::one(); Size];
    let mut _scalars: [ScalarField<NScalarSlices>; Size] = [ScalarField::zero(); Size];
    for i in 0..Size {
        let (input, scalar) = if points[i].is_infinity() {
            (P::one(), ScalarField::zero())
        } else {
            (points[i], scalars[i])
        };
        _inputs[i] = input;
        _scalars[i] = scalar;
    }
    points = _inputs;
    scalars = _scalars;

    let mut tables: [PointTable<B>; Size] = [PointTable::empty(); Size];
    for i in 0..Size {
        let mut table_transcript: [AffineTranscript<B>; 8] = [AffineTranscript::new(); 8];
        for j in 0..8 {
            table_transcript[j] = transcript[i * 8 + j];
        }
        tables[i] = crate::PointTable::new_with_hint::<P>(points[i], table_transcript);
    }

    // Init the accumulator from the most significant scalar slice
    let mut accumulator: P = P::offset_generator();
    let mut accumulator = crate::incomplete_add_with_hint::<B, P>(
        accumulator,
        tables[0].get::<P>(scalars[0].base4_slices[0] as u32),
        transcript[8 * Size],
    );

    for i in 1..Size {
        accumulator = crate::incomplete_add_with_hint::<B, P>(
            accumulator,
            tables[i].get::<P>(scalars[i].base4_slices[0] as u32),
            transcript[8 * Size + i],
        );
    }

    // Perform the "double and add" algorithm but in steps of 4 bits, using the lookup table T to extract 4-bit multiples of P
    for i in 1..NScalarSlices {
        accumulator = crate::double_with_hint::<B, P>(
            accumulator,
            transcript[9 * Size + (4 + Size) * (i - 1)],
        );
        accumulator = crate::double_with_hint::<B, P>(
            accumulator,
            transcript[9 * Size + (4 + Size) * (i - 1) + 1],
        );
        accumulator = crate::double_with_hint::<B, P>(
            accumulator,
            transcript[9 * Size + (4 + Size) * (i - 1) + 2],
        );
        accumulator = crate::double_with_hint::<B, P>(
            accumulator,
            transcript[9 * Size + (4 + Size) * (i - 1) + 3],
        );

        for j in 0..Size {
            accumulator = crate::incomplete_add_with_hint::<B, P>(
                accumulator,
                tables[j].get::<P>(scalars[j].base4_slices[i] as u32),
                transcript[9 * Size + (4 + Size) * (i - 1) + 4 + j],
            );
        }
    }

    // 9 * Size + (4 + Size) * (NScalarSlices - 1) - 1
    // 9 + 5 * NScalarSlices - 6
    // windowed non-adjacent form can only represent odd scalar values.
    // if value is even, the result will be off by one and we need to subtract the input point
    for i in 0..Size {
        accumulator = crate::conditional_incomplete_subtract_with_hint::<B, P>(
            accumulator,
            points[i],
            scalars[i].skew,
            transcript[9 * Size + (4 + Size) * (NScalarSlices - 1) + i],
        );
    }

    accumulator
}

pub(crate) fn conditional_incomplete_add_with_hint<B: BigNum, P: BigCurve<B>>(
    point: P,
    other: P,
    predicate: bool,
    transcript: AffineTranscript<B>,
) -> P {
    let operand_output = crate::incomplete_add_with_hint::<B, P>(point, other, transcript);
    if predicate {
        operand_output
    } else {
        point
    }
}

fn conditional_incomplete_subtract_with_hint<B: BigNum, P: BigCurve<B>>(
    point: P,
    other: P,
    predicate: bool,
    transcript: AffineTranscript<B>,
) -> P {
    let operand_output = crate::incomplete_subtract_with_hint::<B, P>(point, other, transcript);
    if predicate {
        operand_output
    } else {
        point
    }
}

fn incomplete_subtract_with_hint<B: BigNum, P: BigCurve<B>>(
    point: P,
    other: P,
    transcript: AffineTranscript<B>,
) -> P {
    let x1: B = point.x();
    let y1: B = point.y();
    let x2: B = other.x();
    let y2: B = other.y();
    let lambda: B = transcript.lambda;
    let x3: B = transcript.x3;
    let y3: B = transcript.y3;

    // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed BigNum objects!
    x3.validate_in_range();
    y3.validate_in_range();
    lambda.validate_in_range();

    // no incomplete Weierstrass shenanigans here
    x1.assert_is_not_equal(x2);

    // validate the provided value of `lambda` is correct
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[x2, x1]],
        [[false, true]],
        [y2, y1],
        [false, false],
    );

    // validate the provided value of `x3` is correct
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[lambda]],
        [[false]],
        [x3, x2, x1],
        [true, true, true],
    );

    // validate the provided value of `y3` is correct
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[x3, x1]],
        [[false, true]],
        [y3, y1],
        [false, false],
    );

    P::from_coordinates(x3, y3, false)
}

pub(crate) fn add_with_hint<B: BigNum, P: BigCurve<B>>(
    point: P,
    other: P,
    transcript: AffineTranscript<B>,
) -> P {
    let x1: B = point.x();
    let y1: B = point.y();
    let x2: B = other.x();
    let y2: B = other.y();
    let lambda: B = transcript.lambda;
    let x3: B = transcript.x3;
    let y3: B = transcript.y3;

    // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed B objects!
    x3.validate_in_range();
    y3.validate_in_range();
    lambda.validate_in_range();

    // TODO: we can probably optimize this boolean flag jenga mess
    let x_equal_predicate = x2.eq(x1);
    let y_equal_predicate = y2.eq(y1);
    let double_predicate = x_equal_predicate | (point.is_infinity() | other.is_infinity()); // if x1 == x2, evaluate double operation. If y1 = -y2 then we set all input/output parameters to be 0
    let infinity_predicate =
        (x_equal_predicate & !y_equal_predicate) | (point.is_infinity() & other.is_infinity());
    let evaluate_group_operation_predicate: bool =
        !infinity_predicate & !point.is_infinity() & !other.is_infinity();

    // If we are skipping the evaluation of a group operation (x2 == x1, y2 == -y1 OR any input points are at infinity),
    // set input operands to 0!
    let (x1, y1, x2, y2) = if evaluate_group_operation_predicate {
        (x1, y1, x2, y2)
    } else {
        (B::zero(), B::zero(), B::zero(), B::zero())
    };

    // lambda * 2y - 3x * x = 0
    // or
    // lambda * (x2 - x1) - (y2 - y1) = 0
    let product_1_rhs_t0 = if double_predicate { y1 } else { x2 };
    let product_1_rhs_t1 = if double_predicate { y1 } else { x1.neg() };
    let product_2_lhs_t0 = if double_predicate { x1 } else { B::one() };
    let product_2_rhs_t0 = if double_predicate { x1 } else { y2 };
    let product_2_rhs_t1 = if double_predicate { x1 } else { y1.neg() };
    let product_2_rhs_t2 = if double_predicate { x1 } else { B::zero() };

    // validate the provided value of `lambda` is correct
    // if double: lambda * (y1 + y1) + x1 * (-x1 -x1 -x1) - a = 0 => lambda * 2y - 3x*x = 0
    // if add:    lambda * (x2 - x1) + 1 * (-y2 + y1) = 0 => lambda * (x2 - x1) - (y2 - y1) = 0
    let mut a_term = if x_equal_predicate
        & y_equal_predicate
        & !point.is_infinity()
        & !other.is_infinity() {
        P::a()
    } else {
        B::zero()
    };

    bignum::bignum::evaluate_quadratic_expression(
        [[lambda], [product_2_lhs_t0]],
        [[false], [false]],
        [
            [product_1_rhs_t0, product_1_rhs_t1, B::zero()],
            [product_2_rhs_t0, product_2_rhs_t1, product_2_rhs_t2],
        ],
        [[false, false, false], [true, true, true]],
        [a_term],
        [true],
    );

    // x3 = lambda * lambda - x2 - x1
    // if double, then x2 = x1 so we good
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[lambda]],
        [[false]],
        [x3, x2, x1],
        [true, true, true],
    );

    // y3 = lambda * (x1 - x3) - y1
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[x3, x1]],
        [[false, true]],
        [y3, y1],
        [false, false],
    );

    let output_is_lhs = other.is_infinity() & !point.is_infinity();
    let output_is_rhs = point.is_infinity() & !other.is_infinity();
    let mut x_out = if evaluate_group_operation_predicate {
        x3
    } else {
        x1
    };
    x_out = if output_is_lhs { point.x() } else { x_out };
    x_out = if output_is_rhs { other.x() } else { x_out };
    x_out = if infinity_predicate { B::zero() } else { x_out };
    let mut y_out = if evaluate_group_operation_predicate {
        y3
    } else {
        y1
    };
    y_out = if output_is_lhs { point.y() } else { y_out };
    y_out = if output_is_rhs { other.y() } else { y_out };
    y_out = if infinity_predicate { B::zero() } else { y_out };

    let mut infinity_out = !evaluate_group_operation_predicate;
    infinity_out = if infinity_predicate {
        true
    } else {
        infinity_out
    };
    infinity_out = if output_is_lhs {
        point.is_infinity()
    } else {
        infinity_out
    };
    infinity_out = if output_is_rhs {
        other.is_infinity()
    } else {
        infinity_out
    };

    let result: P = P::from_coordinates(x_out, y_out, infinity_out);
    result
}

pub(crate) fn sub_with_hint<B: BigNum, P: BigCurve<B>>(
    point: P,
    other: P,
    transcript: AffineTranscript<B>,
) -> P {
    let x1: B = point.x();
    let y1: B = point.y();
    let x2: B = other.x();
    let y2: B = other.y();
    let lambda: B = transcript.lambda;
    let x3: B = transcript.x3;
    let y3: B = transcript.y3;

    // we pulled x3, y3, lambda out of the ether - we need to make sure they are well-formed B objects!
    x3.validate_in_range();
    y3.validate_in_range();
    lambda.validate_in_range();

    let x_equal_predicate = x2.eq(x1);
    let y_equal_predicate = y2.eq(y1) == false;
    let double_predicate = x_equal_predicate | (point.is_infinity() | other.is_infinity()); // if x1 == x2, evaluate double operation. If y1 = -y2 then we set all input/output parameters to be 0
    let infinity_predicate: bool =
        (x_equal_predicate & !y_equal_predicate) | (point.is_infinity() & other.is_infinity());
    let evaluate_group_operation_predicate: bool =
        !infinity_predicate & !point.is_infinity() & !other.is_infinity();

    // If we are skipping the evaluation of a group operation (x2 == x1, y2 == -y1 OR any input points are at infinity),
    // set input operands to 0!
    let (x1, y1, x2, y2) = if evaluate_group_operation_predicate {
        (x1, y1, x2, y2)
    } else {
        (B::zero(), B::zero(), B::zero(), B::zero())
    };

    // lambda * 2y - 3x*x = 0
    // 3 x * x - lambda * 2y
    // lambda * (x2 - x1) - (y2 - y1) = 0
    // y1 - (y2.neg()) - lambda * (x1 - x2) = 0
    // y1 + y2 - lambda * (x1 - x2) = 0
    // 3 * x * x - lambda * 2 * y
    let product_1_rhs_t0 = if double_predicate { y1 } else { x2.neg() };
    let product_1_rhs_t1 = if double_predicate { y1 } else { x1 };
    let product_2_lhs_t0 = if double_predicate { x1 } else { B::one() };
    let product_2_rhs_t0 = if double_predicate { x1 } else { y2 };
    let product_2_rhs_t1 = if double_predicate { x1 } else { y1 };
    let product_2_rhs_t2 = if double_predicate { x1 } else { B::zero() };

    // validate the provided value of `lambda` is correct
    // if double: -lambda * (y1 + y1) + x1 * (x1 x1 x1) + a= 0 => lambda * 2y - 3x*x = 0
    // if add:    -lambda * (x1 - x2) + 1 * (y2 + y1) = 0 => lambda * (x2 - x1) - (-y2 - y1) = 0
    let a_term = if x_equal_predicate
        & y_equal_predicate
        & !point.is_infinity()
        & !other.is_infinity() {
        P::a()
    } else {
        B::zero()
    };

    bignum::bignum::evaluate_quadratic_expression(
        [[lambda], [product_2_lhs_t0]],
        [[true], [false]],
        [
            [product_1_rhs_t0, product_1_rhs_t1, B::zero()],
            [product_2_rhs_t0, product_2_rhs_t1, product_2_rhs_t2],
        ],
        [[false, false, false], [false, false, false]],
        [a_term],
        [false],
    );

    // x3 = lambda * lambda - x2 - x1
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[lambda]],
        [[false]],
        [x3, x2, x1],
        [true, true, true],
    );

    // y3 = lambda * (x1 - x3) - y1
    bignum::bignum::evaluate_quadratic_expression(
        [[lambda]],
        [[false]],
        [[x3, x1]],
        [[false, true]],
        [y3, y1],
        [false, false],
    );

    let output_is_lhs = other.is_infinity() & !point.is_infinity();
    let output_is_rhs = point.is_infinity() & !other.is_infinity();
    let mut x_out = if evaluate_group_operation_predicate {
        x3
    } else {
        x1
    };
    x_out = if output_is_lhs { point.x() } else { x_out };
    x_out = if output_is_rhs { other.x() } else { x_out };
    x_out = if infinity_predicate { B::zero() } else { x_out };
    let mut y_out = if evaluate_group_operation_predicate {
        y3
    } else {
        y1
    };
    y_out = if output_is_lhs { point.y() } else { y_out };
    y_out = if output_is_rhs {
        other.y().neg()
    } else {
        y_out
    };
    y_out = if infinity_predicate { B::zero() } else { y_out };

    let mut infinity_out = !evaluate_group_operation_predicate;
    infinity_out = if infinity_predicate {
        true
    } else {
        infinity_out
    };
    infinity_out = if output_is_lhs {
        point.is_infinity()
    } else {
        infinity_out
    };
    infinity_out = if output_is_rhs {
        other.is_infinity()
    } else {
        infinity_out
    };

    let result: P = P::from_coordinates(x_out, y_out, infinity_out);
    result
}

/// Performs an ECC scalar multiplication using an [AffineTranscript] generated via unconstrained functions.
///
/// # Arguments
///
/// * `transcript` - The affine transcript used for the operation.
/// * `scalar` - The scalar value to multiply with the elliptic curve point.
///
/// # Returns
///
/// The result of the scalar multiplication as an elliptic curve point.
///
/// # Note
///
/// This function assumes the transcript is generated using unconstrained functions.
pub(crate) fn mul_with_hint<let NScalarSlices: u32, let NTranscriptSlices: u32, B: BigNum, P: BigCurve<B>>(
    point: P,
    scalar: ScalarField<NScalarSlices>,
    transcript: [AffineTranscript<B>; NTranscriptSlices],
) -> P {
    // Compute a 4-bit lookup table of multiples of P
    let (input, scalar) = if point.is_infinity() {
        (P::one(), ScalarField::zero())
    } else {
        (point, scalar)
    };
    let T: PointTable<B> = PointTable::new_with_hint::<P>(
        input,
        [
            transcript[0],
            transcript[1],
            transcript[2],
            transcript[3],
            transcript[4],
            transcript[5],
            transcript[6],
            transcript[7],
        ],
    );

    // Init the accumulator from the most significant scalar slice
    let mut accumulator: P = P::offset_generator();
    let mut accumulator = crate::incomplete_add_with_hint::<B, P>(
        accumulator,
        T.get::<P>(scalar.base4_slices[0] as u32),
        transcript[3 + 5],
    );

    // Perform the "double and add" algorithm but in steps of 4 bits, using the lookup table T to extract 4-bit multiples of P
    for i in 1..NScalarSlices {
        accumulator = crate::double_with_hint::<B, P>(accumulator, transcript[4 + 5 * i]);
        accumulator = crate::double_with_hint::<B, P>(accumulator, transcript[5 + 5 * i]);
        accumulator = crate::double_with_hint::<B, P>(accumulator, transcript[6 + 5 * i]);
        accumulator = crate::double_with_hint::<B, P>(accumulator, transcript[7 + 5 * i]);
        accumulator = crate::incomplete_add_with_hint::<B, P>(
            accumulator,
            T.get::<P>(scalar.base4_slices[i] as u32),
            transcript[8 + 5 * i],
        );
    }

    // windowed non-adjacent form can only represent odd scalar values.
    // if value is even, the result will be off by one and we need to subtract the input point
    accumulator = crate::conditional_incomplete_subtract_with_hint::<B, P>(
        accumulator,
        input,
        scalar.skew,
        transcript[4 + 5 * NScalarSlices],
    );

    accumulator = crate::sub_with_hint::<B, P>(
        accumulator,
        P::offset_generator_final(),
        transcript[5 + 5 * NScalarSlices],
    );
    accumulator
}

fn msm_with_hint<let Size: u32, let NScalarSlices: u32, let NTranscriptSlices: u32, B: BigNum, P: BigCurve<B>>(
    mut points: [P; Size],
    mut scalars: [ScalarField<NScalarSlices>; Size],
    transcript: [AffineTranscript<B>; NTranscriptSlices],
) -> P {
    let mut accumulator = crate::msm_with_hint_internal::<Size, NScalarSlices, NTranscriptSlices, B, P>(
        points,
        scalars,
        transcript,
    );
    accumulator = crate::sub_with_hint::<B, P>(
        P::offset_generator_final(),
        accumulator,
        transcript[10 * Size + (4 + Size) * (NScalarSlices - 1)],
    );
    accumulator
}

unconstrained fn get_mul_transcript<let NScalarSlices: u32, B: BigNum, P: BigCurve<B>>(
    point: P,
    scalar: ScalarField<NScalarSlices>,
) -> [AffineTranscript<B>; 6 + NScalarSlices * 5] {
    let tmp: crate::curve_jac::CurveJ<B, P> = crate::curve_jac::CurveJ::from(point);
    let (_, transcript) = tmp.mul(scalar);
    transcript
}

/// A lookup table used for scalar multiplications using windowed non-adjacent form (WNAF).
///
/// The scalar multiplier is sliced into 4-bit chunks, each represented in WNAF (values in the range [-15, -13, ..., 15]).
/// A table `T` is computed containing point multiples corresponding to these 4-bit WNAF values: `T = ([-15[P], -13[P], ..., 15[P]])`.
///
/// The accumulator is initialized with `T[most significant WNAF slice]`.
/// For each remaining slice (starting from the most significant), the accumulator is doubled 4 times,
/// then `T[slice[i]]` is added to the accumulator.
///
/// For small multiscalar multiplications (fewer than 512 points), this approach minimizes the number of addition operations.
struct PointTable<B> {
    x: [B; 16],
    y: [B; 16],
}

impl<B: BigNum> PointTable<B> {
    pub(crate) fn empty() -> Self {
        PointTable { x: [B::zero(); 16], y: [B::zero(); 16] }
    }

    /// Constructs a `PointTable` from an input point and an `AffineTranscript` containing the required modular inverses.
    ///
    /// # Arguments
    ///
    /// * `point` - The input point to be used for constructing the table.
    /// * `transcript` - An `AffineTranscript` object that holds the necessary modular inverses.
    ///
    /// # Details
    ///
    /// See [`CurveJ::mul`] for an example of how `AffineTranscript` objects are generated and used.
    pub(crate) fn new_with_hint<P: BigCurve<B>>(
        point: P,
        transcript: [AffineTranscript<B>; 8],
    ) -> Self {
        let mut result = PointTable { x: [B::zero(); 16], y: [B::zero(); 16] };

        let D2: P = double_with_hint::<B, P>(point, transcript[0]);

        result.x[8] = point.x();
        result.y[8] = point.y();
        result.x[7] = point.x();
        result.y[7] = point.y().neg();

        let mut A = point;
        for i in 1..8 {
            A = incomplete_add_with_hint::<B, P>(A, D2, transcript[i]);
            result.x[8 + i] = A.x();
            result.y[8 + i] = A.y();
            result.x[7 - i] = A.x();
            result.y[7 - i] = A.y().neg();
        }
        result
    }

    /// Retrieves a value from the lookup table.
    ///
    /// If the backend supports efficient memory lookups, this operation can be highly efficient.
    /// For example, using the barretenberg backend, lookups on 256-bit curves may require only
    /// around 12 constraints.
    pub(crate) fn get<P: BigCurve<B>>(self, idx: u32) -> P {
        P::from_coordinates(self.x[idx], self.y[idx], false)
    }
}
