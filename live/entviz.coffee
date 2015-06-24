svgW = 800
svgH = 600

dataset = [[5, 20], [480, 90], [250, 50], [100, 33], [330, 95],
           [410, 12], [475, 44], [25, 67], [85, 21], [220, 88]
          ]

data_switches = 0
data_links = 0

domain_colorscale = d3.scale.category20()

d3.csv("../data/switches.csv", (d) -> switchdata_wrapper(d))

xscale = d3.scale.linear()
    .domain([0,d3.max(dataset, (d)->d[0])])
    .range([30,svgW-30])

yscale = d3.scale.linear()
    .domain([0,d3.max(dataset, (d)->d[1])])
    .range([svgH-30,30])

xaxis = d3.svg.axis().scale(xscale).orient("bottom").ticks(10)
yaxis = d3.svg.axis().scale(yscale).orient("left")

switchdata_wrapper = (switchdata) ->
    d3.csv("../data/links.csv", (linkdata) -> linkdata_wrapper(switchdata, linkdata))

svg = d3.select("body")
    .append("svg")
    .attr("width", svgW)
    .attr("height", svgH)

linkdata_wrapper = (switchdata, linkdata) ->
    force = d3.layout.force().size([svgW, svgH]).linkDistance(80).charge(-2000).linkStrength(0.8)
        .friction(0.8)

    # create index hashes (for quicker find)
    dpid_to_index = {}
    domains = []
    for s in switchdata
        if domains.indexOf(s['domain']) == -1
            domains.push(s['domain'])
    console.log(domains)
    domain_to_groups = {}
    for domain, i in domains
        console.log(domain,i)
        domain_to_groups[domain] = i

    forceNodes = []
    for s, si in switchdata
        dpid_to_index[s.dpid] = si
        forceNodes[si] =
            name: "#{s['domain']} #{s['dpid']}"
            group: domain_to_groups[s['domain']]

    # find index of source and destination
    forceLinks = []
    for l, li in linkdata
        src = dpid_to_index[l['f-dpid']]
        tar = dpid_to_index[l['t-dpid']]
        forceLinks[li] =
            source: src,
            target: tar,
            type: l['notes']
    console.log(domain_to_groups)
    console.log(forceNodes)
    console.log(forceLinks)

    force.links(forceLinks)
    linkSelection = svg.selectAll("line").data(forceLinks)
    linkSelection.enter()
        .insert("line")
        .attr("class", (d) -> "link #{d.type}")

    force.nodes(forceNodes)
    nodeSelection = svg.selectAll("circle.node").data(forceNodes)
    nodeSelection.enter()
        .append("circle")
        .attr("r", 10)
        .classed("node", true)
        .style("fill", (d) -> domain_colorscale(d.group))
        .call(force.drag)
        .append("title")
        .text((d) -> d.name)

    force.on("tick", (e) ->
        linkSelection.attr("x1", (d) -> d.source.x)
            .attr("y1", (d) -> d.source.y)
            .attr("x2", (d) -> d.target.x)
            .attr("y2", (d) -> d.target.y)
        nodeSelection.attr("cx", (d) -> d.x)
            .attr("cy", (d) -> d.y)
    )


    force.start()


