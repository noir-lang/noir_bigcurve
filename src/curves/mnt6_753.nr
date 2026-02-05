use dep::bignum::BigNum;
pub use dep::bignum::{MNT6_753_Fq, MNT6_753_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global MNT6_753_SCALAR_SLICES: u32 = 189;
pub global MNT6_753_PARAMS: BigCurveParams<MNT6_753_Fq> = BigCurveParams {
    a: MNT6_753_Fq::from_limbs([0x0b, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
    b: MNT6_753_Fq::from_limbs([
        0xba7505ba6fcf2485540b13dfc8468a,
        0xf9a80a95f401867c4e80f4747fde5a,
        0x0fcf2c43d7bf847957c34cca1e3585,
        0xb7985993f62f03b22a9a3c737a1a1e,
        0xbb64b2bb01b10e60a5d5dfe0a25714,
        0x0863c79d56446237ce2e1468d14ae9,
        0x7da285e7,
    ]),
    offset_generator: [
        MNT6_753_Fq::from_limbs([
            0x75c6b0d47ee0a6fd8b9c74e29ed700,
            0xccf6ec7c1e36072ad2cb9f643ad051,
            0xe6aef4eeda3ae944e17a33eeb511e1,
            0xb7414a75673bbb6060bc99afd403ae,
            0xd54e7a521425bdb81c7ce433e1f34f,
            0x3764341f93fa505148ab550afe8380,
            0x9b0faf0a,
        ]),
        MNT6_753_Fq::from_limbs([
            0x8a31645006856830795eb73949cd89,
            0x435fad4504094d81b09f06cde2d7d6,
            0x511128dd719ad7db3b5208e81cc397,
            0x7c355fc21c32066697cffe1c64b00d,
            0x55942a07c48bf9d840f1c7566a78c5,
            0x8f8cb8b299a961ee1a3a4370581fca,
            0x7a4002b0,
        ]),
    ],
    offset_generator_final: [
        MNT6_753_Fq::from_limbs([
            0x65b1da2da3911d646aac5becf084d2,
            0x87003b690a22e3cbee9db8e5c3d506,
            0x944eb186c3593059d7d8bb026e2ca3,
            0x0b9d6a95a9c7d1f06c58ec34d0bfc5,
            0x68ea8f33bc9f251a4ef594fc2a3310,
            0x69c8c3a81d89c2f564bea8ad599f1b,
            0xdab437a5,
        ]),
        MNT6_753_Fq::from_limbs([
            0x698102485cf015269ba367c5cfd93a,
            0x55edf2d8fbda6c96fdeaaaaeaae635,
            0x645493728ccfa7a157175443964067,
            0x214660d1966e841dfeb3fd3fbc25e9,
            0x96ad98966d597dd798effd7c478d16,
            0x9a72b64fb7734df08a6d1c62fea6df,
            0x01a67663a0,
        ]),
    ],
    one: [
        MNT6_753_Fq::from_limbs([
            0x329a6fefa9a1f3f7a1fbd93a7bffb8,
            0x1acbf7da60895b8b3d9d442c4c4123,
            0xe5e3c57b6df120cee3cd9d867e66d1,
            0x0c0d5fc5e818771b931f1d5bdd069c,
            0x131c2437e884c4997fd1dcb409367d,
            0x6e831147412cfb1002284f30338088,
            0x255f8e87,
        ]),
        MNT6_753_Fq::from_limbs([
            0x521df9855687139f0c51754c0ccc49,
            0x4d9992f5cbf4b2cc4c42eff9a5a6c4,
            0x0dc7a593cce5a792e94d0020c335b7,
            0x4c7a18ed9c4bd3c7ed0ffb31c57e61,
            0x2a3585bdd6d7722c6c07d7873bb02d,
            0x6e2eb3fca70dc1063bac3455180120,
            0x0128c02fff,
        ]),
    ],
};

#[derive_curve_impl(quote { MNT6_753_Fq }, quote { MNT6_753_PARAMS })]
pub struct MNT6_753 {
    pub x: MNT6_753_Fq,
    pub y: MNT6_753_Fq,
    pub is_infinity: bool,
}
pub type MNT6_753Scalar = ScalarField<MNT6_753_SCALAR_SLICES>;

mod test {
    use bignum::{BigNum, MNT6_753_Fq, MNT6_753_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{MNT6_753, MNT6_753_SCALAR_SLICES, MNT6_753Scalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = MNT6_753_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == MNT6_753_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = MNT6_753::one();
        let negone = MNT6_753_Fr::one().neg();
        let scalar = MNT6_753Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r = MNT6_753::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let mut four = MNT6_753_Fr::from(4);

        let p_minus_4_fr = MNT6_753_Fr::modulus() - four;
        let p_minus_4 = MNT6_753Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - MNT6_753_Fr::one();
        let p_minus_5 = MNT6_753Scalar::from_bignum(p_minus_5_fr);
        let mut scalars = [p_minus_4, p_minus_5];
        let a = MNT6_753::one();
        let b = a.neg();
        let mut points = [a, b];

        let result = MNT6_753::evaluate_linear_expression(points, scalars, [MNT6_753::one().neg()]);

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // MNT6-753 cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<MNT6_753_Fq, MNT6_753_SCALAR_SLICES, MNT6_753>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: MNT6_753_Fr = MNT6_753_Fr::derive_from_seed(seed);
        let scalar_field = MNT6_753Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }

}
