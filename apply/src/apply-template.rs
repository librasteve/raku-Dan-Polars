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

//START_APPLY - monadic
fn do_apply_monadic(vals: Series) -> Result<Option<Series>, PolarsError> {
    let x = vals
        .%MATYPE%() 
        .unwrap() 
        .into_iter()
        .map(|opt: Option<%MATYPE%>| opt.map(|a: %MATYPE%| %MEXPR% as %MRTYPE%))
        .collect::<%MDTYPE%Chunked>();
    Ok(Some(x.into_series()))
}
//END_APPLY

#[no_mangle]
pub extern "C" fn ap_apply_monadic(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);

    let new_inn: Expr = ex_c.inner.clone().apply(do_apply_monadic, GetOutput::default()).into();

    let ex_n = ExprC::new(new_inn.clone());
    Box::into_raw(Box::new(ex_n))
}

/* Monadic Exemplar
        .i32()
        .unwrap()
        .into_iter()
        .map(|opt: Option<i32>| opt.map(|a: i32| (a + 1) as i32))
        .collect::<Int32Chunked>();
*/

//START_APPLY - dyadic
fn do_apply_dyadic(s: Series) -> Result<Option<Series>, PolarsError> {

    // downcast to struct
    let ca = s.struct_()?;

    // get the fields as Series
    let s_a = &ca.fields()[0];
    let s_b = &ca.fields()[1];

    // downcast the `Series` to their known type
    let ca_a = s_a.%DATYPE%()?;
    let ca_b = s_b.%DBTYPE%()?;

    // iterate both `ChunkedArrays`
    let out: %DDTYPE%Chunked = ca_a
        .into_iter()
        .zip(ca_b)
        .map(|(opt_a, opt_b)| match (opt_a, opt_b) {
            (Some(a), Some(b)) => Some(%DEXPR%),
            _ => None,
        })
        .collect();

    //println!("{}",out.clone().into_series());

    Ok(Some(out.into_series()))
}
//END_APPLY

#[no_mangle]
pub extern "C" fn ap_apply_dyadic(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);

    let new_inn: Expr = ex_c.inner.clone().apply(do_apply_dyadic, GetOutput::default()).into();

    let ex_n = ExprC::new(new_inn.clone());
    Box::into_raw(Box::new(ex_n))
}

/*
Dyadic Exemplar
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
*/

