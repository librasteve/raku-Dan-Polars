#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Polars;

#viz. https://pola-rs.github.io/polars-book/user-guide/dsl/expressions.html

my \df = DataFrame.new([
    nrs    => [1, 2, 3, NaN, 5],
    names  => ["foo", "ham", "spam", "egg", ""],
    random => [1.rand xx 5],
    groups => ["A", "A", "B", "C", "B"],
]);
df.head;

df.prepare.select([col("names").unique.count.alias("smith&jones")]).collect.head;

my $expr;
$expr  = col("random");
$expr .= sum;
$expr .= alias("x");
df.prepare.groupby(["groups"]).agg([$expr]).collect.head;

my \out = df.prepare.select([
    col("random").sum.alias("sum"),
    col("random").min.alias("min"),
    col("random").max.alias("max"),
    col("random").std.alias("std dev"),
    col("random").var.alias("variance"),
]).collect;
out.head;


#`[
do basic (non regex) sort & filter
either sort on a col (up/down), or Dan sort
filter/grep needs a think 
out = df.select(
    [
        pl.col("names").filter(pl.col("names").str.contains(r"am$")).count(),
    ]
)
print(df)
#]

#notes
#- can use ""  for None Str
#- can use NaN for None Num
#- FIXME refactor for (Num), (Str)... (1,2,3,(Int)).are (Int) dd (1e0, NaN, (Num)).are (Num) 
#- FIXME accept List for <a b c>
#https://pola-rs.github.io/polars-book/user-guide/dsl/expressions.html#filter-and-conditionals
#- imo embedded regex/str ops are unfriendly --- aim for this in raku map/apply -- build on Dan sort/grep
#https://pola-rs.github.io/polars-book/user-guide/dsl/expressions.html#binary-functions-and-modification
#- imo embedded ternaries are quite unfriendly --- I would rather aim for this in raku map / apply
