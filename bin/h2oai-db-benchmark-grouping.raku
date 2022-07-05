#!/usr/bin/env raku
use lib '../lib';

use Dan;
use Dan::Polars;

my \N = 30;   #2e9  #fails between 30 and 50
my \K = 100; 

sub randChar(\f, \numGrp, \N) {
    my @things = [sprintf(f, $_) for 1..numGrp];
    @things[[1..numGrp].roll(N)];
}

sub randFloat(\numGrp, \N) {
   my @things = 1e2.rand xx numGrp; 
   @things[[1..numGrp].roll(N)];
}

my \DF = DataFrame.new([
  id1 => [randChar("id%03d", K, N)],       # large groups (char)
  #id2 => [randChar("id%03d", K, N)],       # large groups (char)
  ##id3 => [randChar("id%010d", (N div K), N)],   # small groups (char)
  #id4 => [[1..K].roll(N)],                 # large groups (int)
  #id5 => [[1..K].roll(N)],                 # large groups (int)
  ##id6 => [[1..(N div K)].roll(N)],            # small groups (int)
  #v1  => [[1..5].roll(N)],                 # int in range [1,5]
  #v2  => [[1..5].roll(N)],                 # int in range [1,5]
  #v3  => [randFloat(100,N)],                # numeric e.g. 23.5749
]);
DF.head;





die;







my \df = DataFrame.new;
df.read_csv("../dan/src/iris.csv");

df.column("sepal.length").head;
df.select(["sepal.length", "variety"]).head;

df.prepare().groupby(["variety"]).agg([col("petal.length").sum]).collect.head;

my $expr;
$expr  = col("petal.length");
$expr .= sum;
df.prepare().groupby(["variety"]).agg([$expr]).collect.head;

df.prepare().groupby(["variety"]).agg([col("petal.length").sum,col("sepal.length").sum]).collect.head;

my @exprs;
@exprs.push: col("petal.length").mean;
@exprs.push: col("sepal.length").mean;
df.prepare().groupby(["variety"]).agg(@exprs).collect.head;

