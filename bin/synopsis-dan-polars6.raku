#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Polars;

sub starwars {
    my \sw = DataFrame.new;
    sw.read_csv("test_data/dfStarwars.csv");
    sw
}

my $obj;
$obj = starwars ;
$obj.= select([col("species"), col("mass"), col("height")] ) ;
$obj.= groupby(["species"]) ;
#$obj.= sort({ $obj[$obj.elems-$++]{"species"}, $obj[$++]<mass> });
#$obj.= sort({ say $_; $obj[$++]{"species"}, $obj[$++]<mass> });
#$obj.= sort({ say $_; $_[0]});
#$obj.= sort({$^b[0] cmp $^a[0]});
my $obk = $obj.Dan-DataFrame;
say $obk.columns;
#$obj.= sort({ say $_; $_[$obj.column<species>]});

#`[
$obj = select-columns($obj, ("species", "mass", "height") ) ;
$obj = group-by( $obj, "species") ;
$obj = $obj>>.sort({ ($_{"species"}, $_{"mass"}) })>>.reverse
#]

#$obj.show;
#say ~$obj.Dan-DataFrame;

#say sw.to-dataset;
