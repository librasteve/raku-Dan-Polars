#!/usr/bin/env raku

use Dan;
use Dan::Polars;

my \df = DataFrame.new;
df.read_csv("../dan/src/iris.csv");

# ---------------------------------------

my $se = df.series("sepal.length");
$se.head;

#`[ a Series...
shape: (5,)
Series: 'sepal.length' [f64]
[
	5.1
	4.9
	4.7
	4.6
	5.0
]
#]

# ---------------------------------------

df.select([col("sepal.length"), col("variety")]).head;

#`[ a DataFrame...
shape: (5, 2)
┌──────────────┬─────────┐
│ sepal.length ┆ variety │
│ ---          ┆ ---     │
│ f64          ┆ str     │
╞══════════════╪═════════╡
│ 5.1          ┆ Setosa  │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 4.9          ┆ Setosa  │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 4.7          ┆ Setosa  │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 4.6          ┆ Setosa  │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 5.0          ┆ Setosa  │
└──────────────┴─────────┘
#]

# ---------------------------------------

df.groupby(["variety"]).agg([col("petal.length").sum]).head;

# -- or --
my $expr;
$expr  = col("petal.length");
$expr .= sum;
df.groupby(["variety"]).agg([$expr]).head;

# An Expression takes the form Fn(Series --> Series) {} ...

#`[ a DataFrame...
shape: (2, 2)
┌────────────┬──────────────┐
│ variety    ┆ petal.length │
│ ---        ┆ ---          │
│ str        ┆ f64          │
╞════════════╪══════════════╡
│ Versicolor ┆ 141.4        │
├╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
│ Setosa     ┆ 73.1         │
└────────────┴──────────────┘
#]

# ---------------------------------------
# Here are some unary expressions; the ```.alias``` method can be used to rename cols...

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
@exprs.push: col("sepal.length").reverse;
@exprs.push: col("sepal.length").std.alias("std");
#@exprs.push: col("sepal.length").var;
df.groupby(["variety"]).agg(@exprs).head;

#`[
shape: (2, 4)
┌────────────┬──────────────┬─────────────────────┬──────────┐
│ variety    ┆ petal.length ┆ sepal.length        ┆ std      │
│ ---        ┆ ---          ┆ ---                 ┆ ---      │
│ str        ┆ f64          ┆ list[f64]           ┆ f64      │
╞════════════╪══════════════╪═════════════════════╪══════════╡
│ Versicolor ┆ 141.4        ┆ [5.8, 5.5, ... 7.0] ┆ 0.539255 │
├╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ Setosa     ┆ 73.1         ┆ [5.0, 5.3, ... 5.1] ┆ 0.3524   │
└────────────┴──────────────┴─────────────────────┴──────────┘
#]

# ---------------------------------------
# use col("*") to select all...

df.select([col("*").exclude(["sepal.width"])]).head;
df.select([col("*").sum]).head;

# ---------------------------------------
# Can do Expression math...

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

#`[
shape: (5, 8)
┌──────────────┬──────────────┬─────┬──────┬──────┬──────────┬─────┬──────────┐
│ sepal.length ┆ petal.length ┆ add ┆ sub  ┆ mul  ┆ div      ┆ mod ┆ floordiv │
│ ---          ┆ ---          ┆ --- ┆ ---  ┆ ---  ┆ ---      ┆ --- ┆ ---      │
│ f64          ┆ f64          ┆ f64 ┆ f64  ┆ f64  ┆ f64      ┆ f64 ┆ f64      │
╞══════════════╪══════════════╪═════╪══════╪══════╪══════════╪═════╪══════════╡
│ 5.1          ┆ 1.4          ┆ 6.5 ┆ -3.7 ┆ 7.14 ┆ 0.2745   ┆ 1.4 ┆ 0.2745   │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.9          ┆ 1.4          ┆ 6.3 ┆ -3.5 ┆ 6.86 ┆ 0.285714 ┆ 1.4 ┆ 0.285714 │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.7          ┆ 1.3          ┆ 6.0 ┆ -3.4 ┆ 6.11 ┆ 0.276596 ┆ 1.3 ┆ 0.276596 │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.6          ┆ 1.5          ┆ 6.1 ┆ -3.1 ┆ 6.9  ┆ 0.326087 ┆ 1.5 ┆ 0.326087 │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 5.0          ┆ 1.4          ┆ 6.4 ┆ -3.6 ┆ 7.0  ┆ 0.28     ┆ 1.4 ┆ 0.28     │
└──────────────┴──────────────┴─────┴──────┴──────┴──────────┴─────┴──────────┘
#]

# ---------------------------------------
# And use literals...

df.select([
    col("sepal.length"),
    col("petal.length"),
    (col("petal.length") + 7).alias("add7"),
    (7 - col("petal.length")).alias("sub7"),
    (col("petal.length") * 2.2).alias("mul"),
    (2.2 / (col("sepal.length"))).alias("div"),
    (col("sepal.length") % 2).alias("mod"),
    (col("sepal.length") div 0.1).alias("floordiv"),
]).head;

#`[
shape: (5, 8)
┌──────────────┬──────────────┬──────┬──────┬──────┬──────────┬─────┬──────────┐
│ sepal.length ┆ petal.length ┆ add7 ┆ sub7 ┆ mul  ┆ div      ┆ mod ┆ floordiv │
│ ---          ┆ ---          ┆ ---  ┆ ---  ┆ ---  ┆ ---      ┆ --- ┆ ---      │
│ f64          ┆ f64          ┆ f64  ┆ f64  ┆ f64  ┆ f64      ┆ f64 ┆ f64      │
╞══════════════╪══════════════╪══════╪══════╪══════╪══════════╪═════╪══════════╡
│ 5.1          ┆ 1.4          ┆ 8.4  ┆ 5.6  ┆ 3.08 ┆ 0.431373 ┆ 1.1 ┆ 51.0     │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.9          ┆ 1.4          ┆ 8.4  ┆ 5.6  ┆ 3.08 ┆ 0.4489   ┆ 0.9 ┆ 49.0     │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.7          ┆ 1.3          ┆ 8.3  ┆ 5.7  ┆ 2.86 ┆ 0.468085 ┆ 0.7 ┆ 47.0     │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.6          ┆ 1.5          ┆ 8.5  ┆ 5.5  ┆ 3.3  ┆ 0.478261 ┆ 0.6 ┆ 46.0     │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 5.0          ┆ 1.4          ┆ 8.4  ┆ 5.6  ┆ 3.08 ┆ 0.44     ┆ 1.0 ┆ 50.0     │
└──────────────┴──────────────┴──────┴──────┴──────┴──────────┴─────┴──────────┘
#]

# ---------------------------------------
# There is a variant of with_column (for Series) and with_columns (for Expressions)

df.with_column($se.rename("newcol")).head;
df.with_columns([col("variety").alias("newnew")]).head;

