####ConfParser.jl
ConfParser is a package for parsing configuration files.  Currently, ConfParser
parses files utilizing ini, http, and simple configuration syntaxes.

## INI Files

```
# this config file uses ini syntax
header=juliarocks

# this is a comment
[database]
user=dbuser
password=abc123
host=localhost

# this is another comment
[foobarness]
foo=bar
foobar=barfoo
```

```julia
using ConfParser

conf = ConfParse("config.ini")
parse_conf!(conf)

header  = param(conf, "header")
user     = param(conf, ["block" => "database", "key" => "user"])
password = param(conf, ["block" => "database", "key" => "password"])
host     = param(conf, ["block" => "database", "key" => "host"])

println("Header: $header")
println("User: $user Password: $password Host: $host")

# $ julia testini.jl
# Header: juliarocks
# User: dbuser Password: abc123 Host: localhost

```
