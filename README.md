# TimeToLive

[![Build Status](https://travis-ci.com/christopher-dG/TimeToLive.jl.svg?branch=master)](https://travis-ci.com/christopher-dG/TimeToLive.jl)

A [TTL](https://en.wikipedia.org/wiki/Time_to_live) cache.

```julia
julia> using Dates, TimeToLive

julia> cache = TTL{Int, String}(Second(1))
TTL{Int64,String}()

julia> cache[0] = "foo"
"foo"

julia> cache[0]
"foo"

julia> sleep(2)

julia> cache[0]
ERROR: KeyError: key 0 not found
Stacktrace:
 [1] getindex at ./dict.jl:478 [inlined]
 [2] getindex(::TTL{Int64,String}, ::Int64) at /home/degraafc/.julia/dev/TimeToLive/src/TimeToLive.jl:39
 [3] top-level scope at none:0
```
