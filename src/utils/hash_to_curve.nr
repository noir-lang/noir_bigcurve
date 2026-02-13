use dep::bignum::BigNum;
use dep::bignum::bignum::evaluate_quadratic_expression;

unconstrained fn __hash_to_curve_inner<Fq>(
    seedbase: Field,
    seed_counter: Field,
    a: Fq,
    b: Fq,
) -> (Fq, Fq, Field)
where
    Fq: BigNum,
{
    let seedhash: Field = poseidon::poseidon2::Poseidon2::hash([seedbase, seed_counter], 2);
    // TODO: assert in field?
    let seedhash_bytes: [u8; 32] = seedhash.to_le_bytes();

    let x = Fq::derive_from_seed(seedhash_bytes);

    let yy = x * x * x + a * x + b;
    yy.validate_in_field();
    yy.validate_in_range();
    x.validate_in_field();
    x.validate_in_range();
    let y = yy.__sqrt();

    let y_val = y.unwrap_unchecked();
    let parity_flag = (seedhash_bytes[0] & 1) == 1;
    let y_parity = (y_val.get_limb(0) & 1) == 1;
    let y_out = if (y_parity == parity_flag) {
        y_val
    } else {
        y_val.__neg()
    };
    let yy_reconstructed = y_out * y_out;

    if (yy_reconstructed == yy) & (y.is_some()) {
        y_out.validate_in_field();
        y_out.validate_in_range();
        (x, y_out, seed_counter)
    } else {
        __hash_to_curve_inner(seedbase, seed_counter + 1, a, b)
    }
}

unconstrained fn __hash_to_curve_witgen<Fq, let SeedBytes: u32>(
    seed: [u8; SeedBytes],
    a: Fq,
    b: Fq,
) -> (Fq, Fq, Field)
where
    Fq: BigNum,
{
    let hashed_seed = poseidon_hash_bytes(seed);
    __hash_to_curve_inner(hashed_seed, 0, a, b)
}

fn poseidon_hash_bytes<let SeedBytes: u32>(seed: [u8; SeedBytes]) -> Field {
    // Pack seed bytes into Fields.
    // For the seed of length M, we construct a rolling_hash_field of size ceil(M / 31).
    // i.e.  31 bytes per Field
    // NOTE: the Fields produced are 248 bits in size
    let mut packed_seed: [Field; (SeedBytes + 30) / 31] = [0; (SeedBytes + 30) / 31];
    let mut seed_ptr: u32 = 0;
    for i in 0..(SeedBytes + 30) / 31 {
        let mut packed: Field = 0;
        for _ in 0..31 {
            if (seed_ptr < SeedBytes) {
                packed *= 256;
                packed += seed[seed_ptr] as Field;
                seed_ptr += 1;
            }
        }
        packed_seed[i] = packed;
    }
    let hashed_seed: Field =
        poseidon::poseidon2::Poseidon2::hash(packed_seed, (SeedBytes + 30) / 31);
    hashed_seed
}

pub fn hash_to_curve<Fq, let SeedBytes: u32>(seed: [u8; SeedBytes], a: Fq, b: Fq) -> (Fq, Fq)
where
    Fq: BigNum,
{
    let (_, y, salt) = unsafe { __hash_to_curve_witgen(seed, a, b) };

    let outer_hash: Field = poseidon_hash_bytes(seed);
    let inner_hash = poseidon::poseidon2::Poseidon2::hash([outer_hash, salt], 2);

    // TODO do we need to assert is in field?; I think we do?
    let inner_hash: [u8; 32] = inner_hash.to_le_bytes();
    let x = Fq::derive_from_seed(inner_hash);
    let yy = x * x * x + a * x + b;

    // y * y - yy = 0 (mod MOD)
    evaluate_quadratic_expression([[y]], [[false]], [[y]], [[false]], [yy], [true]);

    // bind the parity
    // We .validate_in_field later, so the only possible mismatch can be when y == 0 (MOD is allowed in this case)
    assert((y.get_limb(0) & 1) as Field == (inner_hash[0] & 1) as Field);

    x.validate_in_field();
    x.validate_in_range();
    y.validate_in_field();
    y.validate_in_range();
    (x, y)
}
