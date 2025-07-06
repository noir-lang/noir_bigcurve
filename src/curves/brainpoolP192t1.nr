use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
use bignum::fields::brainpoolP192t1Fq::BrainpoolP192t1_Fq;

global brainpoolP192t1_SCALAR_SLICES: u32 = 49;

pub struct BrainpoolP192t1_Params {}
impl CurveParamsTrait<BrainpoolP192t1_Fq> for BrainpoolP192t1_Params {

    fn a() -> BrainpoolP192t1_Fq {
        BrainpoolP192t1_Fq::from(0xc302f41d932a36cda7a3463093d18db78fce476de1a86294)
    }
    fn b() -> BrainpoolP192t1_Fq {
        BrainpoolP192t1_Fq::from(0x13d56ffaec78681e68f9deb43b35bec2fb68542e27897b79)
    }

    fn offset_generator() -> [BrainpoolP192t1_Fq; 2] {
        [
            BrainpoolP192t1_Fq::from_limbs([
                341737422451312232813322064752395693,
                2591393770624295342613,
            ]),
            BrainpoolP192t1_Fq::from_limbs([
                165127970448808837395735554849332092,
                385588799216116792916,
            ]),
        ]
    }
    fn offset_generator_final() -> [BrainpoolP192t1_Fq; 2] {
        [
            BrainpoolP192t1_Fq::from_limbs([
                977666942247826077271449140085643223,
                2495353206275603166671,
            ]),
            BrainpoolP192t1_Fq::from_limbs([
                732184512222431221060445227073670042,
                2572538434267253768621,
            ]),
        ]
    }

    // (0x3ae9e58c82f63c30282e1fe7bbf43fa72c446af6f4618129, 0x97e2c5667c2223a902ab5ca449d0084b7e5b3de7ccc01c9)
    fn one() -> [BrainpoolP192t1_Fq; 2] {
        let x = 0x3ae9e58c82f63c30282e1fe7bbf43fa72c446af6f4618129;
        let y = 0x97e2c5667c2223a902ab5ca449d0084b7e5b3de7ccc01c9;
        [BrainpoolP192t1_Fq::from(x), BrainpoolP192t1_Fq::from(y)]
    }
}

pub type BrainpoolP192t1 = BigCurve<BrainpoolP192t1_Fq, BrainpoolP192t1_Params>;
pub type BrainpoolP192t1Scalar = ScalarField<brainpoolP192t1_SCALAR_SLICES>;

mod test {
    use super::brainpoolP192t1_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::fields::brainpoolP192t1Fq::BrainpoolP192t1_Fq;

    #[test]
    fn test_brainpoolP192t1_bits() {
        let x: BrainpoolP192t1_Fq = BrainpoolP192t1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == brainpoolP192t1_SCALAR_SLICES);
    }
}
