using Documenter
using Anneal

# Set up to run docstrings with jldoctest
DocMeta.setdocmeta!(
    Anneal, :DocTestSetup, :(using Anneal); recursive=true
)

makedocs(;
    modules=[Anneal],
    doctest=true,
    clean=true,
    format=Documenter.HTML(
        assets = ["assets/extra_styles.css"], #, "assets/favicon.ico"],
        mathengine=Documenter.KaTeX(),
        sidebar_sitename=false,
    ), 
    sitename="Anneal.jl",
    authors="Pedro Xavier and Tiago Andrade and Joaquim Garcia and David Bernal",
    pages=[
        "Home"     => "index.md",
        "Manual"   => "manual.md",
        "Examples" => "examples.md",
    ],
    workdir="."
)

deploydocs(
    repo=raw"github.com/psrenergy/Anneal.jl.git",
    push_preview = true
)