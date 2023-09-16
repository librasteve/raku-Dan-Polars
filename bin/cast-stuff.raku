#!/usr/bin/env raku

use Dan;
use Dan::Polars;

#casting
#`[
my \df = DataFrame.new([
    integers            => [1, 2, 3, 4, 5],
    big_integers        => [1, 10000002, 3, 10000004, 4294967297],
    floats              => [4.0, 5.0, 6.0, 7.0, 8.0],
    floats_with_decimal => [4.532, 5.5, 6.5, 7.5, 8.5],
]);
df.show;

df.select([
    col("integers").cast("f32").alias("integers_as_floats"),
    col("floats").cast("i32").alias("floats_as_integers"),
    col("floats_with_decimal").cast("i32").alias("floats_with_decimal_as_integers"),
]).show;
#]

#`[
my \dfs = DataFrame.new([
    integers         => [1, 2, 3, 4, 5],
    floats           => [4.0, 5.03, 6.0, 7.0, 8.0],
    strings          => <4.0 5.0 6.0 7.0 8.0>>>.Str.Array,
]);
dfs.show;

dfs.select([
    col("integers").cast("str"),
    col("floats").cast("str"),
    col("strings").cast("f32"),
]).show;
#]

#[
my \dfs = DataFrame.new([
    integers => [-1, 0, 2, 3, 4], 
    floats => [0.0, 1.0, 2.0, 3.0, 4.0],
    bools => [True, False, True, False, True],
]);
dfs.show;

dfs.select([
    col("integers").cast("bool"),
    col("floats").cast("bool"),
    col("bools").cast("i32"),
]).show;
#]
