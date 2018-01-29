#perl
#BY: Seneca Menard
#version 1.0
# This script is for selecting or deselecting edges based off of the angle between the two polys connected to it.  The descriptive image on the website describes it best.
# IMPORTANT NOTE : I tried putting the included form into a pie menu and it would work, but when I'd run the script, it would act up and then crash modo.  So you should NOT put the
# form in a pie menu.  I currently put the form in a little onscreen menu and that works without problems..  I guess I've gotta bug report this to Luxology....

my $mainlayer = lxq("query layerservice layers ? main");
my $pi=3.1415926535897932384626433832795;

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#USER VARIABLES
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#create the sene_edgeSelAngle variable if it didn't already exist.
if (lxq("query scriptsysservice userValue.isdefined ? sene_edgeSelAngle") == 0)
{
	lxout("-The sene_edgeSelAngle cvar didn't exist so I just created one");
	lx( "user.defNew sene_edgeSelAngle integer");
	lx("user.value sene_edgeSelAngle 80");
}
#create the sene_edgeSelSimAngle variable if it didn't already exist.
if (lxq("query scriptsysservice userValue.isdefined ? sene_edgeSelSimAngle") == 0)
{
	lxout("-The sene_edgeSelSimAngle cvar didn't exist so I just created one");
	lx( "user.defNew sene_edgeSelSimAngle integer");
	lx("user.value sene_edgeSelSimAngle 5");
}


#set the user variables.
my $sene_edgeSelAngle = lxq("user.value sene_edgeSelAngle ?");
$sene_edgeSelAngle = $sene_edgeSelAngle*($pi/180);	#convert angle to radian.
$sene_edgeSelAngle = cos($sene_edgeSelAngle);		#convert radian to DP.

my $sene_edgeSelSimAngle = lxq("user.value sene_edgeSelSimAngle ?");
$sene_edgeSelSimAngle = $sene_edgeSelSimAngle*($pi/180);	#convert angle to radian.
$sene_edgeSelSimAngle = cos($sene_edgeSelSimAngle);		#convert radian to DP.
$sene_edgeSelSimAngle = abs($sene_edgeSelSimAngle - 1);	#make the radian be inverse.

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#ARGS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if		($arg eq "greater")		{	our $dir = "greater";		}
	if		($arg eq "deselect")	{	&deselect;					}
	elsif	($arg eq "select")		{	&select;					}
	elsif	($arg eq "similar")		{	our $similar = 1;			}
	elsif	($arg eq "selectRow")	{	&selectRow;					}
	elsif	($arg eq "angleDlg")	{	$sene_edgeSelAngle = quickDialog("edge selection cutoffangle",float,15,.001,170);	$sene_edgeSelAngle = $sene_edgeSelAngle*($pi/180); $sene_edgeSelAngle = cos($sene_edgeSelAngle);	}
	elsif	($arg =~ /[0-9]/)		{	$sene_edgeSelAngle = $arg;	$sene_edgeSelAngle = $sene_edgeSelAngle*($pi/180); $sene_edgeSelAngle = cos($sene_edgeSelAngle);	}
}

lxout("sene_edgeSelAngle = $sene_edgeSelAngle");

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DESELECT EDGES sub
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub deselect{
	my @deselectEdges;
	my @edges;

	if ($similar == 1){
		my @edges = lxq("query layerservice selection ? edge");
		my $lastEdge = @edges[-1];
		$lastEdge =~ s/\(\d{0,},/\(/;
		my @polys = lxq("query layerservice edge.polyList ? $lastEdge");
		my @normal1 = lxq("query layerservice poly.normal ? @polys[0]");
		my @normal2 = lxq("query layerservice poly.normal ? @polys[1]");
		our $similarDP = (@normal1[0]*@normal2[0]+@normal1[1]*@normal2[1]+@normal1[2]*@normal2[2]);
		lxout("[DESELECT SIMILAR] similar edge=@currentEdges[-1] <> dp=$similarDP");
	}

	if( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){
		lx("select.convert edge");
		@edges = lxq("query layerservice edges ? selected");
		lx("select.drop edge");
	}else{
		@edges = lxq("query layerservice edges ? selected");
	}

	foreach my $edge (@edges){
		my @polys = lxq("query layerservice edge.polyList ? $edge");
		my @normal1 = lxq("query layerservice poly.normal ? @polys[0]");
		my @normal2 = lxq("query layerservice poly.normal ? @polys[1]");
		my $dotProduct = (@normal1[0]*@normal2[0]+@normal1[1]*@normal2[1]+@normal1[2]*@normal2[2]);

		if ($similar == 1){
			if (($dotProduct > $similarDP-$sene_edgeSelSimAngle)&&($dotProduct < $similarDP+$sene_edgeSelSimAngle)){
				my @verts = split (/[^0-9]/, $edge);
				lx("select.element [$mainlayer] edge remove index:[@verts[1]] index2:[@verts[2]]");
			}
		}elsif ($dir eq "greater"){
			if ($sene_edgeSelAngle > $dotProduct){
				my @verts = split (/[^0-9]/, $edge);
				lx("select.element [$mainlayer] edge remove index:[@verts[1]] index2:[@verts[2]]");
			}
		}else{
			if ($sene_edgeSelAngle < $dotProduct){
				my @verts = split (/[^0-9]/, $edge);
				lx("select.element [$mainlayer] edge remove index:[@verts[1]] index2:[@verts[2]]");
			}
		}
	}
}




#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SELECT EDGES sub
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub select{
	my @edges;

	if ($similar == 1){
		my @edges = lxq("query layerservice selection ? edge");
		my $lastEdge = @edges[-1];
		$lastEdge =~ s/\(\d{0,},/\(/;
		my @polys = lxq("query layerservice edge.polyList ? $lastEdge");
		my @normal1 = lxq("query layerservice poly.normal ? @polys[0]");
		my @normal2 = lxq("query layerservice poly.normal ? @polys[1]");
		our $similarDP = (@normal1[0]*@normal2[0]+@normal1[1]*@normal2[1]+@normal1[2]*@normal2[2]);
		lxout("[SELECT SIMILAR] similar edge=@currentEdges[-1] <> dp=$similarDP");
	}

	if( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){
		lx("select.convert edge");
		@edges = lxq("query layerservice edges ? selected");
		lx("select.drop edge");
	}else{
		@edges = lxq("query layerservice edges ? visible");
	}

	foreach my $edge (@edges){
		my @polys = lxq("query layerservice edge.polyList ? $edge");
		my @normal1 = lxq("query layerservice poly.normal ? @polys[0]");
		my @normal2 = lxq("query layerservice poly.normal ? @polys[1]");
		my $dotProduct = (@normal1[0]*@normal2[0]+@normal1[1]*@normal2[1]+@normal1[2]*@normal2[2]);

		if (@polys != 1){
			if ($similar == 1){
				if (($dotProduct > $similarDP-$sene_edgeSelSimAngle)&&($dotProduct < $similarDP+$sene_edgeSelSimAngle)){
					my @verts = split (/[^0-9]/, $edge);
					lx("select.element [$mainlayer] edge add index:[@verts[1]] index2:[@verts[2]]");
				}
			}elsif ($dir eq "greater"){
				if ($sene_edgeSelAngle > $dotProduct){
					my @verts = split (/[^0-9]/, $edge);
					lx("select.element [$mainlayer] edge add index:[@verts[1]] index2:[@verts[2]]");
				}
			}else{
				if ($sene_edgeSelAngle < $dotProduct){
					my @verts = split (/[^0-9]/, $edge);
					lx("select.element [$mainlayer] edge add index:[@verts[1]] index2:[@verts[2]]");
				}
			}
		}
	}
}



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SELECT EDGE ROW SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub selectRow{
	my %ignoreEdges;
	my @keepEdges;
	my @currentEdges;
	my @tempEdgeList = lxq("query layerservice selection ? edge");
	foreach my $edge (@tempEdgeList){	if ($edge =~ /\($mainlayer/){push(@currentEdges,$edge);}	}
	s/\(\d{0,},/\(/  for @currentEdges;
	my %polyNormalTable;

	if ($similar == 1){
		my @polys = lxq("query layerservice edge.polyList ? @currentEdges[-1]");
		my @normal1 = lxq("query layerservice poly.normal ? @polys[0]");
		my @normal2 = lxq("query layerservice poly.normal ? @polys[1]");
		our $similarDP = (@normal1[0]*@normal2[0]+@normal1[1]*@normal2[1]+@normal1[2]*@normal2[2]);
		lxout("[SELECT SIMILAR] similar edge=@currentEdges[-1] <> dp=$similarDP <> user.value=$sene_edgeSelSimAngle");
	}

	#build the list of passed connected edges
	while (@currentEdges > 0){
		my $edge = shift(@currentEdges);
		my @edge = split (/[^0-9]/, $edge);
		correctEdgeName(@edge);

		#find all connected verts
		my @connectedVerts1 = lxq("query layerservice vert.vertList ? @edge[0]");
		my @connectedVerts2 = lxq("query layerservice vert.vertList ? @edge[1]");

		#build the list of this round's current edges to check. (and correct the edge names)
		my @currentRoundEdges = @edge[0].",".@edge[1];
		foreach my $vert (@connectedVerts1){
			if (@edge[0]>$vert)	{ push(@currentRoundEdges,@edge[0].",".$vert); }
			else				{ push(@currentRoundEdges,$vert.",".@edge[0]); }
		}
		foreach my $vert (@connectedVerts2){
			if (@edge[1]>$vert)	{ push(@currentRoundEdges,@edge[1].",".$vert); }
			else				{ push(@currentRoundEdges,$vert.",".@edge[1]); }
		}

		#go through this round's current edges and keep the edges that meet the angle requirement
		foreach my $edge(@currentRoundEdges){
			if ($ignoreEdges{$edge} == 1){next;}
			my @polys = lxq("query layerservice edge.polyList ? ($edge)");
			my @normal1;
			my @normal2;

			if (@polys > 1){
				if (!exists $polyNormalTable{@polys[0]})	{	@normal1 = lxq("query layerservice poly.normal ? @polys[0]");	$polyNormalTable{@polys[0]} = \@normal1;}
				else									{	@normal1 = @{$polyNormalTable{@polys[0]}};															}
				if (!exists $polyNormalTable{@polys[1]})	{	@normal2 = lxq("query layerservice poly.normal ? @polys[1]");	$polyNormalTable{@polys[1]} = \@normal2;}
				else									{	@normal2 = @{$polyNormalTable{@polys[1]}};															}
				my $dotProduct = (@normal1[0]*@normal2[0]+@normal1[1]*@normal2[1]+@normal1[2]*@normal2[2]);
				if ($similar == 1)			{	if (($dotProduct > $similarDP-$sene_edgeSelSimAngle)&&($dotProduct < $similarDP+$sene_edgeSelSimAngle))	{	push(@keepEdges,$edge);	push(@currentEdges,$edge);	}}
				elsif ($dir eq "greater")	{	if ($sene_edgeSelAngle > $dotProduct)				{	push(@keepEdges,$edge);	push(@currentEdges,$edge);	}}
				else					{	if ($sene_edgeSelAngle < $dotProduct)				{	push(@keepEdges,$edge);	push(@currentEdges,$edge);	}}
			}
			$ignoreEdges{$edge} = 1;
		}
	}

	foreach my $edge (@keepEdges){
		my @verts = split(/,/, $edge);
		lx("select.element $mainlayer edge add @verts[0] @verts[1]");
	}
}





#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																SUBROUTINES																		====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {@_[0]}");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 0){
			lxout("-The seneTempDialog cvar didn't exist so I just created one");
			lx("user.defNew name:[seneTempDialog] life:[temporary]");
		}
		lx("user.def seneTempDialog username [@_[0]]");
		lx("user.def seneTempDialog type [@_[1]]");
		if ((@_[3] != "") && (@_[4] != "")){
			lx("user.def seneTempDialog min [@_[3]]");
			lx("user.def seneTempDialog max [@_[4]]");
		}
		lx("user.value seneTempDialog [@_[2]]");
		lx("user.value seneTempDialog ?");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CORRECT THE EDGE'S NAME SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub correctEdgeName{
	if (@_[0]<@_[1])	{	return @_;			}
	else			{	return (@_[1],@_[0]);	}
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









