using ConfParser
using Base.Test

conf = ConfParse("confs/config.ini")
parse_conf!(conf)

@test retrieve(conf, "database", "user") == "dbuser"
@test retrieve(conf, "database", "password") == "abc123"
@test commit!(conf, "default", "database", "newuser") == true
@test erase!(conf, "foobarness") == true
save!(conf, "confs/out.conf")

# validate new conf write
conf = ConfParse("confs/out.conf")
parse_conf!(conf)
@test retrieve(conf, "database", "user") == "dbuser"
@test retrieve(conf, "default", "database") == "newuser"
