tests = ["testini.jl",
         "testhttp.jl",
         "testsimple.jl"
]

for test in tests
    include(test)
end

outfile = "confs/out.conf"
if isfile(outfile) == true
    rm(outfile)
end

