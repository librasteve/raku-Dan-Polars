extern crate polars;

use polars::prelude::*;//{CsvReader, DataType, DataFrame, Series};
use polars::lazy::dsl;
//use polars::lazy::dsl::Expr;

fn check_ptr<'a, T>(ptr: *mut T) -> &'a mut T {
    unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    }
}

#[repr(C)]
pub struct ExprC {
    pub inner: dsl::Expr,
}
impl ExprC {
    fn new(inner: dsl::Expr) -> ExprC {
        ExprC { inner }
    }
}

//START_APPLY - monadic, Real
fn do_apply_mr(vals: Series) -> Result<Series> {
    let x = vals

//        .i32()
//        .unwrap() 
//        .into_iter()
//        .map(|opt: Option<i32>| opt.map(|a: i32| (a + 1) as i32))
//        .collect::<Int32Chunked>();

        .i32() 
        .unwrap() 
        .into_iter()
        .map(|opt: Option<i32>| opt.map(|a: i32| (a + a + 1) as i32))
        .collect::<Int32Chunked>();
    Ok(x.into_series())
}

#[no_mangle]
pub extern "C" fn ap_apply_mr(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);

    let new_inn: Expr = ex_c.inner.clone().apply(do_apply_mr, GetOutput::default()).into();

    let ex_n = ExprC::new(new_inn.clone());
    Box::into_raw(Box::new(ex_n))
}
//END_APPLY

//START_APPLY - dyadic, Real
fn do_apply_dr(vals: Series) -> Result<Series> {
    let x = vals

//        .i32()
//        .unwrap() 
//        .into_iter()
//        .map(|opt: Option<i32>| opt.map(|a: i32| (a + 1) as i32))
//        .collect::<Int32Chunked>();

        .i32() 
        .unwrap() 
        .into_iter()
        .map(|opt: Option<i32>| opt.map(|a: i32| (a + a + 1) as i32))
        .collect::<Int32Chunked>();
    Ok(x.into_series())
}

#[no_mangle]
pub extern "C" fn ap_apply_dr(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);

    let new_inn: Expr = ex_c.inner.clone().apply(do_apply_dr, GetOutput::default()).into();

    let ex_n = ExprC::new(new_inn.clone());
    Box::into_raw(Box::new(ex_n))
}
//END_APPLY


/*
Dyadic
 ```python
 out = df.select(
    [
        pl.struct(["keys", "values"])
        .apply(lambda x: len(x["keys"]) + x["values"])
        .alias("solution_apply"),
        (pl.col("keys").str.lengths() + pl.col("values")).alias("solution_expr"),
    ]
)
print(out)
 ```

 ```rust
 let out = df
    .lazy()
    .select([
        // pack to struct to get access to multiple fields in a custom `apply/map`
        as_struct(&[col("keys"), col("values")])      <-- iamerejh
            // we will compute the len(a) + b
            .apply(
                |s| {
                    // downcast to struct
                    let ca = s.struct_()?;

                    // get the fields as Series
                    let s_a = &ca.fields()[0];
                    let s_b = &ca.fields()[1];

                    // downcast the `Series` to their known type
                    let ca_a = s_a.utf8()?;
                    let ca_b = s_b.i32()?;

                    // iterate both `ChunkedArrays`
                    let out: Int32Chunked = ca_a
                        .into_iter()
                        .zip(ca_b)
                        .map(|(opt_a, opt_b)| match (opt_a, opt_b) {
                            (Some(a), Some(b)) => Some(a.len() as i32 + b),
                            _ => None,
                        })
                        .collect();

                    Ok(out.into_series())
                },
                GetOutput::from_type(DataType::Int32),
            )
            .alias("solution_apply"),
        (col("keys").str().count_match(".") + col("values")).alias("solution_expr"),
    ])
    .collect()?;
println!("{}", out);
*/
