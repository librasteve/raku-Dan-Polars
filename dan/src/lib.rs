use libc::c_char;
use libc::size_t;
use std::slice;
use std::ptr;
use std::ffi::*; //{CStr, CString,}
use std::fs::File;
use std::path::{Path};

use polars::prelude::*;//{CsvReader, DataType, DataFrame, Series};
use polars::prelude::{Result as PolarResult};

// these from nodejs lazy/dsl.rs...
use polars::lazy::dsl;
use polars::lazy::dsl::Expr;
use polars::lazy::dsl::Operator;

// maybe also...
//use polars_core::series::ops::NullBehavior;
//use std::borrow::Cow;
//use polars_lazy::prelude::*;
//use polars_core::prelude::*;

// Serde Example from nodejs for later
//    #[napi]
//    pub fn to_js(&self, env: Env) -> napi::Result<napi::JsUnknown> {
//        env.to_js_value(&self.inner)
//    }    
//
//    #[napi]
//    pub fn serialize(&self, format: String) -> napi::Result<Buffer> {
//        let buf = match format.as_ref() {
//            "bincode" => bincode::serialize(&self.inner)
//                .map_err(|err| napi::Error::from_reason(format!("{:?}", err)))?,
//            "json" => serde_json::to_vec(&self.inner)
//                .map_err(|err| napi::Error::from_reason(format!("{:?}", err)))?,
//            _ => { 
//                return Err(napi::Error::from_reason(
//                    "unexpected format. \n supported options are 'json', 'bincode'".to_owned(),
//                ))   
//            }    
//        };   
//        Ok(Buffer::from(buf))
//    }    
//
//    #[napi(factory)]
//    pub fn deserialize(buf: Buffer, format: String) -> napi::Result<ExprC> {
//        // Safety
//        // we skipped the serializing/deserializing of the static in lifetime in `DataType`
//        // so we actually don't have a lifetime at all when serializing.
//
//        // &[u8] still has a lifetime. But its ok, because we drop it immediately
//        // in this scope
//        let bytes: &[u8] = &buf;
//        let bytes = unsafe { std::mem::transmute::<&'_ [u8], &'static [u8]>(bytes) };
//        let expr: Expr = match format.as_ref() {
//            "bincode" => bincode::deserialize(bytes)
//                .map_err(|err| napi::Error::from_reason(format!("{:?}", err)))?,
//            "json" => serde_json::from_slice(bytes)
//                .map_err(|err| napi::Error::from_reason(format!("{:?}", err)))?,
//            _ => { 
//                return Err(napi::Error::from_reason(
//                    "unexpected format. \n supported options are 'json', 'bincode'".to_owned(),
//                ))   
//            }    
//        };   
//        Ok(expr.into())
//    }    

// Callback Types

type RetLine = extern fn(line: CString);

// Helpers for Safety Checks

fn check_ptr<'a, T>(ptr: *mut T) -> &'a mut T {
    unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    }
}

// Series Container

#[repr(C)]
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
        retline(dtype);
    }

    fn name(&self, retline: RetLine) {
        let name = CString::new(self.se.name()).unwrap();
        retline(name);
    }

    fn rename(&mut self, name: String) {
        self.se.rename(&name);
    }

    fn len(&self) -> u32 {
        self.se.len().try_into().unwrap()
    }

    fn get_data<T>(&self, buffer: *mut T, len: size_t, asvec: Vec<T>) {
        let slice: &[T] = &asvec;
        unsafe {
            let buffer: &mut [T] = 
                              slice::from_raw_parts_mut(buffer as *mut T, len as usize);
            ptr::copy_nonoverlapping(slice.as_ptr(), buffer.as_mut_ptr(), len as usize);
        }
    }

    fn get_bool(&self, buffer: *mut bool, len: size_t) {
        let asvec = self.se.bool().into_iter().flatten().flatten().collect();
        self.get_data(buffer, len, asvec);
    }
    fn get_i32(&self, buffer: *mut i32, len: size_t) {
        let asvec = self.se.i32().into_iter().flatten().flatten().collect();
        self.get_data(buffer, len, asvec);
    }
    fn get_i64(&self, buffer: *mut i64, len: size_t) {
        let asvec = self.se.i64().into_iter().flatten().flatten().collect();
        self.get_data(buffer, len, asvec);
    }
    fn get_u32(&self, buffer: *mut u32, len: size_t) {
        let asvec = self.se.u32().into_iter().flatten().flatten().collect();
        self.get_data(buffer, len, asvec);
    }
    fn get_u64(&self, buffer: *mut u64, len: size_t) {
        let asvec = self.se.u64().into_iter().flatten().flatten().collect();
        self.get_data(buffer, len, asvec);
    }
    fn get_f32(&self, buffer: *mut f32, len: size_t) {
        let asvec = self.se.f32().into_iter().flatten().flatten().collect();
        self.get_data(buffer, len, asvec);
    }
    fn get_f64(&self, buffer: *mut f64, len: size_t) {
        let asvec = self.se.f64().into_iter().flatten().flatten().collect();
        self.get_data(buffer, len, asvec);
    }
    fn get_u8(&self, buffer: *mut u8, len: size_t) {
        let asvec: Vec<_> = self.se.utf8().into_iter().flatten().flatten().collect();
        let asstr: String = asvec.join("\",\"");
        let asu8:  Vec<u8> = asstr.into_bytes();

        self.get_data(buffer, len, asu8);
    }

    fn str_lengths(&self) -> u32 {
        let dtype: &str = &self.se.dtype().to_string();
        match dtype {
            "str" => {
                let asvec: Vec<_> = self.se.utf8().into_iter().flatten().flatten().collect(); 
                let mut res: usize = 0;
                for item in asvec.iter() {
                    res = res + item.len();
                }
                res as u32
            },
            &_ => todo!(),
        }
    }

    fn append(&mut self, se_c: &SeriesC) -> Series {
        self.se.append(&se_c.se).unwrap().clone()
    }
}

enum Value<T> {
    Valid(T),
    Null,
}

fn xxx<T>(
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


    // Create a Vec<Value<i64>> with mixed valid and null values
    let data: Vec<Value<i64>> = vec![Value::Valid(1), Value::Valid(2), Value::Null, Value::Valid(4), Value::Null];
    //se_data = vec![Value::Valid(1), Value::Valid(2), Value::Null, Value::Valid(4), Value::Null];
    //let mut data: Vec<T> = vec![true,false];
    //iamerejh

    // Process the data as needed
    /*
    for val in data {
        match val {
            Value::Valid(v) => {
                println!("Valid value: {}", v);
                // Handle valid value
            }
            Value::Null => {
                println!("Null value");
                // Handle null value
            }
        }
    }
    */
    println!("ho");

    //Box::into_raw(Box::new(SeriesC::new(se_name, data)))
    Box::into_raw(Box::new(SeriesC::new(se_name, se_data)))
}

#[no_mangle]
pub extern "C" fn se_new_xxx( 
    name: *const c_char, 
    v_ptr: *const bool, 
    v_len: size_t, 
    d_ptr: *const i32, 
    d_len: size_t, 
) -> *mut SeriesC { 
    xxx(name, v_ptr, v_len) 
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
    let se_c = check_ptr(ptr);
    se_c.show();
}

#[no_mangle]
pub extern "C" fn se_head(ptr: *mut SeriesC) {
    let se_c = check_ptr(ptr);
    se_c.head();
}

#[no_mangle]
pub extern "C" fn se_dtype(ptr: *mut SeriesC, retline: RetLine) {
    let se_c = check_ptr(ptr);
    se_c.dtype(retline);
}

#[no_mangle]
pub extern "C" fn se_name(ptr: *mut SeriesC, retline: RetLine) {
    let se_c = check_ptr(ptr);
    se_c.name(retline);
}

#[no_mangle]
pub extern "C" fn se_rename(
    ptr: *mut SeriesC,
    name: *const c_char,
) -> *mut SeriesC { 
    let se_c = check_ptr(ptr);

    let name = unsafe {
        CStr::from_ptr(name).to_string_lossy().into_owned()
    };

    se_c.rename(name);
    se_c
}

#[no_mangle]
pub extern "C" fn se_len(ptr: *mut SeriesC) -> u32 {
    let se_c = check_ptr(ptr);
    se_c.len()
}

#[no_mangle]
pub extern "C" fn se_get_bool(ptr: *mut SeriesC, res: *mut bool, len: size_t ) {
    let se_c = check_ptr(ptr);
    se_c.get_bool(res, len)
}
#[no_mangle]
pub extern "C" fn se_get_i32(ptr: *mut SeriesC, res: *mut i32, len: size_t ) {
    let se_c = check_ptr(ptr);
    se_c.get_i32(res, len)
}
#[no_mangle]
pub extern "C" fn se_get_i64(ptr: *mut SeriesC, res: *mut i64, len: size_t ) {
    let se_c = check_ptr(ptr);
    se_c.get_i64(res, len)
}
#[no_mangle]
pub extern "C" fn se_get_u32(ptr: *mut SeriesC, res: *mut u32, len: size_t ) {
    let se_c = check_ptr(ptr);
    se_c.get_u32(res, len)
}
#[no_mangle]
pub extern "C" fn se_get_u64(ptr: *mut SeriesC, res: *mut u64, len: size_t ) {
    let se_c = check_ptr(ptr);
    se_c.get_u64(res, len)
}
#[no_mangle]
pub extern "C" fn se_get_f32(ptr: *mut SeriesC, res: *mut f32, len: size_t ) {
    let se_c = check_ptr(ptr);
    se_c.get_f32(res, len)
}
#[no_mangle]
pub extern "C" fn se_get_f64(ptr: *mut SeriesC, res: *mut f64, len: size_t ) {
    let se_c = check_ptr(ptr);
    se_c.get_f64(res, len)
}

#[no_mangle]
pub extern "C" fn se_get_u8(ptr: *mut SeriesC, res: *mut u8, len: size_t ) {
    let se_c = check_ptr(ptr);
    se_c.get_u8(res, len)
}

#[no_mangle]
pub extern "C" fn se_str_lengths(ptr: *mut SeriesC) -> u32 {
    let se_c = check_ptr(ptr);
    se_c.str_lengths()
}

#[no_mangle]
pub extern "C" fn se_append(
    l_ptr: *mut SeriesC,
    r_ptr: *mut SeriesC,
) -> *mut SeriesC { 
    let l_se_c = check_ptr(l_ptr);
    let r_se_c = check_ptr(r_ptr);

    l_se_c.se = l_se_c.append(r_se_c);
    l_se_c
}

// DataFrame Container

pub fn df_load_csv(spath: &str) -> PolarResult<DataFrame> {
    let fpath = Path::new(spath);
    let file = File::open(fpath).expect("Cannot open file.");

    CsvReader::new(file)
    .has_header(true)
    .finish()
}

#[repr(C)]
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

    fn height(&self) -> u32 {
        self.df.height().try_into().unwrap()
    }

    fn width(&self) -> u32 {
        self.df.width().try_into().unwrap()
    }

    fn dtypes(&self, retline: RetLine) {
        let dtypes = self.df.dtypes();

        for dtype in dtypes.iter() {
            let dtype = CString::new(dtype.to_string()).unwrap();
            retline(dtype);
        }
    }

    fn get_column_names(&self, retline: RetLine) {
        let names = self.df.get_column_names();

        for name in names.iter() {
            let name = CString::new(*name).unwrap();
            retline(name);
        }
    }

    fn rename(&mut self, old_name: String, new_name: String) -> DataFrame {
        self.df.rename(&old_name, &new_name).unwrap().clone()
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

    fn drop(&self, string: String) -> DataFrame {
        self.df.drop(&string).unwrap().clone()
    }

    fn vstack(&self, df_c: &DataFrameC) -> DataFrame {
        self.df.vstack(&df_c.df).unwrap().clone()
    }

    fn sort(&self, colvec: Vec::<String>) -> DataFrame {
        self.df.sort(&colvec, true).unwrap().clone()
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
    let df_c = check_ptr(ptr);

    let spath = unsafe {
        CStr::from_ptr(string).to_string_lossy().into_owned()
    };
    df_c.read_csv(spath);
}

#[no_mangle]
pub extern "C" fn df_show(ptr: *mut DataFrameC) {
    let df_c = check_ptr(ptr);
    df_c.show();
}

#[no_mangle]
pub extern "C" fn df_head(ptr: *mut DataFrameC) {
    let df_c = check_ptr(ptr);
    df_c.head();
}

#[no_mangle]
pub extern "C" fn df_height(ptr: *mut DataFrameC) -> u32 {
    let df_c = check_ptr(ptr);
    df_c.height()
}

#[no_mangle]
pub extern "C" fn df_width(ptr: *mut DataFrameC) -> u32 {
    let df_c = check_ptr(ptr);
    df_c.width()
}

#[no_mangle]
pub extern "C" fn df_dtypes(ptr: *mut DataFrameC, retline: RetLine) {
    let df_c = check_ptr(ptr);
    df_c.dtypes(retline);
}

#[no_mangle]
pub extern "C" fn df_get_column_names(ptr: *mut DataFrameC, retline: RetLine) {
    let df_c = check_ptr(ptr);
    df_c.get_column_names(retline);
}

#[no_mangle]
pub extern "C" fn df_rename(
    ptr: *mut DataFrameC,
    old_name: *const c_char,
    new_name: *const c_char,
) -> *mut DataFrameC { 
    let df_c = check_ptr(ptr);

    let old_name = unsafe {
        CStr::from_ptr(old_name).to_string_lossy().into_owned()
    };
    let new_name = unsafe {
        CStr::from_ptr(new_name).to_string_lossy().into_owned()
    };

    df_c.rename(old_name, new_name);
    df_c
}

#[no_mangle]
pub extern "C" fn df_column(
    ptr: *mut DataFrameC,
    string: *const c_char,
) -> *mut SeriesC {
    let df_c = check_ptr(ptr);

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
    let df_c = check_ptr(ptr);

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
    let df_c = check_ptr(d_ptr);
    let se_c = check_ptr(s_ptr);

    let mut df_n = DataFrameC::new();
    df_n.df = df_c.with_column(se_c.se.clone());
    Box::into_raw(Box::new(df_n))
}

#[no_mangle]
pub extern "C" fn df_drop(
    d_ptr: *mut DataFrameC,
    string: *const c_char,
) -> *mut DataFrameC {
    let df_c = check_ptr(d_ptr);

    let colname = unsafe {
        CStr::from_ptr(string).to_string_lossy().into_owned()
    };

    let mut df_n = DataFrameC::new();
    df_n.df = df_c.drop(colname);
    Box::into_raw(Box::new(df_n))
}

#[no_mangle]
pub extern "C" fn df_vstack(
    l_ptr: *mut DataFrameC,
    r_ptr: *mut DataFrameC,
) -> *mut DataFrameC {
    let df_l = check_ptr(l_ptr);
    let df_r = check_ptr(r_ptr);
    
    let mut df_n = DataFrameC::new();
    df_n.df = df_l.vstack(df_r);
    Box::into_raw(Box::new(df_n))
}

#[no_mangle]
pub extern "C" fn df_sort(
    ptr: *mut DataFrameC,
    colspec: *const *const c_char,
    len: size_t, 
) -> *mut DataFrameC {
    let df_c = check_ptr(ptr);

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

// LazyFrame Container

#[repr(C)]
pub struct LazyFrameC {
    lf: LazyFrame,
    gb: Option<LazyGroupBy>,
}

impl LazyFrameC {
    fn new(df_c: &mut DataFrameC) -> LazyFrameC {
        LazyFrameC {
            lf: df_c.df.clone().lazy(), 
            gb: None,
        }
    }

    fn collect(&self) -> DataFrameC {
        let df = self.lf.clone().collect().unwrap();
        let mut df_c = DataFrameC::new();
        df_c.df = df;
        df_c
    }

    fn select(&mut self, exprvec: Vec::<Expr>) {
        self.lf = self.lf.clone().select(exprvec);
    }

    fn with_columns(&mut self, exprvec: Vec::<Expr>) {
        self.lf = self.lf.clone().with_columns(exprvec);
    }

    fn filter(&mut self, exprvec: Vec::<Expr>) {
        self.lf = self.lf.clone().filter(exprvec[0].clone());
    }

    fn groupby(&mut self, colvec: Vec::<String>) {
        let colrefs: Vec<&str> = colvec.iter().map(AsRef::as_ref).collect();
        self.gb = Some(self.lf.clone().groupby(colrefs));
    }

    fn agg(&mut self, exprvec: Vec::<Expr>) {
        self.lf = self.gb.clone().unwrap().agg(exprvec);
    }

    fn join(&self, 
        lf_c: &LazyFrameC,
        l_colvec: Vec::<Expr>,
        r_colvec: Vec::<Expr>,
        jointype: &str 
    ) -> DataFrameC {
        let mut df_c = DataFrameC::new();
        match jointype {
            "Left"  => 
                { df_c.df = self.lf.clone().join(
                    lf_c.lf.clone(), l_colvec, r_colvec, JoinType::Left
                ).collect().unwrap(); ()},
            "Inner"  => 
                { df_c.df = self.lf.clone().join(
                    lf_c.lf.clone(), l_colvec, r_colvec, JoinType::Inner
                ).collect().unwrap(); ()},
            "Outer"  => 
                { df_c.df = self.lf.clone().join(
                    lf_c.lf.clone(), l_colvec, r_colvec, JoinType::Outer
                ).collect().unwrap(); ()},
            //"Asof"  => 
            //    { df_c.df = self.lf.clone().join(
            //        lf_c.lf.clone(), l_colvec, r_colvec, JoinType::Asof
            //    ).collect().unwrap(); ()},
            "Cross"  => 
                { df_c.df = self.lf.clone().join(
                    lf_c.lf.clone(), l_colvec, r_colvec, JoinType::Cross
                ).collect().unwrap(); ()},
            _      => (),
        }
        df_c
    }
}

// extern functions for LazyFrame Container
#[no_mangle]
pub extern "C" fn lf_new(ptr: *mut DataFrameC) -> *mut LazyFrameC {
    let df_c = check_ptr(ptr);
    Box::into_raw(Box::new(LazyFrameC::new(df_c)))
}

#[no_mangle]
pub extern "C" fn lf_free(ptr: *mut LazyFrameC) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        Box::from_raw(ptr);
    }
}

#[no_mangle]
pub extern "C" fn lf_collect(ptr: *mut LazyFrameC) -> *mut DataFrameC {
    let lf_c = check_ptr(ptr);
    Box::into_raw(Box::new(lf_c.collect()))
}

#[no_mangle]
pub extern "C" fn lf_select(
    ptr: *mut LazyFrameC,
    exprarr: *const &ExprC,
    len: size_t, 
) {
    let lf_c = check_ptr(ptr);

    let mut exprvec = Vec::<&ExprC>::new();
    unsafe {
        for item in slice::from_raw_parts(exprarr, len as usize) {
            exprvec.push(item);
        };
    };

    lf_c.select(exprvec.to_exprs());
}

#[no_mangle]
pub extern "C" fn lf_with_columns(
    ptr: *mut LazyFrameC,
    exprarr: *const &ExprC,
    len: size_t, 
) {
    let lf_c = check_ptr(ptr);

    let mut exprvec = Vec::<&ExprC>::new();
    unsafe {
        for item in slice::from_raw_parts(exprarr, len as usize) {
            exprvec.push(item);
        };
    };

    lf_c.with_columns(exprvec.to_exprs());
}

#[no_mangle]
pub extern "C" fn lf_filter(
    ptr: *mut LazyFrameC,
    exprarr: *const &ExprC,
    len: size_t, 
) {
    let lf_c = check_ptr(ptr);

    let mut exprvec = Vec::<&ExprC>::new();
    unsafe {
        for item in slice::from_raw_parts(exprarr, len as usize) {
            exprvec.push(item);
        };
    };

    lf_c.filter(exprvec.to_exprs());
}

#[no_mangle]
pub extern "C" fn lf_groupby(
    ptr: *mut LazyFrameC,
    colspec: *const *const c_char,
    len: size_t, 
) {
    let lf_c = check_ptr(ptr);

    let mut colvec = Vec::<String>::new();
    unsafe {
        assert!(!colspec.is_null());

        for item in slice::from_raw_parts(colspec, len as usize) {
            colvec.push(CStr::from_ptr(*item).to_string_lossy().into_owned());
        };
    };

    lf_c.groupby(colvec);
}

#[no_mangle]
pub extern "C" fn lf_agg(
    ptr: *mut LazyFrameC,
    exprarr: *const &ExprC,
    len: size_t, 
) {
    let lf_c = check_ptr(ptr);

    let mut exprvec = Vec::<&ExprC>::new();
    unsafe {
        for item in slice::from_raw_parts(exprarr, len as usize) {
            exprvec.push(item);
        };
    };

    lf_c.agg(exprvec.to_exprs());
}

#[no_mangle]
pub extern "C" fn lf_join(
    l_ptr: *mut LazyFrameC,
    r_ptr: *mut LazyFrameC,
    l_colarr: *const &ExprC,
    l_len: size_t, 
    r_colarr: *const &ExprC,
    r_len: size_t,
    string: *const c_char
) -> *mut DataFrameC {
    let lf_l = check_ptr(l_ptr);
    let lf_r = check_ptr(r_ptr);

    let mut l_colvec = Vec::<&ExprC>::new();
    unsafe {
        for item in slice::from_raw_parts(l_colarr, l_len as usize) {
            l_colvec.push(item);
        };
    };
    let mut r_colvec = Vec::<&ExprC>::new();
    unsafe {
        for item in slice::from_raw_parts(r_colarr, r_len as usize) {
            r_colvec.push(item);
        };
    };
    let jointype = unsafe {
        CStr::from_ptr(string).to_string_lossy().into_owned()
    };

    Box::into_raw(Box::new(lf_l.join(lf_r, l_colvec.to_exprs(), r_colvec.to_exprs(), &jointype)))
}

// Expressions
// these from nodejs lazy/dsl.rs...

#[repr(C)]
pub struct ExprC {
    pub inner: dsl::Expr,
}

pub trait ToExprs {
    fn to_exprs(self) -> Vec<Expr>;
}

impl ExprC {
    fn new(inner: dsl::Expr) -> ExprC {
        ExprC { inner }
    }    
}
impl From<dsl::Expr> for ExprC {
    fn from(s: dsl::Expr) -> ExprC {
        ExprC::new(s)
    }    
}

impl ToExprs for Vec<ExprC> {
    fn to_exprs(self) -> Vec<Expr> {
        // Safety
        // repr is transparent
        // and has only got one inner field`
        unsafe { std::mem::transmute(self) }
    }    
}
impl ToExprs for Vec<&ExprC> {
    fn to_exprs(self) -> Vec<Expr> {
        self.into_iter()
            .map(|e| e.inner.clone())
            .collect::<Vec<Expr>>()
    }    
}

impl ExprC {
    fn alias(&self, string: String ) -> ExprC {
        self.clone().inner.clone().alias(&string).into()
    }

    fn sum(&self) -> ExprC {
        self.clone().inner.clone().sum().into()
    }

    fn mean(&self) -> ExprC {
        self.clone().inner.clone().mean().into()
    }

    fn min(&self) -> ExprC {
        self.clone().inner.clone().min().into()
    }

    fn max(&self) -> ExprC {
        self.clone().inner.clone().max().into()
    }

    fn first(&self) -> ExprC {
        self.clone().inner.clone().first().into()
    }

    fn last(&self) -> ExprC {
        self.clone().inner.clone().last().into()
    }

    fn unique(&self) -> ExprC {
        self.clone().inner.clone().unique().into()
    }

    fn count(&self) -> ExprC {
        self.clone().inner.clone().count().into()
    }

    fn forward_fill(&self) -> ExprC {
        self.clone().inner.clone().forward_fill(None).into()
    }

    fn backward_fill(&self) -> ExprC {
        self.clone().inner.clone().backward_fill(None).into()
    }

    fn reverse(&self) -> ExprC {
        self.clone().inner.clone().reverse().into()
    }

    fn sort(&self) -> ExprC {
        self.clone().inner.clone().sort(false).into()
    }

    fn std(&self) -> ExprC {
        self.clone().inner.clone().std().into()
    }

    fn var(&self) -> ExprC {
        self.clone().inner.clone().var().into()
    }

    fn exclude(&self, colvec: Vec::<String>) -> ExprC {
        self.clone().inner.clone().exclude(colvec).into()
    }

    fn __add__(&self, rhs: &ExprC) -> ExprC {
        dsl::binary_expr(self.inner.clone(), Operator::Plus, rhs.inner.clone()).into()
    }

    fn __sub__(&self, rhs: &ExprC) -> ExprC {
        dsl::binary_expr(self.inner.clone(), Operator::Minus, rhs.inner.clone()).into()
    }

    fn __mul__(&self, rhs: &ExprC) -> ExprC {
        dsl::binary_expr(self.inner.clone(), Operator::Multiply, rhs.inner.clone()).into()
    }

    fn __div__(&self, rhs: &ExprC) -> ExprC {
        dsl::binary_expr(self.inner.clone(), Operator::TrueDivide, rhs.inner.clone()).into()
    }

    fn __mod__(&self, rhs: &ExprC) -> ExprC {
        dsl::binary_expr(self.inner.clone(), Operator::Modulus, rhs.inner.clone()).into()
    }

    fn __floordiv__(&self, rhs: &ExprC) -> ExprC {
        dsl::binary_expr(self.inner.clone(), Operator::Divide, rhs.inner.clone()).into()
    }

    fn __gt__(&self, other: &ExprC) -> ExprC {
        self.clone().inner.clone().gt(other.inner.clone()).into()
    }

    fn __lt__(&self, other: &ExprC) -> ExprC {
        self.clone().inner.clone().lt(other.inner.clone()).into()
    }

    fn __ge__(&self, other: &ExprC) -> ExprC {
        self.clone().inner.clone().gt_eq(other.inner.clone()).into()
    }

    fn __le__(&self, other: &ExprC) -> ExprC {
        self.clone().inner.clone().lt_eq(other.inner.clone()).into()
    }

    fn __eq__(&self, other: &ExprC) -> ExprC {
        self.clone().inner.clone().eq(other.inner.clone()).into()
    }

    fn __ne__(&self, other: &ExprC) -> ExprC {
        self.clone().inner.clone().neq(other.inner.clone()).into()
    }

    fn __and__(&self, other: &ExprC) -> ExprC {
        self.clone().inner.clone().and(other.inner.clone()).into()
    }

    fn __or__(&self, other: &ExprC) -> ExprC {
        self.clone().inner.clone().or(other.inner.clone()).into()
    }

    fn is_not(&self) -> ExprC {
        self.clone().inner.clone().not().into()
    }

    fn is_null(&self) -> ExprC {
        self.clone().inner.clone().is_null().into()
    }

    fn is_not_null(&self) -> ExprC {
        self.clone().inner.clone().is_not_null().into()
    }

    fn is_infinite(&self) -> ExprC {
        self.clone().inner.clone().is_infinite().into()
    }

    fn is_finite(&self) -> ExprC {
        self.clone().inner.clone().is_finite().into()
    }

    fn is_nan(&self) -> ExprC {
        self.clone().inner.clone().is_nan().into()
    }

    fn is_not_nan(&self) -> ExprC {
        self.clone().inner.clone().is_not_nan().into()
    }
}

//col() is the extern for new()
#[no_mangle]
pub extern "C" fn ex_col(string: *const c_char) -> *mut ExprC {
    let colname = unsafe {
        CStr::from_ptr(string).to_string_lossy().into_owned()
    };

    let ex_c = ExprC::new(col(&colname));
    Box::into_raw(Box::new(ex_c))
}

#[no_mangle]
pub extern "C" fn ex_struct(
    colspec: *const *const c_char,
    len: size_t,
) -> *mut ExprC {

    let mut colvec = Vec::<String>::new();
    unsafe {
        assert!(!colspec.is_null());

        for item in slice::from_raw_parts(colspec, len as usize) {
            colvec.push(CStr::from_ptr(*item).to_string_lossy().into_owned());
        };
    };

    let mut exprvec: Vec<Expr> = Vec::new();
    
    for item in colvec {
        exprvec.push(ExprC::new(col(&item.clone())).inner);
    };

    let ex_c = ExprC::new(as_struct(&exprvec));
    Box::into_raw(Box::new(ex_c))
}

#[no_mangle]
pub extern "C" fn ex_lit_bool(val: bool) -> *mut ExprC {
    let ex_c = ExprC::new(lit(val));
    Box::into_raw(Box::new(ex_c))
}

#[no_mangle]
pub extern "C" fn ex_lit_i32(val: i32) -> *mut ExprC {
    let ex_c = ExprC::new(lit(val));
    Box::into_raw(Box::new(ex_c))
}

#[no_mangle]
pub extern "C" fn ex_lit_i64(val: i64) -> *mut ExprC {
    let ex_c = ExprC::new(lit(val));
    Box::into_raw(Box::new(ex_c))
}

#[no_mangle]
pub extern "C" fn ex_lit_u32(val: u32) -> *mut ExprC {
    let ex_c = ExprC::new(lit(val));
    Box::into_raw(Box::new(ex_c))
}

#[no_mangle]
pub extern "C" fn ex_lit_u64(val: u64) -> *mut ExprC {
    let ex_c = ExprC::new(lit(val));
    Box::into_raw(Box::new(ex_c))
}

#[no_mangle]
pub extern "C" fn ex_lit_f32(val: f32) -> *mut ExprC {
    let ex_c = ExprC::new(lit(val));
    Box::into_raw(Box::new(ex_c))
}

#[no_mangle]
pub extern "C" fn ex_lit_f64(val: f64) -> *mut ExprC {
    let ex_c = ExprC::new(lit(val));
    Box::into_raw(Box::new(ex_c))
}

#[no_mangle]
pub extern "C" fn ex_lit_str( 
    string: *const c_char,
) -> *mut ExprC {

    let strval = unsafe {
        CStr::from_ptr(string).to_string_lossy().into_owned()
    };

    let ex_c = ExprC::new(lit(strval));
    Box::into_raw(Box::new(ex_c))
}

#[no_mangle]
pub extern "C" fn ex_alias(
    ptr: *mut ExprC,
    string: *const c_char,
) -> *mut ExprC {
    let ex_c = check_ptr(ptr);

    let colname = unsafe {
        CStr::from_ptr(string).to_string_lossy().into_owned()
    };

    Box::into_raw(Box::new(ex_c.alias(colname)))
}

#[no_mangle]
pub extern "C" fn ex_free(ptr: *mut ExprC) {
    if ptr.is_null() {
        return;
    }
    unsafe {
        Box::from_raw(ptr);
    }
}

#[no_mangle]
pub extern "C" fn ex_sum(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.sum()))
}

#[no_mangle]
pub extern "C" fn ex_mean(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.mean()))
}

#[no_mangle]
pub extern "C" fn ex_min(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.min()))
}

#[no_mangle]
pub extern "C" fn ex_max(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.max()))
}

#[no_mangle]
pub extern "C" fn ex_first(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.first()))
}

#[no_mangle]
pub extern "C" fn ex_unique(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.unique()))
}

#[no_mangle]
pub extern "C" fn ex_last(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.last()))
}

#[no_mangle]
pub extern "C" fn ex_count(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.count()))
}

#[no_mangle]
pub extern "C" fn ex_forward_fill(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.forward_fill()))
}

#[no_mangle]
pub extern "C" fn ex_backward_fill(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.backward_fill()))
}

#[no_mangle]
pub extern "C" fn ex_sort(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.sort()))
}

#[no_mangle]
pub extern "C" fn ex_reverse(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.reverse()))
}

#[no_mangle]
pub extern "C" fn ex_std(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.std()))
}

#[no_mangle]
pub extern "C" fn ex_var(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.var()))
}

#[no_mangle]
pub extern "C" fn ex_exclude(
    ptr: *mut ExprC,
    colspec: *const *const c_char,
    len: size_t,
) -> *mut ExprC {
    let ex_c = check_ptr(ptr);

    let mut colvec = Vec::<String>::new();
    unsafe {
        assert!(!colspec.is_null());

        for item in slice::from_raw_parts(colspec, len as usize) {
            colvec.push(CStr::from_ptr(*item).to_string_lossy().into_owned());
        };
    };

    Box::into_raw(Box::new(ex_c.exclude(colvec)))
}

#[no_mangle]
pub extern "C" fn ex__add__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__add__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__sub__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__sub__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__mul__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__mul__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__div__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__div__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__mod__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__mod__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__floordiv__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__floordiv__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__gt__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__gt__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__lt__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__lt__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__ge__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__ge__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__le__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__le__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__eq__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__eq__(ex_r)))
}
#[no_mangle]
pub extern "C" fn ex__ne__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__ne__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__and__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__and__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex__or__(ptr: *mut ExprC, rhs: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    let ex_r = check_ptr(rhs);

    Box::into_raw(Box::new(ex_c.__or__(ex_r)))
}

#[no_mangle]
pub extern "C" fn ex_is_not(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.is_not()))
}

#[no_mangle]
pub extern "C" fn ex_is_null(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.is_null()))
}
#[no_mangle]
pub extern "C" fn ex_is_not_null(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.is_not_null()))
}

#[no_mangle]
pub extern "C" fn ex_is_infinite(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.is_infinite()))
}

#[no_mangle]
pub extern "C" fn ex_is_finite(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.is_finite()))

}
#[no_mangle]
pub extern "C" fn ex_is_nan(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.is_nan()))
}

#[no_mangle]
pub extern "C" fn ex_is_not_nan(ptr: *mut ExprC) -> *mut ExprC {
    let ex_c = check_ptr(ptr);
    Box::into_raw(Box::new(ex_c.is_not_nan()))
}
