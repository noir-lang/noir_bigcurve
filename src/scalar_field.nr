use bignum::BigNum;

/// Represents a scalar multiplier as a sequence of 4-bit slices.
///
/// # Overview
/// `ScalarField` efficiently encodes scalars for twisted Edwards curve operations. Since these curves
/// typically have prime group orders that fit within a field element, scalars can often be reconstructed
/// from their 4-bit slices by summing the slices and verifying equality with the original scalar.
///
/// For arbitrary field elements (scalars that may be multiples of the curve's group order), additional
/// validation is required. In these cases, the sum of the 4-bit slices, interpreted as an integer,
/// must be less than the field modulus. This check is computationally expensive and avoided when possible.
///
/// The `ScalarField<N>` type is flexible:
/// - `ScalarField<63>`: Efficient bitslice conversions for scalars less than 2^252.
/// - `ScalarField<64>`: Supports bitslice conversions for arbitrary field elements.
///
/// **Note:** The bit values in `ScalarField` are not constrained to be less than the curve's group order.
/// This type is intended for use in scalar multiplication, where all operations are performed modulo the
/// curve order.
pub struct ScalarField<let N: u32> {
    pub(crate) base4_slices: [u8; N],
    pub(crate) skew: bool,
}

// 1, 2, 3, 4
unconstrained fn get_wnaf_slices<let N: u32>(x: Field) -> ScalarField<N> {
    let mut base4_slices: [u8; N] = [0; N];
    let mut nibbles = x.to_le_radix::<N>(16);

    let skew: bool = nibbles[0] & 1 == 0;
    nibbles[0] = nibbles[0] as u8 + (skew as u8);
    base4_slices[N - 1] = (nibbles[0] + 15) / 2;
    for i in 1..N {
        let mut nibble: u8 = nibbles[i];
        base4_slices[N - 1 - i] = (nibble + 15) / 2;
        if (nibble & 1 == 0) {
            base4_slices[N - 1 - i] += 1;
            base4_slices[N - i] -= 8;
        }
    }

    ScalarField { base4_slices, skew }
}

unconstrained fn get_wnaf_slices2<let N: u32, B>(x: B) -> ScalarField<N>
where
    B: BigNum,
{
    let mut base4_slices: [u8; N] = [0; N];
    let mut nibbles: [[u8; 30]; (N / 30) + 1] = [[0; 30]; (N / 30) + 1];
    let x: [u128; _] = x.get_limbs();
    for i in 0..x.len() {
        nibbles[i] = (x[i] as Field).to_le_radix::<30>(16);
    }

    let skew: bool = nibbles[0][0] & 1 == 0;
    nibbles[0][0] = nibbles[0][0] as u8 + (skew as u8);
    base4_slices[N - 1] = (nibbles[0][0] + 15) / 2;

    for i in 1..N {
        let major_index = i / 30;
        let minor_index = i % 30;
        let mut nibble: u8 = nibbles[major_index][minor_index];
        base4_slices[N - 1 - i] = (nibble + 15) / 2;
        if (nibble & 1 == 0) {
            base4_slices[N - 1 - i] += 1;
            base4_slices[N - i] -= 8;
        }
    }

    ScalarField { base4_slices, skew }
}

unconstrained fn get_modulus_slices<let N: u32>() -> [u8; N] {
    let mut expected_slices: [u8; N] = [0; N];

    if N == 64 {
        let slice: [u8; 64] = [
            9, 8, 3, 2, 2, 7, 3, 9, 7, 0, 9, 8, 13, 0, 1, 4, 13, 12, 2, 8, 2, 2, 13, 11, 4, 0, 12,
            0, 10, 12, 2, 14, 9, 4, 1, 9, 15, 4, 2, 4, 3, 12, 13, 12, 11, 8, 4, 8, 10, 1, 15, 0, 15,
            10, 12, 9, 15, 8, 0, 0, 0, 0, 0, 0,
        ];
        for i in 0..N {
            expected_slices[i] = slice[i];
        }
    } else if N == 65 {
        let slice: [u8; 65] = [
            8, 1, 8, 3, 2, 2, 7, 3, 9, 7, 0, 9, 8, 13, 0, 1, 4, 13, 12, 2, 8, 2, 2, 13, 11, 4, 0,
            12, 0, 10, 12, 2, 14, 9, 4, 1, 9, 15, 4, 2, 4, 3, 12, 13, 12, 11, 8, 4, 8, 10, 1, 15, 0,
            15, 10, 12, 9, 15, 8, 0, 0, 0, 0, 0, 0,
        ];
        for i in 0..N {
            expected_slices[i] = slice[i];
        }
    } else if N > 65 {
        // For N > 65, we need to insert zeros at the beginning
        let num_zeros = N - 65;
        expected_slices[0] = 8;
        for i in 1..num_zeros + 1 {
            expected_slices[i] = 0;
        }
        let slice: [u8; 65] = [
            8, 1, 8, 3, 2, 2, 7, 3, 9, 7, 0, 9, 8, 13, 0, 1, 4, 13, 12, 2, 8, 2, 2, 13, 11, 4, 0,
            12, 0, 10, 12, 2, 14, 9, 4, 1, 9, 15, 4, 2, 4, 3, 12, 13, 12, 11, 8, 4, 8, 10, 1, 15, 0,
            15, 10, 12, 9, 15, 8, 0, 0, 0, 0, 0, 0,
        ];
        for i in num_zeros + 1..N {
            expected_slices[i] = slice[i - num_zeros];
        }
    }
    expected_slices
}

unconstrained fn compare_scalar_field_to_bignum<let N: u32>(result: ScalarField<N>) {
    let expected_slices: [u8; N] = unsafe { get_modulus_slices::<N>() };

    // Lexicographic comparison: stop when we find a strictly smaller number
    let mut should_continue: bool = true;
    for i in 0..N {
        if should_continue {
            if result.base4_slices[i] < expected_slices[i] {
                // Found a strictly smaller number, we can stop - this is valid
                should_continue = false;
            } else if result.base4_slices[i] > expected_slices[i] {
                // Found a strictly larger number, this is invalid
                assert(false);
            }
            // If equal, continue to the next element (should_continue remains true)
        }
    }
}

impl<let N: u32> std::convert::From<Field> for ScalarField<N> {

    /// Constructs an instance from a field element.
    fn from(input: Field) -> Self {
        let result = unsafe { get_wnaf_slices(input) };

        if std::runtime::is_unconstrained() {
            // Enforce that limbs are all 4 bits.
            for i in 0..N {
                (result.base4_slices[i] as Field).assert_max_bit_size::<4>();
            }

            // Enforce consistency with `input`.
            let reconstructed_input: Field = result.into();
            assert_eq(reconstructed_input, input);
        }
        if N >= 64 {
            unsafe { compare_scalar_field_to_bignum(result) };
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
        // TODO: This is susceptible to overflow when N is large!
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
    pub fn len(_: Self) -> u32 {
        N
    }

    pub fn zero() -> Self {
        let mut result: Self = ScalarField { base4_slices: [0; N], skew: true };
        result.base4_slices[0] = 8; // 8 = numeric value of 1, 0 = numeric value of -15
        result
    }

    // Note: I can't propagate ModulusBits or NumLimbs from a generic that satisfies BigNum due to bugs, so we have to pass NumLimbs and Params in directly. disgusting!
    pub fn from_bignum<B>(x: B) -> Self
    where
        B: BigNum,
    {
        x.validate_in_field();
        let result = unsafe { get_wnaf_slices2(x) };
        // TODO: NONE OF THIS IS CONSTRAINED YET. FIX!
        result
    }

    pub fn into_bignum<B>(self) -> B
    where
        B: BigNum,
    {
        let mut result = B::zero();
        let mut count: u32 = 0;
        {
            let mut acc: u128 = 0;
            let mut last_bits = (result.modulus_bits() % 120) as u64;
            if (last_bits == 0) {
                last_bits = 120;
            }
            let mut last_nibbles = (last_bits / 4) + (last_bits % 4 != 0) as u64;
            for _ in 0..last_nibbles {
                acc = acc * 16;
                acc = acc + (self.base4_slices[count] as u128) * 2 - 15;
                count = count + 1;
            }
            result.set_limb(result.num_limbs() - 1, acc);
        }
        for i in 1..result.num_limbs() {
            let mut acc: u128 = 0;
            for _ in 0..30 {
                acc = acc * 16;
                acc = acc + (self.base4_slices[count] as u128) * 2 - 15;
                count = count + 1;
            }
            if acc >= 0x1000000000000000000000000000000 {
                acc += 0x1000000000000000000000000000000;
                result.set_limb(
                    result.num_limbs() - i,
                    result.get_limb((result.num_limbs() - i)) - 1,
                );
            }
            result.set_limb(result.num_limbs() - 1 - i, acc);
        }
        result.set_limb(0, result.get_limb(0) - self.skew as u128);
        result
    }

    pub fn new() -> Self {
        Self { base4_slices: [0; N], skew: false }
    }

    pub fn get(self, idx: u32) -> u8 {
        self.base4_slices[idx]
    }
}

mod tests {
    use crate::scalar_field::get_modulus_slices;
    #[test]
    fn test_get_modulus_slices() {
        let modulus_slices: [u8; 64] = unsafe { get_modulus_slices::<64>() };
        assert(
            modulus_slices
                == [
                    9, 8, 3, 2, 2, 7, 3, 9, 7, 0, 9, 8, 13, 0, 1, 4, 13, 12, 2, 8, 2, 2, 13, 11, 4,
                    0, 12, 0, 10, 12, 2, 14, 9, 4, 1, 9, 15, 4, 2, 4, 3, 12, 13, 12, 11, 8, 4, 8,
                    10, 1, 15, 0, 15, 10, 12, 9, 15, 8, 0, 0, 0, 0, 0, 0,
                ],
        );
        let modulus_slices2: [u8; 65] = unsafe { get_modulus_slices::<65>() };
        assert(
            modulus_slices2
                == [
                    8, 1, 8, 3, 2, 2, 7, 3, 9, 7, 0, 9, 8, 13, 0, 1, 4, 13, 12, 2, 8, 2, 2, 13, 11,
                    4, 0, 12, 0, 10, 12, 2, 14, 9, 4, 1, 9, 15, 4, 2, 4, 3, 12, 13, 12, 11, 8, 4, 8,
                    10, 1, 15, 0, 15, 10, 12, 9, 15, 8, 0, 0, 0, 0, 0, 0,
                ],
        );
        let modulus_slices3: [u8; 68] = unsafe { get_modulus_slices::<68>() };
        assert(
            modulus_slices3
                == [
                    8, 0, 0, 0, 1, 8, 3, 2, 2, 7, 3, 9, 7, 0, 9, 8, 13, 0, 1, 4, 13, 12, 2, 8, 2, 2,
                    13, 11, 4, 0, 12, 0, 10, 12, 2, 14, 9, 4, 1, 9, 15, 4, 2, 4, 3, 12, 13, 12, 11,
                    8, 4, 8, 10, 1, 15, 0, 15, 10, 12, 9, 15, 8, 0, 0, 0, 0, 0, 0,
                ],
        );
    }

}
