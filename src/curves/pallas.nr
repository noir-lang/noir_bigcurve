use bignum::BigNum;
pub use bignum::{Pallas_Fq, Pallas_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global PALLAS_SCALAR_SLICES: u32 = 64;

pub global PALLAS_PARAM: BigCurveParams<Pallas_Fq> = BigCurveParams {
    a: Pallas_Fq::from_limbs([0x00, 0x00, 0x00]),
    b: Pallas_Fq::from_limbs([0x05, 0x00, 0x00]),
    one: [
        Pallas_Fq::from_limbs([0x4698fc094cf91b992d30ed00000000, 0x22, 0x4000]),
        Pallas_Fq::from_limbs([0x02, 0x00, 0x00]),
    ],
    offset_generator: [
        Pallas_Fq::from_limbs([
            0xb77348be910fcbbcbac23eee0ae133,
            0x594232ef6b9545e500d7b2dfbcf8a8,
            0x08f7,
        ]),
        Pallas_Fq::from_limbs([
            0x26bde7336bcca163b1d032a155c6ae,
            0x0b58a19a828ad14a51312dc6dd1701,
            0x2009,
        ]),
    ],
    offset_generator_final: [
        Pallas_Fq::from_limbs([
            0x6d31ec7483a09d4e9831b658bc18f9,
            0xfcbe77071d79420eb5405768742f58,
            0x0b24,
        ]),
        Pallas_Fq::from_limbs([
            0xdea102ffbf107923ba1c99ddf1342e,
            0xd26cf1b331087dea4654743e5780ca,
            0x064a,
        ]),
    ],
};

#[derive_curve_impl(quote { Pallas_Fq }, quote { PALLAS_PARAM })]
pub struct Pallas {
    pub x: Pallas_Fq,
    pub y: Pallas_Fq,
    pub is_infinity: bool,
}

pub type PallasScalar = ScalarField<PALLAS_SCALAR_SLICES>;

mod test {
    use bignum::{BigNum, Pallas_Fq, Pallas_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{Pallas, PALLAS_SCALAR_SLICES, PallasScalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = Pallas_Fr::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == PALLAS_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = Pallas::one();
        let negone = Pallas_Fr::one().neg();
        let scalar = PallasScalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }
    #[test]
    fn test_hash_to_curve() {
        let r = Pallas::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = Pallas_Fr::from(4);
        let p_minus_4_fr = Pallas_Fr::modulus() - four;
        let p_minus_4 = PallasScalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - Pallas_Fr::one();
        let p_minus_5 = PallasScalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = Pallas::one();
        let b = a.neg();
        let points = [a, b];

        let result = Pallas::evaluate_linear_expression(points, scalars, [Pallas::one().neg()]);

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // Pallas cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<Pallas_Fq, PALLAS_SCALAR_SLICES, Pallas>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: Pallas_Fr = Pallas_Fr::derive_from_seed(seed);
        let scalar_field = PallasScalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }

}
