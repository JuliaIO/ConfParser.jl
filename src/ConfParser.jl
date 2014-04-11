module ConfParser

export

# types
ConfParse,

# functions
parse_conf!,
param


# contains information of the configuration file such as
# file name, syntax, and the file handler for IO ops

type ConfParse
    file_handle::IO
    file_name::String
    syntax::String
    data::Dict

    ############################################################    
    # ConfParse
    # ---------
    # constructor for ConfParse type.  Sets file_name,
    # file_handle, and syntax fields
    ############################################################
    
    function ConfParse(file_name::String, syntax::String = "")
        self = new()
        if (isempty(file_name))
            error("no file name specified")
        end

        self.file_name = file_name
        self.file_handle = _open_fh(file_name, "r")

        if (isempty(syntax))
            self.syntax = _guess_syntax(self.file_handle)
        else
            if ((syntax != "ini")  &&
                (syntax != "http") &&
                (syntax != "simple"))
                error("unknown configuration syntax: $(syntax)")
            end
            self.syntax = syntax
        end

        self.data = Dict()
        return self
    end # function ConfParse

end # type ConfigParser

############################################################
# _open_fh
# --------
# open file handler for IO
############################################################

function _open_fh(file_name::String, mode::String)
    local fh::IO
    try
        fh = open(file_name, mode)
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
    local syntax::String

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

function parse_conf!(self::ConfParse)
    if (self.syntax == "ini")
        _parse_ini(self)
    elseif (self.syntax == "http")
        _parse_http(self)
    elseif (self.syntax == "simple")
        _parse_simple(self)
    else
        error("unknown configuration syntax: $(self.syntax)")
    end
end # function parse_conf

############################################################
# _parse_line
# -----------
# Sperates by commas, removes newlines and such
############################################################

function _parse_line(line::String)
    parsed::Array = (String)[]
    splitted::Array = split(line, ",")
    for raw = splitted
        if (ismatch(r"\S+", raw))
            clean = match(r"\S+", raw)
            push!(parsed, clean.match)
        end
    end

    if (length(parsed) == 1)
        return parsed[1]
    end

    parsed
end # function _parse_line

############################################################
# _parse_ini
# ----------
# parses configuration files utilizing ini sytnax.
# Populate the ConfParser.data dictionary
############################################################

function _parse_ini(self::ConfParse)
    local blockname::Any = nothing
    seekstart(self.file_handle)
    
    for line in eachline(self.file_handle)
        local m::Any
        # skip comments and newlines
        if (ismatch(r"^\s*(?:#|$)", line))
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
            key, values = m.captures
            if (blockname != nothing)
                if (!haskey(self.data, blockname))
                    self.data[blockname] = [key => _parse_line(values)]
                else
                    merge!(self.data[blockname], [key => _parse_line(values)])
                end
            else
                self.data[key] = _parse_line(values)
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

function _parse_http(self::ConfParse)
    seekstart(self.file_handle)

    for line in eachline(self.file_handle)
        local m::Any
        # skip comments and newlines
        if (ismatch(r"^\s*(?:#|$)", line))
            continue
        end

        if (!ismatch(r"\w", line))
            continue
        end

        line = chomp(line)
        
        m = match(r"^\s*([\w-]+)\s*:\s*(.*)$", line)
        if (m != nothing)
            key, values = m.captures
            self.data[key] = _parse_line(values)
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

function _parse_simple(self::ConfParse)
    seekstart(self.file_handle)

    for line in eachline(self.file_handle)
        # skip comments and newlines
        if (ismatch(r"^\s*(?:#|$)", line))
            continue
        end

        if (!ismatch(r"\w", line))
            continue
        end

        line = chomp(line)
        
        m = match(r"^\s*([\w-]+)\s+(.*)\s*$", line)
        if (m != nothing)
            key, values = m.captures
            self.data[key] = _parse_line(values)
            continue
        end

        error("invalid syntax on line: $(line)")
    end
end # function _parse_simple

############################################################
# param
# -----
# for retrieving data outside of a block
############################################################

function param(self::ConfParse, key::String)
    return self.data[key]   
end # method param

############################################################
# param
# -----
# for setting new values in a configuration file outside of
# a block
############################################################

function param(self::ConfParse, key::String, new_value::String)

end # method param

############################################################
# param
# -----
# for retrieving data from an ini config file block
############################################################

function param(self::ConfParse, index::Dict{ASCIIString, ASCIIString})
    block::String = index["block"]
    key::String = index["key"]
    return self.data[block][key]
end # method param

############################################################
# param
# -----
# for setting new values in a ini config file block
############################################################

function param(self::ConfParse, index::Dict{ASCIIString, ASCIIString}, new_value::String)

end # method param

end # module ConfParser
