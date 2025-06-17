use crate::BigCurveTrait;
use crate::curve_jac::CurveJ;
use crate::CurveParamsTrait;
use crate::curves::bn254::BN254Params;

use crate::curves::bn254::BN254;
use bignum::BigNum;
use bignum::BN254_Fq;
unconstrained fn compute_offset_generators<Fq, CurveParams, let NScalarSlices: u32, BigCurve: BigCurveTrait<Fq>>(
    cofactor: Field,
) -> ([Fq; 2], [Fq; 2])
where
    Fq: BigNum,
    CurveParams: CurveParamsTrait<Fq>,
    BigCurve: BigCurveTrait<Fq>,
{
    let seed: [u8; 25] = "bigcurve offset generator".as_bytes();

    // we only need well-defined parameters for a and b, for hash_to_curve to work
    // (no offset generators needed)
    let g = <BigCurve as BigCurveTrait<Fq>>::hash_to_curve(seed);

    let g_init: CurveJ<Fq, CurveParams> =
        CurveJ { x: g.get_x(), y: g.get_y(), z: Fq::one(), is_infinity: false };
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

unconstrained fn compute_and_print_offset_generators<Fq, CurveParams, let K: u32, let J: u32, let NScalarSlices: u32, BigCurve: BigCurveTrait<Fq>>(
    bignumstr: str<K>,
    curvestr: str<J>,
    cofactor: Field,
)
where
    Fq: BigNum,
    CurveParams: CurveParamsTrait<Fq>,
    BigCurve: BigCurveTrait<Fq>,
{
    let a = CurveParams::a();
    let b = CurveParams::b();
    let one = CurveParams::one();

    let input = <BigCurve as BigCurveTrait<Fq>>::one();
    <BigCurve as BigCurveTrait<Fq>>::validate_on_curve(input);

    let (offset_generator_initial, offset_generator_final) =
        compute_offset_generators::<Fq, CurveParams, NScalarSlices, BigCurve>(cofactor);

    println(f"pub struct {curvestr} {{}}");
    println(f"impl CurveParamsTrait<{bignumstr}> for {curvestr} {{");

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
        let _ = <BN254 as BigCurveTrait<BN254_Fq>>::one();
        compute_and_print_offset_generators::<BN254_Fq, BN254Params, _, _, 64, BN254>(
            "BN254_Fq",
            "BN254Params",
            1,
        );
        // compute_and_print_offset_generators::<PallasBN, PallasPartialCurveParams, _, _, 64>("Pallas_Fq", "Pallas_Params", 1);
        // compute_and_print_offset_generators::<VestaBN, VestaPartialCurveParams, _, _, 64>("Vesta_Fq", "Vesta_Params", 1);
        // compute_and_print_offset_generators::<BLS377BN, BLS377PartialCurveParams, _, _, 64>(
        //     "BLS12_377_Fq"
        //     "BLS12_377_Params",
        //     0x170b5d44300000000000000000000000
        // );
        // compute_and_print_offset_generators::<BLS381BN, BLS381PartialCurveParams, _, _, 64>(
        //     "BLS12_381_Fq",
        //     "BLS12_381_Params",
        //     0x396C8C005555E1568C00AAAB0000AAAB
        // );
        // compute_and_print_offset_generators::<Mnt4BN, Mnt4PartialCurveParams, _, _, 189>("MNT4_753_Fq", "MNT4_753_Params", 1);
        // compute_and_print_offset_generators::<Mnt6BN, Mnt6PartialCurveParams, _, _, 189>("MNT6_753_Fq", "MNT6_753_Params", 1);
        // compute_and_print_offset_generators::<Secp256k1BN, Secp256k1PartialCurveParams, _, _, 65>("Secp256k1_Fq", "Secp256k1_Params", 1);
        // compute_and_print_offset_generators::<Secp256r1BN, Secp256r1PartialCurveParams, _, _, 65>("Secp256r1_Fq", "Secp256r1_Params", 1);
        // compute_and_print_offset_generators::<Secp384r1BN, Secp384r1PartialCurveParams, _, _, 97>("Secp384r1_Fq", "Secp384r1_Params", 1);
        // cofactor = 0x170b5d44300000000000000000000000 booooo
    }
}

pub(crate) unconstrained fn verify_offset_generators<Fq, CurveParams, BigCurve: BigCurveTrait<Fq>>(
    cofactor: Field,
)
where
    Fq: BigNum,
    CurveParams: CurveParamsTrait<Fq>,
    BigCurve: BigCurveTrait<Fq>,
{
    // For each curve, compute the offset generators and verify they match the ones in the curve parameters
    let seed: [u8; 25] = "bigcurve offset generator".as_bytes();

    // we only need well-defined parameters for a and b, for hash_to_curve to work
    // (no offset generators needed)
    let g = <BigCurve as BigCurveTrait<Fq>>::hash_to_curve(seed);

    let g_init: CurveJ<Fq, CurveParams> =
        CurveJ { x: g.get_x(), y: g.get_y(), z: Fq::one(), is_infinity: false };
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
    let expected_initial = <BigCurve as BigCurveTrait<Fq>>::offset_generator();
    println(f"expected_initial: {expected_initial}");
    println(f"computed_initial: {computed_initial}");
    assert_eq(computed_initial[0], expected_initial.get_x(), "Initial offset generator x mismatch");
    assert_eq(computed_initial[1], expected_initial.get_y(), "Initial offset generator y mismatch");
}
