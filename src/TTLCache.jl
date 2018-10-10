module TTLCache

export TTL

using Dates: Period

mutable struct Node{V}
    val::V
    id::Symbol

    Node{V}(val::V) where V = new(val, gensym())
end

"""
    TTL(ttl::Period) -> TTL{Any, Any}
    TTL{K, V}(ttl::Period) -> TTL{K, V}

A [TTL](https://en.wikipedia.org/wiki/Time_to_live) cache.
"""
struct TTL{K, V}
    d::Dict{K, Node{V}}
    ttl::Period

    TTL{K, V}(ttl::Period) where {K, V} = new(Dict{K, Node{V}}(), ttl)
    TTL(ttl::Period) = TTL{Any, Any}(ttl)
end

function delete_later(c::TTL{K, V}, k::K, v::Node{V}) where {K, V}
    id = v.id
    sleep(c.ttl)
    haskey(c, k) && c.d[k].id === id && delete!(c, k)
end

# Note: This does NOT copy existing values!
# It's only really here to allow this behaviour:
#   julia> struct X c::TTL{Int, String} end
#   julia> X(TTL(Second(1)))
Base.convert(::Type{TTL{K, V}}, c::TTL) where {K, V} = TTL{K, V}(c.ttl)

Base.delete!(c::TTL, key) = (delete!(c.d, key); return c)
Base.eltype(c::TTL{K, V}) where {K, V} = Pair{K, V}
Base.empty!(c::TTL{K, V}) where {K, V} = (empty!(c.d); return c)
Base.filter!(f, c::TTL) = (filter!(f, c.d); return c)
Base.get(c::TTL{K, V}, key, default) where {K, V} = haskey(c, k) ? c[k] : default
Base.getindex(c::TTL, k) = c.d[k].val
Base.getkey(c::TTL{K, V}, key, default) where {K, V} = getkey(c.d, k)
Base.haskey(c::TTL, k) = haskey(c.d, k)
Base.isempty(c::TTL) = isempty(c.d)
Base.keys(c::TTL{K, V}) where {K, V} = keys(c.d)
Base.length(c::TTL) = length(c.d)
Base.pop!(c::TTL) = pop!(c.d)
Base.pop!(c::TTL, key) = pop!(c.d, key)
Base.sizehint!(c::TTL{K, V} where {K, V}, newsz) = (sizehint!(c.d, newsz); return c)
Base.values(c::TTL{K, V}) where {K, V} = map(x -> x.val, values(c.d))

function Base.iterate(c::TTL)
    isempty(c) && return nothing
    ks = collect(keys(c.d))
    k, n = iterate(ks)
    return k => c[k], (ks, (k, n))
end

function Base.iterate(c::TTL, (ks, state))
    state === nothing && return nothing
    k, n = state
    next = iterate(ks, n)
    return k => c[k], (ks, next)
end

# TODO: Look for more useful Base functions to extend.

function Base.setindex!(c::TTL{K, V}, v::V, k::K) where {K, V}
    node = Node{V}(v)
    @async delete_later(c, k, node)
    return c.d[k] = node
end

"""
    touch(c::TTL{K, V}, k::K) -> Union{V, Nothing}

Reset the expiry time for the value at `c[k]`.
"""
function Base.touch(c::TTL{K, V}, k::K) where {K, V}
    return if haskey(c, k)
        c.d[k].id = gensym()
        @async delete_later(c, k, c.d[k])
        c[k]
    else
        nothing
    end
end

Base.show(c::TTL) = show(stdout, c)
function Base.show(io::IO, c::TTL{K, V}) where {K, V}
    # TODO: How to get the pretty formatted dict output?
    buf = IOBuffer()
    show(buf, Dict{K, V}(k => v.val for (k, v) in c.d))
    s = String(take!(buf))
    print(io, "TTL" * s[5:end])
end

end
