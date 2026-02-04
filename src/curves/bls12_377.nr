use dep::bignum::BigNum;
pub use dep::bignum::{BLS12_377_Fq, BLS12_377_Fr};

use crate::BigCurve;
use crate::BigCurveParams;
use crate::derive_curve_impl;
use crate::ScalarField;

pub global BLS12_377_SCALAR_SLICES: u32 = 64;
pub global BLS12_377_PARAMS: BigCurveParams<BLS12_377_Fq> = BigCurveParams {
    a: BLS12_377_Fq::from_limbs([0x00, 0x00, 0x00, 0x00]),
    b: BLS12_377_Fq::from_limbs([0x01, 0x00, 0x00, 0x00]),
    offset_generator: [
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
    ],
    offset_generator_final: [
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
    ],
    one: [
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
    ],
};

pub type BLS12_377Scalar = ScalarField<BLS12_377_SCALAR_SLICES>;

#[derive_curve_impl(quote { BLS12_377_Fq }, quote { BLS12_377_PARAMS })]
pub struct BLS12_377 {
    pub x: BLS12_377_Fq,
    pub y: BLS12_377_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, BLS12_377_Fq, BLS12_377_Fr};
    use std::ops::Neg;

    use crate::BigCurve;

    use super::BLS12_377;
    use super::BLS12_377_SCALAR_SLICES;
    use super::BLS12_377Scalar;

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = BLS12_377_Fr::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BLS12_377_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = BLS12_377::one();
        let negone = BLS12_377_Fr::one().neg();
        let scalar = BLS12_377Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }
    #[test]
    fn test_hash_to_curve() {
        let r = BLS12_377::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let mut four = BLS12_377_Fr::zero();
        four.set_limb(0, 4);
        let p_minus_4_fr = BLS12_377_Fr::modulus() - four;
        let p_minus_4 = BLS12_377Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - BLS12_377_Fr::one();
        let p_minus_5 = BLS12_377Scalar::from_bignum(p_minus_5_fr);
        let mut scalars = [p_minus_4, p_minus_5];
        let a = BLS12_377::one();
        let b = a.neg();
        let mut points = [a, b];

        let result =
            BLS12_377::evaluate_linear_expression(points, scalars, [BLS12_377::one().neg()]);

        assert(result.is_infinity);
    }

    #[test(should_fail)]
    unconstrained fn verify_offset_generators() {
        // BLS12-377 cofactor is 0x170b5d44300000000000000000000000
        crate::utils::derive_offset_generators::verify_offset_generators::<BLS12_377_Fq, BLS12_377>(
            0x170b5d44300000000000000000000000,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: BLS12_377_Fr = BLS12_377_Fr::derive_from_seed(seed);
        let scalar_field = BLS12_377Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
