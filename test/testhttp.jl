include("../src/ConfParser.jl")

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

