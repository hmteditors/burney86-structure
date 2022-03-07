#
# Run this dashboard from the root of the
# github repository:
using Pkg
Pkg.activate(joinpath(pwd(), "dashboard"))
Pkg.instantiate()
assets = joinpath(pwd(), "dashboard", "assets")


dataurl = "https://raw.githubusercontent.com/homermultitext/hmt-archive/master/releases-cex/hmt-current.cex"

DASHBOARD_VERSION = "0.2"

using CitableBase, CitableText, CitableObject
using CitablePhysicalText, CitableCorpus
using CitableAnnotations

using Downloads
using PlotlyJS
using Tables
using Dash

"""Compose markdown-formatted title for text catalog entry.
"""
function mdtitle(entry)
    entry.group * ", *" *  entry.work * "* ("  * entry.version * ")"
end

"""Download current HMT release  from `url`."""
function hmtdata(url)
    src = Downloads.download(url) |> read |> String
    cat = fromcex(src, TextCatalogCollection)
    dses = fromcex(src, TextOnPage)
 
    #keylist = 1:24 |> collect .|> string

    countsbybook = []
    titlelist = []
    for dse in dses
        workurn =  dse.data[1][1] |> droppassage |> string
        catentry = filter(e -> string(e.urn) == workurn, cat.entries)[1]
        push!(titlelist, mdtitle(catentry))
        pagecounts = []

        currentbk = ""
        currentpage = ""
        currentcount = 0
        for pr in dse.data
            bk = collapsePassageTo(pr[1], 1) |> passagecomponent
            pg = pr[2] |> objectcomponent
            if bk != currentbk
                if currentcount > 0
                    #pagecounts[currentbk] = currentcount
                    push!(pagecounts, (bk = currentbk, count = currentcount))
                end
                currentbk = bk
                currentpage = pg
                currentcount = 1
            elseif currentpage != pg
                currentcount += 1
            end
        end
        push!(countsbybook, Tables.columntable(pagecounts))
    end
    
    (countsbybook, titlelist)
end

(countsbybook, titles) = hmtdata(dataurl)


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
        if CitableText.isrange(u)
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
    plotlydata = [burney86trace, e4trace]
    plotlylayout = Layout(
        title="Paragraphing in British Library Burney 86 and Escorial Ω 1.12",
        xaxis_title="Book of the Iliad",
        yaxis_title="Line"
        )

    Plot(plotlydata, plotlylayout)
end

function pageindexing(tbls, titles)
    plotlydata = GenericTrace{Dict{Symbol, Any}}[]
    for (i, tbl) in enumerate(tbls)
        tbltrace = bar(x=tbl.bk, y=tbl.count, 
        name=titles[i]
        )
        push!(plotlydata, tbltrace)
    end
    plotlylayout = Layout(
        title="Pages per book of the Iliad",
        xaxis_title="Book of the Iliad",
        yaxis_title="Number of MS pages"
        )

    Plot(plotlydata, plotlylayout)

end

app = dash(assets_folder = assets)

app.layout = html_div() do
    dcc_markdown("*Dashboard version*: **$(DASHBOARD_VERSION)**"),
    html_h1("Progress in Burney 86 analyses"),
    dcc_markdown("""## Indexing paragraph units in *Iliad* text
     
    Mouse over the graph to get tools for panning,
    zooming and selecting parts of the graph.
    """),
    dcc_graph(figure = paragraphs(burney86, e4)),

    dcc_markdown("""## Indexing *Iliad* to MS pages
     
    Mouse over the graph to get tools for panning,
    zooming and selecting parts of the graph.
    """),

    dcc_graph(figure = pageindexing(countsbybook, titles))
end

run_server(app, "0.0.0.0", debug=true)
