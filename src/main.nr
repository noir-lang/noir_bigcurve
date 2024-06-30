use dep::bignum::ArrayX;
use dep::bignum::BigNum;
use dep::bignum::BNExpressionInput;
use dep::bignum::BigNumParamsTrait;
use dep::bignum::U60Repr;

mod scalar_field;
mod curve;
mod curve_jac;

use crate::curve::BigCurve;
use crate::curve_jac::AffineTranscript;
use crate::curve_jac::CurveJ;
use crate::scalar_field::ScalarField;

struct BNParams {}
impl BigNumParamsTrait<3> for BNParams {
    fn redc_param() -> [Field; 3] {
        [
            0x000000000000000000000000000000000059785d9f353021bcebb62866fe4394, 0x0000000000000000000000000000000000d18988e8129eac1d2961a01cc04eba, 0x0000000000000000000000000000000000000000000000000000000000015291
        ]
    }
    fn modulus() -> [Field; 3] {
        [
            0x0000000000000000000000000000000000816a916871ca8d3c208c16d87cfd47, 0x00000000000000000000000000000000004e72e131a029b85045b68181585d97, 0x0000000000000000000000000000000000000000000000000000000000003064
        ]
    }
    fn double_modulus() -> [Field; 3] {
        [
            0x000000000000000000000000000000000002d522d0e3951a7841182db0f9fa8e, 0x00000000000000000000000000000000009ce5c263405370a08b6d0302b0bb2f, 0x00000000000000000000000000000000000000000000000000000000000060c8
        ]
    }
    fn k() -> u64 {
        255
    }
    fn modulus_bits() -> u64 {
        254
    }
}

type Fq = BigNum<3, BNParams>;

fn main(x: Field) {
    // let two = BigNum::one().__addmod(BigNum::one());
    // let P: CurveJ<3, BNParams> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };
    // let scalar: ScalarField<64> = ScalarField::from(x);
    // let expected = P.dbl().0;
    // let result = foo(P, scalar, expected);
    // assert(result == true);
}

unconstrained fn foo(
    P: CurveJ<3, BNParams>,
    scalar: ScalarField<64>,
    Q: CurveJ<3, BNParams>,
    K: CurveJ<3, BNParams>
) -> bool {
    let s = (P.mul(scalar));
    let fff = s.1[s.1.len() - 2];
    let so = s.0;
    assert(s.0.eq(K.neg()));
    Q.eq(s.0)
}

unconstrained fn get_transcript(P: CurveJ<3, BNParams>, scalar: ScalarField<64>) -> [AffineTranscript<3, BNParams>; 330] {
    (P.mul(scalar).1).as_array()
}

#[test]
fn test_mul() {
    let scalar_multiplier = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000; // p - 1
    let two = BigNum::one().__addmod(BigNum::one());
    let P: CurveJ<3, BNParams> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };

    let scalar: ScalarField<64> = ScalarField::from(scalar_multiplier);

    let transcript = get_transcript(P, scalar);

    let PP: BigCurve<3, BNParams> = BigCurve { x: P.x, y: P.y };
    let result = PP.mul_with_hint(scalar, transcript);

    let mut expected = PP;
    expected.y = BigNum::new() - expected.y;
    assert(result.x == expected.x);
    assert(result.y == expected.y);
}

// MUL RESULT = CurveJ { x: BigNum { limbs: [0xa47823fd000eda1bbfc18418eb3d99, 0x0ca4f07e34bbe4f5b1033127aa8d86, 0x04c1] }, 
// y: BigNum { limbs: [0x11528374493623ffae4630c74901df, 0x4db72e5c95274f7137872f19e6baa8, 0x068a] }, 
// z: BigNum { limbs: [0xae338287d1de4127e865f3f095cf8a, 0x109f23b240924ec0446d8f7aacbe49, 0x2448] } }
// -P = CurveJ { x: BigNum { limbs: [0x5f10, 0x00, 0x00] }, y: BigNum { limbs: [0x73db80, 0x00, 0x00] }, z: BigNum { limbs: [0x816a916871ca8d3c208c16d87cfcab, 0x4e72e131a029b85045b68181585d97, 0x3064] } }
// P = CurveJ { x: BigNum { limbs: [0x01, 0x00, 0x00] }, y: BigNum { limbs: [0x02, 0x00, 0x00] }, z: BigNum { limbs: [0x01, 0x00, 0x00] } }
#[test]
fn test_mul_jac() {
    let scalar_multiplier = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000000; // p - 1
    let two = BigNum::one().__addmod(BigNum::one());
    let P: CurveJ<3, BNParams> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };

    let scalar: ScalarField<64> = ScalarField::from(scalar_multiplier);

    let expected = P.add(P.dbl().0.neg()).0;
    let result = foo(P, scalar, expected, P);
    assert(result == true);
}

#[test]
fn test_add_dbl() {
    let two = BigNum::one().__addmod(BigNum::one());
    println(f"two = {two}");

    let P: CurveJ<3, BNParams> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };

    let lhs = P.dbl().0.dbl().0;
    let rhs = P.dbl().0.add(P).0.add(P).0;
    assert(lhs.eq(rhs));
}
