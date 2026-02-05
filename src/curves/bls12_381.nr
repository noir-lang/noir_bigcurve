use dep::bignum::BigNum;
use dep::bignum::BLS12_381_Fq;

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
            0x87d0820bb18ba1da4f1ac3a7af2783,
            0x43d501fe7c182e6f86408f887893e4,
            0xf16a169c35d81f72336a8452bd0c51,
            0x11763c,
        ]),
        BLS12_381_Fq::from_limbs([
            0xebd2a3424724b80f2aaf7f61ca5875,
            0x1e6eed745c227cbea0d2d2074a9166,
            0x1254ec69b594ff881adaa4482a199f,
            0x0f32e,
        ]),
    ],
    offset_generator_final: [
        BLS12_381_Fq::from_limbs([
            0x13d70317bd159cda46948f3cd27e4d,
            0x6d75fa7df1614976fc1eaf53702d09,
            0x789bb21609e66990208ebc4b6476c8,
            0x0ef7b4,
        ]),
        BLS12_381_Fq::from_limbs([
            0x495f0412a735f01a65dca398d77b90,
            0xa8c67cb03794de4b9f9f8c6960b384,
            0xfbb3e1f164d5edda3ae536923f0359,
            0x1429e5,
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

#[derive_curve_impl(quote { BLS12_381_Fq }, quote { BLS12_381_PARAMS })]
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
        let r = BLS12_381::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = BLS12_381_Fr::from(4);
        let p_minus_4_fr = BLS12_381_Fr::modulus() - four;
        let p_minus_4 = BLS12_381Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - BLS12_381_Fr::one();
        let p_minus_5 = BLS12_381Scalar::from_bignum(p_minus_5_fr);
        let mut scalars = [p_minus_4, p_minus_5];
        let a = BLS12_381::one();
        let b = a.neg();
        let mut points = [a, b];

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
    unconstrained fn print_offset_generators() {
        let (initial, final_gen) = crate::utils::derive_offset_generators::compute_offset_generators::<BLS12_381_Fq, BLS12_381_SCALAR_SLICES, BLS12_381>(0x396C8C005555E1568C00AAAB0000AAAB);
        println(f"offset_generator: {initial}");
        println(f"offset_generator_final: {final_gen}");
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: BLS12_381_Fr = BLS12_381_Fr::derive_from_seed(seed);
        let scalar_field = BLS12_381Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }

}
