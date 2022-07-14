 *WORK IN PROGRESS*

# raku Dan::Polars

This is a new module to bind raku [Dan](https://github.com/p6steve/raku-Dan) to Polars via Raku NativeCall / Rust FFI.

The following broad capabilities are envisaged:
- Polars structures (Series, DataFrames) as shadows
- Polars expressions (maps Polars::dsl)
- Polars lazy APIs via raku lazy semantics
- handle map & apply (with raku callbacks)
- raku Dan features (accessors, dtypes)
- broad datatype support & mapping
- concurrency

The ultimate aim is to emulate the examples in the [Polars User Guide](https://pola-rs.github.io/polars-book/user-guide/dsl/expressions.html)

## All is strictly pre-release and only if you know what you are doing!!!
 
## Installation
 
Use [p6steve/raku-Dockerfiles/raku-dan-polars/stage-2](https://github.com/p6steve/raku-Dockerfiles/blob/main/raku-dan-polars/stage-2/Dockerfile), Docker Hub images are named something like [p6steve/raku-dan:polars-2022.02-arm64](hub.docker.com) - choose arm64 / amd64 for your machine.
 
deploy Dan::Polars like this ...
```
docker run -it p6steve/raku-dan:polars-2022.02-arm64 #(or -amd64)
zef install Dan;
git clone https://github.com/p6steve/raku-Dan-Polars.git
cd raku-Dan-Polars
cd dan
cargo build
cd ../bin
./synopsis-dan-polars4.raku #(or 1,2,3)
```

## Steve's random notes

Notes from Polars Discord

potter420 — 05/01/2022
https://raku-advent.blog/2019/12/13/day-4-a-little-rr/
Raku Advent Calendar
tmtvl
Day 13 – A Little R&R
A Little R&R Introduction Raku is a really nice language. Versatile, expressive, fast, dwimmy. The only problem I sometimes have with it is that it can be a little slow. Fortunately that can ea…

[20:09]
according to this blog, one can make a FFI binding between Raku and Rust
[20:11]
But, @ritchie46  prolly too busy keeping rust and python lib of polars updated. So additional external effort may be needed

ritchie46 — Yesterday at 14:56
Yeap.. 😅
[14:59]
can an FFI capable languge be bound to polars that way reasonably effectively and is there any example/documentation/cheat sheet/advice I can use to avoid reinventing wheels

Yes, definitely look at the python implementation as the reference implementation. The interop goes very well. There are also bindings to nodejs which also may be helpful. The work of @universalmind303 proves that the port is definitely possible and a lot less work than starting from scratch (Trust me, I've got a lot of time in this ;))

Some other notes:
https://news.ycombinator.com/item?id=27051573#27053712
https://www.youtube.com/watch?v=OtIU7HsHCE8&t=2731s
https://arrow.apache.org


20:37	discord-raku-bot	<Anton Antonov> @japhb I got a CBOR file -- how do I read it in Raku? Using `slurp` with ":bin" ?
20:49	discord-raku-bot	<Anton Antonov> @japhp Yeah, I got it working. And, yes, the CBOR utilization gives me the fastest ingestion of ≈700MB CSV file in Raku.

------

## TODOs

1. [ ] Dan API
   - [x] Dan::Series base methods
   - [x] Dan::DataFrame base methods
   - [ ] Dan Accessors
   - [ ] Dan Slice / Concat
   
2. [x] Polars Structs / Modules
   - [x] Polars::Series base methods
   - [x] Polars::DataFrame base methods
   - [x] .push/.pull (set-new/get-data)
   
3. [ ] Polars Exprs (synopsis..2.raku)
   - [x] unary exprs
 
 
## Design Principles
--
1. lazy

Polars implements both lazy and eager APIs, these are functionally similar. Dan::Polars offers only the most efficient lazy API for simplicity since it has better query optimisation with a very low additional overhead.

2. auto

In Rust & Python Polars, lazy must be explicitly requested with .lazy .. .collect methods around expressions. In contrast, Dan::Polars auto-generates the .lazy .. .collect as the default for concise syntax.

3. pure

[Polars Expressions](https://pola-rs.github.io/polars-book/user-guide/dsl/intro.html) are a function mapping from a series to a series (or mathematically ```Fn(Series) -> Series```). As expressions have a Series as an input and a Series as an output then it is straightforward to do a pipeline of expressions.

4. opaque
 
In general each raku object such as Dan::Polars::Series or Dan::Polars::DataFrame maintains a unique pointer to a rust container SeriesC, DataFrameC and the containers map to a shadow Rust Polars Struct. Methods invoked on the raku object are then proxied over to the Rust Polars shadow. 
 
5. dynamic lib.so
 
A connection is made via Raku Nativecall to Rust FFI using a ```lib.so`` dynmaic library or equivalent.
 
5. data flow

Usually no data needs to be transferred from Raku to Rust (or vice versa). For example, a raku script can command a Rust Polars DataFrame to be read from a csv file, apply expressions and output the result. The data items all remain on the Rust side of the connection.
 
Some use cases are supported - such as using the Rust fast read_csv to import a DataFrame from disk like this:
 
```
use Dan;
use Dan::Polars;

my \df = DataFrame.new;
df.read_csv("/tmp/docdir/1mSalesRecords.csv");

say ~df.Dan-DataFrame;   #cast Dan::Polars::DataFrame to raku native Dan::DataFrame
 ```

- opaque only
-- no chunk controls
-- no chunk unpack (i32 ...)
-- no datetime (in v1)
--
-- v2
- expr arity > 1
- clone (then retest h2o-par)
- reset @data after load rc (also to Pandas)
- map & apply
- operators
- datetime
- better value return
- serde
- strip / fold Index
Snagging
- splice & concat - s1
- sort & filter - s3
- cross join

