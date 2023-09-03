#!/usr/bin/env raku

use Dan;
use Dan::Polars;

my \df = DataFrame.new([
    nrs    => [1, 2, 3, 4, 5],
    nrs2   => [2, NaN, 4, Inf, 6],
    #nrs2   => [2, NaN, 4, Inf, Nil],
    names  => ["foo", "ham", "spam", "egg", ""],
    random => [1.rand xx 5],
    groups => ["A", "A", "B", "C", "B"],
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


