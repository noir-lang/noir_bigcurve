use bignum::params::BigNumParams;
use bignum::params::BigNumParamsGetter;
use bignum::bignum::BigNum;
use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;

// ==== Params (can be moved to bignum later on) ====

pub struct BrainpoolP512r1_Fq_Params {}

impl BigNumParamsGetter<5, 512> for BrainpoolP512r1_Fq_Params {
    fn get_params() -> BigNumParams<5, 512> {
        BrainpoolP512r1_Fq_PARAMS
    }
}

global BrainpoolP512r1_Fq_PARAMS: BigNumParams<5, 512> = BigNumParams::new(
    true,
    [
        0x81ff2f2d82c68528aa6056583a48f3,
        0x9b009bc66842aecda12ae6a380e628,
        0xb3b3c9d20ed6639cca703308717d4d,
        0xdbe9c48b3fd4e6ae33c9fc07cb308d,
        0xaadd9db8,
    ],
    [
        0x621c4603556d117e2cf84e911e8d90,
        0xb38823152c5e47d93034e73ea8c71d,
        0xcc44ef09666ad8f2f5bf92f542ff2,
        0x6daeb8a15d5ea2f03461e1e8373af6,
        0x17f8d7f4ed,
    ],
);

pub struct BrainpoolP512r1_Fr_Params {}

impl BigNumParamsGetter<5, 512> for BrainpoolP512r1_Fr_Params {
    fn get_params() -> BigNumParams<5, 512> {
        BrainpoolP512r1_Fr_PARAMS
    }
}

global BrainpoolP512r1_Fr_PARAMS: BigNumParams<5, 512> = BigNumParams::new(
    true,
    [
        0xb1d381085ddaddb58796829ca90069,
        0x5c414ca92619418661197fac10471d,
        0xb3b3c9d20ed6639cca70330870553e,
        0xdbe9c48b3fd4e6ae33c9fc07cb308d,
        0xaadd9db8,
    ],
    [
        0xf0d9015d5c4ce2fafac64db57db370,
        0xc61a235d449ff38f5f59ee47100ea,
        0xcc44ef09666ad8f2f5bf92f7db947,
        0x6daeb8a15d5ea2f03461e1e8373af6,
        0x17f8d7f4ed,
    ],
);

pub type BrainpoolP512r1 = BigCurve<BigNum<5, 512, BrainpoolP512r1_Fq_Params>, BrainpoolP512r1_Params>;
pub type BrainpoolP512r1Scalar = ScalarField<BRAINPOOLP512R1_SCALAR_SLICES>;
pub type BrainpoolP512r1Fq = BigNum<5, 512, BrainpoolP512r1_Fq_Params>;
pub type BrainpoolP512r1Fr = BigNum<5, 512, BrainpoolP512r1_Fr_Params>;

// ==== Curve ====

global BRAINPOOLP512R1_SCALAR_SLICES: u32 = 129;
pub struct BrainpoolP512r1_Params {}
impl CurveParamsTrait<BigNum<5, 512, BrainpoolP512r1_Fq_Params>> for BrainpoolP512r1_Params {
    fn a() -> BigNum<5, 512, BrainpoolP512r1_Fq_Params> {
        BigNum {
            limbs: [
                0x1117a72bf2c7b9e7c1ac4d77fc94ca,
                0x5d5aa8253aa10a2ef1c98b9ac8b57f,
                0x8d3df91610a83441caea9863bc2ded,
                0x8b603b89e2327145ac234cc594cbdd,
                0x7830a331,
            ],
        }
    }
    fn b() -> BigNum<5, 512, BrainpoolP512r1_Fq_Params> {
        BigNum {
            limbs: {
                [
                    0x4050b75ebae5dd2809bd638016f723,
                    0xc7b9e7c1ac4d77fc94cadc083e6798,
                    0xa10a2ef1c98b9ac8b57f1117a72bf2,
                    0xa83441caea9863bc2ded5d5aa8253a,
                    0x3df91610,
                ]
            },
        }
    }

    fn offset_generator() -> [BigNum<5, 512, BrainpoolP512r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0xdcf10230b2c0660f79fc7397a8c6e5,
                    0x0556564b4b7901a0beaed7a0891da5,
                    0xc135b5fb1581ddaa80896e30daee11,
                    0x1a481ad9252517735bfe56e66da9f7,
                    0x66cbe79a,
                ],
            },
            BigNum {
                limbs: [
                    0x64b036951242a31fcf7066d07abcc0,
                    0x618024a6d4ac557eb0358161f6660c,
                    0xf305c87ef13f65c0ecc3047a5022e2,
                    0x64c180f28bbc7c222eae073ac2520a,
                    0x1f9575b6,
                ],
            },
        ]
    }

    fn offset_generator_final() -> [BigNum<5, 512, BrainpoolP512r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0x53e17fbc1d577357b617d757c63cb4,
                    0x9e7ba2c6e516bf440a84b2d3402f7c,
                    0x55d09ab142686a6995c977ed1e8d10,
                    0xaaa3ef0f00c4dc86f1ec828bcc8f7d,
                    0x3ff3122d,
                ],
            },
            BigNum {
                limbs: [
                    0xa18e1f24911d50ccf3e9ed1249f5eb,
                    0x880f5343bc7ef5841cd3307d99eadc,
                    0xb6aad18c4eec580e48862d3190d3c0,
                    0x89fbf0c52b76b888fd185e468b1c99,
                    0x9338fe,
                ],
            },
        ]
    }

    fn one() -> [BigNum<5, 512, BrainpoolP512r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: {
                    [
                        0x6d5047406a5e688b352209bcb9f822,
                        0x1f78e2d0d48d50d1687b93b97d5f7c,
                        0x70b5d916c1b43b62eef4d0098eff3b,
                        0xd82ed9645a21322e9c4c6a9385ed9f,
                        0x81aee4bd,
                    ]
                },
            },
            BigNum {
                limbs: {
                    [
                        0xca2b2fa8f0540678cd1e0f3ad80892,
                        0xde494a5f485e5bca4bd88a2763aed1,
                        0x24a57b1aa000c55b881f8111b2dc,
                        0x566332ecc0eabfa9cf7822fdf209f7,
                        0x7dde385d,
                    ]
                },
            },
        ]
    }
}


mod test {

    use crate::curves::brainpoolP512r1::BrainpoolP512r1Scalar;
    use crate::scalar_field::{ScalarField, ScalarFieldTrait};
    use dep::bignum::{BigNum, BigNumTrait};
    use crate::curves::brainpoolP512r1::BrainpoolP512r1_Fr_Params;

    #[test]
    fn test_brainpoolP512r1_bits() {
        let x: BigNum<5, 512, BrainpoolP512r1_Fr_Params> = BigNum::new();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        let scalar: BrainpoolP512r1Scalar = ScalarField::zero();
        let expected = scalar.len();
        assert(scalar_slices == expected);
    }
}