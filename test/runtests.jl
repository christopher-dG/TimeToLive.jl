using Dates: Second
using TimeToLive: TTL, Node
using Test

const period = Second(2)

@testset "TimeToLive.jl" begin
    t = TTL(period)
    @test t.ttl == period
    @test t.d isa Dict{Any, Node{Any}}

    t = TTL{Int, String}(period)
    @test t.d isa Dict{Int, Node{String}}

    t[0] = "!"
    @test get(t, 0, nothing) == "!"
    sleep(period * 2)
    @test isempty(t)

    t[0] = "!"
    sleep(period / 2)
    touch(t, 0)
    sleep(period)
    @test get(t, 0, nothing) == "!"
    sleep(period)
    @test isempty(t)

    t = TTL(period)
    t[1] = t[2] = t[3] = t[4] = t[5] = "!"
    count = 0
    for pair in t
        @test pair isa Pair{Int, String}
        count += 1
    end
    @test count == 5

    t = convert(TTL{String, Int}, TTL(period))
    @test t.d isa Dict{String, Node{Int}}
end
