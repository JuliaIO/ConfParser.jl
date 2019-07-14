using ConfParser
using Test

conf = ConfParse(joinpath(@__DIR__, "confs", "config.ini"))
parse_conf!(conf)

@test retrieve(conf, "database", "user") == "dbuser"
@test retrieve(conf, "database", "password") == "abc123"
@test retrieve(conf, "database", "speed of light (m/s)") == "3e8"
@test commit!(conf, "default", "database", "newuser")
@test erase!(conf, "foobarness")
@test haskey(conf, "database", "user") == true
@test haskey(conf, "database", "nothere") == false
@test haskey(conf, "nothere", "foo") == false
save!(conf, joinpath(@__DIR__, "confs", "out.conf"))

# validate new conf write
conf = ConfParse(joinpath(@__DIR__, "confs", "out.conf"))
parse_conf!(conf)
@test retrieve(conf, "database", "user") == "dbuser"
@test retrieve(conf, "default", "database") == "newuser"
