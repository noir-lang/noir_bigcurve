use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;

use bignum::BigNum;
pub use bignum::BN254_Fq;

pub struct BN254Params {}
impl CurveParamsTrait<BN254_Fq> for BN254Params {
    fn a() -> BN254_Fq {
        BN254_Fq::from_limbs([0x00, 0x00, 0x00])
    }
    fn b() -> BN254_Fq {
        BN254_Fq::from_limbs([0x03, 0x00, 0x00])
    }
    fn one() -> [BN254_Fq; 2] {
        [BN254_Fq::from_limbs([0x01, 0x00, 0x00]), BN254_Fq::from_limbs([0x02, 0x00, 0x00])]
    }
    fn offset_generator() -> [BN254_Fq; 2] {
        [
            BN254_Fq::from_limbs([
                0x377f339fa8372d1d3adc42a3d4901c,
                0x96cbfde252d4502d20fe63e6eb2b52,
                0x0666,
            ]),
            BN254_Fq::from_limbs([
                0x06d5ac65dd163514b69bb7b45a8c52,
                0xa20295561f2b500335be517e2f9ddf,
                0x1390,
            ]),
        ]
    }
    fn offset_generator_final() -> [BN254_Fq; 2] {
        [
            BN254_Fq::from_limbs([
                0x876f472cd3289fef9f11dc404e447f,
                0x7b083434c2a69effc4cb7fce9fecb6,
                0x0336,
            ]),
            BN254_Fq::from_limbs([
                0xa33149d0f82e5335a130fd3baf1bf4,
                0x37bbf991eefb0b04d52e689358228b,
                0x178e,
            ]),
        ]
    }
}

pub global BN254_SCALAR_SLICES: u32 = 64;
pub type BN254 = BigCurve<BN254_Fq, BN254Params>;
pub type BN254Scalar = ScalarField<BN254_SCALAR_SLICES>;
// pub type Secp256r1Fr = BigNum<3, Secp256r1_Fr_Params>;

// mod test {
//     use bignum::{BigNum, BigNum};
//     use crate::curves::secp256r1::SECP256r1_SCALAR_SLICES;
//     #[test]
// fn test_bn254_bits() {
//         let x: BigNum<3, 254, BN254_Fq_Params> = BigNum::zero();
//         let max_wnaf_bits: u32 = x.modulus_bits() + 1;

//         let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
//         assert(scalar_slices == SECP256r1_SCALAR_SLICES);
//     }
// }
