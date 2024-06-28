// use dep::bignum::ArrayX;
// use dep::bignum::BigNum;
// use dep::bignum::BNExpressionInput;
// use dep::bignum::BigNumParamsTrait;
// // use dep::bignum::BigNumParams;
// use dep::bignum::U60Repr;

// use crate::scalar_field::ScalarField;

// trait BigFieldTrait {
//     fn one() -> Self;
//     fn zero() -> Self;
//     fn new() -> Self;
// }

// trait BigCurveParamsTrait<BigField> where BigField: BigFieldTrait {
//     fn a() -> Field;
//     fn b() -> Field;
//     fn one() -> ();
// }

// struct ProjectiveCurve<N, Params> {
//     x: BigNum<N, Params>,
//     y: BigNum<N, Params>,
//     z: BigNum<N, Params>,
// }

// impl<N, Params> ProjectiveCurve<N, Params> {
//     unconstrained fn add(&mut self, other: Self) where Params: BigNumParamsTrait<N> {
//         let mut Z1Z1 = self.z.__mulmod(self.z);
//         let Z2Z2 = other.z.__mulmod(other.z);
//         let mut S2 = Z1Z1.__mulmod(self.z);
//         let mut U2 = Z1Z1.__mulmod(other.x);
//         S2 = S2.__mulmod(other.y);
//         let mut U1 = Z2Z2.__mulmod(self.x);
//         let mut S1 = Z2Z2.__mulmod(other.z);
//         S1 = S1.__mulmod(self.y);
//         let mut F = S2.__submod(S1);
//         let H = U2.__submod(U1);

//         F = F.__addmod(F);
//         let mut I = H.__addmod(H);
//         I = I.__mulmod(I);
//         let mut J = H.__mulmod(I);
//         U1 = U1.__mulmod(I);
//         U2 = U1.__addmod(U1);
//         U2 = U2.__addmod(J);

//         self.x = F.__mulmod(F);
//         self.x = self.x.__submod(U2);

//         J = J.__mulmod(S1);
//         J = J.__addmod(J);

//         self.y = U1.__submod(self.x);
//         self.y = self.y.__mulmod(F);
//         self.y = self.y.__submod(J);

//         self.z = self.z.__addmod(other.z);
//         Z1Z1 = Z1Z1.__addmod(Z2Z2);
//         self.z = self.z.__mulmod(self.z);
//         self.z = self.z.__submod(Z1Z1);
//         self.z = self.z.__mulmod(H);
//         // ((Z1 + Z2)^2 - Z1Z1 - Z2Z2) * (Z1Z1X2 - Z2Z2X1)
//         // 2Z1Z2 * (Z1Z1X2 - Z2Z2X1)
//         // y2 - y1 / x2 - x1
//         // denominator D = x2 - x1
//         // x3 = LL - x2 - x1
//         // x3 . D = N - x2 - x1
//         // XD *= D
//         // y3 = L.(x1 - x3) - y1
//         // y3.D = N(x1 - x3) - y1
//         // y3.D = N(x1.D - x3.D) - y1.D
//         // x2 - x1 / y2 - y1
//         // X2.Z2^-
//         // x1 = X1 / Z1^2
//         // y1 = Y1 / Z1^3
//         // lambda = y2 - y1 / x2 - x1
//         // 1 / (x2 - x1) = X2/Z2^2 - X1/Z1^2
//     }
// }
// struct BigCurve<BigField, BigCurveParams> {
//     x: BigField,
//     y: BigField,
//     is_point_at_infinity: bool,
// }

// impl<BigField, BigCurveParams> BigCurve<BigField, BigCurveParams> {

//     // unconstrained fn compute_mul_witnesses<NScalarSlices>(self, scalar: ScalarField<NScalarSlices>) {

//     //     let table: []
//     // }
//     unconstrained fn compute_straus_point_table(
//         self,
//         a: Field,
//         b: Field
//     ) -> ([BigField; 16], [BigField; 16]) where BigField: BigFieldTrait {
//         ([BigField::new(); 16], [BigField::new(); 16])
//     }

//     fn dbl_internal(self, a: Field, b: Field) -> Self where BigField: BigFieldTrait {
//         Self { x: BigField::new(), y: BigField::new(), is_point_at_infinity: false }
//     }

//     fn add_internal(self, other: Self, a: Field, b: Field) -> Self where BigField: BigFieldTrait {
//         Self { x: BigField::new(), y: BigField::new(), is_point_at_infinity: false }
//     }

//     fn sub_internal(self, other: Self, a: Field, b: Field) -> Self where BigField: BigFieldTrait {
//         Self { x: BigField::new(), y: BigField::new(), is_point_at_infinity: false }
//     }

//     unconstrained fn mul<NScalarSlices>(
//         self: Self,
//         scalar: ScalarField<NScalarSlices>
//     ) -> Self where BigCurveParams: BigCurveParamsTrait<BigField>, BigField: BigFieldTrait {
//         // define a, d params locally to make code more readable (shouldn't affect performance) 
//         let a = BigCurveParams::a();
//         let b = BigCurveParams::b();

//         // Construct tables of precomputed point coordinates.
//         let (table_x, table_y): ([BigField; 16], [BigField; 16]) = self.compute_straus_point_table(a, b);

//         // Initialize the accumulator with the point that maps to the first (most significant) scalar slice
//         let idx = scalar.base4_slices[0];
//         let mut accumulator: Self = BigCurve { x: table_x[idx], y: table_y[idx], is_point_at_infinity: false };

//         // Execute a double-and-add subroutine
//         // 1. Compute `accumulator = accumulator * 16`
//         // 2. Extract 4-bits from the scalar multiplier and
//         //    use them to retrieve the corresponding point from our point table
//         // Note: this is similar to the "double and add" scalar multiplication method, except we use base16 instead of base2!
//         for i in 1..NScalarSlices {
//             accumulator = accumulator.dbl_internal(a, b);
//             accumulator = accumulator.dbl_internal(a, b);
//             accumulator = accumulator.dbl_internal(a, b);
//             accumulator = accumulator.dbl_internal(a, b);
//             let idx: u8 = scalar.base4_slices[i];
//             let x = table_x[idx];
//             let y = table_y[idx];
//             accumulator = accumulator.add_internal(BigCurve{ x, y, is_point_at_infinity: false }, a, b);
//         }

//         // todo fix
//         if (scalar.skew) {
//             accumulator = accumulator.sub_internal(self, a, b);
//         }
//         accumulator
//     }

//     fn montgomery_ladder(self, other: Self) {
//         // add add add add
//         /*

//         L1 = y2 - y1 / x2 - x1

//         xo1 = L1^2 - x2 - x1
//         yo1 = L1 (x1 - xo1) - y1

//         L2 = y3 - yo1 / (x3 - xo1)
//         L2 = y3 - L1(x1 - xo1) / (x3 - xo1)

//         xo2 = L2.L2 - x3 - xo1
//         yo2 = L2.(x3 - xo2) - y3

//         // etc etc

//         // dbl

//         //
//         // L = 3x.x / 2y
//         // x2 = LL - 2x
//         // y2 = L.(x - x2) - y

//         // L2 = 3x2.x2 / 2y2
//         // L2 * 2y2 = 3x2 * x2

//         // y^2 = x^3 + b
//         // x2 = (9x4) / (4yy) - 2x
//         // x2 = 9x.(y^2 - b) / 4yy - 2x
//         // x2 = 9/4.x - 9b.x/4y.y - 2x
//         // x2 = 1/4.x - 9b.x/4y.y

//         // K1x + (x2 - K2x).y^2 = 0 (x3)

//         // L2 = 3x2.x2 = 3.(9x^4 - 2x)^2 = x^8 x^5 x^2 . x^8 = y^4.x^2

//         // 9x^4 / 4y^2

//         // y^2 - b = x^3
//         // y^4 - 2by^2 + b^2 = x^6

//         // y^4 - 2by^2 + b^2 / 4yyxx

//         // y^2 / x^2  1 / x^2  1 / y^2x^2
//         */
//     }
// }
