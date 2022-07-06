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
df.prepare.groupby(["variety"]).agg(@exprs).collect.head;

## todos from https://github.com/p6steve/polars/blob/master/nodejs-polars/src/lazy/dsl.rs
#skip: all __add__ operators
#skip: to_string (what for)
#skip: binary - cmps
#skip: is_not, is_not, is_null, is_not_null - think
#skip: is_infinite, is_finite, is_nan, is_not_nan -think
#skip: n-unique, arg_unique, unique_stable - think
#skip: list (need to add Array dtype)
#skip: quantile                     - arity
#skip: agg_groups                   - internal detail
#skip: value_counts, unique_counts  - internal detail
#skip: cast                         - arity
#skip: sort_with, sort_by           - arity
#skip: arg_sort                     - internal detail
#skip: arg_max, arg_min             - think
#skip: take                         - arity
#skip: shift, shift_and_fill        - arity
#skip: fill_null, fill_..., fill_nan - think
#skip: drop_nulls, drop_nans        - think
#skip: filter                       - arity
#skip: is_first, is_unique          - think
#skip: explode                      - array
#skip: tail, head                   - arity
#skip: slice                        - think
#skip: round                        - arity
#skip: floor, ceil                  - ^^^^ method not found in `Expr`
#skip: clip                         - arity
#skip: abs                          - ^^^^ method not found in `Expr`
#464

#iamerejh - alias && lf/df.with_column

