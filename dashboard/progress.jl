# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "dashboard"))
Pkg.instantiate()

using CitableText
using PlotlyJS
using Dash
using Tables

burneyfile = joinpath(pwd(), "tables", "paragraphs-burney86.cex")
e4file = joinpath(pwd(), "tables", "paragraphs-e4.cex")


function bookline(s::AbstractString)
    try
        (bk,ln) = split(s, ".")
        (book = parse(Int64, bk), line = parse(Int64,ln))
    catch 
        throw(ArgumentError("Failed to parse string $(s)"))
    end
end

function datafy(f)
    dataurns = readlines(f)[3:end] .|> CtsUrn
    datapairs = []
    for u in dataurns
        if isrange(u)
            push!(datapairs, range_end(u) |> bookline)
        end
    end
    datapairs  |> Tables.columntable
end

burney86 = datafy(burneyfile)
e4 = datafy(e4file)