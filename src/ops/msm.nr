use crate::bigcurve::BigCurve;
use crate::curve_jac::types::{AffineTranscript, CurveJ};
use crate::ops::affine::{
    add_with_hint, conditional_incomplete_add_with_hint, conditional_incomplete_subtract_with_hint,
    double_with_hint, incomplete_add_with_hint, sub_with_hint,
};
use crate::ops::point_table::PointTable;
use crate::scalar_field::ScalarField;
use bignum::BigNum;

/// Perform a multi-scalar multiplication (constrained)
///
/// Computes `sum_i(mul_scalars[i] * mul_points[i])`.
/// Delegates to `evaluate_linear_expression` with no additive points.
pub fn msm<P: BigCurve<BN>, BN: BigNum, let NScalarSlices: u32, let NMuls: u32>(
    mul_points: [P; NMuls],
    mul_scalars: [ScalarField<NScalarSlices>; NMuls],
) -> P {
    let add_points: [P; 0] = [];
    P::evaluate_linear_expression(mul_points, mul_scalars, add_points)
}

/// Perform a single scalar multiplication, verifying an `AffineTranscript` (constrained)
///
/// Computes `scalar * point` by replaying the wNAF double-and-add loop against
/// the provided transcript, then subtracts `offset_generator_final`.
pub fn mul_with_hint<let NScalarSlices: u32, let NTranscriptSlices: u32, BN: BigNum, P: BigCurve<BN>>(
    point: P,
    scalar: ScalarField<NScalarSlices>,
    transcript: [AffineTranscript<BN>; NTranscriptSlices],
) -> P {
    let (input, scalar): (P, ScalarField<NScalarSlices>) = if point.is_infinity() {
        (P::one(), ScalarField::zero())
    } else {
        (point, scalar)
    };
    let T: PointTable<BN> = PointTable::new_with_hint::<P>(
        input,
        [
            transcript[0],
            transcript[1],
            transcript[2],
            transcript[3],
            transcript[4],
            transcript[5],
            transcript[6],
            transcript[7],
        ],
    );

    // Initialize accumulator: offset_generator + T[slice[0]]
    let mut accumulator: P = P::offset_generator();
    let mut accumulator: P = incomplete_add_with_hint::<BN, P>(
        accumulator,
        T.get::<P>(scalar.base4_slices[0] as u32),
        transcript[3 + 5],
    );

    // For each subsequent slice: 4 doublings then add table lookup
    for i in 1..NScalarSlices {
        accumulator = double_with_hint::<BN, P>(accumulator, transcript[4 + 5 * i]);
        accumulator = double_with_hint::<BN, P>(accumulator, transcript[5 + 5 * i]);
        accumulator = double_with_hint::<BN, P>(accumulator, transcript[6 + 5 * i]);
        accumulator = double_with_hint::<BN, P>(accumulator, transcript[7 + 5 * i]);
        accumulator = incomplete_add_with_hint::<BN, P>(
            accumulator,
            T.get::<P>(scalar.base4_slices[i] as u32),
            transcript[8 + 5 * i],
        );
    }

    // wNAF skew correction: subtract P when scalar is even
    accumulator = conditional_incomplete_subtract_with_hint::<BN, P>(
        accumulator,
        input,
        scalar.skew,
        transcript[4 + 5 * NScalarSlices],
    );

    // Remove the offset generator
    accumulator = sub_with_hint::<BN, P>(
        accumulator,
        P::offset_generator_final(),
        transcript[5 + 5 * NScalarSlices],
    );
    accumulator
}

/// Generate the `AffineTranscript` for a single scalar multiplication (unconstrained)
pub unconstrained fn get_mul_transcript<let NScalarSlices: u32, BN: BigNum, P: BigCurve<BN>>(
    point: P,
    scalar: ScalarField<NScalarSlices>,
) -> [AffineTranscript<BN>; 6 + NScalarSlices * 5] {
    let tmp: CurveJ<BN, P> = CurveJ::from(point);
    let (_, transcript) = tmp.mul(scalar);
    transcript
}

/// Evaluate `sum_i(mul_scalars[i] * mul_points[i]) + sum_j(add_points[j])` (constrained)
///
/// Generates the transcript via unconstrained witness generation, then replays
/// the full MSM + additions loop, verifying each step against the transcript.
pub fn evaluate_linear_expression<BN: BigNum, Curve: BigCurve<BN>, let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>(
    mul_points: [Curve; NMuls],
    mul_scalars: [ScalarField<NScalarSlices>; NMuls],
    add_points: [Curve; NAdds],
) -> Curve {
    evaluate_linear_expression_impl(
        mul_points,
        mul_scalars,
        add_points,
        false,
        true,
        Curve::offset_generator(),
    )
}

/// Returns [16^(NScalarSlices-1)]initial_offset + sum(s_i P_i) + sum(add_points).
/// Requires NScalarSlices > 0 and NMuls > 0. The selected offset is checked
/// finite and on-curve. Other points must be valid, as for the standard MSM.
/// Incomplete intermediate formulas can reject exceptional offsets; the
/// witness-only search helper does not replace constrained replay.
/// Final additions use the complete formulas of `add_with_hint` (as `Add`
/// does), so an add point may cancel or equal the accumulator (e.g. a
/// correction applied through `add_points`); doubling a finite point with
/// y = 0 is still rejected.
/// The caller must bind any final correction to this exact offset and schedule.
pub fn evaluate_linear_expression_preserving_selected_offset<BN: BigNum, Curve: BigCurve<BN>, let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>(
    mul_points: [Curve; NMuls],
    mul_scalars: [ScalarField<NScalarSlices>; NMuls],
    add_points: [Curve; NAdds],
    initial_offset: Curve,
) -> Curve {
    assert((NScalarSlices > 0) & (NMuls > 0), "MSM needs windows and multiplication terms");
    initial_offset.validate_on_curve();
    assert(!initial_offset.is_infinity(), "MSM initial offset must be finite");
    evaluate_linear_expression_impl(
        mul_points,
        mul_scalars,
        add_points,
        true,
        false,
        initial_offset,
    )
}

// `complete_final_additions` and `remove_offset` are always literals fixed by
// one of the public wrappers above, never caller-controlled values, so each
// wrapper compiles to a single formula and offset handling.
fn evaluate_linear_expression_impl<BN: BigNum, Curve: BigCurve<BN>, let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>(
    mul_points: [Curve; NMuls],
    mul_scalars: [ScalarField<NScalarSlices>; NMuls],
    add_points: [Curve; NAdds],
    complete_final_additions: bool,
    remove_offset: bool,
    initial_offset: Curve,
) -> Curve {
    // Safety: transcript is verified step-by-step in the constrained replay loop below
    let transcript: [AffineTranscript<BN>; NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 + NAdds - 3] = unsafe {
        get_linear_expression_transcript(
            mul_points,
            mul_scalars,
            add_points,
            complete_final_additions,
            remove_offset,
            initial_offset,
        )
    };

    // Replace infinity inputs with the generator (scalar zeroed to produce identity)
    let mut _inputs: [Curve; NMuls] = [BigCurve::one(); NMuls];
    let mut _scalars: [ScalarField<NScalarSlices>; NMuls] = [ScalarField::zero(); NMuls];
    for i in 0..NMuls {
        let (input, scalar) = if mul_points[i].is_infinity() {
            (BigCurve::one(), ScalarField::zero())
        } else {
            (mul_points[i], mul_scalars[i])
        };
        _inputs[i] = input;
        _scalars[i] = scalar;
    }
    let msm_points: [Curve; NMuls] = _inputs;
    let scalars: [ScalarField<NScalarSlices>; NMuls] = _scalars;

    let mut tables: [PointTable<BN>; NMuls] = [PointTable::empty(); NMuls];
    for i in 0..NMuls {
        let mut table_transcript: [AffineTranscript<BN>; 8] = [AffineTranscript::new(); 8];
        for j in 0..8 {
            table_transcript[j] = transcript[i * 8 + j];
        }
        tables[i] = PointTable::<BN>::new_with_hint::<Curve>(msm_points[i], table_transcript);
    }

    // Initialize accumulator: offset_generator + T_0[slice_0[0]] + T_1[slice_1[0]] + ...
    let mut accumulator: Curve = initial_offset;
    let mut accumulator: Curve = incomplete_add_with_hint::<BN, Curve>(
        accumulator,
        tables[0].get::<Curve>(scalars[0].base4_slices[0] as u32),
        transcript[8 * NMuls],
    );
    for i in 1..NMuls {
        accumulator = incomplete_add_with_hint::<BN, Curve>(
            accumulator,
            tables[i].get::<Curve>(scalars[i].base4_slices[0] as u32),
            transcript[8 * NMuls + i],
        );
    }

    // For each subsequent slice: 4 doublings then add each point's table lookup
    for i in 1..NScalarSlices {
        accumulator = double_with_hint::<BN, Curve>(
            accumulator,
            transcript[9 * NMuls + (4 + NMuls) * (i - 1)],
        );
        accumulator = double_with_hint::<BN, Curve>(
            accumulator,
            transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 1],
        );
        accumulator = double_with_hint::<BN, Curve>(
            accumulator,
            transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 2],
        );
        accumulator = double_with_hint::<BN, Curve>(
            accumulator,
            transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 3],
        );
        for j in 0..NMuls {
            accumulator = incomplete_add_with_hint::<BN, Curve>(
                accumulator,
                tables[j].get::<Curve>(scalars[j].base4_slices[i] as u32),
                transcript[9 * NMuls + (4 + NMuls) * (i - 1) + 4 + j],
            );
        }
    }

    // wNAF skew correction: subtract P_i when scalar_i is even
    for i in 0..NMuls {
        accumulator = conditional_incomplete_subtract_with_hint::<BN, Curve>(
            accumulator,
            msm_points[i],
            scalars[i].skew,
            transcript[9 * NMuls + (4 + NMuls) * (NScalarSlices - 1) + i],
        );
    }

    // Add the additive points: complete formulas (infinity, equality and
    // cancellation accepted; doubling a finite y = 0 point still rejected), or
    // incomplete formulas skipping infinity.
    for i in 0..NAdds {
        let add_transcript = transcript[10 * NMuls + (4 + NMuls) * (NScalarSlices - 1) + i];
        accumulator = if complete_final_additions {
            add_with_hint::<BN, Curve>(accumulator, add_points[i], add_transcript)
        } else {
            conditional_incomplete_add_with_hint::<BN, Curve>(
                accumulator,
                add_points[i],
                !add_points[i].is_infinity(),
                add_transcript,
            )
        };
    }

    // Each public wrapper passes a fixed constant; only the selected-offset API keeps F.
    if remove_offset {
        accumulator = sub_with_hint::<BN, Curve>(
            accumulator,
            BigCurve::offset_generator_final(),
            transcript[NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 + NAdds - 4],
        );
    }

    accumulator
}

/// Untrusted deterministic search for an offset accepted by the incomplete MSM.
/// Inputs and candidates must be valid points in an odd prime-order subgroup;
/// infinity multiplication inputs are replaced by the generator with scalar zero.
/// Returns the first admissible candidate, or fails if the finite list is exhausted.
/// No universal candidate-count or success guarantee is made. The caller must
/// constrain the selected array lookup and replay the MSM with the chosen offset.
pub unconstrained fn find_safe_msm_offset<BN: BigNum, Curve: BigCurve<BN>, let NScalarSlices: u32, let NMuls: u32, let NCandidates: u32>(
    mul_points: [Curve; NMuls],
    mul_scalars: [ScalarField<NScalarSlices>; NMuls],
    offsets: [Curve; NCandidates],
) -> u32 {
    CurveJ::<BN, Curve>::find_safe_msm_offset(mul_points, mul_scalars, offsets)
}

// Expose only the transcript as witnesses; the unused Jacobian result is
// not part of the constrained replay interface.
unconstrained fn get_linear_expression_transcript<BN: BigNum, Curve: BigCurve<BN>, let NScalarSlices: u32, let NMuls: u32, let NAdds: u32>(
    mul_points: [Curve; NMuls],
    mul_scalars: [ScalarField<NScalarSlices>; NMuls],
    add_points: [Curve; NAdds],
    complete_final_additions: bool,
    remove_offset: bool,
    initial_offset: Curve,
) -> [AffineTranscript<BN>; NScalarSlices * NMuls + NScalarSlices * 4 + NMuls * 9 + NAdds - 3] {
    CurveJ::<BN, Curve>::compute_linear_expression_transcript(
        mul_points,
        mul_scalars,
        add_points,
        complete_final_additions,
        remove_offset,
        initial_offset,
    )
        .1
}
