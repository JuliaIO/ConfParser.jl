using ConfParser

conf = ConfParse("confs/config.ini")
parse_conf!(conf)

# get parameters
user     = retrieve(conf, ["block" => "database", "key" => "user"])
password = retrieve(conf, ["block" => "database", "key" => "password"])
host     = retrieve(conf, ["block" => "database", "key" => "host"])

# replace entry
commit!(conf, ["block" => "database", "key" => "user"], "newuser")

# erase a block
erase!(conf, "foobarness")

# save to another file
save!(conf, "testout.ini")
