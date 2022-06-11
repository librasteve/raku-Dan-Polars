use libc::c_char;
use libc::size_t;
use std::slice;
use std::ffi::*; //{CStr, CString,}
use std::fs::File;
use std::io::Write;
use std::path::{Path};

use polars::prelude::*;//{CsvReader, DataType, DataFrame, Series};
use polars::prelude::{Result as PolarResult};

// Callback Types

type RetLine = extern fn(line: *const u8);

// Series Container

pub struct SeriesC {
    se: Series,
}

impl SeriesC {
    fn new<T>(name: String, data: Vec::<T>) -> SeriesC 
        where Series: NamedFrom<Vec<T>, [T]>
    {
        SeriesC {
            se: Series::new(&name, data),
        }
    }

    fn show(&self) {
        println!{"{}", self.se};
    }

    fn head(&self) {
        println!{"{}", self.se.head(Some(5))};
    }

    fn dtype(&self, retline: RetLine) {
        let dtype = CString::new(self.se.dtype().to_string()).unwrap();
        retline(dtype.as_ptr());
    }

    fn name(&self, retline: RetLine) {
        let name = CString::new(self.se.name()).unwrap();
        retline(name.as_ptr());
    }

    fn elems(&self) -> u32 {
        self.se.len().try_into().unwrap()
    }

    fn values(&self, vfile: String) {
        let mut w = File::create(vfile).unwrap();
        let dtype: &str = &self.se.dtype().to_string();
        match dtype {
            "i32" => { 
                let asvec: Vec<_> = self.se.i32().into_iter().collect(); 
                let bsvec: Vec<_> = asvec[0].into_iter().collect();
                for value in bsvec.iter() { 
                    writeln!(&mut w, "{}", value.unwrap()).unwrap();
                }
            },
            "u32" => { 
                let asvec: Vec<_> = self.se.u32().into_iter().collect(); 
                let bsvec: Vec<_> = asvec[0].into_iter().collect();
                for value in bsvec.iter() { 
                    writeln!(&mut w, "{}", value.unwrap()).unwrap();
                }
            },
            "i64" => { 
                let asvec: Vec<_> = self.se.i64().into_iter().collect(); 
                let bsvec: Vec<_> = asvec[0].into_iter().collect();
                for value in bsvec.iter() { 
                    writeln!(&mut w, "{}", value.unwrap()).unwrap();
                }
            },
            "u64" => { 
                let asvec: Vec<_> = self.se.u64().into_iter().collect(); 
                let bsvec: Vec<_> = asvec[0].into_iter().collect();
                for value in bsvec.iter() { 
                    writeln!(&mut w, "{}", value.unwrap()).unwrap();
                }
            },
            "f32" => { 
                let asvec: Vec<_> = self.se.f32().into_iter().collect(); 
                let bsvec: Vec<_> = asvec[0].into_iter().collect();
                for value in bsvec.iter() { 
                    writeln!(&mut w, "{}", value.unwrap()).unwrap();
                }
            },
            "f64" => { 
                let asvec: Vec<_> = self.se.f64().into_iter().collect(); 
                let bsvec: Vec<_> = asvec[0].into_iter().collect();
                for value in bsvec.iter() { 
                    writeln!(&mut w, "{}", value.unwrap()).unwrap();
                }
            },
            "str" => { 
                let asvec: Vec<_> = self.se.utf8().into_iter().collect(); 
                let bsvec: Vec<_> = asvec[0].into_iter().collect();
                for value in bsvec.iter() { 
                    writeln!(&mut w, "{}", value.unwrap()).unwrap();
                }
            },
            "bool" => { 
                let asvec: Vec<_> = self.se.bool().into_iter().collect(); 
                let bsvec: Vec<_> = asvec[0].into_iter().collect();
                for value in bsvec.iter() { 
                    writeln!(&mut w, "{}", value.unwrap()).unwrap();
                }
            },
            &_ => todo!(),
        }
    }
}

fn se_new_vec<T>(
    name: *const c_char,
    ptr: *const T,
    len: size_t, 
) -> *mut SeriesC 
        where Series: NamedFrom<Vec<T>, [T]>, T: Clone
    {

    let se_name;
    let mut se_data = Vec::new();
    unsafe {
        assert!(!ptr.is_null());
        se_name = CStr::from_ptr(name).to_string_lossy().into_owned();
        se_data.extend_from_slice(slice::from_raw_parts(ptr, len as usize));
    };

    Box::into_raw(Box::new(SeriesC::new(se_name, se_data)))
}

#[no_mangle]
pub extern "C" fn se_new_i32( name: *const c_char, ptr: *const i32, len: size_t, )
    -> *mut SeriesC { se_new_vec(name, ptr, len) }

#[no_mangle]
pub extern "C" fn se_new_i64( name: *const c_char, ptr: *const i64, len: size_t, ) 
    -> *mut SeriesC { se_new_vec(name, ptr, len) }

#[no_mangle]
pub extern "C" fn se_new_u32( name: *const c_char, ptr: *const u32, len: size_t, ) 
    -> *mut SeriesC { se_new_vec(name, ptr, len) }

#[no_mangle]
pub extern "C" fn se_new_u64( name: *const c_char, ptr: *const u64, len: size_t, ) 
    -> *mut SeriesC { se_new_vec(name, ptr, len) }

#[no_mangle]
pub extern "C" fn se_new_f32( name: *const c_char, ptr: *const f32, len: size_t, ) 
    -> *mut SeriesC { se_new_vec(name, ptr, len) }

#[no_mangle]
pub extern "C" fn se_new_f64( name: *const c_char, ptr: *const f64, len: size_t, ) 
    -> *mut SeriesC { se_new_vec(name, ptr, len) }

#[no_mangle]
pub extern "C" fn se_new_bool( name: *const c_char, ptr: *const bool, len: size_t, ) 
    -> *mut SeriesC { se_new_vec(name, ptr, len) }

#[no_mangle]
pub extern "C" fn se_new_str( name: *const c_char, ptr: *const *const c_char, len: size_t, ) 
    -> *mut SeriesC { 

    let se_name;
    let mut se_data = Vec::<String>::new();
    unsafe {
        assert!(!ptr.is_null());
        se_name = CStr::from_ptr(name).to_string_lossy().into_owned();

        for item in slice::from_raw_parts(ptr, len as usize) {
            se_data.push(CStr::from_ptr(*item).to_string_lossy().into_owned());
        };
    };

    Box::into_raw(Box::new(SeriesC::new(se_name, se_data)))
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
pub extern "C" fn se_show(ptr: *mut SeriesC) {
    let se_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    se_c.show();
}

#[no_mangle]
pub extern "C" fn se_head(ptr: *mut SeriesC) {
    let se_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    se_c.head();
}

#[no_mangle]
pub extern "C" fn se_dtype(ptr: *mut SeriesC, retline: RetLine) {
    let se_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    se_c.dtype(retline);
}

#[no_mangle]
pub extern "C" fn se_name(ptr: *mut SeriesC, retline: RetLine) {
    let se_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    se_c.name(retline);
}

#[no_mangle]
pub extern "C" fn se_elems(ptr: *mut SeriesC) -> u32 {
    let se_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    se_c.elems()
}

#[no_mangle]
pub extern "C" fn se_values(
    ptr: *mut SeriesC,
    string: *const c_char,
) {
    let se_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };
    let vfile = unsafe {
        CStr::from_ptr(string).to_string_lossy().into_owned()
    };

    se_c.values(vfile);
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

    fn read_csv(&mut self, path: String) {
        self.df = df_load_csv(&path).unwrap(); 
    }

    fn show(&self) {
        println!{"{}", self.df};
    }

    fn head(&self) {
        println!{"{}", self.df.head(Some(5))};
    }

    fn get_column_names(&self, retline: RetLine) {
        let names = self.df.get_column_names();

        for name in names.iter() {
            // convert string slice to a C style NULL terminated string
            let name = CString::new(*name).unwrap();
            retline(name.as_ptr());
        }
    }

    fn column(&self, string: String) -> Series {
        self.df.column(&string).unwrap().clone()
    }

    fn select(&self, colvec: Vec::<String>) -> DataFrame {
        self.df.select(&colvec).unwrap().clone()
    }

    fn with_column(&mut self, series: Series) -> DataFrame {
        self.df.with_column(series).unwrap().clone()
    }

    fn query(&self) -> DataFrame {
        let result = self.df.clone()

    .groupby(["variety"])
    .unwrap()
    .select(["petal.length"])
    .sum()
    .unwrap()

            ;
       result 
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
pub extern "C" fn df_show(ptr: *mut DataFrameC) {
    let df_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    df_c.show();
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
pub extern "C" fn df_get_column_names(ptr: *mut DataFrameC, retline: RetLine) {
    let df_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    df_c.get_column_names(retline);
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

    let mut se_n = SeriesC::new::<i64>("dummy".to_owned(), [].to_vec());
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
pub extern "C" fn df_with_column(
    d_ptr: *mut DataFrameC,
    s_ptr: *mut SeriesC,
) -> *mut DataFrameC {
    let df_c = unsafe {
        assert!(!d_ptr.is_null());
        &mut *d_ptr
    };
    let se_c = unsafe {
        assert!(!s_ptr.is_null());
        &mut *s_ptr
    };

    let mut df_n = DataFrameC::new();
    df_n.df = df_c.with_column(se_c.se.clone()); 
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

