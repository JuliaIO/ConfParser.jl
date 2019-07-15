# ConfParser.jl

ConfParser is a package for parsing, modifying, and writing to configuration files. ConfParser can handle configuration files utilizing multiple syntaxes to include INI, HTTP, and simple.

## Index

```@index
Pages = ["index.md"]
```

## Examples

### INI Files
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

# get and store config parameters
user     = retrieve(conf, "database", "user")
password = retrieve(conf, "database", "password")
host     = retrieve(conf, "database", "host")

# replace config paramater
commit!(conf, "database", "user", "newuser")

# erase a config block
erase!(conf, "foobarness")

# save to another file
save!(conf, "testout.ini")
```

### HTTP Files

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

# get and store config parameters
email    = retrieve(conf, "email")
password = retrieve(conf, "password")
foobars  = retrieve(conf, "foobars")

# modify config parameter
commit!(conf, "email", "newemail@test.com")

# save changes
save!(conf)
```

### Simple Files

```
# this is a comment
protocol kreberos
port 6643
user root

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

# remove config parameter
erase!(conf, "protocol")

# generate new config from data
save!(conf, "outconf.simple")
```

## Public Interface

```@autodocs
Modules = [ConfParser]
Private = false
```

## Internals

```@autodocs
Modules = [ConfParser]
Public = true
```