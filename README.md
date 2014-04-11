##ConfParser.jl
ConfParser is a package for parsing configuration files.  Currently, ConfParser
parses files utilizing ini, http, and simple configuration syntaxes.

####INI Files

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

####HTTP Files

```
# this is a comment
email:juliarocks@socks.com
password:qwerty

# this is another comment
url:julialang.org
foobars:foo,bar
```

```julia
using ConfParser

conf = ConfParse("config.http")
parse_conf!(conf)

email    = param(conf, "email")
password = param(conf, "password")

# gets multiple values seperated by comma
foobars  = param(conf, "foobars")

println("Email: $email Password: $password")

# print values in foobars line
println("Foobars:")
for value = foobars
    println("- $value")
end

# $ julia testhttp.jl
# Email: juliarocks@socks.com Password: qwerty
# Foobars:
# - foo
# - bar

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

conf = ConfParse("config.simple")
parse_conf!(conf)

protocol = param(conf, "protocol")
port     = param(conf, "port")
user     = param(conf, "user")

println("Protocol: $protocol Port: $port")
println("User: $user")

# $ julia testsimple.jl
# Protocol: kreberos Port: 6643
# User: root
```
