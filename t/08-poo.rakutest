#!/usr/bin/env raku
#t/08-poo.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 6;

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
ok $res.elems ~~ 5,                                           '.sort,.first';

$res = df.with_columns(
    [
        col("nrs").sum.alias("nrs_sum"),
        col("random").count.alias("count"),
    ]
);
$res.flood;
ok $res[0]<count> ~~ 5,                                       '.with_columns';

df.groupby(["groups"]).agg(
    [
        col("nrs").sum,  # sum nrs by groups
        col("random").count().alias("count"),  # count group members
        #col("random").filter(col("names").is_not_null).sum.alias("random_sum"), FIXME add is_not_null
        col("names").reverse.alias("reversed names"),
    ]
);
$res.flood;
ok $res[0]<names> ~~ 'foo',                                   '.with_columns';

#done-testing
