unit module Dan::Polars::Containers:ver<0.0.1>:auth<Steve Roe (p6steve@furnival.net)>;

use NativeCall;

### Helper Items

my regex number {
	\S+                     #grab chars
	<?{ +"$/" ~~ Real }>    #assert coerces via '+' to Real
}

sub carray( $dtype, @items ) {
    my $output := CArray[$dtype].new();
    loop ( my $i = 0; $i < @items; $i++ ) {
        $output[$i] = @items[$i]
    }
    $output
}

### Container Classes (CStruct) that interface to Rust lib.rs ###

constant $n-path    = '../dan/target/debug/dan';
constant $vals-file = 'dan-values.txt';

class SeriesC is repr('CPointer') is export {
    sub se_new_bool(Str, CArray[bool],  size_t) returns SeriesC is native($n-path) { * }
    sub se_new_i32(Str, CArray[int32], size_t) returns SeriesC is native($n-path) { * }
    sub se_new_i64(Str, CArray[int64], size_t) returns SeriesC is native($n-path) { * }
    sub se_new_u32(Str, CArray[uint32],size_t) returns SeriesC is native($n-path) { * }
    sub se_new_u64(Str, CArray[uint64],size_t) returns SeriesC is native($n-path) { * }
    sub se_new_f32(Str, CArray[num32], size_t) returns SeriesC is native($n-path) { * }
    sub se_new_f64(Str, CArray[num64], size_t) returns SeriesC is native($n-path) { * }
    sub se_new_str(Str, CArray[Str],   size_t) returns SeriesC is native($n-path) { * }
    sub se_free(SeriesC)   is native($n-path) { * }
    sub se_show(SeriesC)   is native($n-path) { * }
    sub se_head(SeriesC)   is native($n-path) { * }
    sub se_dtype(SeriesC,  &callback (Str --> Str)) is native($n-path) { * }
    sub se_name(SeriesC,   &callback (Str --> Str)) is native($n-path) { * }
    sub se_rename(SeriesC, Str) is native($n-path) { * }
    sub se_len(SeriesC) returns uint32 is native($n-path) { * }
    sub se_values(SeriesC, Str) is native($n-path) { * }
    sub se_get_data(SeriesC) returns CArray[num64] is native($n-path) { * }
    sub se_get_f64(SeriesC, CArray[num64]) is native($n-path) { * }

    method new( $name, @data, :$dtype ) {

        if $dtype {

            @data.map({ $_ .= Num if $_ ~~ Rat});                                               #Coerce stray Rats to Num
            @data.map({ $_ .= Num if $_ ~~ Int}) if $dtype eq <f32 f64 num32 num64 Num>.any;    #Coerce stray Ints to Num

            given $dtype {
                when    'i32' { se_new_i32($name, carray( int32, @data), @data.elems) }
                when    'u32' { se_new_u32($name, carray(uint32, @data), @data.elems) }
                when    'i64' { se_new_i64($name, carray( int64, @data), @data.elems) }
                when    'u64' { se_new_u64($name, carray(uint64, @data), @data.elems) }
                when    'f32' { se_new_f32($name, carray( num32, @data), @data.elems) }
                when    'f64' { se_new_f64($name, carray( num64, @data), @data.elems) }
                when  'int32' { se_new_i32($name, carray( int32, @data), @data.elems) }
                when 'uint32' { se_new_u32($name, carray(uint32, @data), @data.elems) }
                when  'int64' { se_new_i64($name, carray( int64, @data), @data.elems) }
                when 'uint64' { se_new_u64($name, carray(uint64, @data), @data.elems) }
                when  'num32' { se_new_f32($name, carray( num32, @data), @data.elems) }
                when  'num64' { se_new_f64($name, carray( num64, @data), @data.elems) }
                when    'str' { se_new_str($name, carray(   Str, @data), @data.elems) }
                when    'Str' { se_new_str($name, carray(   Str, @data), @data.elems) }
                when   'bool' { se_new_bool($name, carray( bool, @data), @data.elems) }
                when   'Bool' { se_new_bool($name, carray( bool, @data), @data.elems) }
                when    'Int' { se_new_i64($name, carray( int64, @data), @data.elems) }
                when    'Num' { se_new_f64($name, carray( num64, @data), @data.elems) }
                when    'Rat' { die "Rats are not implemented by Polars" }
                when   'Real' { die "Rats are not implemented by Polars" }
            }

        } else {

            given @data.are {
                when Bool {   
                    se_new_bool($name, carray(bool, @data), @data.elems );
                }
                when Int {
                    given @data.min, @data.max {
                        when * > -2**31, * < 2**31-1 { se_new_i32($name, carray( int32, @data), @data.elems) }
                        when * >      0, * < 2**32-1 { se_new_u32($name, carray(uint32, @data), @data.elems) }
                        when * > -2**63, * < 2**63-1 { se_new_i64($name, carray( int64, @data), @data.elems) }
                        when * >      0, * < 2**64-1 { se_new_u64($name, carray(uint64, @data), @data.elems) }
                        default { die "Int larger than 2**64 are not implemented by Polars" }
                    }
                }
                when Real {   
                    @data.map({ $_.=Num }) if @data.are ~~ Real;     #Coerce stray Rats & Ints to Num
                    se_new_f64($name, carray(num64, @data), @data.elems );
                }
                when Str {   
                    se_new_str($name, carray(Str, @data), @data.elems );
                }
            }
        }
    }

    submethod DESTROY {           #Free data when the object is garbage collected.
        se_free(self);
    }

    method show {
        se_show(self)
    }

    method head {
        se_head(self)
    }

    method dtype {
        my $out;
        my &line_out = sub ( $line ) {
            $out := $line
        }

        se_dtype(self, &line_out);
        $out
    }

    method name {
        my $out;
        my &line_out = sub ( $line ) {
            $out := $line
        }

        se_name(self, &line_out);
        $out
    }

    method rename( Str $name ) {
        se_rename(self,$name)
    }

    method len {
        se_len(self)
    }

    method values {
        se_values(self, $vals-file);
        my @values = $vals-file.IO.lines;
        if $.dtype ne <str Str>.any { 
            @values.map({ $_ = +$_ if $_ ~~ /<number>/ });     #convert to narrowest Real type
        }
        @values
    }

#`[
    #get data via carray ptr
    method get-data {
        my @out;
        my &array_out = sub ( @array ) {
            say 'yo';
            dd @array;
            @out := @array 
        }

        se_get_data(self, &array_out);
        @out
    }
#]
    # viz. https://docs.raku.org/language/nativecall#Arrays
    method get-data {
        my $elems = 100;
        my $array = CArray[num64].allocate($elems); # instantiates an array with 10 elements
        se_get_f64(self, $array);
        $array
    }
}

class DataFrameC is repr('CPointer') is export {
    sub df_new() returns DataFrameC  is native($n-path) { * }
    sub df_free(DataFrameC)          is native($n-path) { * }
    sub df_read_csv(DataFrameC, Str) is native($n-path) { * }
    sub df_show(DataFrameC)          is native($n-path) { * }
    sub df_head(DataFrameC)          is native($n-path) { * }
    sub df_height(DataFrameC) returns uint32 is native($n-path) { * }
    sub df_width(DataFrameC) returns uint32 is native($n-path) { * }
    sub df_dtypes(DataFrameC, &callback (Str)) is native($n-path) { * }
    sub df_get_column_names(DataFrameC, &callback (Str)) is native($n-path) { * }
    sub df_column(DataFrameC, Str) returns SeriesC is native($n-path) { * }
    sub df_select(DataFrameC, CArray[Str], size_t) returns DataFrameC is native($n-path) { * }
    sub df_with_column(DataFrameC, SeriesC) returns DataFrameC is native($n-path) { * }
    sub df_query(DataFrameC) returns DataFrameC is native($n-path) { * }

    method new {
        df_new
    }

    submethod DESTROY {              #Free data when the object is garbage collected.
        df_free(self);
    }

    method read_csv( Str \path ) {
        df_read_csv(self, path);
    }

    method show {
        df_show(self)
    }

    method head {
        df_head(self)
    }

    method height {
        df_height(self)
    }

    method width {
        df_width(self)
    }

    method dtypes {
        my @out;
        my &line_out = sub ( $line ) {
            @out.push: $line;
        }

        df_dtypes(self, &line_out);
        @out
    }

    method get_column_names {
        my @out;
        my &line_out = sub ( $line ) {
            @out.push: $line;
        }

        df_get_column_names(self, &line_out);
        @out
    }

    method column( Str \colname ) {
        my $cont = df_column(self, colname);
        ( $cont.name, $cont.dtype, $cont.values )
    }

    method select( Array \colspec ) {
        df_select(self, carray( Str, colspec ), colspec.elems)
    }

    method with_column( SeriesC \column ) {
        df_with_column(self, column)
    }

    method query {
        df_query(self)
    }
}

class LazyFrameC is repr('CPointer') is export {
    sub lf_new(DataFrameC)         returns LazyFrameC  is native($n-path) { * }
    sub lf_free(LazyFrameC)                            is native($n-path) { * }
    sub lf_select(LazyFrameC, CArray[Pointer], size_t) is native($n-path) { * }
    sub lf_with_columns(LazyFrameC, CArray[Pointer], size_t) is native($n-path) { * }
    sub lf_groupby(LazyFrameC, CArray[Str], size_t)    is native($n-path) { * }
    sub lf_agg(LazyFrameC, CArray[Pointer], size_t)    is native($n-path) { * }
    sub lf_collect(LazyFrameC)     returns DataFrameC  is native($n-path) { * }

    method new( DataFrameC \df_c ) {
        lf_new( df_c )
    }

    submethod DESTROY {              #Free data when the object is garbage collected.
        lf_free(self);
    }

    method select( Array \exprvec ) {
        lf_select(self, carray( Pointer, exprvec ), exprvec.elems)
    }

    method with_columns( Array \exprvec ) {
        lf_with_columns(self, carray( Pointer, exprvec ), exprvec.elems)
    }

    method collect {
        lf_collect(self)
    }

    method groupby( Array \colspec ) {
        lf_groupby(self, carray( Str, colspec ), colspec.elems)
    }

    method agg( Array \exprvec ) {
        lf_agg(self, carray( Pointer, exprvec ), exprvec.elems)
    }
}

class ExprC is repr('CPointer') is export {
    sub ex_new()                 returns ExprC is native($n-path) { * }
    sub ex_free(ExprC)                         is native($n-path) { * }
    sub ex_col(Str)              returns ExprC is native($n-path) { * }
    sub ex_alias(ExprC,Str)      returns ExprC is native($n-path) { * }
    sub ex_sum(ExprC)            returns ExprC is native($n-path) { * }
    sub ex_mean(ExprC)           returns ExprC is native($n-path) { * }
    sub ex_min(ExprC)            returns ExprC is native($n-path) { * }
    sub ex_max(ExprC)            returns ExprC is native($n-path) { * }
    sub ex_first(ExprC)          returns ExprC is native($n-path) { * }
    sub ex_last(ExprC)           returns ExprC is native($n-path) { * }
    sub ex_unique(ExprC)         returns ExprC is native($n-path) { * }
    sub ex_count(ExprC)          returns ExprC is native($n-path) { * }
    sub ex_forward_fill(ExprC)   returns ExprC is native($n-path) { * }
    sub ex_backward_fill(ExprC)  returns ExprC is native($n-path) { * }
    sub ex_reverse(ExprC)        returns ExprC is native($n-path) { * }
    sub ex_sort(ExprC)           returns ExprC is native($n-path) { * }
    sub ex_std(ExprC)            returns ExprC is native($n-path) { * }
    sub ex_var(ExprC)            returns ExprC is native($n-path) { * }
    sub ex_exclude(ExprC,CArray[Str], size_t) returns ExprC is native($n-path) { * }

    method new {
        ex_new
    }

    submethod DESTROY {              #Free data when the object is garbage collected.
        ex_free(self)
    }

    method col( Str \colname ) {
        ex_col(colname)
    }

    method alias( Str \colname ) {
        ex_alias(self, colname)
    }

    method sum {
        ex_sum(self)
    }

    method mean {
        ex_mean(self)
    }

    method min {
        ex_min(self)
    }

    method max {
        ex_max(self)
    }

    method first {
        ex_first(self)
    }

    method last {
        ex_last(self)
    }

    method unique {
        ex_unique(self)
    }

    method count {
        ex_count(self)
    }

    method elems {
        ex_count(self)
    }

    method forward_fill {
        ex_forward_fill(self)
    }

    method backward_fill {
        ex_backward_fill(self)
    }

    method reverse {
        ex_reverse(self)
    }

    method sort {
        ex_sort(self)
    }

    method std {
        ex_std(self)
    }

    method var {
        ex_var(self)
    }

    method exclude( Array \colspec ) {
        ex_exclude(self, carray( Str, colspec ), colspec.elems)
    }
}

