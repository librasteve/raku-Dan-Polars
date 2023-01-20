#!/usr/bin/env raku
#t/01.ser.t
#TESTALL$ prove6 ./t      [from root]
use lib '../lib';
use Test;
plan 19;

use Dan;
use Dan::Polars;

#Polars does not support index, so all Dan index tests are inverted (to nok) or commented out

## Series
my \s = $;    

# Constructors

s = Series.new([1, 3, 5, NaN, 6, 8], name => "mary");
ok s.data == [1, 3, 5, NaN, 6, 8],                                          'Series.new';
is s.name, 'mary',                                                          '.name';
s = Series.new([0.239451e0 xx 5], index => <a b c d e>);

ok s.data =~= [0.239451 xx 5],                                              '.data';
nok s.index.values ~~ ('a'..'e' Z=> 0..∞).values,                          '.index';
nok s.ix.values ~~ ('a'..'e').values,                                      '.ix';
is s.dtype, 'f64',                                                          '.dtype';

s = Series.new([b=>1, a=>0, c=>2]);
ok s.data == [1, 0, 2],                                                     'new(@aop)'; 

s = Series.new(5e0, index => <a b c d e>);
ok s.data =~= [5e1 xx 5],                                                   'new(Scalar)';

# Accessors

ok s[1]==5,                                                                 'Positional';

#`[Polars does not support index
ok s{'b'}==5,                                                               'Associative not Int';
ok s<c>==5,                                                                 'Associative <>';
ok s{"c"}==5,                                                               'Associative {}';
ok s.index.map(*.key) == 'a'..'e',                                          '.index keys';
#]

ok s.of ~~ Any,                                                             '.of';

# Operations 

ok s[*].values ~~ (5 xx 5).values,                                         'Whatever slice';
# zen slice fails (should implicitly call .data!)
##ok s[] == 5 xx 5,                                                           'Zen slice';
ok s[*-1] == 5,                                                             'Whatever Pos';
ok s[0..2] == 5 xx 3,                                                       'Range slice';
ok s[2] + 2 == 7,                                                           'Element math';
ok s.map(*+2) ~~ 7 xx 5,                                                    '.map math';
# reduction op fails Cannot resolve caller Numeric
##ok ([+] s) == 25,                                                           '[] operator';
ok s.hyper ~~ HyperSeq,                                                     '.hyper';
ok (s >>+>> 2) ~~ 7 xx 5,                                                   '>>+>>';
ok (s >>+<< s) ~~ 10 xx 5,                                                  '>>+<<';
my \t = s; 
ok (t >>+>> 2) ~~ 7 xx 5,                                                   '>>+>>';

#done-testing;
