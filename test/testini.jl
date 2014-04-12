using ConfParser

conf = ConfParse("config.ini")
parse_conf!(conf)

heading  = param(conf, "header")
user     = param(conf, ["block" => "database", "key" => "user"])
password = param(conf, ["block" => "database", "key" => "password"])
host     = param(conf, ["block" => "database", "key" => "host"])
