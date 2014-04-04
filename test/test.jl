include("../src/ConfParser.jl")

using ConfParser

function main()
    conf = ConfParse("config.ini")
    parse_conf!(conf)
    println(conf.data)
end

main()
