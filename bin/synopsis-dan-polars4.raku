#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Polars;

say DateTime.now, "...loading from csv";

my \df = DataFrame.new;
df.read_csv("../dan/src/iris.csv");
df.head;

say DateTime.now, "...converting to dataset";
my \ds = df.to-dataset;

say DateTime.now, "...accessing dataset";
say ds[3;3];

