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

#df.select([col("*").exclude(["keys"])]).show;
#df.select([col("keys").alias("solution_apply")]).show;
#df.select([(col("ovalues") + col("values")).alias("solution_expr")]).show;  # str and lengths tbd
#df.select([struct(["keys", "values"]).alias("struct")]).show;

#iamerejh

#df.select([col("nrs2").apply("|a: i32| (a + a + 1) as i32").alias("jones")]).head;
df.select([struct(["values", "ovalues"]).apply("|v: i32, o: i32| (k + v) as i32").alias("jones")]).show;
#df.select([struct(["keys", "values"]).apply("|k: str, v: i32| (k.len() + v) as i32").alias("jones")]).show;


