*WORK IN PROGRESS*

_So far, I have managed to bring about a third of the Polars library into the Raku world with this module. Some track has been laid that may make the rest go faster and easier, but surely there is a lot of refactoring and tidying up to do to._

_You can see the TODO files here for Query and Expression features and I will be working my way down this list steadily._

_If you would like to alter the priority, please create an issue (or find an existing one) and hopefully others will upvoat it._

_Even better would be to work with me to do a PR (I will probbaly need to do a bit of guidance initiallly)._

_librasteve@furnival.net_

*THIS MODULE IS EXPERIMENTAL AND SUBJECT TO CHANGE WITHOUT NOTICE*
 
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)
[![raku-dan:polars -> DH](https://github.com/librasteve/raku-Dan-Polars/actions/workflows/polars-weekly.yaml/badge.svg)](https://github.com/librasteve/raku-Dan-Polars/actions/workflows/polars-weekly.yaml)

# raku Dan::Polars - WIP

This new module binds Raku [Dan](https://github.com/librasteve/raku-Dan) to Polars via Raku NativeCall / Rust FFI.

The following broad capabilities are included:
- Polars structures (Series & DataFrames)
- Polars lazy queries & expressions
- raku Dan features (accessors, dtypes, base methods)
- broad datatype support
- concurrency

The aim is to emulate the examples in the [Polars User Guide](https://pola-rs.github.io/polars-book/user-guide/dsl/expressions.html)
 
### Installation
Based on the Dockerfile chain [(1)](https://github.com/librasteve/raku-Dan-Polars/blob/main/Dockerfile) FROM [(2)](https://github.com/librasteve/raku-Dockerfiles/blob/main/rusty-ma/Dockerfile)
- ```docker run -it librasteve/raku-dan:polars-amd64```
- ```cd ~/raku-Dan-Polars/bin``` (this repo was cloned to load test_data)
- ```./synopsis-dan-polars.raku``` or ```./nutshell.raku```

(see bin/setup.raku for manual / development install steps)

_You are welcome to plunder the Dockerfiles for how to set up your own environment._

------

### Nutshell

```raku
use Dan;
use Dan::Polars;

sub starwars {
    my \sw = DataFrame.new;
    sw.read_csv("test_data/dfStarwars.csv");
    sw  
}

my $obj = starwars;
$obj .= select( [ <species mass height>>>.&col ] ) ;
$obj .= groupby([ <species> ]) ;
$obj .= sort( {$obj[$++]<species>, $obj[$++]<mass>} )[*].reverse^;

$obj.show;

shape: (87, 3)
┌────────────────┬──────┬────────┐
│ species        ┆ mass ┆ height │
│ ---            ┆ ---  ┆ ---    │
│ str            ┆ str  ┆ str    │
╞════════════════╪══════╪════════╡
│ Zabrak         ┆ NA   ┆ 171    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ Zabrak         ┆ 80   ┆ 175    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ Yoda's species ┆ 17   ┆ 66     │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ Xexto          ┆ NA   ┆ 122    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ ...            ┆ ...  ┆ ...    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ Chagrian       ┆ NA   ┆ 196    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ Cerean         ┆ 82   ┆ 198    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ Besalisk       ┆ 102  ┆ 198    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌┤
│ Aleena         ┆ 15   ┆ 79     │
└────────────────┴──────┴────────┘

#say ~$obj.Dan-DataFrame;       # coerce to a vanilla Dan::DataFrame (e.g. to say all rows)
#say ~$obj.to-dataset;          # or export to a dataset for ad hoc data munging
```
_datasets are used by raku [Data::...](https://raku.land/?q=Data%3A%3A) modules_

### Synopsis

Dan::Polars is a specialization of raku Dan. Checkout the [Dan synopsis](https://github.com/librasteve/raku-Dan/blob/main/README.md#synopsis) for base Series and DataFrame operations. The following covers the additional features that are specific to Dan::Polars.

* Each Dan::Polars object (Series or DataFrame) contains a pointer to its Rust Polars "shadow". 
* Polars does not implement indexes, so any attempt to set a row index will be ignored.
* Dan::Polars only exposes the Polars lazy API and quietly calls ```.lazy``` and ```.collect``` as needed.

```raku
use Dan;
use Dan::Polars;

my \df = DataFrame.new;
df.read_csv("../dan/src/iris.csv");

# ---------------------------------------

my $se = df.column("sepal.length");
$se.head;

# a Series...
shape: (5,)
Series: 'sepal.length' [f64]
[
	5.1
	4.9
	4.7
	4.6
	5.0
]

# ---------------------------------------

df.select([col("sepal.length"), col("variety")]).head;

# a DataFrame...
shape: (5, 2)
┌──────────────┬─────────┐
│ sepal.length ┆ variety │
│ ---          ┆ ---     │
│ f64          ┆ str     │
╞══════════════╪═════════╡
│ 5.1          ┆ Setosa  │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 4.9          ┆ Setosa  │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 4.7          ┆ Setosa  │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 4.6          ┆ Setosa  │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌┤
│ 5.0          ┆ Setosa  │
└──────────────┴─────────┘

# ---------------------------------------

df.groupby(["variety"]).agg([col("petal.length").sum]).head;

# -- or --
my $expr;
$expr  = col("petal.length");
$expr .= sum;
df.groupby(["variety"]).agg([$expr]).head;

# An Expression takes the form Fn(Series --> Series) {} ...

# a DataFrame...
shape: (2, 2)
┌────────────┬──────────────┐
│ variety    ┆ petal.length │
│ ---        ┆ ---          │
│ str        ┆ f64          │
╞════════════╪══════════════╡
│ Versicolor ┆ 141.4        │
├╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
│ Setosa     ┆ 73.1         │
└────────────┴──────────────┘

# ---------------------------------------
# Here are some unary expressions; the ```.alias``` method can be used to rename cols...

my @exprs;
@exprs.push: col("petal.length").sum;
#@exprs.push: col("sepal.length").mean;
#@exprs.push: col("sepal.length").min;
#@exprs.push: col("sepal.length").max;
#@exprs.push: col("sepal.length").first;
#@exprs.push: col("sepal.length").last;
#@exprs.push: col("sepal.length").unique;
#@exprs.push: col("sepal.length").count;
#@exprs.push: col("sepal.length").forward_fill;
#@exprs.push: col("sepal.length").backward_fill;
@exprs.push: col("sepal.length").reverse;
@exprs.push: col("sepal.length").std.alias("std");
#@exprs.push: col("sepal.length").var;
df.groupby(["variety"]).agg(@exprs).head;

shape: (2, 4)
┌────────────┬──────────────┬─────────────────────┬──────────┐
│ variety    ┆ petal.length ┆ sepal.length        ┆ std      │
│ ---        ┆ ---          ┆ ---                 ┆ ---      │
│ str        ┆ f64          ┆ list[f64]           ┆ f64      │
╞════════════╪══════════════╪═════════════════════╪══════════╡
│ Versicolor ┆ 141.4        ┆ [5.8, 5.5, ... 7.0] ┆ 0.539255 │
├╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ Setosa     ┆ 73.1         ┆ [5.0, 5.3, ... 5.1] ┆ 0.3524   │
└────────────┴──────────────┴─────────────────────┴──────────┘

# ---------------------------------------
# use col("*") to select all...

df.select([col("*").exclude(["sepal.width"])]).head;
df.select([col("*").sum]).head;

# ---------------------------------------
# Can do Expression math...

df.select([
    col("sepal.length"),
    col("petal.length"),
    (col("petal.length") + (col("sepal.length"))).alias("add"),
    (col("petal.length") - (col("sepal.length"))).alias("sub"),
    (col("petal.length") * (col("sepal.length"))).alias("mul"),
    (col("petal.length") / (col("sepal.length"))).alias("div"),
    (col("petal.length") % (col("sepal.length"))).alias("mod"),
    (col("petal.length") div (col("sepal.length"))).alias("floordiv"),
]).head;

shape: (5, 8)
┌──────────────┬──────────────┬─────┬──────┬──────┬──────────┬─────┬──────────┐
│ sepal.length ┆ petal.length ┆ add ┆ sub  ┆ mul  ┆ div      ┆ mod ┆ floordiv │
│ ---          ┆ ---          ┆ --- ┆ ---  ┆ ---  ┆ ---      ┆ --- ┆ ---      │
│ f64          ┆ f64          ┆ f64 ┆ f64  ┆ f64  ┆ f64      ┆ f64 ┆ f64      │
╞══════════════╪══════════════╪═════╪══════╪══════╪══════════╪═════╪══════════╡
│ 5.1          ┆ 1.4          ┆ 6.5 ┆ -3.7 ┆ 7.14 ┆ 0.2745   ┆ 1.4 ┆ 0.2745   │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.9          ┆ 1.4          ┆ 6.3 ┆ -3.5 ┆ 6.86 ┆ 0.285714 ┆ 1.4 ┆ 0.285714 │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.7          ┆ 1.3          ┆ 6.0 ┆ -3.4 ┆ 6.11 ┆ 0.276596 ┆ 1.3 ┆ 0.276596 │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.6          ┆ 1.5          ┆ 6.1 ┆ -3.1 ┆ 6.9  ┆ 0.326087 ┆ 1.5 ┆ 0.326087 │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 5.0          ┆ 1.4          ┆ 6.4 ┆ -3.6 ┆ 7.0  ┆ 0.28     ┆ 1.4 ┆ 0.28     │
└──────────────┴──────────────┴─────┴──────┴──────┴──────────┴─────┴──────────┘

# ---------------------------------------
# And use literals...

df.select([
    col("sepal.length"),
    col("petal.length"),
    (col("petal.length") + 7).alias("add7"),
    (7 - col("petal.length")).alias("sub7"),
    (col("petal.length") * 2.2).alias("mul"),
    (2.2 / (col("sepal.length"))).alias("div"),
    (col("sepal.length") % 2).alias("mod"),
    (col("sepal.length") div 0.1).alias("floordiv"),
]).head;

shape: (5, 8)
┌──────────────┬──────────────┬──────┬──────┬──────┬──────────┬─────┬──────────┐
│ sepal.length ┆ petal.length ┆ add7 ┆ sub7 ┆ mul  ┆ div      ┆ mod ┆ floordiv │
│ ---          ┆ ---          ┆ ---  ┆ ---  ┆ ---  ┆ ---      ┆ --- ┆ ---      │
│ f64          ┆ f64          ┆ f64  ┆ f64  ┆ f64  ┆ f64      ┆ f64 ┆ f64      │
╞══════════════╪══════════════╪══════╪══════╪══════╪══════════╪═════╪══════════╡
│ 5.1          ┆ 1.4          ┆ 8.4  ┆ 5.6  ┆ 3.08 ┆ 0.431373 ┆ 1.1 ┆ 51.0     │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.9          ┆ 1.4          ┆ 8.4  ┆ 5.6  ┆ 3.08 ┆ 0.4489   ┆ 0.9 ┆ 49.0     │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.7          ┆ 1.3          ┆ 8.3  ┆ 5.7  ┆ 2.86 ┆ 0.468085 ┆ 0.7 ┆ 47.0     │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 4.6          ┆ 1.5          ┆ 8.5  ┆ 5.5  ┆ 3.3  ┆ 0.478261 ┆ 0.6 ┆ 46.0     │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌┤
│ 5.0          ┆ 1.4          ┆ 8.4  ┆ 5.6  ┆ 3.08 ┆ 0.44     ┆ 1.0 ┆ 50.0     │
└──────────────┴──────────────┴──────┴──────┴──────┴──────────┴─────┴──────────┘

# ---------------------------------------
# There is a variant of with_column (for Series) and with_columns (for Expressions)

df.with_column($se.rename("newcol")).head;
df.with_columns([col("variety").alias("newnew")]).head;
```

Notes:

* Most methods such as queries on the Raku object are applied to the shadow and the data remains on the Rust side for performance reasons. Exceptions are accessors and map operations which require the data to be synched manually to the Raku side using the ```.flood``` method and, when done, to be sent back Rustwards with ```.flush```. Sort & grep methods (in their current incarnations) also implicitly use .flood/.flush to sync.
* On reflection, the vanilla Dan splice & concat methods are not a good fit for Polars which has the simpler Series.append, DataFrame.vstack|.hstack and DataFrame.join methods. The new plan is to implement these Polars methods here (v0.2) and then to replace Dan and Dan::Pandas splice & concat with the Polars  equivalent in the forthcoming As::Query role.
* To avoid synching for ```say ~df``` operations, the ```.show``` method applies Rust println! to STDOUT.
* For import and export, the ```se.Dan-Series``` and ```df.Dan-DataFrame``` methods will coerce to the raku-only Dan equivalent. You can go ```Series.new(Dan::Series:D --> Dan::Polars::Series)``` and ```DataFrame.new(Dan::DataFrame:D --> Dan::Polars::DataFrame)```.
* The method ```df.to-dataset``` is provided to, err, make a dataset for various raku Data:: library compatibility

----
 
### Design Notes

1. lazy

Polars implements both lazy and eager APIs, these are functionally similar. For simplicity, Dan::Polars offers only the most efficient: lazy API. It has better query optimisation with low additional overhead.

2. auto-lazy

In Rust & Python Polars, lazy must be explicitly requested with ```.lazy .. .collect``` methods around expressions. In contrast, Dan::Polars auto-generates the ```.lazy .. .collect``` quietly for concise syntax.

3. pure

[Polars Expressions](https://pola-rs.github.io/polars-book/user-guide/dsl/intro.html) are a function mapping from a series to a series (or mathematically ```Fn(Series) -> Series```). As expressions have a Series as an input and a Series as an output then it is straightforward to do a pipeline of expressions.

4. opaque
 
In general each raku object (Dan::Polars::Series, Dan::Polars::DataFrame) maintains a unique pointer to a rust container (SeriesC, DataFrameC) and they contain a shadow Rust Polars Struct. Methods invoked on the raku object are then proxied over to the Rust Polars shadow. 
 
5. dynamic lib.so
 
A connection is made via Raku Nativecall to Rust FFI using a ```lib.so`` dymanic library or equivalent.
 
5. data transfer

Usually no data needs to be transferred from Raku to Rust (or vice versa). For example, a raku script can command a Rust Polars DataFrame to be read from a csv file, apply expressions and output the result. The data items all remain on the Rust side of the connection.
 
----
## TODOs

### v0.1

1. [x] Dan API
   - [x] Dan::Series base methods
   - [x] Dan::DataFrame base methods
   - [x] Dan Accessors
   - [x] Dan sort & grep (s3)
   
2. [x] Polars Structs / Modules
   - [x] Polars::Series base methods
   - [x] Polars::DataFrame base methods
   - [x] .push/.pull (set-new/get-data)
   - [x] better value return
   
3. [x] Polars Exprs (s2)
   - [x] unary exprs
   - [x] operators
   
4. [x] Documentation
   - [x] synopsis
   - [x] refactor /bin

5. [x] Test
 
This will then provide a basis for ...

### v0.2
- [x] drop col
- [x] apply (jit DSL style)
- [ ] [Dan concat (s1) via Rust join](https://github.com/p6steve/raku-Dan-Polars/issues/10)
- [ ] Dan splice to with_col, col, drop, hstack, vstack, append (need Issue discussion)
- [ ] non-null, etc.
- [ ] cast
- [ ] str basics (eg .len())

This will then provide a basis for design Dan::As::Query v0.1 for Dan and Dan::Pandas and review Dan API slice & concat, immutability, refactor...

### v0.3...
- [ ] datetime
- [ ] [asof join](https://pola-rs.github.io/polars/polars_core/prelude/struct.AsOfOptions.html)
- [ ] unique_stable
- [ ] expr arity > 1
- [ ] 'over' expr
- [ ] 'fold' expr
- [ ] clone (then retest h2o-par)
- [ ] immutability
- [ ] reset @data after load rc (also to Pandas)
 
### v0.4...
- [ ] strip / fold Index
- [ ] cross join (aka cross product)
- [ ] pivot / cross-tabluate
- [ ] apply over [multiple cols](https://stackoverflow.com/questions/72372821/how-to-apply-a-function-to-multiple-columns-of-a-polars-dataframe-in-rust)
- [ ] ternary if-then-else (Dan::As::Ternary)
- [ ] str operations (Dan::As::Str)
- [ ] chunked transfer
- [ ] serde

(c) Henley Cloud Consulting Ltd.
