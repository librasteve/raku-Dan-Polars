#!/usr/bin/env raku
use lib '../lib';

#`[ 
### Example Raku code generation from DSL ...

use DSL::English::DataQueryWorkflows;

my $command = 'use starwars;
select species, mass & height;
group by species;
arrange by the variables species and mass descending';

{say $_.key,  ":\n", $_.value, "\n"} for <Raku> .map({ $_ => ToDataQueryWorkflowCode($command, $_ ) });

Raku:
$obj = starwars ;
$obj = select-columns($obj, ("species", "mass", "height") ) ;
$obj = group-by( $obj, "species") ;
$obj = $obj>>.sort({ ($_{"species"}, $_{"mass"}) })>>.reverse
#]

### Equivalent of Raku example with Dan::Polars ...

use Dan;
use Dan::Polars;

sub starwars {
    my \sw = DataFrame.new;
    sw.read_csv("test_data/dfStarwars.csv");
    sw
}

my $obj;
$obj = starwars ;
$obj = select( $obj: [ <species mass height>>>.&col ]) ;
$obj = groupby($obj: [ <species> ]) ;
$obj = sort(   $obj: { $obj[$++]<species>, $obj[$++]<mass>})[*].reverse^;

$obj.show;                      # Polars print cmd truncates mid-section
#say ~$obj.Dan-DataFrame;       # convert to Dan::DataFrame to see all rows
#say ~$obj.to-dataset;          # or to a dataset for use by Data:: modules

