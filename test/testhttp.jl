using ConfParser

conf = ConfParse("confs/config.http")
parse_conf!(conf)

email    = retrieve(conf, "email")
password = retrieve(conf, "password")
foobars  = retrieve(conf, "foobars")

commit!(conf, "email", "newemail@test.com")
save!(conf, "outhttp.ini")
