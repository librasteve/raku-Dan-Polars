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

        .%ATYPE%() 
        .unwrap() 
        .into_iter()
        .map(|opt: Option<%ATYPE%>| opt.map(|a: %ATYPE%| %BODY% as %RTYPE%))
        .collect::<%DTYPE%Chunked>();
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

