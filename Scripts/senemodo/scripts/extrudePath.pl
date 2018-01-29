#perl
#BY: Seneca Menard
#version 1.55

#This script is to extrude polysets along edgeRows.  The video on the website explains it best, but here are the rules:
# - The edgerows can't have branches.
# - There must be one poly set per edge row.
# - The polysets must be 2d.

#(8-11-07 bugfix) : The script wasn't removing the "senetemp" selection set from all the polys in all cases.
#(8-01-08 bugfix) : I swapped the [] for {} because my previous fix wasn't restoring the measurement system if the script was cancelled.
#(11-23-09 feature) : You can now do 2.5d extrudes, to keep a spiral staircase from twirling slowly over time.  To use that, you should just use the included form gui: "sen_extrudePath".
#(6-29-10 bugfix) : hmm.  the extrude syntax changed a bit in 401 SP3 i think, so i changed my syntax.
#(1-10-14 fix) : got the actr storage system up to date with 601

my $modoBuild = lxq("query platformservice appbuild ?");
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
lx("select.type polygon");
lx("!!poly.merge");  #this is to remove inner verts because it destroys modo's extrude tool indices
my @polys = lxq("query layerservice polys ? selected");
my @edges = lxq("query layerservice edges ? selected");
my $totalVertCount = lxq("query layerservice vert.n ? all");
my $currentVertAddList;
my %vertRowList=();
my %searchedRows;
my @normal;
my @polyPos;
my $flipPoly;
my $bothSides;
my $fakeAxis = -1;


#script arguments
foreach my $arg (@ARGV){
	if		($arg =~ /fakeX/i)	{	$fakeAxis = 0;	}
	elsif	($arg =~ /fakeY/i)	{	$fakeAxis = 1;	}
	elsif	($arg =~ /fakeZ/i)	{	$fakeAxis = 2;	}
}


#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																	SAFETY CHECKS																====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#symm
our $symmAxis = lxq("select.symmetryState ?");
if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
elsif	($symmAxis eq "x")		{	$symmAxis = 0;	}
elsif	($symmAxis eq "y")		{	$symmAxis = 1;	}
elsif	($symmAxis eq "z")		{	$symmAxis = 2;	}
if ($symmAxis != 3){
	lx("select.symmetryState none");
}

#Remember what the workplane was
@WPmem[0] = lxq ("workPlane.edit cenX:? ");
@WPmem[1] = lxq ("workPlane.edit cenY:? ");
@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
@WPmem[3] = lxq ("workPlane.edit rotX:? ");
@WPmem[4] = lxq ("workPlane.edit rotY:? ");
@WPmem[5] = lxq ("workPlane.edit rotZ:? ");
lx("workPlane.reset ");

#layer reference (modded.  only references if not in item mode)
my $layerReference = lxq("layer.setReference ?");
lx("!!layer.setReference $mainlayerID");

#-----------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO6 FIX))
#-----------------------------------------------------------------------------------
#sets the ACTR preset
our $seltype;
our $selAxis;
our $selCenter;
our $actr = 1;

if   ( lxq( "tool.set actr.auto ?") eq "on")			{	$seltype = "actr.auto";			}
elsif( lxq( "tool.set actr.select ?") eq "on")			{	$seltype = "actr.select";		}
elsif( lxq( "tool.set actr.border ?") eq "on")			{	$seltype = "actr.border";		}
elsif( lxq( "tool.set actr.selectauto ?") eq "on")		{	$seltype = "actr.selectauto";	}
elsif( lxq( "tool.set actr.element ?") eq "on")			{	$seltype = "actr.element";		}
elsif( lxq( "tool.set actr.screen ?") eq "on")			{	$seltype = "actr.screen";		}
elsif( lxq( "tool.set actr.origin ?") eq "on")			{	$seltype = "actr.origin";		}
elsif( lxq( "tool.set actr.parent ?") eq "on")			{	$seltype = "actr.parent";		}
elsif( lxq( "tool.set actr.local ?") eq "on")			{	$seltype = "actr.local";		}
elsif( lxq( "tool.set actr.pivot ?") eq "on")			{	$seltype = "actr.pivot";		}
elsif( lxq( "tool.set actr.pivotparent ?") eq "on")		{	$seltype = "actr.pivotparent";	}

elsif( lxq( "tool.set actr.worldAxis ?") eq "on")		{	$seltype = "actr.worldAxis";	}
elsif( lxq( "tool.set actr.localAxis ?") eq "on")		{	$seltype = "actr.localAxis";	}
elsif( lxq( "tool.set actr.parentAxis ?") eq "on")		{	$seltype = "actr.parentAxis";	}

else
{
	$actr = 0;
	lxout("custom Action Center");
	
	if   ( lxq( "tool.set axis.auto ?") eq "on")		{	 $selAxis = "auto";				}
	elsif( lxq( "tool.set axis.select ?") eq "on")		{	 $selAxis = "select";			}
	elsif( lxq( "tool.set axis.element ?") eq "on")		{	 $selAxis = "element";			}
	elsif( lxq( "tool.set axis.view ?") eq "on")		{	 $selAxis = "view";				}
	elsif( lxq( "tool.set axis.origin ?") eq "on")		{	 $selAxis = "origin";			}
	elsif( lxq( "tool.set axis.parent ?") eq "on")		{	 $selAxis = "parent";			}
	elsif( lxq( "tool.set axis.local ?") eq "on")		{	 $selAxis = "local";			}
	elsif( lxq( "tool.set axis.pivot ?") eq "on")		{	 $selAxis = "pivot";			}
	else												{	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action AXIS that I couldn't read");}

	if   ( lxq( "tool.set center.auto ?") eq "on")		{	 $selCenter = "auto";			}
	elsif( lxq( "tool.set center.select ?") eq "on")	{	 $selCenter = "select";			}
	elsif( lxq( "tool.set center.border ?") eq "on")	{	 $selCenter = "border";			}
	elsif( lxq( "tool.set center.element ?") eq "on")	{	 $selCenter = "element";		}
	elsif( lxq( "tool.set center.view ?") eq "on")		{	 $selCenter = "view";			}
	elsif( lxq( "tool.set center.origin ?") eq "on")	{	 $selCenter = "origin";			}
	elsif( lxq( "tool.set center.parent ?") eq "on")	{	 $selCenter = "parent";			}
	elsif( lxq( "tool.set center.local ?") eq "on")		{	 $selCenter = "local";			}
	elsif( lxq( "tool.set center.pivot ?") eq "on")		{	 $selCenter = "pivot";			}
	else												{ 	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action CENTER that I couldn't read");}
}
lx("tool.set actr.auto on");

#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																	SCRIPT STARTUP																====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
tr/()//d for @edges;
&mainRoutine;
&cleanup;



#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																	MAIN  ROUTINES																====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#MAIN ROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub mainRoutine{
	&sortRowStartup(dontFormat,@edges);
	&buildVertPosTable;

	our @todoPolys = @polys;
	my @lastRoundPolys;
	my $loop = 1;
	my $nextVertDir;
	my @posVerts;
	my @negVerts;
	my @newPolyList;
	my @oldPolyList;
	my @currentVerts;
	my $planeDist;


	while ($loop == 1){
		if (@lastRoundPolys > 0){ &fixReorderedElements(\@todoPolys,\@lastRoundPolys);}
		if (@todoPolys[0] eq undef){die("\n.\n[-----------------------------------------You have no polys selected so I'm killing the script---------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");}
		lx("select.element $mainlayer polygon set @todoPolys[0]");
		#lxout("todoPolys = @todoPolys");
		&determineIfBothSides(@todoPolys[0]); #decided whether or not to extrude the negPolys
		my @currentPolys = @todoPolys[0];
		@lastRoundPolys = @todoPolys[0];
		my @verts = getVertList(poly,\@currentPolys);
		my ($closestVert,$closestVertRow,$vertRowPlace) = findClosestEdgeRow(@currentPolys);
		my @vertRow = @{$vertRowList{$closestVertRow}};
		#lxout("closestVert=$closestVert,closestVertRow=$closestVertRow,vertRowPlace=$vertRowPlace");
		#lxout("vertRow = @vertRow");

		#find which side of the closest vert it's on.
		if (@vertRow == 2){
			#lxout("[->] The current vertRow has 2 verts, so I shouldn't bother trying to find which side the vert is on.");
			$nextVertDir = 1;
		}else{
			#lxout("[->] The current vertRow has more than 2 verts, so I need to find which verts the poly is inbetween <> vertRowPlace = $vertRowPlace.");
			my @normal = lxq("query layerservice poly.normal ? @currentPolys[0]");
			#if poly's closest vert is at end of edgerow, disp1 = (vert0,close)
			if ($vertRowPlace+1 == @vertRow){
				#lxout("this element in the array will be beyond the scope");
				#lxout("disp1 verts = @vertRow[0] , $closestVert <> (at end)");
				our @disp1 = unitVector(arrMath(@{$vertPosTable{@vertRow[0]}},@{$vertPosTable{$closestVert}},subt));
			}
			#if poly is in the middle of the edgerow, disp1 = (close+1,close)
			else{
				#lxout("this element in the array is in the scope");
				#lxout("disp1 verts = @vertRow[$vertRowPlace+1] , $closestVert <> (middle)");
				our @disp1 = unitVector(arrMath(@{$vertPosTable{@vertRow[$vertRowPlace+1]}},@{$vertPosTable{$closestVert}},subt));
			}

			#if poly is at vert0 and edgerow is loop, disp2 = (vert-2,close)
			if (($vertRowPlace == 0) && (@vertRow[0] == @vertRow[-1])){
				#lxout("disp2 verts = @vertRow[$vertRowPlace-2] , $closestVert <> (at start)");
				our @disp2 = unitVector(arrMath(@{$vertPosTable{@vertRow[$vertRowPlace-2]}},@{$vertPosTable{$closestVert}},subt));
			}
			#if poly is in middle of edgerow, disp2 = (vert-1,close)
			else{
				#lxout("disp2 verts = @vertRow[$vertRowPlace-1] , $closestVert <> (middle)");
				our @disp2 = unitVector(arrMath(@{$vertPosTable{@vertRow[$vertRowPlace-1]}},@{$vertPosTable{$closestVert}},subt));
			}
			my $dp1= dotProduct(\@normal,\@disp1);
			my $dp2 = dotProduct(\@normal,\@disp2);

			if (abs($dp1) > abs($dp2)){
				if ($vertRowPlace+1 == @vertRow){
					#lxout("EDGE 1 : (dp1 = $dp1<>dp2 = $dp2) the poly is inbetween verts ($closestVert) and (@vertRow[0])");
					$nextVertDir = 1;
				}else{
					#lxout("EDGE 1 : (dp1 = $dp1<>dp2 = $dp2) the poly is inbetween verts ($closestVert) and (@vertRow[$vertRowPlace+1])");
					$nextVertDir = 1;
				}
			}else{
				#lxout("EDGE 2 : (dp1 = $dp1<>dp2 = $dp2) the poly is inbetween verts ($closestVert) and (@vertRow[$vertRowPlace-1])");
				$nextVertDir = -1;
			}
		}

		#create the two arrays
		if ($nextVertDir == 1){
			#lxout("1");
			@negVerts = @vertRow;

			#if vertRow is a loop and the closest vert is vert0, then split the array in special way.
			if ((@vertRow[0] == @vertRow[-1]) && ($vertRowPlace == 0)){
				#lxout("vert row is special case : is a loop and the closest vert is the first or last");
				@posVerts = @vertRow;
				@negVerts = shift(@posVerts);
			}else{
				#lxout("vert row is not special case");
				@posVerts = splice(@negVerts, $vertRowPlace+1, @negVerts-$vertRowPlace);
				@negVerts = reverse(@negVerts);
			}
		}else{
			#lxout("-1");
			@negVerts = @vertRow;

			#if vertRow is a loop and the closest vert is vert0, then split the array in special way.
			if ((@vertRow[0] == @vertRow[-1]) && ($vertRowPlace == 0)){
				#lxout("vert row is special case : is a loop and the closest vert is the first or last");
				@posVerts = reverse(@negVerts);
				@negVerts = shift(@posVerts);
			}else{
				#correct?
				#lxout("vert row is not special case");
				@posVerts = splice(@negVerts, $vertRowPlace, @negVerts-$vertRowPlace);
				@negVerts = reverse(@negVerts);
			}
		}

		#flip the arrays if pos verts is less than negVerts
		if (@posVerts < @negVerts){
			my @temp = @posVerts;
			@posVerts = @negVerts;
			@negVerts = @temp;
		}
		#if negVerts has no verts, then give it posVerts[0] #TEMP : is this right?
		if (@negVerts == 0){	@negVerts = shift(@posVerts);	}
		#lxout("posVerts = @posVerts");
		#lxout("negVerts = @negVerts");

		#now build the new polys for the first half
		for (my $i=0; $i<@posVerts; $i++){
			my @vector1;
			my @vector2;
			my @fakeAxisOffset = (0,0,0);

			if ($i == 0)	{	our $prevVert = @negVerts[0];		}
			else			{	our $prevVert = @posVerts[$i-1];	}

			#get the direction
			@vector1 = arrMath(@{$vertPosTable{@posVerts[$i]}},@{$vertPosTable{$prevVert}},subt);
			if ($fakeAxis != -1){
				@fakeAxisOffset[$fakeAxis] = @vector1[$fakeAxis];
				@vector1[$fakeAxis] = 0;
			}
			@vector1 = unitVector(@vector1);


			#generate the plane  (normal plane)
			if (($i != $#posVerts) || (@posVerts[-1] == @negVerts[-1])){
				if (@posVerts[$i+1] eq undef){
					if (@negVerts >1){
						#lxout("vector2 (negVerts > 1) = using backup vert (@negVerts[-2],@negVerts[-1])");
						@vector2 = unitVector(arrMath(@{$vertPosTable{@negVerts[-2]}},@{$vertPosTable{@negVerts[-1]}},subt));
					}else{
						#lxout("vector2 (negVerts = 0) = using backup vert (@posVerts[0],@negVerts[0])");
						@vector2 = unitVector(arrMath(@{$vertPosTable{@posVerts[0]}},@{$vertPosTable{@negVerts[0]}},subt));
					}
				}else{
					#lxout("vector2 = using real vert (@posVerts[$i+1],@posVerts[$i])");
					@vector2 = unitVector(arrMath(@{$vertPosTable{@posVerts[$i+1]}},@{$vertPosTable{@posVerts[$i]}},subt));
				}
				if ($fakeAxis != -1){@vector2[$fakeAxis] = 0;}
				@vectorAvg = unitVector(arrMath(arrMath(@vector1,@vector2,add),0.5,0.5,0.5,mult));
				$planeDist = -1 * dotProduct(\@vectorAvg,\@{$vertPosTable{@posVerts[$i]}});

				#my @vertPos = arrMath(@{$vertPosTable{@posVerts[$i]}},@vectorAvg,add);
				#lx("vert.new @vertPos");
				#lxout("planeDist = $planeDist");
				#lxout("vectorAvg = @vectorAvg");
			}
			#special plane (end of edgerow)
			else{
				#popup("end of edgeRow (and not a loop)");
				@vectorAvg = @vector1;
				$planeDist = -1 * dotProduct(\@vectorAvg,\@{$vertPosTable{@posVerts[$i]}});
			}

			#now extrude the geometry
			lx("select.type polygon");
			#popup("before extrude");
			lx("tool.set poly.extrude on");
			lx("tool.reset");
			lx("tool.set actr.auto on");
			lx("tool.setAttr poly.extrude mode auto");
			lx("tool.setAttr center.auto cenX {@{$vertPosTable{@posVerts[$i]}}[0]}");
			lx("tool.setAttr center.auto cenY {@{$vertPosTable{@posVerts[$i]}}[1]}");
			lx("tool.setAttr center.auto cenZ {@{$vertPosTable{@posVerts[$i]}}[2]}");
			if ($modoBuild >= 33819){
				lx("tool.setAttr axis.auto startX {1}");
				lx("tool.setAttr axis.auto startY {0}");
				lx("tool.setAttr axis.auto startZ {0}");
				lx("tool.setAttr axis.auto endX {1}");
				lx("tool.setAttr axis.auto endY {0}");
				lx("tool.setAttr axis.auto endZ {0}");
			}else{
				lx("tool.setAttr axis.auto axisX {1}");
				lx("tool.setAttr axis.auto axisY {0}");
				lx("tool.setAttr axis.auto axisZ {0}");
				lx("tool.setAttr axis.auto upX {1}");
				lx("tool.setAttr axis.auto upY {0}");
				lx("tool.setAttr axis.auto upZ {0}");
			}
			lx("tool.setAttr poly.extrude shiftX {@vector1[0]}");
			lx("tool.setAttr poly.extrude shiftY {@vector1[1]}");
			lx("tool.setAttr poly.extrude shiftZ {@vector1[2]}");
			lx("tool.doApply");
			lx("tool.set poly.extrude off");
			#popup("after extrude");

			#if extrude is thicken, then we have to desel one side.
			if ($i == 0){
				lx("select.editSet senetemp add");
				my @currPolys = lxq("query layerservice polys ? selected");
				if (@currPolys == 2){
					if ($currPolys[0] < $currPolys[1]){
						lx("select.element $mainlayer polygon remove $currPolys[0]");
					}else{
						lx("select.element $mainlayer polygon remove $currPolys[1]");
					}
				}

				#for (my $i = $polyCount-(($#currentPolys*2)+2); $i<$polyCount-($#currentPolys+1); $i++){	lx("select.element $mainlayer polygon add $i");	}
				my @newPolys = lxq("query layerservice polys ? selected");
				@currentVerts = getVertList(poly,\@newPolys);
				$currentVertAddList = @currentVerts;
				$totalVertCount += $currentVertAddList;
			}else{
				$totalVertCount += $currentVertAddList;
				@currentVerts = ($totalVertCount-$currentVertAddList..$totalVertCount-1);
				lx("select.drop vertex");
				foreach my $vert (@currentVerts){
					lx("select.element $mainlayer vertex add $vert");
				}
			}


			#now taut the new verts to the plane.
			lx("select.type vertex");
			foreach my $vert (@currentVerts){
				my @pos = lxq("query layerservice vert.pos ? $vert");
				my $test1 = -1 * (dotProduct(\@pos,\@vectorAvg)+$planeDist);
				my $test2 = dotProduct(\@vector1,\@vectorAvg);
				my $time;
				if ( ($test1 != 0) && ($test2 != 0) ){
					$time = $test1/$test2;
				}else{
					next;
				}

				my @intersectPoint = arrMath(@pos,arrMath(@vector1,$time,$time,$time,mult),add);
				if (@intersectPoint[0] eq undef){	die("Apparently, one of your polygon set(s) are coplanar with the edgerow and thus generating illegal geometry so I'm cancelling the script");	}
				if ($fakeAxisPoint != -1){@intersectPoint = arrMath(@intersectPoint,@fakeAxisOffset,add);}

				#popup("fakeAxisOffset = @fakeAxisOffset");
				lx("select.element $mainlayer vertex set $vert");
				lx("!!vert.set x {@intersectPoint[0]}");
				lx("!!vert.set y {@intersectPoint[1]}");
				lx("!!vert.set z {@intersectPoint[2]}");
			}

			if ($i == $#posVerts){

				lx("select.type polygon");
				lx("select.editSet senetemp remove");

			}

		}

		#now build the new polys for the second half
		if ($bothSides == 1){
			for (my $i=0; $i<@negVerts; $i++){
				my @vector1;
				my @vector2;
				my @fakeAxisOffset = (0,0,0);

				#get vector 1 in normal cases.
				if (@vertRow[0] != @vertRow[1]){
					if ($i == 0)	{	our $prevVert = @posVerts[0];		}
					else			{	our $prevVert = @negVerts[$i-1];	}

					#get the direction
					@vector1 = arrMath(@{$vertPosTable{@negVerts[$i]}},@{$vertPosTable{$prevVert}},subt);
					if ($fakeAxis != -1){
						@fakeAxisOffset[$fakeAxis] = @vector1[$fakeAxis];
						@vector1[$fakeAxis] = 0;
					}
					@vector1 = unitVector(@vector1);
				}
				#get vector 1 in loop cases.
				else{
					#popup("special case for loops");
					@vector1 = arrMath(@{$vertPosTable{@negVerts[0]}},@{$vertPosTable{@posVerts[0]}},subt);
					if ($fakeAxis != -1){
						@fakeAxisOffset[$fakeAxis] = @vector1[$fakeAxis];
						@vector1[$fakeAxis] = 0;
					}
					@vector1 = unitVector(@vector1);
				}

				#generate the plane  (normal plane)
				if (($i != $#negVerts) || (@negVerts[-1] == @posVerts[-1])){
					if (@negVerts[$i+1] eq undef){
						#lxout("using backup vert (@posVerts[-2],@negVerts[0])");
						@vector2 = unitVector(arrMath(@{$vertPosTable{@posVerts[-2]}},@{$vertPosTable{@posVerts[-1]}},subt));
					}else{
						#lxout("using real vert (@negVerts[$i+1])");
						@vector2 = unitVector(arrMath(@{$vertPosTable{@negVerts[$i+1]}},@{$vertPosTable{@negVerts[$i]}},subt));
					}
					if ($fakeAxis != -1){@vector2[$fakeAxis] = 0;}
					@vectorAvg = unitVector(arrMath(arrMath(@vector1,@vector2,add),0.5,0.5,0.5,mult));
					$planeDist = -1 * dotProduct(\@vectorAvg,\@{$vertPosTable{@negVerts[$i]}});

					#my @vertPos = arrMath(@{$vertPosTable{@negVerts[$i]}},@vectorAvg,add);
					#lx("vert.new @vertPos");
					#lxout("planeDist = $planeDist");
					#lxout("vectorAvg = @vectorAvg");
				}
				#special plane (end of edgerow)
				else{
					#popup("end of edgeRow (and not a loop)");
					@vectorAvg = @vector1;
					$planeDist = -1 * dotProduct(\@vectorAvg,\@{$vertPosTable{@negVerts[$i]}});
				}


				#now move or extrude the geometry.
				#MOVE if on round 0

				if ($i == 0){
					lx("select.drop polygon");
					lx("select.useSet senetemp select");
					lx("select.editSet senetemp remove");

					lx("tool.set xfrm.move on");
					lx("tool.reset");
					lx("tool.setAttr axis.auto axisX {1}");
					lx("tool.setAttr axis.auto axisY {0}");
					lx("tool.setAttr axis.auto axisZ {0}");
					lx("tool.setAttr axis.auto upX {1}");
					lx("tool.setAttr axis.auto upY {0}");
					lx("tool.setAttr axis.auto upZ {0}");
					lx("tool.setAttr xfrm.move X {@vector1[0]}");
					lx("tool.setAttr xfrm.move Y {@vector1[1]}");
					lx("tool.setAttr xfrm.move Z {@vector1[2]}");
					lx("tool.doApply");
					lx("tool.set xfrm.move off");
				}

				#EXTRUDE if not on round 0
				else{
					#now extrude the geometry
					lx("select.type polygon");
					#popup("before extrude");
					lx("tool.set poly.extrude on");
					lx("tool.reset");
					lx("tool.setAttr poly.extrude mode auto");
					lx("tool.setAttr center.auto cenX {@{$vertPosTable{@negVerts[$i]}}[0]}");
					lx("tool.setAttr center.auto cenY {@{$vertPosTable{@negVerts[$i]}}[1]}");
					lx("tool.setAttr center.auto cenZ {@{$vertPosTable{@negVerts[$i]}}[2]}");
					lx("tool.setAttr axis.auto axisX {1}");
					lx("tool.setAttr axis.auto axisY {0}");
					lx("tool.setAttr axis.auto axisZ {0}");
					lx("tool.setAttr axis.auto upX {1}");
					lx("tool.setAttr axis.auto upY {0}");
					lx("tool.setAttr axis.auto upZ {0}");
					lx("tool.setAttr poly.extrude shiftX {@vector1[0]}");
					lx("tool.setAttr poly.extrude shiftY {@vector1[1]}");
					lx("tool.setAttr poly.extrude shiftZ {@vector1[2]}");
					lx("tool.doApply");
					lx("tool.set poly.extrude off");
					#popup("after extrude");
				}

				#find the current round's verts
				if ($i == 0){
					my @currentPolys = lxq("query layerservice polys ? selected");
					@currentVerts = getVertList(poly,\@currentPolys);
				}else{
					$totalVertCount += $currentVertAddList;
					@currentVerts = ($totalVertCount-$currentVertAddList..$totalVertCount-1);
				}

				#now taut the new verts to the plane.
				lx("select.type vertex");
				foreach my $vert (@currentVerts){
					my @neg = lxq("query layerservice vert.pos ? $vert");
					my $test1 = -1 * (dotProduct(\@neg,\@vectorAvg)+$planeDist);
					my $test2 = dotProduct(\@vector1,\@vectorAvg);
					my $time;
					if ( ($test1 != 0) && ($test2 != 0) ){
						$time = $test1/$test2;
					}else{
						next;
					}

					my @intersectPoint = arrMath(@neg,arrMath(@vector1,$time,$time,$time,mult),add);
					if ($forceAxis != -1){@intersectPoint = arrMath(@intersectPoint,@fakeAxisOffset,add);}

					lx("select.element $mainlayer vertex set $vert");
					lx("vert.set x {@intersectPoint[0]}");
					lx("vert.set y {@intersectPoint[1]}");
					lx("vert.set z {@intersectPoint[2]}");
				}
			}
		}


		@todoPolys = removeListFromArray(\@todoPolys,\@currentPolys);
		if (@todoPolys == 0){$loop = 0;}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND CLOSEST EDGE ROW
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub findClosestEdgeRow{
	my $closestFakeDist=10000000000000000;
	my $closestVert;
	my $closestEdgeRow;
	my $closestEdgeRowPos;

	#find averaged poly position
	my @polyPosAvg=(0,0,0);
	foreach my $poly (@_){
		my @pos = lxq("query layerservice poly.pos ? $poly");
		@polyPosAvg = arrMath(@pos,@polyPosAvg,add);
	}
	my $count = @_;
	@polyPosAvg = arrMath(@polyPosAvg,$count,$count,$count,div);

	#find closest vert
	foreach my $vert (keys %vertPosTable){
		my @disp = arrMath(@{$vertPosTable{$vert}},@polyPosAvg,subt);
		my $fakeDist = abs(@disp[0]) + abs(@disp[1]) + abs(@disp[2]);
		if ($fakeDist < $closestFakeDist){
			$closestFakeDist = $fakeDist;
			$closestVert = $vert;
		}
	}

	#find closest edge row...
	for (my $table=0; $table<(keys %vertRowList); $table++){
		#skip this row if it's already been used.
		if ($searchedRows{$table} == 1){next;}
		if ($closestEdgeRow ne undef){last;}
		my @searchedRows = (keys %searchedRows);
		#lxout("edgerows I'm skipping this round (@searchedRows)");

		for (my $i=0; $i<@{$vertRowList{$table}}; $i++){
			if(@{$vertRowList{$table}}[$i] == $closestVert){
				#lxout("[->] edgeRow ($table) (@{$vertRowList{$table}}) has vert ($closestVert);");
				$searchedRows{$table} = 1;
				$closestEdgeRow = $table;
				$closestEdgeRowPos = $i;
				last;
			}
			#else{lxout("NOPE.  vert=$closestVert <> table=$table(@{$vertRowList{$table}}) <> i=$i");}
		}
	}

	if ($closestEdgeRow eq undef){	die("Two of your polygon sets are choosing the same edge row.\nEither move the polygons so they're not choosing the same edge row or do them one at a time");	}
	return($closestVert,$closestEdgeRow,$closestEdgeRowPos);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DETERMINE WHETHER OR NOT TO EXTRUDE THE NEGATIVE POLYS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub determineIfBothSides{
	my @vertList = lxq("query layerservice poly.vertList ? @_[0]");
	$bothSides = 1;

	foreach my $vert (@vertList){
		my @polys = lxq("query layerservice vert.polyList ? $vert");
		if (@polys > 1){
			lxout("This poly is connected to other polys, so I'm not going to extrude both sides");
			$bothSides = 0;
			last;
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BUILD VERT POS TABLE (from edge rows)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub buildVertPosTable{
	our %vertPosTable=();
	my $count = 0;
	foreach my $vertRow(@vertRowList){
		my @verts = split(/[^0-9]/,$vertRow);
		$vertRowList{$count} = \@verts;
		foreach my $vert (@verts){
			my @pos = lxq("query layerservice vert.pos ? $vert");
			$vertPosTable{$vert} = \@pos;
		}
		$count++;
	}
}


#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																	SUBROUTINES																	====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#REMOVE INDEX LIST2 FROM INDEX LIST1 (so if you delete polys, you can keep your array)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : &fixReorderedElements(\@list1,\@list2);
sub fixReorderedElements{
	my @compareList = sort {$a <=> $b} @{$_[1]};

	for (my $i=0; $i<@{$_[0]}; $i++){
		my $subtract = 0;
		foreach my $subt (@compareList){
			if ($subt <= @{$_[0]}[$i])		{	$subtract++;		}
			else						{	last;			}
		}
		@{$_[0]}[$i] -= $subtract;
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CONVERT POLY OR EDGE LIST INTO VERT LIST.
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub getVertList{
	my $selType = @_[0];
	my %elemList;
	foreach my $elem (@{$_[1]}){
		my @verts = lxq("query layerservice $selType.vertList ? $elem");
		foreach my $vert (@verts){	$elemList{$vert}=1;}
	}
	return(keys %elemList);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#REMOVE ARRAY2 FROM ARRAY1 SUBROUTINE v1.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @newArray = removeListFromArray(\@full_list,\@small_list);
sub removeListFromArray{
	my @fullList = @{$_[0]};
	for (my $i=0; $i<@{$_[1]}; $i++){
		for (my $u=0; $u<@fullList; $u++){
			if ($fullList[$u] eq ${$_[1]}[$i]){
				splice(@fullList, $u,1);
				last;
			}
		}
	}
	return @fullList;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#2 CROSSPRODUCT VECTORS FROM 1 VECTOR (in=2pos out=2vec)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#requires UNITVECTOR
#requires CROSSPRODUCT
#my @twoVectors = twoVertCPSetup(@pos1,@pos2);
sub twoVertCPSetup{
	my @pos1 = @{$_[0]};
	my @pos2 = @{$_[1]};

	#create the real vector
	my @vector1 = ((@pos2[0]-@pos1[0]),(@pos2[1]-@pos1[1]),(@pos2[2]-@pos1[2]));
	@vector1 = unitVector(@vector1);

	#create the fake vector
	my @vector2 = (0,1,0);
	my $dp = (@vector1[0]*@vector2[0] + @vector1[1]*@vector2[1] + @vector1[2]*@vector2[2]);
	if ($dp > .95){	@vector2 = (1,0,0);	}

	#create the first and second crossProduct
	my @crossProduct = crossProduct(\@vector1,\@vector2);
	@crossProduct = unitVector(@crossProduct);
	my @secondCrossProduct = crossProduct(\@vector1,\@crossProduct);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CROSSPRODUCT SUBROUTINE (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @crossProduct = crossProduct(\@vector1,\@vector2);
sub crossProduct{
	return ( (${$_[0]}[1]*${$_[1]}[2])-(${$_[1]}[1]*${$_[0]}[2]) , (${$_[0]}[2]*${$_[1]}[0])-(${$_[1]}[2]*${$_[0]}[0]) , (${$_[0]}[0]*${$_[1]}[1])-(${$_[1]}[0]*${$_[0]}[1]) );
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

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DOT PRODUCT subroutine (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	return (	(${$_[0]}[0]*${$_[1]}[0])+(${$_[0]}[1]*${$_[1]}[1])+(${$_[0]}[2]*${$_[1]}[2])	);
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
	if ($math eq "add")		{	@newArray = (@array1[0]+@array2[0],@array1[1]+@array2[1],@array1[2]+@array2[2]);	}
	elsif ($math eq "subt")	{	@newArray = (@array1[0]-@array2[0],@array1[1]-@array2[1],@array1[2]-@array2[2]);	}
	elsif ($math eq "mult")	{	@newArray = (@array1[0]*@array2[0],@array1[1]*@array2[1],@array1[2]*@array2[2]);	}
	elsif ($math eq "div")		{	@newArray = (@array1[0]/@array2[0],@array1[1]/@array2[1],@array1[2]/@array2[2]);	}
	return @newArray;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SORT THE ELEMENTS INTO SYMMETRICAL HALVES (requires $symmAxis)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub sortSymm{
	my $selType = shift(@_);
	my @positive;
	my @negative;

	foreach my $elem (@_){
		my @pos = lxq("query layerservice $selType.pos ? $elem");
		if (@pos[$symmAxis] > 0 )	{  push(@positive,$elem);		}
		else					{  push(@negative,$elem);	}

	}
	return(\@positive,\@negative);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SORT ROWS SETUP subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#requires SORTROW sub
#sortRowStartup(dontFormat,@edges);		#NO FORMAT
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

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE A SPHERE AT THE SPECIFIED PLACE/SCALE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub createSphere{
	if (@_[3] eq undef){@_[3] = 5;}
	lx("tool.set prim.sphere on");
	lx("tool.reset");
	lx("tool.setAttr prim.sphere cenX {@_[0]}");
	lx("tool.setAttr prim.sphere cenY {@_[1]}");
	lx("tool.setAttr prim.sphere cenZ {@_[2]}");
	lx("tool.setAttr prim.sphere sizeX {@_[3]}");
	lx("tool.setAttr prim.sphere sizeY {@_[3]}");
	lx("tool.setAttr prim.sphere sizeZ {@_[3]}");
	lx("tool.doApply");
	lx("tool.set prim.sphere off");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE A CUBE AT THE SPECIFIED PLACE/SCALE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub createCube{
	if (@_[3] eq undef){@_[3] = 5;}
	lx("tool.set prim.cube on");
	lx("tool.reset");
	lx("tool.setAttr prim.cube cenX {@_[0]}");
	lx("tool.setAttr prim.cube cenY {@_[1]}");
	lx("tool.setAttr prim.cube cenZ {@_[2]}");
	lx("tool.setAttr prim.cube sizeX {@_[3]}");
	lx("tool.setAttr prim.cube sizeY {@_[3]}");
	lx("tool.setAttr prim.cube sizeZ {@_[3]}");
	lx("tool.doApply");
	lx("tool.set prim.cube off");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CLEANUP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub cleanup{
	#Set the layer reference back
	lx("!!layer.setReference [$layerReference]");

	#put the WORKPLANE and UNIT MODE back to what you were in before.
	lx("workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");

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

	#Set the action center settings back
	if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
	else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }

	#drop poly selection
	lx("select.type polygon");
	lx("!!select.useSet senetemp select");
	lx("!!select.editSet senetemp remove");
	lx("!!select.drop polygon");
}