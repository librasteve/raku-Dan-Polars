use std::ffi::*; //{CStr, CString,}
use std::os::raw::c_char;
use std::cell::RefCell;

use polars::prelude::*;//{CsvReader, DataType, Field, Result as PolarResult, Schema, DataFrame,};
use polars::prelude::{Result as PolarResult};
use polars::frame::DataFrame;
use std::fs::File;
use std::path::{Path};

pub fn read_csv(spath: &str) -> PolarResult<DataFrame> {
    println!{"{}", spath};
    let fpath = Path::new("/root/raku-Dan-Polars/spike2/pl_so/src/iris.csv");
    //let fpath = Path::new(spath);
    let file = File::open(fpath).expect("Cannot open file.");

    CsvReader::new(file)
    .has_header(true)
    .finish()
}
#[no_mangle]
pub extern "C" fn xxx(string: *const c_char) {
    let df = read_csv(&str_in(string)).unwrap();
    println!{"{}", df.head(Some(5))};
}

fn str_in(i_string: *const c_char) -> String {
    unsafe {
        CStr::from_ptr(i_string).to_string_lossy().into_owned()
    }
}
#[no_mangle]
pub extern "C" fn str2rust(string: *const c_char) {
    println!("{:?}", str_in(string));
}

//viz. https://metacpan.org/pod/FFI::Platypus::Lang::Rust#returning-strings
fn str_out(o_string: &str) -> *const u8 {
    thread_local! {
        static KEEP: RefCell<Option<CString>> = RefCell::new(None);
    }
 
    let c_string = CString::new(o_string).unwrap();
    let ptr = c_string.as_ptr();
    KEEP.with(|k| {
        *k.borrow_mut() = Some(c_string);
    });
 
    ptr
}
#[no_mangle]
pub extern "C" fn str2raku() -> *const u8 {
    str_out("yo")
}

#[no_mangle]
pub extern "C" fn add(a:i32, b:i32) -> i32 {
    a+b 
}
