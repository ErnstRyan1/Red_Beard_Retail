#python

#This script calls EdgeDivide4.pl by Allan in order to open a user input window
#Created by Cristobal Vila, based on "callCurveSpan.py" (created and shared by Takumi on September 30, 2012)

import lx

lx.eval('user.defNew CallEdgeDivide.N integer momentary')
lx.eval('user.def CallEdgeDivide.N username {Vertices Between}')
lx.eval('user.def CallEdgeDivide.N dialogname {Divide Edge into Segments}')
lx.eval('user.def CallEdgeDivide.N min 1')
lx.eval('user.value CallEdgeDivide.N 1')

try:
    lx.eval('user.value CallEdgeDivide.N')
    n = lx.eval('user.value CallEdgeDivide.N ?')
    lx.eval('@EdgeDivide4.pl %s' % n)

except:
    lx.out('User abort.')