#perl
#AUTHOR: Seneca Menard
#version 1.92
#This script goes through your model and cleans it up for you.  :)
#
#-It removes 0 poly points
#-It removes 1pt + 2pt polygons
#-It removes those mysterious 3pt/4edge polygons that look like 2pt polygons (and 1 edge verts)
#-It also does a fixed 1 um vert merge, poly unify, and poly align to remove DUPLICATE geometry (if you accidentally pasted an object twice, for ex.)
#-It now unhides everything when it's doing the POLY.UNIFY, because of modo's bug where it will sometimes delete the hidden geometry.
#-It now unifies subDs as well. (like if you accidentally hit TAB on a hal hidden model, and now only half of it is in subDs....)
#-It now merges colinear edges.  You can overwrite the angle check if you want.  Just append a number to the end of the script. (0.99 for only merging straight lines, 0.1 for merging lines up to about 90 degree)
#-(1-14-06) MODO2 FIX: I'm now canceling modo's warning windows!  Plus I added options now, so if you don't like some part of this script, you can remove it by appending
# a word to the script.  For example: @meshcleanup.pl vertMerge
#-(12-15-06 m2 bugfix) : in modo2, a feature changed that made my illegal poly deletion technique not work.  That's now fixed again.
#-(7-29-07 m3 fix) : in m3, they make it so you have to specify whether or not you want to do a force unify with the poly unify tool.
#-(10-3-07 fix) : I added a section to remove the "senetemp" selection set from all the polys.  It's just a safety check to make sure none exist.
#(3-25-11 fix) : 501 sp2 had an annoying syntax change.  grrr.
#(12-22-11 fix) : it now unifies catmull clark psubs as well.
#(7-12-13 fix) : put in a colinear vert check fix and am now printing what data i can on what errors were found.

#Here's the wordlist:
# "vertMerge"			: This is to turn off vert merging
# "polyUnify"			: This is to turn off poly unifying
# "noForceUnify"		: This is if poly unifying is on, but you don't want to "force unify" (m3 feature)
# "zeroPolyPoints"		: This is to stop the deletion of (0poly pts) and (1edge verts).
# "oneAndTwoPointPolys"	: This is to stop the deletion of (1pt polys) and (2pt polys).
# "threeEdgePolygons"	: This is to stop the deletion of (3edge Polys)
# "colinearVerts"		: This is to stop the deletion of colinear verts.
# "unifySubDs"			: This is to stop the unifying of your subDs.
# -any number typed in-	: This is to set the dotProduct for the colinearVert Removal as mentioned above....

my $modoVer = lxq("query platformservice appversion ?");
my $modoBuild = lxq("query platformservice appbuild ?");
if ($modoBuild > 41320){our $selectPolygonArg = "psubdiv";}else{our $selectPolygonArg = "curve";}
my $selected;
my $sel_type;
my $counter1;
my $counter2;

#------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#------------------------------------------------------------------------------------
if ($#ARGV > -1)  #DPVALUE SAFETY CHECK. (if there's no args, then it doesn't know to set the dpValue to 0.985
{
	foreach my $arg (@ARGV)
	{
		if ($arg =~ /vertMerge/i)			{	our $vertMerge = 1;									}
		if ($arg =~ /polyUnify/i)			{	our $polyUnify = 1;									}
		if ($arg =~ /zeroPolyPoints/i)		{	our $zeroPolyPoints = 1;							}
		if ($arg =~ /oneAndTwoPointPolys/i)	{	our $oneAndTwoPointPolys = 1;						}
		if ($arg =~ /threeEdgePolygons/i)	{	our $threeEdgePolygons = 1;							}
		if ($arg =~ /colinearVerts/i)		{	our $colinearVerts = 1;								}
		if ($arg =~ /unifySubDs/i)			{	our $unifySubDs = 1;								}
		if ($arg =~ /noForceUnify/i)		{	our $noForceUnify =1 ;								}
		if ($arg =~ m/\d/)					{	our $dpValue = $arg;	}else{our $dpValue = 0.985;	}
	}
}
else
{
	our $dpValue = 0.985;
}



#------------------------------------------------------------------------------------
#THIS WILL KEEP YOUR SELECTION SETTINGS
#------------------------------------------------------------------------------------
if		( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ) 	{	$sel_type = "vertex";	}
elsif	( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )	{	$sel_type = "edge";		}
elsif	( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )	{	$sel_type = "polygon";	}


#------------------------------------------------------------------------------------
#DESELECT EVERYTHING
#------------------------------------------------------------------------------------
lxout("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ");
lxout("Running the mesh cleanup script:");
lx( "select.drop vertex" );
lx( "select.drop edge" );
lx( "select.drop polygon" );


#------------------------------------------------------------------------------------
#TEMPORARILY UNHIDE EVERYTHING TO PROTECT YOUR MODEL FROM THE POLY.UNIFY BUG
#------------------------------------------------------------------------------------
lx("!!select.editSet supertempBLAH add");
lx("unhide");


#------------------------------------------------------------------------------------
#GET RID OF THE SENETEMP SELECTION SET.
#------------------------------------------------------------------------------------
lx("!!select.drop polygon");
lx("!!select.useSet senetemp select");
lx("!!select.editSet senetemp remove");
lx("!!select.drop polygon");


#------------------------------------------------------------------------------------
#VERT MERGE
#------------------------------------------------------------------------------------
$counter1 = lxq("query layerservice vert.n ? all");

if ($vertMerge != 1){
	lx("!!vert.merge auto [0] [1 um]");
}else{
	lxout(">>SKIPPING vert merging");
}

$counter2 = lxq("query layerservice vert.n ? all");
$diff = $counter1 - $counter2;
if ($diff > 0){lxout("-       ($diff) verts removed with VERT MERGE");}


#------------------------------------------------------------------------------------
#POLY UNIFY
#------------------------------------------------------------------------------------
$counter1 = lxq("query layerservice poly.n ? all");

if ($polyUnify != 1){
	if ($modoVer > 300){
		if ($noForceUnify == 1){
			lx("!!poly.unify [False]");
		}else{
			lx("!!poly.unify [True]");
		}
	}else{
		lx("!!poly.unify");
	}
	lx( "select.drop polygon" );
}else{
	lxout(">>SKIPPING poly unifying");
}

$counter2 = lxq("query layerservice poly.n ? all");
$diff = $counter1 - $counter2;
if ($counter1-$counter2 > 0){lxout("-       ($diff) polys removed with POLY UNIFY");}


#------------------------------------------------------------------------------------
#SELECT AND DELETE 0 POLY POINTS (and 1 edge vertices)
#------------------------------------------------------------------------------------
$counter1 = $counter2;

if ($zeroPolyPoints != 1){
	lx("!!select.vertex add poly equal 0");
	lx("!!select.vertex add edge equal 1");
	$selected = lxq("select.count vertex ?");
	if ($selected != "0"){
		lxout("-        I deleted ($selected+1) 0 poly points and/or 1 edge vertices");
		lx("delete");
	}
}
else{
	lxout(">>SKIPPING deleting 0poly points (and 1edge verts)");
}

$counter2 = lxq("query layerservice poly.n ? all");
$diff = $counter1 - $counter2;
if ($counter1-$counter2 > 0){lxout("-       ($diff) 0 poly points and/or 1 edge vertices removed");}


#------------------------------------------------------------------------------------
#DELETE 2PT and 1PT POLYGONS
#------------------------------------------------------------------------------------
$counter1 = $counter2;

if ($oneAndTwoPointPolys != 1){
	lx("!!select.polygon add vertex {$selectPolygonArg} 2");
	lx("!!select.polygon add vertex {$selectPolygonArg} 1");
	$selected = lxq("select.count polygon ?");
	if ($selected != "0"){
		lxout("-        I deleted ($selected+1) 2pt and/or 1pt polygons");
		lx("delete");
	}
}
else{
	lxout(">>SKIPPING deleting 1pt+2pt polys");
}

$counter2 = lxq("query layerservice poly.n ? all");
$diff = $counter1 - $counter2;
if ($counter1-$counter2 > 0){lxout("-       ($diff) 2PT and/or 1PT polys deleted");}


#------------------------------------------------------------------------------------
#SELECT 3+ EDGE POLYGONS AND DELETE 'EM
#------------------------------------------------------------------------------------
$counter1 = $counter2;

if ($threeEdgePolygons != 1){
	lx("!!select.edge add poly more 2");
	lx("!!select.convert vertex");
	lx("!!select.convert polygon");
	$selected = lxq("select.count polygon ?");
	if ($selected != "0"){
		lx("delete");
	}
}
else{
	lxout(">>SKIPPING deleting 3+ edge polys");
}

$counter2 = lxq("query layerservice poly.n ? all");
$diff = $counter1 - $counter2;
if ($counter1-$counter2 > 0){lxout("-       ($diff) 3+ edge polys deleted");}


#------------------------------------------------------------------------------------
#FIND THE COLINEAR EDGE VERTS AND REMOVE 'EM
#------------------------------------------------------------------------------------
if ($colinearVerts != 1)
{
	lx("select.drop vertex");
	lx("!!select.vertex add edge equal 2");
	$selected = lxq("select.count vertex ?");
	if ($selected != "0"){
		my $mainLayer = lxq("query layerservice layers ? main");
		my @twoEdgeVerts =  lxq("query layerservice verts ? selected");
		$dpValue *= -1; #straight line instead of facing themselves.
		
		foreach my $currentVert (@twoEdgeVerts){
			my @connectedVerts = lxq("query layerservice vert.vertList ? $currentVert");
			my @pos = lxq("query layerservice vert.pos ? $currentVert");
			my @posA = lxq("query layerservice vert.pos ? $connectedVerts[0]");
			my @posB = lxq("query layerservice vert.pos ? $connectedVerts[1]");
			my @disp1 = unitVector(arrMath(@posA,@pos,subt));
			my @disp2 = unitVector(arrMath(@posB,@pos,subt));
			my $dotProduct = ($disp1[0]*$disp2[0])+($disp1[1]*$disp2[1])+($disp1[2]*$disp2[2]);
			
			if ($dotProduct > $dpValue){
				lx("select.element [$mainLayer] vertex remove [$currentVert]");
			}
		}

		$selected = lxq("select.count vertex ?");
		my @selVerts = lxq("query layerservice verts ? selected");
		if ($selected != "0"){
			lxout("-       ($selected) colinear edge verts removed");
			#return;
			lx("remove");
		}
	}
}
else{
	lxout(">>SKIPPING removing colinear verts");
}


#------------------------------------------------------------------------------------
#THIS WILL POLY ALIGN
#------------------------------------------------------------------------------------
lx("!!poly.align");


#------------------------------------------------------------------------------------
#UNIFY THE SUBDS.
#------------------------------------------------------------------------------------
if ($unifySubDs != 1){
	lx("!!select.polygon add type subdiv 1");
	lx("!!select.connect");
	lx("!!select.polygon remove type subdiv 1");
	if (lxq("select.count polygon ?")){
		lxout("-        I unified the subDs");
		lx("poly.convert face subpatch [1]");
	}
	else{
		lxout("-       There are no subDs to unify");
	}
}
else{
	lxout(">>SKIPPING subD unifying");
}

if ($unifyCatmull != 1){
	lx("!!select.polygon add type psubdiv 2");
	lx("!!select.connect");
	lx("!!select.polygon remove type psubdiv 2");
	if (lxq("select.count polygon ?")){
		lxout("-        I unified the subDs");
		lx("poly.convert face psubdiv true");
	}
	else{
		lxout("-       There are no subDs to unify");
	}
}



#------------------------------------------------------------------------------------
#HIDE EVERYTHING AGAIN NOW THAT THE MODEL'S BEEN CLEANED UP.
#------------------------------------------------------------------------------------
lx("!!select.useSet supertempBLAH select");
lx("!!hide.unsel");
lx("!!select.editSet supertempBLAH remove");
lx("select.drop polygon");
lx("select.type $sel_type");
if ($dpValue != 0.985)	{lxout("-       The DOTPRODUCT was set to this : ($dpValue)");}
lxout("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ");



#------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------
#SUBROUTINES
#------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------
sub displacement{
	my ($vert1,$vert2) = @_;
	my @vertPos1 = lxq("query layerservice vert.pos ? $vert1");
	my @vertPos2 = lxq("query layerservice vert.pos ? $vert2");

	my $disp0 = @vertPos1[0] - @vertPos2[0];
	my $disp1 = @vertPos1[1] - @vertPos2[1];
	my $disp2 = @vertPos1[2] - @vertPos2[2];

	my @disp = ($disp0,$disp1,$disp2);

	#normalize the disp
	my $dist = sqrt(($disp0*$disp0)+($disp1*$disp1)+($disp2*$disp2));
	@disp[0,1,2] = ((@disp[0]/$dist),(@disp[1]/$dist),(@disp[2]/$dist));
	return @disp;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PERFORM MATH FROM ONE ARRAY TO ANOTHER subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @disp = arrMath(@pos2,@pos1,subt);
sub arrMath{
	my @array1 = (@_[0],@_[1],@_[2]);
	my @array2 = (@_[3],@_[4],@_[5]);
	my $math = @_[6];

	my @newArray;
	if		($math eq "add")	{	@newArray = (@array1[0]+@array2[0],@array1[1]+@array2[1],@array1[2]+@array2[2]);	}
	elsif	($math eq "subt")	{	@newArray = (@array1[0]-@array2[0],@array1[1]-@array2[1],@array1[2]-@array2[2]);	}
	elsif	($math eq "mult")	{	@newArray = (@array1[0]*@array2[0],@array1[1]*@array2[1],@array1[2]*@array2[2]);	}
	elsif	($math eq "div")	{	@newArray = (@array1[0]/@array2[0],@array1[1]/@array2[1],@array1[2]/@array2[2]);	}
	return @newArray;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#UNIT VECTOR SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @unitVector = unitVector(@vector);
sub unitVector{
	my $dist1 = sqrt((@_[0]*@_[0])+(@_[1]*@_[1])+(@_[2]*@_[2]));
	@_ = ((@_[0]/$dist1),(@_[1]/$dist1),(@_[2]/$dist1));
	return @_;
}

sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}