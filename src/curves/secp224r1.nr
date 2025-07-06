use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::BigNum;
use bignum::fields::secp224r1Fq::Secp224r1_Fq;

global secp224r1_SCALAR_SLICES: u32 = 57;

pub struct Secp224r1_Params {}
impl CurveParamsTrait<Secp224r1_Fq> for Secp224r1_Params {

    // a = 0xfffffffffffffffffffffffffffffffefffffffffffffffffffffffe
    fn a() -> Secp224r1_Fq {
        let a: Field = 0xfffffffffffffffffffffffffffffffefffffffffffffffffffffffe;
        Secp224r1_Fq::from(a)
    }
    // b = 0xb4050a850c04b3abf54132565044b0b7d7bfd8ba270b39432355ffb4
    fn b() -> Secp224r1_Fq {
        let b: Field = 0xb4050a850c04b3abf54132565044b0b7d7bfd8ba270b39432355ffb4;
        Secp224r1_Fq::from(b)
    }
    //
    fn offset_generator() -> [Secp224r1_Fq; 2] {
        [
            Secp224r1_Fq::from_limbs([
                256580546934709026519577652212863357,
                11339088992457647144137718767961,
            ]),
            Secp224r1_Fq::from_limbs([
                353594544583432096372112790460281511,
                2171878428325809151599171173861,
            ]),
        ]
    }
    fn offset_generator_final() -> [Secp224r1_Fq; 2] {
        [
            Secp224r1_Fq::from_limbs([
                1054362967121624051910781646571944004,
                13920482839761186129698370926212,
            ]),
            Secp224r1_Fq::from_limbs([
                1271693749289344300113760553252857630,
                17890356279514120347325778718798,
            ]),
        ]
    }

    // (0xb70e0cbd6bb4bf7f321390b94a03c1d356c21122343280d6115c1d21, 0xbd376388b5f723fb4c22dfe6cd4375a05a07476444d5819985007e34)
    fn one() -> [Secp224r1_Fq; 2] {
        let x = 0xb70e0cbd6bb4bf7f321390b94a03c1d356c21122343280d6115c1d21;
        let y = 0xbd376388b5f723fb4c22dfe6cd4375a05a07476444d5819985007e34;
        [Secp224r1_Fq::from(x), Secp224r1_Fq::from(y)]
    }
}

pub type Secp224r1 = BigCurve<Secp224r1_Fq, Secp224r1_Params>;
pub type Secp224r1Scalar = ScalarField<secp224r1_SCALAR_SLICES>;

mod test {
    use super::secp224r1_SCALAR_SLICES;
    use bignum::BigNum;
    use bignum::fields::secp224r1Fq::Secp224r1_Fq;

    #[test]
    fn test_secp224r1_bits() {
        let x: Secp224r1_Fq = Secp224r1_Fq::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        assert(scalar_slices == secp224r1_SCALAR_SLICES);
    }
}
