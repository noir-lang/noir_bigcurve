use dep::bignum::ArrayX;
use dep::bignum::BigNum;
use dep::bignum::BNExpressionInput;
use dep::bignum::BigNumParamsTrait;
use dep::bignum::U60Repr;

mod scalar_field;
mod curve_jac;

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
    let two = BigNum::one().__addmod(BigNum::one());
    let P: CurveJ<3, BNParams> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };

    let scalar: ScalarField<10> = ScalarField::from(x);

    let result = foo(P, scalar);
    let expected = P.dbl().0;
    assert(result.x == expected.x);
}

unconstrained fn foo(P: CurveJ<3, BNParams>, scalar: ScalarField<10>) -> CurveJ<3, BNParams> {
    P.mul(scalar).0
}
#[test]
fn test_foo() {
    let two = BigNum::one().__addmod(BigNum::one());
    let P: CurveJ<3, BNParams> = CurveJ { x: BigNum::one(), y: two, z: BigNum::one() };

    let scalar: ScalarField<10> = ScalarField::from(2);

    let result = foo(P, scalar);
    let expected = P.dbl().0;
    assert(result.x == expected.x);
}
