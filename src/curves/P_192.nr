use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::{BigNum,fields::P192Fq::{P192 as P192_Fq}};



// // // ==== Curve ====

global P192_SCALAR_SLICES: u32 = 49;

pub struct P192_Params {}
impl CurveParamsTrait<P192_Fq> for P192_Params {

    // a = 0xfffffffffffffffffffffffffffffffefffffffffffffffc
    fn a() -> P192_Fq {
        let a: Field = 0xfffffffffffffffffffffffffffffffefffffffffffffffc;
        P192_Fq::from(a)
    }
    // b = 0x64210519e59c80e70fa7e9ab72243049feb8deecc146b9b1
    fn b() -> P192_Fq {
       let b: Field = 0x64210519e59c80e70fa7e9ab72243049feb8deecc146b9b1;
       P192_Fq::from(b)
    }
    // (0x188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012, 0x07192b95ffc8da78631011ed6b24cdd573f977a11e794811)
    fn offset_generator() -> [P192_Fq; 2] { [P192_Fq::from_limbs([232713807617434633364479786242241517, 90646127116863941060]), P192_Fq::from_limbs([851326007238532123554569531696614955, 206678998028752795097])] }
    fn offset_generator_final() -> [P192_Fq; 2] { [P192_Fq::from_limbs([354972031435724352040004843069284759, 2389854163324638626497]), P192_Fq::from_limbs([634712850436303468863967363097653750, 2581934864307078617660])]  }

    fn one() -> [P192_Fq; 2] {
        let x = 0x188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012; 
        let y = 0x07192b95ffc8da78631011ed6b24cdd573f977a11e794811; 
        [P192_Fq::from(x), P192_Fq::from(y)]
    }
}


pub type P192 = BigCurve<P192_Fq, P192_Params>;
pub type P192Scalar = ScalarField<P192_SCALAR_SLICES>;

mod test {
    use super::P192_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::fields::P192Fq::{P192 as P192_Fq};

    #[test]
    fn test_p192_bits() {
        let x: P192_Fq = P192_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == P192_SCALAR_SLICES);
    }
}
