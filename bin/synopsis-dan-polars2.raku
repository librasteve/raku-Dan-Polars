#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Polars;

my \df = DataFrame.new;
df.read_csv("../dan/src/iris.csv");

df.column("sepal.length").head;
df.select(["sepal.length", "variety"]).head;

df.prepare.groupby(["variety"]).agg([col("petal.length").sum]).collect.head;

my $expr;
$expr  = col("petal.length");
$expr .= sum;
df.prepare.groupby(["variety"]).agg([$expr]).collect.head;

df.prepare.groupby(["variety"]).agg([col("petal.length").sum,col("sepal.length").sum]).collect.head;

my @exprs;
@exprs.push: col("petal.length").sum;
#@exprs.push: col("sepal.length").mean;
#@exprs.push: col("sepal.length").min;
@exprs.push: col("sepal.length").max;
df.prepare.groupby(["variety"]).agg(@exprs).collect.head;

## todos from https://github.com/p6steve/polars/blob/master/nodejs-polars/src/lazy/dsl.rs
#skip: all __add__ operators
#skip: to_string (what for)
#skip: binary - cmps
#skip: is_not, is_not, is_null, is_not_null
#skip: is_infinite, is_finite, is_nan, is_not_nan


#iamerejh - alias && lf/df.with_column

