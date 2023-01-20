#!/usr/bin/env raku
#t/07-qpo.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 7;

use Dan;
use Dan::Polars;

my $res;

#viz. https://pola-rs.github.io/polars-book/user-guide/dsl/expressions.html
#viz. https://pola-rs.github.io/polars-book/user-guide/dsl/contexts.html

my \df = DataFrame.new([
    nrs    => [1, 2, 3, 4, 5], 
    names  => ["foo", "ham", "spam", "egg", ""],
    random => [1.rand xx 5], 
    groups => ["A", "A", "B", "C", "B"],
]);

$res = df.select([col("names").unique.count.alias("smith")]);
$res.flood;
ok $res[0][0] == 5,                                             '.unique.count.alias';

#apply moved to v3
#df.select([col("nrs").apply.alias("jones")]).head;

my $expr;
$expr  = col("nrs");
$expr .= sum;
$expr .= alias("x");
$res = df.groupby(["groups"]).agg([$expr]);
$res.flood;
ok $res[2][1] ~~ Int,                                           '.groupby.agg';

$res = df.select(
    [   
        col("random").sum.alias("sum"),
        col("random").min.alias("min"),
        col("random").max.alias("max"),
        col("random").std.alias("std dev"),
        col("random").var.alias("variance"),
    ]   
);
$res.flood;
ok $res.elems ~~ 1,                                           '.sum,.min,.max,.std,.var';

$res = df.select(
    [   
        col("nrs").sum,
        col("names").sort,
        col("names").first.alias("first name"),
        #(pl.mean("nrs") * 10).alias("10xnrs"),
    ]   
);
$res.flood;
ok $res.elems ~~ 5,                                          '.sort,.first';

die; #iamerejh

df.with_columns(
    [
        col("nrs").sum.alias("nrs_sum"),
        col("random").count.alias("count"),
    ]
).head;

df.groupby(["groups"]).agg(
    [
        col("nrs").sum,  # sum nrs by groups
        col("random").count().alias("count"),  # count group members
        #col("random").filter(col("names").is_not_null).sum.alias("random_sum"),
        col("names").reverse.alias("reversed names"),
    ]
).head;

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
#- FIXME refactor for (Num), (Str) == None... (1,2,3,(Int)).are (Int) dd (1e0, NaN, (Num)).are (Num) 
#- FIXME accept List for <a b c>
#https://pola-rs.github.io/polars-book/user-guide/dsl/expressions.html#filter-and-conditionals
#- imo embedded regex/str ops are unfriendly --- aim for this in raku map/apply -- build on Dan sort/grep
#https://pola-rs.github.io/polars-book/user-guide/dsl/expressions.html#binary-functions-and-modification
#- imo embedded ternaries are quite unfriendly --- I would rather aim for this in raku map / apply
                                             



#done-testing
