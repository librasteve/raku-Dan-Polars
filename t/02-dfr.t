#!/usr/bin/env raku
#t/02.dfr.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 33;

use Dan;
use Dan::Polars;

## DataFrames

my \d = DataFrame.new( [[rand xx 4] xx 6], );
ok d.columns.elems == 4,                                                    'new auto';

my \dates = (Date.new("2022-01-01"), *+1 ... *)[^6];    #say dates;
my \df = DataFrame.new( data => [[0..3] xx 6], index => dates, columns => <A B C D> );

ok df.columns.elems == 4,                                                   'new DataFrame';
ok df.elems == 6,                                                           '.elems';
#Polars does not implement index
#is ~df.index, "2022-01-01\t0\n2022-01-02\t1\n2022-01-03\t2\n2022-01-04\t3\n2022-01-05\t4\n2022-01-06\t5", '.index';
ok df.cx == 0..3,                                                           '.cx';

# Positional
df.flood;
ok df[0;1] == 1,                                                            '[0;1]';
ok df[*;1] == (1,1,1,1,1,1),                                                '[*;1]';
ok df[0;*] == (1,2,3,4),                                                    '[0;*]';

is df[2].^name, 'Dan::DataSlice',                                           '[2]';
my $s1 = df[2];
my @s2 = [$s1 xx 2];
ok df[0,3] == @s2,                                                          '[0,3]';
ok df[0..1] == @s2,                                                         '[0..1]';

my @s6 = [$s1 xx 6];
ok df[*] == @s6,                                                            '[*]';

ok df[0][1] == 1,                                                           '[0][0]';
ok df[*][1] ~~ Dan::Polars::Series,                                         '[*][1]';
ok df[0][*] >>==<< (0,1,2,3),                                               '[0][*]';

ok df[0..1] >>==<< @s2,                                                     '[0..1]';
ok df[0..*-5] >>==<< @s2,                                                   '[0..*-5]';
ok df[0..*-5][1].ix >>==<< (0,1),                                           '[0..*-5][1]';
ok df[0..*-5][0..*-2].cx == <A B C>,                                        '[0..*-5][0..*-2]';

is df[0..1].^name, "Array[Dan::DataSlice]",                                 '[0..1].^name';
ok df[0..1][1].elems == 2,                                                  '[0..1][1]';
ok df[0..1][*].ix >>==<< (0,1),                                             '[0..1][*]';
ok df[0]^ ~~ Dan::Polars::DataFrame,                                        '[0]^';

ok df[0..1]^.cx >>eq<< <A B C D>,                                           '[0..1]^';
ok df[*][1].elems == 6,                                                     '[*][1]';
is df[0..*-2][1].^name, "Dan::Polars::Series",                              '[0..*-2][1]';
ok df[0..1][1,2].cx >>eq<< <B C>,                                           '[0..*-2][1,2]';
ok df[0..*-2][1..*-1].cx >>eq<< <B C D>,                                    '[0..*-2][1..*-1]';
ok df[0..1][*].cx >>eq<< <A B C D>,                                         '[0..1][*]';

# Associative

is df{'0'}.^name, "Dan::DataSlice",                                         '{dates[0]}'; 
ok df{'0'..'1'}^.cx >>eq<< <A B C D>,                                       '{dates[0..1]}'; 
ok df{'0'}{"C"} == 2,                                                       '{dates[0]}{"C"}';
ok df{'0'}<D> == 3,                                                         '{dates[0]}<D>';
ok df{'0'..'1'}<A>.ix >>==<< (0,1),                                         '{dates[0..1]}<A>';
ok df[*]<A C>.cx >>==<< <A C>,                                              '[*]<A C>';
ok df.series(<C>).elems == 6,                                               '.series: <C>';

#done-testing;

#EOF
