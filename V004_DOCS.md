# v0.0.4 Documentation

As at v0.0.4, the Dan::Polars synopsis has been extended in multiple ways. This page is a vestigal version of the Dan::Polars documentation. For now it includes only features that are not covered in the [Dan synopsis](https://github.com/librasteve/raku-Dan) or the [Dan::Polars synopsis](https://github.com/librasteve/raku-Dan-Polars).

Over time, the synopsis items will be added here in more detail.

This Documentation should be read in conjunction with the [Polars Book](https://pola-rs.github.io/polars-book/user-guide/). The content is largely example based and can be read alongside the Python and Rust examples given there.

## TOC

The TOC is a subset of the Polars Book TOC.

- Installation
- [Concepts](#Concepts)
  - [Contexts](#Contexts)
- [Expressions](#Expressions)
  - [Casting](#Casting)
    - [Numerics](#Numerics)
    - [Strings](#Strings)
    - [Booleans](#Booleans)
  - [Aggregation](#Aggregation)
    - [Conditionals](#Conditionals)
    - [Filter](#Filter) (aka grep)
    - [Sort](#Sort)
  - [Missing Data](#Missing Data)
  - Apply (user-defined functions)
- [Transformations](#Transformations)
  - [Join](#Join)
  - [Concat](#Concat)

## Concepts

### Contexts

#### Select

```perl6
my \df1 = DataFrame.new(['Ray Type' => ["α", "β", "X", "γ"]]);
df1.show;

shape: (4, 1)
┌──────────┐
│ Ray Type │
│ ---      │
│ str      │
╞══════════╡
│ α        │
├╌╌╌╌╌╌╌╌╌╌┤
│ β        │
├╌╌╌╌╌╌╌╌╌╌┤
│ X        │
├╌╌╌╌╌╌╌╌╌╌┤
│ γ        │
└──────────┘
```

```perl6
my \df2 = df1.drop(['Ray Type']);
df2.show;

shape: (0, 0)
┌┐
╞╡
└┘

say df2.is_empty; #True
```

## Expressions

### Casting

#### Numerics

```perl6
my \df = DataFrame.new([
    integers            => [1, 2, 3, 4, 5],
    big_integers        => [1, 10000002, 3, 10000004, 4294967297],
    floats              => [4.0, 5.0, 6.0, 7.0, 8.0],
    floats_with_decimal => [4.532, 5.5, 6.5, 7.5, 8.5],
]);
df.show;

df.select([
    col("integers").cast("f32").alias("integers_as_floats"),
    col("floats").cast("i32").alias("floats_as_integers"),
    col("floats_with_decimal").cast("i32").alias("floats_with_decimal_as_integers"),
]).show;
```

#### Strings

```perl6
my \dfs = DataFrame.new([
    integers         => [1, 2, 3, 4, 5],
    floats           => [4.0, 5.03, 6.0, 7.0, 8.0],
    strings          => <4.0 5.0 6.0 7.0 8.0>>>.Str.Array,
]);
dfs.show;

dfs.select([
    col("integers").cast("str"),
    col("floats").cast("str"),
    col("strings").cast("f32"),
]).show;
```

#### Booleans

```perl6
my \dfs = DataFrame.new([
    integers => [-1, 0, 2, 3, 4],
    floats => [0.0, 1.0, 2.0, 3.0, 4.0],
    bools => [True, False, True, False, True],
]);
dfs.show;

dfs.select([
    col("integers").cast("bool"),
    col("floats").cast("bool"),
    col("bools").cast("i32"),
]).show;
```

### Aggregation

#### Conditionals

```perl6
my \df = DataFrame.new([
    nrs    => [1, 2, 3, 4, 5], 
    nrs2   => [2, 3, 4, 5, 6], 
    names  => ["foo", "ham", "spam", "egg", ""],
    random => [1.rand xx 5], 
    groups => ["A", "A", "B", "C", "B"],
]);
df.show;

#viz. https://pola-rs.github.io/polars-book/user-guide/expressions/operators/#logical
#(gt >, lt <, ge >=, le <=, eq ==, ne !=, and &&, or ||)
df.select([(col("nrs") > 2).alias("jones")]).head;
#df.select([(col("nrs") >= 2).alias("jones")]).head;
#df.select([(col("nrs") < 2).alias("jones")]).head;
#df.select([(col("nrs") <= 2).alias("jones")]).head;
#df.select([(col("nrs") == 2).alias("jones")]).head;
#df.select([(col("nrs") != 2).alias("jones")]).head;
#df.select([((col("nrs") >= 2) && (col("nrs2") == 5)) .alias("jones")]).head;
#df.select([((col("nrs") >= 2) || (col("nrs2") == 5)) .alias("jones")]).head;
```

#### Filter

The filter method applies to the entire DataFrame.

```perl6
df.filter([(col("nrs") != 4)]).show;
```

```
shape: (4, 5)
┌─────┬──────┬───────┬──────────┬────────┐
│ nrs ┆ nrs2 ┆ names ┆ random   ┆ groups │
│ --- ┆ ---  ┆ ---   ┆ ---      ┆ ---    │
│ i32 ┆ i32  ┆ str   ┆ f64      ┆ str    │
╞═════╪══════╪═══════╪══════════╪════════╡
│ 1   ┆ 2    ┆ foo   ┆ 0.568035 ┆ A      │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 2   ┆ 3    ┆ ham   ┆ 0.4602   ┆ A      │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 3   ┆ 4    ┆ spam  ┆ 0.647715 ┆ B      │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 5   ┆ 6    ┆       ┆ 0.991221 ┆ B      │
└─────┴──────┴───────┴──────────┴────────┘
```

Unlike ```.filter```, DataFrame ```.grep``` is implemented by converting a rust ```Dan::Polars::DataFrame``` to a raku ```Dan::DataFrame``` (a ```.flood```), performing the grep with a raku block-style syntax and then convering back (a ```.flush```). The implication is that the syntax is very rich, but the performance is lower than Expression Sorting.

```perl6
# Grep (binary filter)
say ~df.grep( { .[1] < 0.5 } );                                # by 2nd column 
say ~df.grep( { df.ix[$++] eq <2022-01-02 2022-01-06>.any } ); # by index (multiple) 

```

#### Sort

##### DataFrame Sort

Specify an Array[Str] of column names and an Array[Bool] of descending? options:

```perl6
df.sort(["groups","names"],[False, True]).show;
```

```
shape: (5, 5)
┌─────┬──────┬───────┬──────────┬────────┐
│ nrs ┆ nrs2 ┆ names ┆ random   ┆ groups │
│ --- ┆ ---  ┆ ---   ┆ ---      ┆ ---    │
│ i32 ┆ i32  ┆ str   ┆ f64      ┆ str    │
╞═════╪══════╪═══════╪══════════╪════════╡
│ 2   ┆ 3    ┆ ham   ┆ 0.651383 ┆ A      │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 1   ┆ 2    ┆ foo   ┆ 0.687945 ┆ A      │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 3   ┆ 4    ┆ spam  ┆ 0.020684 ┆ B      │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 5   ┆ 6    ┆       ┆ 0.961176 ┆ B      │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 4   ┆ 5    ┆ egg   ┆ 0.666724 ┆ C      │
└─────┴──────┴───────┴──────────┴────────┘
```

Or, if you prefer a more raku-oriented style, specify a Block:

```perl6
df.sort( {df[$++]<random>} )[*].reverse^.show;
```

```
shape: (5, 5)
┌─────┬──────┬───────┬──────────┬────────┐
│ nrs ┆ nrs2 ┆ names ┆ random   ┆ groups │
│ --- ┆ ---  ┆ ---   ┆ ---      ┆ ---    │
│ i32 ┆ i32  ┆ str   ┆ f64      ┆ str    │
╞═════╪══════╪═══════╪══════════╪════════╡
│ 5   ┆ 6    ┆       ┆ 0.961176 ┆ B      │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 1   ┆ 2    ┆ foo   ┆ 0.687945 ┆ A      │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 4   ┆ 5    ┆ egg   ┆ 0.666724 ┆ C      │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 2   ┆ 3    ┆ ham   ┆ 0.651383 ┆ A      │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 3   ┆ 4    ┆ spam  ┆ 0.020684 ┆ B      │
└─────┴──────┴───────┴──────────┴────────┘
```

As set out in the [Dan synopsis](https://github.com/librasteve/raku-Dan), DataFrame level sort is done like this:

```perl6
# Sort
say ~df.sort: { .[1] };         # sort by 2nd col (ascending)
say ~df.sort: { -.[1] };        # sort by 2nd col (descending)
say ~df.sort: { df[$++]<C> };   # sort by col C
say ~df.sort: { df.ix[$++] };   # sort by index
```

Here is another example from the [Dan::Polars Nutshell](https://github.com/librasteve/raku-Dan-Polars):

```perl6
$obj .= sort( {$obj[$++]<species>, $obj[$++]<mass>} )[*].reverse^;
```

Unlike colspec sort, Block sort is implemented by converting a rust ```Dan::Polars::DataFrame``` to a raku ```Dan::DataFrame``` (ie. ```.flood```), performing the sort with a raku block-style syntax and then convering back (ie. ```.flush```). The implication is that the syntax is very rich, but the performance is lower.

##### Expression Sort

The sort method on col Expressions in a select is independently applied to each col.

```perl6
df.select([(col("names").alias("jones").sort),col("groups").alias("smith").sort,col("nrs").reverse]).head;
```

```
shape: (5, 3)
┌───────┬───────┬─────┐
│ jones ┆ smith ┆ nrs │
│ ---   ┆ ---   ┆ --- │
│ str   ┆ str   ┆ i32 │
╞═══════╪═══════╪═════╡
│       ┆ A     ┆ 5   │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌┤
│ egg   ┆ A     ┆ 4   │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌┤
│ foo   ┆ B     ┆ 3   │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌┤
│ ham   ┆ B     ┆ 2   │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌┤
│ spam  ┆ C     ┆ 1   │
└───────┴───────┴─────┘
```

The sort method on col Expressions in a groupby is applied to the list result.

```perl6
df.groupby(["groups"]).agg([col("nrs").sort]).head;
#df.groupby(["groups"]).agg([col("nrs").reverse]).head;
```

```
shape: (3, 2)
┌────────┬───────────┐
│ groups ┆ nrs       │
│ ---    ┆ ---       │
│ str    ┆ list[i32] │
╞════════╪═══════════╡
│ C      ┆ [4]       │
├╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌┤
│ A      ┆ [1, 2]    │
├╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌┤
│ B      ┆ [3, 5]    │
└────────┴───────────┘
```
### Missing Data

In Dan::Polars, missing data is represented by the raku Type Object (Int, Bool, Str and so on) or by the raku Numeric special values (NaN, +/-Inf).

```perl6
my \df = DataFrame.new([
    nrs    => [1, 2, 3, 4, 5], 
    nrs2   => [Num, NaN, 4, Inf, 8.3],
    names  => ["foo", Str, "spam", "egg", ""],
    random => [1.rand xx 5], 
    groups => ["A", "A", "B", "C", "B"],
    flags  => [True,True,False,True,Bool],
]);
df.show;

shape: (5, 6)
┌─────┬──────┬───────┬──────────┬────────┬───────┐
│ nrs ┆ nrs2 ┆ names ┆ random   ┆ groups ┆ flags │
│ --- ┆ ---  ┆ ---   ┆ ---      ┆ ---    ┆ ---   │
│ i32 ┆ f64  ┆ str   ┆ f64      ┆ str    ┆ bool  │
╞═════╪══════╪═══════╪══════════╪════════╪═══════╡
│ 1   ┆ null ┆ foo   ┆ 0.074586 ┆ A      ┆ true  │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┤
│ 2   ┆ NaN  ┆ null  ┆ 0.867919 ┆ A      ┆ true  │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┤
│ 3   ┆ 4.0  ┆ spam  ┆ 0.069183 ┆ B      ┆ false │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┤
│ 4   ┆ inf  ┆ egg   ┆ 0.739191 ┆ C      ┆ true  │
├╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┤
│ 5   ┆ 8.3  ┆       ┆ 0.133729 ┆ B      ┆ null  │
└─────┴──────┴───────┴──────────┴────────┴───────┘
```

And, conversely, when cast back to a (non Polars) Dan DataFrame:

```perl6
say ~df.Dan-DataFrame;

    nrs  nrs2  names  random               groups  flags 
 0  1    Num   foo    0.9188127959571387   A       True  
 1  2    NaN   Str    0.08257029673307026  A       True  
 2  3    4     spam   0.0682447340762582   B       False 
 3  4    Inf   egg    0.3287371781756494   C       True  
 4  5    8.3          0.5133318112263049   B       Bool 
```

You can test for what you have with:

| Sense | Truthiness | Definedness | Numberness   | Finiteness  |
|-------|------------|-------------|--------------|-------------|
|  so   |    n/a     | is_null     | is_not_nan   | is_finite   |
|  not  |   is_not   | is_not_null | is_nan       | is_infinite |  

```perl6
#`[
df.select([(col("nrs") > 2)]).head;
df.select([((col("nrs") > 2).is_not)]).head;
df.select([(col("nrs2").is_null)]).head;
df.select([(col("nrs2").is_not_null)]).head;
df.select([(col("nrs2").is_not_nan)]).head;
df.select([(col("nrs2").is_nan)]).head;
df.select([(col("nrs2").is_finite)]).head;
#]
df.select([(col("nrs2").is_infinite)]).head;

shape: (5, 1)
┌───────┐
│ nrs2  │
│ ---   │
│ bool  │
╞═══════╡
│ null  │
├╌╌╌╌╌╌╌┤
│ false │
├╌╌╌╌╌╌╌┤
│ false │
├╌╌╌╌╌╌╌┤
│ true  │
├╌╌╌╌╌╌╌┤
│ false │
└───────┘
```

### Transformations

In Dan::Polars, the two sections - Join and Concat - are related via these tables:

##### Table 1: Combining functions for DataFrames

| Function | Description               | Dan                                       |
|----------|---------------------------|-------------------------------------------|
| join     | Join on a column          | `df1.join(df2, how=>'inner', on=>'col')`  |
| concat   | Concatenate along an axis | `df1.concat(df2, axis=>0/1)`              |


##### Table 2: Combining functions for Series

| Function | Description                   | Dan                                    |
|----------|-------------------------------|----------------------------------------| 
| concat   | Append one Series to another  | `series1.concat( series2 )`            |

The rationale for this solution is set out in [Issue #10](https://github.com/librasteve/raku-Dan-Polars/issues/10)

#### Join

Here is the signature of the Dan::Polars ```.join``` method:

```perl6
subset JoinType of Str where <left inner outer cross>.any;
method join( DataFrame \right, Str :$on, JoinType :$how = 'outer' ) { ... }
```

- use ```on => 'colname' to pass the column on which to do the join
  - Dan::Polars will guess the on column(s) if nothing is supplied
  - ```on_right``` and ```on_left``` are not provided
  - ignored if a ```cross``` join
- use ```how => 'jointype' to specify how to do the join
  - default is ```outer```
  - undefined cells are created as ```null```
  - ```right``` is not implemented (swap method call if needed)
  - ```asof``` and ```semi``` are not yet implemented

First some examples:

```perl6
my \df_customers = DataFrame([
    customer_id => [1, 2, 3], 
    name => ["Alice", "Bob", "Charlie"],
]);
df_customers.show;

shape: (3, 2)
┌─────────────┬─────────┐
│ customer_id ┆ name    │
│ ---         ┆ ---     │
│ i32         ┆ str     │
╞═════════════╪═════════╡
│ 1           ┆ Alice   │
├╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 2           ┆ Bob     │
├╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 3           ┆ Charlie │
└─────────────┴─────────┘

my \df_orders = DataFrame([
    order_id => ["a", "b", "c"],
    customer_id => [1, 2, 2], 
    amount => [100, 200, 300],
]);
df_orders.show;

shape: (3, 3)
┌──────────┬─────────────┬────────┐
│ order_id ┆ customer_id ┆ amount │
│ ---      ┆ ---         ┆ ---    │
│ str      ┆ i32         ┆ i32    │
╞══════════╪═════════════╪════════╡
│ a        ┆ 1           ┆ 100    │
├╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ b        ┆ 2           ┆ 200    │
├╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ c        ┆ 2           ┆ 300    │
└──────────┴─────────────┴────────┘
```

```perl6
df_customers.join(df_orders, on => "customer_id", how => "inner").show;

shape: (3, 4)
┌─────────────┬───────┬──────────┬────────┐
│ customer_id ┆ name  ┆ order_id ┆ amount │
│ ---         ┆ ---   ┆ ---      ┆ ---    │
│ i32         ┆ str   ┆ str      ┆ i32    │
╞═════════════╪═══════╪══════════╪════════╡
│ 1           ┆ Alice ┆ a        ┆ 100    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 2           ┆ Bob   ┆ b        ┆ 200    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 2           ┆ Bob   ┆ c        ┆ 300    │
└─────────────┴───────┴──────────┴────────┘

df_customers.join(df_orders).show;    #outer join relying on defaults

shape: (4, 4)
┌─────────────┬─────────┬──────────┬────────┐
│ customer_id ┆ name    ┆ order_id ┆ amount │
│ ---         ┆ ---     ┆ ---      ┆ ---    │
│ i32         ┆ str     ┆ str      ┆ i32    │
╞═════════════╪═════════╪══════════╪════════╡
│ 1           ┆ Alice   ┆ a        ┆ 100    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 2           ┆ Bob     ┆ b        ┆ 200    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 2           ┆ Bob     ┆ c        ┆ 300    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ 3           ┆ Charlie ┆ null     ┆ null   │
└─────────────┴─────────┴──────────┴────────┘

df_customers.join(df_orders, on => "customer_id", how => "left").show;
^^ same as above (in this example)
```

For cross join:

```perl6
my \df_colors = DataFrame([ 
    color => ["red", "blue", "green"],
]);
df_colors.show;

shape: (3, 1)
┌───────┐
│ color │
│ ---   │
│ str   │
╞═══════╡
│ red   │
├╌╌╌╌╌╌╌┤
│ blue  │
├╌╌╌╌╌╌╌┤
│ green │
└───────┘

my \df_sizes = DataFrame([
    size => ["S", "M", "L"],
]);
df_sizes.show;

shape: (3, 1)
┌──────┐
│ size │
│ ---  │
│ str  │
╞══════╡
│ S    │
├╌╌╌╌╌╌┤
│ M    │
├╌╌╌╌╌╌┤
│ L    │
└──────┘
```

```perl6
df_colors.join( df_sizes, :how<cross> ).show;

shape: (9, 2)
┌───────┬──────┐
│ color ┆ size │
│ ---   ┆ ---  │
│ str   ┆ str  │
╞═══════╪══════╡
│ red   ┆ S    │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌┤
│ red   ┆ M    │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌┤
│ red   ┆ L    │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌┤
│ blue  ┆ S    │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌┤
│ ...   ┆ ...  │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌┤
│ blue  ┆ L    │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌┤
│ green ┆ S    │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌┤
│ green ┆ M    │
├╌╌╌╌╌╌╌┼╌╌╌╌╌╌┤
│ green ┆ L    │
└───────┴──────┘
```

#### Concat

##### DataFrames

Here is the signature of the Dan::Polars DataFrame ```.concat``` method:

```perl6
method concat( DataFrame:D $dfr, :ax(:$axis) is copy ) { ... }

given $axis {
    when ! .so || /^r/ || /^v/ { 0 }
    when   .so || /^c/ || /^h/ { 1 }
}
```

- ```ax``` is an alias for ```axis```
- default (False) is vertical
- as values you can use
  - False | True
  - 0 | 1
  - anything with initial char [r]ow or [c]olumn
  - anything with initial char [v]ertical or [h]orizontal

First, some example data:

```perl6
my \dfa = DataFrame.new(
        [['a', 1], ['b', 2]],
        columns => <letter number>,
);

my \dfb = DataFrame.new(
        [['c', 3], ['d', 4]],
        columns => <letter number>,
);

my \dfc = DataFrame.new(
        [['cat', 4], ['dog', 4]],
        columns => <animal legs>,
);
```

```perl6
dfa.concat(dfb).show;               # vertical is default

shape: (4, 2)
┌────────┬────────┐
│ letter ┆ number │
│ ---    ┆ ---    │
│ str    ┆ i32    │
╞════════╪════════╡
│ a      ┆ 1      │
├╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ b      ┆ 2      │
├╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ c      ┆ 3      │
├╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ d      ┆ 4      │
└────────┴────────┘
```

```perl6
dfa.concat(dfc, :axis).show;     # horizontal or column-wise

shape: (2, 4)
┌────────┬────────┬────────┬──────┐
│ letter ┆ number ┆ animal ┆ legs │
│ ---    ┆ ---    ┆ ---    ┆ ---  │
│ str    ┆ i32    ┆ str    ┆ i32  │
╞════════╪════════╪════════╪══════╡
│ a      ┆ 1      ┆ cat    ┆ 4    │
├╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┤
│ b      ┆ 2      ┆ dog    ┆ 4    │
└────────┴────────┴────────┴──────┘
```

##### Series

```perl6
my \s = Series.new( [b=>1, a=>0, c=>2] );
my \t = Series.new( [f=>1, e=>0, d=>2] );

my $u = s.concat: t;                # concatenate
$u.show;

shape: (6,)
Series: 'anon' [i32]
[
	1
	0
	2
	1
	0
	2
]
```

Copyright(c) 2022-2023 Henley Cloud Consulting Ltd.
