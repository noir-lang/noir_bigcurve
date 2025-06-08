use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
pub use bignum::{BrainpoolP512r1_Fq, BrainpoolP512r1_Fr};

pub type BrainpoolP512r1 = BigCurve<BrainpoolP512r1_Fq, BrainpoolP512r1_Params>;
pub type BrainpoolP512r1Scalar = ScalarField<BRAINPOOLP512R1_SCALAR_SLICES>;

// ==== Curve ====

global BRAINPOOLP512R1_SCALAR_SLICES: u32 = 129;
pub struct BrainpoolP512r1_Params {}
impl CurveParamsTrait<BrainpoolP512r1_Fq> for BrainpoolP512r1_Params {
    fn a() -> BrainpoolP512r1_Fq {
        BigNum::from_limbs([
            0x1117a72bf2c7b9e7c1ac4d77fc94ca,
            0x5d5aa8253aa10a2ef1c98b9ac8b57f,
            0x8d3df91610a83441caea9863bc2ded,
            0x8b603b89e2327145ac234cc594cbdd,
            0x7830a331,
        ])
    }
    fn b() -> BrainpoolP512r1_Fq {
        BigNum::from_limbs([
            0x4050b75ebae5dd2809bd638016f723,
            0xc7b9e7c1ac4d77fc94cadc083e6798,
            0xa10a2ef1c98b9ac8b57f1117a72bf2,
            0xa83441caea9863bc2ded5d5aa8253a,
            0x3df91610,
        ])
    }

    fn offset_generator() -> [BrainpoolP512r1_Fq; 2] {
        [
            BigNum::from_limbs([
                0xdcf10230b2c0660f79fc7397a8c6e5,
                0x0556564b4b7901a0beaed7a0891da5,
                0xc135b5fb1581ddaa80896e30daee11,
                0x1a481ad9252517735bfe56e66da9f7,
                0x66cbe79a,
            ]),
            BigNum::from_limbs([
                0x64b036951242a31fcf7066d07abcc0,
                0x618024a6d4ac557eb0358161f6660c,
                0xf305c87ef13f65c0ecc3047a5022e2,
                0x64c180f28bbc7c222eae073ac2520a,
                0x1f9575b6,
            ]),
        ]
    }

    fn offset_generator_final() -> [BrainpoolP512r1_Fq; 2] {
        [
            BigNum::from_limbs([
                0x53e17fbc1d577357b617d757c63cb4,
                0x9e7ba2c6e516bf440a84b2d3402f7c,
                0x55d09ab142686a6995c977ed1e8d10,
                0xaaa3ef0f00c4dc86f1ec828bcc8f7d,
                0x3ff3122d,
            ]),
            BigNum::from_limbs([
                0xa18e1f24911d50ccf3e9ed1249f5eb,
                0x880f5343bc7ef5841cd3307d99eadc,
                0xb6aad18c4eec580e48862d3190d3c0,
                0x89fbf0c52b76b888fd185e468b1c99,
                0x9338fe,
            ]),
        ]
    }

    fn one() -> [BrainpoolP512r1_Fq; 2] {
        [
            BigNum::from_limbs([
                0x6d5047406a5e688b352209bcb9f822,
                0x1f78e2d0d48d50d1687b93b97d5f7c,
                0x70b5d916c1b43b62eef4d0098eff3b,
                0xd82ed9645a21322e9c4c6a9385ed9f,
                0x81aee4bd,
            ]),
            BigNum::from_limbs([
                0xca2b2fa8f0540678cd1e0f3ad80892,
                0xde494a5f485e5bca4bd88a2763aed1,
                0x24a57b1aa000c55b881f8111b2dc,
                0x566332ecc0eabfa9cf7822fdf209f7,
                0x7dde385d,
            ]),
        ]
    }
}

mod test {
    use super::BRAINPOOLP512R1_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::BrainpoolP512r1_Fq;

    #[test]
    fn test_brainpoolP512r1_bits() {
        let x: BrainpoolP512r1_Fq = BrainpoolP512r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BRAINPOOLP512R1_SCALAR_SLICES);
    }
}
