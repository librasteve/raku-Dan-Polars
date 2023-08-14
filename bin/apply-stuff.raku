#!/usr/bin/env raku

use Dan;
use Dan::Polars;

#monadic
#`[
my \df = DataFrame.new([
    nrs    => [1, 2, 3, 4, 5],
    nrs2   => [2, 3, 4, 5, 6],
    names  => ["foo", "ham", "spam", "egg", ""],
    random => [1.rand xx 5],
    groups => ["A", "A", "B", "C", "B"],
]);

# viz. https://pola-rs.github.io/polars-book/user-guide/expressions/user-defined-functions/#to-map-or-to-apply

df.select([col("names").unique.count.alias("smith")]).head;

#df.select([pl.col("values").apply(lambda a: (a+1) ).alias("jones"),];
#.map(|a: i32| (a + 1) as i32)

#my $type = df.column("nrs").dtype;
#df.select([col("nrs").apply("|a: $type| (a + 1) as $type").alias("jones")]).head;

#df.select([col("nrs2").apply("|a: i32| (a + a + 1) as i32").alias("jones")]).head;
#df.select([col("nrs").apply("|a: i32| (a as f32 * 2.01) as f32").alias("jones")]).head;

df.groupby(["groups"]).agg([col("nrs").apply("|a: i32| (a + 1) as i32").alias("jones")]).head;
#]

#dyadic
my \df = DataFrame.new([
    keys => ["a", "a", "b"],
    values => [10, 7, 1],
    ovalues => [10, 7, 1],
]);

df.show;

df.select([col("*").exclude(["keys"])]).show;
df.select([col("keys").alias("solution_apply")]).show;

#`[
df.groupby(["keys"]).agg([
    col("values").alias("shift_map"),
    col("values").shift().alias("shift_expression"),
]).show;

#]

#`[
df.select(
    pl.struct(["keys", "values"])
    .apply(lambda x: len(x["keys"]) + x["values"])
    .alias("solution_apply"),
    (pl.col("keys").str.lengths() + pl.col("values")).alias("solution_expr"),
)
#]

df.select([(col("ovalues") + col("values")).alias("solution_expr")]).show;  # str and lengths tbd

#iamerejh ... get struct to work
#df.select([struct(["keys", "values"]).apply(lambda x: len(x["keys"]) + x["values"]).alias("solution_apply")]);
df.select([struct(["keys", "values", "ovalues"]).alias("struct")]).show;


