use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
pub use bignum::{Vesta_Fq, Vesta_Fr};

pub struct Vesta_Params {}
impl CurveParamsTrait<Vesta_Fq> for Vesta_Params {
    fn a() -> Vesta_Fq {
        Vesta_Fq::from_limbs([0x00, 0x00, 0x00])
    }
    fn b() -> Vesta_Fq {
        Vesta_Fq::from_limbs([0x05, 0x00, 0x00])
    }
    fn one() -> [Vesta_Fq; 2] {
        [
            Vesta_Fq::from_limbs([0x4698fc0994a8dd8c46eb2100000000, 0x22, 0x4000]),
            Vesta_Fq::from_limbs([0x02, 0x00, 0x00]),
        ]
    }
    fn offset_generator() -> [Vesta_Fq; 2] {
        [
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
        ]
    }
    fn offset_generator_final() -> [Vesta_Fq; 2] {
        [
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
        ]
    }
}

pub global VESTA_SCALAR_SLICES: u32 = 64;
pub type Vesta = BigCurve<Vesta_Fq, Vesta_Params>;
pub type VestaScalar = ScalarField<VESTA_SCALAR_SLICES>;

mod test {
    use super::VESTA_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::Vesta_Fq;

    #[test]
    fn test_vesta_bits() {
        let x = Vesta_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == VESTA_SCALAR_SLICES);
    }
}
