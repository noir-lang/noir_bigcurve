use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
use bignum::fields::brainpoolP192r1Fq::BrainpoolP192r1_Fq;

global brainpoolP192r1_SCALAR_SLICES: u32 = 49;

pub struct BrainpoolP192r1_Params {}
impl CurveParamsTrait<BrainpoolP192r1_Fq> for BrainpoolP192r1_Params {

    fn a() -> BrainpoolP192r1_Fq {
        BrainpoolP192r1_Fq::from(0x6a91174076b1e0e19c39c031fe8685c1cae040e5c69a28ef)
    }

    fn b() -> BrainpoolP192r1_Fq {
        BrainpoolP192r1_Fq::from(0x469a28ef7c28cca3dc721d044f4496bcca7ef4146fbf25c9)
    }

    fn offset_generator() -> [BrainpoolP192r1_Fq; 2] {
        [
            BrainpoolP192r1_Fq::from_limbs([
                341737422451312232813322064752395693,
                2591393770624295342613,
            ]),
            BrainpoolP192r1_Fq::from_limbs([
                998235051954736967020072969000649982,
                2426767175810624694119,
            ]),
        ]
    }

    fn offset_generator_final() -> [BrainpoolP192r1_Fq; 2] {
        [
            BrainpoolP192r1_Fq::from_limbs([
                983407475235826105811997472305228754,
                3281197066244531590496,
            ]),
            BrainpoolP192r1_Fq::from_limbs([
                817955550732409348615512766579207649,
                3022595801548064898877,
            ]),
        ]
    }

    fn one() -> [BrainpoolP192r1_Fq; 2] {
        let x = 0xc0a0647eaab6a48753b033c56cb0f0900a2f5c4853375fd6;
        let y = 0x14b690866abd5bb88b5f4828c1490002e6773fa2fa299b8f;
        [BrainpoolP192r1_Fq::from(x), BrainpoolP192r1_Fq::from(y)]
    }
}

pub type BrainpoolP192r1 = BigCurve<BrainpoolP192r1_Fq, BrainpoolP192r1_Params>;
pub type BrainpoolP192r1Scalar = ScalarField<brainpoolP192r1_SCALAR_SLICES>;

mod test {
    use super::brainpoolP192r1_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::fields::brainpoolP192r1Fq::BrainpoolP192r1_Fq;

    #[test]
    fn test_brainpoolP192r1_bits() {
        let x: BrainpoolP192r1_Fq = BrainpoolP192r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == brainpoolP192r1_SCALAR_SLICES);
    }
}
