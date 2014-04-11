include("../src/ConfParser.jl")

using ConfParser

conf = ConfParse("config.simple")
parse_conf!(conf)

protocol = param(conf, "protocol")
port     = param(conf, "port")
user     = param(conf, "user")

println("Protocol: $protocol Port: $port")
println("User: $user")
