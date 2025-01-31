use bignum::params::BigNumParams;
use bignum::params::BigNumParamsGetter;
use bignum::bignum::BigNum;
use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;

// ==== Params (can be moved to bignum later on) ====

pub struct BrainpoolP384t1_Fq_Params {}

impl BigNumParamsGetter<4, 384> for BrainpoolP384t1_Fq_Params {
    fn get_params() -> BigNumParams<4, 384> {
        BrainpoolP384t1_Fq_PARAMS
    }
}

global BrainpoolP384t1_Fq_PARAMS: BigNumParams<4, 384> = BigNumParams::new(
    true,
    [
        0xd3a729901d1a71874700133107ec53,
        0x7109ed5456b412b1da197fb71123ac,
        0x82a3386d280f5d6f7e50e641df152f,
        0x8cb91e,
    ],
    [
        0x7bce07a71566f10a03bf684a267160,
        0x449cae56ede9ed590cef1c4d721904,
        0x16d8ec6b8ff25adfd3cc6fa65dda2c,
        0x1d1b575b,
    ],
);

pub struct BrainpoolP384t1_Fr_Params {}

impl BigNumParamsGetter<4, 384> for BrainpoolP384t1_Fr_Params {
    fn get_params() -> BigNumParams<4, 384> {
        BrainpoolP384t1_Fr_PARAMS
    }
}

global BrainpoolP384t1_Fr_PARAMS: BigNumParams<4, 384> = BigNumParams::new(
    true,
    [
        0x3ab6af6b7fc3103b883202e9046565,
        0x7109ed5456b31f166e6cac0425a7cf,
        0x82a3386d280f5d6f7e50e641df152f,
        0x8cb91e,
    ],
    [
        0xfdb467a652109600adcccf8a71f8a0,
        0x449cae56ee1c506f2fe165031e7189,
        0x16d8ec6b8ff25adfd3cc6fa65dda2c,
        0x1d1b575b,
    ],
);

pub type BrainpoolP384t1 = BigCurve<BigNum<4, 384, BrainpoolP384t1_Fq_Params>, BrainpoolP384t1_Params>;
pub type BrainpoolP384t1Scalar = ScalarField<BRAINPOOLP384T1_SCALAR_SLICES>;
pub type BrainpoolP384t1Fq = BigNum<4, 384, BrainpoolP384t1_Fq_Params>;
pub type BrainpoolP384t1Fr = BigNum<4, 384, BrainpoolP384t1_Fr_Params>;

// ==== Curve ====

global BRAINPOOLP384T1_SCALAR_SLICES: u32 = 97;
pub struct BrainpoolP384t1_Params {}
impl CurveParamsTrait<BigNum<4, 384, BrainpoolP384t1_Fq_Params>> for BrainpoolP384t1_Params {
    fn a() -> BigNum<4, 384, BrainpoolP384t1_Fq_Params> {
        BigNum {
            limbs: [
                0xd3a729901d1a71874700133107ec50,
                0x7109ed5456b412b1da197fb71123ac,
                0x82a3386d280f5d6f7e50e641df152f,
                0x8cb91e,
            ],
        }
    }
    fn b() -> BigNum<4, 384, BrainpoolP384t1_Fq_Params> {
        BigNum {
            limbs: {
                [
                    0x74aa263b88805ced70355a33b471ee,
                    0x46ed8ccdc64e4b1abd11756dce1d20,
                    0xada7bda81bd826dba647910f8c4b93,
                    0x7f519e,
                ]
            },
        }
    }

    fn offset_generator() -> [BigNum<4, 384, BrainpoolP384t1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0xab2a95595a8cf5c742744146db4423,
                    0xcafbcff834543d7813419ddbc47dc9,
                    0x5d28d6a981a53726bf047776d08a7e,
                    0x168260,
                ],
            },
            BigNum {
                limbs: [
                    0x3a87f2e823514ed685a7dd25cfcdbe,
                    0xd7dd6f25cb3c5766b7a36e055c5523,
                    0xd29b58363212f0d12f1f8869a093fb,
                    0x6e1883,
                ],
            },
        ]
    }

    fn offset_generator_final() -> [BigNum<4, 384, BrainpoolP384t1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0x1e940dd0d5fd274ecda25613aea130,
                    0x6c088dcfccc1a92ada8b7195c33b31,
                    0x2fc84411ddaf2f68a06db9fcc77a59,
                    0x195942,
                ],
            },
            BigNum {
                limbs: [
                    0xf3c0a8d407798b901c3cd905ac157d,
                    0xfaa93dfeae5e0759fe001cf3f52f1d,
                    0x2fbc2d9f2c4f18a417c7b40823d678,
                    0x781ef2,
                ],
            },
        ]
    }

    fn one() -> [BigNum<4, 384, BrainpoolP384t1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: {
                    [
                        0xff191b946a5f54d8d0aa2f418808cc,
                        0xab12ebd653172476fecd462aabffc4,
                        0xb02db9a306f2afcd7235f72a819b80,
                        0x18de98,
                    ]
                },
            },
            BigNum {
                limbs: {
                    [
                        0x9408584dc2b2912675bf5b9e582928,
                        0x93475b7a1fca3b88f2b6a208ccfe46,
                        0x6962d30651a114afd2755ad336747f,
                        0x25ab05,
                    ]
                },
            },
        ]
    }
}

mod test {

    use crate::curves::brainpoolP384t1::BrainpoolP384t1Scalar;
    use crate::scalar_field::{ScalarField, ScalarFieldTrait};
    use dep::bignum::{BigNum, BigNumTrait};
    use crate::curves::brainpoolP384t1::BrainpoolP384t1_Fr_Params;

    #[test]
    fn test_brainpoolP384t1_bits() {
        let x: BigNum<4, 384, BrainpoolP384t1_Fr_Params> = BigNum::new();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        let scalar: BrainpoolP384t1Scalar = ScalarField::zero();
        let expected = scalar.len();
        assert(scalar_slices == expected);
    }
}