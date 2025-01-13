pub(crate) mod curves;

use dep::bignum::BigNumTrait;

/**
 * @brief Implements an elliptic curve instantiated over a prime field that is NOT the circuit's native field
 **/
pub struct BigCurve<BigNum, CurveParams> {
    pub x: BigNum,
    pub y: BigNum,
    pub is_infinity: bool,
}

trait CurveParamsTrait<BigNum>
where
    BigNum: BigNumTrait,
{
    fn offset_generator() -> [BigNum; 2];
    fn offset_generator_final() -> [BigNum; 2];
    fn one() -> [BigNum; 2];
    fn b() -> BigNum;
    fn a() -> BigNum;
}

trait BigCurveTrait {
    fn one() -> Self;
}

impl<BigNum, CurveParams> BigCurveTrait for BigCurve<BigNum, CurveParams>
where
    CurveParams: CurveParamsTrait<BigNum>,
    BigNum: BigNumTrait,
{
    fn one() -> Self {
        let result = CurveParams::one();
        Self { x: result[0], y: result[1], is_infinity: false }
    }
}

use crate::curves::bn254::BN254;

#[test]
fn test_add() {
    unsafe {
        let P = BN254::one();
    }
}
