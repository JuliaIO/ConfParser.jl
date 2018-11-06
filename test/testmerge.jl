using ConfParser, Compat
using Compat.Test

conf = ConfParse("confs/config.ini")
parse_conf!(conf)
loc = ConfParse("confs/local.ini")
parse_conf!(loc)

@test retrieve(conf, "database", "user") == "dbuser"
@test retrieve(conf, "database", "password") == "abc123"
@test retrieve(loc, "database", "password") == "xyz789"
@test retrieve(loc, "foobar", "foo") == ["foo","bar"]
@test merge!(conf, loc) == true
save!(conf, "confs/out.conf")

# validate new conf write
conf = ConfParse("confs/out.conf")
parse_conf!(conf)
@test retrieve(conf, "database", "user") == "dbuser"
@test retrieve(conf, "database", "password") == "xyz789"
@test retrieve(conf, "foobar", "foo") == ["foo","bar"]
