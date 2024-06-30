use dep::bignum::ArrayX;
use dep::bignum::BigNum;
use dep::bignum::BNExpressionInput;
use dep::bignum::BigNumParamsTrait;
// use dep::bignum::BigNumParams;
use dep::bignum::U60Repr;

use crate::scalar_field::ScalarField;

use crate::curve_jac::AffineTranscript;
// trait BigFieldTrait {
//     fn one() -> Self;
//     fn zero() -> Self;
//     fn new() -> Self;
// }

// trait BigCurveParamsTrait<BigField> where BigField: BigFieldTrait {
//     fn a() -> Field;
//     fn b() -> Field;
//     fn one() -> ();
// }

struct BigCurve<N, Params> {
    x: BigNum<N, Params>,
    y: BigNum<N, Params>
}

struct PointTable<N, Params> {
    x: [[Field; N]; 16],
    y: [[Field; N]; 16],
}

impl<N, Params> PointTable<N, Params> {
    fn new_with_hint(
        P: BigCurve<N, Params>,
        transcript: [AffineTranscript<N, Params>; 9]
    ) -> Self where Params: BigNumParamsTrait<N> {
        let mut result = PointTable { x: [[0; N]; 16], y: [[0; N]; 16] };

        let D2 = P.double_with_hint(transcript[0]);

        result.x[8] = P.x.limbs;
        result.y[8] = P.y.limbs;
        result.x[7] = P.x.limbs;
        result.y[7] = (BigNum::new() - P.y).limbs; // TODO: THIS IS EXPENSIVE. CAN WE DO BETTER?

        let mut A = P;
        for i in 1..8 {
            A = D2.add_with_hint(A, transcript[i + 1]);
            result.x[8 + i] = A.x.limbs;
            result.y[8 + i] = A.y.limbs;
            result.x[7 - i] = A.x.limbs;
            result.y[7 - i] = (BigNum::new() - A.y).limbs;
        }
        result
    }

    fn get(self, idx: u8) -> BigCurve<N, Params> {
        let x = self.x[idx];
        let y = self.y[idx];
        BigCurve { x: BigNum { limbs: x }, y: BigNum { limbs: y } }
    }
}

impl<N, Params> BigCurve<N, Params> {

    fn neg(self) -> Self where Params: BigNumParamsTrait<N> {
        BigCurve { x: self.x, y: BigNum::new() - self.y }
    }
    fn add_with_hint(
        self,
        other: Self,
        transcript: AffineTranscript<N, Params>
    ) -> Self where Params: BigNumParamsTrait<N> {
        let x1: BigNum<N, Params> = self.x;
        let y1: BigNum<N, Params> = self.y;
        let x2: BigNum<N, Params> = other.x;
        let y2: BigNum<N, Params> = other.y;
        let lambda: BigNum<N, Params> = transcript.lambda;
        let x3: BigNum<N, Params> = transcript.x3;
        let y3: BigNum<N, Params> = transcript.y3;
        BigNum::evaluate_quadratic_expression(
            [[BNExpressionInput::new(lambda, false), BNExpressionInput::new(BigNum::new(), false)]],
            [[BNExpressionInput::new(x2, false), BNExpressionInput::new(x1, true)]],
            [BNExpressionInput::new(y2, true), BNExpressionInput::new(y1, false)]
        );

        // \lambda^2 - x3 - x2 - x1 = 0
        BigNum::evaluate_quadratic_expression(
            [[BNExpressionInput::new(lambda, false)]],
            [[BNExpressionInput::new(lambda, false)]],
            [
            BNExpressionInput::new(x3, true), BNExpressionInput::new(x2, true), BNExpressionInput::new(x1, true)
        ]
        );

        // lambda * (x3 - x1) + y3 + y1 = 0
        BigNum::evaluate_quadratic_expression(
            [[BNExpressionInput::new(lambda, false), BNExpressionInput::new(BigNum::new(), false)]],
            [[BNExpressionInput::new(x3, false), BNExpressionInput::new(x1, true)]],
            [BNExpressionInput::new(y3, false), BNExpressionInput::new(y1, false)]
        );

        BigCurve { x: x3, y: y3 }
    }

    fn mul_with_hint<NScalarSlices, NTranscriptSlices>(
        self,
        scalar: ScalarField<NScalarSlices>,
        transcript: [AffineTranscript<N, Params>; NTranscriptSlices]
    ) -> Self where Params: BigNumParamsTrait<N> {
        let table_transcript: [AffineTranscript<N, Params>; 9] = [
            transcript[0], transcript[1], transcript[2], transcript[3], transcript[4], transcript[5], transcript[6], transcript[7], transcript[8]
        ];

        let T: PointTable<N, Params> = PointTable::new_with_hint(self, table_transcript);

        let mut accumulator = T.get(scalar.base4_slices[0]);
        for i in 1..NScalarSlices {
            accumulator = accumulator.double_with_hint(transcript[4 + 5 * i]);
            accumulator = accumulator.double_with_hint(transcript[5 + 5 * i]);
            accumulator = accumulator.double_with_hint(transcript[6 + 5 * i]);
            accumulator = accumulator.double_with_hint(transcript[7 + 5 * i]);

            accumulator = accumulator.add_with_hint(T.get(scalar.base4_slices[i]), transcript[8 + 5 * i]);
        }

        if (scalar.skew) {
            accumulator = accumulator.add_with_hint(self.neg(), transcript[4 + 5 * NScalarSlices]);
        }

        accumulator
    }

    fn double_with_hint(
        self,
        transcript: AffineTranscript<N, Params>
    ) -> Self where Params: BigNumParamsTrait<N> {
        let x1: BigNum<N, Params> = self.x;
        let y1: BigNum<N, Params> = self.y;
        let lambda: BigNum<N, Params> = transcript.lambda;
        let x3: BigNum<N, Params> = transcript.x3;
        let y3: BigNum<N, Params> = transcript.y3;

        // lambda * 2y - 3x^2 = 0
        BigNum::evaluate_quadratic_expression(
            [
            [
                BNExpressionInput::new(x1, false), BNExpressionInput::new(x1, false), BNExpressionInput::new(x1, false)
            ],
            [
                BNExpressionInput::new(y1, false), BNExpressionInput::new(y1, false), BNExpressionInput::new(BigNum::new(), false)
            ]
        ],
            [
            [
                BNExpressionInput::new(x1, true), BNExpressionInput::new(BigNum::new(), false), BNExpressionInput::new(BigNum::new(), false)
            ],
            [
                BNExpressionInput::new(lambda, true), BNExpressionInput::new(BigNum::new(), false), BNExpressionInput::new(BigNum::new(), false)
            ]
        ],
            []
        );

        // \lambda^2 - x3 - x1 - x1 = 0
        BigNum::evaluate_quadratic_expression(
            [[BNExpressionInput::new(lambda, false)]],
            [[BNExpressionInput::new(lambda, false)]],
            [
            BNExpressionInput::new(x3, true), BNExpressionInput::new(x1, true), BNExpressionInput::new(x1, true)
        ]
        );

        // lambda * (x3 - x1) + y3 + y1 = 0
        BigNum::evaluate_quadratic_expression(
            [[BNExpressionInput::new(lambda, false), BNExpressionInput::new(BigNum::new(), false)]],
            [[BNExpressionInput::new(x3, false), BNExpressionInput::new(x1, true)]],
            [BNExpressionInput::new(y3, false), BNExpressionInput::new(y1, false)]
        );

        BigCurve { x: x3, y: y3 }
    }
}
