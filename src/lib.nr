pub(crate) mod curves;

use dep::bignum::BigNum;
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

/**
 * @brief A lookup table we use when performing scalar multiplications.
 * @description We slice scalar multiplier into 4 bit chunks represented
 * in windowed non-adjacent form ([-15, -13, ..., 15])
 * We compute a table of point multiples that map to the 4-bit WNAF values T = ([-15[P], -13[P], ..., 15[P]])
 * We set an accumulator to equal T[most significant WNAF slice]
 * We then iterate over our remaining bit slices (starting with most significant slice)
 * For each iteration `i` we double the accumulator 4 times and then add `T[slice[i]]` into the accumulator.
 * For small multiscalar multiplications (i.e. <512 points) this produces the minimal number of addition operations.
 **/
struct PointTable<BigNum> {
    x: [BigNum; 16],
    y: [BigNum; 16],
}

impl<BigNum> PointTable<BigNum>
where
    BigNum: BigNumTrait,
{
    pub(crate) fn empty() -> Self {
        PointTable { x: [BigNum::new(); 16], y: [BigNum::new(); 16] }
    }

    /**
     * @brief get a value out of the lookup table
     * @description if the backend has an efficient implementation of memory lookups,
     * this will be very efficient (~12 constraints for 256-bit curves using the barretenberg backend)
     **/
    pub(crate) fn get<CurveParams>(self, idx: u8) -> BigCurve<BigNum, CurveParams> {
        BigCurve { x: self.x[idx], y: self.y[idx], is_infinity: false }
    }
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
