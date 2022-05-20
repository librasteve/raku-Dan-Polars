use polars::prelude::*;//{CsvReader, DataType, Field, Result as PolarResult, Schema, DataFrame,};
use polars::prelude::{Result as PolarResult};
use polars::frame::DataFrame;
use std::fs::File;
use std::path::{Path};
// an eye on traits:
use polars::prelude::SerReader;
// If we don't import this one we might get the error CsvReader::new(file) new function not found in CsvReader

pub fn read_csv<P: AsRef<Path>>(path: P) -> PolarResult<DataFrame> {
    /* Example function to create a dataframe from an input csv file*/
    let file = File::open(path).expect("Cannot open file.");

    CsvReader::new(file) 
    .has_header(true)
    .finish()
}


fn main() -> Result<()> {
  let ifile = "/root/raku-Dan-Polars/spike2/pl_so/src/iris.csv";
  let df = read_csv(&ifile).unwrap();
  println!{"{}", df.head(Some(5))};

  Ok(())
}
