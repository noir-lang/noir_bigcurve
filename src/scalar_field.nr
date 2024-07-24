use dep::bignum::BigNum;
use dep::bignum::BigNumTrait;
use dep::bignum::RuntimeBigNumTrait;
use dep::bignum::BigNumParamsTrait;
use dep::bignum::runtime_bignum::BigNumParamsTrait as RuntimeBigNumParamsTrait;

/**
 * @brief ScalarField represents a scalar multiplier as a sequence of 4-bit slices
 * @details There is nuance to ScalarField, because twisted edwards curves generally have prime group orders that easily fit into a Field
 *          We can therefore obtain cheap conversions by simply summing up the bit slices and validate they equal the input scalar
 *          However...when converting arbitrary field elements (i.e. scalars that are multiples of a TE curve group order),
 *          we must perform additional checks when converting into 4-bit slices, as we must validate that the sum of the slices is smaller than the Field modulus (when evaluated over the integers)
 *          This is expensive and we would rather not do it! therefore ScalarField<N> is flexible.
 *          ScalarField<63> enables cheap bitslice converions for scalar multipliers that must be <2^{252}
 *          ScalarField<64> enables bitslice conversions for arbitrary field elements
 *
 *          N.B. ScalarField bit values are not constrained to be smaller than the TE curve group order.
 *          ScalarField is used when performing scalar multiplications, where all operations wrap modulo the curve order
 **/
struct ScalarField<let N: u32> {
    base4_slices: [u8; N],
    skew: bool
}

// 1, 2, 3, 4
unconstrained fn get_wnaf_slices<let N: u32>(x: Field) -> ([u8; N], bool) {

    let mut result: [u8; N] = [0; N];
    let mut nibbles = x.to_le_radix(16, N);

    let skew: bool = nibbles[0] & 1 == 0;
    nibbles[0] = nibbles[0] as u8 + (skew as u8);
    result[N-1] = (nibbles[0] + 15) / 2;
    for i in 1..N {
        let mut nibble: u8 = nibbles[i];
        result[N-1 - i] = (nibble + 15) / 2;
        if (nibble & 1 == 0) {
            result[N-1 - i] += 1;
            result[N - i] -= 8;
        }
    }

    (result, skew)
}

unconstrained fn get_wnaf_slices2<let N: u32, let M: u32>(x: [Field; M]) -> ([u8; N], bool) {

    let mut result: [u8; N] = [0; N];
    let mut nibbles: [[u8; 30]; M] = [[0; 30]; M];
    for i in 0..M {
        nibbles[i] = x[i].to_le_radix(16, 30).as_array();
    }

    let skew: bool = nibbles[0][0] & 1 == 0;
    nibbles[0][0] = nibbles[0][0] as u8 + (skew as u8);
    result[N-1] = (nibbles[0][0] + 15) / 2;

    for i in 1..N {
        let major_index = i / 30;
        let minor_index = i % 30;
        let mut nibble: u8 = nibbles[major_index][minor_index];
        result[N-1 - i] = (nibble + 15) / 2;
        if (nibble & 1 == 0) {
            result[N-1 - i] += 1;
            result[N - i] -= 8;
        }
    }

    (result, skew)
}

unconstrained fn from_wnaf_slices(x: [u8; 64], skew: bool) -> Field {
    let mut result: Field = 0;

    for i in 0..64 {
        result *= 16;
        result += (x[i] as Field) * 2 - 15;
    }
    result -= skew as Field;
    result
}


unconstrained fn get_modulus_slices() -> (Field, Field) {
    let bytes = std::field::modulus_be_bytes();
    let num_bytes = (std::field::modulus_num_bits() / 8) + ((std::field::modulus_num_bits() % 8 != 0) as u64);
    let mut lo: Field = 0;
    let mut hi: Field = 0;
    for i in 0..(num_bytes / 2) {
        hi *= 256;
        hi += bytes[i] as Field;
        lo *= 256;
        lo += bytes[i + (num_bytes/2)] as Field;
    }
    if (num_bytes & 1 == 1) {
        lo *= 256;
        lo += bytes[num_bytes - 1] as Field;
    }
    (lo, hi)
}

unconstrained fn get_borrow_flag(lhs_lo: Field, rhs_lo: Field) -> bool {
    lhs_lo.lt(rhs_lo + 1)
}

impl<let N: u32> std::convert::From<Field> for ScalarField<N> {

    /**
     * @brief construct from a field element
     * @details if N >= 64 we perform extra checks to ensure the slice decomposition represents the same integral value as the input
     *          (e.g. sum of slices != x + modulus)
     **/
    fn from(x: Field) -> Self {
        let mut result: Self = ScalarField { base4_slices: [0; N], skew: false };
        let (slices, skew): ([u8; N], bool) = get_wnaf_slices(x);
        result.base4_slices = slices;
        result.skew = skew;
        if (N < 64) {
            let mut acc: Field = (slices[0] as Field) * 2 - 15;
            for i in 1..N {
                acc *= 16;
                acc += (slices[i] as Field) * 2 - 15;
            }
            assert(acc - skew as Field == x);
        }
        else
        {
            // TODO: if num bits = 64, validate in sum of the bits is smaller than the Field modulus
            let mut lo: Field = slices[(N/2)] as Field * 2 - 15;
            let mut hi: Field = slices[0] as Field * 2 - 15;
            let mut borrow_shift = 1;
            for i in 1..(N/2) {
                borrow_shift *= 16;
                lo *= 16;
                lo += (slices[(N/2) + i] as Field) * 2 - 15;
                hi *= 16;
                hi += (slices[i] as Field) * 2 - 15;
            }
            if ((N & 1) == 1)
            {
                borrow_shift *= 16;
                lo *= 16;
                lo += (slices[N-1] as Field) * 2 - 15;
            }
// 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593efffffff
                                // 0x2833e84879b9709143e1f593f0000001
                                // 0x8833e84879b9709143e1f593efffffff
            lo -= skew as Field;
            // Validate that the integer represented by (lo, hi) is smaller than the integer represented by (plo, phi)
            let (plo, phi) = get_modulus_slices();
            let borrow = get_borrow_flag(plo, lo) as Field;
            let rlo = plo - lo + borrow * borrow_shift - 1; // -1 because we are checking a strict <, not <=
            let rhi = phi - hi - borrow;
            let offset = (N & 1 == 1) as u32;
            let hibits = (N / 2) * 4;
            let lobits = hibits + offset * 4 + 1; // 1 extra bit to account for borrow
            // 0x013833e84879b9709143e1f593f0000000
            rlo.assert_max_bit_size(lobits as u32);
            rhi.assert_max_bit_size(hibits as u32);
        }
        for i in 0..N {
            (result.base4_slices[i] as Field).assert_max_bit_size(4);
        }
        result
    }
}

impl<let N: u32> std::convert::Into<Field> for ScalarField<N> {
    /**
     * @brief construct from tuple of field elements
     * @details use this method instead of `new` if you know x/y is on the curve
     **/
    fn into(self: Self) -> Field {
        let mut acc: Field = 0;
        for i in 0..N {
            acc = acc * 16;
            acc = acc + (self.base4_slices[i] as Field) * 2 - 15;
        }
        acc -= self.skew as Field;
        acc
    }
}

impl<let N: u32> ScalarField<N> {

    fn zero() -> Self {
        let mut result: Self = ScalarField{ base4_slices: [0; N], skew: true };
        
        result.base4_slices[N-1] = 8; // 8 = numeric value of 1, 0 = numeric value of -15
        result
    }

    fn conditional_select(lhs: Self, rhs: Self, predicate: bool) -> Self {
        let mut result = rhs;
        if (predicate)
        {
            result = lhs;
        }
        result
    }

    // Note: I can't propagate ModulusBits or NumLimbs from a generic that satisfies BigNumTrait due to bugs, so we have to pass NumLimbs and Params in directly. disgusting!
    fn from_bignum<let NumLimbs: u64, Params>(x: BigNum<NumLimbs, Params>) -> Self where Params: BigNumParamsTrait<NumLimbs> + RuntimeBigNumParamsTrait<NumLimbs>  {
        x.validate_in_field();
        let mut (slices, skew): ([u8; N], bool) = get_wnaf_slices2(x.limbs);

        // TODO: NONE OF THIS IS CONSTRAINED YET. FIX!
        Self{ base4_slices: slices, skew }
    }

   fn into_bignum<BigNum>(self) -> BigNum where BigNum: BigNumTrait {
        let mut result = BigNum::new();
        let mut count: u64 = 0;
        {
            let mut acc = 0;
                let mut last_bits: u64 = result.modulus_bits() % 120;
                if (last_bits == 0) { last_bits = 120; }
                let mut last_nibbles = (last_bits / 4) + (last_bits % 4 != 0) as u64;
                for _ in 0..last_nibbles {
                    acc = acc * 16;
                    acc = acc + (self.base4_slices[count] as Field) * 2 - 15;
                    count = count + 1;
                }
            result.set_limb(result.num_limbs() - 1, acc);
        }
        for i in 1..result.num_limbs() {
            let mut acc: Field = 0;
            for _ in 0..30 {
                acc = acc * 16;
                acc = acc + (self.base4_slices[count] as Field) * 2 - 15;
                count = count + 1;
            }
            if acc.lt(0x1000000000000000000000000000000) == false {
                acc += 0x1000000000000000000000000000000;
                result.set_limb(result.num_limbs() - i, result.get_limb(result.num_limbs() - i) - 1);
            }
            result.set_limb(result.num_limbs() - 1 - i, acc);
        }
        result.set_limb(0, result.get_limb(0) - self.skew as Field);
        result
    }
    
    fn new() -> Self {
        Self { base4_slices: [0; N], skew: false }
    }
    fn get(self, idx: u64) -> u8 {
        self.base4_slices[idx]
    }
}

