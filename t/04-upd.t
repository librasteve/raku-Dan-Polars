#!/usr/bin/env raku
#t/04.upd.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 18;

use Dan;
use Dan::Pandas;

## Series - Updates

my \s = $;
my \t = $;

s = Series.new([b=>1, a=>0, c=>2]);
s.ix: <b c d>;
is ~s, "b    1\nc    0\nd    2\nName: anon, dtype: int64",			's.ix';

s.splice: *-1;
ok s.elems ==2,                                                                 's.pop';

s.splice( 1,2,(j => NaN) );
ok s.ix[1] eq 'j',                                                          	's.splice';

s = Series.new([b=>1, a=>0, c=>2]);
t = Series.new([f=>1, e=>0, d=>2]);
ok (s.concat: t).ix[3] eq 'f',                                              	's.concat';

## DataFrames - Updates 

my $df2 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4], dtype => Num),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);

$df2.ix: <a b c d>;
is $df2.index, "a\t0\nb\t1\nc\t2\nd\t3",                                        'df.ix';

$df2.cx: <a b c d e f>;
is $df2.series('a').dtype, "<class 'numpy.int64'>",			  	'df.cx';

$df2.splice: *-1; 
ok $df2.ix.elems == 3,                                                          'df.pop [row]';

$df2.splice: :ax(1), *-1;
ok $df2.cx.elems == 5,                                                          'df.pop [col]';

my $df3 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4], dtype => Num),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);

my $ds = $df3[1];
$ds.splice(3,1,(D => 7));
$ds.name = '7';

my $se = $df3.series: <A>;
$se.splice(2,1,(2 => 7));
#$se.name = 'X';       ##Dan::Pandas::Series name immutable, adjust Dan::Series to match

$df3.splice(2,1,$ds);
ok $df3[2]<D> == 7,                                                             'df.splice array [row]';

$df3.splice(:ax(1),2,2,(X=>$se));     ##note now aop
ok $df3[2]<X> == 7,                                                             'df.splice array [col]';

my $df4 = DataFrame.new([
        A => 1.0,
        B => Date.new("2022-01-01"),
        C => Series.new(1, index => [0..^4], dtype => Num),
        D => [3 xx 4],
        E => Categorical.new(<test train test train>),
        F => "foo",
]);

$df4.splice( axis => 'row',1,2,(j => $ds) );
ok $df4<j><D> == 7,                                                             'df.splice pair [row]';

$df4.splice( :ax(1),3,2,(X => $se) );
ok $df4<j><X> == 1,                                                             'df.splice pair [col]';

my \dfa = DataFrame.new(
        [['a', 1], ['b', 2]],
        columns => <letter number>,
);
my \dfb = DataFrame.new(
        [['c', 3], ['d', 4]],
        columns => <letter number>,
);

dfa.concat: dfb;
ok dfa[2;1] == 3,                                                                   'df.concat [row]';
ok dfa.ix[3] eq '1⋅1',                                                              'df.concat dupes';

dfa.concat: dfa, :ii;
ok dfa.ix[7] == 7,                                                                  'df.concat ii';

my \dfc = DataFrame.new(
        [['c', 3, 'cat'], ['d', 4, 'dog']],
        columns => <letter number animal>,
);
my \dfa2 = DataFrame.new(
        [['a', 1], ['b', 2]],
        columns => <letter number>,
);

dfa2.concat: dfc;
is dfa2[0;2], "NaN",                                                                'df.concat [outer]';

my \dfa3 = DataFrame.new(
        [['a', 1], ['b', 2]],
        columns => <letter number>,
);
dfa3.concat: dfc, join => 'inner';
ok dfa3.cx.elems == 2,                                                              'df.concat [inner]';

my \dfa4 = DataFrame.new(
        [['a', 1], ['b', 2]],
        columns => <letter number>,
);
my \dfd = DataFrame.new([['bird', 'polly'], ['monkey', 'george']],
                          columns=> <animal name>                );
dfa4.concat: dfd, axis => 1;
is dfa4[1;2], "monkey",                                                               'df.concat [col]';

#done-testing;
