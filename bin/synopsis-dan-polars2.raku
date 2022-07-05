#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Polars;

my \df = DataFrame.new;
df.read_csv("../dan/src/iris.csv");

df.column("sepal.length").head;
df.select(["sepal.length", "variety"]).head;

df.prepare().groupby(["variety"]).agg([col("petal.length").sum]).collect.head;

my $expr;
$expr  = col("petal.length");
$expr .= sum;
df.prepare().groupby(["variety"]).agg([$expr]).collect.head;

df.prepare().groupby(["variety"]).agg([col("petal.length").sum,col("sepal.length").sum]).collect.head;

my @exprs;
@exprs.push: col("petal.length").sum;
@exprs.push: col("sepal.length").sum;
df.prepare().groupby(["variety"]).agg(@exprs).collect.head;

