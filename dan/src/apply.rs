extern crate polars;

use polars::prelude::*;//{CsvReader, DataType, DataFrame, Series};
use polars::lazy::dsl;
use polars::lazy::dsl::Expr;

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

fn add_one(num_val: Series) -> Result<Series> {
    let x = num_val
        .i32()
        .unwrap()
        .into_iter()
        // your actual custom function would be in this map
        .map(|opt_name: Option<i32>| opt_name.map(|name: i32| (name + 1) as i32))
        .collect::<Int32Chunked>();
    Ok(x.into_series())
}

#[no_mangle]
pub extern "C" fn ap_apply(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);

    let o = GetOutput::from_type(DataType::Int32);
    let new_inner: Expr = ex_c.inner.clone().apply(add_one, o).into();

    //let ex_n = ExprC::new(ex_c.inner.clone());
    let ex_n = ExprC::new(new_inner.clone());
    Box::into_raw(Box::new(ex_n))
}


