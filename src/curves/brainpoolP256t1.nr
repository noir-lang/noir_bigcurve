use bignum::params::BigNumParams;
use bignum::params::BigNumParamsGetter;
use bignum::bignum::BigNum;
use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;

// ==== Params (can be moved to bignum later on) ====

pub struct BrainpoolP256t1_Fq_Params {}

impl BigNumParamsGetter<3, 256> for BrainpoolP256t1_Fq_Params {
    fn get_params() -> BigNumParams<3, 256> {
        BrainpoolP256t1_Fq_PARAMS
    }
}

global BrainpoolP256t1_Fq_PARAMS: BigNumParams<3, 256> = BigNumParams::new(
    true,
    [0x3bf623d52620282013481d1f6e5377, 0x57dba1eea9bc3e660a909d838d726e, 0xa9fb],
    [0xf54a0ff6a2fa9b62ae6301180dd0c0, 0x131a1c55b7ebb73aba8322a7bf29b4, 0x1818c1],
);

pub struct BrainpoolP256t1_Fr_Params {}

impl BigNumParamsGetter<3, 256> for BrainpoolP256t1_Fr_Params {
    fn get_params() -> BigNumParams<3, 256> {
        BrainpoolP256t1_Fr_PARAMS
    }
}

global BrainpoolP256t1_Fr_PARAMS: BigNumParams<3, 256> = BigNumParams::new(
    true,
    [0x397aa3b561a6f7901e0e82974856a7, 0x57dba1eea9bc3e660a909d838d718c, 0xa9fb],
    [0x88c5fdf55ea50d73b46ccd107160, 0x131a1c55b7ebb73aba8322a7bf49bf, 0x1818c1],
);

pub type BrainpoolP256t1 = BigCurve<BigNum<3, 256, BrainpoolP256t1_Fq_Params>, BrainpoolP256t1_Params>;
pub type BrainpoolP256t1Scalar = ScalarField<BRAINPOOLP256T1_SCALAR_SLICES>;
pub type BrainpoolP256t1Fq = BigNum<3, 256, BrainpoolP256t1_Fq_Params>;
pub type BrainpoolP256t1Fr = BigNum<3, 256, BrainpoolP256t1_Fr_Params>;


// ==== Curve ====

global BRAINPOOLP256T1_SCALAR_SLICES: u32 = 65;
pub struct BrainpoolP256t1_Params {}
impl CurveParamsTrait<BigNum<3, 256, BrainpoolP256t1_Fq_Params>> for BrainpoolP256t1_Params {
    fn a() -> BigNum<3, 256, BrainpoolP256t1_Fq_Params> {
        BigNum {
            limbs: [0x3bf623d52620282013481d1f6e5374, 0x57dba1eea9bc3e660a909d838d726e, 0xa9fb],
        }
    }
    fn b() -> BigNum<3, 256, BrainpoolP256t1_Fq_Params> {
        BigNum {
            limbs: { [0x93ebc4af2f49256ae58101fee92b04, 0x61c430d84ea4fe66a7733d0b76b7bf, 0x662c] },
        }
    }

    fn offset_generator() -> [BigNum<3, 256, BrainpoolP256t1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [0xdf7b7690a146dc4daa3e512094cd28, 0x0293f430def68c091076b5e85608a3, 0x256a],
            },
            BigNum {
                limbs: [0x3cd2eb3fdb4d801d7d357371eeb0f7, 0xaa3d8b3084d3a11df020a3fe22a258, 0x4ecd],
            },
        ]
    }

    fn offset_generator_final() -> [BigNum<3, 256, BrainpoolP256t1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [0x982c0658a8aa105afe1c74b5f403b5, 0x7b8ade1081f0492e3fab6d9a99d0c2, 0x7dcf],
            },
            BigNum {
                limbs: [0x442f5f8f9bdef5a5366dc979b93d2a, 0xd1c8259ef3e220a6792624929c0520, 0x4862],
            },
        ]
    }

    fn one() -> [BigNum<3, 256, BrainpoolP256t1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: {
                    [0xa142c47aafbc2b79a191562e1305f4, 0xeb3cc1cfe7b7732213b23a656149af, 0xa3e8]
                },
            },
            BigNum {
                limbs: {
                    [0xbcb6de39d027001dabe8f35b25c9be, 0x6c823439c56d7f7b22e14644417e69, 0x2d99]
                },
            },
        ]
    }
}

mod test {

    use crate::curves::brainpoolP256t1::BrainpoolP256t1Scalar;
    use crate::scalar_field::{ScalarField, ScalarFieldTrait};
    use dep::bignum::{BigNum, BigNumTrait};
    use crate::curves::brainpoolP256t1::BrainpoolP256t1_Fr_Params;

    #[test]
    fn test_brainpoolP256t1_bits() {
        let x: BigNum<3, 256, BrainpoolP256t1_Fr_Params> = BigNum::new();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        let scalar: BrainpoolP256t1Scalar = ScalarField::zero();
        let expected = scalar.len();
        assert(scalar_slices == expected);
    }
}