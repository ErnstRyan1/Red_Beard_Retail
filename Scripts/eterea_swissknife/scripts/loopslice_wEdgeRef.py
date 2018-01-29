#python
#loopslice_wEdgeRef.py by ylaz dec 2013
#loop slice using reference edge for distance
#select edge/s to slice first, then the ref edge last. run script
#hide or lock any geo to remian unsliced
	
def slice():
	client = sum(lx.eval('query layerservice edge.length ? %s' % edge)
                  	 for edge in lx.evalN('query layerservice edges ? selected'))
	lx.out('client',client)
	length = 100-((ref/client)*100)
	percent = (100-length)/100
	lx.out('percent',percent)
	lx.eval('tool.set poly.loopSlice on')
	lx.eval('tool.reset')
	lx.eval('tool.attr poly.loopSlice mode symmetry')
	lx.eval('tool.attr poly.loopSlice count 2')
	lx.eval('tool.attr poly.loopSlice pos %s' % percent)
	lx.eval('tool.doApply')
	lx.eval('tool.set poly.loopSlice off')
	lx.eval('select.drop edge')

lx.eval('select.editSet all add')
lx.eval('select.less')	
lx.eval('select.editSet clients add')
lx.eval('select.useSet all select')
lx.eval('select.deleteSet all')
lx.eval('select.useSet clients deselect')
ref = sum(lx.eval('query layerservice edge.length ? %s' % edge)
                   for edge in lx.evalN('query layerservice edges ? selected'))
lx.out('ref',ref)
lx.eval('select.drop edge')
lx.eval('select.useSet clients select')
lx.eval('select.deleteSet clients')
edges = lx.eval('query layerservice edges ? selected')
edgecount = lx.eval('query layerservice edge.N ? selected')
layer = lx.eval('query layerservice layer.index ? main')
lx.out('edges',edges)
lx.out('edgecount',edgecount)
#lx.eval('select.drop edge')

if edgecount == 1:
	slice()
elif edgecount > 1:
	lx.eval('select.drop edge')
	# --------this iterater is provided by ShaunAbsher. awesome !---------------------------------
	for edge in edges:
 		indicies = edge[1:-1]
 		indicies = indicies.split(',')
 		lx.eval('select.element %s edge set index:%s index2:%s' % (layer,indicies[0], indicies[1]))
 		# ----------------------------------------------------------------------------------------
		lx.eval('select.editSet edge%s add' % str(edge))
		lx.eval('select.drop edge')
	for e in edges:
		lx.eval('select.useSet edge%s select' % str(e))
		lx.eval('select.deleteSet edge%s' % str(e))
		slice()
lx.out('ver 1.0 dec 2013')










