# Some notes on design of filters / sort / regex

```
do basic (non regex) sort & filter
either sort on a col (up/down), or Dan sort
filter/grep needs a think
out = df.select(
    [
        pl.col("names").filter(pl.col("names").str.contains(r"am$")).count(),
    ]
)
print(df)
```

#notes
- FIXME refactor for (Num), (Str) == None... (1,2,3,(Int)).are (Int) dd (1e0, NaN, (Num)).are (Num)
- FIXME accept List for <a b c>
https://pola-rs.github.io/polars-book/user-guide/dsl/expressions.html#filter-and-conditionals
- imo embedded regex/str ops are unfriendly --- aim for this in raku map/apply -- build on Dan sort/grep
https://pola-rs.github.io/polars-book/user-guide/dsl/expressions.html#binary-functions-and-modification
- imo embedded ternaries are quite unfriendly --- I would rather aim for this in raku map / apply
