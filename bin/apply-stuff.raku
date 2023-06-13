#!/usr/bin/env raku

use Dan;
use Dan::Polars;

my $res;

my \df = DataFrame.new([
    nrs    => [1, 2, 3, 4, 5],
    names  => ["foo", "ham", "spam", "egg", ""],
    random => [1.rand xx 5],
    groups => ["A", "A", "B", "C", "B"],
]);

# viz. https://pola-rs.github.io/polars-book/user-guide/expressions/user-defined-functions/#to-map-or-to-apply

df.select([col("names").unique.count.alias("smith")]).head;

#df.select)[pl.col("values").apply(lambda a: (a+1) ).alias("jones"),];
#.map(|a: i32| (a + 1) as i32)

#my $type = df.column("nrs").dtype;
#df.select([col("nrs").apply("|a: $type| (a + 1) as $type").alias("jones")]).head;

#monadic
#df.select([col("nrs").apply("|a: i32| (a + 1) as i32").alias("jones")]).head;
#df.select([col("nrs").apply("|a: i32| (a as f32 * 2.01) as f32").alias("jones")]).head;

df.groupby(["groups"]).agg([col("nrs").apply("|a: i32| (a + 1) as i32").alias("jones")]).head;




