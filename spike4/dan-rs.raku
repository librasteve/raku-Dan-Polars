use NativeCall; 

constant $n-path = './dan/target/debug/dan';

sub str2rust(Str is encoded('utf8')) is native($n-path) {*};
str2rust("/root/raku-Dan-Polars/spike2/pl_so/src/iris.csv");

sub str2raku() returns Pointer[Str] is native($n-path) {*};
say str2raku.deref;

sub add (int32, int32) returns int32 is native($n-path) { * };  
say add(1, 2); 

