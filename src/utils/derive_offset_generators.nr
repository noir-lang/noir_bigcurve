use crate::BigCurve;
use crate::curve_jac::CurveJ;

use crate::curves::bn254::BN254;
use bignum::BigNum;
use bignum::BN254_Fq;
unconstrained fn compute_offset_generators<Fq, let NScalarSlices: u32, Curve>(
    cofactor: Field,
) -> ([Fq; 2], [Fq; 2])
where
    Fq: BigNum,
    Curve: BigCurve<Fq>,
{
    let seed: [u8; 25] = "bigcurve offset generator".as_bytes();

    // we only need well-defined parameters for a and b, for hash_to_curve to work
    // (no offset generators needed)
    let g: Curve = Curve::hash_to_curve(seed);

    let g_init = CurveJ::<Fq, Curve>::from(g);
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

    (offset_generator_initial, offset_generator_final)
}

unconstrained fn compute_and_print_offset_generators<Fq, let K: u32, let J: u32, let NScalarSlices: u32, Curve>(
    bignumstr: str<K>,
    curvestr: str<J>,
    cofactor: Field,
)
where
    Fq: BigNum,
    Curve: BigCurve<Fq>,
{
    let a: Fq = Curve::a();
    let b: Fq = Curve::b();
    let one: Curve = Curve::one();

    let input = Curve::one();
    input.validate_on_curve();

    let (offset_generator_initial, offset_generator_final) =
        compute_offset_generators::<Fq, NScalarSlices, Curve>(cofactor);

    println(f"pub struct {curvestr} {{}}");

    println(f"  fn a() -> {bignumstr} {{ {a} }}");
    println(f"  fn b() -> {bignumstr} {{ {b} }}");
    println(f"  fn one() -> [{bignumstr}; 2] {{ {one} }}");
    println(
        f"  fn offset_generator() -> [{bignumstr}; 2] {{ {offset_generator_initial} }}",
    );
    println(
        f"  fn offset_generator_final() -> [{bignumstr}; 2] {{ {offset_generator_final} }}",
    );
    println("}}");
}

#[test]
fn test_compute_and_print_offset_generators() {
    unsafe {
        let _ = <BN254 as BigCurve<BN254_Fq>>::one();
        compute_and_print_offset_generators::<BN254_Fq, _, _, 64, BN254>("BN254_Fq", "BN254", 1);
        // compute_and_print_offset_generators::<PallasBN, _, _, 64>("Pallas_Fq", "Pallas", 1);
        // compute_and_print_offset_generators::<VestaBN, _, _, 64>("Vesta_Fq", "Vesta", 1);
        // compute_and_print_offset_generators::<BLS377BN, _, _, 64>(
        //     "BLS12_377_Fq",
        //     "BLS12_377",
        //     0x170b5d44300000000000000000000000
        // );
        // compute_and_print_offset_generators::<BLS381BN, _, _, 64>(
        //     "BLS12_381_Fq",
        //     "BLS12_381",
        //     0x396C8C005555E1568C00AAAB0000AAAB
        // );
        // compute_and_print_offset_generators::<Mnt4BN, _, _, 189>("MNT4_753_Fq", "MNT4_753", 1);
        // compute_and_print_offset_generators::<Mnt6BN, _, _, 189>("MNT6_753_Fq", "MNT6_753", 1);
        // compute_and_print_offset_generators::<Secp256k1BN, _, _, 65>("Secp256k1_Fq", "Secp256k1", 1);
        // compute_and_print_offset_generators::<Secp256r1BN, _, _, 65>("Secp256r1_Fq", "Secp256r1", 1);
        // compute_and_print_offset_generators::<Secp384r1BN, _, _, 97>("Secp384r1_Fq", "Secp384r1", 1);
        // cofactor = 0x170b5d44300000000000000000000000 booooo
    }
}

pub(crate) unconstrained fn verify_offset_generators<Fq, Curve>(cofactor: Field)
where
    Fq: BigNum,
    Curve: BigCurve<Fq>,
{
    // For each curve, compute the offset generators and verify they match the ones in the curve parameters
    let seed: [u8; 25] = "bigcurve offset generator".as_bytes();

    // we only need well-defined parameters for a and b, for hash_to_curve to work
    // (no offset generators needed)
    let g: Curve = Curve::hash_to_curve(seed);

    let g_init = CurveJ::<Fq, Curve>::from(g);
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
    assert_eq(computed_initial[0], expected_initial.x(), "Initial offset generator x mismatch");
    assert_eq(computed_initial[1], expected_initial.y(), "Initial offset generator y mismatch");
}
