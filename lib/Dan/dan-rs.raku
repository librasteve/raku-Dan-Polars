use NativeCall; 

constant $n-path = '../../dan/target/debug/dan';
constant $s-path = '../../dan/src/';
constant $s-name = 'lib.rs';
constant $t-name = 'lib.rs.template';
constant $r-name = 'dan-rs.raku';

sub build-me {
    indir( $s-path, {
        spurt 'file', 'default text, directly written';
        run 'cargo', 'build';
    });
}

say my $raku-modified = $r-name.IO.modified.DateTime; 
say my $rust-modified = indir( $s-path, { $s-name.IO.modified.DateTime } ); 
say $raku-modified > $rust-modified; 

die;
if $raku-modified > $rust-modified { 

    my $template = indir( $s-path, {slurp $t-name} );
    say $template;
    build-me;
}
die;


class Series is repr('CPointer') {
    sub se_new() returns Series  is native($n-path) { * }
    sub se_free(Series)          is native($n-path) { * }
    sub se_head(Series)          is native($n-path) { * }

    method new { 
        se_new 
    }

    #Free data when the object is garbage collected.
    submethod DESTROY {
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
    @output
}

class DataFrame is repr('CPointer') {
    sub df_new() returns DataFrame  is native($n-path) { * }
    sub df_free(DataFrame)          is native($n-path) { * }
    sub df_read_csv(DataFrame, Str) is native($n-path) { * }
    sub df_head(DataFrame)          is native($n-path) { * }
    sub df_column(DataFrame, Str) returns Series is native($n-path) { * }
    sub df_select(DataFrame, CArray[Str], size_t) returns DataFrame is native($n-path) { * }
#    sub df_groupby(DataFrame, CArray[Str], size_t) returns DataFrame is native($n-path) { * }
    sub df_sum(DataFrame) returns DataFrame is native($n-path) { * }

    method new { 
        df_new 
    }

    #Free data when the object is garbage collected.
    submethod DESTROY {
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

#`[
    method groupby( Array \colspec ) { 
        df_groupby(self, prep-carray-str( colspec ), colspec.elems)
    }
#]

    method sum { 
        df_sum(self) 
    }
}

my \df = DataFrame.new;
df.read_csv("../../dan/src/iris.csv");
df.head;
my $se-sl = df.column("sepal.length");
$se-sl.head;

dd my $selection = df.select(["sepal.length", "variety"]);
$selection.head;
my $sum = $selection.sum;
$sum.head;
