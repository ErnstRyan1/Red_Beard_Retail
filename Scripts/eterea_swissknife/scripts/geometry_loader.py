#python

# geometry_loader.py by Synide / Cristobal Vila
#
# Hack script to query and apply ABSOLUTE paths, since this regular command:
# preset.do {kit_eterea_swissknife:scripts/geometry/guides.lxl}
#     ...doesn't works (?)
#
# Thanks for help offered by Synide on this topic:
#     http://community.thefoundry.co.uk/discussion/topic.aspx?f=37&t=54872
#
# Example of use: @geometry_loader.py guides

mygeom = lx.arg()

mypath = lx.eval("query platformservice alias ? {kit_eterea_swissknife:scripts/geometry}")

lx.eval("preset.do {%s/%s.lxl}" % (mypath, mygeom))