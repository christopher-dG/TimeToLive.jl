module TimeToLive

export TTL

using Dates: Period

struct Node{T}
    v::T
    id::Symbol

    Node{T}(v::T) where T = new(v, gensym())
end

"""
    TTL(ttl::Period; refresh_on_access::Bool=true) -> TTL{Any, Any}
    TTL{K, V}(ttl::Period; refresh_on_access::Bool=true) -> TTL{K, V}

A [TTL](https://en.wikipedia.org/wiki/Time_to_live) cache.
If `refresh_on_access` is set, then values' expiries are reset whenever they are accessed.
"""
struct TTL{K, V}
    d::Dict{K, Node{V}}
    ttl::Period
    refresh::Bool

    function TTL{K, V}(ttl::Period; refresh_on_access::Bool=true) where {K, V}
        return new(Dict{K, Node{V}}(), ttl, refresh_on_access)
    end
    function TTL(ttl::Period; refresh_on_access::Bool=true)
        return TTL{Any, Any}(ttl; refresh_on_access=refresh_on_access)
    end
end

function delete_later(t::TTL, k, v::Node)
    id = v.id
    sleep(t.ttl)
    haskey(t, k) && t.d[k].id === id && delete!(t, k)
end

# Note: This does NOT copy existing values!
# It's only really here to allow this behaviour:
#   julia> struct X t::TTL{Int, String} end
#   julia> X(TTL(Second(1)))
Base.convert(::Type{TTL{K, V}}, t::TTL) where {K, V} = TTL{K, V}(t.ttl)

Base.delete!(t::TTL, key) = (delete!(t.d, key); return t)
Base.eltype(::TTL{K, V}) where {K, V} = Pair{K, V}
Base.empty!(t::TTL{K, V}) where {K, V} = (empty!(t.d); return t)
Base.filter!(f, t::TTL) = (filter!(f, t.d); return t)
Base.get(t::TTL{K, V}, key, default) where {K, V} = haskey(t, key) ? t[key] : default
Base.getindex(t::TTL, k) = (t.refresh && touch(t, k); return t.d[k].v)
Base.getkey(t::TTL{K, V}, key, default) where {K, V} = getkey(t.d, k)
Base.haskey(t::TTL, k) = haskey(t.d, k)
Base.isempty(t::TTL) = isempty(t.d)
Base.keys(t::TTL{K, V}) where {K, V} = keys(t.d)
Base.length(t::TTL) = length(t.d)
Base.pop!(t::TTL) = pop!(t.d)
Base.pop!(t::TTL, key) = pop!(t.d, key)
Base.sizehint!(t::TTL{K, V} where {K, V}, newsz) = (sizehint!(t.d, newsz); return t)
Base.values(t::TTL{K, V}) where {K, V} = map(x -> x.v, values(t.d))

function Base.iterate(t::TTL, ks::AbstractVector=collect(keys(t.d)))
    isempty(ks) && return nothing
    k = ks[1]
    return k => t.d[k].v, ks[2:end]
end

# TODO: Look for more useful Base functions to extend.

function Base.setindex!(t::TTL{K, V}, v, k) where {K, V}
    node = Node{V}(v)
    @async delete_later(t, k, node)
    return t.d[k] = node
end

"""
    touch(t::TTL, k)

Reset the expiry time for the value at `t[k]`.
"""
function Base.touch(t::TTL{K, V}, k) where {K, V}
    if haskey(t, k)
        t.d[k] = Node{V}(t.d[k].v)  # Change the ID.
        @async delete_later(t, k, t.d[k])
    end
    return nothing
end

Base.show(t::TTL) = show(stdout, t)
function Base.show(io::IO, t::TTL{K, V}) where {K, V}
    # TODO: How to get the pretty formatted dict output? repr?
    buf = IOBuffer()
    show(buf, Dict{K, V}(k => v.v for (k, v) in t.d))
    s = String(take!(buf))
    print(io, "TTL($(t.ttl))" * s[5:end])
end

end
