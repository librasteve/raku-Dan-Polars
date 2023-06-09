#[no_mangle]
pub extern "C" fn add(a: isize, b: isize) -> isize {
    println!("yo babay");
    a + b 
}

#[no_mangle]
pub extern "C" fn cod( a: i32 ) -> i32 {
    (a + 42) as i32
}
