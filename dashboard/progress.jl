# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "dashboard"))
Pkg.instantiate()
assets = joinpath(pwd(), "dashboard", "assets")

DASHBOARD_VERSION = "0.1"

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


function progressgraph(burney, escorial)
    burney86trace = scatter(x=burney.book, y=burney.line, mode="markers", 
    name="Burney 86",
    marker=attr(
        color="rgba(135, 206, 250, 0.5)",
        size=10,
        line=attr(
            color="MediumPurple",
            width=2
        )

    ))
    
    
    
    e4trace = scatter(x=escorial.book, y=escorial.line, mode="markers", 
    name="Ω 1.12",
    marker=attr(
        size="6"
    ))
    
    #burney86trace["marker"] = Dict(:size => 14,
    #:symbol => "circle-dot")

    #e4trace["marker"] = Dict(:size => 8)
    

    plotlydata = [burney86trace, e4trace]

    plotlylayout = Layout(;title="Paragraphing in British Library Burney 86 and Escorial Ω 1.12")


    Plot(plotlydata, plotlylayout)
end


app = dash(assets_folder = assets)

app.layout = html_div() do
    dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)**"),

    html_h1("Progress in Burney 86 analyses"),
    dcc_graph(figure = progressgraph(burney86, e4))
end

run_server(app, "0.0.0.0", debug=true)
