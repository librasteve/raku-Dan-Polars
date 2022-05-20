#![crate_type = "dylib"]
use std::ffi::*;
//use std::ffi::c_void;
//use std::os::raw::c_void;
 
// compile with: rustc add.rs
 
#[no_mangle]
pub extern "C" fn add(a:i32, b:i32) -> i32 {
    a+b
}

type CFoo = c_void;

#[no_mangle]
pub extern "C" fn foo_new(_class const i8) -> mut CFoo {
    Box::into_raw(Box::new(Foo::new())) as mut CFoo
}

//#[no_mangle]
//pub extern "C" fn foo_method1(f: *mut CFoo) {
//    let f = unsafe { &*(f as *mut Foo) };
//    f.method1();
//}
//
//#[allow(non_snake_case)]
//#[no_mangle]
//pub extern "C" fn foo_DESTROY(f: *mut CFoo) {
//    unsafe { drop(Box::from_raw(f as *mut Foo)) };
//}
