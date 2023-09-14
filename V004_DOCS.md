# v0.0.4 Documentation

As at v0.0.4, the Dan::Polars synopsis has been extended in multiple ways. This page is a vestigal version of the Dan::Polars documentation. For now it includes only features that are not covered in the [Dan synopsis](https://github.com/librasteve/raku-Dan) or the [Dan::Polars synopsis](https://github.com/librasteve/raku-Dan-Polars).

Over time, the synopsis items will be added here in more detail.

This Documentation should be read in conjunction with the [Polars Book](https://pola-rs.github.io/polars-book/user-guide/). The content is largely example based and can be read alongside the Python and Rust examples given there.

## TOC

The TOC is a subset of the Polars Book TOC.

- Installation
- Concepts
- [Expressions](#Expressions)
  - [Casting](#Casting)
    - [Numerics](#Numerics)
    - [Strings](#Strings)
    - [Booleans](#Booleans)
  - [Aggregation](#Aggregation)
    - [Conditionals](#Conditionals)
    - [Filter](#Filter) (aka grep)
    - [Sort](#Sort)
  - Missing Data
  - Apply (user-defined functions)
- [Transformations](#Transformations)
  - [Join](#Join)
  - [Concat](#Concat)

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

#### Join

#### Concat

```perl6
  method concat( DataFrame:D $dfr, :ax(:$axis) is copy,
                            :jn(:$join) = 'outer', :ii(:$ignore-index) ) {

        $axis = clean-axis(:$axis);

        if ! $axis {                        # row-wise with Polars join

            if $join eq 'right' {           # Polars has no JoinType Right
                $dfr.join( self, jointype => 'left' )
            } else {
                self.join( $dfr, jointype => $join )
            }

        } else {                            # col-wise with Polars hstack

            if $dfr.elems !== self.elems {
                warn 'Polars column-wise join only implemented for DataFrames with same number of elems!'
            } else {
                my @series = $dfr.cx.map({$dfr.column($_)});
                self.hstack: @series
            }

        }

        self
    }
```

Here's what is going on:
- Rust-Polars has hstack & vstack methods, these are often wrapped in Rust-Polars ```.concat``` as described [here](https://pola-rs.github.io/polars-book/user-guide/transformations/concatenation/).
- Python-Pandas has 

After some experimentation, the 
aka hstack/vstack


Copyright(c) 2022-2023 Henley Cloud Consulting Ltd.
