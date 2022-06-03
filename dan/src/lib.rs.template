use libc::c_char;
use libc::size_t;
use std::slice;
use std::ffi::*; //{CStr, CString,}
use std::fs::File;
use std::path::{Path};

use polars::prelude::*;//{CsvReader, DataType, DataFrame, Series};
use polars::prelude::{Result as PolarResult};

// Series Container

pub struct SeriesC {
    se: Series,
}

impl SeriesC {
    fn new() -> SeriesC {
        SeriesC {
            se: Series::new_empty("anon", &DataType::UInt32),
        }
    }

    fn say(&self) {
        println!{"{}", self.se};
    }

    fn head(&self) {
        println!{"{}", self.se.head(Some(5))};
    }
}

// extern functions for Series Container
#[no_mangle]
pub extern "C" fn se_new() -> *mut SeriesC {
    Box::into_raw(Box::new(SeriesC::new()))
}

#[no_mangle]
pub extern "C" fn se_free(ptr: *mut SeriesC) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        Box::from_raw(ptr);
    }
}


#[no_mangle]
pub extern "C" fn se_say(ptr: *mut SeriesC) {
    let se_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    se_c.say();
}
#[no_mangle]
pub extern "C" fn se_head(ptr: *mut SeriesC) {
    let se_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    se_c.head();
}

// DataFrame Container

pub fn df_load_csv(spath: &str) -> PolarResult<DataFrame> {
    let fpath = Path::new(spath);
    let file = File::open(fpath).expect("Cannot open file.");

    CsvReader::new(file)
    .has_header(true)
    .finish()
}

pub struct DataFrameC {
    df: DataFrame,
}

impl DataFrameC {
    fn new() -> DataFrameC {
        DataFrameC {
            df: DataFrame::default(),
        }
    }

    fn read_csv(&mut self, string: String) {
        self.df = df_load_csv(&string).unwrap(); 
    }

    fn head(&self) {
        println!{"{}", self.df.head(Some(5))};
    }

    fn column(&self, string: String) -> Series {
        self.df.column(&string).unwrap().clone()
    }

    fn select(&self, colvec: Vec::<String>) -> DataFrame {
        self.df.select(&colvec).unwrap().clone()
    }

    fn query(&self) -> DataFrame {
        let x = self.df.clone()
//%INSERT-QUERY%
            ;
        x
    }
}

// extern functions for DataFrame Container
#[no_mangle]
pub extern "C" fn df_new() -> *mut DataFrameC {
    Box::into_raw(Box::new(DataFrameC::new()))
}

#[no_mangle]
pub extern "C" fn df_free(ptr: *mut DataFrameC) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        Box::from_raw(ptr);
    }
}

#[no_mangle]
pub extern "C" fn df_read_csv(
    ptr: *mut DataFrameC,
    string: *const c_char,
) {
    let df_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };
    let spath = unsafe {
        CStr::from_ptr(string).to_string_lossy().into_owned()
    };
    df_c.read_csv(spath);
}

#[no_mangle]
pub extern "C" fn df_head(ptr: *mut DataFrameC) {
    let df_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };
    df_c.head();
}

#[no_mangle]
pub extern "C" fn df_column(
    ptr: *mut DataFrameC,
    string: *const c_char,
) -> *mut SeriesC {

    let df_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    let colname = unsafe {
        CStr::from_ptr(string).to_string_lossy().into_owned()
    };

    let mut se_n = SeriesC::new();
    se_n.se = df_c.column(colname);
    Box::into_raw(Box::new(se_n))
}

#[no_mangle]
pub extern "C" fn df_select(
    ptr: *mut DataFrameC,
    colspec: *const *const c_char,
    len: size_t, 
) -> *mut DataFrameC {
    let df_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    let mut colvec = Vec::<String>::new();
    unsafe {
        assert!(!colspec.is_null());

        for item in slice::from_raw_parts(colspec, len as usize) {
            colvec.push(CStr::from_ptr(*item).to_string_lossy().into_owned());
        };
    };

    //FIXME adjust to new(df)
    let mut df_n = DataFrameC::new();
    df_n.df = df_c.select(colvec);
    Box::into_raw(Box::new(df_n))
}

#[no_mangle]
pub extern "C" fn df_query(
    ptr: *mut DataFrameC,
) -> *mut DataFrameC {
    let df_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    //FIXME adjust to new(df)
    let mut df_n = DataFrameC::new();
    df_n.df = df_c.query();
    Box::into_raw(Box::new(df_n))
}

