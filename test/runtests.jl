using Dates: Millisecond
using TimeToLive: TTL, Node
using Test

const p = Millisecond(250)

@testset "TimeToLive.jl" begin
    # Constructors.
    t = TTL(p)
    @test t.ttl == p
    @test t.d isa Dict{Any, Node{Any}}
    t = TTL{Int, String}(p)
    @test t.d isa Dict{Int, Node{String}}

    # Basic expiry.
    t[0] = "!"
    @test get(t, 0, nothing) == "!"
    sleep(2p)
    @test isempty(t)

    # Refreshing expiry.
    t[0] = "!"
    sleep(p/2)
    touch(t, 0)
    sleep(p)
    @test get(t, 0, nothing) == "!"
    sleep(2p)
    @test isempty(t)

    # Iteration.
    t = TTL(p)
    t[1] = t[2] = t[3] = t[4] = t[5] = "!"
    count = 0
    for pair in t
        @test pair isa Pair{Int, String}
        count += 1
    end
    @test count == 5

    # Conversion.
    t = convert(TTL{String, Int}, TTL(p))
    @test t.d isa Dict{String, Node{Int}}

    # Refresh on access.
    t = TTL(p; refresh_on_access=true)
    t[0] = "!"
    sleep(p/2)
    t[0]
    sleep(p)
    @test get(t, 0, nothing) == "!"

    # Disabled refresh on access.
    t = TTL(p; refresh_on_access=false)
    t[0] = "!"
    sleep(p/2)
    t[0]
    sleep(p)
    @test get(t, 0, nothing) === nothing
end
