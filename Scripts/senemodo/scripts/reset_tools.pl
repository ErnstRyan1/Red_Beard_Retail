#perl
#this is to reset all my tool settings.  I use this tool hundreds of times every day.
my $modoVer = lxq("query platformservice appversion ?");

lx("!!tool.set actr.selectauto on");
if (lxq("select.symmetryState ?") ne "none"){	lx("!!select.symmetryState none");	lxout("turning off symmetry");}
lx("!!tool.clearTask falloff");
lx("!!tool.clearTask snap");
lx("!!tool.clearTask constraint");
lx("!!select.vertexMap Subdivision subd replace");

#turn off the scatter
if (lxq("tool.set gen.scatter ?") eq "on"){
	lxout("-Scatter was on and so I'm turning it off");
	lx("!!tool.set gen.scatter off");
}

#turn off snapping if modo ver > 800
if ($modoVer > 800){lx("!!tool.snapState false");}
