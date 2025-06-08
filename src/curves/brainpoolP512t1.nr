use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
pub use bignum::{BrainpoolP512t1_Fq, BrainpoolP512t1_Fr};

pub type BrainpoolP512t1 = BigCurve<BrainpoolP512t1_Fq, BrainpoolP512t1_Params>;
pub type BrainpoolP512t1Scalar = ScalarField<BRAINPOOLP512T1_SCALAR_SLICES>;

// ==== Curve ====

global BRAINPOOLP512T1_SCALAR_SLICES: u32 = 129;
pub struct BrainpoolP512t1_Params {}
impl CurveParamsTrait<BrainpoolP512t1_Fq> for BrainpoolP512t1_Params {
    fn a() -> BrainpoolP512t1_Fq {
        BigNum::from_limbs([
            0x81ff2f2d82c68528aa6056583a48f0,
            0x9b009bc66842aecda12ae6a380e628,
            0xb3b3c9d20ed6639cca703308717d4d,
            0xdbe9c48b3fd4e6ae33c9fc07cb308d,
            0xaadd9db8,
        ])
    }
    fn b() -> BrainpoolP512t1_Fq {
        BigNum::from_limbs([
            0x2553b465763689180ea2571867423e,
            0xfa2304976540f6450085f2dae145c2,
            0xbcb4981527897504bec3e36a62bcd,
            0x441cfab76e1890e46884eae321f70c,
            0x7cbbbcf9,
        ])
    }

    fn offset_generator() -> [BrainpoolP512t1_Fq; 2] {
        [
            BigNum::from_limbs([
                0xdcf10230b2c0660f79fc7397a8c6e5,
                0x0556564b4b7901a0beaed7a0891da5,
                0xc135b5fb1581ddaa80896e30daee11,
                0x1a481ad9252517735bfe56e66da9f7,
                0x66cbe79a,
            ]),
            BigNum::from_limbs([
                0x1c6aa6c8709a7ece25d8f1f6edc899,
                0x195ca5bccc18999c80123574962c7c,
                0xa99e8057af3c1120b2f2201a1d92cc,
                0x349185683024e53e809dd1ce4bc8b2,
                0x44963c33,
            ]),
        ]
    }

    fn offset_generator_final() -> [BrainpoolP512t1_Fq; 2] {
        [
            BigNum::from_limbs([
                0x813b049374f7c0bb40fb2811111662,
                0x8684539a69e1d3fe9bbf911e3ea04b,
                0x9be7dc88b90072819806e09897121a,
                0x9b130e4cc41066313fbe901f8761b0,
                0x5f25a490,
            ]),
            BigNum::from_limbs([
                0x245156a742893d5e4b73e73dc82668,
                0xc90ed6121108b6c30519ba1e3c9578,
                0x59c6a6adcef48852e56ddbbf6a9f8a,
                0x38e1d6da6bfd998f4fafd4344fb177,
                0x1045e964,
            ]),
        ]
    }

    fn one() -> [BrainpoolP512t1_Fq; 2] {
        [
            BigNum::from_limbs([
                0xa3f25fe26f06b51baa2696fa9035da,
                0x51735cdb3ea499aa77a7d6943a64f7,
                0x2458c56dde9db1758d39c0313d82ba,
                0x12788717b9c1ba06cbc2a6feba8584,
                0x640ece5c,
            ]),
            BigNum::from_limbs([
                0x6ecff96dbb8bace198b61e00f8b332,
                0x2184beef216bd71df2dadf86a62730,
                0x19b71634c01131159cae03cee9d993,
                0x95f5af0fa2c892376c84ace1bb4e30,
                0x5b534bd5,
            ]),
        ]
    }
}

mod test {
    use super::BRAINPOOLP512T1_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::BrainpoolP512t1_Fq;

    #[test]
    fn test_brainpoolP512t1_bits() {
        let x: BrainpoolP512t1_Fq = BrainpoolP512t1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == BRAINPOOLP512T1_SCALAR_SLICES);
    }
}
