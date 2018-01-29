#perl
#Tube to Chain and Back
#AUTHOR: Seneca Menard
#version 1.03

#This script is for taking your current polygon selection and assumes it's pipes, and deletes the current geometry after rebuilding the pipes again from scratch.  Basically, it's to kinda pretend as if we had live extrusion entity types in modo, so now you can tweak a pipe with whatever tool and you don't have to worry about it's deformations because you can delete those by running this script to rebuild it.
#NOTE : this script is only for pipe with open ends.  if your pipes don't have open ends, this script skips those.

#(12-18-08 fix) : I went and removed the square brackets so that the numbers will always be read as metric units and also because my prior safety check would leave the unit system set to metric system if the script was canceled because changing that preference doesn't get undone if a script is cancelled.
#(1-30-09 fix) : removed a meaningless popup that would occur the first time you run the script.
#(6-22-10 feature) : The script was rewritten.  It's now for taking your currently selected polygon pipes and rebuilding them so as to remove any deformations or whatnot.
#(6-29-10 feature) : The script keeps the poly parts now.
#(9-10-10 feature) : The script now reselects the pipes for you.
#(12-29-10 fix) : forced caps to be off unless "leaveCapsAlone" cvar is on.

#SCRIPT CVARS :
# leaveCapsAlone : This cvar is to have the tube tool retain it's current "caps" setting.  if you don't use this cvar, i force turn them off because our pipes need them off in 99% of cases and i'm tired of turning that option off.



#----------------------------------------------------------------------------------------------
#USER VALUES
#----------------------------------------------------------------------------------------------
userValueTools(senePipeSmooth,string,temporary,senePipeSmooth,"","","",xxx,xxx,"",null);

#----------------------------------------------------------------------------------------------
#CVARS
#----------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if ($arg =~ /leaveCapsAlone/i)	{	our $leaveCapsAlone = 1;	}
}

#----------------------------------------------------------------------------------------------
#SAFETY CHECKS
#----------------------------------------------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");

#CONVERT THE SYMM AXIS TO MY OLDSCHOOL NUMBER AND TURN IT OFF
our $symmAxis = lxq("select.symmetryState ?");
if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
elsif	($symmAxis eq "x")		{	$symmAxis = 0;	}
elsif	($symmAxis eq "y")		{	$symmAxis = 1;	}
elsif	($symmAxis eq "z")		{	$symmAxis = 2;	}
if		($symmAxis != 3)		{	lx("select.symmetryState none");	}

#Remember what the workplane was and turn it off
my @WPmem;
@WPmem[0] = lxq ("workPlane.edit cenX:? ");
@WPmem[1] = lxq ("workPlane.edit cenY:? ");
@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
@WPmem[3] = lxq ("workPlane.edit rotX:? ");
@WPmem[4] = lxq ("workPlane.edit rotY:? ");
@WPmem[5] = lxq ("workPlane.edit rotZ:? ");
lx("workPlane.reset ");

#set the main layer to be "reference" to get the true vert positions.
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my $layerReference = lxq("layer.setReference ?");
lx("!!layer.setReference $mainlayerID");





#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------
#OLD ALGORITHM : that converts a tube to an edge chain and an edge chain to a tube
#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------

#----------------------------------------------------------------------------------------------
#EDGE MODE
#----------------------------------------------------------------------------------------------
if ($oldSchoolWay == 1){
	if ( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) == 1){
		lxout("[->] Building a 2pt poly chain from the selected edge loops");

		lx("select.ring");
		lx("select.loop");
		if (lxq("select.count edge ?") < 3){	die("There's not enough edges selected to run the script");	}
		my $sides;
		my $material;
		my $thickness;
		my @chainPositions;
		my @edges = lxq("query layerservice selection ? edge");
		sortRowStartup(@edges);

		#get the properties of the tube
		foreach my $vertRow (@vertRowList){
			my @verts = split (/[^0-9]/, $vertRow);
			if (@verts[-1] == @verts[0]){pop(@verts);}
			if ($sides == ""){
				$sides = @verts;
				my @polys = lxq("query layerservice vert.polyList ? @verts[0]");
				my @tags = lxq("query layerservice poly.tags ? @polys[0]");
				$material = @tags[0];
			}

			my @avgPos = (0,0,0);
			foreach my $vert (@verts){
				@avgPos = arrMath(lxq("query layerservice vert.pos ? $vert"),@avgPos,add);
			}
			my @pos = arrMath(@avgPos,$#verts+1,$#verts+1,$#verts+1,div);
			push(@chainPositions,@pos);

			#get thickness
			if ($thickness == ""){
				foreach my $vert (@verts){
					my @vertPos = lxq("query layerservice vert.pos ? $vert");
					my @disp = arrMath(@pos,@vertPos,subt);
					my $dist = sqrt((@disp[0]*@disp[0])+(@disp[1]*@disp[1])+(@disp[2]*@disp[2]));
					$thickness += $dist;
				}
				$thickness = $thickness/@verts;
			}
		}

		#delete the tube
		lx("select.connect");
		lx("delete");

		#recreate the tube as a 2pt poly chain.
		my $vertCount = lxq("query layerservice vert.n ? all");
		lx("select.drop polygon");
		lx("select.type vertex");
		lx("vert.new {@chainPositions[0]} {@chainPositions[1]} {@chainPositions[2]}");
		for (my $i=3; $i<@chainPositions; $i=$i+3){
			my @vertPos = (@chainPositions[$i],@chainPositions[$i+1],@chainPositions[$i+2]);
			my $secondVert = $vertCount+1;
			lx("vert.new {@vertPos[0]} {@vertPos[1]} {@vertPos[2]}");
			lx("select.element $mainlayer vertex set $vertCount");
			lx("select.element $mainlayer vertex add $secondVert");
			lx("poly.makeFace");
			$vertCount++;
		}

		#set the user.value
		lx("user.value senePipeSmooth [$sides,$material,$thickness]");

		#turn the smooth tool on
		lx("select.type polygon");
		lx("tool.set xfrm.smooth on");
		lx("tool.reset");
	}



	#----------------------------------------------------------------------------------------------
	#POLY MODE
	#----------------------------------------------------------------------------------------------
	elsif ( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) == 1){
		lxout("[->] Rebuilding the tube");

		lx("select.convert edge");
		lx("select.connect");
		my @edges = lxq("query layerservice edges ? selected");
		sortRowStartup(edgesSelected,@edges);

		my @values = split(/,/, lxq("user.value senePipeSmooth ?"));

		lx("tool.set prim.tube on");
		lx("tool.attr prim.tube sides {@values[0]}");
		lx("tool.attr prim.tube segments {1}");
		lx("tool.attr prim.tube radius {@values[2]}");
		if ($leaveCapsAlone != 1){lx("tool.attr prim.tube caps false");}

		foreach my $vertRow (@vertRowList){
			my @verts = split (/[^0-9]/, $vertRow);
			for (my $i=0; $i<@verts; $i++){
				my @pos = lxq("query layerservice vert.pos ? @verts[$i]");
				my $u=$i+1;
				lx("tool.setAttr prim.tube number $u");
				lx("tool.setAttr prim.tube ptX {@pos[0]}");
				lx("tool.setAttr prim.tube ptY {@pos[1]}");
				lx("tool.setAttr prim.tube ptZ {@pos[2]}");
			}
		}
		lx("tool.doApply");
		lx("tool.set prim.tube off");

		lx("select.type polygon");
		lx("delete");
		my $polyCount = lxq("query layerservice poly.n ? all");
		lx("select.element $mainlayer polygon set [$polyCount-2]");
		lx("select.connect");
		lx("poly.setMaterial @values[1]");
	}

	#----------------------------------------------------------------------------------------------
	#SCRIPT CANCEL
	#----------------------------------------------------------------------------------------------
	else{	die("You're not in edge mode (which says you want to create a 2pt poly chain from the selection\nYou're not in poly mode (which says you wish to rebuild the tube)\nSo I'm cancelling the script.");}
}

#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------
#NEW ALGORITHM : that takes polygroups and re-pipes each one.
#----------------------------------------------------------------------------------------------
#----------------------------------------------------------------------------------------------
else{
	my @polys = lxq("query layerservice polys ? selected");
	my %polyTable; $polyTable{$_} = 1 for @polys;
	my @polysToDelete;

	while ((keys %polyTable) > 0){
		my $thickness;
		my $sides;
		my $material;
		my $part;
		my @chainPositions;
		my $poly = (keys %polyTable)[0];

		#make edge selection
		lx("select.drop edge");
		lx("select.drop polygon");
		lx("select.element {$mainlayer} polygon set {$poly}");
		lx("select.connect");
		lx("select.boundary");
		lx("select.loop");
		lx("select.ring");

		#find edge rows
		my @connectedPolys = lxq("query layerservice polys ? selected");
		my @edges = lxq("query layerservice edges ? selected");
		delete $polyTable{$_} for @connectedPolys;

		if (@edges < 1){
			lxout("This poly set doesn't have any open edges, so I can't run the script on it! \n@connectedPolys");
			next;
		}else{
			push(@polysToDelete,@connectedPolys);
		}
		sortRowStartup(edgesSelected,@edges);

		#go thru each edge loop and find each center and thickness
		foreach my $vertRow (@vertRowList){
			my @verts = split (/[^0-9]/, $vertRow);
			if (@verts[-1] == @verts[0]){pop(@verts);}
			if ($sides == ""){
				$sides = @verts;
				my @polys = lxq("query layerservice vert.polyList ? $verts[0]");
				my @tags = lxq("query layerservice poly.tags ? $polys[0]");
				$material = $tags[0];
				$part = lxq("query layerservice poly.part ? $polys[0]");
			}

			my @avgPos = (0,0,0);
			foreach my $vert (@verts){
				@avgPos = arrMath(lxq("query layerservice vert.pos ? $vert"),@avgPos,add);
			}
			my @pos = arrMath(@avgPos,$#verts+1,$#verts+1,$#verts+1,div);
			push(@chainPositions,@pos);

			#get thickness
			if ($thickness == ""){
				foreach my $vert (@verts){
					my @vertPos = lxq("query layerservice vert.pos ? $vert");
					my @disp = arrMath(@pos,@vertPos,subt);
					my $dist = sqrt((@disp[0]*@disp[0])+(@disp[1]*@disp[1])+(@disp[2]*@disp[2]));
					$thickness += $dist;
				}
				$thickness = $thickness/@verts;
			}
		}

		#now find the REAL order of the pipe.
		my $borderVert;
		my $secondVert;
		foreach my $vertRow (@vertRowList){
			my @verts = split (/[^0-9]/, $vertRow);
			my $edge = "(".$verts[0].",".$verts[1].")";
			my @edgePolys = lxq("query layerservice edge.polyList ? $edge");
			if (@edgePolys == 1){
				$borderVert = $verts[0];
				last;
			}
		}

		my @vertList = lxq("query layerservice vert.vertList ? $borderVert");
		for (my $i=0; $i<@vertList; $i++){
			my $edge = "(".$borderVert.",".$vertList[$i].")";
			if (lxq("query layerservice edge.numPolys ? $edge") != 1){
				$secondVert = $vertList[$i];
				last;
			}
		}

		lx("select.drop vertex");
		lx("select.element $mainlayer vertex add $borderVert");
		lx("select.element $mainlayer vertex add $secondVert");
		lx("select.loop");
		my @sortedVertRow = lxq("query layerservice verts ? selected");
		my @cp;
		my %foundRows = ();

		for (my $i=0; $i<@sortedVertRow; $i++){
			for (my $j=0; $j<@vertRowList; $j++){
				if ($foundRows{$j} == 1){next;}
				my @verts = split (/[^0-9]/, $vertRowList[$j]);
				for (my $k=0; $k<@verts; $k++){
					if ($sortedVertRow[$i] == $verts[$k]){
						$cp[$i] = $j;
						$j = @vertRowList; #last;
						$k = @verts;
						$foundRows{$j} = 1;
					}
				}
			}
		}

		#build new pipe
		my $count = 1;
		lx("tool.set prim.tube on");
		lx("tool.attr prim.tube sides {$sides}");
		lx("tool.attr prim.tube segments {1}");
		lx("tool.attr prim.tube radius {$thickness}");
		if ($leaveCapsAlone != 1){lx("tool.attr prim.tube caps false");}
		for (my $i=0; $i<@cp; $i++){
			my @tubeNodePos = (@chainPositions[$cp[$i]*3],@chainPositions[($cp[$i]*3)+1],@chainPositions[($cp[$i]*3)+2]);
			lx("tool.setAttr prim.tube number $count");
			lx("tool.setAttr prim.tube ptX {$tubeNodePos[0]}");
			lx("tool.setAttr prim.tube ptY {$tubeNodePos[1]}");
			lx("tool.setAttr prim.tube ptZ {$tubeNodePos[2]}");
			$count++;
		}
		lx("tool.doApply");
		lx("tool.set prim.tube off");


		#apply material and part and selSet
		my $polyCount = lxq("query layerservice poly.n ? all") - 1;
		lx("select.drop polygon");
		lx("select.element $mainlayer polygon set {$polyCount}");
		lx("select.connect");
		lx("poly.setMaterial {$material}");
		lx("poly.setPart {$part}");
		lx("select.editSet {seneTubeRebuilder} add");
	}

	#now delete all the old polys
	lx("select.drop polygon");
	lx("select.element $mainlayer polygon add $_") for @polysToDelete;
	if (@polysToDelete > 0){lx("delete");}

	#now reselect the tubes
	lx("select.useSet {seneTubeRebuilder} select");
	lx("select.editSet {seneTubeRebuilder} remove {}");
}



















#----------------------------------------------------------------------------------------------
#CLEANUP
#----------------------------------------------------------------------------------------------
#Set Symmetry back
if ($symmAxis != 3)
{
	#CONVERT MY OLDSCHOOL SYMM AXIS TO MODO's NEWSCHOOL NAME
	if 		($symmAxis == "3")	{	$symmAxis = "none";	}
	elsif	($symmAxis == "0")	{	$symmAxis = "x";		}
	elsif	($symmAxis == "1")	{	$symmAxis = "y";		}
	elsif	($symmAxis == "2")	{	$symmAxis = "z";		}
	lxout("turning symm back on ($symmAxis)"); lx("!!select.symmetryState $symmAxis");
}

#Set the layer reference back
lx("!!layer.setReference [$layerReference]");

#Put workplane back
lx("workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");









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
#SORT ROWS SETUP subroutine  (0 and -1 are dupes if it's a loop)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#requires SORTROW sub
#sortRowStartup(dontFormat,@edges);			#NO FORMAT
#sortRowStartup(edgesSelected,@edges);		#EDGES SELECTED
#sortRowStartup(@edges);					#SELECTION ? EDGE

sub sortRowStartup{

	#------------------------------------------------------------
	#Import the edge list and format it.
	#------------------------------------------------------------
	my @origEdgeList = @_;
	my $edgeQueryMode = shift(@origEdgeList);
	#------------------------------------------------------------
	#(NO) formatting
	#------------------------------------------------------------
	if ($edgeQueryMode eq "dontFormat"){
		#don't format!
	}
	#------------------------------------------------------------
	#(edges ? selected) formatting
	#------------------------------------------------------------
	elsif ($edgeQueryMode eq "edgesSelected"){
		tr/()//d for @origEdgeList;
	}
	#------------------------------------------------------------
	#(selection ? edge) formatting
	#------------------------------------------------------------
	else{
		my @tempEdgeList;
		foreach my $edge (@origEdgeList){	if ($edge =~ /\($mainlayer/){	push(@tempEdgeList,$edge);		}	}
		#[remove layer info] [remove ( ) ]
		@origEdgeList = @tempEdgeList;
		s/\(\d{0,},/\(/  for @origEdgeList;
		tr/()//d for @origEdgeList;
	}


	#------------------------------------------------------------
	#array creation (after the formatting)
	#------------------------------------------------------------
	our @origEdgeList_edit = @origEdgeList;
	our @vertRow=();
	our @vertRowList=();

	our @vertList=();
	our %vertPosTable=();
	our %endPointVectors=();

	our @vertMergeOrder=();
	our @edgesToRemove=();
	our $removeEdges = 0;


	#------------------------------------------------------------
	#Begin sorting the [edge list] into different [vert rows].
	#------------------------------------------------------------
	while (($#origEdgeList_edit + 1) != 0)
	{
		#this is a loop to go thru and sort the edge loops
		@vertRow = split(/,/, @origEdgeList_edit[0]);
		shift(@origEdgeList_edit);
		&sortRow;

		#take the new edgesort array and add it to the big list of edges.
		push(@vertRowList, "@vertRow");
	}


	#Print out the DONE list   [this should normally go in the sorting sub]
	#lxout("- - -DONE: There are ($#vertRowList+1) edge rows total");
	#for ($i = 0; $i < @vertRowList; $i++) {	lxout("- - -vertRow # ($i) = @vertRowList[$i]"); }
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SORT ROWS subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#requires sortRowStartup sub.

sub sortRow
{
	#this first part is stupid.  I need it to loop thru one more time than it will:
	my @loopCount = @origEdgeList_edit;
	unshift (@loopCount,1);

	foreach(@loopCount)
	{
		#lxout("[->] USING sortRow subroutine----------------------------------------------");
		#lxout("original edge list = @origEdgeList");
		#lxout("edited edge list =  @origEdgeList_edit");
		#lxout("vertRow = @vertRow");
		my $i=0;
		foreach my $thisEdge(@origEdgeList_edit)
		{
			#break edge into an array  and remove () chars from array
			@thisEdgeVerts = split(/,/, $thisEdge);
			#lxout("-        origEdgeList_edit[$i] Verts: @thisEdgeVerts");

			if (@vertRow[0] == @thisEdgeVerts[0])
			{
				#lxout("edge $i is touching the vertRow");
				unshift(@vertRow,@thisEdgeVerts[1]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[0] == @thisEdgeVerts[1])
			{
				#lxout("edge $i is touching the vertRow");
				unshift(@vertRow,@thisEdgeVerts[0]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[-1] == @thisEdgeVerts[0])
			{
				#lxout("edge $i is touching the vertRow");
				push(@vertRow,@thisEdgeVerts[1]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			elsif (@vertRow[-1] == @thisEdgeVerts[1])
			{
				#lxout("edge $i is touching the vertRow");
				push(@vertRow,@thisEdgeVerts[0]);
				splice(@origEdgeList_edit, $i,1);
				last;
			}
			else
			{
				$i++;
			}
		}
	}
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

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT   (no popups)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : popup("What I wanna print");

sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}