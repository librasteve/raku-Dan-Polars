#!/usr/bin/env raku

use Dan;
use Dan::Polars;

my \df = DataFrame.new([
    nrs    => [1, 2, 3, 4, 5],
    nrs2   => [2, 3, 4, 5, 6],
    names  => ["foo", "ham", "spam", "egg", ""],
    random => [1.rand xx 5],
    groups => ["A", "A", "B", "C", "B"],
]);
df.show;

#viz. https://pola-rs.github.io/polars-book/user-guide/expressions/operators/#logical
#(gt >, lt <, ge >=, le <=, eq ==, ne !=, and &&, or ||)
#df.select([(col("nrs") > 2).alias("jones")]).head;
#df.select([(col("nrs") >= 2).alias("jones")]).head;
#df.select([(col("nrs") < 2).alias("jones")]).head;
#df.select([(col("nrs") <= 2).alias("jones")]).head;
#df.select([(col("nrs") == 2).alias("jones")]).head;
#df.select([(col("nrs") != 2).alias("jones")]).head;
#df.select([((col("nrs") >= 2) && (col("nrs2") == 5)) .alias("jones")]).head;
#df.select([((col("nrs") >= 2) || (col("nrs2") == 5)) .alias("jones")]).head;

#viz. https://pola-rs.github.io/polars-book/user-guide/concepts/contexts/#filter
df.filter([(col("nrs") != 4).alias("jones")]).head;

#viz. https://pola-rs.github.io/polars-book/user-guide/expressions/aggregation/#conditionals
df.groupby(["groups"]).agg([col("nrs")]).sort(["groups"]).head;
#df.filter([(col("nrs") != 4).alias("jones")]).head;
