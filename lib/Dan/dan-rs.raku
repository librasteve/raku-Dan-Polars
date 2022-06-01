use NativeCall; 

constant $n-path = '../../dan/target/debug/dan';

class Series is repr('CPointer') {
    sub se_new() returns Series  is native($n-path) { * }
    sub se_free(Series)          is native($n-path) { * }
    sub se_head(Series)          is native($n-path) { * }

    method new { 
        se_new 
    }

    submethod DESTROY { #Free data when the object is garbage collected.
        se_free(self);
    }

    method head { 
        se_head(self) 
    }
}

my \se = Series.new;
se.head;

sub prep-carray-str( @items where .are ~~ Str --> CArray ) {
    my @output := CArray[Str].new();
    @output[$++] = $_ for @items;
    @output;
}

class DataFrame is repr('CPointer') {
    sub df_new() returns DataFrame  is native($n-path) { * }
    sub df_free(DataFrame)          is native($n-path) { * }
    sub df_read_csv(DataFrame, Str) is native($n-path) { * }
    sub df_head(DataFrame)          is native($n-path) { * }
    sub df_column(DataFrame, Str) returns Series is native($n-path) { * }
    sub df_select(DataFrame, CArray[Str], size_t) returns DataFrame is native($n-path) { * }

    method new { 
        df_new 
    }

    submethod DESTROY { #Free data when the object is garbage collected.
        df_free(self);
    }

    method read_csv( Str \path ) {
        df_read_csv(self, path);
    }

    method head { 
        df_head(self) 
    }

    method column( Str \colname ) { 
        df_column(self, colname) 
    }

    method select( Array \colspec ) { 
        df_select(self, prep-carray-str( colspec ), colspec.elems)
    }
}

my \df = DataFrame.new;
df.read_csv("../../dan/src/iris.csv");
df.head;
my $se-sl = df.column("sepal.length");
$se-sl.head;

dd my $selection = df.select(["sepal.length", "variety"]);
$selection.head;

#-----------------------------------------------------------------------------

## Rust FFI Omnibus: Slice Arguments
sub sum_of_even(CArray[uint32], size_t) returns uint32 is native($n-path) { * }

my @numbers := CArray[uint32].new;
@numbers[$++] = $_ for 1..6;

say sum_of_even( @numbers, @numbers.elems );

