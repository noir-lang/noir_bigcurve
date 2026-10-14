use bignum::BigNum;
pub use bignum::{MNT6_753_Fq, MNT6_753_Fr};

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
            0xca267e707ebeeefe8c30da5ac9c110,
            0xc55d6f106dd01105fc2a32dc6bf50f,
            0x1a09a82ba56c976c3b1ba112cdf0ec,
            0xebd73b776a7ed1978128f2b0ef6d32,
            0xebaa9e9c5ef1127287f9bb40ad9c3a,
            0xb35169636e5d4d6ecdd3c1a56d572e,
            0x8d27befb,
        ]),
        MNT6_753_Fq::from_limbs([
            0xe8e53dc20f58431c578c904cc46bc2,
            0x848c1fef74fd21532ac69c54d8445a,
            0x7be3764e21a9ca4005f50b9232711d,
            0x59825b455470b37c9a9fd1658c16f2,
            0xb525ddddbca542da767ecec568caba,
            0xfcfaaba3cf68e578744b223466d0fb,
            0x09051ff06,
        ]),
    ],
    offset_generator_final: [
        MNT6_753_Fq::from_limbs([
            0x3bd4e86e4e5662910022e6a5f68044,
            0xe1b2ab552d75969b39a05361e3f7c6,
            0x2d082d8487a640a06a0b22454b2da4,
            0x7f12adb72485e0eeed8431b78022db,
            0x7d91cea9ba6da618994ee58974b210,
            0x0064581a39ef6ce0934f79a4e51de4,
            0x0d3f53d27,
        ]),
        MNT6_753_Fq::from_limbs([
            0x7a21f40f7b8629698f5d8f1fdded21,
            0x030d5524909344a466243bc6e89914,
            0x402a94758b9c8994c54cfccb18780c,
            0xd28b8b4b30cc93b965dd8cf05edab3,
            0x1abec4a435d5f475e5cb325df79bff,
            0x4253e5953459575809a0799b4ee9fd,
            0x863bdf01,
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
        let four = MNT6_753_Fr::from(4);

        let p_minus_4_fr = MNT6_753_Fr::modulus() - four;
        let p_minus_4 = MNT6_753Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - MNT6_753_Fr::one();
        let p_minus_5 = MNT6_753Scalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = MNT6_753::one();
        let b = a.neg();
        let points = [a, b];

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
