#!/usr/bin/env raku

use Dan;
use Dan::Polars;

my \u = Series.new( data => [1, 2, Num, 4, 5] );
u.show;


#`[[
my \df = DataFrame.new([
    nrs    => [1, 2, 3, 4, 5],
    nrs2   => [2, NaN, 4, Inf, Num],
    #names  => ["foo", "ham", "spam", "egg", ""],
    random => [1.rand xx 5],
    #groups => ["A", "A", "B", "C", "B"],
]);
df.show;

#df.select([(col("nrs") > 2)]).head;
#df.select([((col("nrs") > 2).is_not)]).head;

#df.select([(col("nrs2").is_nan)]).head;
df.select([(col("nrs2").is_not_nan)]).head;

df.select([(col("nrs2").is_infinite)]).head;
df.select([(col("nrs2").is_finite)]).head;
#`[
df.select([(col("nrs2").is_null)]).head;
df.select([(col("nrs2").is_not_null)]).head;
#]
#]]

my \s = Series.new( [b=>1, a=>Int, c=>2] );
s.show;

# todos
# - memory allocation of 1501208859245568 bytes failed
# - this is_null
# - round trip some nulls
# - str
# - Nil OK?
# - test
