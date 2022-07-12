#!/usr/bin/env raku

use lib '../lib';

use Dan;
use Dan::Polars;


say DateTime.now, "...loading from csv";

my \df = DataFrame.new;
#df.read_csv("/tmp/docdir/5mSalesRecords.csv");
df.read_csv("../dan/src/iris.csv");
df.head;

say DateTime.now, "...converting to dataset";
my $dataset = [;];
my $colname;
my $series;

#[
#Strat1: cols over rows
loop ( my $j=0; $j < df.shape[1]; $j++ ) {    #for each Series column
    $colname = df.cx[$j];
    $series  = df.column($colname);
    say DateTime.now, "...column $colname";

    loop ( my $i=0; $i < df.shape[0]; $i++ ) {
        $dataset[$i;$j] = ($colname => $series[$i])
    }
}
#]

#`[
#Strat1: cols over rows

#]


say DateTime.now, "...accessing dataset";
say $dataset[3;3];

# df.column is tromboning - should be able to just get col data 
