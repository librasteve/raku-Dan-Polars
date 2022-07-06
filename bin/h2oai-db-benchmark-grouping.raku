#!/usr/bin/env raku
use lib '../lib';

# Benchmarks from H2O AI
# https://h2oai.github.io/db-benchmark
# https://github.com/Rdatatable/data.table/wiki/Benchmarks-%3A-Grouping

use Dan;
use Dan::Polars;
use Timer;

my \N = 2e5;   #2e9  
my \K = 100; 

sub randChar(\f, \numGrp, \N) {
    my @things = [sprintf(f, $_) for 1..numGrp];
    @things.roll(N)
}

sub randFloat(\numGrp, \N) {
   my @things = 1e2.rand xx numGrp; 
   @things.roll(N)
}

my \DF = DataFrame.new([
  id1 => [randChar("id%03d", K, N)],       # large groups (char)
  id2 => [randChar("id%03d", K, N)],       # large groups (char)
  id3 => [randChar("id%010d", (N.Int div K), N)],   # small groups (char)
  id4 => [[1..K].roll(N)],                 # large groups (int)
  id5 => [[1..K].roll(N)],                 # large groups (int)
  id6 => [[1..(N.Int div K)].roll(N)],     # small groups (int)
  v1  => [[1..5].roll(N)],                 # int in range [1,5]
  v2  => [[1..5].roll(N)],                 # int in range [1,5]
  v3  => [randFloat(100,N)],               # numeric e.g. 23.5749
]);

my @times;
@times.push: (timer { DF.prepare.groupby(['id1']).agg([col('v1').sum]).collect; }).[1];
@times.push: (timer { DF.prepare.groupby(['id1']).agg([col('v1').sum]).collect; }).[1];
@times.push: (timer { DF.prepare.groupby(['id1','id2']).agg([col('v1').sum]).collect; }).[1];
@times.push: (timer { DF.prepare.groupby(['id1','id2']).agg([col('v1').sum]).collect; }).[1];
@times.push: (timer { DF.prepare.groupby(['id3']).agg([col('v1').sum, col('v3').mean]).collect; }).[1];
@times.push: (timer { DF.prepare.groupby(['id3']).agg([col('v1').sum, col('v3').mean]).collect; }).[1];
@times.push: (timer { DF.prepare.groupby(['id4']).agg([col('v1').mean,col('v2').mean,col('v3').mean]).collect; }).[1];
@times.push: (timer { DF.prepare.groupby(['id4']).agg([col('v1').mean,col('v2').mean,col('v3').mean]).collect; }).[1];
@times.push: (timer { DF.prepare.groupby(['id6']).agg([col('v1').sum, col('v2').sum, col('v3').sum]).collect; }).[1];
@times.push: (timer { DF.prepare.groupby(['id6']).agg([col('v1').sum, col('v2').sum, col('v3').sum]).collect; }).[1];
say @times;
say @times.sum ~ 's';
