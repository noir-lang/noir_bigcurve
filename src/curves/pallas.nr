use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;

pub use bignum::{Pallas_Fq, Pallas_Fr};

pub global PALLAS_SCALAR_SLICES: u32 = 64;

pub struct Pallas_Params {}
impl CurveParamsTrait<Pallas_Fq> for Pallas_Params {
    fn a() -> Pallas_Fq {
        Pallas_Fq::from_limbs([0x00, 0x00, 0x00])
    }
    fn b() -> Pallas_Fq {
        Pallas_Fq::from_limbs([0x05, 0x00, 0x00])
    }
    fn one() -> [Pallas_Fq; 2] {
        [
            Pallas_Fq::from_limbs([0x4698fc094cf91b992d30ed00000000, 0x22, 0x4000]),
            Pallas_Fq::from_limbs([0x02, 0x00, 0x00]),
        ]
    }
    fn offset_generator() -> [Pallas_Fq; 2] {
        [
            Pallas_Fq::from_limbs([
                0xd2422812b398350c1aebba48ec188a,
                0xb131381b40fe8f0a2a6379eb41d224,
                0x241a,
            ]),
            Pallas_Fq::from_limbs([
                0x0b9046b0869b1629091d1fa9f16692,
                0xc5dec5f6d150a01e8529316736e0fa,
                0x2c49,
            ]),
        ]
    }
    fn offset_generator_final() -> [Pallas_Fq; 2] {
        [
            Pallas_Fq::from_limbs([
                0x8d735ee60f0b794209ba47e69517b5,
                0x0268fe41698522f06c1f464e5425f6,
                0x1e33,
            ]),
            Pallas_Fq::from_limbs([
                0xbd45401bf9c27bf9dd24a5ce54ce87,
                0x47abf9cd0515d86bf76d53b264cfcc,
                0x072a,
            ]),
        ]
    }
}

pub type Pallas = BigCurve<Pallas_Fq, Pallas_Params>;
pub type PallasScalar = ScalarField<PALLAS_SCALAR_SLICES>;

mod test {

    use super::PALLAS_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::Pallas_Fr;

    #[test]
    fn test_pallas_bits() {
        let x = Pallas_Fr::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == PALLAS_SCALAR_SLICES);
    }
}
