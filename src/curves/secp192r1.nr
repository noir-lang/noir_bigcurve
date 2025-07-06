use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
use bignum::fields::secp192r1Fq::Secp192r1_Fq;

global secp192r1_SCALAR_SLICES: u32 = 49;

pub struct Secp192r1_Params {}
impl CurveParamsTrait<Secp192r1_Fq> for Secp192r1_Params {

    // a = 0xfffffffffffffffffffffffffffffffefffffffffffffffc
    fn a() -> Secp192r1_Fq {
        let a: Field = 0xfffffffffffffffffffffffffffffffefffffffffffffffc;
        Secp192r1_Fq::from(a)
    }
    // b = 0x64210519e59c80e70fa7e9ab72243049feb8deecc146b9b1
    fn b() -> Secp192r1_Fq {
        let b: Field = 0x64210519e59c80e70fa7e9ab72243049feb8deecc146b9b1;
        Secp192r1_Fq::from(b)
    }
    // (0x188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012, 0x07192b95ffc8da78631011ed6b24cdd573f977a11e794811)
    fn offset_generator() -> [Secp192r1_Fq; 2] {
        [
            Secp192r1_Fq::from_limbs([232713807617434633364479786242241517, 90646127116863941060]),
            Secp192r1_Fq::from_limbs(
                [851326007238532123554569531696614955, 206678998028752795097],
            ),
        ]
    }
    fn offset_generator_final() -> [Secp192r1_Fq; 2] {
        [
            Secp192r1_Fq::from_limbs([354972031435724352040004843069284759, 2389854163324638626497]),
            Secp192r1_Fq::from_limbs([634712850436303468863967363097653750, 2581934864307078617660]),
        ]
    }

    fn one() -> [Secp192r1_Fq; 2] {
        let x = 0x188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012;
        let y = 0x07192b95ffc8da78631011ed6b24cdd573f977a11e794811;
        [Secp192r1_Fq::from(x), Secp192r1_Fq::from(y)]
    }
}

pub type Secp192r1 = BigCurve<Secp192r1_Fq, Secp192r1_Params>;
pub type Secp192r1Scalar = ScalarField<secp192r1_SCALAR_SLICES>;

mod test {
    use super::secp192r1_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::fields::secp192r1Fq::Secp192r1_Fq;

    #[test]
    fn test_p192_bits() {
        let x: Secp192r1_Fq = Secp192r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == secp192r1_SCALAR_SLICES);
    }
}
