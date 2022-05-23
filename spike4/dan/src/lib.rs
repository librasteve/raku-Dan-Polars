//#![crate_type = "dylib"] #define dylib in Cargo.toml 

use std::ffi::*;//{CStr}

use polars::prelude::*;//{CsvReader, DataType, Field, Result as PolarResult, Schema, DataFrame,};
use polars::prelude::{Result as PolarResult};
use polars::frame::DataFrame;
use std::fs::File;
use std::path::{Path};
//// an eye on traits:
use polars::prelude::SerReader;
//// If we don't import this one we might get the error CsvReader::new(file) new function not found in CsvReader

//pub fn read_csv<P: AsRef<Path>>(path: P) -> PolarResult<DataFrame> {
//    /* Example function to create a dataframe from an input csv file*/
//    let file = File::open(path).expect("Cannot open file.");
//
//    CsvReader::new(file)
//    .has_header(true)
//    .finish()
//}

//iamerejh ... get from CStr to AsRef<Path> maybe via AsRef<OsStr>?
pub fn read_csv(spath:&str) -> PolarResult<DataFrame> {
    println!{"{}", spath};
    let fpath = Path::new("/root/raku-Dan-Polars/spike2/pl_so/src/iris.csv");
    //let fpath = Path::new(spath);
    let file = File::open(fpath).expect("Cannot open file.");

    CsvReader::new(file)
    .has_header(true)
    .finish()
}

#[no_mangle]
pub extern "C" fn xxx(cfile:&CStr) {
//fn main() -> Result<()> {

  //let ifile = "/root/raku-Dan-Polars/spike2/pl_so/src/iris.csv";
  let sfile = "some text";
  //let sfile = cfile.to_str().unwrap();
  println!("{}", sfile.len());
  //let ifile = sfile;
  let df = read_csv(sfile).unwrap();
  println!{"{}", df.head(Some(5))};

  //Ok(())  
  //#may need some incantation like this for "no panic" return types?
}
 

 
#[no_mangle]
pub extern "C" fn add(a:i32, b:i32) -> i32 {
    a+b 
}
