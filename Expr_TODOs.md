Here is the set of Polars Exprs to be considered for Dan::Polars:

todos from https://github.com/p6steve/polars/blob/master/nodejs-polars/src/lazy/dsl.rs

consider groupng by: [str list analysis null_nan apply_alt extrapolate]

done:
- [x] head
- [x] min,sum,mean,sort,reverse,unique,std,var
- [x] add,sub,mul,div,true_div,rem
- [x] first, last, backward_fill, forward_fill
- [x] lit
- [x] binary - cmps #(gt >, lt <, ge >=, le <=, eq ==, ne !=, and &&, or ||)
- [x] _and,_or
- [x] as_struct
- [x] filter
- [x] all (just use col("*")
- [x] drop
      
next up:
- [ ] is, is_not, is_null, is_not_null, is_infinite, is_finite, is_nan, is_not_nan -think
- [ ] cast                         - arity

later:
- [ ] quantile                     - arity
- [ ] clip                         - arity
- [ ] rank, diff, pct_change, skew, kurtosis - arity
- [ ] pearson, spearman_rank_corr  - arity
- [ ] entropy                      - think

think:
- [ ] n-unique, arg_unique, unique_stable - think
- [ ] sort_with, sort_by           - arity / think
- [ ] arg_max, arg_min             - think
- [ ] fill_null, fill_..., fill_nan - think
- [ ] drop_nulls, drop_nans        - think
- [ ] is_first, is_unique          - think
- [ ] slice                        - think
- [ ] is_dupe,not,_xor             - think
- [ ] str_parse_date, str_parse_datetime - think
- [ ] str_strip,str_rstrip,str_lstrip - think
- [ ] str_to_uppercase, str_to_lowercase - think
- [ ] str_slice,str_lengths        - think
- [ ] str_contains, str_extract    - think
- [ ] str_replace, str_replace_all - think
- [ ] str_hex_decode,str_hex_encode - think
- [ ] str_base64_encode, str_base64_decode - think
- [ ] str_json_path_match          - think
- [ ] str_split, str_split_inclusive, str_split_exact, str_split_exact_inclusive - think
- [ ] strftime, year, month, week, weekday, day, ordinal_day, hour, minute, second, nanosecond - think
- [ ] duration_days, hours, seconds, nanoseconds, millisecondsi - think
- [ ] timestamp, dt_epoch_seconds  - think
- [ ] reinterpret (Int64/UInt64)   - think
- [ ] exclude_dtype                - think
- [ ] interpolate                  - think
- [ ] rolling_sum,min,max,mean,std,var,median,quantile,skew - think
- [ ] arange, range                - think
- [ ] whenthenthen (ternary)       - think
- [ ] str_concat                   - think
- [ ] cat_set_ordering             - think
- [ ] reshape, shuffle             - think
- [ ] cumcount                     - think
- [ ] sample_frac                  - arity
- [ ] ewm_mean                     - arity
- [ ] extend                       - arity

maybe:
- [ ] to_string (what for)
- [ ] list (need to add Array dtype)
- [ ] take                         - arity
- [ ] shift, shift_and_fill        - arity
- [ ] explode                      - array
- [ ] tail                         - arity
- [ ] round                        - arity
- [ ] over                         - arity
- [ ] is_in                        - arity
- [ ] repeat_by                    - arity
- [ ] pow                          - arity
- [ ] cov                          - arity
- [ ] log                          - arity

nope:
- [ ] agg_groups                   - internal detail
- [ ] value_counts, unique_counts  - internal detail
- [ ] arg_sort                     - internal detail
- [ ] floor, ceil                  - ^^^^ method not found in `Expr`
- [ ] abs                          - ^^^^ method not found in `Expr`
- [ ] cumsum,cummax,cummin,cumprod - arity / daftness
- [ ] product                      - this is daft!
- [ ] dot, mode, keep_name         - huh?
- [ ] prefix, suffix               - just use alias
- [ ] lower_bound,upper_bound      - internal detail 
- [ ] lst_max,lengths,get,join,arg_min,arg_max,diff,shift,slice,eval
- [ ] to_physical                  - internal detail
- [ ] any                          - huh?
- [ ] struct_field_by_name,struct_rename_fields - huh?
- [ ] dtype_cols                   - internal detail
- [ ] argsort_by                   - huh?
- [ ] concat_lst, concat_str       - huh?
- [ ] min_exprs, max_exprs         - huh?


### philisophy
- align to raku methods https://docs.raku.org/type/Array
- no numpy ufuncs
- desire to offer myfunc == rust dsl => rust so lib long term
- apply only, no map
  - map is not needed since you can do apply in a select context to get same result
  - viz. https://pola-rs.github.io/polars-book/user-guide/expressions/user-defined-functions/#to-map-or-to-apply
  - raku is anyway not as fast as rust+polars ... use that if you need map levels of performance
- filter is native rust polars, grep is via raku flood / flush
- sort on expr is native polars, sort on df (with Block) is via raku flood/flush
