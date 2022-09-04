unit module Dan::Polars:ver<0.0.1>:auth<Steve Roe (p6steve@furnival.net)>;

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

role Series does Positional does Iterable is export {

    ## attrs for construct and push/pull only
    ## not synched to Rust shadow 
    has Str	    $.name;
    has Any     @.data;
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

    method get-data {
        $!rc.get-data 
    }

    method Dan-Series {
        my @data := $.get-data;
        Dan::Series.new( :$!name, :@data )
    }

    #### Sync Methods #####
    #### Flood & Flush  #####

    #| set raku attrs to rc_data, reset index
    method flood {
	    @!data = $.get-data.flat;

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

        self.flush;

        @res
    }

    ### Concat ###
    #| concat done by way of aop splice

    method concat( Dan::Polars::Series:D $dsr ) {

	    self.flood;

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

}

role Categorical does Series is export {
}

role DataFrame does Positional does Iterable is export {
    has Any        @.data;             #redo 2d shaped Array when [; ] implemented
    has Int        %!index;            #row index
    has Int        %!columns;          #column index

    has DataFrameC $.rc;       #Rust container
    has LazyFrameC $.lc;       #Rust container

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

    method height { 
        $!rc.height
    }

    method width { 
        $!rc.width
    }

    method dtypes {
        $!rc.dtypes
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
        $!rc.with_column( column.rc )
    }

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

            @aoa.push: [$series.get-data.map({$colname => $_})];
        }

        say DateTime.now, "...transpose dataset";
        $dataset = [Z] @aoa;
        $dataset
    }

    #| get index as Array
    multi method ix {
        $.index.&sbv
    }

    #| get index as Hash
    method index {
        %!index = gather {
            for 0..^$.height {
                take ( $_ => $_ )
            }
        }.Hash
    }

    #| get columns as Array
    multi method cx {
        $.get_column_names
    }

    #| get columns as Hash
    method columns {
        my @keys = |$.cx;
        @keys.map({ $_ => $++ }).Hash
    }

    #### Query Methods #####

    submethod collect( --> DataFrame ) {
        my \df = DataFrame.new;
        df.rc: $!lc.collect;
        df
    }

    method select( Array \exprs ) {
        $!lc = LazyFrameC.new( $!rc ); #autolazy 
        $!lc.select( exprs );
        $.collect
    }

    method with_columns( Array \exprs ) {
        $!lc = LazyFrameC.new( $!rc ); #autolazy 
        $!lc.with_columns( exprs );
        $.collect
    }

    #autocollect means groupby must always have an agg
    method groupby( Array \colspec ) {
        $!lc = LazyFrameC.new( $!rc ); #autolazy 
        $!lc.groupby( colspec );
        self
    }

    method agg( Array \exprs ) {
        $!lc.agg( exprs );
        $.collect
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

    method rc( $rc ) {
        $!rc = $rc
    }

    #### File Methods #####
    #### Read & Write #####

    method read_csv( Str \path ) {
        $!rc.read_csv( path )        
    }

    #### Sync Methods #####
    #### Flood & Flush  #####

    #| set raku attrs to rc_cols, rc_data, reset index
    method flood {
        self.cx: self.cx;       #gettor queries rc, settor is raku side

        my @series;
        for |$.cx -> $colname {
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
        say 'flushing...', @!data;
        self.load-from-data
    }

    ### Mezzanine methods ###  

    method T {                      #FIXME - rust not working
        my \df = $.Dan-DataFrame;
        DataFrame.new: df.T
    }

    method shape {
	    $.height, $.width 
    }

    method describe {
        my \df = $.Dan-DataFrame;
	    df.describe
    }

    method series( $k ) {
        $.column( $k ) 
    }

    method sort( &cruton ) {  #&custom-routine-to-use
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

    method grep( &cruton ) {  #&custom-routine-to-use
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
    ### Splicing ###

    #| reset attributes
    method reset( :$axis ) {

        @!data = [];

        if ! $axis {
            %!index = %()
        } else {
            %!columns = %()
        }

        $!rc = DataFrameC.new()
    }

    #| get as Array or Array of Pairs - [index|columns =>] DataSlice|Series
    method get-ap( :$axis, :$pair ) {
        given $axis, $pair {
            when 0, 0 {
                self.[*]
            }
            when 0, 1 {
                my @slices = self.[*];
                self.ix.map({ $_ => @slices[$++] })
            }
            when 1, 0 {
                self.cx.map({self.series($_)}).Array
            }
            when 1, 1 {
                my @series = self.cx.map({self.series($_)}).Array;
                self.cx.map({ $_ => @series[$++] })
            }
        }
    }

    #| set from Array or Array of Pairs - [index|columns =>] DataSlice|Series
    method set-ap( :$axis, :$pair, *@set ) {

        self.reset: :$axis;

        given $axis, $pair {
            when 0, 0 {                         # row - array
                self.load-from-slices: @set
            }
            when 0, 1 {                         # row - aops
                self.load-from-slices: @set.map(*.value);
                self.ix: @set.map(*.key)
            }
            when 1, 0 {                         # col - array
                self.load-from-series: |@set;
                self.flood
            }
            when 1, 1 {                         # col - aops
                @set.map({ $_.value.rename( $_.key ) });
                self.load-from-series: |@set.map(*.value);
                self.flood
            }
        }
    }

    sub clean-axis( :$axis ) {
        given $axis {
            when ! .so || /row/ { 0 }
            when   .so || /col/ { 1 }
        }
    }

    #| get self as a Dan::DataFrame, perform splice operation and push back
    method splice( DataFrame:D: $start = 0, $elems?, :ax(:$axis), *@replace ) {
        my $danse = self.Dan-DataFrame;

        my @res = $danse.splice( $start, $elems, :$axis, |@replace );

        %!index   = $danse.index;
        %!columns = $danse.columns;
        @!data    = $danse.data;

        #iamerejh - this will never work, need to make new rc for this self!!
        my $df-n = DataFrame.new( :@!data, :%!columns );

        #my $args = self.prep-py-args;
        #$!po.rd_push($args);

        @res
    }

#`[
    #| splice as Array or Array of Pairs - [index|columns =>] DataSlice|Series
    #| viz. https://docs.raku.org/routine/splice
    method splice( DataFrame:D: $start = 0, $elems?, :ax(:$axis) is copy, *@replace ) {
           $axis = clean-axis(:$axis);
        my $pair = @replace.first ~~ Pair ?? 1 !! 0;

        my @wip = self.get-ap: :$axis, :$pair;
        my @res = @wip.splice: $start, $elems//*, @replace;   # just an Array splice
                  self.set-ap: :$axis, :$pair, @wip;

        @res
    }
#]

#`[[[iamerejh
    ### Concat ###
    #| get self & other as Dan::DataFrames, perform concat operation and push back

    method concat( DataFrame:D $dfr, :ax(:$axis), :jn(:$join) = 'outer', :ii(:$ignore-index) ) {

        my $danse = self.Dan-DataFrame;
        my $danot = $dfr.Dan-DataFrame;

        my @res = $danse.concat( $danot, :$axis, :$join, :$ignore-index );

        %!index   = $danse.index;
        %!columns = $danse.columns;
        @!data    = $danse.data;

        $.push;
        @res
    }
#]]]
}

### Infix operators for ExprCs 
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
