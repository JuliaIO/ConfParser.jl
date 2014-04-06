include("../src/ConfParser.jl")

using ConfParser

function main()
    conf = ConfParse("config.ini")
    parse_conf!(conf)
    println(param(conf, ["block" => "lolol", "key" => "foo"]))
    println(param(conf, "haha"))
end

main()
