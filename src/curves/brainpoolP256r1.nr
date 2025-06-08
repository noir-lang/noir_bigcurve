use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
pub use bignum::{BrainpoolP256r1_Fq, BrainpoolP256r1_Fr};

pub type BrainpoolP256r1 = BigCurve<BrainpoolP256r1_Fq, BrainpoolP256r1_Params>;
pub type BrainpoolP256r1Scalar = ScalarField<BRAINPOOLP256R1_SCALAR_SLICES>;

// ==== Curve ====

global BRAINPOOLP256R1_SCALAR_SLICES: u32 = 65;
pub struct BrainpoolP256r1_Params {}
impl CurveParamsTrait<BrainpoolP256r1_Fq> for BrainpoolP256r1_Params {
    fn a() -> BrainpoolP256r1_Fq {
        BrainpoolP256r1_Fq::from_limbs([
            0x8055c126dc5c6ce94a4b44f330b5d9,
            0x975fc2c3057eef67530417affe7fb,
            0x7d5a,
        ])
    }
    fn b() -> BrainpoolP256r1_Fq {
        BrainpoolP256r1_Fq::from_limbs([
            0x8416295cf7e1ce6bccdc18ff8c07b6,
            0x5c6ce94a4b44f330b5d9bbd77cbf95,
            0x26dc,
        ])
    }

    fn offset_generator() -> [BrainpoolP256r1_Fq; 2] {
        [
            BrainpoolP256r1_Fq::from_limbs([
                0xdf7b7690a146dc4daa3e512094cd28,
                0x0293f430def68c091076b5e85608a3,
                0x256a,
            ]),
            BrainpoolP256r1_Fq::from_limbs([
                0xe90d38a99e804a5d800451dcb0103e,
                0x398ffd08546ea665948bc7f6fb6ca7,
                0x0b5e,
            ]),
        ]
    }

    fn offset_generator_final() -> [BrainpoolP256r1_Fq; 2] {
        [
            BrainpoolP256r1_Fq::from_limbs([
                0xa92997c4eee759bbff34df47c83551,
                0x49c4a27c8f3a09dce7819cd9e8903d,
                0x8bd1,
            ]),
            BrainpoolP256r1_Fq::from_limbs([
                0x7c95e35a05c9ad107623858de9a569,
                0x9fd7b0ea3a97ed1cd0b8820e3aec6d,
                0x26e5,
            ]),
        ]
    }

    fn one() -> [BrainpoolP256r1_Fq; 2] {
        [
            BrainpoolP256r1_Fq::from_limbs([
                0xde27e1e3bd23c23a4453bd9ace3262,
                0xaeb9cb7e57cb2c4b482ffc81b7afb9,
                0x8bd2,
            ]),
            BrainpoolP256r1_Fq::from_limbs([
                0x7745132ded8e545c1d54c72f046997,
                0xf835c3dac4fd97f8461a14611dc9c2,
                0x547e,
            ]),
        ]
    }
}

mod test {
    use super::BRAINPOOLP256R1_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::BrainpoolP256r1_Fq;

    #[test]
    fn test_brainpoolP256r1_bits() {
        let x: BrainpoolP256r1_Fq = BrainpoolP256r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BRAINPOOLP256R1_SCALAR_SLICES);
    }
}
