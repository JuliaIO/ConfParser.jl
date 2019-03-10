tests = ["testini.jl",
         "testhttp.jl",
         "testsimple.jl",
         "testmerge.jl"]

for test in tests
    include(test)
end

outfile = joinpath(@__DIR__, "confs", "out.conf")
if isfile(outfile)
    rm(outfile)
end
