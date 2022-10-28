using Pkg
Pkg.activate(".")
using CitableImage
using CitableObject

srcfile = joinpath(pwd(), "paleography-guide", "source.md")
lines = readlines(srcfile)

baseurl = "http://www.homermultitext.org/iipsrv"
root = "/project/homer/pyramidal/deepzoom"
ict = "http://www.homermultitext.org/ict2/?"
service = IIIFservice(baseurl, root)



function tabulate(srclines, ht = 30)
	lines = filter(l -> ! isempty(l), srclines)
    tbllines = [
        "| Image | Transcription | Notes |",
        "| --- | --- | --- |"
    ]
    for ln in lines[2:end]
        cols = split(ln, "|")
        if isempty(cols[2])
            push!(tbllines, "|  |  | $(cols[4]) |")
        else
            img = Cite2Urn(cols[2])
            mdImage = linkedMarkdownImage(ict,img, service; ht = ht)
            push!(tbllines, "| $(mdImage) | $(cols[3]) | $(cols[4]) |")
        end
    end
    join(tbllines, "\n")
end


function writefile(imght = 40)

    pagelines = []
    tablelines = []
    intable = false
    for ln in lines
        if startswith(ln, "```paleography")
            intable = true
        elseif intable && startswith(ln, "```")
            push!(pagelines, tabulate(tablelines, imght))
            intable = false
            tablelines = []
        else
            intable ? push!(tablelines, ln) : push!(pagelines, ln)
        end
    end
    open(joinpath(pwd(), "paleography-guide.md"), "w") do io
        write(io, join(pagelines,"\n"))
    end
end

writefile(40)