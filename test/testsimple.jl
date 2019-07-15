using ConfParser
using Test

conf = ConfParse(joinpath(@__DIR__, "confs", "config.simple"))
parse_conf!(conf)

@test retrieve(conf, "protocol") == "kreberos"
@test retrieve(conf, "port")     == "6643"
@test erase!(conf, "protocol")
@test haskey(conf, "port") == true
@test haskey(conf, "nothere") == false
save!(conf, joinpath(@__DIR__, "confs", "out.conf"))

conf = ConfParse(joinpath(@__DIR__, "confs", "out.conf"))
parse_conf!(conf)
@test retrieve(conf, "port")     == "6643"
