extern crate libloading;

use libloading::{Library, Symbol};

type AddFunc = fn(isize, isize) -> isize;

fn main() {
    unsafe {
        let lib = Library::new("./libadder.so").unwrap();

        let func: Symbol<AddFunc> = lib.get(b"add").unwrap();

        let answer = func(1, 2);
        println!("1 + 2 = {}", answer);
    }
}

