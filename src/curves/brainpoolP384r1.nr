use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::bignum::BigNum;
use bignum::params::BigNumParams;
use bignum::params::BigNumParamsGetter;

// ==== Params (can be moved to bignum later on) ====

pub struct BrainpoolP384r1_Fq_Params {}

impl BigNumParamsGetter<4, 384> for BrainpoolP384r1_Fq_Params {
    fn get_params() -> BigNumParams<4, 384> {
        BrainpoolP384r1_Fq_PARAMS
    }
}

global BrainpoolP384r1_Fq_PARAMS: BigNumParams<4, 384> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0xd3a729901d1a71874700133107ec53,
        0x7109ed5456b412b1da197fb71123ac,
        0x82a3386d280f5d6f7e50e641df152f,
        0x8cb91e,
    ],
    double_modulus: [
        0x01a74e53203a34e30e8e0026620fd8a6,
        0x01e213daa8ad682563b432ff6e224758,
        0x01054670da501ebadefca1cc83be2a5d,
        0x0119723c,
    ],
    redc_param: [
        0x7bce07a71566f10a03bf684a267160,
        0x449cae56ede9ed590cef1c4d721904,
        0x16d8ec6b8ff25adfd3cc6fa65dda2c,
        0x1d1b575b,
    ],
};

pub struct BrainpoolP384r1_Fr_Params {}

impl BigNumParamsGetter<4, 384> for BrainpoolP384r1_Fr_Params {
    fn get_params() -> BigNumParams<4, 384> {
        BrainpoolP384r1_Fr_PARAMS
    }
}

global BrainpoolP384r1_Fr_PARAMS: BigNumParams<4, 384> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0x3ab6af6b7fc3103b883202e9046565,
        0x7109ed5456b31f166e6cac0425a7cf,
        0x82a3386d280f5d6f7e50e641df152f,
        0x8cb91e,
    ],
    double_modulus: [
        0x01756d5ed6ff862077106405d208caca,
        0x01e213daa8ad663e2cdcd958084b4f9d,
        0x01054670da501ebadefca1cc83be2a5d,
        0x0119723c,
    ],
    redc_param: [
        0xfdb467a652109600adcccf8a71f8a0,
        0x449cae56ee1c506f2fe165031e7189,
        0x16d8ec6b8ff25adfd3cc6fa65dda2c,
        0x1d1b575b,
    ],
};

pub type BrainpoolP384r1 = BigCurve<BigNum<4, 384, BrainpoolP384r1_Fq_Params>, BrainpoolP384r1_Params>;
pub type BrainpoolP384r1Scalar = ScalarField<BRAINPOOLP384R1_SCALAR_SLICES>;
pub type BrainpoolP384r1Fq = BigNum<4, 384, BrainpoolP384r1_Fq_Params>;
pub type BrainpoolP384r1Fr = BigNum<4, 384, BrainpoolP384r1_Fr_Params>;

// ==== Curve ====

global BRAINPOOLP384R1_SCALAR_SLICES: u32 = 97;
pub struct BrainpoolP384r1_Params {}
impl CurveParamsTrait<BigNum<4, 384, BrainpoolP384r1_Fq_Params>> for BrainpoolP384r1_Params {
    fn a() -> BigNum<4, 384, BrainpoolP384r1_Fq_Params> {
        BigNum {
            limbs: [
                0xa5814a503ad4eb04a8c7dd22ce2826,
                0xa28e4fb22787139165efba91f90f8a,
                0xc63d8c150c3c72080ace05afa0c2be,
                0x7bc382,
            ],
        }
    }
    fn b() -> BigNum<4, 384, BrainpoolP384r1_Fq_Params> {
        BigNum {
            limbs: {
                [
                    0xb4390295dbc9943ab78696fa504c11,
                    0x7de107dcd2a62e880ea53eeb62d57c,
                    0xdd22ce28268b39b55416f0447c2fb7,
                    0x4a8c7,
                ]
            },
        }
    }

    fn offset_generator() -> [BigNum<4, 384, BrainpoolP384r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0xbbbaabfc4cac1a405d106d80d5c4d3,
                    0x43fd3007a1f13a542923edd0092e31,
                    0x56f1e610db6c0448cd751930f2aec1,
                    0x6bfeb1,
                ],
            },
            BigNum {
                limbs: [
                    0xc9c86458b6cea4b5b0de7915d7bbae,
                    0xac24a6ee83c6a3f28782753877c208,
                    0xeaa52b8f5dd6e1e0f1d1f7bebdcbb2,
                    0x3837d0,
                ],
            },
        ]
    }

    fn offset_generator_final() -> [BigNum<4, 384, BrainpoolP384r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0x2e9f7227713bea6f733c401324b4e0,
                    0x785e76d88efb112077932d55a977da,
                    0xa0a30affcd27bceca918db80e34dd6,
                    0x1bce71,
                ],
            },
            BigNum {
                limbs: [
                    0x5be84d2eeb67a7c229a9fa69e4b8fe,
                    0xbfe86c50b839a1fd240ccd06d5c2e6,
                    0xc93d3f8b990b154369ebf7c3621a8d,
                    0x60cef5,
                ],
            },
        ]
    }

    fn one() -> [BigNum<4, 384, BrainpoolP384r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: {
                    [
                        0x26e03436d646aaef87b2e247d4af1e,
                        0xa3e77ef14fe3db7fcafe0cbd10e8e8,
                        0xf068cf45ffa2a63a81b7c13f6b8847,
                        0x1d1c64,
                    ]
                },
            },
            BigNum {
                limbs: {
                    [
                        0x4646217791811142820341263c5315,
                        0xb29feec5864e19c054ff99129280e,
                        0x7520f9c2a45cb1eb8e95cfd55262b7,
                        0x8abe1d,
                    ]
                },
            },
        ]
    }
}

mod test {

    use crate::curves::brainpoolP384r1::BrainpoolP384r1_Fr_Params;
    use crate::curves::brainpoolP384r1::BrainpoolP384r1Scalar;
    use crate::scalar_field::{ScalarField, ScalarFieldTrait};
    use dep::bignum::{BigNum, BigNumTrait};

    #[test]
    fn test_brainpoolP384r1_bits() {
        let x: BigNum<4, 384, BrainpoolP384r1_Fr_Params> = BigNum::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        let scalar: BrainpoolP384r1Scalar = ScalarField::zero();
        let expected = scalar.len();
        assert(scalar_slices == expected);
    }
}
