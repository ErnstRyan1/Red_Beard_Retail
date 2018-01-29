#perl
#This script is used with my custom knife tool.  If geometry snap is on, I'll turn that and the tool off and perform meshcleanup.

my $modoBuild = lxq("query platformservice appbuild ?");
if ($modoBuild > 41320){our $selectPolygonArg = "psubdiv";}else{our $selectPolygonArg = "curve";}

if (lxq("tool.set snap.element ?") eq "on"){
	lxout("snap is on");
	lx("tool.set snap.element off");
	lx("tool.set seneKnife off");
	&meshCleanup;
}

else{
	lxout("snap is off");
	lx("tool.set seneKnife off");
}




sub meshCleanup{
	#VERT MERGE
	lx("!!vert.merge auto [0] [1 um]");  #lx("vert.merge fixed dist:[1 um]");  (!!MODO2!!)

	#SELECT AND DELETE 0 POLY POINTS (and 1 edge vertices)
	lx("select.drop vertex");
	lx("!!select.vertex add poly equal 0"); #CORRECT way to select o poly points
	lx("!!select.vertex add edge equal 1");
	$selected = lxq("select.count vertex ?");
	lxout("selected=$selected");
	if ($selected != "0")
	{
		lxout("-        I deleted ($selected+1) 0 poly points and/or 1 edge vertices");
		lx("delete");
	}

	#DELETE 2PT and 1PT POLYGONS
	lx("select.drop polygon");
	lx("!!select.polygon add vertex {$selectPolygonArg} 2");
	lx("!!select.polygon add vertex {$selectPolygonArg} 1");
	$selected = lxq("select.count polygon ?");
	if ($selected != "0")
	{
		lxout("-        I deleted ($selected+1) 2pt and/or 1pt polygons");
		lx("delete");
	}

	#SELECT 3+ EDGE POLYGONS AND DELETE 'EM
	lx("!!select.edge add poly more 2");
	lx("!!select.convert vertex");
	lx("!!select.convert polygon");
	$selected = lxq("select.count polygon ?");
	if ($selected != "0")
	{
		lxout("-        I deleted ($selected+1) 3+ edge polygons");
		lx("delete");
	}
}

