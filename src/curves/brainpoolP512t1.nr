use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::bignum::BigNum;
use bignum::params::BigNumParams;
use bignum::params::BigNumParamsGetter;

// ==== Params (can be moved to bignum later on) ====

pub struct BrainpoolP512t1_Fq_Params {}

impl BigNumParamsGetter<5, 512> for BrainpoolP512t1_Fq_Params {
    fn get_params() -> BigNumParams<5, 512> {
        BrainpoolP512t1_Fq_PARAMS
    }
}

global BrainpoolP512t1_Fq_PARAMS: BigNumParams<5, 512> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0x81ff2f2d82c68528aa6056583a48f3,
        0x9b009bc66842aecda12ae6a380e628,
        0xb3b3c9d20ed6639cca703308717d4d,
        0xdbe9c48b3fd4e6ae33c9fc07cb308d,
        0xaadd9db8,
    ],
    double_modulus: [
        0x0103fe5e5b058d0a5154c0acb07491e6,
        0x013601378cd0855d9b4255cd4701cc50,
        0x01676793a41dacc73994e06610e2fa9a,
        0x01b7d389167fa9cd5c6793f80f96611a,
        0x0155bb3b70,
    ],
    redc_param: [
        0x621c4603556d117e2cf84e911e8d90,
        0xb38823152c5e47d93034e73ea8c71d,
        0xcc44ef09666ad8f2f5bf92f542ff2,
        0x6daeb8a15d5ea2f03461e1e8373af6,
        0x17f8d7f4ed,
    ],
};

pub struct BrainpoolP512t1_Fr_Params {}

impl BigNumParamsGetter<5, 512> for BrainpoolP512t1_Fr_Params {
    fn get_params() -> BigNumParams<5, 512> {
        BrainpoolP512t1_Fr_PARAMS
    }
}

global BrainpoolP512t1_Fr_PARAMS: BigNumParams<5, 512> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0xb1d381085ddaddb58796829ca90069,
        0x5c414ca92619418661197fac10471d,
        0xb3b3c9d20ed6639cca70330870553e,
        0xdbe9c48b3fd4e6ae33c9fc07cb308d,
        0xaadd9db8,
    ],
    double_modulus: [
        0x0163a70210bbb5bb6b0f2d05395200d2,
        0x01b88299524c32830cc232ff58208e3a,
        0x01676793a41dacc73994e06610e0aa7b,
        0x01b7d389167fa9cd5c6793f80f96611a,
        0x0155bb3b70,
    ],
    redc_param: [
        0xf0d9015d5c4ce2fafac64db57db370,
        0xc61a235d449ff38f5f59ee47100ea,
        0xcc44ef09666ad8f2f5bf92f7db947,
        0x6daeb8a15d5ea2f03461e1e8373af6,
        0x17f8d7f4ed,
    ],
};

pub type BrainpoolP512t1 = BigCurve<BigNum<5, 512, BrainpoolP512t1_Fq_Params>, BrainpoolP512t1_Params>;
pub type BrainpoolP512t1Scalar = ScalarField<BRAINPOOLP512T1_SCALAR_SLICES>;
pub type BrainpoolP512t1Fq = BigNum<5, 512, BrainpoolP512t1_Fq_Params>;
pub type BrainpoolP512t1Fr = BigNum<5, 512, BrainpoolP512t1_Fr_Params>;

// ==== Curve ====

global BRAINPOOLP512T1_SCALAR_SLICES: u32 = 129;
pub struct BrainpoolP512t1_Params {}
impl CurveParamsTrait<BigNum<5, 512, BrainpoolP512t1_Fq_Params>> for BrainpoolP512t1_Params {
    fn a() -> BigNum<5, 512, BrainpoolP512t1_Fq_Params> {
        BigNum {
            limbs: [
                0x81ff2f2d82c68528aa6056583a48f0,
                0x9b009bc66842aecda12ae6a380e628,
                0xb3b3c9d20ed6639cca703308717d4d,
                0xdbe9c48b3fd4e6ae33c9fc07cb308d,
                0xaadd9db8,
            ],
        }
    }
    fn b() -> BigNum<5, 512, BrainpoolP512t1_Fq_Params> {
        BigNum {
            limbs: {
                [
                    0x2553b465763689180ea2571867423e,
                    0xfa2304976540f6450085f2dae145c2,
                    0xbcb4981527897504bec3e36a62bcd,
                    0x441cfab76e1890e46884eae321f70c,
                    0x7cbbbcf9,
                ]
            },
        }
    }

    fn offset_generator() -> [BigNum<5, 512, BrainpoolP512t1_Fq_Params>; 2] {
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
                    0x1c6aa6c8709a7ece25d8f1f6edc899,
                    0x195ca5bccc18999c80123574962c7c,
                    0xa99e8057af3c1120b2f2201a1d92cc,
                    0x349185683024e53e809dd1ce4bc8b2,
                    0x44963c33,
                ],
            },
        ]
    }

    fn offset_generator_final() -> [BigNum<5, 512, BrainpoolP512t1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0x813b049374f7c0bb40fb2811111662,
                    0x8684539a69e1d3fe9bbf911e3ea04b,
                    0x9be7dc88b90072819806e09897121a,
                    0x9b130e4cc41066313fbe901f8761b0,
                    0x5f25a490,
                ],
            },
            BigNum {
                limbs: [
                    0x245156a742893d5e4b73e73dc82668,
                    0xc90ed6121108b6c30519ba1e3c9578,
                    0x59c6a6adcef48852e56ddbbf6a9f8a,
                    0x38e1d6da6bfd998f4fafd4344fb177,
                    0x1045e964,
                ],
            },
        ]
    }

    fn one() -> [BigNum<5, 512, BrainpoolP512t1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: {
                    [
                        0xa3f25fe26f06b51baa2696fa9035da,
                        0x51735cdb3ea499aa77a7d6943a64f7,
                        0x2458c56dde9db1758d39c0313d82ba,
                        0x12788717b9c1ba06cbc2a6feba8584,
                        0x640ece5c,
                    ]
                },
            },
            BigNum {
                limbs: {
                    [
                        0x6ecff96dbb8bace198b61e00f8b332,
                        0x2184beef216bd71df2dadf86a62730,
                        0x19b71634c01131159cae03cee9d993,
                        0x95f5af0fa2c892376c84ace1bb4e30,
                        0x5b534bd5,
                    ]
                },
            },
        ]
    }
}

mod test {

    use crate::curves::brainpoolP512t1::BrainpoolP512t1_Fr_Params;
    use crate::curves::brainpoolP512t1::BrainpoolP512t1Scalar;
    use crate::scalar_field::{ScalarField, ScalarFieldTrait};
    use dep::bignum::{BigNum, BigNumTrait};

    #[test]
    fn test_brainpoolP512t1_bits() {
        let x: BigNum<5, 512, BrainpoolP512t1_Fr_Params> = BigNum::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        let scalar: BrainpoolP512t1Scalar = ScalarField::zero();
        let expected = scalar.len();
        assert(scalar_slices == expected);
    }
}
