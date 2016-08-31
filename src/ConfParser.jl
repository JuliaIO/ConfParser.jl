module ConfParser

export ConfParse, parse_conf!, erase!,
       save!, retrieve, commit!


type ConfParse
    _fh::IO
    _filename::ASCIIString
    _syntax::ASCIIString
    _data::Dict
    _is_modified::Bool

    function ConfParse(filename::ASCIIString, syntax::ASCIIString = "")
        if (isempty(filename))
            error("no file name specified")
        end

        _filename = filename
        _fh = open_fh(filename, "r") # _fh was defined inside if-statement: so if syntax!="", then _fh is not defined
        if (isempty(syntax))
            _syntax = guess_syntax(_fh)
        else
            if ((syntax != "ini")  &&
                (syntax != "http") &&
                (syntax != "simple"))
                error("unknown configuration syntax: $(syntax)")
            end
            _syntax = syntax
        end
        _data        = Dict()
        _is_modified = false
        new(_fh, _filename, _syntax,
            _data, _is_modified)
    end # function ConfParse

end # type ConfParse

#----------
# open file handler for IO
#----------
function open_fh(filename::ASCIIString, mode::ASCIIString)
    try
        fh = open(filename, mode)
        return fh
    catch
        error("configuration file could not be opened")
    end
end

#------------
# attempts to guess the configuration file syntax using
# regular expressions
#----------
function guess_syntax(fh::IO)
    syntax = ""
    for line in eachline(fh)

        # is a commented line
        if (ismatch(r"^\s*(?:#|$)", line))
            continue
        end

        # is not alphanumeric
        if (!ismatch(r"\w", line))
            continue
        end

        # remove \n
        line = chomp(line)

        # contains a [block]; ini
        if (ismatch(r"^\s*\[\s*[^\]]+\s*\]\s*$", line))
            syntax = "ini"
            break
        end

        # key/value pairs are seperated by a '='; ini
        if (ismatch(r"^\s*[\w-]+\s*=\s*.*\s*$", line))
            syntax = "ini"
            break
        end

        # key/value pairs are seperated by a ':'; http
        if (ismatch(r"^\s*[\w-]+\s*:\s*.*\s*$", line))
            syntax = "http"
            break
        end

        # key/value pairs are seperated by whitespace; simple
        if (ismatch(r"^\s*[\w-]+\s+.*$", line))
            syntax = "simple"
            break
        end
    end

    if (syntax != "")
        return syntax
    end

    error("unable to identify the configuration file syntax")
end # function guess_syntax

#----------
# tasks appropriate parser function based on configuration
# syntax
#----------
function parse_conf!(s::ConfParse)
    if (s._syntax == "ini")
        parse_ini(s)
    elseif (s._syntax == "http")
        parse_http(s)
    elseif (s._syntax == "simple")
        parse_simple(s)
    else
        error("unknown configuration syntax: $(s._syntax)")
    end
    
    close(s._fh)                # no need to keep file opened
end # function parse_conf

#----------
# Sperates by commas, removes newlines and such
#----------
function parse_line(line::ASCIIString)
    parsed   = (AbstractString)[]
    splitted = split(line, ",")
    for raw = splitted
        if (ismatch(r"\S+", raw))
            clean = match(r"\S+", raw)
            push!(parsed, clean.match)
        end
    end

    parsed
end # function parse_line

#----------
# parses configuration files utilizing ini sytnax.
# Populate the ConfParser.data dictionary
#----------
function parse_ini(s::ConfParse)
    blockname = "default"
    seekstart(s._fh)
    for line in eachline(s._fh)
        # skip comments and newlines
        if (ismatch(r"^\s*(\n|\#|;)", line))
            continue
        end

        if (!ismatch(r"\w", line))
            continue
        end

        line = chomp(line)

        # parse blockname
        m = match(r"^\s*\[\s*([^\]]+)\s*\]$", line)
        if (m != nothing)
            blockname = lowercase(m.captures[1])
            continue
        end

        # parse key/value
        m = match(r"^\s*([^=]*\w)\s*=\s*(.*)\s*$", line)
        if (m != nothing)
            key::ASCIIString, values::ASCIIString = m.captures
            if (!haskey(s._data, blockname))
                s._data[blockname] = Dict(key => parse_line(values))
            else
                merge!(s._data[blockname], Dict(key => parse_line(values)))
            end
            continue
        end
        error("invalid syntax on line: $(line)")
    end
end # function parse_ini

#----------
# parses configuration files utilizing http sytnax.
# Populate the ConfParser.data dictionary
#----------
function parse_http(s::ConfParse)
    seekstart(s._fh)
    for line in eachline(s._fh)
        # skip comments and newlines
        if (ismatch(r"^\s*(\n|\#|;)", line))
            continue
        end

        if (!ismatch(r"\w", line))
            continue
        end

        line = chomp(line)

        m = match(r"^\s*([\w-]+)\s*:\s*(.*)$", line)
        if (m != nothing)
            key::ASCIIString, values::ASCIIString = m.captures
            s._data[key] = parse_line(values)
            continue
        end

        error("invalid syntax on line: $(line)")
    end
end # function parse_http

#----------
# parses configuration files utilizing simple syntax.
# Populates the ConfParser.data dictionary
#----------
function parse_simple(s::ConfParse)
    seekstart(s._fh)
    for line in eachline(s._fh)
        # skip comments and newlines
        if (ismatch(r"^\s*(\n|\#|;)", line))
            continue
        end

        if (!ismatch(r"\w", line))
            continue
        end

        line = chomp(line)

        m = match(r"^\s*([\w-]+)\s+(.*)\s*$", line)
        if (m != nothing)
            key::ASCIIString, values::ASCIIString = m.captures
            s._data[key] = parse_line(values)
            continue
        end

        error("invalid syntax on line: $(line)")
    end
end # function parse_simple

#----------
# craft content strings from data array for saved config
#----------
function craft_content(s::ConfParse)
   content = ""
   if (s._syntax == "ini")
        for (block, key_values) = s._data
            content *= "[$block]\n"
            for (key, values) = key_values
                if (typeof(values) == Array{AbstractString, 1})
                    content *= "$key=$(join(values, ","))\n"
                else
                    content *= "$key=$values\n"
                end
            end
            content *= "\n"
        end

    elseif (s._syntax == "http")
        for (key, values) = s._data
            if (typeof(values) == Array{AbstractString, 1})
                content *= "$key: $(join(values, ","))\n"
            else
                content *= "$key: $values\n"
            end
        end

    elseif (s._syntax == "simple")
        for (key, values) = s._data
            if (typeof(values) == Array{AbstractString, 1})
                content *= "$key $(join(values, ","))\n"
            else
                content *= "$key $values\n"
            end
        end

    else
        error("unknown syntax type: $(s._syntax)")
    end

    content
end # function craft_content

#----------
# remove entry from inside ini block
#----------
function erase!(s::ConfParse, block::ASCIIString, key::ASCIIString)
    block_key = getkey(s._data, block, nothing)
    if (block_key != nothing)
        if (haskey(s._data[block_key], key))
            delete!(s._data[block_key], key)
        end
    end
    
    s._is_modified = true
end # function erase!

#----------
# remove entry from config (outside of block if ini)
#----------
function erase!(s::ConfParse, key::ASCIIString)
    if (haskey(s._data, key))
        delete!(s._data, key)
    end
   
    s._is_modified = true
end # function erase!

#----------
# for writing out new or modified configuration files
#----------
function save!(s::ConfParse, filename::Any = nothing)
    # if data has not been modified and a new file has not
    # been specified, don't write out
    if (s._is_modified == false) && (filename == nothing)
        return
    end

    # if there is no content to write out, don't create an
    # empty file
    content = craft_content(s)
    if (content == nothing)
        return
    end

    if (filename == nothing)
        s._fh = open_fh(s._filename, "w")
    else
        s._fh = open_fh(filename, "w")
    end
    
    write(s._fh, content)
    close(s._fh)                # if not closed, content is written when julia-session finishes
end # function save

#----------
# for retrieving data outside of a block
#----------
function retrieve(s::ConfParse, key::ASCIIString)
    if (length(s._data[key]) == 1)
        return s._data[key][1]
    end

    s._data[key]
end # function retrieve

#----------
# for retrieving data from an ini config file block
#----------
function retrieve(s::ConfParse, block::ASCIIString, key::ASCIIString)
    if (length(s._data[block][key]) == 1)
        return s._data[block][key][1]
    end

    s._data[block][key]
end # function retrieve

#----------
# for retrieving data outside of a block and converting to type
#----------
function retrieve(s::ConfParse, key::ASCIIString, t::Type) 
    if (length(s._data[key]) == 1)
        return parse(t, s._data[key][1])
    end

    parse(t, s._data[key])
end # function retrieve

#----------
# for retrieving data from an ini config file block and converting to type
#----------
function retrieve(s::ConfParse, block::ASCIIString, key::ASCIIString, t::Type) 
    if (length(s._data[block][key]) == 1)
        return parse(t, s._data[block][key][1])
    end

    parse(t, s._data[block][key])
end # function retrieve

#----------
# for inserting data in a config file
#----------
function commit!(s::ConfParse, key::ASCIIString, value::Any)
    s._data[key]   = value
    s._is_modified = true
end # function commit!

#----------
# for inserting data inside an ini file block
#----------
function commit!(s::ConfParse, block::ASCIIString, key::ASCIIString, values::ASCIIString)
    if (s._syntax != "ini")
        error("invalid setter function called for syntax type: $(s._syntax)")
    end

    s._data[block][key] = [values]
    s._is_modified      = true
end # function commit!

end # module ConfParser
