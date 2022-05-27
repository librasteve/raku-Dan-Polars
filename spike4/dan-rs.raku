use NativeCall; 

constant $n-path = './dan/target/debug/dan';

sub str2rust(Str is encoded('utf8')) is native($n-path) {*};
str2rust("hey");

sub str2raku() returns Pointer[Str] is native($n-path) {*};
say str2raku.deref;

sub df_read_csv(Str is encoded('utf8')) is native($n-path) {*};
df_read_csv("./dan/src/iris.csv");

sub add (int32, int32) returns int32 is native($n-path) { * };  
say add(1, 2); 

