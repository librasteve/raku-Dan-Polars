extern crate polars;

use polars::prelude::*;//{CsvReader, DataType, DataFrame, Series};
use polars::prelude::{Result as PolarResult};
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

/*
fn add_one_shallow( opt_name: Option<i32> ) -> Option<i32> {
    opt_name.map( |name| add_one_deep(name) )
}

fn add_one_deep( name: i32 ) -> i32 {
    (name + 2) as i32
}

fn do_apply(num_val: Series) -> Result<Series> {
    let x = num_val
        .i32()
        .unwrap()
        .into_iter()

        .map(|opt_name| {
            add_one_shallow(opt_name)
        } )

        .collect::<Int32Chunked>();
    Ok(x.into_series())
}
*/
/*
fn do_apply(num_val: Series) -> Result<Series> {
    let x = num_val
        .i32()
        .unwrap()
        .into_iter()
        .map(|opt_name: Option<i32>| opt_name.map(|name: i32| (name + 1) as i32))
        .collect::<Int32Chunked>();
    Ok(x.into_series())
}

fn get_apply(ex_c: &mut ExprC) -> *mut ExprC {

    let o = GetOutput::from_type(DataType::Int32);
    let new_inner: Expr = ex_c.inner.clone().apply(do_apply, o).into();
    println!("17");

    //let ex_n = ExprC::new(new_inner.clone());
    let ex_n = ExprC::new(ex_c.inner.clone());
    println!("18");
    Box::into_raw(Box::new(ex_n))
}

#[no_mangle]
pub extern "C" fn ap_apply(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);

    println!("hoho");

    get_apply(ex_c)
}
*/

fn add_one(num_val: Series) -> Result<Series> {
    let x = num_val
        .i32()
        .unwrap()
        .into_iter()
        .map(|opt_name: Option<i32>| opt_name.map(|name: i32| (name + 1) as i32))
        .collect::<Int32Chunked>();
    Ok(x.into_series())
}

#[no_mangle]
pub extern "C" fn ap_apply(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);

    println!("hoho");

    let o = GetOutput::from_type(DataType::Int32);
    //let new_inner: Expr = ex_c.inner.clone();
    let new_inner: Expr = ex_c.inner.clone().apply(add_one, o).into();
    println!("17");

    let ex_n = ExprC::new(new_inner.clone());
    println!("18");

    Box::into_raw(Box::new(ex_n))
}






