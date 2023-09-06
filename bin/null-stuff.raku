#!/usr/bin/env raku

use Dan;
use Dan::Polars;

my \df = DataFrame.new([
    nrs    => [1, 2, 3, 4, 5],
    nrs2   => [Num, NaN, 4, Inf, 8.3],
    #names  => ["foo", Str, "spam", "egg", ""],
    random => [1.rand xx 5],
    #groups => ["A", "A", "B", "C", "B"],
    flags  => [True,True,False,True,Bool],
]);
df.show;

#iamerejh
my \ddf := df.Dan-DataFrame;
say ~ddf;
say ddf.shape;
die;
#`[
df.select([(col("nrs") > 2)]).head;
df.select([((col("nrs") > 2).is_not)]).head;
df.select([(col("nrs2").is_nan)]).head;
df.select([(col("nrs2").is_not_nan)]).head;
df.select([(col("nrs2").is_infinite)]).head;
df.select([(col("nrs2").is_finite)]).head;
df.select([(col("nrs2").is_null)]).head;
df.select([(col("nrs2").is_not_null)]).head;
#]

my \s = Series.new( [b=>1, a=>Int, c=>2] );
s.show;

# todos
# - round trip some nulls
# - write tests
