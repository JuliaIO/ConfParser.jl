##ConfParser.jl
ConfParser is a package for parsing, modifying, and writing to configuration
files.  ConfParser can handle configuration files utilizing multiple syntaxes
to include INI, HTTP, and simple.

####INI Files

```
header=leheader

; this is a comment
[database]
user=dbuser
password=abc123
host=localhost

; this is another comment
[foobarness]
foo=bar,foo
foobar=barfoo
```

```julia
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
```

####HTTP Files

```
# this is a comment
email:juliarocks@socks.com
password:qwerty

# this is another comment
url:julialang.org
foobars:foo,bar,snafu
```

```julia
using ConfParser

conf = ConfParse("confs/config.http")
parse_conf!(conf)

# store config items in vars
email    = retrieve(conf, "email")
password = retrieve(conf, "password")
foobars  = retrieve(conf, "foobars")

# modify email parameter
commit!(conf, "email", "newemail@test.com")

# save changes
save!(conf)
```

####Simple Files

```
# this is a comment
protocol kreberos
port 6643
user                root

# this is another comment
foobar barfoo
```

```julia
using ConfParser

conf = ConfParse("confs/config.simple")
parse_conf!(conf)

# store config items in vars
protocol = retrieve(conf, "protocol")
port     = retrieve(conf, "port")
user     = retrieve(conf, "user")

# remove protocol element
erase!(conf, "protocol")

# save to new file
save!(conf, "outconf.simple")
```
