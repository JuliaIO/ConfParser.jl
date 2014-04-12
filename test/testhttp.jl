using ConfParser

conf = ConfParse("config.http")
parse_conf!(conf)

email    = param(conf, "email")
password = param(conf, "password")
foobars  = param(conf, "foobars")
