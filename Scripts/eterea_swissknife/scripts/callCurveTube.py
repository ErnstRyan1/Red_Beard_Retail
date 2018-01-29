#python

#This script calls curveTube.pl by Dion Burgoyne in order to open user input dialogs
#Created by Cristobal Vila, based on "callCurveSpan.py" (created and shared by Takumi on September 30, 2012)
#Thanks also to GwynneR for the help with final "lx.eval" line and "float momentary" type ;-)


import lx

lx.eval('user.defNew CallCurveTube.A integer momentary')
lx.eval('user.def CallCurveTube.A username {Sides}')
lx.eval('user.def CallCurveTube.A dialogname {How many section sides?}')
lx.eval('user.def CallCurveTube.A min 1')
lx.eval('user.value CallCurveTube.A 8')

lx.eval('user.defNew CallCurveTube.B integer momentary')
lx.eval('user.def CallCurveTube.B username {Segments}')
lx.eval('user.def CallCurveTube.B dialogname {How many segments between every two spline nodes?}')
lx.eval('user.def CallCurveTube.B min 1')
lx.eval('user.value CallCurveTube.B 3')

lx.eval('user.defNew CallCurveTube.C float momentary')
lx.eval('user.def CallCurveTube.C username {Radius (in meters)}')
lx.eval('user.def CallCurveTube.C dialogname {And finally, your desired radius?}')
lx.eval('user.def CallCurveTube.C min 0.0001')
lx.eval('user.value CallCurveTube.C 0.1')

try:
    lx.eval('user.value CallCurveTube.A')
    a = lx.eval('user.value CallCurveTube.A ?')
    lx.eval('user.value CallCurveTube.B')
    b = lx.eval('user.value CallCurveTube.B ?')
    lx.eval('user.value CallCurveTube.C')
    c = lx.eval('user.value CallCurveTube.C ?')
      
    lx.eval('@curveTube.pl "%s" "%s" "%s"' % (a, b, c))

except:
    lx.out('User abort.')