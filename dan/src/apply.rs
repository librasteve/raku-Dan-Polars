#[no_mangle]
pub extern "C" fn add(a: isize, b: isize) -> isize {
    println!("yo babay");
    a + b 
}

#[no_mangle]
pub extern "C" fn cod( a: i32 ) -> i32 {
    (a + 42) as i32
}


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
        // your actual custom function would be in this map
        //.map(|opt_name: Option<i32>| opt_name.map(|name: i32| (name + 1) as i32))

        .map(|opt_name| {
            add_one_shallow(opt_name)
        } )

        .collect::<Int32Chunked>();
    Ok(x.into_series())
}

fn get_apply(ex_c: &mut ExprC) -> *mut ExprC {
    println!("17");

    let o = GetOutput::from_type(DataType::Int32);
    let new_inner: Expr = ex_c.inner.clone().apply(do_apply, o).into();

    let ex_n = ExprC::new(new_inner.clone());
    Box::into_raw(Box::new(ex_n))
}


#[no_mangle]
pub extern "C" fn ap_apply(ptr: *mut ExprC) -> *mut ExprC {
//pub extern "C" fn ap_apply(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    println!("hoho");

    //ptr

    get_apply(ex_c)
}
