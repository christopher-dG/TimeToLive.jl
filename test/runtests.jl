using Dates: Second
using TimeToLive: TTL, Node
using Test

const period = Second(2)

@testset "TimeToLive.jl" begin
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

    c = TTL(period)
    c[1] = c[2] = c[3] = c[3] = c[5] = "!"
    count = 0
    for pair in c
        @test pair isa Pair{Int, String}
        count += 1
    end
    @test count == 5

    c = convert(TTL{String, Int}, TTL(period))
    @test c.d isa Dict{String, Node{Int}}
end
