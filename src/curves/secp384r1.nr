use bignum::BigNum;
pub use bignum::{Secp384r1_Fq, Secp384r1_Fr};

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
            0x8b0fe06cd1b66ed66faabd1c2722c0,
            0x57bc94347289a033892787616b7ecd,
            0xd6fad6d83b5bbf771e552d82f71614,
            0x3bbcff,
        ]),
        Secp384r1_Fq::from_limbs([
            0xe3590b2bd088bcedfc55ee8db1d122,
            0x7034a9edf311eee1c30cbaae97cc11,
            0xfc18ea11889504169b1bdfa19c2fc3,
            0xeb8122,
        ]),
    ],
    offset_generator_final: [
        Secp384r1_Fq::from_limbs([
            0x9b022829a5fabd27f3b11c9adac2ed,
            0xadfd085b8f14894b0d28763f8df84f,
            0xd26cefd3e3260d3ba258e19a00ce6f,
            0xd9b7de,
        ]),
        Secp384r1_Fq::from_limbs([
            0x26a4542593b60be233dad9a796ed91,
            0xaaced835908c43e6239dedf4e1b620,
            0x569368cea31f2d40949b583b7b32c4,
            0x31dbc7,
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
        let scalars = [p_minus_4, p_minus_5];
        let a = Secp384r1::one();
        let b = a.neg();
        let points = [a, b];

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
    unconstrained fn test_scalar_field_conversion(seed: [u8; 10]) {
        let num: Secp384r1_Fr = Secp384r1_Fr::derive_from_seed(seed);
        let scalar_field = Secp384r1Scalar::from_bignum(num);
        let bignum = scalar_field.into_bignum();
        assert(bignum == num);
    }
}
