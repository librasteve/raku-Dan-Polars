use NativeCall; 

constant $n-path = './dan/target/debug/foo';

sub add (int32, int32) returns int32 is native($n-path) { * };  

say add(1, 2); 
