using ConfParser
using Base.Test

conf = ConfParse("confs/config.http")
parse_conf!(conf)

@test retrieve(conf, "email")    == "juliarocks@socks.com"
@test retrieve(conf, "password") == "qwerty"
@test commit!(conf, "email", "newemail@test.com") == true
save!(conf, "confs/out.conf")

conf = ConfParse("confs/out.conf")
parse_conf!(conf)
@test retrieve(conf, "password") == "qwerty"
@test retrieve(conf, "email") == "newemail@test.com"
