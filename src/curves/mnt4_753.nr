use ::bignum::BigNum;
pub use ::bignum::{MNT4_753_Fq, MNT4_753_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global MNT4_753_SCALAR_SLICES: u32 = 189;

pub global MNT4_753_PARAMS: BigCurveParams<MNT4_753_Fq> = BigCurveParams {
    a: MNT4_753_Fq::from_limbs([0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
    b: MNT4_753_Fq::from_limbs([
        0xad265458e06372009c9a0491678ef4,
        0x773111c36c8b1b4e8f1ece940ef9ea,
        0xc3d8bb21c8d68bb8cfb9db4b8c8fba,
        0xa92c78dc537e51a16703ec9855c77f,
        0x051c596560835df0c9e50a5b59b882,
        0xc9dcae7a016ac5d7748d3313cd8e39,
        0x01373684a8,
    ]),
    offset_generator: [
        MNT4_753_Fq::from_limbs([
            0x689f7eb877b9ec3d4d50f24ca4bda4,
            0x8ebbf41d9b8720c364d208b32e2c6a,
            0x3631d0ebfa59cf7fbddcf4075e42b0,
            0x9b3e81e9cb5938a27da0e993db039b,
            0xff843ab0288fba71c674b3dc6d469d,
            0x781b9bf90724c1a8ca3c1d59d002af,
            0x01306f9d33,
        ]),
        MNT4_753_Fq::from_limbs([
            0xa4e4d828d3a2c88adbb5952128f4a6,
            0x92176ea6cf116851feb79f9fc1e186,
            0x7516bd6e70b6912d76652d0c128b25,
            0x5177af59cd1da0340958359ca906fc,
            0xd6fac38f4c5422d2c40159fdb59898,
            0x3e0871eeddc13152661454f427860d,
            0x8c4203a9,
        ]),
    ],
    offset_generator_final: [
        MNT4_753_Fq::from_limbs([
            0xaf693e388ff67021d00d7ecbf154a6,
            0x699b8e9df7b79d55714b3401af07f2,
            0x497614df3d15c64883975abc974bef,
            0xd35eb4508c315ed1cdfa2f267261d3,
            0xba3b3e0cf3214fb4b25160f2cdd1b7,
            0x5022cc26e06c7d2d8da353ab3d0819,
            0x011e247f1c,
        ]),
        MNT4_753_Fq::from_limbs([
            0x81cf8297ab9bd8427e8dfc2d57d884,
            0x53986fa58fad63afae4dceddd14dc6,
            0xfed9cebc6bc6ad40177d7f400ac2c6,
            0x18aa8723f0ec36420123fba5923f98,
            0xe713b0ad5fa48040f990fe5779cd59,
            0xd2fa1a7cdf081bad054661193c97f9,
            0x1d9c2c50,
        ]),
    ],
    one: [
        MNT4_753_Fq::from_limbs([
            0xc2ab23be1c24740af0fdeb3b7f1981,
            0xfeff338dd73a5a7eeecfbce7cf95d3,
            0x463d98a4ea009d57aad9716f708885,
            0x6d1ef781d1de4ffb1f806b314c5ad3,
            0xefa5546444d40c82d6a271f1a43862,
            0x450bb76a02d86daaffbaeb69995eb9,
            0x542f1dad,
        ]),
        MNT4_753_Fq::from_limbs([
            0x031ea99cff05e05ec3be2e4a050358,
            0x23036db8fb990a342449caeb92fa6b,
            0x5dea57ef53ee29157bdf1b741aebd4,
            0xee5599dd7c3dfa4100284833115aec,
            0x7fddcdea19cb10b2bf61f37ae2c456,
            0x26e257b175ae94deb9e10aba4ba72f,
            0x4ab64735,
        ]),
    ],
};

pub type MNT4_753Scalar = ScalarField<MNT4_753_SCALAR_SLICES>;

#[derive_curve_impl(quote { MNT4_753_Fq }, quote { MNT4_753_PARAMS })]
pub struct MNT4_753 {
    pub x: MNT4_753_Fq,
    pub y: MNT4_753_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, MNT4_753_Fq, MNT4_753_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;

    use super::{MNT4_753, MNT4_753_SCALAR_SLICES, MNT4_753Scalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = MNT4_753_Fr::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == MNT4_753_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = MNT4_753::one();
        let negone = MNT4_753_Fr::one().neg();
        let scalar = MNT4_753Scalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r: MNT4_753 = crate::utils::hash_to_curve::hash_to_curve_point::<bignum::MNT4_753_Fq, MNT4_753, 11>(
            "hello world".as_bytes(),
        );

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = MNT4_753_Fr::from(4);
        let p_minus_4_fr = MNT4_753_Fr::modulus() - four;
        let p_minus_4 = MNT4_753Scalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - MNT4_753_Fr::one();
        let p_minus_5 = MNT4_753Scalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = MNT4_753::one();
        let b = a.neg();
        let points = [a, b];

        let result = MNT4_753::evaluate_linear_expression(points, scalars, [MNT4_753::one().neg()]);

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // MNT4-753 cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<MNT4_753_Fq, MNT4_753_SCALAR_SLICES, MNT4_753>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: MNT4_753_Fr = MNT4_753_Fr::derive_from_seed(seed);
        let scalar_field = MNT4_753Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
