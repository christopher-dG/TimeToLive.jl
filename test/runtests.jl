using Dates: Millisecond
using TimeToLive: TTL, Node
using Test: @test, @testset, @test_throws

const p = Millisecond(250)

@testset "TimeToLive.jl" begin
    @testset "Constructors" begin
        t = TTL(p)
        @test t.ttl == p
        @test t.dict isa Dict{Any, Node{Any}}
        t = TTL{Int, String}(p)
        @test t.dict isa Dict{Int, Node{String}}
    end

    @testset "Basic expiry" begin
        t = TTL(p)
        t[0] = "!"
        @test get(t, 0, nothing) == "!"
        sleep(p)
        @test isempty(t)
    end

    @testset "Iteration" begin
        t = TTL(p)
        t[0] = "?"
        sleep(p)
        foreach(i -> t[i] = "!", 1:5)
        count = 0
        for pair in t
            @test pair isa Pair{Int, String}
            @test pair.second == "!"
            count += 1
        end
        @test count == 5
    end

    @testset "Refresh on access" begin
        t = TTL(p; refresh_on_access=true)
        t[0] = "!"
        sleep(3p/5)
        t[0]
        sleep(p/2)
        @test get(t, 0, nothing) == "!"
    end

    @testset "Disabled refresh on access" begin
        t = TTL(p; refresh_on_access=false)
        t[0] = "!"
        sleep(p/2)
        t[0]
        sleep(p)
        @test get(t, 0, nothing) === nothing
    end

    @testset "Base methods" begin
        @testset "delete!" begin
            t = TTL(p)
            t[0] = 1
            @test delete!(t, 0) === t
            @test isempty(t)
            @test delete!(t, 1) === t
        end

        @testset "empty!" begin
            t = TTL(p)
            t[0] = t[1] = 2
            @test empty!(t) === t
            @test isempty(t)
        end

        @testset "get" begin
            t = TTL(p)
            @test get(t, 0, nothing) === nothing
            t[0] = 1
            @test get(t, 0, nothing) == 1
            sleep(p)
            @test get(t, 0, nothing) === nothing

            @test get(() -> nothing, t, 0) === nothing
            t[0] = 1
            @test get(() -> nothing, t, 0) == 1
            sleep(p)
            @test get(() -> nothing, t, 0) === nothing
        end

        @testset "get!" begin
            t = TTL(p)
            @test get!(t, 0, 1) == 1
            @test t[0] == 1
            t[1] = 2
            @test get!(t, 1, 3) == 2
            @test t[1] == 2
            sleep(p)
            @test get!(t, 1, 3) == 3
            @test t[1] == 3
        end

        @testset "getkey" begin
            t = TTL(p)
            t[1] = 2
            @test getkey(t, 0, nothing) === nothing
            @test getkey(t, 1, nothing) == 1
            sleep(2p)
            @test getkey(t, 1, nothing) === nothing
        end

        @testset "length" begin
            t = TTL(p)
            @test length(t) == 0
            t[1] = t[2] = t[3] = 4
            @test length(t) == 3
            sleep(p/2)
            t[5] = 6
            sleep(p/2)
            @test length(t) == 1
        end

        @testset "pop!" begin
            t = TTL(p)
            t[1] = 2
            t[3] = 4
            t[5] = 6
            t[7] = 8
            @test pop!(t) == (7 => 8)
            @test length(t) == 3
            @test pop!(t, 1) == 2
            @test length(t) == 2
            sleep(p)
            @test_throws KeyError pop!(t, 5)
            @test_throws ArgumentError pop!(t)
        end

        @testset "push!" begin
            t = TTL(p)
            @test push!(t, 1 => 2) === t
            @test t[1] == 2
        end

        @testset "sizehint!" begin
            t = TTL(p)
            @test sizehint!(t, 10) === t
        end

        @testset "Others" begin
            t = TTL(p)
            t[1] = 2
            t[2] = 3
            t[3] = 4
            t[4] = 5
            t[5] = 6

            @test all(v -> v isa Int, values(t))
            @test length(filter!(p -> p.second > 2, t)) == 4
            @test !haskey(t, 1)
        end
    end
end
