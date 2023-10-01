#!/usr/bin/env raku

use Dan;
use Dan::Polars;

#monadic
#[
my \df = DataFrame.new([
    nrs    => [1, 2, 3, 4, 5],
    nrs2   => [2, 3, 4, 5, 6],
    names  => ["foo", "ham", "spam", "egg", ""],
    random => [1.rand xx 5],
    groups => ["A", "A", "B", "C", "B"],
]);
df.show;
# viz. https://pola-rs.github.io/polars-book/user-guide/expressions/user-defined-functions/#to-map-or-to-apply

#my $type = df.column("nrs").dtype;
#df.select([col("nrs").apply("|a: $type| (a + 1) as $type").alias("jones")]).head;

#df.select([col("nrs2").apply("|a: i32| (a + a + 1) as i32").alias("jones")]).head;
#df.select([col("nrs").apply("|a: i32| (a as f32 * 2.01) as f32").alias("jones")]).head;

df.groupby(["groups"]).agg([col("nrs").apply("|a: i32| (a + 1) as i32").alias("jones")]).head;
#]

#dyadic
#`[
my \df2 = DataFrame.new([
    keys => ["a", "a", "b"],
    values => [10, 7, 1],
    ovalues => [10, 7, 1],
]);
df2.show;

#df2.select([(col("ovalues") + col("values")).alias("solution_expr")]).show;  # str and lengths tbd
#df2.select([struct(["keys", "values"]).alias("struct")]).show;
#df2.select([struct(["values", "ovalues"]).apply("|a: i32, b: i32| (a + b) as i32").alias("jones")]).show;
#df2.select([struct(["keys", "values"]).apply("|a: str, b: i32| (a.len() as i32 + b) as i32").alias("jones")]).show;
df2.groupby(["keys"]).agg([struct(["keys", "values"]).apply("|a: str, b: i32| (a.len() as i32 + b) as i32").alias("jones")]).show;
#]


#`[ todo
- create apply section in synopsis
- ditto README
- ditto test
#]

