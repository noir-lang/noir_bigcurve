use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
use bignum::BLS12_381_Fq;

pub global BLS12_381_SCALAR_SLICES: u32 = 64;
pub struct BLS12_381_Params {}
impl CurveParamsTrait<BLS12_381_Fq> for BLS12_381_Params {
    fn a() -> BLS12_381_Fq {
        BLS12_381_Fq::from_limbs([0x00, 0x00, 0x00, 0x00])
    }
    fn b() -> BLS12_381_Fq {
        BLS12_381_Fq::from_limbs([0x04, 0x00, 0x00, 0x00])
    }
    fn one() -> [BLS12_381_Fq; 2] {
        [
            BLS12_381_Fq::from_limbs([
                0x55e83ff97a1aeffb3af00adb22c6bb,
                0x8c4f9774b905a14e3a3f171bac586c,
                0xa73197d7942695638c4fa9ac0fc368,
                0x17f1d3,
            ]),
            BLS12_381_Fq::from_limbs([
                0x3cc744a2888ae40caa232946c5e7e1,
                0xe095d5d00af600db18cb2c04b3edd0,
                0x81e3aaa0f1a09e30ed741d8ae4fcf5,
                0x08b3f4,
            ]),
        ]
    }
    fn offset_generator() -> [BLS12_381_Fq; 2] {
        [
            BLS12_381_Fq::from_limbs([
                0xcaa8bd3652a69894c3e8ce75bd7de0,
                0x921cf06eacb00767c6aa2186d51836,
                0xf00e268786f3d4f245e1afd2b99cbf,
                0x1660ef,
            ]),
            BLS12_381_Fq::from_limbs([
                0xdf7b66a7f319b3af6961dd328b5691,
                0x3debb030dcfa8fd697ac3704931596,
                0xc1a488f265da2fc98fa92f57698a23,
                0x054b43,
            ]),
        ]
    }
    fn offset_generator_final() -> [BLS12_381_Fq; 2] {
        [
            BLS12_381_Fq::from_limbs([
                0xe3a05fbbe9bd6bb2669ccc7a7c81c4,
                0xfdd0554fc1ae7ef6bae1896afe2dd1,
                0xa5d836272c350f0590344fb99b61c7,
                0x0efaeb,
            ]),
            BLS12_381_Fq::from_limbs([
                0x1b17500cfb60985fc0834ca89b798c,
                0x76fe94b37e801b6b8d582c683bd931,
                0xa5e501f313de4014dd33cbdcb16653,
                0x0e1da3,
            ]),
        ]
    }
}

pub type BLS12_381 = BigCurve<BLS12_381_Fq, BLS12_381_Params>;
pub type BLS12_381Scalar = ScalarField<BLS12_381_SCALAR_SLICES>;

mod test {
    use super::BLS12_381_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::BLS12_381_Fr;

    #[test]
    fn test_bls12_381_bits() {
        let x = BLS12_381_Fr::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BLS12_381_SCALAR_SLICES);
    }
}
