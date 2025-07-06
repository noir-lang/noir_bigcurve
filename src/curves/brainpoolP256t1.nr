use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
use bignum::fields::brainpoolP256t1Fq::BrainpoolP256t1_Fq;

pub type BrainpoolP256t1 = BigCurve<BrainpoolP256t1_Fq, BrainpoolP256t1_Params>;
pub type BrainpoolP256t1Scalar = ScalarField<BRAINPOOLP256T1_SCALAR_SLICES>;

// ==== Curve ====

global BRAINPOOLP256T1_SCALAR_SLICES: u32 = 65;
pub struct BrainpoolP256t1_Params {}
impl CurveParamsTrait<BrainpoolP256t1_Fq> for BrainpoolP256t1_Params {
    fn a() -> BrainpoolP256t1_Fq {
        BrainpoolP256t1_Fq::from_limbs([
            0x3bf623d52620282013481d1f6e5374,
            0x57dba1eea9bc3e660a909d838d726e,
            0xa9fb,
        ])
    }
    fn b() -> BrainpoolP256t1_Fq {
        BigNum::from_limbs([
            0x93ebc4af2f49256ae58101fee92b04,
            0x61c430d84ea4fe66a7733d0b76b7bf,
            0x662c,
        ])
    }

    fn offset_generator() -> [BrainpoolP256t1_Fq; 2] {
        [
            BrainpoolP256t1_Fq::from_limbs([
                0xdf7b7690a146dc4daa3e512094cd28,
                0x0293f430def68c091076b5e85608a3,
                0x256a,
            ]),
            BrainpoolP256t1_Fq::from_limbs([
                0x3cd2eb3fdb4d801d7d357371eeb0f7,
                0xaa3d8b3084d3a11df020a3fe22a258,
                0x4ecd,
            ]),
        ]
    }

    fn offset_generator_final() -> [BrainpoolP256t1_Fq; 2] {
        [
            BrainpoolP256t1_Fq::from_limbs([
                0x982c0658a8aa105afe1c74b5f403b5,
                0x7b8ade1081f0492e3fab6d9a99d0c2,
                0x7dcf,
            ]),
            BrainpoolP256t1_Fq::from_limbs([
                0x442f5f8f9bdef5a5366dc979b93d2a,
                0xd1c8259ef3e220a6792624929c0520,
                0x4862,
            ]),
        ]
    }

    fn one() -> [BrainpoolP256t1_Fq; 2] {
        [
            BrainpoolP256t1_Fq::from_limbs([
                0xa142c47aafbc2b79a191562e1305f4,
                0xeb3cc1cfe7b7732213b23a656149af,
                0xa3e8,
            ]),
            BrainpoolP256t1_Fq::from_limbs([
                0xbcb6de39d027001dabe8f35b25c9be,
                0x6c823439c56d7f7b22e14644417e69,
                0x2d99,
            ]),
        ]
    }
}

mod test {
    use super::BRAINPOOLP256T1_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::fields::brainpoolP256t1Fq::BrainpoolP256t1_Fq;

    #[test]
    fn test_brainpoolP256t1_bits() {
        let x: BrainpoolP256t1_Fq = BrainpoolP256t1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BRAINPOOLP256T1_SCALAR_SLICES);
    }
}
