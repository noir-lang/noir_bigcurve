use crate::BigCurve;
use crate::CurveParamsTrait;
use crate::scalar_field::ScalarField;
use bignum::bignum::BigNum;
use bignum::params::BigNumParams;
use bignum::params::BigNumParamsGetter;

// ==== Params (can be moved to bignum later on) ====

pub struct Secp521r1_Fq_Params {}

impl BigNumParamsGetter<5, 521> for Secp521r1_Fq_Params {
    fn get_params() -> BigNumParams<5, 521> {
        Secp521r1_Fq_PARAMS
    }
}

global Secp521r1_Fq_PARAMS: BigNumParams<5, 521> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0xffffffffffffffffffffffffffffff,
        0x01ffffffffff,
    ],
    double_modulus: [
        0x01fffffffffffffffffffffffffffffe,
        0x01fffffffffffffffffffffffffffffe,
        0x01fffffffffffffffffffffffffffffe,
        0x01fffffffffffffffffffffffffffffe,
        0x03fffffffffe,
    ],
    redc_param: [0x10, 0x0, 0x0, 0x0, 0x200000000000],
};

pub struct Secp521r1_Fr_Params {}

impl BigNumParamsGetter<5, 521> for Secp521r1_Fr_Params {
    fn get_params() -> BigNumParams<5, 521> {
        Secp521r1_Fr_PARAMS
    }
}

global Secp521r1_Fr_PARAMS: BigNumParams<5, 521> = BigNumParams {
    has_multiplicative_inverse: true,
    modulus: [
        0xb5c9b8899c47aebb6fb71e91386409,
        0x8783bf2f966b7fcc0148f709a5d03b,
        0xfffffffffffffffffffffffffa5186,
        0xffffffffffffffffffffffffffffff,
        0x01ffffffffff,
    ],
    double_modulus: [
        0x016b937113388f5d76df6e3d2270c812,
        0x010f077e5f2cd6ff980291ee134ba076,
        0x01fffffffffffffffffffffffff4a30c,
        0x01fffffffffffffffffffffffffffffe,
        0x03fffffffffe,
    ],
    redc_param: [
        0xa36477663b851449048e16ec79bf70,
        0x87c40d069948033feb708f65a2fc44,
        0x5ae797,
        0x0,
        0x200000000000,
    ],
};
pub type Secp521r1 = BigCurve<BigNum<5, 521, Secp521r1_Fq_Params>, Secp521r1_Params>;
pub type Secp521r1Scalar = ScalarField<SECP521r1_SCALAR_SLICES>;
pub type Secp521r1Fq = BigNum<5, 521, Secp521r1_Fq_Params>;
pub type Secp521r1Fr = BigNum<5, 521, Secp521r1_Fr_Params>;

// ==== Curve ====

global SECP521r1_SCALAR_SLICES: u32 = 131;
pub struct Secp521r1_Params {}
impl CurveParamsTrait<BigNum<5, 521, Secp521r1_Fq_Params>> for Secp521r1_Params {
    fn a() -> BigNum<5, 521, Secp521r1_Fq_Params> {
        BigNum {
            limbs: [
                0xfffffffffffffffffffffffffffffc,
                0xffffffffffffffffffffffffffffff,
                0xffffffffffffffffffffffffffffff,
                0xffffffffffffffffffffffffffffff,
                0x01ffffffffff,
            ],
        }
    }
    fn b() -> BigNum<5, 521, Secp521r1_Fq_Params> {
        BigNum {
            limbs: {
                [
                    0x73df883d2c34f1ef451fd46b503f00,
                    0x3951ec7e937b1652c0bd3bb1bf0735,
                    0x5b99b315f3b8b489918ef109e15619,
                    0x8e1c9a1f929a21a0b68540eea2da72,
                    0x51953eb961,
                ]
            },
        }
    }

    fn offset_generator() -> [BigNum<5, 521, Secp521r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0x556e6521a2e048b585bd4221787414,
                    0xd054f5d5317edea39eac7c0cdc4338,
                    0x1317c4d27d768ef84cbe5b656be8c7,
                    0x1f171c2c85cf6432bc4cc735794aff,
                    0x019239eeece5,
                ],
            },
            BigNum {
                limbs: [
                    0x7a162ee85cbddff40688824e850caa,
                    0xcf8f5428560f64e195da7cdcceb42a,
                    0x36d91a939cab0b7cb093f4f586ff4a,
                    0xc05642261499a58d74752ac95a0058,
                    0x0145ca767742,
                ],
            },
        ]
    }

    fn offset_generator_final() -> [BigNum<5, 521, Secp521r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: [
                    0xb483f5efbac1cf69bca8bddc4dc26e,
                    0x02ad53022131b99528a619ead7e675,
                    0xd1889b76dfdd29015488507df6ad3b,
                    0x2f876099900e5e458a3c978bef39be,
                    0x01260121e9f4,
                ],
            },
            BigNum {
                limbs: [
                    0xedccb160310b14dae3a8faf4550e8a,
                    0x106d88c2d6a0a6f50d6609bc7e1a80,
                    0x053a8d8f0a56d8b08ae5482fdf2206,
                    0x84659f411d8392905aa718aa9b36c0,
                    0xb281ae4c0d,
                ],
            },
        ]
    }

    fn one() -> [BigNum<5, 521, Secp521r1_Fq_Params>; 2] {
        [
            BigNum {
                limbs: {
                    [
                        0x48b3c1856a429bf97e7e31c2e5bd66,
                        0x5e77efe75928fe1dc127a2ffa8de33,
                        0x39053fb521f828af606b4d3dbaa14b,
                        0x404e9cd9e3ecb662395b4429c6481,
                        0xc6858e06b7,
                    ]
                },
            },
            BigNum {
                limbs: {
                    [
                        0x3c7086a272c24088be94769fd16650,
                        0x72995ef42640c550b9013fad076135,
                        0x49579b446817afbd17273e662c97ee,
                        0x9a3bc0045c8a5fb42c7d1bd998f544,
                        0x011839296a78,
                    ]
                },
            },
        ]
    }
}

mod test {

    use crate::curves::secp521r1::Secp521r1_Fr_Params;
    use crate::curves::secp521r1::Secp521r1Scalar;
    use crate::scalar_field::{ScalarField, ScalarFieldTrait};
    use dep::bignum::{BigNum, BigNumTrait};

    #[test]
    fn test_secp521r1_bits() {
        let x: BigNum<5, 521, Secp521r1_Fr_Params> = BigNum::zero();
        let max_wnaf_bits: u32 = x.modulus_bits() + 1;

        let scalar_slices = (max_wnaf_bits / 4) + (max_wnaf_bits % 4 != 0) as u32;
        let scalar: Secp521r1Scalar = ScalarField::zero();
        let expected = scalar.len();
        assert(scalar_slices == expected);
    }
}
