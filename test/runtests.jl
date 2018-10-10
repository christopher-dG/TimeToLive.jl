using Dates: Millisecond
using TTLCache: TTL, Node
using Test

@testset "TTLCache.jl" begin
    c = TTL(Millisecond(100))
    @test c.ttl == Millisecond(100)
    @test c.d isa Dict{Any, Node{Any}}

    c = TTL{Int, String}(Millisecond(100))
    @test c.d isa Dict{Int, Node{String}}

    c[0] = "!"
    @test c[0] == "!"
    sleep(Millisecond(150))
    @test isempty(c)
    c[0] = "!"
    sleep(Millisecond(50))
    touch(c, 0)
    sleep(Millisecond(100))
    @test c[0] == "!"
    sleep(Millisecond(100))
    @test isempty(c)
end
