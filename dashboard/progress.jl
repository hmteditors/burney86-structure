# urn:cite2:hmt:datamodels.v1:textonpage
#TextOnPage
#const TEXT_ON_PAGE_MODEL = Cite2Urn("urn:cite2:hmt:datamodels.v1:textonpage")

url = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"
src = Downloads.download(url) |> read |> String
dses = fromcex(src, TextOnPage)
# peek at dse[n].data[1][1] to get text catalog data
cat = fromcex(src, TextCatalogCollection)


matches = filter(cat.entries) do e
    urn(e) == CtsUrn("urn:cts:greekLit:tlg0012.tlg001.msB:")
end

function titling(entry)
    entry.group * ", *" *  entry.work * "* ("  * entry.version * ")"
end


#
#
# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "dashboard"))
Pkg.instantiate()
assets = joinpath(pwd(), "dashboard", "assets")

DASHBOARD_VERSION = "0.1"

using CitableBase, CitableText, CitableObject
using CitableCorpus
using CitableAnnotations
using Downloads
using PlotlyJS
using Dash
using Tables

burneyfile = joinpath(pwd(), "tables", "paragraphs-burney86.cex")
e4file = joinpath(pwd(), "tables", "paragraphs-e4.cex")

"Create a named tuple of integers for book and line."
function bookline(s::AbstractString)
    try
        (bk,ln) = split(s, ".")
        (book = parse(Int64, bk), line = parse(Int64,ln))
    catch 
        throw(ArgumentError("Failed to parse string $(s)"))
    end
end

"Read file `f` and create a data table of book, line pairs."
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

"Plot progress in recording paragraph openings."
function paragraphs(burney, escorial)
    burney86trace = scatter(x=burney.book, y=burney.line, mode="markers", 
    name="Burney 86",
    marker=attr(
        color="Dodger",
        size=10,
        opacity=0.5,
        line=attr(
            color="Navy",
            width=2
        )

    ))
    
    
    
    e4trace = scatter(x=escorial.book, y=escorial.line, mode="markers", 
    name="Ω 1.12",
    marker=attr(
        color="Orange",
        size="6",
        opacity=0.5,
        symbol="circle-dot",
        line=attr(
            color="DarkOrange",
            width=2
        )
    ))
    
    #burney86trace["marker"] = Dict(:size => 14,
    #:symbol => "circle-dot")

    #e4trace["marker"] = Dict(:size => 8)
    

    plotlydata = [burney86trace, e4trace]

    plotlylayout = Layout(
        title="Paragraphing in British Library Burney 86 and Escorial Ω 1.12",
        xaxis_title="Book of the Iliad",
        yaxis_title="Line"
        )


    Plot(plotlydata, plotlylayout)
end


app = dash(assets_folder = assets)

app.layout = html_div() do
    dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)**"),
    html_h1("Progress in Burney 86 analyses"),
    dcc_markdown("""Mouse over the graph to get tools for panning,
    zooming and selecting parts of the graph.
    """),
    dcc_graph(figure = paragraphs(burney86, e4))
end

run_server(app, "0.0.0.0", debug=true)
