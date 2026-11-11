# noir_bigcurve

> [!WARNING]
> **This library is experimental software. It has not been fully audited and is not guaranteed to be secure. Expect bugs!**
>
> Bugs in this library can lead to under-constrained circuits, allowing invalid proofs to be accepted. Do not rely on it to protect real assets or sensitive data without your own independent review.

An optimized elliptic curve library for Noir.

`noir_bigcurve` provides elliptic curve arithmetic over arbitrary prime fields using the Weierstrass form:

y^2 = x^3 + a*x + b (mod p)

It builds on noir-bignum for arbitrary-precision field arithmetic.

`BigCurve` instances are parameterized by a struct implementing `BigCurveParams`.

## Overview

This library implements elliptic curve operations over arbitrary-precision prime fields.

- Uses noir-bignum for field arithmetic
- Minimizes modular reductions for efficiency
- Supports both constrained and unconstrained execution paths
- Provides runtime lookup tables for faster scalar multiplication

Predefined curves are included, and tools are provided to define custom curves.

## Getting Started

### Using a predefined curve

```rust
use ::bigcurve::BLS12_377;
```

See:
- `src/lib.nr` for exported curves
- `src/curves/` for parameter definitions

### Defining a custom curve

If your curve is not included:

1. Define or import a parameter set (see noir-bignum)
2. Define the corresponding big number type
3. Implement `BigCurveParams`

Examples are available in `src/curves/`.

## Important: Constrained vs Unconstrained Operations

- Operators like `+`, `-`, `==` are constrained and expensive
- Best practice:
  - Apply constraints once using `evaluate_linear_expression`

This significantly reduces gate count.

## Important: Validating Circuit Inputs and Outputs

`BigCurve` does **not** automatically constrain that point coordinates are valid field elements or that points lie on the curve. If your circuit receives curve points as inputs or returns them as outputs, you **must** manually validate them. Without these checks, a malicious prover can supply invalid values that break the soundness of your circuit.

**1. `validate_in_field`** — Call this on the `x` and `y` coordinates (which are `BigNum` values) to constrain that they are valid elements of the base field (i.e. less than the field modulus). Without this, a prover can use unreduced values that are congruent modulo p but not canonical, leading to inconsistent behavior.

**2. `validate_on_curve`** — Call this on the point to constrain that (x, y) satisfies the curve equation y^2 = x^3 + ax + b. Without this, a prover can supply arbitrary (x, y) pairs that are not on the curve.

```rust
let point: BLS12_377 = /* ... from circuit input ... */;
point.x.validate_in_field();
point.y.validate_in_field();
point.validate_on_curve();
```

Points produced by `one` already include these checks and do not need manual validation.

## Example

```rust
use ::bigcurve::BigCurve;
use ::bigcurve::{BLS12_377, BLS12_377Scalar};

fn main() {
    let one = BLS12_377::one();
    let two = one.mul(BLS12_377Scalar::from(2));
    let three = one.mul(BLS12_377Scalar::from(3));

    assert((one + two) == three);
}
```

## Core Types

### BigCurve

Represents a point on an elliptic curve over a field `MOD`.

### ScalarField

Represents scalars used in point multiplication.

## API Overview

### ScalarField

- `zero`
- `from(Field)`
- `into(Field)`
- `from_bignum`
- `into_bignum`

### BigCurve

#### Constrained operations

- `+`, `-`, `==`
- `neg`, `add`, `sub`
- `mul(ScalarField)`

#### Metadata

- `x`, `y`
- `a`, `b`
- `is_infinity`

#### Constructors

- `one`
- `point_at_infinity`
- `from_coordinates`
- `from_coordinates_unsafe`

#### Helpers

- `validate_on_curve`
- `validate_in_subgroup` — For curves with cofactor greater than one (e.g. BLS12-377, BLS12-381), check subgroup membership whenever the protocol requires it and membership has not already been established. This applies to public and private inputs. A trusted subgroup constant or a subgroup-preserving derivation can establish membership without repeating the check.

## evaluate_linear_expression

Efficiently computes expressions of the form:

sum_i(a_i * P_i) + sum_j(Q_j)

This allows batching operations and applying constraints once.

### Signature

```rust
fn evaluate_linear_expression<
    let NScalarSlices: u32,
    let NMuls: u32,
    let NAdds: u32
>(
    mul_points: [Self; NMuls],
    mul_scalars: [ScalarField<NScalarSlices>; NMuls],
    add_points: [Self; NAdds],
) -> Self;
```

For example, for the earlier example we wanted to calculate `S = a * G + b * Q + P + R`. The parameters then become:
- `NMuls` = 2. The products are `a * G` and `b * Q`
- `NAdds` = 2. The linear terms are `P` and `R`


#### Example usage evaluate_linear_expression

```rust
use ::bigcurve::BigCurve;
use ::bigcurve::{BLS12_377, BLS12_377Scalar};
use ::bignum::BigNum;
use ::bignum::BLS12_377_Fr;

fn main(G: BLS12_377, Q: BLS12_377, P: BLS12_377, R: BLS12_377, s1: [u8; 4], s2: [u8; 3]) -> pub BLS12_377 {
    // G, Q, P and R are inputs here: validate them as described above before use.
    let a = BLS12_377Scalar::from_bignum(BLS12_377_Fr::derive_from_seed(s1));
    let b = BLS12_377Scalar::from_bignum(BLS12_377_Fr::derive_from_seed(s2));


    BLS12_377::evaluate_linear_expression([G, Q], [a, b], [P, R])
}
```

See `src/tests/bigcurve_test.nr` for more examples.

## Custom or predefined parameter set

There are predefined parameter sets located in `src/curves` of this library.

### Predefined Curves

This library includes the following field presets:

| Curve       | Base Field Instance                | Scalar Field Instance              |
|-------------|------------------------------------|------------------------------------|
| [BLS12-377](https://eprint.iacr.org/2020/351)   | `BLS12_377_Fq`            | `BLS12_377_Fr`            |
| [BLS12-381](https://electriccoin.co/blog/new-snark-curve/)   | `BLS12_381_Fq`            | `BLS12_381_Fr`            |
| [BN254](https://zips.z.cash/protocol/protocol.pdf)   | `BN254_Fq`                    | (Scalar field is the native field in Noir) |
| [MNT4-753](https://eprint.iacr.org/2014/595)    | `MNT4_753_Fq`             | `MNT4_753_Fr`             |
| [MNT6-753](https://eprint.iacr.org/2014/595)    | `MNT6_753_Fq`             | `MNT6_753_Fr`             |
| [Pallas](https://electriccoin.co/blog/the-pasta-curves-for-halo-2-and-beyond/)     | `Pallas_Fr` | `Pallas_Fq` |
| [Secp256k1](https://en.bitcoin.it/wiki/Secp256k1) | `Secp256k1_Fq`            | `Secp256k1_Fr`            |
| [Secp256r1](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-4.pdf) | `Secp256r1_Fq`            | `Secp256r1_Fr`            |
| [Secp384r1](https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.186-4.pdf) | `Secp384r1_Fq`            | `Secp384r1_Fr`            |
| [Vesta](https://github.com/zcash/pasta) | `Vesta_Fq` | `Vesta_Fr` |
Feature requests and/or pull requests welcome for missing fields you need.

# FAQ

Q: What's up with the Jacobian points and the transcript objects?
A: To minimize witness generation time (currently the bottleneck due to Brillig VM) we evaluate ECC operations over Jacobian coordinates in an unconstrained function, in order to efficiently batch-compute the modular inverses required to constrain ECC operations over Affine coordinates (which is more constraint-efficient)

# Future work

- Parametrize and test with a degree-2 extension field instead of `BigNum`
- Add support for curve endomorphisms where applicable (if base field and scalar field both contain cube roots of unity, we can reduce the number of point doublings required for an MSM in half)

## MSM with a caller-selected initial offset

`mul` and `evaluate_linear_expression` start their accumulator from a fixed
point, the curve's offset generator, and subtract a fixed correction at the end.
That correction is precomputed for the curve's full scalar width (`NScalarSlices`
4-bit windows, e.g. 64 for BN254), so short scalars (e.g. 128-bit) must still be
encoded at full width and pay for every window's doublings.

`bigcurve::internal::evaluate_linear_expression_preserving_selected_offset(mul_points, mul_scalars, add_points, initial_offset)`
runs the same MSM but starts from the caller's `initial_offset` and does not
remove it. For `S = NScalarSlices` windows it returns

`[16^(S-1)]initial_offset + sum(s_i P_i) + sum(Q_j)`

To get the plain result, subtract the correction `[16^(S-1)]initial_offset`
with the ordinary `-`. The correction must belong to the same initial offset
and the same `S`: a constant precomputed for a fixed initial offset, or a value
computed in constrained code. A correction the prover supplies without
constraints would let the prover choose the result.

Requirements: `S > 0` and at least one multiplication term. `initial_offset`
must be a validly constructed point like the other inputs (range-checked
coordinates); the function additionally checks that it is on the curve and not
the point at infinity. The MSM steps and the additions of `add_points` use the
same incomplete formulas as `evaluate_linear_expression`: an initial offset that
makes one of them add equal or opposite points makes the circuit unsatisfiable,
never wrong. Choose the initial offset independently of the input points, e.g. a
fixed nothing-up-my-sleeve point with no known discrete-log relation to them, as
the library's offset generator is; then a collision has negligible probability
for inputs chosen without knowledge of it. An offset the prover picks freely
affects only whether a proof exists. Input points must be valid; a protocol
requiring subgroup membership must establish it separately.

`bigcurve::internal::find_safe_msm_offset(mul_points, mul_scalars, add_points, offsets)`
helps a prover pick the initial offset when the input points may have been
chosen to collide with it. This unconstrained helper runs the MSM's steps and
the additions of `add_points` from each candidate in `offsets` in turn, and
returns the index of the first candidate for which no step adds equal or
opposite points, or fails if none qualifies; nothing guarantees that one does.
Inputs and candidates must be valid points in an odd prime-order group. Use the
index to select both the candidate and its matching correction from fixed
arrays in constrained code, then call
`evaluate_linear_expression_preserving_selected_offset` with the same inputs.
The constrained replay, not the helper, is what makes the result correct.
