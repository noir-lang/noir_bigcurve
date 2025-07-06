use std::{ops::Neg, panic};

use crate::{BigCurve, BigCurveTrait};
use crate::curve_jac::CurveJ;
use crate::CurveParamsTrait;

use crate::curves::brainpoolP192r1::BrainpoolP192r1_Params;
use crate::curves::brainpoolP192t1::BrainpoolP192t1_Params;
use crate::curves::brainpoolP224r1::BrainpoolP224r1_Params;
use crate::curves::brainpoolP224t1::BrainpoolP224t1_Params;
use crate::curves::secp224r1::Secp224r1_Params;
use bignum::BigNum;
use bignum::BLS12_377_Fq;
use bignum::BLS12_381_Fq;
use bignum::BN254_Fq;
use bignum::BrainpoolP192r1_Fq;
use bignum::BrainpoolP192t1_Fq;
use bignum::BrainpoolP224r1_Fq;
use bignum::BrainpoolP224t1_Fq;
use bignum::fields::secp192r1Fq::Secp192r1_Fq;
use bignum::fields::secp224r1Fq::Secp224r1_Fq;
use bignum::MNT4_753_Fq;
use bignum::MNT6_753_Fq;
use bignum::Pallas_Fq;
use bignum::Secp256k1_Fr;
use bignum::Secp256r1_Fr;
use bignum::Secp384r1_Fr;
use bignum::Vesta_Fq;
pub struct BLS377PartialCurveParams {}

impl CurveParamsTrait<BLS12_377_Fq> for BLS377PartialCurveParams {
    fn a() -> BLS12_377_Fq {
        BLS12_377_Fq::zero()
    }
    fn b() -> BLS12_377_Fq {
        BLS12_377_Fq::one()
    }
    fn one() -> [BLS12_377_Fq; 2] {
        let y = BLS12_377_Fq::from_limbs([
            0xfe3d3634a9591afd82de55559c8ea6,
            0xb348ca3e52d96d182ad44fb82305c2,
            0x69c5102eff1f674f5d30afeec4bd7f,
            0x01914a,
        ]);
        let x = BLS12_377_Fq::from_limbs([
            0x481512ffcd394eeab9b16eb21be9ef,
            0x1e2caa9d41bb188282c8bd37cb5cd5,
            0xdefe740a67c8fc6225bf87ff548595,
            0x008848,
        ]);
        [x, y]
    }

    fn offset_generator_final() -> [BLS12_377_Fq; 2] {
        BLS377PartialCurveParams::one()
    }

    fn offset_generator() -> [BLS12_377_Fq; 2] {
        BLS377PartialCurveParams::one()
    }
}

pub struct BLS381PartialCurveParams {}
impl CurveParamsTrait<BLS12_381_Fq> for BLS381PartialCurveParams {
    fn a() -> BLS12_381_Fq {
        BLS12_381_Fq::zero()
    }
    fn b() -> BLS12_381_Fq {
        let mut r = BLS12_381_Fq::zero();
        r.set_limb(0, 4);
        r
    }

    fn one() -> [BLS12_381_Fq; 2] {
        let y = BLS12_381_Fq::from_limbs([
            0x3CC744A2888AE40CAA232946C5E7E,
            0xE095D5D00AF600DB18CB2C04B3EDD0,
            0x81E3AAA0F1A09E30ED741D8AE4FCF5,
            0x08B3F4,
        ]);
        let x = BLS12_381_Fq::from_limbs([
            0x55E83FF97A1AEFFB3AF00ADB22C6B,
            0x8C4F9774B905A14E3A3F171BAC586C,
            0xA73197D7942695638C4FA9AC0FC368,
            0x17F1D3,
        ]);
        [x, y]
    }

    fn offset_generator_final() -> [BLS12_381_Fq; 2] {
        panic(f"generator does not exist!")
    }

    fn offset_generator() -> [BLS12_381_Fq; 2] {
        panic(f"generator does not exist!")
    }
}

pub struct Curve25519PartialCurveParams {}
// impl CurveParamsTrait<ED25519BN> for Curve25519PartialCurveParams {
//     fn a() -> ED25519BN {
//         BigNum { limbs: [486662, 0, 0] }
//     }
//     fn b() -> ED25519BN {
//         BigNum { limbs: [1, 0, 0] }
//     }

//     fn one() -> [ED25519BN; 2] {
//         let mut y: ED25519BN = BigNum::from_limbs( [0x3d4d7e6d7c61b229e9c5a27eced3d9, 0x19a1b8a086b4e01edd2c7748d14c92, 0x20ae],
//         );

//         let mut x: ED25519BN = BigNum { limbs: [9, 0, 0] };
//         [x, y]
//     }

//     fn offset_generator_final() -> [ED25519BN; 2] {
//         panic(f"generator does not exist!")
//     }

//     fn offset_generator() -> [ED25519BN; 2] {
//         panic(f"generator does not exist!")
//     }
// }

pub struct Secp256r1PartialCurveParams {}
impl CurveParamsTrait<Secp256r1_Fr> for Secp256r1PartialCurveParams {
    fn a() -> Secp256r1_Fr {
        Secp256r1_Fr::from_limbs([
            0x000000fffffffffffffffffffffffc,
            0xffff00000001000000000000000000,
            0xffff,
        ])
    }
    fn b() -> Secp256r1_Fr {
        Secp256r1_Fr::from_limbs([
            0x1d06b0cc53b0f63bce3c3e27d2604b,
            0x35d8aa3a93e7b3ebbd55769886bc65,
            0x5ac6,
        ])
    }

    fn one() -> [Secp256r1_Fr; 2] {
        let y = Secp256r1_Fr::from_limbs([
            0xce33576b315ececbb6406837bf51f5,
            0x42e2fe1a7f9b8ee7eb4a7c0f9e162b,
            0x4fe3,
        ]);
        let x = Secp256r1_Fr::from_limbs([
            0x037d812deb33a0f4a13945d898c296,
            0xd1f2e12c4247f8bce6e563a440f277,
            0x6b17,
        ]);
        [x, y]
    }

    fn offset_generator_final() -> [Secp256r1_Fr; 2] {
        panic(f"generator does not exist!")
    }

    fn offset_generator() -> [Secp256r1_Fr; 2] {
        panic(f"generator does not exist!")
    }
}

pub struct P192PartialCurveParams {}
impl CurveParamsTrait<Secp192r1_Fq> for P192PartialCurveParams {
    fn a() -> Secp192r1_Fq {
        let a: Field = 0xfffffffffffffffffffffffffffffffefffffffffffffffc;
        Secp192r1_Fq::from(a)
    }
    fn b() -> Secp192r1_Fq {
        let b = 0x64210519e59c80e70fa7e9ab72243049feb8deecc146b9b1;
        Secp192r1_Fq::from(b)
    }

    fn one() -> [Secp192r1_Fq; 2] {
        let x = 0x188da80eb03090f67cbf20eb43a18800f4ff0afd82ff1012;
        let y = 0x07192b95ffc8da78631011ed6b24cdd573f977a11e794811;
        [Secp192r1_Fq::from(x), Secp192r1_Fq::from(y)]
    }

    fn offset_generator() -> [Secp192r1_Fq; 2] {
        [
            Secp192r1_Fq::from_limbs([0x2cd1ad32ee897a00308b502d4b73ed, 0x4e9f7bc59599429c4]),
            Secp192r1_Fq::from_limbs([0xa3f59ce015e46c1665c2b29b940e2b, 0xb343f4dacc57835d9]),
        ]
    }
    fn offset_generator_final() -> [Secp192r1_Fq; 2] {
        [
            Secp192r1_Fq::from_limbs([0x2159802de6552a9f8dd88c322f3e94, 0x337387dc59578aa74f]),
            Secp192r1_Fq::from_limbs([0xee6981164ce518b87adb6c499e4f28, 0x975029505881daf7ed]),
        ]
    }
}

pub struct Secp384r1PartialCurveParams {}
impl CurveParamsTrait<Secp384r1_Fr> for Secp384r1PartialCurveParams {
    fn a() -> Secp384r1_Fr {
        let x: Secp384r1_Fr = Secp384r1_Fr::from_limbs([3, 0, 0, 0]);
        x.neg()
    }
    fn b() -> Secp384r1_Fr {
        Secp384r1_Fr::from_limbs([
            0x56398D82ED19D2A85C8EDD3EC2AEF,
            0x9C6EFE8141120314088F5013875AC6,
            0xA7E23EE7E4988E056BE3F82D19181D,
            0xB3312F,
        ])
    }

    fn one() -> [Secp384r1_Fr; 2] {
        let mut y: Secp384r1_Fr = Secp384r1_Fr::from_limbs([
            0x60B1CE1D7E819D7A431D7C90EA0E5,
            0x1DBD289A147CE9DA3113B5F0B8C00A,
            0x4A96262C6F5D9E98BF9292DC29F8F4,
            0x3617DE,
        ]);

        let mut x: Secp384r1_Fr = Secp384r1_Fr::from_limbs([
            0x02F25DBF55296C3A545E3872760AB,
            0x3B628BA79B9859F741E082542A3855,
            0x22BE8B05378EB1C71EF320AD746E1D,
            0xAA87CA,
        ]);
        [x, y]
    }

    fn offset_generator_final() -> [Secp384r1_Fr; 2] {
        panic(f"generator does not exist!")
    }

    fn offset_generator() -> [Secp384r1_Fr; 2] {
        panic(f"generator does not exist!")
    }
}

pub struct Secp256k1PartialCurveParams {}
impl CurveParamsTrait<Secp256k1_Fr> for Secp256k1PartialCurveParams {
    fn a() -> Secp256k1_Fr {
        Secp256k1_Fr::from_limbs([0, 0, 0])
    }
    fn b() -> Secp256k1_Fr {
        Secp256k1_Fr::from_limbs([7, 0, 0])
    }

    fn one() -> [Secp256k1_Fr; 2] {
        let y = Secp256k1_Fr::from_limbs([
            0x17b448a68554199c47d08ffb10d4b8,
            0xda7726a3c4655da4fbfc0e1108a8fd,
            0x483a,
        ]);
        let x = Secp256k1_Fr::from_limbs([
            0x9bfcdb2dce28d959f2815b16f81798,
            0x667ef9dcbbac55a06295ce870b0702,
            0x79be,
        ]);
        [x, y]
    }

    fn offset_generator_final() -> [Secp256k1_Fr; 2] {
        panic(f"generator does not exist!")
    }

    fn offset_generator() -> [Secp256k1_Fr; 2] {
        panic(f"generator does not exist!")
    }
}

pub struct Mnt4PartialCurveParams {}
impl CurveParamsTrait<MNT4_753_Fq> for Mnt4PartialCurveParams {
    fn a() -> MNT4_753_Fq {
        MNT4_753_Fq::from_limbs([2, 0, 0, 0, 0, 0, 0])
    }
    fn b() -> MNT4_753_Fq {
        MNT4_753_Fq::from_limbs([
            0xAD26545E06372009C9A0491678EF4,
            0x773111C36C8B1B4E8F1ECE940EF9EA,
            0xC3D8BB21C8D68BB8CFB9DB4B8C8FBA,
            0xA92C78DC537E51A16703EC9855C77F,
            0x051C596560835DF0C9E50A5B59B882,
            0xC9DCAE7A016AC5D7748D3313CD8E39,
            0x01373684A8,
        ])
    }

    fn one() -> [MNT4_753_Fq; 2] {
        let y = MNT4_753_Fq::from_limbs([
            0x031EA99CFF05E05EC3BE2E4A05058,
            0x23036DB8FB990A342449CAEB92FA6B,
            0x5DEA57EF53EE29157BDF1B741AEBD4,
            0xEE5599DD7C3DFA4100284833115AEC,
            0x7FDDCDEA19CB10B2BF61F37AE2C456,
            0x26E257B175AE94DEB9E10ABA4BA72F,
            0x4AB64735,
        ]);

        let x = MNT4_753_Fq::from_limbs([
            0xC2AB23BE1C24740AF0FDEB3B7F181,
            0xFEFF338DD73A5A7EEECFBCE7CF95D3,
            0x463D98A4EA009D57AAD9716F708885,
            0x6D1EF781D1DE4FFB1F806B314C5AD3,
            0xEFA5546444D40C82D6A271F1A43862,
            0x450BB76A02D86DAAFFBAEB69995EB9,
            0x542F1DAD,
        ]);
        [x, y]
    }

    fn offset_generator_final() -> [MNT4_753_Fq; 2] {
        panic(f"generator does not exist!")
    }

    fn offset_generator() -> [MNT4_753_Fq; 2] {
        panic(f"generator does not exist!")
    }
}

pub struct Mnt6PartialCurveParams {}
impl CurveParamsTrait<MNT6_753_Fq> for Mnt6PartialCurveParams {
    fn a() -> MNT6_753_Fq {
        MNT6_753_Fq::from_limbs([11, 0, 0, 0, 0, 0, 0])
    }
    fn b() -> MNT6_753_Fq {
        MNT6_753_Fq::from_limbs([
            0xBA7505B6FCF2485540B13DFC8468A,
            0xF9A80A95F401867C4E80F4747FDE5A,
            0x0FCF2C43D7BF847957C34CCA1E3585,
            0xB7985993F62F03B22A9A3C737A1A1E,
            0xBB64B2BB01B10E60A5D5DFE0A25714,
            0x0863C79D56446237CE2E1468D14AE9,
            0x7DA285E7,
        ])
    }

    fn one() -> [MNT6_753_Fq; 2] {
        let y = MNT6_753_Fq::from_limbs([
            0x521DF9855687139F0C51754C0CC49,
            0x4D9992F5CBF4B2CC4C42EFF9A5A6C4,
            0x0DC7A593CCE5A792E94D0020C335B7,
            0x4C7A18ED9C4BD3C7ED0FFB31C57E61,
            0x2A3585BDD6D7722C6C07D7873BB02D,
            0x6E2EB3FCA70DC1063BAC3455180120,
            0x128C02FFF,
        ]);

        let x = MNT6_753_Fq::from_limbs([
            0x329A6FEFA9A1F3F7A1FBD93A7BFB8,
            0x1ACBF7DA60895B8B3D9D442C4C4123,
            0xE5E3C57B6DF120CEE3CD9D867E66D1,
            0x0C0D5FC5E818771B931F1D5BDD069C,
            0x131C2437E884C4997FD1DCB409367D,
            0x6E831147412CFB1002284F30338088,
            0x255F8E87,
        ]);
        [x, y]
    }

    fn offset_generator_final() -> [MNT6_753_Fq; 2] {
        panic(f"generator does not exist!")
    }

    fn offset_generator() -> [MNT6_753_Fq; 2] {
        panic(f"generator does not exist!")
    }
}

pub struct BN254PartialCurveParams {}
impl CurveParamsTrait<BN254_Fq> for BN254PartialCurveParams {
    fn a() -> BN254_Fq {
        BN254_Fq::zero()
    }
    fn b() -> BN254_Fq {
        BN254_Fq::from_limbs([3, 0, 0])
    }

    fn one() -> [BN254_Fq; 2] {
        let mut y: BN254_Fq = BN254_Fq::from_limbs([2, 0, 0]);

        let mut x: BN254_Fq = BN254_Fq::one();
        [x, y]
    }

    fn offset_generator_final() -> [BN254_Fq; 2] {
        panic(f"generator does not exist!")
    }

    fn offset_generator() -> [BN254_Fq; 2] {
        panic(f"generator does not exist!")
    }
}

pub struct PallasPartialCurveParams {}
impl CurveParamsTrait<Pallas_Fq> for PallasPartialCurveParams {
    fn a() -> Pallas_Fq {
        Pallas_Fq::zero()
    }
    fn b() -> Pallas_Fq {
        Pallas_Fq::from_limbs([5, 0, 0])
    }

    fn one() -> [Pallas_Fq; 2] {
        let mut y: Pallas_Fq = Pallas_Fq::from_limbs([2, 0, 0]);

        let mut x: Pallas_Fq = Pallas_Fq::one().neg();
        [x, y]
    }

    fn offset_generator_final() -> [Pallas_Fq; 2] {
        panic(f"generator does not exist!")
    }

    fn offset_generator() -> [Pallas_Fq; 2] {
        panic(f"generator does not exist!")
    }
}

pub struct VestaPartialCurveParams {}
impl CurveParamsTrait<Vesta_Fq> for VestaPartialCurveParams {
    fn a() -> Vesta_Fq {
        Vesta_Fq::zero()
    }
    fn b() -> Vesta_Fq {
        Vesta_Fq::from_limbs([5, 0, 0])
    }

    fn one() -> [Vesta_Fq; 2] {
        let y = Vesta_Fq::from_limbs([2, 0, 0]);

        let x = Vesta_Fq::one().neg();
        [x, y]
    }

    fn offset_generator_final() -> [Vesta_Fq; 2] {
        panic(f"generator does not exist!")
    }

    fn offset_generator() -> [Vesta_Fq; 2] {
        panic(f"generator does not exist!")
    }
}
/*
(

   )
*/
unconstrained fn compute_and_print_offset_generators<Fq, Curve, let K: u32, let J: u32, let NScalarSlices: u32>(
    n: u32,
    paramstr: str<K>,
    curvestr: str<J>,
    cofactor: Field,
)
where
    Fq: BigNum,
    Curve: CurveParamsTrait<Fq>,
{
    let a = Curve::a();
    let b = Curve::b();
    let one = Curve::one();

    let input: BigCurve<Fq, Curve> = BigCurve::one();
    input.validate_on_curve();

    let seed: [u8; 25] = "bigcurve offset generator".as_bytes();

    // we only need well-defined parameters for a and b, for hash_to_curve to work
    // (no offset gneerators needed)
    let g: BigCurve<Fq, Curve> = BigCurve::hash_to_curve(seed);

    let g_init: CurveJ<Fq, Curve> = CurveJ { x: g.x, y: g.y, z: Fq::one(), is_infinity: false };
    let mut gen = g_init;

    let cofactor_bits: [u1; 128] = cofactor.to_be_bits();
    let mut it: u32 = 0;
    for i in 0..128 {
        if (cofactor_bits[i] == 1) {
            it = i + 1;
            break;
        }
    }

    for i in it..128 {
        gen = gen.dbl().0;
        if (cofactor_bits[i] == 1) {
            gen = gen.incomplete_add(g_init).0;
        }
    }

    let mut offset_generator_initial: [Fq; 2] = [Fq::new(); 2];
    let mut offset_generator_final: [Fq; 2] = [Fq::new(); 2];

    {
        let mut genz = gen.z;
        genz = genz.__invmod();
        let zz = genz.__mul(genz);
        let zzz = zz.__mul(genz);

        offset_generator_initial[0] = gen.x.__mul(zz);
        offset_generator_initial[1] = gen.y.__mul(zzz);
    }

    let end = (NScalarSlices - 1) * 4;
    for _ in 0..end {
        gen = gen.dbl().0;
    }
    {
        let mut genz = gen.z;
        genz = genz.__invmod();
        let zz = genz.__mul(genz);
        let zzz = zz.__mul(genz);

        offset_generator_final[0] = gen.x.__mul(zz);
        offset_generator_final[1] = gen.y.__mul(zzz);
    }

    println(f"pub struct {curvestr} {{}}");
    println(
        f"impl CurveParamsTrait<BigNum<{n}, {paramstr}>> for {curvestr} {{",
    );

    println(f"  fn a() -> BigNum<{n}, {paramstr}> {{ {a} }}");
    println(f"  fn b() -> BigNum<{n}, {paramstr}> {{ {b} }}");
    println(f"  fn one() -> [BigNum<{n}, {paramstr}>; 2] {{ {one} }}");
    println(
        f"  fn offset_generator() -> [BigNum<{n}, {paramstr}>; 2] {{ {offset_generator_initial} }}",
    );
    println(
        f"  fn offset_generator_final() -> [BigNum<{n}, {paramstr}>; 2] {{ {offset_generator_final} }}",
    );
    println("");
}

#[test]
fn test_compute_and_print_offset_generators() {
    unsafe {
        /**
        compute_and_print_offset_generators::<BN254_Fq, BN254PartialCurveParams, _, _, 64>(
            3,
            "BN254_Fq_Params",
            "BN254PartialCurveParams",
            1,
        ); compute_and_print_offset_generators::<Secp224r1_Fq, Secp224r1_Params, _, _, 57>(
            2,
            "Secp224r1_Fq_Params",
            "Secp224r1_Params",
            1,
        );
        

        compute_and_print_offset_generators::<BrainpoolP192r1_Fq, BrainpoolP192r1_Params, _, _, 49>(
            2,
            "BrainpoolP192r1_Fq_Params",
            "BrainpoolP192r1_Params",
            1,
        );
        compute_and_print_offset_generators::<BrainpoolP192t1_Fq, BrainpoolP192t1_Params, _, _, 49>(
            2,
            "BrainpoolP192t1_Fq_Params",
            "BrainpoolP192t1_Params",
            1,
        );

        compute_and_print_offset_generators::<BrainpoolP224t1_Fq, BrainpoolP224t1_Params, _, _, 57>(
            2,
            "BrainpoolP224t1_Fq_Params",
            "BrainpoolP224t1_Params",
            1,
        ); 

        **/
        compute_and_print_offset_generators::<BrainpoolP224r1_Fq, BrainpoolP224r1_Params, _, _, 57>(
            2,
            "BrainpoolP224r1_Fq_Params",
            "BrainpoolP224r1_Params",
            1,
        );

        // compute_and_print_offset_generators::<P192_Fq, P192PartialCurveParams, _, _, 49>(2, "P192_Fq_Params", "P192PartialCurveParams", 1);
        // compute_and_print_offset_generators::<PallasBN, PallasPartialCurveParams, _, _, 64>(3, "Pallas_Fq_Params", "Pallas_Params", 1);
        // compute_and_print_offset_generators::<VestaBN, VestaPartialCurveParams, _, _, 64>(3, "Vesta_Fq_Params", "Vesta_Params", 1);
        // compute_and_print_offset_generators::<BLS377BN, BLS377PartialCurveParams, _, _, 64>(
        //     4,
        //     "BLS12_377_Fq_Params",
        //     "BLS12_377_Params",
        //     0x170b5d44300000000000000000000000
        // );
        // compute_and_print_offset_generators::<BLS381BN, BLS381PartialCurveParams, _, _, 64>(
        //     4,
        //     "BLS12_381_Fq_Params",
        //     "BLS12_381_Params",
        //     0x396C8C005555E1568C00AAAB0000AAAB
        // );
        // compute_and_print_offset_generators::<Mnt4BN, Mnt4PartialCurveParams, _, _, 189>(7, "MNT4_753_Fq_Params", "MNT4_753_Params", 1);
        // compute_and_print_offset_generators::<Mnt6BN, Mnt6PartialCurveParams, _, _, 189>(7, "MNT6_753_Fq_Params", "MNT6_753_Params", 1);
        // compute_and_print_offset_generators::<Secp256k1BN, Secp256k1PartialCurveParams, _, _, 65>(3, "Secp256k1_Fq_Params", "Secp256k1_Params", 1);
        // compute_and_print_offset_generators::<Secp256r1BN, Secp256r1PartialCurveParams, _, _, 65>(3, "Secp256r1_Fq_Params", "Secp256r1_Params", 1);
        // compute_and_print_offset_generators::<Secp384r1BN, Secp384r1PartialCurveParams, _, _, 97>(4, "Secp384r1_Fq_Params", "Secp384r1_Params", 1);
        // cofactor = 0x170b5d44300000000000000000000000 booooo
    }
}
