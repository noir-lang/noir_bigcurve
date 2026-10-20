use ::bignum::BigNum;
pub use ::bignum::{MNT6_753_Fq, MNT6_753_Fr};

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
            0x3ebe2271d844a642961e4ccd2871c4,
            0x6e1319dff62bf245984bf1b6d2f875,
            0xd547d995844277338761106f05433f,
            0x6ae2b547ae5cd4d285eeac3fd59808,
            0x99572582185c4b46154c801a6d725b,
            0xb295d9c8348efc4f96095bb8b6f5a4,
            0x01034712d8,
        ]),
        MNT6_753_Fq::from_limbs([
            0x0cbc071ec6df0366b5f43ec9926fa9,
            0x95f753639105fa6c53659b69ed41ba,
            0xf65918e347b2a4f0131d32fa8e2248,
            0x65aaa7beeb298095b82a21ab545708,
            0xf384beb83b3a148305c204ea7d16c5,
            0x46c3ccf11c6aa60f793c07fac40f6e,
            0xf269ea5b,
        ]),
    ],
    offset_generator_final: [
        MNT6_753_Fq::from_limbs([
            0x2e40bf225557a4bc3992791dbffa0e,
            0x855564ed85bea74cb8e61d28ce4727,
            0x2888179a81756993f079e456a565cc,
            0x0cc4e468ad9b0ee92db0c709c3abf9,
            0x4623a0ff425e927d9ee099de55e643,
            0x062fd49361662bd14daaa8a8763e3a,
            0x017d854304,
        ]),
        MNT6_753_Fq::from_limbs([
            0x37105b989a4efcf498923ab2a1f669,
            0xdacb416a8bb78eac612b1f95abe6a1,
            0x160f055aa5a7c1cab9c2dfaa22fe7b,
            0x131ed4d61aeb5fecb0cec38f844790,
            0x3c3f9367b58d7d6a526478092ef400,
            0x4f1dbadc43472c8500acc4ed877264,
            0x012b07b474,
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

#[derive_curve_impl(
    quote { MNT6_753_Fq },
    quote { MNT6_753_PARAMS },
    quote { MNT6_753Scalar::from_bignum(-bignum::MNT6_753_Fr::one()) },
)]
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
        let r: MNT6_753 = crate::utils::hash_to_curve::hash_to_curve_point::<bignum::MNT6_753_Fq, MNT6_753, 11>(
            "hello world".as_bytes(),
        );

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
