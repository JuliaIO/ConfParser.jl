include("../src/ConfParser.jl")

using ConfParser

conf = ConfParse("config.ini")
parse_conf!(conf)

heading  = param(conf, "header")
user     = param(conf, ["block" => "database", "key" => "user"])
password = param(conf, ["block" => "database", "key" => "password"])
host     = param(conf, ["block" => "database", "key" => "host"])

println("Header: $heading")
println("User: $user Password: $password Host: $host")

