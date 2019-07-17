using ConfParser
using Test

conf = ConfParse(joinpath(@__DIR__, "confs", "config.http"))
parse_conf!(conf)

@test retrieve(conf, "email")    == "juliarocks@socks.com"
@test retrieve(conf, "password") == "qwerty"
@test commit!(conf, "email", "newemail@test.com") == true
@test haskey(conf, "email") == true
@test haskey(conf, "nothere") == false
save!(conf, joinpath(@__DIR__, "confs", "out.conf"))

conf = ConfParse(joinpath(@__DIR__, "confs", "out.conf"))
parse_conf!(conf)
@test retrieve(conf, "password") == "qwerty"
@test retrieve(conf, "email") == "newemail@test.com"
