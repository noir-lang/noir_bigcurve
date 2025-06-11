use crate::{BigCurve, BigCurveTrait};
use crate::curve_jac::CurveJ;
use crate::CurveParamsTrait;
use crate::curves::bn254::BN254Params;
// use crate::curves::bls12_377::BLS12_377_Params;
// use crate::curves::bls12_381::BLS12_381_Params;
// use crate::curves::mnt4_753::MNT4_753_Params;
// use crate::curves::mnt6_753::MNT6_753_Params;
// use crate::curves::pallas::Pallas_Params;
// use crate::curves::secp256k1::Secp256k1_Params;
// use crate::curves::secp256r1::Secp256r1_Params;
// use crate::curves::secp384r1::Secp384r1_Params;
// use crate::curves::vesta::Vesta_Params;

use bignum::BigNum;
// use bignum::BLS12_377_Fq;
// use bignum::BLS12_381_Fq;
use bignum::BN254_Fq;
// use bignum::MNT4_753_Fq;
// use bignum::MNT6_753_Fq;
// use bignum::Pallas_Fq;
// use bignum::Secp256k1_Fq;
// use bignum::Secp256r1_Fq;
// use bignum::Secp384r1_Fq;
// use bignum::Vesta_Fq;

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
    println("}}");
}

unconstrained fn verify_offset_generators<Fq, Curve>(cofactor: Field)
where
    Fq: BigNum,
    Curve: CurveParamsTrait<Fq>,
{
    // For each curve, compute the offset generators and verify they match the ones in the curve parameters
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
    let mut genz = gen.z;
    genz = genz.__invmod();
    let zz = genz.__mul(genz);
    let zzz = zz.__mul(genz);
    let computed_initial = [gen.x.__mul(zz), gen.y.__mul(zzz)];
    // Verify against the values in the curve parameters
    let expected_initial = Curve::offset_generator();
    println(f"expected_initial: {expected_initial}");
    println(f"computed_initial: {computed_initial}");
    assert_eq(computed_initial[0], expected_initial[0], "Initial offset generator x mismatch");
    assert_eq(computed_initial[1], expected_initial[1], "Initial offset generator y mismatch");
}

#[test]
fn test_compute_and_print_offset_generators() {
    unsafe {
        compute_and_print_offset_generators::<BN254_Fq, BN254Params, _, _, 64>(
            3,
            "BN254_Fq_Params",
            "BN254Params",
            1,
        );
        // compute_and_print_offset_generators::<Pallas_Fq, Pallas_Params, _, _, 64>(3, "Pallas_Fq_Params", "Pallas_Params", 1);
        // compute_and_print_offset_generators::<Vesta_Fq, Vesta_Params, _, _, 64>(3, "Vesta_Fq_Params", "Vesta_Params", 1);
        // compute_and_print_offset_generators::<BLS12_377_Fq, BLS12_377_Params, _, _, 64>(
        //     4,
        //     "BLS12_377_Fq_Params",
        //     "BLS12_377_Params",
        //     0x170b5d44300000000000000000000000
        // );
        // compute_and_print_offset_generators::<BLS12_381_Fq, BLS12_381_Params, _, _, 64>(
        //     4,
        //     "BLS12_381_Fq_Params",
        //     "BLS12_381_Params",
        //     0x396C8C005555E1568C00AAAB0000AAAB
        // );
        // compute_and_print_offset_generators::<MNT4_753_Fq, MNT4_753_Params, _, _, 189>(7, "MNT4_753_Fq_Params", "MNT4_753_Params", 1);
        // compute_and_print_offset_generators::<MNT6_753_Fq, MNT6_753_Params, _, _, 189>(7, "MNT6_753_Fq_Params", "MNT6_753_Params", 1);
        // compute_and_print_offset_generators::<Secp256k1_Fq, Secp256k1_Params, _, _, 65>(3, "Secp256k1_Fq_Params", "Secp256k1_Params", 1);
        // compute_and_print_offset_generators::<Secp256r1_Fq, Secp256r1_Params, _, _, 65>(3, "Secp256r1_Fq_Params", "Secp256r1_Params", 1);
        // compute_and_print_offset_generators::<Secp384r1_Fq, Secp384r1_Params, _, _, 97>(4, "Secp384r1_Fq_Params", "Secp384r1_Params", 1);
        // cofactor = 0x170b5d44300000000000000000000000 booooo
    }
}

#[test]
unconstrained fn test_verify_offset_generators() {
    // BN254 cofactor is 1
    verify_offset_generators::<BN254_Fq, BN254Params>(1);
    // BLS12-377 cofactor is 0x170b5d44300000000000000000000000
    // verify_offset_generators::<BLS12_377_Fq, BLS12_377_Params>(0x170b5d44300000000000000000000000);
    // BLS12-381 cofactor is 0x396C8C005555E1568C00AAAB0000AAAB
    // verify_offset_generators::<BLS12_381_Fq, BLS12_381_Params>(0x396C8C005555E1568C00AAAB0000AAAB);
    // MNT4-753 cofactor is 1
    // verify_offset_generators::<MNT4_753_Fq, MNT4_753_Params>(1);
    // MNT6-753 cofactor is 1
    // verify_offset_generators::<MNT6_753_Fq, MNT6_753_Params>(1);
    // Pallas cofactor is 1
    // verify_offset_generators::<Pallas_Fq, Pallas_Params>(1);
    // Secp256k1 cofactor is 1
    // verify_offset_generators::<Secp256k1_Fq, Secp256k1_Params>(1);
    // Secp256r1 cofactor is 1
    // verify_offset_generators::<Secp256r1_Fq, Secp256r1_Params>(1);
    // Secp384r1 cofactor is 1
    // verify_offset_generators::<Secp384r1_Fq, Secp384r1_Params>(1);
    // Vesta cofactor is 1
    // verify_offset_generators::<Vesta_Fq, Vesta_Params>(1);
}
