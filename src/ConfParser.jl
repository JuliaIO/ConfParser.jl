module ConfParser

import Base: haskey, merge!

export ConfParse, parse_conf!, erase!, save!, retrieve, commit!, haskey, merge!

Base.@deprecate open_fh(filename::String, mode::String) open(filename, mode) false

mutable struct ConfParse
    _fh::IO
    _filename::String
    _syntax::String
    _data::Dict
    _is_modified::Bool

    function ConfParse(filename::AbstractString, syntax::AbstractString="")
        isempty(filename) && throw(ArgumentError("no file name specified"))
        fh = open(filename, "r")
        if isempty(syntax)
            syntax = guess_syntax(fh)
        elseif !(syntax == "ini" || syntax == "http" || syntax == "simple")
            close(fh)
            throw(ArgumentError("unrecognized configuration syntax: $syntax"))
        end
        conf = new(fh, filename, syntax, Dict(), false)
        finalizer(c->close(c._fh), conf)
        return conf
    end
end

"""
    guess_syntax(fh::IO)

Attempts to guess the configuration file syntax using
regular expressions.
"""
function guess_syntax(fh::IO)
    for line in eachline(fh)
        # is a commented line
        occursin(r"^\s*(?:#|$)", line) && continue

        # is not alphanumeric
        occursin(r"\w", line) || continue

        # remove \n
        line = chomp(line)

        # contains a [block]; ini
        occursin(r"^\s*\[\s*[^\]]+\s*\]\s*$", line) && return "ini"

        # key/value pairs are seperated by a '='; ini
        occursin(r"^\s*[\w-]+\s*=\s*.*\s*$", line) && return "ini"

        # key/value pairs are seperated by a ':'; http
        occursin(r"^\s*[\w-]+\s*:\s*.*\s*$", line) && return "http"

        # key/value pairs are seperated by whitespace; simple
        occursin(r"^\s*[\w-]+\s+.*$", line) && return "simple"
    end

    error("unable to identify the configuration file syntax")
end

"""
    parse_conf!(s::ConfParse)

Tasks appropriate parser function based on configuration syntax.
"""
function parse_conf!(s::ConfParse)
    if s._syntax == "ini"
        parse_ini(s)
    elseif s._syntax == "http"
        parse_http(s)
    elseif s._syntax == "simple"
        parse_simple(s)
    else
        error("unknown configuration syntax: $(s._syntax)")
    end
end

"""
    parse_line(line::String)

Sperates by commas, removes newlines and such.
"""
function parse_line(line::String)
    parsed   = String[]
    splitted = split(line, ",")
    for raw = splitted
        if occursin(r"\S+", raw)
            clean = match(r"\S+", raw)
            push!(parsed, clean.match)
        end
    end
    parsed
end

"""
    parse_ini(s::ConfParse)

Parses configuration files utilizing ini sytnax.
Populate the ConfParser.data dictionary.
"""
function parse_ini(s::ConfParse)
    blockname = "default"
    seekstart(s._fh)
    for line in eachline(s._fh)
        # skip comments and newlines
        occursin(r"^\s*(\n|\#|;)", line) && continue

        occursin(r"\w", line) || continue

        line = chomp(line)

        # parse blockname
        m = match(r"^\s*\[\s*([^\]]+)\s*\]$", line)
        if m !== nothing
            blockname = lowercase(m.captures[1])
            continue
        end

        # parse key/value
        m = match(r"^\s*([^=]*[^\s])\s*=\s*(.*)\s*$", line)
        if m !== nothing
            key::String, values::String = m.captures
            if !haskey(s._data, blockname)
                s._data[blockname] = Dict(key => parse_line(values))
            else
                merge!(s._data[blockname], Dict(key => parse_line(values)))
            end
            continue
        end

        error("invalid syntax on line: $(line)")
    end
    nothing
end

"""
    parse_http(s::ConfParse)

Parses configuration files utilizing http sytnax.
Populate the ConfParser.data dictionary.
"""
function parse_http(s::ConfParse)
    seekstart(s._fh)
    for line in eachline(s._fh)
        # skip comments and newlines
        occursin(r"^\s*(\n|\#|;)", line) && continue

        occursin(r"\w", line) || continue

        line = chomp(line)

        m = match(r"^\s*([\w-]+)\s*:\s*(.*)$", line)
        if m !== nothing
            key::String, values::String = m.captures
            s._data[key] = parse_line(values)
            continue
        end

        error("invalid syntax on line: $(line)")
    end
end

"""
    parse_simple(s::ConfParse)

Parses configuration files utilizing simple syntax.
Populates the ConfParser.data dictionary.
"""
function parse_simple(s::ConfParse)
    seekstart(s._fh)
    for line in eachline(s._fh)
        # skip comments and newlines
        occursin(r"^\s*(\n|\#|;)", line) && continue

        occursin(r"\w", line) || continue

        line = chomp(line)

        m = match(r"^\s*([\w-]+)\s+(.*)\s*$", line)
        if m !== nothing
            key::String, values::String = m.captures
            s._data[key] = parse_line(values)
            continue
        end

        error("invalid syntax on line: $(line)")
    end
    nothing
end

"""
    craft_content(s::ConfParse)

Craft content strings from data array for saved config.
"""
function craft_content(s::ConfParse)
   content = IOBuffer()
   if s._syntax == "ini"
        for (block, key_values) = s._data
            println(content, "[$block]")
            for (key, values) = key_values
                if values isa Vector{<:AbstractString}
                    print(content, key, '=')
                    join(content, values, ',')
                    println(content)
                else
                    println(content, key, '=', values)
                end
            end
            println(content)
        end
    elseif s._syntax == "http"
        for (key, values) = s._data
            if values isa Vector{<:AbstractString}
                print(content, key, ": ")
                join(content, values, ',')
                println(content)
            else
                println(content, key, ": ", values)
            end
        end
    elseif s._syntax == "simple"
        for (key, values) = s._data
            if values isa Vector{<:AbstractString}
                print(content, key, ' ')
                join(content, values, ',')
                println(content)
            else
                println(content, key, ' ', values)
            end
        end
    else
        error("unknown syntax type: $(s._syntax)")
    end
    String(take!(content))
end

"""
    erase!(s::ConfParse, block::String, key::String)

Remove entry from ini block.
"""
function erase!(s::ConfParse, block::String, key::String)
    block_key = getkey(s._data, block, nothing)
    if block_key !== nothing
        if haskey(s._data[block_key], key)
            delete!(s._data[block_key], key)
            s._is_modified = true
        end
    end
    s._is_modified
end

"""
    erase!(s::ConfParse, key::String)
    
Remove entry from config (outside of block if ini).
"""
function erase!(s::ConfParse, key::String)
    if haskey(s._data, key)
        delete!(s._data, key)
        s._is_modified = true
    end
    s._is_modified
end

"""
    save!(s::ConfParse, filename=nothing)

Write out new or modified configuration files.
"""
function save!(s::ConfParse, filename=nothing)
    # if data has not been modified and a new file has not
    # been specified, don't write out
    !s._is_modified && filename === nothing && return

    # if there is no content to write out, don't create an
    # empty file
    content = craft_content(s)
    content === nothing && return

    if filename === nothing
        s._fh = open(s._filename, "w")
    else
        s._fh = open(filename, "w")
    end

    write(s._fh, content)
    flush(s._fh)
    nothing
end

"""
    retrieve(s::ConfParse, key::String)

Retrieve data outside of a block.
"""
function retrieve(s::ConfParse, key::String)
    k = s._data[key]
    length(k) == 1 ? first(k) : k
end

"""
    retrieve(s::ConfParse, block::String, key::String)

Retrieve data from an ini config file block.
"""
function retrieve(s::ConfParse, block::String, key::String)
    k = s._data[block][key]
    length(k) == 1 ? first(k) : k
end

"""
    retrieve(s::ConfParse, key::String, t::Type)

Retrieve data outside of a block and converting to type.
"""
function retrieve(s::ConfParse, key::String, t::Type)
    k = s._data[key]
    parse(t, length(k) == 1 ? first(k) : k)
end

"""
    retrieve(s::ConfParse, block::String, key::String, t::Type)

Retrieve data from an ini config file block and converting to type.
"""
function retrieve(s::ConfParse, block::String, key::String, t::Type)
    k = s._data[block][key]
    parse(t, length(k) == 1 ? first(k) : k)
end

"""
    commit!(s::ConfParse, key::String, value::Any)

Insert data in a config file.
"""
function commit!(s::ConfParse, key::String, value::Any)
    s._data[key]   = value
    s._is_modified = true
end

"""
    commit!(s::ConfParse, block::String, key::String, values::String)

Insert data inside an ini file block.
"""
function commit!(s::ConfParse, block::String, key::String, values::String)
    if s._syntax != "ini"
        throw(ArgumentError("invalid setter function called for syntax type: $(s._syntax)"))
    end
    s._data[block][key] = [values]
    s._is_modified      = true
end

"""
    Base.merge!(s::ConfParse, t::ConfParse)

Merge data of two configuration files.
"""
function merge!(s::ConfParse, t::ConfParse)
    for (block, key_values) = t._data
        if !haskey(s._data, block)
            s._data[block] = key_values
        else
            merge!(s._data[block], key_values)
        end
    end
    s._is_modified = true
end

"""
    haskey(s::ConfParse, key::String)

Check if a key exists.
"""
haskey(s::ConfParse, key::String) = haskey(s._data, key)

"""
    haskey(s::ConfParse, block::String, key::String)

Check if a key exists inside an ini file block.
"""
haskey(s::ConfParse, block::String, key::String) = haskey(s._data, block) && haskey(s._data[block], key)

end # module ConfParser
