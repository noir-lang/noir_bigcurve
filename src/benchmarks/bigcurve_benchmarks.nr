use crate::curves::bn254::{BN254};
use crate::curves::secp256k1::{Secp256k1};
comptime fn make_bench(m: Module, params: Quoted) -> Quoted {
    let module_name = m.name();
    let add_bench_name = f"add_{module_name}".quoted_contents();
    let sub_bench_name = f"sub_{module_name}".quoted_contents();
    let one_bench_name = f"one_{module_name}".quoted_contents();
    let BigCurve = quote { crate::BigCurve };

    let from_field_bench_name = f"from_field_{module_name}".quoted_contents();
    let typ = params.as_type();

    quote {
        #[export]
        fn $add_bench_name(a: $typ, b: $typ) -> $typ {
            a.add(b)
        }

        #[export] 
        fn $sub_bench_name(a: $typ, b: $typ) -> $typ {
            a.sub(b)
        }

        #[export]
        fn $one_bench_name() -> $typ {
            $typ::one()
        }

    }
}

#[make_bench(quote { BN254 })]
mod BN254_Bench {}

#[make_bench(quote { Secp256k1 })]
mod Secp256k1_Bench {}