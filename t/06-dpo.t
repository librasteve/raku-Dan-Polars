#!/usr/bin/env raku
#t/06-dpo.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 8;

use Dan;
use Dan::Polars;

#my $t-path = '../bin/test_data';
#my $t-path = ?%*ENV<PSIXSTEVE> ?? '../bin/test_data' !! %?RESOURCES<bin/test_data>;
#my $t-path = ?%*ENV<PSIXSTEVE> ?? '../resources/test_data' !! %?RESOURCES<bin/test_data>;

my $t-path = %?RESOURCES<test_data>.absolute;
warn "t-path is $t-path";

## Polars DataFrames

# read csv
my \df0 = DataFrame.new;
#df0.read_csv("$t-path/iris.csv");
df0.read_csv("$t-path/iris.csv");
my $column = df0.column("sepal.length");
my $select = df0.select([col("sepal.length"), col("variety")]);
$select.flood;
ok $select[0][0] == 5.1e0,                                                  'flood';

#with_col
my \df = DataFrame.new( [[rand xx 4] xx 6], columns => <A B C D> );
my \se = Series.new([1, 3, 5, 6, 8, 10], name => 'E' );
df.with_column(se);
df.flood;
ok df[0][4] == 1,                                                           'with_col';

# Data Accessors [row;col]
ok df[0;4] == 1,                                                            '[0;4] get';
df[0;4] = 3;                # must manual flush
#df.flush;                  # FIXME too verbose for zef install
#df.flood;
ok df[0;4] == 3,                                                            '[0;4] set';

ok df ~~ DataFrame:D,                                                       'DataFrame:D';
ok df[0] ~~ Dan::DataSlice,                                                 'DataSlice';
ok df[0]<E> == 3,                                                           '[0]<E>';

# Object Accessors & Slices (see note 1)
ok df[*]<A> ~~ Series:D,                                                    '[*]<A>';
ok df[0..*-2][1..*-1].elems == 5,                                           '2d Slices';

#done-testing;

