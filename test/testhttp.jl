using ConfParser
using Test

conf = ConfParse(joinpath(@__DIR__, "confs", "config.http"))
parse_conf!(conf)

@test retrieve(conf, "email")    == "juliarocks@socks.com"
@test retrieve(conf, "password") == "qwerty"
@test commit!(conf, "email", "newemail@test.com") == true
save!(conf, joinpath(@__DIR__, "confs", "out.conf"))

conf = ConfParse(joinpath(@__DIR__, "confs", "out.conf"))
parse_conf!(conf)
@test retrieve(conf, "password") == "qwerty"
@test retrieve(conf, "email") == "newemail@test.com"
