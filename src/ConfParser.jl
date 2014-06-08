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
    _file_handle::IO
    _file_name::ASCIIString
    _syntax::ASCIIString
    _data::Dict
    _is_modified::Bool

    ############################################################
    # ConfParse
    # ---------
    # constructor for ConfParse type.  Sets file_name,
    # file_handle, and syntax fields
    ############################################################

    function ConfParse(file_name::ASCIIString, syntax::ASCIIString = "")
        self = new()
        if (isempty(file_name))
            error("no file name specified")
        end

        self._file_name = file_name

        if (isempty(syntax))
            self._file_handle = _open_fh(file_name, "r")
            self._syntax = _guess_syntax(self._file_handle)
        else
            if ((syntax != "ini")  &&
                (syntax != "http") &&
                (syntax != "simple"))
                error("unknown configuration syntax: $(syntax)")
            end
            self._syntax = syntax
        end

        self._data        = Dict()
        self._is_modified = false
        return self
    end # function ConfParse

end # type ConfigParser

############################################################
# _open_fh
# --------
# open file handler for IO
############################################################

function _open_fh(file_name::ASCIIString, mode::ASCIIString)
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

function parse_conf!(self::ConfParse)
    if (self._syntax == "ini")
        _parse_ini(self)
    elseif (self._syntax == "http")
        _parse_http(self)
    elseif (self._syntax == "simple")
        _parse_simple(self)
    else
        error("unknown configuration syntax: $(self._syntax)")
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

function _parse_ini(self::ConfParse)
    local blockname::ASCIIString = "default"
    seekstart(self._file_handle)

    for line in eachline(self._file_handle)
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
            if (!haskey(self._data, blockname))
                self._data[blockname] = [key => _parse_line(values)]
            else
                merge!(self._data[blockname], [key => _parse_line(values)])
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
    seekstart(self._file_handle)

    for line in eachline(self._file_handle)
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
            self._data[key] = _parse_line(values)
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
    seekstart(self._file_handle)

    for line in eachline(self._file_handle)
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
            self._data[key] = _parse_line(values)
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

function _craft_content(self::ConfParse)
   local content::ASCIIString = ""

   if (self._syntax == "ini")
        for (block, key_values) = self._data
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

    elseif (self._syntax == "http")
        for (key, values) = self._data
            if (typeof(values) == Array{String, 1})
                content *= "$key: $(join(values, ","))\n"
            else
                content *= "$key: $values\n"
            end
        end

    elseif (self._syntax == "simple")
        for (key, values) = self._data
            if (typeof(values) == Array{String, 1})
                content *= "$key $(join(values, ","))\n"
            else
                content *= "$key $values\n"
            end
        end

    else
        error("unknown syntax type: $(self._syntax)")
    end

    content
end # function _craft_content

############################################################
# erase!
# ------
# remove entry from inside ini block
############################################################

function erase!(self::ConfParse, block::ASCIIString, key::ASCIIString)
    local block_key = getkey(self._data, block, nothing)
    if (block_key != nothing)
        if (haskey(self._data[block_key], key))
            delete!(self._data[block_key], key)
        end
    end

    self._is_modified = true
end # method erase!

############################################################
# erase!
# ------
# remove entry from config (outside of block if ini)
############################################################

function erase!(self::ConfParse, key::ASCIIString)
    if (haskey(self._data, key))
        delete!(self._data, key)
    end

    self._is_modified = true
end # method erase!

############################################################
# save
# -----
# for writing out new or modified configuration files
############################################################

function save!(self::ConfParse, file_name::Any = nothing)
    # if data has not been modified and a new file has not
    # been specified, don't write out
    if (self._is_modified == false) && (file_name == nothing)
        return
    end

    # if there is no content to write out, don't create an
    # empty file
    content = _craft_content(self)
    if (content == nothing)
        return
    end

    if (file_name == nothing)
        self._file_handle = _open_fh(self._file_name, "w")
    else
        self._file_handle = _open_fh(file_name, "w")
    end

    write(self._file_handle, content)
end # function save

############################################################
# retrieve
# -----
# for retrieving data outside of a block
############################################################

function retrieve(self::ConfParse, key::ASCIIString)
    if (length(self._data[key]) == 1)
        return self._data[key][1]
    end

    self._data[key]
end # method retrieve

############################################################
# retrieve
# -----
# for retrieving data from an ini config file block
############################################################

function retrieve(self::ConfParse, block::ASCIIString, key::ASCIIString)

    if (length(self._data[block][key]) == 1)
        return self._data[block][key][1]
    end

    self._data[block][key]
end # method retrieve

############################################################
# commit!
# -----
# for inserting data in a config file
############################################################

function commit!(self::ConfParse, key::ASCIIString, value::Any)
    self._data[key]   = value
    self._is_modified = true
end # method commit!

############################################################
# commit!
# -----
# for inserting data inside an ini file block
############################################################

function commit!(self::ConfParse, block::ASCIIString, key::ASCIIString, values::ASCIIString)
    if (self._syntax != "ini")
        error("invalid setter method called for syntax type: $(self._syntax)")
    end

    self._data[block][key] = [values]
    self._is_modified      = true
end # method commit!

end # module ConfParser
