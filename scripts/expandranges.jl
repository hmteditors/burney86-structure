using Pkg

# Run this from root of repo, or reset 
# `root` to point to that directory.
root  = pwd()
scriptdir = joinpath(root, "scripts")
Pkg.activate(scriptdir)

using CitableText
f = joinpath(root, "tables", "iliad-index-burney86.cex")
datalines = readlines(f)[3:end]
data = filter(ln -> !isempty(ln), datalines)

expanded = []
for ln in data
    (folio, startline, stopline) = split(ln, "|")
    psg =  CtsUrn(startline) |> passagecomponent
    bk = replace(psg, r"\..+" => "")
    baseurn = CtsUrn(startline) |> droppassage
    startint = parse(Int64, (replace(startline, r"[^\.]+\." => ""))) 
    stopint = parse(Int64, (replace(stopline, r"[^\.]+\." => ""))) 
    
    # Iliad/page
    for i in startint:stopint
        psgref = join([bk, string(i)], ".")
        urnvalue = addpassage(baseurn, psgref)
        push!(expanded, join([string(urnvalue), folio], "|"))
    end
end

outfile = joinpath(scriptdir, "expandeddata.cex")

open(outfile,"w") do io
    write(io, join(expanded, "\n"))
end
