use ::bignum::BigNum;
use ::bignum::BLS12_381_Fq;

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global BLS12_381_SCALAR_SLICES: u32 = 64;
pub global BLS12_381_PARAMS: BigCurveParams<BLS12_381_Fq> = BigCurveParams {
    a: BLS12_381_Fq::from_limbs([0x00, 0x00, 0x00, 0x00]),
    b: BLS12_381_Fq::from_limbs([0x04, 0x00, 0x00, 0x00]),
    offset_generator: [
        BLS12_381_Fq::from_limbs([
            0x7743bae4232f8d176017130f9cce29,
            0x35a094f6204b23e49cf2b670c15eb3,
            0xf91801a7a092a34a949d54db5d3e40,
            0x0c5123,
        ]),
        BLS12_381_Fq::from_limbs([
            0x8816ba23e82c1086bbe9771653b5b1,
            0x492a060a04e8807ee564f92f304fc6,
            0x7478d23a7e258b6ec0bb0645e9351a,
            0x088858,
        ]),
    ],
    offset_generator_final: [
        BLS12_381_Fq::from_limbs([
            0x26930e9d897072207180868cdedb94,
            0xf7f71a1e9074ed02703c14675512bd,
            0xe4040f7b82c3ab503b56877f847e5e,
            0x08ba68,
        ]),
        BLS12_381_Fq::from_limbs([
            0xb60b7756d403638af9be4e1a068a89,
            0x80bf0bb6cbfe6b019694b7d5545eb8,
            0xee516c6272079719986092adc1b762,
            0x073fb9,
        ]),
    ],
    one: [
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
    ],
};

pub type BLS12_381Scalar = ScalarField<BLS12_381_SCALAR_SLICES>;

#[derive_curve_impl(
    quote { BLS12_381_Fq },
    quote { BLS12_381_PARAMS },
    quote { BLS12_381Scalar::from_bignum(-bignum::BLS12_381_Fr::one()) },
)]
pub struct BLS12_381 {
    pub x: BLS12_381_Fq,
    pub y: BLS12_381_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, BLS12_381_Fq, BLS12_381_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{BLS12_381, BLS12_381_SCALAR_SLICES, BLS12_381Scalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = BLS12_381_Fr::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BLS12_381_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = BLS12_381::one();
        let negone = BLS12_381_Fr::one().neg();
        let scalar = BLS12_381Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r: BLS12_381 = crate::utils::hash_to_curve::hash_to_curve_point::<bignum::BLS12_381_Fq, BLS12_381, 11>(
            "hello world".as_bytes(),
        );

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = BLS12_381_Fr::from(4);
        let p_minus_4_fr = BLS12_381_Fr::modulus() - four;
        let p_minus_4 = BLS12_381Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - BLS12_381_Fr::one();
        let p_minus_5 = BLS12_381Scalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = BLS12_381::one();
        let b = a.neg();
        let points = [a, b];

        let result =
            BLS12_381::evaluate_linear_expression(points, scalars, [BLS12_381::one().neg()]);

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // BLS12-381 cofactor is 0x396C8C005555E1568C00AAAB0000AAAB
        crate::utils::derive_offset_generators::verify_offset_generators::<BLS12_381_Fq, BLS12_381_SCALAR_SLICES, BLS12_381>(
            0x396C8C005555E1568C00AAAB0000AAAB,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: BLS12_381_Fr = BLS12_381_Fr::derive_from_seed(seed);
        let scalar_field = BLS12_381Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }

}
