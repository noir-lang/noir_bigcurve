use bignum::params::BigNumParams;
use bignum::params::BigNumParamsGetter;
use bignum::bignum::BigNum;
use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;

// ==== Params (can be moved to bignum later on) ====

pub struct BrainpoolP256r1_Fq_Params {}

impl BigNumParamsGetter<3, 256> for BrainpoolP256r1_Fq_Params {
    fn get_params() -> BigNumParams<3, 256> {
        BrainpoolP256r1_Fq_PARAMS
    }
}

global BrainpoolP256r1_Fq_PARAMS: BigNumParams<3, 256> = BigNumParams::new(
    true,
    [0x3bf623d52620282013481d1f6e5377, 0x57dba1eea9bc3e660a909d838d726e, 0xa9fb],
    [0xf54a0ff6a2fa9b62ae6301180dd0c0, 0x131a1c55b7ebb73aba8322a7bf29b4, 0x1818c1],
);

pub struct BrainpoolP256r1_Fr_Params {}

impl BigNumParamsGetter<3, 256> for BrainpoolP256r1_Fr_Params {
    fn get_params() -> BigNumParams<3, 256> {
        BrainpoolP256r1_Fr_PARAMS
    }
}

global BrainpoolP256r1_Fr_PARAMS: BigNumParams<3, 256> = BigNumParams::new(
    true,
    [0x397aa3b561a6f7901e0e82974856a7, 0x57dba1eea9bc3e660a909d838d718c, 0xa9fb],
    [0x88c5fdf55ea50d73b46ccd107160, 0x131a1c55b7ebb73aba8322a7bf49bf, 0x1818c1],
);

pub type BrainpoolP256r1 = BigCurve<BigNum<3, 256, BrainpoolP256r1_Fq_Params>, BrainpoolP256r1_Params>;
pub type BrainpoolP256r1Scalar = ScalarField<BRAINPOOLP256R1_SCALAR_SLICES>;
pub type BrainpoolP256r1Fq = BigNum<3, 256, BrainpoolP256r1_Fq_Params>;
pub type BrainpoolP256r1Fr = BigNum<3, 256, BrainpoolP256r1_Fr_Params>;

// ==== Curve ====

global BRAINPOOLP256R1_SCALAR_SLICES: u32 = 65;
pub struct BrainpoolP256r1_Params {}
impl CurveParamsTrait<BigNum<3, 256, BrainpoolP256r1_Fq_Params>> for BrainpoolP256r1_Params {
    fn a() -> BigNum<3, 256, BrainpoolP256r1_Fq_Params> {
        BigNum {
            limbs: [0x8055c126dc5c6ce94a4b44f330b5d9, 0x975fc2c3057eef67530417affe7fb, 0x7d5a],
        }
    }
    fn b() -> BigNum<3, 256, BrainpoolP256r1_Fq_Params> {
        BigNum {
            limbs: { [0x8416295cf7e1ce6bccdc18ff8c07b6, 0x5c6ce94a4b44f330b5d9bbd77cbf95, 0x26dc] },
        }
    }

    fn offset_generator() -> [BigNum<3, 256, BrainpoolP256r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [0xdf7b7690a146dc4daa3e512094cd28, 0x0293f430def68c091076b5e85608a3, 0x256a],
            },
            BigNum {
                limbs: [0xe90d38a99e804a5d800451dcb0103e, 0x398ffd08546ea665948bc7f6fb6ca7, 0x0b5e],
            },
        ]
    }

    fn offset_generator_final() -> [BigNum<3, 256, BrainpoolP256r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [0xa92997c4eee759bbff34df47c83551, 0x49c4a27c8f3a09dce7819cd9e8903d, 0x8bd1],
            },
            BigNum {
                limbs: [0x7c95e35a05c9ad107623858de9a569, 0x9fd7b0ea3a97ed1cd0b8820e3aec6d, 0x26e5],
            },
        ]
    }

    fn one() -> [BigNum<3, 256, BrainpoolP256r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: {
                    [0xde27e1e3bd23c23a4453bd9ace3262, 0xaeb9cb7e57cb2c4b482ffc81b7afb9, 0x8bd2]
                },
            },
            BigNum {
                limbs: {
                    [0x7745132ded8e545c1d54c72f046997, 0xf835c3dac4fd97f8461a14611dc9c2, 0x547e]
                },
            },
        ]
    }
}

mod test {

    use crate::curves::brainpoolP256r1::BrainpoolP256r1Scalar;
    use crate::scalar_field::{ScalarField, ScalarFieldTrait};
    use dep::bignum::{BigNum, BigNumTrait};
    use crate::curves::brainpoolP256r1::BrainpoolP256r1_Fr_Params;

    #[test]
    fn test_brainpoolP256r1_bits() {
        let x: BigNum<3, 256, BrainpoolP256r1_Fr_Params> = BigNum::new();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        let scalar: BrainpoolP256r1Scalar = ScalarField::zero();
        let expected = scalar.len();
        assert(scalar_slices == expected);
    }
}
