use dep::bignum::BigNum;
use dep::bignum::fields::bn254Fq::BN254_Fq_Params;
use crate::CurveParamsTrait;
use crate::BigCurve;
use crate::scalar_field::ScalarField;

pub struct BN254Params {}
impl CurveParamsTrait<BigNum<3, 254, BN254_Fq_Params>> for BN254Params {
    fn a() -> BigNum<3, 254, BN254_Fq_Params> {
        BigNum { limbs: [0x00, 0x00, 0x00] }
    }
    fn b() -> BigNum<3, 254, BN254_Fq_Params> {
        BigNum { limbs: [0x03, 0x00, 0x00] }
    }
    fn one() -> [BigNum<3, 254, BN254_Fq_Params>; 2] {
        [BigNum { limbs: [0x01, 0x00, 0x00] }, BigNum { limbs: [0x02, 0x00, 0x00] }]
    }
    fn offset_generator() -> [BigNum<3, 254, BN254_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [0x377f339fa8372d1d3adc42a3d4901c, 0x96cbfde252d4502d20fe63e6eb2b52, 0x0666],
            },
            BigNum {
                limbs: [0x06d5ac65dd163514b69bb7b45a8c52, 0xa20295561f2b500335be517e2f9ddf, 0x1390],
            },
        ]
    }
    fn offset_generator_final() -> [BigNum<3, 254, BN254_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [0x876f472cd3289fef9f11dc404e447f, 0x7b083434c2a69effc4cb7fce9fecb6, 0x0336],
            },
            BigNum {
                limbs: [0xa33149d0f82e5335a130fd3baf1bf4, 0x37bbf991eefb0b04d52e689358228b, 0x178e],
            },
        ]
    }
}

global BN254_SCALAR_SLICES = 64;
pub type BN254 = BigCurve<BigNum<3, 254, BN254_Fq_Params>, BN254Params>;
pub type BN254Scalar = ScalarField<BN254_SCALAR_SLICES>;
pub type BN254Fq = BigNum<3, 254, BN254_Fq_Params>;
// pub type Secp256r1Fr = BigNum<3, Secp256r1_Fr_Params>;

// mod test {
//     use dep::bignum::BigNum;
//     use crate::curves::secp256r1::SECP256r1_SCALAR_SLICES;
//     #[test]
// fn test_bits() {
//         let x: BigNum<3, 254, BN254_Fq_Params> = BigNum::new();
//         let max_wnaf_bits: u32 = x.modulus_bits() + 1;

//         let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
//         assert(scalar_slices == SECP256r1_SCALAR_SLICES);
//     }
// }
