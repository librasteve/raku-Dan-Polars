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

df.select([col("names").unique.count.alias("smith")]).head;

#apply moved to v3
df.select([col("nrs").apply.alias("jones")]).head;
