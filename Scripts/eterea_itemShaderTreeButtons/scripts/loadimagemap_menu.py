#python

# loadimagemap_menu
# To load any image map using a button and open dialog
#
# Created an kindly shared by Dongju on Lux forums
# http://forums.luxology.com/topic.aspx?f=119&t=71816
#
# This script calls to "LoadImageMap.py" by Mark Rossi aka Onim
# http://forums.luxology.com/topic.aspx?f=37&t=53003
# It's included too with EtereaUVTools

lx.eval('dialog.setup fileOpen')
lx.eval('dialog.fileType image')
lx.eval('dialog.title {Load Image}')
try:
    lx.eval('dialog.open')
    image = lx.eval('dialog.result ?')
except:
    sys.exit('LXe_ABORT')

lx.eval('@loadImageMap.py Texture "%s"' % image)