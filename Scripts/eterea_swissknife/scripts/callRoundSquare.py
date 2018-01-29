#python

#This script calls roundSquare.pl by Ariel Chai in order to open a user input window
#Created by Cristobal Vila, based on "callCurveSpan.py" (created and shared by Takumi on September 30, 2012)

import lx

lx.eval('user.defNew CallRoundSquare.N integer momentary')
lx.eval('user.def CallRoundSquare.N username {Round Level (min: 1)}')
lx.eval('user.def CallRoundSquare.N dialogname {Round Two Collateral Edges}')
lx.eval('user.def CallRoundSquare.N min 1')
lx.eval('user.value CallRoundSquare.N 2')

try:
    lx.eval('user.value CallRoundSquare.N')
    n = lx.eval('user.value CallRoundSquare.N ?')
    lx.eval('@roundSquare.pl %s' % n)

except:
    lx.out('User abort.')