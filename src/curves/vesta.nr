use crate::BigCurve;
use crate::BigCurveParams;
use crate::derive_curve_impl;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
pub use bignum::{Vesta_Fq, Vesta_Fr};

pub global VESTA_PARAM: BigCurveParams<Vesta_Fq> = BigCurveParams {
    a: Vesta_Fq::from_limbs([0x00, 0x00, 0x00]),
    b: Vesta_Fq::from_limbs([0x05, 0x00, 0x00]),
    one: [
        Vesta_Fq::from_limbs([0x4698fc0994a8dd8c46eb2100000000, 0x22, 0x4000]),
        Vesta_Fq::from_limbs([0x02, 0x00, 0x00]),
    ],
    offset_generator: [
        Vesta_Fq::from_limbs([
            0xd6286ae8e92203a8122b1827a9b6d1,
            0xcd21322ea03ceea814cfd7137b4a13,
            0x0116,
        ]),
        Vesta_Fq::from_limbs([
            0x6c4531e4384d03f3c0febb060cbe74,
            0xabaae719efbfcf4a24508d1596c758,
            0x2190,
        ]),
    ],
    offset_generator_final: [
        Vesta_Fq::from_limbs([
            0xa87902cfed63db9fdaa5a570a4938d,
            0x1d99860422926bca663f59f047ce18,
            0x1083,
        ]),
        Vesta_Fq::from_limbs([
            0x9fa3943f857b1178d7242101da6c4c,
            0xa67fd5354fcf62d204d7ad617adb6c,
            0x0a9f,
        ]),
    ],
};

pub global VESTA_SCALAR_SLICES: u32 = 64;
pub type VestaScalar = ScalarField<VESTA_SCALAR_SLICES>;

#[derive_curve_impl(quote { Vesta_Fq }, quote { VESTA_PARAM })]
pub struct Vesta {
    pub x: Vesta_Fq,
    pub y: Vesta_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, Vesta_Fq, Vesta_Fr};
    use std::ops::Neg;

    use crate::BigCurve;
    use super::{Vesta, VESTA_SCALAR_SLICES, VestaScalar};

    #[test]
    fn check_num_scalar_slices_in_scalar_field() {
        let x = Vesta_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == VESTA_SCALAR_SLICES);
    }

    #[test]
    fn test_offset_generators() {
        let one = Vesta::one();
        let negone = Vesta_Fr::one().neg();
        let scalar = VestaScalar::from_bignum(negone);
        let final = one.mul(scalar);

        assert(final.eq(one.neg()));
    }

    #[test]
    fn test_hash_to_curve() {
        let r = Vesta::hash_to_curve("hello world".as_bytes());

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = Vesta_Fr::from(4);
        let p_minus_4_fr = Vesta_Fr::modulus() - four;
        let p_minus_4 = VestaScalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - Vesta_Fr::one();
        let p_minus_5 = VestaScalar::from_bignum(p_minus_5_fr);
        let mut scalars = [p_minus_4, p_minus_5];
        let a = Vesta::one();
        let b = a.neg();
        let mut points = [a, b];

        let result = Vesta::evaluate_linear_expression(points, scalars, [Vesta::one().neg()]);

        assert(result.is_infinity);
    }

    #[test(should_fail)]
    unconstrained fn verify_offset_generators() {
        // Vesta cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<Vesta_Fq, Vesta>(1);
    }
}
