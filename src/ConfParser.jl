module ConfParser

export

# types
ConfParse,

# functions
parse_conf!,
get_field

# contains information of the configuration file such as
# file name, syntax, and the file handler for IO ops
type ConfParse
    file_handle::IO
    file_name::String
    syntax::String
    data::Dict

    function ConfParse(file_name::String, syntax::String = "")
        self = new()
        if (isempty(file_name))
            error("no file name specified")
        end

        self.file_name = file_name
        try
            self.file_handle = open(file_name, "r")
        catch
            error("configuration file could not be opened")
        end

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
    end

end # type ConfigParser

# guess_syntax
# ------------
# attempts to guess the configuration file syntax using
# regular expressions

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


# parse_conf!
# -----------
# tasks appropriate parser method based on configuration
# syntax

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


# _parse_ini
# ----------
# parses configuration files utilizing ini sytnax.
# Populate the ConfParser.data dictionary

function _parse_ini(self::ConfParse)
    local blockname::String
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

        # parse key/values
        m = match(r"^\s*([^=]*\w)\s*=\s*(.*)\s*$", line)
        if (m != nothing)
            key, values = m.captures
            if (haskey(self.data, blockname))
                push!(self.data[blockname], [key => split(values, ",")])
            else
                self.data[blockname] = [[key => split(values, ",")]]
            end

            continue
        end
        error("invalid syntax on line: $(line)")
    end
end # function _parse_ini

# _parse_http
# -----------
# parses configuration files utilizing http sytnax.
# Populate the ConfParser.data dictionary

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
            self.data[key] = split(values, ",")
            continue
        end

        error("invalid syntax on line: $(line)")
    end
end # function _parse_http

# _parse_simple
# -------------
# parses configuration files utilizing simple syntax.
# Populates the ConfParser.data dictionary

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
            self.data[key] = split(values, ",")
            continue
        end

        error("invalid syntax on line: $(line)")
    end
end # function _parse_simple

# get_field
# -------------
# returns field based on parameters

function get_field(self::ConfParse, key::String = "", block::String = "")
    
    # for non-ini syntaxes
    if (isempty(block))
        if (isempty(key))
            return self.data
        end
        return self.data[key]
    end

    # for ini syntax
    if (isempty(key))
        return self.data[block]
    end
    
    return self.data[block][key]
end # function get_param

end # module ConfParser
