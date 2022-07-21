Here is the set of Polars Exprs yet to be implement in Dan::Polars:

## todos from https://github.com/p6steve/polars/blob/master/nodejs-polars/src/lazy/dsl.rs
#skip: all __add__ operators
#skip: to_string (what for)
#skip: binary - cmps
#skip: is_not, is_not, is_null, is_not_null - think
#skip: is_infinite, is_finite, is_nan, is_not_nan -think
#skip: n-unique, arg_unique, unique_stable - think
#skip: list (need to add Array dtype)
#skip: quantile                     - arity
#skip: agg_groups                   - internal detail
#skip: value_counts, unique_counts  - internal detail
#skip: cast                         - arity
#skip: sort_with, sort_by           - arity / think
#skip: arg_sort                     - internal detail
#skip: arg_max, arg_min             - think
#skip: take                         - arity
#skip: shift, shift_and_fill        - arity
#skip: fill_null, fill_..., fill_nan - think
#skip: drop_nulls, drop_nans        - think
#skip: filter                       - arity
#skip: is_first, is_unique          - think
#skip: explode                      - array
#skip: tail, head                   - arity
#skip: slice                        - think
#skip: round                        - arity
#skip: floor, ceil                  - ^^^^ method not found in `Expr`
#skip: clip                         - arity
#skip: abs                          - ^^^^ method not found in `Expr`
#skip: over                         - arity
#skip: is_dupe,_and,not,_xor,_or    - think
#skip: is_in                        - arity
#skip: repeat_by                    - arity
#skip: pow                          - arity
#skip: cumsum,cummax,cummin,cumprod - arity / daftness
#skip: product                      - this is daft!
#skip: str_parse_date, str_parse_datetime - think
#skip: str_strip,str_rstrip,str_lstrip - think
#skip: str_to_uppercase, str_to_lowercase - think
#skip: str_slice,str_lengths        - think
#skip: str_contains, str_extract    - think
#skip: str_replace, str_replace_all - think
#skip: str_hex_decode,str_hex_encode - think
#skip: str_base64_encode, str_base64_decode - think
#skip: str_json_path_match          - think
#skip: str_split, str_split_inclusive, str_split_exact, str_split_exact_inclusive - think
#skip: strftime, year, month, week, weekday, day, ordinal_day
#      hour, minute, second, nanosecond - think
#skip: duration_days, hours, seconds, nanoseconds, millisecondsi - think
#skip: timestamp, dt_epoch_seconds  - think
#skip: reinterpret (Int64/UInt64)   - think
#skip: dot, mode, keep_name         - huh?
#skip: prefix, suffix               - just use alias
#skip: exclude_dtype                - think
#skip: interpolate                  - think
#skip: rolling_sum,min,max,mean,std,var,median,quantile,skew - think
#skip: lower_bound,upper_bound      - internal detail 
#skip: lst_max,min,sum,mean,sort,reverse,unique,lengths,get,join,arg_min,arg_max,diff,shift
#      slice, eval
#skip: rank, diff, pct_change, skew, kurtosis - arity
#skip: str_concat                   - think
#skip: cat_set_ordering             - think
#skip: reshape, shuffle             - think
#skip: cumcount                     - think
#skip: to_physical                  - internal detail
#skip: sample_frac                  - arity
#skip: ewm_mean,std,var,            - arity
#skip: extend                       - arity
#skip: all (just use col("*")       - drop
#skip: any                          - huh?
#skip: struct_field_by_name,struct_rename_fields - huh?
#skip: log                          - arity
#skip: entropy                      - huh?
#skip: add,sub,mul,div,true_div,rem - arity
#skip: whenthenthen stuff           - think
#skip: dtype_cols                   - internal detail
#skip: arange, range                - think
#skip: pearson, spearman_rank_corr  - arity
#skip: cov                          - arity
#skip: lit                          - operators
#skip: argsort_by                   - huh?
#skip: concat_lst, concat_str       - huh?
#skip: min_exprs, max_exprs         - huh?
#skip: as_struct                    - huh?


## philisophy
# match raku methods https://docs.raku.org/type/Array
# no numpy ufuncs
# desire to offer myfunc == rust dsl => rust so lib long term
