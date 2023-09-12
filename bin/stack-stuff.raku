#!/usr/bin/env raku

use Dan;
use Dan::Polars;

#`[
### drop
my \df1 = DataFrame.new(['Ray Type' => ["α", "β", "X", "γ"]]);
df1.show;
my \df2 = df1.drop(['Ray Type']);
df2.show;
say df2.is_empty;
#]

#`[
### hstack
### now as private method as not part of API
my \df3 = DataFrame.new(["Element" => ["Copper", "Silver", "Gold"]]);
my \se1 = Series.new(name => "Proton", [29, 47, 79]);
my \se2 = Series.new(name => "Electron", [29, 47, 79]);

say "hstack....";
my \df4 = df3.hstack([se1,se2]);
df4.show;

### vstack
### now as private method as not part of API
my \df5 = DataFrame.new([
    "Element" => ["Copper", "Silver", "Gold"],
    "Melting Point (K)" => [1357.77, 1234.93, 1337.33],
]);
#df5.show;
my \df6 = DataFrame.new([
    "Element" => ["Platinum", "Palladium"],
    "Melting Point (K)" => [2041.4, 1828.05],
]);
#df6.show;

say "vstack....";
my \df7 = df5.vstack(df6);
df7.show;
#]





#[
### join

my \df_customers = DataFrame([
    customer_id => [1, 2, 3],
    name => ["Alice", "Bob", "Charlie"],
]);
df_customers.show;

my \df_orders = DataFrame([
    order_id => ["a", "b", "c"],
    customer_id => [1, 2, 2],
    amount => [100, 200, 300],
]);
df_orders.show;

my \df_inner_join = df_customers.join(df_orders, on => "customer_id", jointype => "inner");
df_inner_join.show;

my \df_left_join = df_customers.join(df_orders, on => "customer_id", jointype => "left");
df_left_join.show;
die;
#]

##<left right inner outer>; # asof cross>;


#`[ 
#for <left right inner outer> -> $jointype {
for <left right outer> -> $jointype {
    say "$jointype join...";
    dfa.join( dfc, :$jointype ).show
}
#]






#`[ 
###cross join
my \df_colors = DataFrame([ 
    color => ["red", "blue", "green"],
]);
df_colors.show;

my \df_sizes = DataFrame([
    size => ["S", "M", "L"],
]);
df_sizes.show;

my \df_crossjoin = df_colors.join( df_sizes, :jointype<cross> );
df_crossjoin.show;
#]

#`[
### se_concat
my \s = Series.new( [b=>1, a=>0, c=>2] );
my \t = Series.new( [f=>1, e=>0, d=>2] );

my $u = s.concat: t;                # concatenate
$u.show;
#]

#`[
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
$y1.show;

my $y2 = dfa.concat( dfc, join => 'inner' );
$y2.show;

my $y3 = dfa.concat( dfc, join => 'left' );
$y3.show;

my $y4 = dfa.concat( dfc, join => 'right' );
$y4.show;


my \dfd = DataFrame.new( [['bird', 'polly'], ['monkey', 'george']],
                         columns=> <animal name>,                   );

my $y5 = dfb.concat( dfd, axis => 1);             #column-wise
$y5.show;
#]
