svgW = 900
svgH = 700

d3_default_link_distance = 80
core_distance = 1
internal_distance = 2
external_distance = 50
core_strength = 1
internal_strength = 0.9
external_strength = 0.3

nodesizes =
    'meta': 5,
    'switch': 10

switch_charge = -2300
meta_charge = -1800


switchdata_wrapper = (switchdata) ->
    d3.csv("../data/links.csv", (linkdata) ->
        linkdata_wrapper(switchdata, linkdata))
d3.csv("../data/switches.csv", (d) -> switchdata_wrapper(d))

svg = d3.select("body")
    .append("svg")
    .attr("width", svgW)
    .attr("height", svgH)

linkdata_wrapper = (switchdata, linkdata) ->
    # create index hashes (for quicker find)
    dpid_to_index = {}
    domains = []
    ns = switchdata.length
    nl = linkdata.length
    for s in switchdata
        if domains.indexOf(s['domain']) == -1
            domains.push(s['domain'])
    nd = domains.length
    forceNodes = []

    console.log(switchdata)

    for s, si in switchdata
        dpid_to_index[s.dpid] = si
        forceNodes.push(
            dpid: s['dpid'],
            name: "#{s['domain']} #{s['dpid']}",
            group: domains.indexOf(s['domain']),
            type: 'switch',
            charge: switch_charge
        )

    # add metanodes to improve clustering
    for d, di in domains
        forceNodes.push(
            dpid: "#{d}",
            name: "#{d}",
            group: domains.indexOf(d),
            type: 'meta',
            charge: meta_charge
        )
    console.log('nodes', forceNodes)

    forceLinks = []
    for l, li in linkdata
        src = dpid_to_index[l['f-dpid']]
        tar = dpid_to_index[l['t-dpid']]
        console.log(forceNodes[src], forceNodes[tar])
        samegroup = forceNodes[src].group == forceNodes[tar].group
        forceLinks.push(
            source: src,
            target: tar,
            type: l['notes'],
            length: if samegroup then internal_distance else external_distance,
            strength: if samegroup then internal_strength else external_strength
        )

    # link all nonmeta switches to group heads
    for n, ni in forceNodes[0...ns]
        forceLinks.push(
            source: ni,
            target: n.group+ns,
            type: 'hidden',
            length: core_distance,
            strength: core_strength
        )

    domain_colorscale = d3.scale.category20()



    # start defining force layout stuff
    force = d3.layout.force().size([svgW, svgH])
        .linkDistance((d) -> console.log(d.source.dpid, d.target.dpid, d.source.weight, d.target.weight); d.length)
        #.charge((d) -> d.charge)
        .charge((d) -> d.weight * -500)
        .linkStrength(0.7)
        .friction(0.5)
        .gravity(0.1)

    force.on("tick", (e) ->
        linkSelection.attr("x1", (d) -> d.source.x)
            .attr("y1", (d) -> d.source.y)
            .attr("x2", (d) -> d.target.x)
            .attr("y2", (d) -> d.target.y)
        nodeSelection.attr("cx", (d) -> d.x)
            .attr("cy", (d) -> d.y)
    )


    force.nodes(forceNodes).links(forceLinks)
    linkSelection = svg.selectAll("line").data(forceLinks)
    linkSelection.enter()
        .insert("line")
        .attr("class", (d) -> "link #{d.type}")

    nodeSelection = svg.selectAll("circle.node").data(forceNodes)
    nodeSelection.enter()
        .append("circle")
        .attr("r", (d) -> nodesizes[d.type])
        .attr("class", (d) -> "node #{d.type}")
        .style("fill", (d) -> domain_colorscale(d.group))
        .call(force.drag)
        .append("title")
        .text((d) -> d.name)


    console.log(forceNodes)
    console.log(forceLinks)

    # write up table
    swt = d3.select("body").append("table")
    swth = swt.append("thead")
    swtb = swt.append("tbody")
    swtcols = ['dpid', 'group', 'name', 'type']
    swth.append("tr").selectAll("th").data(swtcols).enter().append("th").text((d)->d)
    swtr = swtb.selectAll("tr").data(forceNodes).enter().append("tr")
    swtc = swtr.selectAll("td")
        .data((r) ->
            swtcols.map((col)->{col: col, value: r[col]}))
        .enter()
        .append("td")
        .text((d) -> d.value)

    lit = d3.select("body").append("table")
    lith = lit.append("thead")
    litb = lit.append("tbody")
    litcols = ['length', 'source', 'target', 'type']
    lith.append("tr").selectAll("th").data(litcols).enter().append("th").text((d)->d)
    litr = litb.selectAll("tr").data(forceLinks).enter().append("tr")
    litc = litr.selectAll("td")
        .data((r) ->
            litcols.map((col)->{col: col, value: r[col]}))
        .enter()
        .append("td")
        .text((d) -> d.value)



    force.start()


