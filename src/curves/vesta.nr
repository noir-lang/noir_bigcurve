use ::bignum::BigNum;
pub use ::bignum::{Vesta_Fq, Vesta_Fr};

use crate::bigcurve::BigCurve;
use crate::bigcurve::BigCurveParams;
use crate::bigcurve::derive_curve_impl;
use crate::scalar_field::ScalarField;

pub global VESTA_PARAM: BigCurveParams<Vesta_Fq> = BigCurveParams {
    a: Vesta_Fq::from_limbs([0x00, 0x00, 0x00]),
    b: Vesta_Fq::from_limbs([0x05, 0x00, 0x00]),
    one: [
        Vesta_Fq::from_limbs([0x4698fc0994a8dd8c46eb2100000000, 0x22, 0x4000]),
        Vesta_Fq::from_limbs([0x02, 0x00, 0x00]),
    ],
    offset_generator: [
        Vesta_Fq::from_limbs([
            0x46504246237b1e8a2fde3f1eed5e05,
            0x70942053ba0017bcf5ecf45e513310,
            0x1e8f,
        ]),
        Vesta_Fq::from_limbs([
            0xfc2de08ea4751c0e60b9ff23ef908c,
            0xc47fc750236eb2948f19bd28d9fe74,
            0x1916,
        ]),
    ],
    offset_generator_final: [
        Vesta_Fq::from_limbs([
            0x08d93d9650911f156934f8abb5076c,
            0xa50e3e97963e724406d4ee6998dcf6,
            0x1bd8,
        ]),
        Vesta_Fq::from_limbs([
            0x7790d3d6eb81b4c0eaf8d2b34e82bf,
            0x8b8fb7404edd3bd7f16b95775f6fcd,
            0x1278,
        ]),
    ],
};

pub global VESTA_SCALAR_SLICES: u32 = 64;
pub type VestaScalar = ScalarField<VESTA_SCALAR_SLICES>;

#[derive_curve_impl(
    quote { Vesta_Fq },
    quote { VESTA_PARAM },
    quote { VestaScalar::from_bignum(-bignum::Vesta_Fr::one()) },
)]
pub struct Vesta {
    pub x: Vesta_Fq,
    pub y: Vesta_Fq,
    pub is_infinity: bool,
}

mod test {
    use bignum::{BigNum, Vesta_Fq, Vesta_Fr};
    use std::ops::Neg;

    use crate::bigcurve::BigCurve;
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
        let r: Vesta = crate::utils::hash_to_curve::hash_to_curve_point::<bignum::Vesta_Fq, Vesta, 11>(
            "hello world".as_bytes(),
        );

        r.validate_on_curve();
    }

    #[test]
    fn test_msm() {
        let four = Vesta_Fr::from(4);
        let p_minus_4_fr = Vesta_Fr::modulus() - four;
        let p_minus_4 = VestaScalar::from_bignum(p_minus_4_fr);
        let p_minus_5_fr = p_minus_4_fr - Vesta_Fr::one();
        let p_minus_5 = VestaScalar::from_bignum(p_minus_5_fr);
        let scalars = [p_minus_4, p_minus_5];
        let a = Vesta::one();
        let b = a.neg();
        let points = [a, b];

        let result = Vesta::evaluate_linear_expression(points, scalars, [Vesta::one().neg()]);

        assert(result.is_infinity);
    }

    #[test]
    unconstrained fn verify_offset_generators() {
        // Vesta cofactor is 1
        crate::utils::derive_offset_generators::verify_offset_generators::<Vesta_Fq, VESTA_SCALAR_SLICES, Vesta>(
            1,
        );
    }

    #[test]
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: Vesta_Fr = Vesta_Fr::derive_from_seed(seed);
        let scalar_field = VestaScalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
