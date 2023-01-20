#!/usr/bin/env raku
#t/07-qpo.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 7;

use Dan;
use Dan::Polars;

my $res;

## Polars DataFrames

# read csv
my \df = DataFrame.new;
df.read_csv("../dan/src/iris.csv");

my $se = df.column("variety");
my @da = $se.get-data;
ok @da[0] ~~ 'Setosa',                                          '.column';

my $expr;
$expr  = col("petal.length");
$expr .= sum;
$res = df.groupby(["variety"]).agg([$expr]);
$res.flood;
ok $res[1][0] ~~ <Setosa Versicolor>.any,                       '.groupby';

#df.select([col("sepal.length"), col("variety")]).head;
#df.groupby(["variety"]).agg([col("petal.length").sum]).head;

my @exprs;
@exprs.push: col("petal.length").sum;
@exprs.push: col("sepal.length").mean;
#@exprs.push: col("sepal.length").min;
#@exprs.push: col("sepal.length").max;
#@exprs.push: col("sepal.length").first;
#@exprs.push: col("sepal.length").last;
#@exprs.push: col("sepal.length").unique;
#@exprs.push: col("sepal.length").count;
#@exprs.push: col("sepal.length").forward_fill;
#@exprs.push: col("sepal.length").backward_fill;
#@exprs.push: col("sepal.length").reverse;
#@exprs.push: col("sepal.length").std.alias("std");
#@exprs.push: col("sepal.length").var;
$res = df.groupby(["variety"]).agg(@exprs);
$res.flood;
ok $res[1][0] ~~ <Setosa Versicolor>.any,                       'exprs';

#df.select([col("*").exclude(["sepal.width"])]).head;
#df.select([col("*").sum]).head;

$res = df.select([
    col("sepal.length"),
    col("petal.length"),
    (col("petal.length") + (col("sepal.length"))).alias("add"),
    (col("petal.length") - (col("sepal.length"))).alias("sub"),
    (col("petal.length") * (col("sepal.length"))).alias("mul"),
    (col("petal.length") / (col("sepal.length"))).alias("div"),
    (col("petal.length") % (col("sepal.length"))).alias("mod"),
    (col("petal.length") div (col("sepal.length"))).alias("floordiv"),
]);
$res.flood;
ok $res[0][0] == 5.1,                                           'math';

$res = df.select([
    col("sepal.length"),
    col("petal.length"),
    (col("petal.length") + 7).alias("add7"),
    (7 - col("petal.length")).alias("sub7"),
    (col("petal.length") * 2.2).alias("mul"),
    (2.2 / (col("sepal.length"))).alias("div"),
    (col("sepal.length") % 2).alias("mod"),
    (col("sepal.length") div 0.1).alias("floordiv"),
]);
$res.flood;
ok $res[0][0] == 5.1,                                           'literals';

$res = df.with_column($se.rename("newcol"));
$res.flood;
ok $res[0]<newcol> ~~ 'Setosa',                                 '.with_column';

$res = df.with_columns([col("variety").alias("newnew")]);
$res.flood;
ok $res[0]<newnew> ~~ 'Setosa',                                 '.with_column';

#`[notes
df.with_column takes a Series and adds it to the df
lf.with_column takes an Expr (eg. col("variety").xx)
... so .lf.with_column is just a nicety
lf.with_columns takes an exprvec (eg. [col("variety").xx, col("sepal.length").yy]
use alias to control in place vs. new col
#]




#done-testing;

