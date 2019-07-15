using Documenter
using ConfParser

makedocs(
    sitename = "ConfParser",
    format = Documenter.HTML(),
    modules = [ConfParser]
)

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
