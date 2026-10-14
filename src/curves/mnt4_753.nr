use bignum::BigNum;
pub use bignum::{MNT4_753_Fq, MNT4_753_Fr};

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
            0x847a8e4624a952cef7fedf55ad87e4,
            0x7c70828e3a6534a429b38f4a17ac69,
            0x28fbdb555aebcce37b1da473385e61,
            0x301715c168b23317dcd18b11fafba7,
            0xb3e4fb6260089d8dfc8150a97eb6db,
            0x7567fc61002cb4722ce61c62a056aa,
            0x1ba26a62d,
        ]),
        MNT4_753_Fq::from_limbs([
            0xa9d5b944f1096476c482986915d602,
            0xa421cfcb3392f1d5290075970c6e78,
            0xcec8014e75db23c4f66045911fdb49,
            0xe47d4f6a119e92b66a3f5c84c9a53d,
            0x7071dbf0c4aec90ad29e6aa165028d,
            0x13c97c3302caaa10b07256bcbf5fb9,
            0x10046b9bc,
        ]),
    ],
    offset_generator_final: [
        MNT4_753_Fq::from_limbs([
            0x087cf013f1ffb2c56caa2181739d79,
            0x3c5f28c05cf28db35a2307bef381b6,
            0x16db493b79bc477776bf15e3817439,
            0x41aa17b60a3bafef58d767d9cffd1b,
            0x89555ab322236fc3c2b8fd61a7af14,
            0x9b8f33b0a2dd3132145ef152fdcba1,
            0x4e095965,
        ]),
        MNT4_753_Fq::from_limbs([
            0x3937d3ea38205741c3577a09e0e553,
            0x53c657182797e935d9bc7b40b8b30a,
            0x9b8a609a11d8e939ef8453f515049f,
            0xccfaab918ff506f2a48c8beb6cb641,
            0xf23bba97605bf2fe9292be3a7e4045,
            0xc4424ac74edd8e946b7f655808222c,
            0x0965935ed,
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
        let r = MNT4_753::hash_to_curve("hello world".as_bytes());

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
