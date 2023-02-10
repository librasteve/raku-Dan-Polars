#!/usr/bin/env raku

use Dan;
use Dan::Polars;

#`[
### drop
my \df1 = DataFrame.new(['Ray Type' => ["α", "β", "X", "γ"]]);
#df1.head;
my \df2 = df1.drop('Ray Type');
#df2.head;
#say df2.is_empty;

### hstack
my \df3 = DataFrame.new(["Element" => ["Copper", "Silver", "Gold"]]);
my \se1 = Series.new(name => "Proton", [29, 47, 79]);
my \se2 = Series.new(name => "Electron", [29, 47, 79]);

my \df4 = df3.hstack([se1,se2]);
df4.head;

### vstack
my \df5 = DataFrame.new([
    "Element" => ["Copper", "Silver", "Gold"],
    "Melting Point (K)" => [1357.77, 1234.93, 1337.33],
]);
#df5.head;
my \df6 = DataFrame.new([
    "Element" => ["Platinum", "Palladium"],
    "Melting Point (K)" => [2041.4, 1828.05],
]);
#df6.head;
my \df7 = df5.vstack(df6);
df7.head;

### join
my \dfa = DataFrame.new(
        [['a', 1], ['b', 2]],
        columns => <letter number>,
);
dfa.head;

my \dfc = DataFrame.new(
        [['c', 3, 'cat'], ['d', 4, 'dog']],
        columns => <letter number animal>,
);
dfc.head;

#<left inner outer asof cross>
#my $x=dfa.join( dfc, :jointype<left> );
my $x = dfa.join: dfc;
$x.head;

### se_concat
my \s = Series.new( [b=>1, a=>0, c=>2] );
my \t = Series.new( [f=>1, e=>0, d=>2] );

my $u = s.concat: t;                # concatenate
$u.show;
#]

### df_concat
my \dfa = DataFrame.new(
        [['a', 1], ['b', 2]],
        columns => <letter number>,
);

my \dfb = DataFrame.new(
        [['c', 3], ['d', 4]],
        columns => <letter number>,
);

my \dfc = DataFrame.new(
        [['c', 3, 'cat'], ['d', 4, 'dog']],
        columns => <letter number animal>,
);

my $y1 = dfa.concat: dfc;            # row-wise / outer join is default
$y1.head;

my $y2 = dfa.concat( dfc, join => 'inner' );
$y2.head;

my $y3 = dfa.concat( dfc, join => 'left' );
$y3.head;

my $y4 = dfa.concat( dfc, join => 'right' );
$y4.head;


my \dfd = DataFrame.new( [['bird', 'polly'], ['monkey', 'george']],
                         columns=> <animal name>,                   );

my $y5 = dfb.concat: dfd, axis => 1;             #column-wise
$y5.head;

