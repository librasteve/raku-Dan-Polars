extern crate libloading;

use std::env;
use libloading::{Library, Symbol};

type AddFunc = fn(isize, isize) -> isize;

fn main() {
    let library_path = env::args().nth(1).expect("USAGE: loading <LIB>");
    println!("Loading addd() from {}", library_path);

    unsafe {
        let lib = Library::new(library_path).unwrap();

        let func: Symbol<AddFunc> = lib.get(b"add").unwrap();

        let answer = func(1, 2);
        println!("1 + 2 = {}", answer);
    }
}

