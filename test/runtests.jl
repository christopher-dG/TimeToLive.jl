using Dates: Second
using TTLCache: TTL, Node
using Test

const period = Second(2)

@testset "TTLCache.jl" begin
    c = TTL(period)
    @test c.ttl == period
    @test c.d isa Dict{Any, Node{Any}}

    c = TTL{Int, String}(period)
    @test c.d isa Dict{Int, Node{String}}

    c[0] = "!"
    @test c[0] == "!"
    sleep(period * 2)
    @test isempty(c)
    c[0] = "!"
    sleep(period / 2)
    touch(c, 0)
    sleep(period)
    @test c[0] == "!"
    sleep(period)
    @test isempty(c)
end
