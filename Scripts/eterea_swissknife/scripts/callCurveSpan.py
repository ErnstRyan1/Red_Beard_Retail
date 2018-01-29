#python

#This script calls curveSpan.pl by Dion Burgoyne in order to open a user input window
#Kindly created and shared by Takumi on September 30, 2012

import lx

lx.eval('user.defNew CallCurveSpan.N integer momentary')
lx.eval('user.def CallCurveSpan.N username {Steps Between Curves}')
lx.eval('user.def CallCurveSpan.N dialogname {Blend Curves}')
lx.eval('user.def CallCurveSpan.N min 2')
lx.eval('user.value CallCurveSpan.N 2')

try:
    lx.eval('user.value CallCurveSpan.N')
    n = lx.eval('user.value CallCurveSpan.N ?')
    lx.eval('@curveSpan.pl %s' % n)

except:
    lx.out('User abort.')