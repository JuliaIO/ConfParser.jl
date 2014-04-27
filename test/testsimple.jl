using ConfParser

conf = ConfParse("confs/config.simple")
parse_conf!(conf)

protocol = retrieve(conf, "protocol")
port     = retrieve(conf, "port")
user     = retrieve(conf, "user")

erase!(conf, "protocol")

save!(conf, "outconf.simple")
