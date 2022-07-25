#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Polars;

my \df = DataFrame.new;
df.read_csv("../dan/src/iris.csv");

df.column("sepal.length").head;

my $se;
$se = df.column("sepal.length");
#say $se.get-data;

my $se = df.column("variety");
my @da = $se.get-data;
#say @da[0];
#say @da[57];

#$se.pull;
#say $se.data;

#this version of select no longer works
#df.select(["sepal.length", "variety"]).head;

#df.groupby(["variety"]).agg([col("petal.length").sum]).head;

my $expr;
$expr  = col("petal.length");
$expr .= sum;
#df.groupby(["variety"]).agg([$expr]).head;

#df.groupby(["variety"]).agg([col("petal.length").sum,col("sepal.length").sum]).head;

my @exprs;
@exprs.push: col("petal.length").sum;
#@exprs.push: col("sepal.length").mean;
#@exprs.push: col("sepal.length").min;
#@exprs.push: col("sepal.length").max;
#@exprs.push: col("sepal.length").first;
#@exprs.push: col("sepal.length").last;
#@exprs.push: col("sepal.length").unique;
#@exprs.push: col("sepal.length").count;
#@exprs.push: col("sepal.length").forward_fill;
#@exprs.push: col("sepal.length").backward_fill;
#@exprs.push: col("sepal.length").reverse;
#@exprs.push: col("sepal.length").std;
@exprs.push: col("sepal.length").var;
#df.groupby(["variety"]).agg(@exprs).head;

#df.select([col("*").exclude(["sepal.width"])]).head;
#df.select([col("*").sum]).head;

df.select([
    col("sepal.length"),
    col("petal.length"),
    (col("petal.length") + (col("sepal.length"))).alias("add"),
    (col("petal.length") - (col("sepal.length"))).alias("sub"),
    (col("petal.length") * (col("sepal.length"))).alias("mul"),
    (col("petal.length") / (col("sepal.length"))).alias("div"),
    (col("petal.length") % (col("sepal.length"))).alias("mod"),
    (col("petal.length") div (col("sepal.length"))).alias("floordiv"),
]).head;




