use NativeCall; 

constant $n-path = './dan/target/debug/dan';

sub add (int32, int32) returns int32 is native($n-path) { * };  
say add(1, 2); 

sub xxx(Str is encoded('utf8')) is native($n-path) {*};
xxx("/root/raku-Dan-Polars/spike2/pl_so/src/iris.csv");
