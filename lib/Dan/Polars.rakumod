unit module Dan::Polars:ver<0.0.3>:auth<Steve Roe (librasteve@furnival.net)>;

use Dan;
use Dan::Polars::Containers;

### Series, DataFrame [..] Roles that are exported for Script Usage ###

# generates default column labels
constant @alphi = 'A'..∞; 

# sorts Hash by value, returns keys (poor woman's Ordered Hash)
sub sbv( %h --> Seq ) is export {
    %h.sort(*.value).map(*.key)
}

# bare sub 'col' creates Expr.new
sub col( Str \colname ) is export {
    ExprC.col(colname)
}

# bare sub 'lit' creates Expr.new
sub lit( \value ) is export {
    ExprC.lit(value)
}

# bare sub 'struct' creates Expr.new
sub struct( Array \colspec ) is export {
    ExprC.struct(colspec)
}

role Series does Positional does Iterable is export {

    ## attrs for construct and push/pull only
    ## not synched to Rust shadow 
    has Str	    $.name;
    has         @.data;
    has Int     %.index;
    has         $!dtype;

    has SeriesC $.rc is rw;       #Rust container

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
        $!name  = $name // 'anon';
        @!data  = @data;
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

        # reject missing empty data (since we cannot infer dtype)
        die "please provide at least one data item so that we can infer the dtype" without @!data;

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

        #say 'tweaking...', $!name, @!data, $!dtype;
        $!rc = SeriesC.new( $!name, @!data, :$!dtype )
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

    method name {
        $!rc.name 
    }

    method rename( $name ) {
        $!rc.rename( $name ) ;
        self
    }

    method len {
        $!rc.len 
    }

    method !is-null {         # cannot autoflood as self referential
        my $nulls = Series.new( data => [False], name => 'nulls' );
        $nulls.rc = $!rc.is_null;
        $nulls
    }

    method index {              # get index as Hash
        self.flood; 
        %!index
    }

    multi method ix {           # get index as Array
        %!index.&sbv
    }

    method str-lengths {
        $!rc.str-lengths
    }

    method get_data {
        my $nulls = self!is-null;
        my @nulls = $nulls.rc.get_data;
        my $null-count = +@nulls.grep(*.so); 
        my $null-value = $nulls.rc.raku-null-val( self.dtype );

        my @data = $!rc.get_data($null-count); 

        my @vals = gather {
            for ^self.elems -> $i {
                if @nulls[$i] {
                    take $null-value 
                } else {
                    take @data.shift
                }
            }
        }

        @vals
    }

    method Dan-Series {
        my @data := $.get_data;
        Dan::Series.new( :$!name, :@data )
    }

    #### Sync Methods #####
    #### Flood & Flush  #####

    #| set raku attrs to rc_data, reset index
    method flood {
	    @!data = $.get_data.flat;

        %!index = gather {
            for 0..^@!data {
                take ( $_ => $_ )
            }
        }.Hash;
    }

    #| flush SeriesC (with same dtype)
    method flush {
        $!rc = SeriesC.new( $!name, @!data, :$.dtype )
    }

    #### MAC Methods #####
    #Moves, Adds, Changes#

    #| get self as Array of Pairs
    multi method aop {
	    self.flood;
        self.ix.map({ $_ => @!data[$++] })
    }

    #| set data and index from Array of Pairs
    multi method aop( @aop ) {
        %!index = @aop.map({$_.key => $++});
        @!data  = @aop.map(*.value);
        $.push
    }

    # concat (maps onto Polars append)
    method concat( Series:D $dsr ) {
        $!rc.append: $dsr.rc;
        self
    }

    ### Role Support ###

    # Positional role support 
    # viz. https://docs.raku.org/type/Positional

    method of {
        Any
    }
    method elems {
        $.len
    }
    method AT-POS( $p ) {
        @!data[$p]
    }
    method EXISTS-POS( $p ) {
        0 <= $p < self.len ?? True !! False
    }

    # Iterable role support 
    # viz. https://docs.raku.org/type/Iterable

    method iterator {
        @!data.iterator
    }
    method flat {
        @!data.flat
    }
    method lazy {
        @!data.lazy
    }
    method hyper {
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
        @!data[%.index{$k}]
    }
    method EXISTS-KEY( $k ) {
        %!index{$k}:exists
    }

    # Extra support for + numeric and  [+] reduce via list and Numeric

    method Numeric {
        @!data.Numeric
    }
    method list {
        @!data.list
    }

}

role Categorical does Series is export {
}

# viz. https://pola-rs.github.io/polars/polars_core/frame/hash_join/enum.JoinType.html
subset JoinType of Str where <left inner outer asof cross>.any;

role DataFrame does Positional does Iterable is export {
    has Any        @.data;             #redo 2d shaped Array when [; ] implemented
    has Int        %!index;            #row index
    has Int        %!columns;          #column index

    has DataFrameC $.rc;       #Rust container
    has LazyFrameC $.lc;       #Rust container

    #| need this to avoid immutable error
    multi method rc( $rc ) {
        $!rc = $rc
    }

    multi method rc {
        $!rc
    }

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

    # helper functions for TWEAK

    method load-from-series( *@series ) {
        for @series -> \column {
            self.with_column( column )
        }
    }

    method load-from-data {                     #not using accessors as still constructing
        my @cx = %!columns.&sbv;

        my @series = gather {
            loop ( my $i = 0; $i < @!data.first.elems; $i++ ) {
                #say 'loading...', @!data[*;$i];
                take Series.new( data => @!data[*;$i], name => @cx[$i] ) 
            }
        }

        self.load-from-series: |@series
    }

    method load-from-slices( @slices ) {

        loop ( my $i=0; $i < @slices; $i++ ) {
            my $key = @slices[$i].name // ~$i;
            %!index{ $key } = $i;

            @!data[$i] := @slices[$i].data
        }

        self.load-from-data
    }

    method TWEAK {

        return unless @!data;

        given @!data.first {            #FIXME .first should be Array[Pair]

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
                            when Series { take Series.new( $_.data, :$name, dtype => $_.dtype ) }
                            when Array  { take Series.new( $_, :$name ) }

                            # handle Scalar items (set index to auto-expand)
                            when Str|Real { take Series.new( $_,     :$name, :@index ) }
                            when Date     { take Series.new( $_.Str, :$name, :@index ) }
                        }
                    }
                }.Array;

                self.load-from-series: |@series
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
                self.load-from-slices: @slices;
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

                self.load-from-data
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

    method dtypes {
        $!rc.dtypes
    }

    method shape {
	    $.height, $.width
    }

    method describe {
        my \df = $.Dan-DataFrame;
	    df.describe
    }

    multi method ix {                   # get index as Array
        $.index.&sbv
    }

    method index {                      # get index as Hash
        %!index = gather {
            for 0..^$.height {
                take ( $_ => $_ )
            }
        }.Hash
    }

    multi method cx {                   # get columns as Array
        $.get_column_names
    }

    method columns {                    # get columns as Hash
        my @keys = |$.cx;
        @keys.map({ $_ => $++ }).Hash
    }

    #### Coercion / Export Methods ####

    method Dan-DataFrame {
        self.flood;
        Dan::DataFrame.new( :@!data, :%!columns )
    }

    method to-dataset {
        my $dataset = [;];
        my @aoa = [];
        my $colname;
        my $series;

        say DateTime.now, "...converting to dataset";
        for 0..^$.cx -> $j {
            $colname = $.cx[$j];

            say DateTime.now, "...column $colname";
            $series = $.column($colname);

            @aoa.push: [$series.get_data.map({$colname => $_})];
        }

        say DateTime.now, "...transpose dataset";
        $dataset = [Z] @aoa;
        $dataset
    }

    #### Polars Specific Submethods ###

    method height {
        $!rc.height
    }

    method width {
        $!rc.width
    }

    method get_column_names {
        $!rc.get_column_names
    }

    method column( Str \colname ) {
        my SeriesC $cont = $!rc.column( colname );
        my $news = Series.new( data => [<0>], name => $cont.name, dtype => $cont.dtype );
        $news.rc = $cont;
        $news
    }

    method with_column( Series \column ) {
        $!rc.with_column( column.rc );
        self
    }

    method !vstack( DataFrame \right ) {
        $!rc.vstack( right.rc )
    }

    method !hstack( @series ) {
        self.with_column($_) for @series;
        self
    }

    sub clean-axis( :$axis ) {
        given $axis {
            when ! .so || /^r/ || /^v/ { 0 }
            when   .so || /^c/ || /^h/ { 1 }
        }
    }

    method concat( DataFrame:D $dfr, :ax(:$axis) is copy ) {

        $axis = clean-axis(:$axis);

        if ! $axis {                        # row-wise with Polars vstack 

            if $dfr.width !== self.width {
                warn 'Polars row-wise concat only implemented for DataFrames with same number of columns!'
            } else {
                self!vstack: $dfr 
            }

        } else {                            # col-wise with Polars hstack

            if $dfr.height !== self.height {
                warn 'Polars column-wise join only implemented for DataFrames with same number of rows!'
            } else {
                my @series = $dfr.cx.map({$dfr.column($_)});
                self!hstack: @series
            }

        }
    }

    #| viz. https://docs.rs/polars/latest/polars/prelude/struct.LazyFrame.html#method.join
    #| exposes just the on argument but not on_right and on_left 
    method join( DataFrame \right, Str :$on, JoinType :$how = 'outer' ) {
        my @join-cols;

        if $on {
            @join-cols = $on
        } else {                            #autogen join-cols if 'on' not provided 
            @join-cols = gather {
                for self.columns.&sbv {
                    take $_ if right.columns{$_}:exists
                }
            }
        }

        my $colspec = [@join-cols.map({ col($_) })];

        $!lc = LazyFrameC.new( $!rc );                                  #autolazy self & right args
        my $lr = LazyFrameC.new( right.rc );

        my \df = DataFrame.new;
        df.rc: $!lc.join( $lr, $colspec, $colspec, $how.tc );      #l_ & r_colspec are the same
        df
    }

    #### Query Methods #####

#`[
dfa.groupby(["letter"]).agg([col("number").sum]).head;
--- ------- ----------  ---  --- --------- ---   ----
 |     |        |        |    |      |      |      -> method head prints some lines of thesresult
 |     |        |        |    |      |      |
 |     |        |        |    |      |      -> method sum returns a new Expr
 |     |        |        |    |      |
 |     |        |        |    |      -> colname argument
 |     |        |        |    |
 |     |        |        |    -> method col(Str \colname) returns a new Expr
 |     |        |        |
 |     |        |        -> method agg(Array \expr) applies a list of Expr to the LazyGroupBy,
 |     |        |                 then calls .collect to convert the LazyFrame result to a new DataFrame
 |     |        |
 |     |        -> colspec is List of Str valid column names [1]
 |     |
 |     -> method groupby(Array \colspec) creates a LazyFrame and returns a LazyGroupBy object into the lf.gb field
 |
 -> DataFrame object with attributes of pointers to rust DataFrame and LazyFrame structures
 #]

    method series( $k ) {
        $.column( $k )
    }

    method select( Array \exprs ) {
        $!lc = LazyFrameC.new( $!rc );      # autolazy
        $!lc.select( exprs );
        self!collect
    }

    method with_columns( Array \exprs ) {
        $!lc = LazyFrameC.new( $!rc );      # autolazy
        $!lc.with_columns( exprs );
        self!collect
    }

    method drop( @colnames ) {              # takes List of Str (unlike Polars native call)
        $!rc .= drop( $_ ) for @colnames;
        self
    }

    method !collect( --> DataFrame ) {
        my \df = DataFrame.new;
        df.rc: $!lc.collect;
        df
    }

    method groupby( Array \colspec ) {      # autocollect means groupby must always have an agg
        $!lc = LazyFrameC.new( $!rc );      # autolazy
        $!lc.groupby( colspec );
        self
    }

    method agg( Array \exprs ) {
        $!lc.agg( exprs );
        self!collect
    }

    multi method sort( Array \colspec, Array \descvec ) {   # takes colspec, descvec
        $!rc .= sort( colspec, descvec );
        self
    }

    multi method sort( &cruton ) {                          # takes Block &custom-routine-to-use
        self.flood;

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

    method filter( Array \exprs ) {         # takes Array of Exprs (unlike Polars native call)
        $!lc = LazyFrameC.new( $!rc );      # autolazy
        $!lc.filter( exprs );
        self!collect
    }

    method grep( &cruton ) {                # &custom-routine-to-use
        self.flood;

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

    #### Test Methods ###

    method is_empty {
        self.shape ~~ (0,0)
    }

    #### MAC Methods #####
    #Moves, Adds, Changes#

    #| set (re)index from Array
    multi method ix( @new-index ) {
        warn "settor method .ix is not implemented by Dan::Polars (Polars does not implement row index";
    }

    method rename( $old_name, $new_name ) {
        $!rc.rename( $old_name, $new_name )
    }

    #| set columns (relabel) from Array
    multi method cx( @new-names ) {
        my @old-names = |self.cx;
        for ^@new-names {
            self.rename( @old-names[$++], @new-names[$++] ) 
        }
    }

    #### File Methods #####
    #### Read & Write #####

    method read_csv( Str \path ) {
        $!rc.read_csv( path )        
    }

    #### Sync Methods #####
    #### Flood & Flush ####

    #| set raku attrs to rc_cols, rc_data, reset index
    method flood {
        %!columns = self.cx.map({ $_ => $++ });

        my @series;
        for |self.cx -> $colname {
            @series.push: $.column( $colname )    
        }

        @!data = [];
        loop ( my $i=0; $i < @series; $i++ ) {
            @series[$i].flood;
            @!data.push: @series[$i].data
        }
        @!data = [Z] @!data;
        @!data.map: {$_.=Array};        #my @a = [[0,1],[2,3],[4,5]]; my Array() @b = [Z] @a; say @b;

        %!index = gather {
            for 0..^@!data {
                take ( $_ => $_ )
            }
        }.Hash;
    }

    #| flush DataFrame 
    method flush {
        say 'flushing...';
        self.load-from-data
    }

    ### Mezzanine methods ###  

    method T {                      #FIXME - rust not working
        my \df = $.Dan-DataFrame;
        DataFrame.new: df.T
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
        @!data.elems
    }
    method AT-POS( $p, $q? ) {
        @!data[$p;$q // *]
    }
    method EXISTS-POS( $p ) {
        0 <= $p < @!data.elems ?? True !! False
    }

    # Iterable role support 
    # viz. https://docs.raku.org/type/Iterable

    method iterator {
        @!data.iterator
    }
    method flat {
        @!data.flat
    }
    method lazy {
        @!data.lazy
    }
    method hyper {
        @!data.hyper
    }

    # Extra support for + numeric and  [+] reduce via list and Numeric

    method Numeric {
        @!data.Numeric
    }
    method list {
        @!data.list
    }
}

### Infix operators for ExprCs - Numerical
multi infix:<+>( ExprC:D $left, Real:D $right ) is export {
    $left.__add__: lit($right) 
}
multi infix:<+>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__add__: $right 
}
multi infix:<+>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__add__: $right 
}

multi infix:<->( ExprC:D $left, Real:D $right ) is export {
    $left.__sub__: lit($right) 
}
multi infix:<->( Real:D $left, ExprC:D $right ) is export {
    lit($left).__sub__: $right 
}
multi infix:<->( ExprC:D $left, ExprC:D $right ) is export {
    $left.__sub__: $right 
}

multi infix:<*>( ExprC:D $left, Real:D $right ) is export {
    $left.__mul__: lit($right) 
}
multi infix:<*>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__mul__: $right 
}
multi infix:<*>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__mul__: $right 
}

multi infix:</>( ExprC:D $left, Real:D $right ) is export {
    $left.__div__: lit($right) 
}
multi infix:</>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__div__: $right 
}
multi infix:</>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__div__: $right 
}

multi infix:<%>( ExprC:D $left, Real:D $right ) is export {
    $left.__mod__: lit($right) 
}
multi infix:<%>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__mod__: $right 
}
multi infix:<%>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__mod__: $right 
}

multi infix:<div>( ExprC:D $left, Real:D $right ) is export {
    $left.__floordiv__: lit($right) 
}
multi infix:<div>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__floordiv__: $right 
}
multi infix:<div>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__floordiv__: $right 
}

### Infix operators for ExprCs - Logical
#(gt >, lt <, ge >=, le <=, eq ==, ne !=, and &&, or ||)

multi infix:<\>>( ExprC:D $left, Real:D $right ) is export {
    $left.__gt__: lit($right) 
}
multi infix:<\>>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__gt__: $right 
}
multi infix:<\>>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__gt__: $right 
}

multi infix:<\<>( ExprC:D $left, Real:D $right ) is export {
    $left.__lt__: lit($right) 
}
multi infix:<\<>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__lt__: $right 
}
multi infix:<\<>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__lt__: $right 
}

multi infix:<\>=>( ExprC:D $left, Real:D $right ) is export {
    $left.__ge__: lit($right) 
}
multi infix:<\>=>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__ge__: $right 
}
multi infix:<\>=>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__ge__: $right 
}

multi infix:<\<=>( ExprC:D $left, Real:D $right ) is export {
    $left.__le__: lit($right) 
}
multi infix:<\<=>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__le__: $right 
}
multi infix:<\<=>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__le__: $right 
}

multi infix:<==>( ExprC:D $left, Real:D $right ) is export {
    $left.__eq__: lit($right) 
}
multi infix:<==>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__eq__: $right 
}
multi infix:<==>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__eq__: $right 
}

multi infix:<!=>( ExprC:D $left, Real:D $right ) is export {
    $left.__ne__: lit($right) 
}
multi infix:<!=>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__ne__: $right 
}
multi infix:<!=>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__ne__: $right 
}

multi infix:<&&>( ExprC:D $left, Real:D $right ) is export {
    $left.__and__: lit($right) 
}
multi infix:<&&>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__and__: $right 
}
multi infix:<&&>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__and__: $right 
}

multi infix:<||>( ExprC:D $left, Real:D $right ) is export {
    $left.__or__: lit($right) 
}
multi infix:<||>( Real:D $left, ExprC:D $right ) is export {
    lit($left).__or__: $right 
}
multi infix:<||>( ExprC:D $left, ExprC:D $right ) is export {
    $left.__or__: $right 
}



### Postfix '^' as explicit subscript chain terminator

multi postfix:<^>( @ds ) is export {     #FIXME add this to Dan
    DataFrame.new(@ds) 
}
multi postfix:<^>( Dan::DataSlice @ds ) is export {
    DataFrame.new(@ds) 
}
multi postfix:<^>( Dan::DataSlice $ds ) is export {
    DataFrame.new(($ds,)) 
}

##proto postcircumfix:<[ ]>( DataFrame:D $df, |) { * }
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

#EOF
