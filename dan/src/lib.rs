use libc::c_char;
use libc::size_t;
use std::slice;
use std::ffi::*; //{CStr, CString,}
use std::fs::File;
use std::io::Write;
use std::path::{Path};

use polars::prelude::*;//{CsvReader, DataType, DataFrame, Series};
use polars::prelude::{Result as PolarResult};

// these from nodejs lazy/dsl.rs
use polars::lazy::dsl;
use polars::lazy::dsl::Expr;
//use polars::lazy::dsl::Operator;
//use polars_core::series::ops::NullBehavior;
//use std::borrow::Cow;


//use polars_lazy::prelude::*;
//use polars_core::prelude::*;

// Callback Types

type RetLine = extern fn(line: *const u8);

// these from nodejs lazy/dsl.rs
// Expressions

pub struct ExprC {
    pub inner: dsl::Expr,
}

//pub(crate) trait ToExprs {
//    fn to_exprs(self) -> Vec<Expr>;
//}

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

//impl ToExprs for Vec<ExprC> {
//    fn to_exprs(self) -> Vec<Expr> {
//        // Safety
//        // repr is transparent
//        // and has only got one inner field`
//        unsafe { std::mem::transmute(self) }
//    }    
//}
//impl ToExprs for Vec<&ExprC> {
//    fn to_exprs(self) -> Vec<Expr> {
//        self.into_iter()
//            .map(|e| e.inner.clone())
//            .collect::<Vec<Expr>>()
//    }    
//}

impl ExprC {
    fn sum(&self) -> ExprC {
        self.clone().inner.clone().sum().into()
    }
}

#[no_mangle]
pub extern "C" fn ex_col(
    string: *const c_char,
) -> *mut ExprC {

    let colname = unsafe {
        CStr::from_ptr(string).to_string_lossy().into_owned()
    };

    let ex_c = ExprC::new(col(&colname));
    Box::into_raw(Box::new(ex_c))
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
    let ex_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    Box::into_raw(Box::new(ex_c.sum()))
}

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

    fn rename(&mut self, name: String) {
        self.se.rename(&name);
    }

    fn len(&self) -> u32 {
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
pub extern "C" fn se_rename(
    ptr: *mut SeriesC,
    name: *const c_char,
) {
    let se_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    let name = unsafe {
        CStr::from_ptr(name).to_string_lossy().into_owned()
    };

    se_c.rename(name);
}

#[no_mangle]
pub extern "C" fn se_len(ptr: *mut SeriesC) -> u32 {
    let se_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    se_c.len()
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
            retline(dtype.as_ptr());
        }
    }

    fn get_column_names(&self, retline: RetLine) {
        let names = self.df.get_column_names();

        for name in names.iter() {
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
pub extern "C" fn df_height(ptr: *mut DataFrameC) -> u32 {
    let df_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    df_c.height()
}

#[no_mangle]
pub extern "C" fn df_width(ptr: *mut DataFrameC) -> u32 {
    let df_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    df_c.width()
}

#[no_mangle]
pub extern "C" fn df_dtypes(ptr: *mut DataFrameC, retline: RetLine) {
    let df_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    df_c.dtypes(retline);
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

fn str_to_len(str_val: Series) -> Result<Series> {
    let x = str_val
        .utf8()
        .unwrap()
        .into_iter()
        // your actual custom function would be in this map
        .map(|opt_name: Option<&str>| opt_name.map(|name: &str| name.len() as u32))
        .collect::<UInt32Chunked>();
    Ok(x.into_series())
}

// LazyFrame Container

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

    fn sum(&mut self) {
        self.lf = self.lf.clone().sum();
    }

    fn groupby(&mut self, colvec: Vec::<String>) {

        let o = GetOutput::from_type(DataType::UInt32);
        //self.lf = self.lf.clone().with_column(col("variety").apply(str_to_len, o));
        let lf = self.lf.clone().with_column(col("variety").apply(str_to_len, o));
        println!("{:?}", lf.describe_plan());

        //self.lf = self.lf.clone().groupby(["variety"]).agg([col("petal.length").sum()]);
        //self.gb = Some(self.lf.clone().groupby(["variety"]));
        let colrefs: Vec<&str> = colvec.iter().map(AsRef::as_ref).collect();
        self.gb = Some(self.lf.clone().groupby(colrefs));

        //self.lf = self.lf.clone();
        //self.gb = Some(self.lf.groupby(["variety"]));
        //let ret = self.lf.clone().groupby(["variety"]);    // .unwrap()   // .clone()
        //println!("{:?}", self.gb.agg().collect());
        //self.lf.groupby(&colvec);    // .unwrap()   // .clone()
    }

//    fn agg(&mut self) {
//        //let x = col("petal.length").sum();
//        //println!("{:?}", x);
//        let x = col("petal.length");
//        println!("{:?}", x);
//        let y = x.sum();
//        println!("{:?}", y);
//
//        //self.lf = self.gb.clone().unwrap().agg([col("petal.length").sum()]);
//        self.lf = self.gb.clone().unwrap().agg([y]);
//    }
    fn agg(&mut self, exprvec: Vec::<Expr>) {
        self.lf = self.gb.clone().unwrap().agg(exprvec);
    }
}

// extern functions for LazyFrame Container
#[no_mangle]
pub extern "C" fn lf_new(ptr: *mut DataFrameC) -> *mut LazyFrameC {
    let df_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

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
    let lf_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    Box::into_raw(Box::new(lf_c.collect()))
}

#[no_mangle]
pub extern "C" fn lf_sum(
    ptr: *mut LazyFrameC,
) {
    let lf_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    lf_c.sum();
}

#[no_mangle]
pub extern "C" fn lf_groupby(
    ptr: *mut LazyFrameC,
    colspec: *const *const c_char,
    len: size_t, 
) {
    let lf_c = unsafe {
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

    lf_c.groupby(colvec);
}

#[no_mangle]
pub extern "C" fn lf_agg(
    ptr: *mut LazyFrameC,
    expr: *mut ExprC,
) {
    let lf_c = unsafe {
        assert!(!ptr.is_null());
        &mut *ptr
    };

    let ex_c = unsafe {
        assert!(!expr.is_null());
        &mut *expr
    };

    lf_c.agg([ex_c.inner.clone()].to_vec());
}


