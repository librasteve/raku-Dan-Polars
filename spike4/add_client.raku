use NativeCall; 

#cp add_dll/src/libadd.so /usr/lib (or use path)
#sub add (int32, int32) returns int32 is native('add') { * }; 

sub add (int32, int32) returns int32 is native('./add_dll/src/add') { * }; 

say add(1, 2);

#`[
class CFoo is repr('CStruct') {
    #has int32    $.sa_family;
    #has Str      $.sa_data;
}

sub foo_new ( ) returns CFoo is native('add') { * }
say foo_new;
#]
