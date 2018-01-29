#perl
#BY: Seneca Menard
#version 1.4 (modo2)
#This is a script to replace the COPY tool.  If you use it on polys, it's just like normal.  If you use it on edges, it
#will take each edge, make a 2pt polygon, and then CUT them.  So just hit paste and you'll paste all your 2pt polys you just made.
#(new feature 8-11-05) This script now brings up a warning window when you're copying edges or verts.  There were a number of times where I was trying to
#copy the entire mesh, but didn't realize I was in edge mode or vert mode, and so it took a long time and didn't copy what i wanted anyways.  So now there's a warning.   :)
#(8-21-06 bugfix) : in M202, the edge.polyList query syntax changed a bit and needs the () marks now so I put them back in.


my $mainLayer = lxq("query layerservice layers ? main");

#-------------------------------------------------------------------------------------------------------------------
#if you're in EDGE mode and have some selected, it'll convert the edges to 2pt polygons and then cut 'em.
#-------------------------------------------------------------------------------------------------------------------
if( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )
{
	lxout("EDGE MODE!");
	popup("Did you really wanna copy EDGES?");
	my @subdivPolyList;
	my @polyListFinal;
	my $subDcheck;


	#if no edges are selected, select all.
	if (lxq ("select.count edge ? ") lt 1)
	{
		lxout("You have no edges selected");
		lx("select.invert edge");
	}

	#drop the polygon selection
	lx("select.drop polygon");

	#CREATE the edge list.
	my @origEdgeList = lxq("query layerservice edges ? selected");



	#check to see if edges are connected to subD polygons and fix that.
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	foreach my $edge (@origEdgeList)
	{
		my @polyList = lxq("query layerservice edge.polyList ? $edge");
		#lxout("This edge $edge : : poly list = @polyList");
		push(@polyListFinal, @polyList);
	}
	#lxout("poly list final = @polyListFinal");
	#lxout("poly list final [0] = @polyListFinal[0]");


	foreach my $poly (@polyListFinal)
	{
		my $type = lxq("query layerservice poly.type ? $poly");
		#lxout("poly $poly 's type is this: $type");
		if ($type eq "subdiv"){	$subDcheck =1;	}
	}


	#now select those subD polygons and turn 'em into non subD.
	if ($subDcheck == 1)
	{
		lxout("Converting the subD polygons");

		foreach my $polygon (@polyListFinal)
		{
			lx("select.element [$mainLayer] polygon add index:[$polygon]");
		}
		lx("select.connect");
		lx("poly.convert face subpatch [1]");
		lx("select.drop polygon");
	}
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


	#EDIT the original edge list. [remove ( ) ]
	tr/()//d for @origEdgeList;
	#lxout("origEdgeList = @origEdgeList");

	#go thru each selected edge and convert it to a polygon
	foreach my $edge (@origEdgeList)
	{
		my @edgeVerts =  split (/[^0-9]/, $edge);
		#lxout("edgeVerts1 =  @edgeVerts[0]  edgeVerts2 = @edgeVerts[1]");

		lx("!!select.drop vertex");
		lx("!!select.element [$mainLayer] vertex add index:[@edgeVerts[0]]");
		lx("!!select.element [$mainLayer] vertex add index:[@edgeVerts[1]]");
		lx("!!poly.make face");
	}
	lx("select.type polygon");
	lx("!!select.cut");


	#put the subDs back
	if ($subDcheck == 1)
	{
		lxout("Converting the subD polygons");

		foreach my $polygon (@polyListFinal)
		{
			lx("select.element [$mainLayer] polygon add index:[$polygon]");
		}
		lx("select.connect");
		lx("poly.convert face subpatch [1]");
		lx("select.drop polygon");
	}
}


#-------------------------------------------------------------------------------------------------------------------
#if you're in POLY  mode, do the regular COPY
#-------------------------------------------------------------------------------------------------------------------
elsif( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )
{
	lxout("POLY MODE!");
	lx("select.copy");
}



#-------------------------------------------------------------------------------------------------------------------
#if you're in VERT  mode, do the regular COPY
#-------------------------------------------------------------------------------------------------------------------
elsif( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )
{
	lxout("VERT MODE!");
	popup("Did you really wanna copy VERTS?");
	lx("select.copy");
}




sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}