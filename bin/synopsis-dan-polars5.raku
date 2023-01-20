#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Polars;


say DateTime.now, "...loading from csv";

my \df = DataFrame.new;
#df.read_csv("/tmp/docdir/1mSalesRecords.csv");
df.read_csv("../dan/src/iris.csv");
df.head;

#say df.to-dataset[300;12];
say df.to-dataset;

