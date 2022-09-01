#!/usr/bin/env raku
#t/03.dfo.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 24;

use Dan;
use Dan::Polars;

## DataFrames - Operations

#no index in Dan::Polars
my \df = DataFrame.new( [[0..3] xx 6], columns => <A B C D> );

# Math
df.flood;
ok df.map(*.map(*+2)) >>==<< ((2,3,4,5),(2,3,4,5),(2,3,4,5),(2,3,4,5),(2,3,4,5),(2,3,4,5)), '.map.map';
ok df[1].map(*+3) >>==<< (3,4,5,6),                                                         '.[1].map';
ok df[1][1,2].map(*+3) >>==<< (4,5),                                                        '.[1][1,2].map';
ok ([+] df[1;*]) == 6,                                                                      '[+] df[1;*]';
ok ([+] df[*;1]) == 6,                                                                      '[+] df[*;1]';
ok ([+] df[*;*]) == 36,                                                                     '[+] df[*;*]';
ok ([Z] @ = df) >>==<< ((0,0,0,0,0,0),(1,1,1,1,1,1),(2,2,2,2,2,2),(3,3,3,3,3,3)),           '[Z] @=df';
ok ([Z] df.data) >>==<< ((0,0,0,0,0,0),(1,1,1,1,1,1),(2,2,2,2,2,2),(3,3,3,3,3,3)),          '[Z] df.data';

my \tf = df.T;
ok tf.data >>eq<< ([Z] df.data),                                                            'df.T';

# Hyper
ok (df >>+>> 2)[1;1] == 3,                                                              'df >>+>> 2';
ok (df >>+<< df)[1;1] ==2,                                                              'df >>+<< df'; 

# Head & Tail
ok df[0..^3]^[1;1] == 1,                                                                '.head';
ok df[(*-3..*-1)]^[1;1] == 1,                                                           '.tail';

# Describe
# no Dan::Polars::Series describe
#ok df[*]<A>.describe<count> == 6,                                                       's.describe';
#NB. assoc accessor is export Dan :ALL only
ok df.describe[0;0] == 6,                                                               'df.describe';

# Sort
#viz. https://docs.raku.org/routine/sort#(List)_routine_sort

ok (df.sort: { .[1] })[1][1] == 1,                                                      '.sort: {.[1]}';
ok (df.sort: { .[1], .[2] })[1][1] == 1,                                                '.sort: {.[1],.[2]}';
ok (df.sort: { -.[1] })[1][1] == 1,                                                     '.sort: {-.[1]}';
ok (df.sort: { df[$++]<C> })[1][1] == 1,                                                '.sort: {df[$++]<C>}';
ok (df.sort: { df.ix[$++] })[1][1] == 1,                                                '.sort: {df.ix[$++]}';
ok (df.sort: { df.ix.reverse.[$++] })[1][1] == 1,                                       '.sort: {df.ix.reverse}';

my @data = [Z] ([0.1, 0.2 ... 0.6] xx 4);
my \dg = DataFrame.new( :@data, columns => <A B C D> );

# Grep not destructive for Dan::Polars 
my \gg = dg.grep( { .[1] < 0.5 } );
ok gg.height == 4,                                                                      '.grep: {.[1] < 0.5}';
#ok df.grep( { df.ix[$++] eq <2022-01-02 2022-01-06>.any } ).elems == 2,                 '.grep index (multiple)';

my \df2 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4]),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);
ok df2.columns.elems == 6,                                                              '.columns';
is df2.dtypes, "f64 str i32 i32 str str",                                               '.dtypes';

is df2.shape, "4 6",                                                                  '.shape';

#done-testing;
