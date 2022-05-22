use NativeCall; 

#cp PATHTO/libdan_polars.so /usr/lib (or use path)
#sub add (int32, int32) returns int32 is native('dan-polars') { * }; 

sub add (int32, int32) returns int32 is native('./dan-polars/src/dan_polars') { * }; 

say add(1, 2);
