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


// START_APPLY - monadic, Real
fn do_apply(vals: Series) -> Result<Series> {
    let x = vals
        .i32()
        .unwrap()
        .into_iter()
        .map(|opt: Option<i32>| opt.map(|a: i32| (a + 1) as i32))
        .collect::<Int32Chunked>();
    Ok(x.into_series())
}

#[no_mangle]
pub extern "C" fn ap_apply(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);

    let o = GetOutput::from_type(DataType::Int32);
    let new_inn: Expr = ex_c.inner.clone().apply(do_apply, o).into();

    let ex_n = ExprC::new(new_inn.clone());
    Box::into_raw(Box::new(ex_n))
}
//END_APPLY
