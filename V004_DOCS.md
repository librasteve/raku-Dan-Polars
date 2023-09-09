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
    - [Filtering](#Filtering) (aka grep)
    - [Sorting](#Sorting)
  - Missing Data
  - Apply (user-defined functions)
- Transfomations
  - Joins
  - Concatenation (Stacking)

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

#### Filtering

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

#### Sorting

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


Copyright(c) 2022-2023 Henley Cloud Consulting Ltd.
