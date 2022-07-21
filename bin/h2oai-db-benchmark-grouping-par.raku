#!/usr/bin/env raku
use lib '../lib';

# Benchmarks from H2O AI
# https://h2oai.github.io/db-benchmark
# https://github.com/Rdatatable/data.table/wiki/Benchmarks-%3A-Grouping

use Dan;
use Dan::Polars;
use Timer;

my \N = 1e2;   #1e6 ok, #2e9  #fails between 30 and 100  unless MVM_SPESH_DISABLED=1
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

# Basic use of start / await to run concurrently ... much slower ... perhaps can clone DF?
# FIXME this is a cock-eyed way to look at timing
my @times;
my $p1 = start { @times.push: (timer { DF.groupby(['id1']).agg([col('v1').sum]); }).[1]; }
my $p2 = start { @times.push: (timer { DF.groupby(['id1']).agg([col('v1').sum]); }).[1]; }
my $p3 = start { @times.push: (timer { DF.groupby(['id1','id2']).agg([col('v1').sum]); }).[1]; }
my $p4 = start { @times.push: (timer { DF.groupby(['id1','id2']).agg([col('v1').sum]); }).[1]; }
my $p5 = start { @times.push: (timer { DF.groupby(['id3']).agg([col('v1').sum, col('v3').mean]); }).[1]; }
my $p6 = start { @times.push: (timer { DF.groupby(['id3']).agg([col('v1').sum, col('v3').mean]); }).[1]; }
my $p7 = start { @times.push: (timer { DF.groupby(['id4']).agg([col('v1').mean,col('v2').mean,col('v3').mean]); }).[1]; }
my $p8 = start { @times.push: (timer { DF.groupby(['id4']).agg([col('v1').mean,col('v2').mean,col('v3').mean]); }).[1]; }
my $p9 = start { @times.push: (timer { DF.groupby(['id6']).agg([col('v1').sum, col('v2').sum, col('v3').sum]); }).[1]; }
my $p10 = start { @times.push: (timer { DF.groupby(['id6']).agg([col('v1').sum, col('v2').sum, col('v3').sum]); }).[1]; }
await $p1, $p2, $p3, $p4, $p5, $p6, $p7, $p8, $p9, $p10;
say @times;
say @times.sum ~ 's';
