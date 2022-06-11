unit module Dan::Polars:ver<0.0.1>:auth<Steve Roe (p6steve@furnival.net)>;

#`[TODOs
- se functions
- df functions
- strip Index
- single query
--
- lazy only
- pure only
- opaque only
-- no chunk controls
-- no chunk unpack (i32 ...)
-- no datetime (in v1)
--
-- v2
- apply
- datetime
- better value return
- multiple query
#]

use Dan;
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
constant $rust-dir  = '../dan/src/';
constant $rust-file = 'lib.rs';
constant $tmpl-file = 'lib.rs.template';
constant $raku-dir  = '../lib/Dan/';
constant $raku-file = 'Polars.rakumod';
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
    sub se_elems(SeriesC)  returns uint32 is native($n-path) { * }
    sub se_values(SeriesC, Str) is native($n-path) { * }

    method new( $name, @data, :$dtype ) {

        if $dtype {

            @data.map({ $_ .= Num if $_ ~~ Rat});                       #Coerce stray Rats to Num
            @data.map({ $_ .= Num if $_ ~~ Int}) if $dtype eq 'Num';    #Coerce stray Ints to Num

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
                when   'bool' { se_new_bool($name, carray( bool, @data), @data.elems) }
                when   'Bool' { se_new_bool($name, carray( bool, @data), @data.elems) }
                when    'Int' { se_new_i64($name, carray( int64, @data), @data.elems) }
                when    'Num' { se_new_f64($name, carray( num64, @data), @data.elems) }
                when    'Str' { se_new_str($name, carray(   Str, @data), @data.elems) }
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

    method elems {
        se_elems(self)
    }

    method values {
        se_values(self, $vals-file);
        my @values = $vals-file.IO.lines;
        @values.map({ $_ = +$_ if $_ ~~ /<number>/ });     #convert to narrowest Real type
        @values
    }
}

class DataFrameC is repr('CPointer') {
    sub df_new() returns DataFrameC  is native($n-path) { * }
    sub df_free(DataFrameC)          is native($n-path) { * }
    sub df_read_csv(DataFrameC, Str) is native($n-path) { * }
    sub df_show(DataFrameC)          is native($n-path) { * }
    sub df_head(DataFrameC)          is native($n-path) { * }
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

    method column( Str \colname ) {
        df_column(self, colname)
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

class Query {
    has Str $.s;

    submethod TWEAK {

        if "$raku-dir/$raku-file".IO.modified > "$rust-dir/$rust-file".IO.modified {

            indir( $rust-dir, {
                my $template = slurp $tmpl-file;
                $template ~~ s/'//%INSERT-QUERY%'/$!s/;;
                spurt $rust-file, $template;

                run <cargo build>;
            });

        }
    }
}

#`[ off
Query.new( s => q{
    .groupby(["variety"])
    .unwrap()
    .select(["petal.length"])
    .sum()
    .unwrap()
});

my \x = df.query;
x.head;
#]

### Series, DataFrame [..] Roles that are exported for Script Usage ###

# generates default column labels
constant @alphi = 'A'..∞; 

# sorts Hash by value, returns keys (poor woman's Ordered Hash)
sub sbv( %h --> Seq ) is export {
    %h.sort(*.value).map(*.key)
}

role Series does Positional does Iterable is export {

    ## attrs for construct and pull only: not synched to Rust side ##
    has Str	    $.name;
    has Any     @.data;
    has Int     %!index;
    has         $!dtype;

    has SeriesC $.rc;       #Rust container

    ### Constructors ###
 
    # Positional data array arg => redispatch as Named
    multi method new( @data, *%h ) {
        samewith( :@data, |%h )
    }

    # Positional data scalar arg => redispatch as Named
    multi method new( $data, *%h ) {
        samewith( :$data, |%h )
    }

    # Real (scalar) data arg => populate Array & redispatch
    multi method new( Real:D :$data, :$index, *%h ) {
        die "index required if data ~~ Real" unless $index;
        samewith( data => ($data xx $index.elems).Array, :$index, |%h )
    }

    # Str (scalar) data arg => populate Array & redispatch
    multi method new( Str:D :$data, :$index, *%h ) {
        die "index required if data ~~ Str" unless $index;
        samewith( data => ($data xx $index.elems).Array, :$index, |%h )
    }

    # Date (scalar) data arg => populate Array & redispatch
    multi method new( Date:D :$data, :$index, *%h ) {
        die "index required if data ~~ Date" unless $index;
        samewith( data => ($data xx $index.elems).Array, :$index, |%h )
    }

    # from Dan::Series 
    multi method new( Dan::Series:D \s ) {
        samewith( name => s.name, data => s.data, index => s.index )
    }

    submethod BUILD( :$name, :@data, :$index, :$dtype ) {
        $!name = $name // 'anon';
        @!data = @data;
        $!dtype = $dtype; 

	    if $index {
            if $index !~~ Hash {
                %!index = $index.map({ $_ => $++ })
            } else {
                %!index = $index
            }
        }
    }

    method TWEAK {

        # handle data => Array of Pairs 

        if @!data.first ~~ Pair {

            die "index not permitted if data is Array of Pairs" if %!index;

            @!data = gather {
                for @!data -> $p {
                    take $p.value;
                    %!index{$p.key} = $++
                }
            }.Array
	    }

        # handle implicit index
        # NB for Dan::Polars::Series, we accept index same as Dan::Series
        # and then overwrite with the implicit index immediately

        #if ! %!index {
            %!index = gather {
                for 0..^@!data {
                    take ( $_ => $_ )
                }
            }.Hash;
        #}

        $!rc = SeriesC.new( $!name, @!data, dtype => $!dtype )
    }

    #### Info Methods #####

    method show {
	    $!rc.show
    }

    method head {
        $!rc.head 
    }

    method dtype {
        $!rc.dtype 
    }

    method index {              # get index as Hash
        $.pull; 
        %!index
    }

    multi method ix {           # get index as Array
        $.index.&sbv
    }

    method name {
        $!rc.name 
    }

    method values {
        $!rc.values 
    }

    method Dan-Series {
        @!data = $!rc.values;
        Dan::Series.new( :$!name, :@!data )
    }

    #### Sync Methods #####
    #### Pull & Push  #####

    #| set raku attrs to rc_values, reset index
    method pull {
	    @!data = $!rc.values;

        %!index = gather {
            for 0..^@!data {
                take ( $_ => $_ )
            }
        }.Hash;
    }

    #| flush SeriesC (with same dtype)
    method push {
        $!rc = SeriesC.new( $!name, @!data, :$.dtype )
    }

    #### MAC Methods #####
    #Moves, Adds, Changes#

    #| get self as Array of Pairs
    multi method aop {
	    $.pull;
        self.ix.map({ $_ => @!data[$++] })
    }

    #| set data and index from Array of Pairs
    multi method aop( @aop ) {
        %!index = @aop.map({$_.key => $++});
        @!data  = @aop.map(*.value);
        $.push
    }

    ### Splice ###
    #| get self as a Dan::Series, perform splice operation and push back

    method splice( Series:D: $start = 0, $elems?, :ax(:$axis), *@replace ) {

	    my $serse = self.Dan-Series;

	    my @res = $serse.splice( $start, $elems, :$axis, |@replace );

        @!data  = $serse.data;
        %!index = gather {
            for 0..^@!data {
                take ( $_ => $_ )
            }
        }.Hash;

        $.push;

        @res
    }

    ### Concat ###
    #| concat done by way of aop splice

    method concat( Dan::Polars::Series:D $dsr ) {

	    $.pull;

        my $start = %!index.elems;
        my $elems = $dsr.index.elems;
        my @replace = $dsr.aop;

        self.splice: $start, $elems, @replace;    
        self
    }

    ### Role Support ###

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional

    method of {
        Any
    }
    method elems {
        $!rc.elems()
    }
    method AT-POS( $p ) {
        $.pull;
        @!data[$p]
    }
    method EXISTS-POS( $p ) {
        0 <= $p < self.elems ?? True !! False
    }

    # Iterable role support 
    # viz. https://docs.raku.org/type/Iterable

    method iterator {
        $.pull;
        @!data.iterator
    }
    method flat {
        $.pull;
        @!data.flat
    }
    method lazy {
        $.pull;
        @!data.lazy
    }
    method hyper {
        $.pull;
        @!data.hyper
    }

    # LIMITED Associative role support 
    # viz. https://docs.raku.org/type/Associative
    # DataSlice just implements the Assoc. methods, but does not do the Assoc. role
    # ...thus very limited support for Assoc. accessors (to ensure Positional Hyper methods win)

    method keyof {
        Str(Any) 
    }
    method AT-KEY( $k ) {
        $.pull;
        @!data[%.index{$k}]
    }
    method EXISTS-KEY( $k ) {
        $.pull;
        %.index{$k}:exists
    }

}

role Categorical does Series is export {
}

role DataFrame does Positional does Iterable is export {
    has Any        @.data;             #redo 2d shaped Array when [; ] implemented
    has Int        %!index;            #row index
    has Int        %!columns;          #column index

    has DataFrameC $.rc;       #Rust container
    has $.po;			  #ref to Python DataFrame obj  FIXME


    ### Constructors ###
 
    # Positional data array arg => redispatch as Named
    multi method new( @data, *%h ) {
        samewith( :@data, |%h )
    }

    # from Dan::DataFrame 
    multi method new( Dan::DataFrame:D \s ) {
        samewith( name => s.name, data => s.data, index => s.index )
    }

    submethod BUILD( :@data, :$index, :$columns ) {
        @!data = @data;

        if $index {
            if $index !~~ Hash {
                %!index = $index.map({ $_ => $++ })
            } else {
                %!index = $index
            }
        }

        if $columns {
            if $columns !~~ Hash {
                %!columns = $columns.map({ $_ => $++ })
            } else {
                %!columns = $columns
            }
        }

        $!rc = DataFrameC.new;
    }

#`[[[
    # helper functions for TWEAK

    method load-from-series( *@series ) {
        for @series -> $sene {
            $!po.rd_concat_series($sene.po)
        }
        $.pull
    }

    method load-from-slices( @slices ) {
        loop ( my $i=0; $i < @slices; $i++ ) {

            my $key = @slices[$i].name // ~$i;
            %!index{ $key } = $i;

            @!data[$i] := @slices[$i].data
        }
    }

  
    sub prep-py-str( $args ) {  #FIXME
#`[
qq{

# since Inline::Python will not pass a DataFrame class back and forth
# we make and instantiate a standard class 'RakuDataFrame' as container
# and populate methods over in Python to condition the returns as 
# supported datastypes (Int, Str, Array, Hash, etc)

class RakuDataFrame:
    def __init__(self):
        self.dataframe = pd.DataFrame($args)
        #print(self.dataframe)

    def rd_str(self):
        return(str(self.dataframe))

    def rd_dtypes(self):
        print(str(self.dataframe.dtypes))

    def rd_index(self):
        return(self.dataframe.index)

    def rd_columns(self):
        return(self.dataframe.columns)

    def rd_values(self):
        array = self.dataframe.values
        result = array.tolist()
        return(result)

    def rd_eval(self, exp):
        result = eval('self.dataframe' + exp)
        print(result) 

    def rd_eval2(self, exp, other):
        result = eval('self.dataframe' + exp + '(other.dataframe)')
        print(result) 

    def rd_exec(self, exp):
        exec('self.dataframe' + exp)

    def rd_push(self, args):
        self.dataframe = eval('pd.DataFrame(' + args + ')')

    def rd_transpose(self):
        self.dataframe = self.dataframe.T

    def rd_shape(self):
        return(self.dataframe.shape)

    def rd_describe(self):
        print(self.dataframe.describe())

    def rd_concat_series(self, other):
        self.dataframe = pd.concat([self.dataframe, other.series], axis=1)

};

    }
#]
#]]]

    # helper functions for TWEAK

    method load-from-series( *@series ) {
        for @series -> \column {
            $.with_column( column )
        }
    }

    method load-from-data {                     #not using accessors as still constructing

        my @cx = %!columns.&sbv;

        my @series = gather {
            loop ( my $i = 0; $i < @!data.first.elems; $i++ ) {
                take Series.new( data => @!data[*;$i], name => @cx[$i] ) 
            }
        }

        $.load-from-series: |@series
    }

    method load-from-slices( @slices ) {

        loop ( my $i=0; $i < @slices; $i++ ) {

            my $key = @slices[$i].name // ~$i;
            %!index{ $key } = $i;

            @!data[$i] := @slices[$i].data
        }

        $.load-from-data
    }

    method TWEAK {

        given @!data.first {

            # data arg is 1d Array of Pairs (label => Series)
            when Pair {

                die "columns / index not permitted if data is Array of Pairs" if %!index || %!columns;

                my $row-count = 0;
                @!data.map( $row-count max= *.value.elems );

                my @index  = 0..^$row-count;
                my @labels = @!data.map(*.key);

                # make (or update) each Series with column key as name, index as index
                my @series = gather {
                    for @!data -> $p {
                        my $name = ~$p.key;
                        given $p.value {
                            # handle Series/Array with row-elems (auto index)
                            when Series { take Series.new( $_.data, :$name, dtype => ::($_.dtype ) ) }
                            when Array  { take Series.new( $_, :$name ) }

                            # handle Scalar items (set index to auto-expand)
                            when Str|Real { take Series.new( $_,     :$name, :@index ) }
                            when Date     { take Series.new( $_.Str, :$name, :@index ) }
                        }
                    }
                }.Array;

                $.load-from-series: |@series
            } 

#`[
            # data arg is 1d Array of Series (cols)
            when Series {
                die "columns.elems != data.first.elems" if ( %!columns && %!columns.elems != @!data.first.elems );

                my $row-count = @!data.first.elems;
                my @series = @!data; 

                # clear and load data (and columns)
                @!data = [];
                $.load-from-series: :$row-count, |@series;

                # make index Hash
                %!index = @series.first.index;
            }
#]

            # data arg is 1d Array of DataSlice (rows)
            when Dan::DataSlice {
                my @slices = @!data; 

                # make columns Hash
                %!columns = @slices.first.index;

                # clear and load data (and index)
                @!data = [];
                $.load-from-slices: @slices;
            }

            # data arg is 2d Array (already) 
            default {
                die "columns.elems != data.first.elems" if ( %!columns && %!columns.elems != @!data.first.elems );

                if ! %!index {
                    [0..^@!data.elems].map( {%!index{$_.Str} = $_} );
                }
                if ! %!columns {
                    @alphi[0..^@!data.first.elems].map( {%!columns{$_} = $++} ).eager;
                }

                $.load-from-data
            } 
        }

        # since this is Polars now reset index
        %!index = gather {
            for 0..^@!data {
                take ( $_ => $_ )
            }
        }.Hash;
    }

    #### Info Methods #####

    method show { 
        $!rc.show
    }

    method head { 
        $!rc.head
    }

    method column( Str \colname ) {
        $!rc.column( colname )
    }

    method select( Array[Str] \colspec ) {
        $!rc.select( colspec )
    }

    method with_column( Series \column ) {
        $!rc.with_column( column.rc )
    }


#`[[[
    method dtypes {
        $!po.rd_dtypes()
    }

    method Dan-DataFrame {
        $.pull;
        Dan::DataFrame.new( :@!data, :%!index, :%!columns )
    }

    #| get index as Array
    multi method ix {
        $!po.rd_index()
    }

    #| get index as Hash
        method index {
        my @keys = $!po.rd_index();
        @keys.map({ $_ => $++ }).Hash
    }

    #| get columns as Array
    multi method cx {
        $!po.rd_columns()
    }

    #| get columns as Hash
    method columns {
        my @keys = $!po.rd_columns();
        @keys.map({ $_ => $++ }).Hash
    }

    #### MAC Methods #####
    #Moves, Adds, Changes#

    #| set (re)index from Array
    multi method ix( @new-index ) {
        %.index.keys.map: { %!index{$_}:delete };
        @new-index.map:   { %!index{$_} = $++  };

        my $args = self.prep-py-args;
        $!po.rd_push($args)
    }

    #| set columns (relabel) from Array
    multi method cx( @new-labels ) {
        %.columns.keys.map: { %!columns{$_}:delete };
        @new-labels.map:    { %!columns{$_} = $++  };

        my $args = self.prep-py-args;
        $!po.rd_push($args)
    }

#]]]

    #### File Methods #####
    #### Read & Write #####

    method read_csv( Str \path ) {
        $!rc.read_csv( path )        
    }

#`[[[
    #### Sync Methods #####
    #### Pull & Push  #####

    #| set raku attrs to rd_array / rd_index / rd_columns
    method pull {
        %!index   = $.index;
        %!columns = $.columns;
        @!data    = $!po.rd_values;
    }

    ### Mezzanine methods ###  
    #   (these use Python)  #

    method T {
        $!po.rd_transpose();
        self
    }

    method shape {
	    $!po.rd_shape()
    }

    method describe {
	    $!po.rd_describe()
    }

    method series( $k ) {
        self.[*]{$k}
    }

    method sort( &cruton ) {  #&custom-routine-to-use
        $.pull;

        my $i;
        loop ( $i=0; $i < @!data; $i++ ) {
            @!data[$i].push: %!index.&sbv[$i]
        }

        @!data .= sort: &cruton;
        %!index = %();

        loop ( $i=0; $i < @!data; $i++ ) {
            %!index{@!data[$i].pop} = $i
        }

        DataFrame.new( :%!index, :%!columns, :@!data )
    }

    method grep( &cruton ) {  #&custom-routine-to-use
	$.pull;

        my $i;
        loop ( $i=0; $i < @!data; $i++ ) {
            @!data[$i].push: %!index.&sbv[$i]
        }

        @!data .= grep: &cruton;
        %!index = %();

        loop ( $i=0; $i < @!data; $i++ ) {
            %!index{@!data[$i].pop} = $i
        }

	DataFrame.new( :%!index, :%!columns, :@!data )
    }

    ### Pandas Methods ###

    multi method pd( $exp ) {
        if $exp ~~ /'='/ {
	    $!po.rd_exec( $exp )
	} else {
	    $!po.rd_eval( $exp )
	}
    }

    multi method pd( $exp, Dan::Polars::Series:D $other ) {
        $!po.rd_eval2( $exp, $other.po )
    }

    ### Role Support ###

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional
    # delegates semilist [; ] value element access to @!data
    # override list [] access anyway

    method of {
        Any
    }
    method elems {
	    $.pull;
        @!data.elems
    }
    method AT-POS( $p, $q? ) {
	    $.pull;
        @!data[$p;$q // *]
    }
    method EXISTS-POS( $p ) {
	    $.pull;
        0 <= $p < @!data.elems ?? True !! False
    }

    # Iterable role support 
    # viz. https://docs.raku.org/type/Iterable

    method iterator {
	    $.pull;
        @!data.iterator
    }
    method flat {
	    $.pull;
        @!data.flat
    }
    method lazy {
	    $.pull;
        @!data.lazy
    }
    method hyper {
	    $.pull;
        @!data.hyper
    }

    ### Splice ###
    #| get self as a Dan::DataFrame, perform splice operation and push back

    method splice( DataFrame:D: $start = 0, $elems?, :ax(:$axis), *@replace ) {

        my $danse = self.Dan-DataFrame;

        my @res = $danse.splice( $start, $elems, :$axis, |@replace );

        %!index   = $danse.index;
        %!columns = $danse.columns;
        @!data    = $danse.data;

        my $args = self.prep-py-args;
        $!po.rd_push($args);

        @res
    }

    ### Concat ###
    #| get self & other as Dan::DataFrames, perform concat operation and push back

    method concat( DataFrame:D $dfr, :ax(:$axis), :jn(:$join) = 'outer', :ii(:$ignore-index) ) {

	my $danse = self.Dan-DataFrame;
	my $danot = $dfr.Dan-DataFrame;

	my @res = $danse.concat( $danot, :$axis, :$join, :$ignore-index );

        %!index   = $danse.index;
        %!columns = $danse.columns;
        @!data    = $danse.data;

        my $args = self.prep-py-args;
        $!po.rd_push($args);

        @res
    }
#]]]
}
#{{


### Postfix '^' as explicit subscript chain terminator

multi postfix:<^>( Dan::DataSlice @ds ) is export {
    DataFrame.new(@ds) 
}
multi postfix:<^>( Dan::DataSlice $ds ) is export {
    DataFrame.new(($ds,)) 
}

### Override first subscript [i] to make Dan::DataSlices (rows)

#| provides single Dan::DataSlice which can be [j] subscripted directly to value 
multi postcircumfix:<[ ]>( DataFrame:D $df, Int $p ) is export {
    Dan::DataSlice.new( data => $df.data[$p;*], index => $df.columns, name => $df.index.&sbv[$p] )
}

# helper
sub make-aods( $df, @s ) {
    my Dan::DataSlice @ = @s.map({
        Dan::DataSlice.new( data => $df.data[$_;*], index => $df.columns, name => $df.index.&sbv[$_] )
    })
}

#| slices make Array of Dan::DataSlice objects
multi postcircumfix:<[ ]>( DataFrame:D $df, @s where Range|List ) is export {
    make-aods( $df, @s )
}
multi postcircumfix:<[ ]>( DataFrame:D $df, WhateverCode $p ) is export {
    my @s = $p( |($df.elems xx $p.arity) );
    make-aods( $df, @s )
}
multi postcircumfix:<[ ]>( DataFrame:D $df, Whatever ) is export {
    my @s = 0..^$df.elems; 
    make-aods( $df, @s )
}


### Override second subscript [j] to make DataFrame

# helper
sub sliced-slices( @aods, @s ) {
    gather {
        @aods.map({ take Dan::DataSlice.new( data => $_[@s], index => $_.index.&sbv[@s], name => $_.name )}) 
    }   
}
sub make-series( @sls ) {
    my @data  = @sls.map({ $_.data[0] }); 
    my @index = @sls.map({ $_.name[0] });
    my $name  = @sls.first.index.&sbv[0];

    Series.new( :@data, :@index, :$name )
}

#| provides single Series which can be [j] subscripted directly to value 
multi postcircumfix:<[ ]>( Dan::DataSlice @aods , Int $p ) is export {
    make-series( sliced-slices(@aods, ($p,)) )
}

#| make DataFrame from sliced Dan::DataSlices 
multi postcircumfix:<[ ]>( Dan::DataSlice @aods, @s where Range|List ) is export {
    DataFrame.new( sliced-slices(@aods, @s) )
}
multi postcircumfix:<[ ]>( Dan::DataSlice @aods, WhateverCode $p ) is export {
    my @s = $p( |(@aods.first.elems xx $p.arity) );
    DataFrame.new( sliced-slices(@aods, @s) )
}
multi postcircumfix:<[ ]>( Dan::DataSlice @aods, Whatever ) is export {
    my @s = 0..^@aods.first.elems;
    DataFrame.new( sliced-slices(@aods, @s) )
}

### Override first assoc subscript {i}

multi postcircumfix:<{ }>( DataFrame:D $df, $k ) is export {
    $df[$df.index{$k}]
}
multi postcircumfix:<{ }>( DataFrame:D $df, @ks ) is export {
    $df[$df.index{@ks}]
}

### Override second assoc subscript {j} to make DataFrame

multi postcircumfix:<{ }>( Dan::DataSlice @aods , $k ) is export {
    my $p = @aods.first.index{$k};
    make-series( sliced-slices(@aods, ($p,)) )
}
multi postcircumfix:<{ }>( Dan::DataSlice @aods , @ks ) is export {
    my @s = @aods.first.index{@ks};
    DataFrame.new( sliced-slices(@aods, @s) )
}

#}}
