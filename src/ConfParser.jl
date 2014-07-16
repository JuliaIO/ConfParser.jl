module ConfParser

export

# types
ConfParse,

# functions
parse_conf!,
erase!,
save!,
retrieve,
commit!


# contains information of the configuration file such as
# file name, syntax, and the file handler for IO ops
type ConfParse
    _fh::IO
    _filename::ASCIIString
    _syntax::ASCIIString
    _data::Dict
    _is_modified::Bool

    ############################################################
    # ConfParse
    # ---------
    # constructor for ConfParse type.  Sets filename,
    # fh, and syntax fields
    ############################################################

    function ConfParse(filename::ASCIIString, syntax::ASCIIString = "")
        if (isempty(filename))
            error("no file name specified")
        end

        _filename = filename

        if (isempty(syntax))
            _fh = _open_fh(filename, "r")
            _syntax = _guess_syntax(_fh)
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

end # type ConfigParser

############################################################
# _open_fh
# --------
# open file handler for IO
############################################################

function _open_fh(filename::ASCIIString, mode::ASCIIString)
    local fh::IO
    try
        fh = open(filename, mode)
    catch
        error("configuration file could not be opened")
    end
    fh
end

############################################################
# _guess_syntax
# ------------
# attempts to guess the configuration file syntax using
# regular expressions
############################################################

function _guess_syntax(fh::IO)
    local syntax::ASCIIString
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

############################################################
# parse_conf!
# -----------
# tasks appropriate parser method based on configuration
# syntax
############################################################

function parse_conf!(s::ConfParse)
    if (s._syntax == "ini")
        _parse_ini(s)
    elseif (s._syntax == "http")
        _parse_http(s)
    elseif (s._syntax == "simple")
        _parse_simple(s)
    else
        error("unknown configuration syntax: $(s._syntax)")
    end
end # function parse_conf

############################################################
# _parse_line
# -----------
# Sperates by commas, removes newlines and such
############################################################

function _parse_line(line::ASCIIString)
    parsed::Array   = (String)[]
    splitted::Array = split(line, ",")
    for raw = splitted
        if (ismatch(r"\S+", raw))
            clean = match(r"\S+", raw)
            push!(parsed, clean.match)
        end
    end

    parsed
end # function _parse_line

############################################################
# _parse_ini
# ----------
# parses configuration files utilizing ini sytnax.
# Populate the ConfParser.data dictionary
############################################################

function _parse_ini(s::ConfParse)
    local blockname::ASCIIString = "default"
    seekstart(s._fh)
    for line in eachline(s._fh)
        local m::Any
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
                s._data[blockname] = [key => _parse_line(values)]
            else
                merge!(s._data[blockname], [key => _parse_line(values)])
            end
            continue
        end
        error("invalid syntax on line: $(line)")
    end
end # function _parse_ini

############################################################
# _parse_http
# -----------
# parses configuration files utilizing http sytnax.
# Populate the ConfParser.data dictionary
############################################################

function _parse_http(s::ConfParse)
    seekstart(s._fh)
    for line in eachline(s._fh)
        local m::Any
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
            s._data[key] = _parse_line(values)
            continue
        end

        error("invalid syntax on line: $(line)")
    end
end # function _parse_http

############################################################
# _parse_simple
# -------------
# parses configuration files utilizing simple syntax.
# Populates the ConfParser.data dictionary
############################################################

function _parse_simple(s::ConfParse)
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
            s._data[key] = _parse_line(values)
            continue
        end

        error("invalid syntax on line: $(line)")
    end
end # function _parse_simple

############################################################
# _craft_content
# --------------
# craft content strings from data array for saved config
############################################################

function _craft_content(s::ConfParse)
   local content::ASCIIString = ""
   if (s._syntax == "ini")
        for (block, key_values) = s._data
            content *= "[$block]\n"
            for (key, values) = key_values
                if (typeof(values) == Array{String, 1})
                    content *= "$key=$(join(values, ","))\n"
                else
                    content *= "$key=$values\n"
                end
            end
            content *= "\n"
        end

    elseif (s._syntax == "http")
        for (key, values) = s._data
            if (typeof(values) == Array{String, 1})
                content *= "$key: $(join(values, ","))\n"
            else
                content *= "$key: $values\n"
            end
        end

    elseif (s._syntax == "simple")
        for (key, values) = s._data
            if (typeof(values) == Array{String, 1})
                content *= "$key $(join(values, ","))\n"
            else
                content *= "$key $values\n"
            end
        end

    else
        error("unknown syntax type: $(s._syntax)")
    end

    content
end # function _craft_content

############################################################
# erase!
# ------
# remove entry from inside ini block
############################################################

function erase!(s::ConfParse, block::ASCIIString, key::ASCIIString)
    local block_key = getkey(s._data, block, nothing)
    if (block_key != nothing)
        if (haskey(s._data[block_key], key))
            delete!(s._data[block_key], key)
        end
    end

    s._is_modified = true
end # method erase!

############################################################
# erase!
# ------
# remove entry from config (outside of block if ini)
############################################################

function erase!(s::ConfParse, key::ASCIIString)
    if (haskey(s._data, key))
        delete!(s._data, key)
    end

    s._is_modified = true
end # method erase!

############################################################
# save
# -----
# for writing out new or modified configuration files
############################################################

function save!(s::ConfParse, filename::Any = nothing)
    # if data has not been modified and a new file has not
    # been specified, don't write out
    if (s._is_modified == false) && (filename == nothing)
        return
    end

    # if there is no content to write out, don't create an
    # empty file
    content = _craft_content(s)
    if (content == nothing)
        return
    end

    if (filename == nothing)
        s._fh = _open_fh(s._filename, "w")
    else
        s._fh = _open_fh(filename, "w")
    end

    write(s._fh, content)
end # function save

############################################################
# retrieve
# -----
# for retrieving data outside of a block
############################################################

function retrieve(s::ConfParse, key::ASCIIString)
    if (length(s._data[key]) == 1)
        return s._data[key][1]
    end

    s._data[key]
end # method retrieve

############################################################
# retrieve
# -----
# for retrieving data from an ini config file block
############################################################

function retrieve(s::ConfParse, block::ASCIIString, key::ASCIIString)

    if (length(s._data[block][key]) == 1)
        return s._data[block][key][1]
    end

    s._data[block][key]
end # method retrieve

############################################################
# commit!
# -----
# for inserting data in a config file
############################################################

function commit!(s::ConfParse, key::ASCIIString, value::Any)
    s._data[key]   = value
    s._is_modified = true
end # method commit!

############################################################
# commit!
# -----
# for inserting data inside an ini file block
############################################################

function commit!(s::ConfParse, block::ASCIIString, key::ASCIIString, values::ASCIIString)
    if (s._syntax != "ini")
        error("invalid setter method called for syntax type: $(s._syntax)")
    end

    s._data[block][key] = [values]
    s._is_modified      = true
end # method commit!

end # module ConfParser
