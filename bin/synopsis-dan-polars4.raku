#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Polars;

my \df = DataFrame.new;
df.read_csv("../dan/src/iris.csv");
df.head;

my \ds = df.to-dataset;
say ds[3;3];

