use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
use bignum::fields::brainpoolP224r1Fq::BrainpoolP224r1_Fq;

global brainpoolP224r1_SCALAR_SLICES: u32 = 57;

pub struct BrainpoolP224r1_Params {}
impl CurveParamsTrait<BrainpoolP224r1_Fq> for BrainpoolP224r1_Params {

    fn a() -> BrainpoolP224r1_Fq {
        BrainpoolP224r1_Fq::from(0x68a5e62ca9ce6c1c299803a6c1530b514e182ad8b0042a59cad29f43)
    }

    fn b() -> BrainpoolP224r1_Fq {
        BrainpoolP224r1_Fq::from(0x2580f63ccfe44138870713b1a92369e33e2135d266dbb372386c400b)
    }

    fn offset_generator() -> [BrainpoolP224r1_Fq; 2] {
        [
            BrainpoolP224r1_Fq::from_limbs([
                1075323320920990120713067180320075673,
                6568313905546376908115172528949,
            ]),
            BrainpoolP224r1_Fq::from_limbs([
                1192846486069290426873476727072532297,
                588125046588385822265914270979,
            ]),
        ]
    }

    fn offset_generator_final() -> [BrainpoolP224r1_Fq; 2] {
        [
            BrainpoolP224r1_Fq::from_limbs([
                1114440702009118313651831794369170326,
                2044932198558320143185824551663,
            ]),
            BrainpoolP224r1_Fq::from_limbs([
                1152749763947463143444993900943280499,
                6355650461538811215480836636148,
            ]),
        ]
    }

    fn one() -> [BrainpoolP224r1_Fq; 2] {
        let x = 0xd9029ad2c7e5cf4340823b2a87dc68c9e4ce3174c1e6efdee12c07d;
        let y = 0x58aa56f772c0726f24c6b89e4ecdac24354b9e99caa3f6d3761402cd;
        [BrainpoolP224r1_Fq::from(x), BrainpoolP224r1_Fq::from(y)]
    }
}

pub type BrainpoolP224r1 = BigCurve<BrainpoolP224r1_Fq, BrainpoolP224r1_Params>;
pub type BrainpoolP224r1Scalar = ScalarField<brainpoolP224r1_SCALAR_SLICES>;

mod test {
    use super::brainpoolP224r1_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::fields::brainpoolP224r1Fq::BrainpoolP224r1_Fq;

    #[test]
    fn test_brainpoolP224r1_bits() {
        let x: BrainpoolP224r1_Fq = BrainpoolP224r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == brainpoolP224r1_SCALAR_SLICES);
    }
}
