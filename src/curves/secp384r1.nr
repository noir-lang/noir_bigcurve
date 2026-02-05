use dep::bignum::BigNum;
pub use dep::bignum::{Secp384r1_Fq, Secp384r1_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global SECP384r1_PARAM: BigCurveParams<Secp384r1_Fq> = BigCurveParams {
    a: Secp384r1_Fq::from_limbs([
        0xffffff0000000000000000fffffffc,
        0xfffffffffffffffffffffffffffeff,
        0xffffffffffffffffffffffffffffff,
        0xffffff,
    ]),
    b: Secp384r1_Fq::from_limbs([
        0x56398d8a2ed19d2a85c8edd3ec2aef,
        0x9c6efe8141120314088f5013875ac6,
        0xa7e23ee7e4988e056be3f82d19181d,
        0xb3312f,
    ]),
    one: [
        Secp384r1_Fq::from_limbs([
            0x02f25dbf55296c3a545e3872760ab7,
            0x3b628ba79b9859f741e082542a3855,
            0x22be8b05378eb1c71ef320ad746e1d,
            0xaa87ca,
        ]),
        Secp384r1_Fq::from_limbs([
            0x60b1ce1d7e819d7a431d7c90ea0e5f,
            0x1dbd289a147ce9da3113b5f0b8c00a,
            0x4a96262c6f5d9e98bf9292dc29f8f4,
            0x3617de,
        ]),
    ],
    offset_generator: [
        Secp384r1_Fq::from_limbs([
            0xd68ec92657e3401b10862bdfa76fb6,
            0x4f5244943254ad6a59c7c802d66b75,
            0xb0f8c657bb5346f6d6526bf0b0bfef,
            0x4445b4,
        ]),
        Secp384r1_Fq::from_limbs([
            0xa74bdf110f4cf113899d846bcc9528,
            0xa014c66a73213dee9e45fac23434b4,
            0x4b57166c9280a05515cb22c1efdeb0,
            0xaf65de,
        ]),
    ],
    offset_generator_final: [
        Secp384r1_Fq::from_limbs([
            0x375e4d0a23e5d33af27762b3a9ba39,
            0x8ca34d9af67da7563350597a555c8e,
            0xc9a546932ad79926633aa4bfe473dc,
            0xd8c921,
        ]),
        Secp384r1_Fq::from_limbs([
            0xff7f5b7c5b5d78f0328715852acc49,
            0x7502ccb0fd045541f123dbc849e2fb,
            0xaf68320088dd92a6f6af8c636c5113,
            0xd03cb3,
        ]),
    ],
};

pub global SECP384r1_SCALAR_SLICES: u32 = 97;
pub type Secp384r1Scalar = ScalarField<SECP384r1_SCALAR_SLICES>;

#[derive_curve_impl(quote { Secp384r1_Fq }, quote { SECP384r1_PARAM })]
pub struct Secp384r1 {
    pub x: Secp384r1_Fq,
    pub y: Secp384r1_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, Secp384r1_Fq, Secp384r1_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;
    use super::Secp384r1;
    use super::SECP384r1_SCALAR_SLICES;
    use super::Secp384r1Scalar;

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = Secp384r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == SECP384r1_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = Secp384r1::one();
        let negone = Secp384r1_Fr::one().neg();
        let scalar = Secp384r1Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r = Secp384r1::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = Secp384r1_Fr::from(4);
        let p_minus_4_fr = Secp384r1_Fr::modulus() - four;
        let p_minus_4 = Secp384r1Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - Secp384r1_Fr::one();
        let p_minus_5 = Secp384r1Scalar::from_bignum(p_minus_5_fr);
        let mut scalars = [p_minus_4, p_minus_5];
        let a = Secp384r1::one();
        let b = a.neg();
        let mut points = [a, b];

        let result =
            Secp384r1::evaluate_linear_expression(points, scalars, [Secp384r1::one().neg()]);

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // Secp384r1 cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<Secp384r1_Fq, SECP384r1_SCALAR_SLICES, Secp384r1>(
            1,
        );
    }

    #[test]
    unconstrained fn print_offset_generators() {
        let (initial, final_gen) = crate::utils::derive_offset_generators::compute_offset_generators::<Secp384r1_Fq, SECP384r1_SCALAR_SLICES, Secp384r1>(1);
        println(f"offset_generator: {initial}");
        println(f"offset_generator_final: {final_gen}");
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: Secp384r1_Fr = Secp384r1_Fr::derive_from_seed(seed);
        let scalar_field = Secp384r1Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
