use crate::curve_jac::AffineTranscript;
use crate::CurveParamsTrait;
use crate::derive_curve_impl;
use crate::scalar_field::ScalarField;
use crate::utils::hash_to_curve::hash_to_curve;
use bignum::BigNum;
pub use bignum::{Secp256r1_Fq, Secp256r1_Fr};

pub struct Secp256r1_Params {}
impl CurveParamsTrait<Secp256r1_Fq> for Secp256r1_Params {
    fn a() -> Secp256r1_Fq {
        Secp256r1_Fq::from_limbs([
            0xfffffffffffffffffffffffc,
            0xffff00000001000000000000000000,
            0xffff,
        ])
    }
    fn b() -> Secp256r1_Fq {
        Secp256r1_Fq::from_limbs([
            0x1d06b0cc53b0f63bce3c3e27d2604b,
            0x35d8aa3a93e7b3ebbd55769886bc65,
            0x5ac6,
        ])
    }
    fn one() -> [Secp256r1_Fq; 2] {
        [
            Secp256r1_Fq::from_limbs([
                0x037d812deb33a0f4a13945d898c296,
                0xd1f2e12c4247f8bce6e563a440f277,
                0x6b17,
            ]),
            Secp256r1_Fq::from_limbs([
                0xce33576b315ececbb6406837bf51f5,
                0x42e2fe1a7f9b8ee7eb4a7c0f9e162b,
                0x4fe3,
            ]),
        ]
    }
    fn offset_generator() -> [Secp256r1_Fq; 2] {
        [
            Secp256r1_Fq::from_limbs([
                0x43a84352fdbca907cb6bcdc31f4784,
                0x02b728fe767007b08d0ced4ccf0591,
                0x5c14,
            ]),
            Secp256r1_Fq::from_limbs([
                0x664a12c8ee78446ee947a8a109adfe,
                0x445dd71ff484b877a5bf3df6263bfc,
                0x841b,
            ]),
        ]
    }
    fn offset_generator_final() -> [Secp256r1_Fq; 2] {
        [
            Secp256r1_Fq::from_limbs([
                0x4e53e542bc502419d0cb4b99c0aa48,
                0x74d3a045b26542b1a5931d721650ab,
                0x6982,
            ]),
            Secp256r1_Fq::from_limbs([
                0xbe3c1ef0581c8f76517e499277b269,
                0xfd562740986614ce3b7025c0dfb8aa,
                0xfc88,
            ]),
        ]
    }
}

pub global SECP256r1_SCALAR_SLICES: u32 = 65;

pub type Secp256r1Scalar = ScalarField<SECP256r1_SCALAR_SLICES>;

#[derive_curve_impl(quote { bignum::Secp256r1_Fq }, quote { Secp256r1_Params })]
pub struct Secp256r1 {
    pub x: Secp256r1_Fq,
    pub y: Secp256r1_Fq,
    pub is_infinity: bool,
}

mod test {

    use super::SECP256r1_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::Secp256r1_Fq;

    #[test]
    fn test_secp256r1_bits() {
        let x = Secp256r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == SECP256r1_SCALAR_SLICES);
    }
}
