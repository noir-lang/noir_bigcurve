use bignum::BigNum;
pub use bignum::{BLS12_377_Fq, BLS12_377_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global BLS12_377_SCALAR_SLICES: u32 = 64;
pub global BLS12_377_PARAMS: BigCurveParams<BLS12_377_Fq> = BigCurveParams {
    a: BLS12_377_Fq::from_limbs([0x00, 0x00, 0x00, 0x00]),
    b: BLS12_377_Fq::from_limbs([0x01, 0x00, 0x00, 0x00]),
    offset_generator: [
        BLS12_377_Fq::from_limbs([
            0x606feecefa0b97b1dd8092bf118c2f,
            0xf3cc9b4497531bdec8408bd4c8dd8b,
            0x586666b5fc57a056fdde468e243402,
            0x971f,
        ]),
        BLS12_377_Fq::from_limbs([
            0xd5486d4742b3c338aa338f581e945b,
            0x8f50108be9fa5ae6b95f2208aa4511,
            0x0c2371e3c3fb261185d1c33f01a83b,
            0x2e44,
        ]),
    ],
    offset_generator_final: [
        BLS12_377_Fq::from_limbs([
            0x285a0ca0c4f613161d282501187525,
            0x213b6e7de99e2bd2dd6efe902c66ff,
            0x080161787c0e67ddcceb91901f7c2e,
            0x1a494,
        ]),
        BLS12_377_Fq::from_limbs([
            0xcf5406696d8b0083394a55024e0155,
            0xf0095bd5b2fd5dba278a79ce4d64c5,
            0x367849ed91f419715be731d04428d9,
            0x04157,
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

    use crate::bigcurve::BigCurve;

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
        let scalars = [p_minus_4, p_minus_5];
        let a = BLS12_377::one();
        let b = a.neg();
        let points = [a, b];

        let result =
            BLS12_377::evaluate_linear_expression(points, scalars, [BLS12_377::one().neg()]);

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // BLS12-377 cofactor is 0x170b5d44300000000000000000000000
        crate::utils::derive_offset_generators::verify_offset_generators::<BLS12_377_Fq, BLS12_377_SCALAR_SLICES, BLS12_377>(
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
