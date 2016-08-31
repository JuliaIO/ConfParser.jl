using ConfParser
using Base.Test

conf = ConfParse("confs/config.simple")
parse_conf!(conf)

@test retrieve(conf, "protocol") == "kreberos"
@test retrieve(conf, "port")     == "6643"
@test erase!(conf, "protocol")   == true
save!(conf, "confs/out.conf")

conf = ConfParse("confs/out.conf")
parse_conf!(conf)
@test retrieve(conf, "port")     == "6643"
