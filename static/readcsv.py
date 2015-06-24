import csv
switch_to_site = {}
with open('../data/switches.csv', 'rb') as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    next(reader, None)
    for row in reader:
        switch_to_site[int(row[1],16)] = row[0]


sites = set(switch_to_site.values())
local_links = {site: [] for site in sites}

links_header = ['f-domain', 'f-dpid', 'f-port', 't-domain', 't-dpid', 't-port', 'Note']
nonlocal_links = []
links = []
with open('../data/links.csv', 'rb') as csvfile:
    reader = csv.reader(csvfile, delimiter=',')
    links = [row for row in reader]

nonlocal_links = [row for row in links if row[0]!=row[3]]
for link in links:
    if link[0]==link[3]:
        local_links[link[0]].append(link)

print 'digraph {'
for site in local_links:
    print '    subgraph %s {' % (site)
    for link in local_links[site]:
        print '        %s-%s -> %s-%s;' % (link[0], link[1], link[3], link[4])
    print '    }'
#print ';'.join(nonlocal_links)
print '}'
