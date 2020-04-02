using ConfParser
using Test

conf = ConfParse(joinpath(@__DIR__, "confs", "config.keyonly"))
parse_conf!(conf)

@test retrieve(conf, "key") == "e613ef71d63b84b721bdd345a5708ce5738028"
@test haskey(conf, "key") == true
@test haskey(conf, "nothere") == false
@test erase!(conf, "key")
@test commit!(conf,"key","e613ef71d63b84b721bdd345a5708ce5738028")
save!(conf, joinpath(@__DIR__, "confs", "out.conf"))

conf = ConfParse(joinpath(@__DIR__, "confs", "out.conf"))
parse_conf!(conf)
@test retrieve(conf, "key")     == "e613ef71d63b84b721bdd345a5708ce5738028"
