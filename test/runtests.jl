tests = ["testini.jl",
         "testhttp.jl",
         "testsimple.jl"
]

for test in tests
    include(test)
end

