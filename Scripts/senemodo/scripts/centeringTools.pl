#perl
#ver 1.03
#author : Seneca Menard

#This script will store a position into space and from then on, you can then center or flatten the elements on a specific axis to that point in space.  Note that the quickMirror script has been modified to pay attention to this stored position when you're mirroring polys.
#script arguments :
# setPos	: This will look at your last selected elem and write it's position to a temporary cvar.												example = "@centeringTools.pl setPos"
# resetPos	: This will reset the temporary cvar back to the world origin, which is (0,0,0)															example = "@centeringTools.pl resetPos"
# center	: This will center your geometry on one axis to the stored position, but you also have to type in the axis you wish to center it on.	example = "@centeringTools.pl x center"
# flatten	: This will flatten your geometry to the stored position, and you also have to type in an axis.											example = "@centeringTools.pl y flatten"

#CHANGELIST : 
#6-10-14 	: 801 broke the user.value so I fixed that.

#remember selType
if( lxq( "select.typeFrom {vertex;polygon;item;edge} ?" ) ) 	{	our $selType = "vert";	}
elsif( lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ) )	{	our $selType = "edge";	}
elsif( lxq( "select.typeFrom {polygon;item;edge;vertex} ?" ) )	{	our $selType = "poly";	}
else{die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

#extra setup
userValueTools(sen_centeringToolsPos,string,temporary,"The fake origin position","","","",xxx,xxx,"","0,0,0");

#script args :
foreach my $arg (@ARGV){
	if		($arg =~ /x/i)			{	our $axis = 0;	our $axisLetter = "X";	}
	elsif	($arg =~ /y/i)			{	our $axis = 1;	our $axisLetter = "Y";	}
	elsif	($arg =~ /z/i)			{	our $axis = 2;	our $axisLetter = "Z";	}
	elsif	($arg =~ /resetPos/i)	{	&resetPos;								}
	elsif	($arg =~ /setPos/i)		{	&setPos;								}
	elsif	($arg =~ /center/i)		{	&center;								}
	elsif	($arg =~ /flatten/i)	{	&flatten;								}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SET POSITION SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub setPos{
	my @elems = lxq("query layerservice ".$selType."s ? selected");
	if (@elems == 0){die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}
	my @pos = lxq("query layerservice $selType.pos ? $elems[-1]");
	my $posString = $pos[0].",".$pos[1].",".$pos[2];
	lx("user.value sen_centeringToolsPos {$posString}");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RESET POSITION SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub resetPos{
	my @posBefore = lxq("user.value sen_centeringToolsPos ?");
	lx("user.value sen_centeringToolsPos {0,0,0}");
	my @posAfter = lxq("user.value sen_centeringToolsPos ?");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CENTER ELEMENTS SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub center{
	my @pos = split (/[,]/, lxq("user.value sen_centeringToolsPos ?"));

	#if the fake origin axis is 0, have modo do the work for us as it's faster
	if ($pos[$axis] == 0){
		lx("vert.center $axis");
	}

	#else we have to do the work to center the geometry
	else{
		our $symmetry = lxq("select.symmetryState ?");
		if 		($symmetry eq "none")	{	$symmetry = 3;	}
		elsif	($symmetry eq "x")		{	$symmetry = 0;	}
		elsif	($symmetry eq "y")		{	$symmetry = 1;	}
		elsif	($symmetry eq "z")		{	$symmetry = 2;	}
		if		($symmetry != 3)		{	lx("select.symmetryState none");	}

		if ($selType ne "vert"){lx("select.convert vertex");}
		my @selectedVerts = lxq("query layerservice verts ? selected");
		my @bbox = boundingbox(@selectedVerts);
		my $bboxAxisCenter = ($bbox[$axis] + $bbox[$axis+3]) * .5;
		my $moveDistance = -1 * ($bboxAxisCenter - $pos[$axis]);
		lx("vert.move delta".$axisLetter.":$moveDistance");

		if		($selType eq "vert")	{	lx("select.type vertex");	}
		elsif	($selType eq "edge")	{	lx("select.type edge");		}
		elsif	($selType eq "poly")	{	lx("select.type polygon");	}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FLATTEN ELEMENTS SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub flatten{
	my $sen_centeringToolsPos = lxq("user.value sen_centeringToolsPos ?");
	if ($sen_centeringToolsPos eq "")	{	our @pos = (0,0,0);									}
	else								{	our @pos = split (/[,]/,$sen_centeringToolsPos);	}
	lx("vert.move pos".$axisLetter.":$pos[$axis]");
}




#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------GENERIC SUBROUTINES------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT   (no popups)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#userValueTools(name,type,life,username,list,listnames,argtype,min,max,action,value);
sub userValueTools{
	if (lxq("query scriptsysservice userValue.isdefined ? @_[0]") == 0){
		lxout("Setting up @_[0]--------------------------");
		lxout("Setting up @_[0]--------------------------");
		lxout("0=@_[0],1=@_[1],2=@_[2],3=@_[3],4=@_[4],5=@_[6],6=@_[6],7=@_[7],8=@_[8],9=@_[9],10=@_[10]");
		lxout("@_[0] didn't exist yet so I'm creating it.");
		lx( "user.defNew name:[@_[0]] type:[@_[1]] life:[@_[2]]");
		if (@_[3] ne "")	{	lxout("running user value setup 3");	lx("user.def [@_[0]] username [@_[3]]");	}
		if (@_[4] ne "")	{	lxout("running user value setup 4");	lx("user.def [@_[0]] list [@_[4]]");		}
		if (@_[5] ne "")	{	lxout("running user value setup 5");	lx("user.def [@_[0]] listnames [@_[5]]");	}
		if (@_[6] ne "")	{	lxout("running user value setup 6");	lx("user.def [@_[0]] argtype [@_[6]]");		}
		if (@_[7] ne "xxx")	{	lxout("running user value setup 7");	lx("user.def [@_[0]] min @_[7]");			}
		if (@_[8] ne "xxx")	{	lxout("running user value setup 8");	lx("user.def [@_[0]] max @_[8]");			}
		if (@_[9] ne "")	{	lxout("running user value setup 9");	lx("user.def [@_[0]] action [@_[9]]");		}
		if (@_[1] eq "string"){
			if (@_[10] eq ""){lxout("woah.  there's no value in the userVal sub!");							}		}
		elsif (@_[10] == ""){lxout("woah.  there's no value in the userVal sub!");									}
								lx("user.value [@_[0]] [@_[10]]");		lxout("running user value setup 10");
	}else{
		#STRING-------------
		if (@_[1] eq "string"){
			if (lxq("user.value @_[0] ?") eq ""){
				lxout("user value @_[0] was a blank string");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#BOOLEAN------------
		elsif (@_[1] eq "boolean"){

		}
		#LIST---------------
		elsif (@_[4] ne ""){
			if (lxq("user.value @_[0] ?") == -1){
				lxout("user value @_[0] was a blank list");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#ALL OTHER TYPES----
		elsif (lxq("user.value @_[0] ?") == ""){
			lxout("user value @_[0] was a blank number");
			lx("user.value [@_[0]] [@_[10]]");
		}
	}
}

#-----------------------------------------------------------------------------------
#BOUNDING BOX subroutine (ver 1.5)
#-----------------------------------------------------------------------------------
sub boundingbox  #minX-Y-Z-then-maxX-Y-Z
{
	lxout("[->] Using boundingbox (math) subroutine");
	my @firstVertPos = lxq("query layerservice vert.pos ? $_[0]");
	my $minX = $firstVertPos[0];
	my $minY = $firstVertPos[1];
	my $minZ = $firstVertPos[2];
	my $maxX = $firstVertPos[0];
	my $maxY = $firstVertPos[1];
	my $maxZ = $firstVertPos[2];
	my @bbVertPos;

	foreach my $bbVert (@_){
		@bbVertPos = lxq("query layerservice vert.pos ? $bbVert");
		if ($bbVertPos[0] < $minX)	{	$minX = $bbVertPos[0];	}
		if ($bbVertPos[0] > $maxX)	{	$maxX = $bbVertPos[0];	}
		if ($bbVertPos[1] < $minY)	{	$minY = $bbVertPos[1];	}
		if ($bbVertPos[1] > $maxY)	{	$maxY = $bbVertPos[1];	}
		if ($bbVertPos[2] < $minZ)	{	$minZ = $bbVertPos[2];	}
		if ($bbVertPos[2] > $maxZ)	{	$maxZ = $bbVertPos[2];	}
	}
	return ($minX,$minY,$minZ,$maxX,$maxY,$maxZ);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
