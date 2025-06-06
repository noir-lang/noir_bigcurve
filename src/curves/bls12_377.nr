use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;

pub use bignum::{BLS12_377_Fq, BLS12_377_Fr};

pub global BLS12_377_SCALAR_SLICES: u32 = 64;
pub struct BLS12_377_Params {}
impl CurveParamsTrait<BLS12_377_Fq> for BLS12_377_Params {
    fn a() -> BLS12_377_Fq {
        BLS12_377_Fq::from_limbs([0x00, 0x00, 0x00, 0x00])
    }
    fn b() -> BLS12_377_Fq {
        BLS12_377_Fq::from_limbs([0x01, 0x00, 0x00, 0x00])
    }
    fn one() -> [BLS12_377_Fq; 2] {
        [
            BLS12_377_Fq::from_limbs([
                0x481512ffcd394eeab9b16eb21be9ef,
                0x1e2caa9d41bb188282c8bd37cb5cd5,
                0xdefe740a67c8fc6225bf87ff548595,
                0x8848,
            ]),
            BLS12_377_Fq::from_limbs([
                0xfe3d3634a9591afd82de55559c8ea6,
                0xb348ca3e52d96d182ad44fb82305c2,
                0x69c5102eff1f674f5d30afeec4bd7f,
                0x01914a,
            ]),
        ]
    }
    fn offset_generator() -> [BLS12_377_Fq; 2] {
        [
            BLS12_377_Fq::from_limbs([
                0xba342dd2e8a57e30e4fab3aac114b2,
                0x6e7346ab4fea7f55a1f08939754a50,
                0x6412e09f423388a318b8a4d36a0072,
                0x3eb8,
            ]),
            BLS12_377_Fq::from_limbs([
                0x8a796bd31648b17a897fce57b28356,
                0x2e1d2547bb3228e76b01175312545b,
                0x9accab8b8165af3afa1a90cb152ecd,
                0xa0e9,
            ]),
        ]
    }
    fn offset_generator_final() -> [BLS12_377_Fq; 2] {
        [
            BLS12_377_Fq::from_limbs([
                0x671498ee656f13e9b769355538d6a5,
                0x50f93aaeb8c9ffbd231d89d655a66e,
                0xab51ed158495b9e4459d72be5ef856,
                0x01ab35,
            ]),
            BLS12_377_Fq::from_limbs([
                0x7e1116c8a65727559685d7c70063ff,
                0xf16bb13f725cac296ddbd1bd54515c,
                0x892af9d72f0a7eeeee28cce211e07c,
                0x9991,
            ]),
        ]
    }
}

pub type BLS12_377 = BigCurve<BLS12_377_Fq, BLS12_377_Params>;
pub type BLS12_377Scalar = ScalarField<BLS12_377_SCALAR_SLICES>;

mod test {
    use super::BLS12_377_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::BLS12_377_Fr;

    #[test]
    fn test_bls12_377_bits() {
        let x = BLS12_377_Fr::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BLS12_377_SCALAR_SLICES);
    }
}
