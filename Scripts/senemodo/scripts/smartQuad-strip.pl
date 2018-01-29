#perl
#AUTHOR: Seneca Menard
#version 3.36
#This tool is like "3pt2quad" and "Smart Quad" only that it can actually create a single polygon, or a strip of polygons, or a mesh of polygons.  :)
#(8-29-05 overhaul) : This script now works with VERTS and EDGES and SYMMETRY.
#(7-23-06) : The script now works properly on layers with translation
#(8-12-06) : The script gets canceled if the edge that the edge extend is supposed to come from doesn't exist.
#(8-22-06) : I reordered the layer ref command to get around a small modo bug.
#(8-01-08) : I swapped the [] for {} to stop the bug with my pref change not getting undone if the script was cancelled.
#(3-20-12) : noticed a bug where it'd leave nonborder edges selected when it converts the selection to edge.
#(1-10-14 fix) : got the actr storage system up to date with 601

#-----------------------------------------------------------------------------------
#To create a single polygon:
#-----------------------------------------------------------------------------------
	#1)  VERT MODE : Select 3 verts and run the script.  (the last two verts MUST be connected to a polygon)
	#2) EDGE MODE : Select 2 edges and run the script.  (the second edge MUST be connected to a polygon)

#-----------------------------------------------------------------------------------
#To create a strip of polygons:
#-----------------------------------------------------------------------------------
	#1) VERT MODE : Select an "L" shape of verts, with the first selected vert being the stubby part of the L and run the script.  (All the other verts must be connected to polygons)
	#2) EDGE MODE : Select an "L" shape of edges, with the first selected edge being the stubby part of the L and run the script.  (All the other edges must be connected to polygons)

#-----------------------------------------------------------------------------------
#To create a strip of polygons and have the last vert be connected to a preexisting vert: (CONNECT)
#-----------------------------------------------------------------------------------
	#1) VERT MODE : Select the "L" shape just as usual, but select ONE MORE vert at the end, and I will make the strip connect to that vert. (and run the script with "connect" appended)
	#2) EDGE MODE : Select the "L" shape just as usual, but select ONE MORE edge at the end, and I will make the strip connect to that edge. (and run the script with "connect" appended)

#-----------------------------------------------------------------------------------
#To create a mesh of polygons:
#-----------------------------------------------------------------------------------
	#1) EDGE MODE : This is the same as creating a strip of polygons, only it will create MULTIPLE strips, one after another.  Normally, I need an L shape of edges selected where there only be one edge selected before the bend in the L shape, but
	#in this case it's a little wierder.  I need two rows of edges selected, but they're touching and so it'd actually be one edgerow...  So, what I need is to have one vertex selected that will tell me where to break the edgerow into two edgerows.  :)
	#So have 1 vert selected, select the edgerow, and run the script.

#-----------------------------------------------------------------------------------
#To create a mesh of polygons and have the end verts on the mesh connect to preexisting edges: (CONNECT)
#-----------------------------------------------------------------------------------
	#1) EDGE MODE : This is the same as creating a mesh of polygons, only it needs two vertices selected.  The edgeRow will then be broken into three edgerows.  The first edgerow will be the verts that tell me where to do each extend TO.   The second edgerow will be the edgerow that's extended.
	#The third edgerow will be the edgerow that tells me what edges to connect to.  So have two verts selected, select the edgerow, and run the script with "connect" appended.



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#--------------------------------------SAFETY CHECKS------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
lxout("-----------------------------------------------------------------------------------------");
lxout("-----------------------------SMARTQUAD SCRIPT----------------------------------");
lxout("-----------------------------------------------------------------------------------------");
our $mainlayer = lxq("query layerservice layers ? main");
our @vertsel;
our $selectMode;


#-----------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO6 FIX))
#-----------------------------------------------------------------------------------
#sets the ACTR preset
my $seltype;
my $selAxis;
my $selCenter;
my $actr = 1;

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
lx("tool.set actr.selectauto on");


#Remember what the workplane was and turn it off
my @WPmem;
@WPmem[0] = lxq ("workPlane.edit cenX:? ");
@WPmem[1] = lxq ("workPlane.edit cenY:? ");
@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
@WPmem[3] = lxq ("workPlane.edit rotX:? ");
@WPmem[4] = lxq ("workPlane.edit rotY:? ");
@WPmem[5] = lxq ("workPlane.edit rotZ:? ");
lx("!!workPlane.reset ");

#set the main layer to be "reference" to get the true vert positions.
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my $layerReference = lxq("layer.setReference ?");
lx("!!layer.setReference $mainlayerID");




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SYMMETRY CHECKS AND (VERT OR EDGE MODE) CHECKS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
our $symmAxis = lxq("select.symmetryState ?");

#CONVERT THE SYMM AXIS TO MY OLDSCHOOL NUMBER
if 		($symmAxis eq "none")	{	$symmAxis = 3;	}
elsif	($symmAxis eq "x")		{	$symmAxis = 0;	}
elsif	($symmAxis eq "y")		{	$symmAxis = 1;	}
elsif	($symmAxis eq "z")		{	$symmAxis = 2;	}


#-----------------------------------------------------------------
#-----------------------------------------------------------------
#WHAT TO DO IF IN VERT MODE
#-----------------------------------------------------------------
#-----------------------------------------------------------------
if( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )
{
	lxout("[->] VERT MODE");

	#make sure the user has at least three verts selected
	if (lxq("select.count vertex ?") < 3){die("You must have at least 3 verts selected");}

	@vertsel = lxq("query layerservice verts ? selected");

	#-----------------------------------------------------------
	#SYMMETRY IS OFF
	#-----------------------------------------------------------
	if ($symmAxis == 3)
	{
		lxout("[->] SYMMETRY IS OFF");
		&smartQuad;
		if (@ARGV[0] eq "connect") {	&connect;	}

	}
	#-----------------------------------------------------------
	#SYMMETRY IS ON
	#-----------------------------------------------------------
	else
	{
		lxout("[->] SYMMETRY IS ON");
		our $allVertsOnAxis = 1;
		our @vertListPos;
		our @vertListNeg;
		our $symmetry = 1;

		#turn SYMM OFF
		lx("select.symmetryState none");


		#-----------------------------------------------------------------------
		#sort the selected verts to each symmetrical half
		#-----------------------------------------------------------------------
		my $count = 0;
		foreach my $vert (@vertsel)
		{
			#POSITIVE check
			my @vertPos = lxq("query layerservice vert.pos ? $vert");
			#lxout("vert[$vert]Pos = @vertPos");
			if (@vertPos[$symmAxis] > 0.00000001)
			{
				#lxout("[$count] = (vert$vert)POS");
				push(@vertListPos, "$vert");
				$allVertsOnAxis = 0;
			}
			#NEGATIVE check
			elsif (@vertPos[$symmAxis] < -0.00000001)
			{
				#lxout("[$count] = (vert$vert)NEG");
				push(@vertListNeg, "$vert");
				$allVertsOnAxis = 0;
			}
			#THEN THIS VERT MUST BE ON THE AXIS
			else
			{
				#lxout("[$count] = (vert$vert)ON AXIS!");
				push(@vertListPos, "$vert");
				push(@vertListNeg, "$vert");
			}
			$count++;
		}

		#-----------------------------------------------------------------------------------------
		#NOW RUN THE SCRIPT ON EACH HALF OF THE MODEL
		#-----------------------------------------------------------------------------------------

		#all verts on 0 message
		if ($allVertsOnAxis == 1)	{lxout("[->] ALL the verts are ON the symm axis, so i'm not using symmetry");}

		lxout("vertListPos = @vertListPos");
		lxout("vertListNeg = @vertListNeg");
		if ($#vertListPos > 1)
		{
			@vertsel = @vertListPos;
			&smartQuad;
			if (@ARGV[0] eq "connect") {	&connect;	}
		}
		else { lxout("[->]NOT running script on POS half");	}

		if (($#vertListNeg > 1) && ($allVertsOnAxis == 0) )
		{
			@vertsel = @vertListNeg;
			&smartQuad;
			if (@ARGV[0] eq "connect") {	&connect;	}
		}
		else { lxout("[->]NOT running script on NEG half");	}
	}
}



#-----------------------------------------------------------------
#-----------------------------------------------------------------
#WHAT TO DO IF IN EDGE MODE
#-----------------------------------------------------------------
#-----------------------------------------------------------------
elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )
{
	lxout("[->] EDGE MODE");
	$selectMode = edge;

	#drop all non-border edges
	lx("!!select.edge remove poly more 1");

	#make sure the user has at least two edges selected
	if (lxq("select.count edge ?") < 2){die("You must have at least 2 edges selected");}

	#Get and edit the original edge list *throw away all edges that aren't in mainlayer* (FIXED FOR MODO2)
	our @origEdgeList = lxq("query layerservice selection ? edge");
	my @tempEdgeList;
	foreach my $edge (@origEdgeList){	if ($edge =~ /\($mainlayer/){	push(@tempEdgeList,$edge);		}	}
	#[remove layer info] [remove ( ) ]
	@origEdgeList = @tempEdgeList;
	s/\(\d{0,},/\(/  for @origEdgeList;
	tr/()//d for @origEdgeList;

	#-----------------------------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------
	#SYMMETRY IS OFF
	#-----------------------------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------
	if ($symmAxis == 3)
	{
		lxout("[->] SYMMETRY IS OFF");
		@selectedVerts = lxq("query layerservice verts ? selected");
		&vertRowCompute;
	}
	#-----------------------------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------
	#SYMMETRY IS ON
	#-----------------------------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------------------------
	else
	{
		#time to sort the selected edges into each symmetrical half
		lxout("[->] SYMMETRY IS ON");
		our $allVertsOnAxis = 1;
		lx("select.symmetryState none");
		our $symmetry = 1;
		my $count = 0;
		our @edgeListPos;
		our @edgeListNeg;

		#-----------------------------------------------------------
		#CHECK WHICH EDGES ARE ON WHICH SIDE OF THE AXIS
		#-----------------------------------------------------------
		foreach my $edge (@origEdgeList)
		{
			my @verts = split(/,/, $edge);
			#lxout("[$count]:verts = @verts");

			#TIME TO CHECK VERT0---------------------------------
			#vert0 POSITIVE check
			my @vert0Pos = lxq("query layerservice vert.pos ? @verts[0]");
			#lxout("--[@verts[0]]vert0Pos = @vert0Pos");
			if (@vert0Pos[$symmAxis] > 0.00000001)
			{
				#lxout("[$count]0 = POS");
				push(@edgeListPos, "$edge");
				$allVertsOnAxis = 0;
			}
			#vert0 NEGATIVE check
			elsif (@vert0Pos[$symmAxis] < -0.00000001)
			{
				#lxout("[$count]0 = NEG");
				push(@edgeListNeg, "$edge");
				$allVertsOnAxis = 0;
			}

			else #TIME TO CHECK VERT1---------------------------------
			{
				#vert1 POSITIVE check
				my @vert1Pos = lxq("query layerservice vert.pos ? @verts[1]");
				#lxout("--[@verts[1]]vert1Pos = @vert1Pos");
				if (@vert1Pos[$symmAxis] > 0.00000001)
				{
					#lxout("[$count]1 = POS");
					push(@edgeListPos, "$edge");
					$allVertsOnAxis = 0;
				}
				#vert1 NEGATIVE check
				elsif (@vert1Pos[$symmAxis] < -0.00000001)
				{
					#lxout("[$count]1 = NEG");
					push(@edgeListNeg, "$edge");
					$allVertsOnAxis = 0;
				}

				#I guess both verts are on ZERO then.
				else
				{
					#lxout("[$count]NEITHER");
					push(@edgeListPos, "$edge");
					push(@edgeListNeg, "$edge");
				}
			}
			$count++;
		}

		#lxout("ALL DONE: ");
		#lxout("EDGES ABOVE symm: [$#edgeListPos]@edgeListPos");
		#lxout("EDGES BELOW symm: [$#edgeListNeg]@edgeListNeg");
		#ask the user if they still wanna run the script if the model's symmetry appears to be off
		#if ($#edgeListPos != $#edgeListNeg)	{	popup("There aren't an even number of edges selected on both sides of the model.  Do you still want to run the script?");	}


		#-----------------------------------------------------------
		#CHECK WHICH VERTS ARE ON WHICH SIDE OF THE AXIS
		#-----------------------------------------------------------
		$count = 0;
		our @vertListPos;
		our @vertListNeg;
		@vertsel = lxq("query layerservice verts ? selected");
		foreach my $vert (@vertsel)
		{
			#POSITIVE check
			my @vertPos = lxq("query layerservice vert.pos ? $vert");
			#lxout("vert[$vert]Pos = @vertPos");
			if (@vertPos[$symmAxis] > 0.00000001)
			{
				#lxout("[$count] = (vert$vert)POS");
				push(@vertListPos, "$vert");
				$allVertsOnAxis = 0;
			}
			#NEGATIVE check
			elsif (@vertPos[$symmAxis] < -0.00000001)
			{
				#lxout("[$count] = (vert$vert)NEG");
				push(@vertListNeg, "$vert");
				$allVertsOnAxis = 0;
			}
			#THEN THIS VERT MUST BE ON THE AXIS
			else
			{
				#lxout("[$count] = (vert$vert)ON AXIS!");
				push(@vertListPos, "$vert");
				push(@vertListNeg, "$vert");
			}
			$count++;
		}




		#-----------------------------------------------------------
		#SCRIPT EXECUTION TIME
		#-----------------------------------------------------------

		#all verts on 0 message
		if ($allVertsOnAxis == 1)	{lxout("[->] ALL the verts are ON the symm axis, so i'm not using symmetry");}

		#TIME TO DO THE EDGEWELDING!
		#round 1
		if ($#edgeListPos > 0)
		{
			lxout("----POSITIVE HALF-----");
			@origEdgeList = @edgeListPos;
			@selectedVerts = @vertListPos;

			&vertRowCompute;
		}
		else
		{
			lxout("[->]NOT RUNNING the script on POS half of model");
		}

		#round 2
		if ((@edgeListNeg > 0) && ($allVertsOnAxis == 0))
		{
			lxout("----NEGATIVE HALF-----");
			@origEdgeList = @edgeListNeg;
			@selectedVerts = @vertListNeg;

			&vertRowCompute;
		}
		else
		{
			lxout("[->]NOT RUNNING the script on NEG half of model");
		}
	}
}


#-----------------------------------------------------------------
#-----------------------------------------------------------------
#WHAT TO DO IF IN ANOTHER SEL MODE
#-----------------------------------------------------------------
#-----------------------------------------------------------------
else{ !!die("You're not in VERT or EDGE mode, so I'm killing the script");}







#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#--------------------------all the special EDGE ROW  code--------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub vertRowCompute
{
	#-----------------------------------------------------------------------------------------------------------
	#Begin sorting the [edge list] into different [vert rows].
	#-----------------------------------------------------------------------------------------------------------
	our @origEdgeList_edit=@origEdgeList;
	our @vertRow;
	our @vertRowList;
	undef(@vertRowList);

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
	#for ($i = 0; $i < (@vertRowList) ; $i++) {	lxout("- - -vertRow # ($i) = @vertRowList[$i]"); }






	#-----------------------------------------------------------------------------------------------------------
	#Go thru each vert row and (split it to verts), (order it), (run the smartquad script on it)
	#-----------------------------------------------------------------------------------------------------------
	my $vertRowCount =0;
	foreach my $vertRow (@vertRowList)
	{
		#----------------------------------------------------------------------
		#PART 1 : Split the vertRow string into an array
		#----------------------------------------------------------------------
		my @currentRow = split (/[^0-9]/, $vertRow);
#TEMP : I need to check to see if the user has connect on and if so, need more than 3 verts.



		#----------------------------------------------------------------------
		#PART 2 : Make sure the VertRow is in the right order and not flipped
		#----------------------------------------------------------------------
		my $count = 0;
		my $firstCount;
		my $lastCount;

		#check how far into the edgelist the first vert is
		foreach my $edge (@origEdgeList)
		{
			#lxout("CHECK FIRST[$count] <>vert=@currentRow[0]<>edge = $edge");
			if ($edge =~ @currentRow[0])
			{
				$firstCount = $count;
				#lxout("firstCount = $firstCount;");
				last;
			}
			$count++;
		}


		#check how far into the edgelist the last vert is, but don't bother checking if the firstCount is at ZERO
		if ($firstCount != 0)
		{
			$count = 0;
			foreach my $edge (@origEdgeList)
			{
				#lxout("CHECK LAST[$count] <>vert=@currentRow[-1]<>edge = $edge");
				if ($edge =~ @currentRow[-1])
				{
					$lastCount = $count;
					#lxout("lastCount = $lastCount;");
					last;
				}
				$count++;
			}
		}

		#reverse the vertRow if it was flipped
		if ($firstCount > $lastCount)
		{
			#lxout("[->] I'm reversing this current vertRow");
			@currentRow = reverse @currentRow;
		}

		lxout("- - -vertRow # ($vertRowCount) = @currentRow");

		#----------------------------------------------------------------------
		#PART 3 : SEE if the user had VERTS selected, and if so, then that means they wanted to run teh script multiple times for this vertRow
		#----------------------------------------------------------------------
		my @cornerVerts;

		#See if any of the selected Verts are on the edgeRows, and if so, remember them as cornerVerts
		if (($#currentRow > 2) && ($#selectedVerts > -1) && ($#selectedVerts <= (($#vertRowList+1)*2)))
		{
			if ($vertRowCount < 1) {lxout("[->] The user had some Verts selected, and not too many, so I'm going to see which selected verts are on this vertRow");} #the IF statement is only to print this ONCE

			foreach my $vert (@selectedVerts)
			{
				#lxout("vert = $vert");
				my $currentRowCount=0;
				foreach my $vert2 (@currentRow)
				{
					if ($vert == $vert2)
					{
						#check to make sure that the user didn't accidentally select the FIRST VERT

						if (($currentRowCount != 0) && ($currentRowCount != $#currentRow))
						{
							#lxout("This cornerVert ($vert) is in the vertRow in this position($vertRowCount)");
							push(@cornerVerts, "$vert,$currentRowCount");
							last;
						}
					}
					$currentRowCount++;
				}
			}
			#lxout("vertRow ($vertRowCount)'s cornerVerts = @cornerVerts");

			#Time to reorder the cornerVert List if they weren't selected in the proper order (if there's more than one cornerVert)
			if ($#cornerVerts > 0)
			{
				my @cvSplit0 = split(/,/, @cornerVerts[0]);
				my @cvSplit1 = split(/,/, @cornerVerts[1]);
				if (@cvSplit1[1] < @cvSplit0[1])
				{
					lxout("[->] vertRow # ($vertRowCount) The cornerVerts weren't selected in the right order, so I'm reversing them.");
					#lxout("        before: @cornerVerts");
					my $cornerVert2 =splice(@cornerVerts, 1,1);
					unshift(@cornerVerts,$cornerVert2);
					#lxout("       after: @cornerVerts");
				}
			}
		}
		else
		{	lxout("[->] I didn't check for corner verts because:(NONE?)(TOO MANY?)(TOO FEW EDGES?)");	}




		#----------------------------------------------------------------------
		#PART 4 : RUN the smartquad tools on this vertRow
		#----------------------------------------------------------------------

		#Now run the script in a special LOOPED way if the user had selected some corner verts
		if ($#cornerVerts != -1)
		{
			lxout("[->] vertRow # ($vertRowCount) is a (-LOOPING-) cornerVert vertRow");

			#PART 1 ---------------------------------------------------------------------------------------------------
			#PART 1A : connect to verts : break the vertRow into (TWO) vertLists, but only if CONNECT's being used.
			if (@ARGV[0] eq "connect")
			{
				if ($#cornerVerts > 0)
				{
					lxout("connect is on");
					my @cvSplit = split(/,/, @cornerVerts[1]);
					our @connectToVerts = @currentRow[ (@cvSplit[1]+1) .. ( $#currentRow ) ];
					@currentRow = @currentRow[ 0 .. (@cvSplit[1]) ];

					#lxout("connectToVerts = @connectToVerts ");
					#lxout("AFTER : currentRow = @currentRow");
				}
			}
			#PART 1B : start verts
			my @cvSplit = split(/,/, @cornerVerts[0]);
			our @startVerts = @currentRow[ 0 .. (@cvSplit[1]-1) ];
			@startVerts = reverse @startVerts;
			@currentRow = @currentRow[(@cvSplit[1]) .. $#currentRow ];
			our $extendVertCount = $#currentRow;

			if ((@ARGV[0] eq "connect") && ($#startVerts != $#connectToVerts)) {die("You're trying to use CONNECT, but there aren't an equal number of *(start-edges)* and *(connect-to-edges)* selected");}

			#lxout("startVerts = @startVerts ");
			#lxout("AFTER : currentRow = @currentRow");

			#PART 2 ---------------------------------------------------------------------------------------------------
			#PART 2A :  LAUNCH THE smartQuad tool on the first row
			unshift(@currentRow,@startVerts[0]);
			if (@ARGV[0] eq "connect"){ push(@currentRow,@connectToVerts[0]);	}
			@vertsel = @currentRow;
			&smartQuad;
			if (@ARGV[0] eq "connect") {	&connect;	}

			#PART 2B : LAUNCH the smartquad tool for every LOOP
			for (my $i=1; $i<@startVerts; $i++)
			{
				#add the verts we wanna EXTEND to the vertlist
				our @lastRow = @currentRow;
				@vertsel = lxq("query layerservice vert.index ? last");
				for (my $i=1; $i<$extendVertCount+1; $i++)
				{
					unshift(@vertsel,(@vertsel[-1] -$i));
					#popup("(i=[$i]<>connect To verts[$extendVertCount]<>vertSel = @vertsel");
				}

				#now we've got to look for the first vert and reorder the vertlist, because it was random.  :(
				my $count = 0;
				my @lastStartVertPos = lxq("query layerservice vert.pos ? @lastRow[0]");
				foreach my $vert (@vertsel)
				{
					my @pos = lxq("query layerservice vert.pos ? $vert");
					my $diff = ((@pos[0]-@lastStartVertPos[0])+(@pos[1]-@lastStartVertPos[1])+(@pos[2]-@lastStartVertPos[2]));
					#lxout("vert=$vert<><>lastStartVert=@lastRow[0]<><>diff=$diff");
					if (abs($diff) < .0000000000001)
					{
						#lxout("This vert is the startVert[$vert]");
						our $startVert  = $vert;
						splice(@vertsel, $count,1);
						last;
					}
					$count++;
				}
				#popup("startVert = $startVert<>vertSel = @vertsel");

				#Now reorder the vertlist
				unshift(@vertsel,$startVert);

				#add the connect To vert to the vertlist
				if (@ARGV[0] eq "connect"){ push(@vertsel,@connectToVerts[$i]);	}

				#add the startVert to the vertlist
				unshift(@vertsel,@startVerts[$i]);

				#popup("vertSel = @vertsel");
				@currentRow = @vertsel;

				#Time to run the smartQuad scripts
				&smartQuad;
				if (@ARGV[0] eq "connect") {	&connect;	}
			}
		}
		#Else run the script normally
		else
		{
			lxout("[->]This vertRow($vertRowCount) is a (-NORMAL-) vertRow");
			@vertsel = @currentRow;
			&smartQuad;
			if (@ARGV[0] eq "connect") {	&connect;	}
		}

		#update the vertRowCount
		$vertRowCount++;
	}
}








#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#----------------------------------------SMART QUAD---------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub smartQuad()
{
	lxout("[->] SMARTQUAD subroutine");
	#this will check all the selected verts and specialize the first two
	our @firstVertPos = lxq("query layerservice vert.pos ? $vertsel[0]");
	our @newSelVertPos = lxq("query layerservice vert.pos ? $vertsel[1]");
	our $lastVert;
	our @finalVertPos;

	#deselect all verts and then only select the verts for the proper halves of the model (and skip the 1st vert of course)
	lx("select.drop vertex");
	for (my $i =1; $i<@vertsel; $i++)
	{
		lx("!!select.element [$mainlayer] vertex add index:$vertsel[$i]");
	}

	#this will check the displacement between the verts
	#lxout("@firstVertPos /// @newSelVertPos");
	my @disp = (@firstVertPos[0] - @newSelVertPos[0], @firstVertPos[1] - @newSelVertPos[1], @firstVertPos[2] - @newSelVertPos[2]);

	#CHECK IF CONNECT is on and deselect last vert (and then convert to edges)
	if (@ARGV[0] eq "connect") {lx("!!select.element [$mainlayer] vertex remove index:$vertsel[-1]");}
	else{
		#safety check to make sure that the first edge actually exists!  (i put it in with the CONNECT check, because it wouldn't work properly on the smart quad routines that use connect"
		my @test = lxq("query layerservice edge.vertList ? @vertsel[1],@vertsel[2]");
		if (@test[0] eq ""){	die("This script works off of edge extensions, and apparently the first edge doesn't actually exist and so it can't extend");	}
	}

	lx("!!select.convert edge");
	lx("select.edge remove poly more 1");

	#edge extend
	lx( "tool.set edge.extend on" );
	lx("tool.reset");
	lx( "tool.attr edge.extend offX {@disp[0]}" );
	lx( "tool.attr edge.extend offY {@disp[1]}" );
	lx( "tool.attr edge.extend offZ {@disp[2]}" );
	lx( "tool.doapply" );
	lx( "tool.set edge.extend off" );
	lx("select.drop polygon");
	lx("select.drop vertex"); #go back to vert selection mode
}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------CONNECT-------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub connect()
{
	#------------------------------------------------------------------------------------------
	#FIND FARTHEST POINT ON NEW EDGE ROW
	#------------------------------------------------------------------------------------------
	lxout("[->] Using CONNECT subroutine");
	lx( "select.typeFrom {edge;polygon;item;vertex} 1" );
	#Get and edit the original edge list *throw away all edges that aren't in mainlayer* (FIXED FOR MODO2)
	our @origEdgeList = lxq("query layerservice selection ? edge");
	my @tempEdgeList;
	foreach my $edge (@origEdgeList){	if ($edge =~ /\($mainlayer/){	push(@tempEdgeList,$edge);		}	}
	#[remove layer info] [remove ( ) ]
	@origEdgeList = @tempEdgeList;
	s/\(\d{0,},/\(/  for @origEdgeList;
	tr/()//d for @origEdgeList;

	our @origEdgeList_edit = @origEdgeList;
	our @vertRow = split(/,/, @origEdgeList_edit[0]);
	shift(@origEdgeList_edit);
	&sortRow;

	#lxout("vertRow = @vertRow");

	#NOW that the edgerow is sorted, let's see which end of the row is the farthest
	my @newRowFirstVertPos = lxq("query layerservice vert.pos ? @vertRow[0]");
	my @newRowLastVertPos = lxq("query layerservice vert.pos ? @vertRow[-1]");
	my $newRowFirstVertDiff = ((@newRowFirstVertPos[0]-@firstVertPos[0])+(@newRowFirstVertPos[1]-@firstVertPos[1])+(@newRowFirstVertPos[2]-@firstVertPos[2]));
	my $newRowLastVertDiff = ((@newRowLastVertPos[0]-@firstVertPos[0])+(@newRowLastVertPos[1]-@firstVertPos[1])+(@newRowLastVertPos[2]-@firstVertPos[2]));

	if (abs($newRowFirstVertDiff) > abs($newRowLastVertDiff))
	{
		#lxout("firstVert[@vertRow[0]] diff = $newRowFirstVertDiff");
		our $farthestNewVert = @vertRow[0];
	}
	else
	{
		#lxout("lastVert[@vertRow[-1]] diff = $newRowLastVertDiff");
		our $farthestNewVert = @vertRow[-1];
	}

	#------------------------------------------------------------------------------------------
	#NOW TAPERING THE NEW EDGES TO LINE UP
	#------------------------------------------------------------------------------------------
	my @farthestNewVertPos = lxq("query layerservice vert.pos ? $farthestNewVert");

	#finding displacement between farthest vert and final vert
	my @connectDisp = displacement($farthestNewVert,$vertsel[-1]);
	#lxout("farthest vert=$farthestNewVert....final vert=@vertsel[-1]"); #####
	#lxout("connect displacement = @connectDisp"); #
	@connectDisp[0,1,2] = (@connectDisp[0]*-1,@connectDisp[1]*-1,@connectDisp[2]*-1);

	#turning MOVE tool on and moving to match up
	lx("tool.set xfrm.move on");
	lx("tool.reset");
	lx("tool.set falloff.linear on");
	lx("tool.setAttr falloff.linear endX {@firstVertPos[0]}");
	lx("tool.setAttr falloff.linear endY {@firstVertPos[1]}");
	lx("tool.setAttr falloff.linear endZ {@firstVertPos[2]}");
	lx("tool.setAttr falloff.linear startX {@farthestNewVertPos[0]}");
	lx("tool.setAttr falloff.linear startY {@farthestNewVertPos[1]}");
	lx("tool.setAttr falloff.linear startZ {@farthestNewVertPos[2]}");

	lx("tool.setAttr xfrm.move X {@connectDisp[0]}");
	lx("tool.setAttr xfrm.move Y {@connectDisp[1]}");
	lx("tool.setAttr xfrm.move Z {@connectDisp[2]}");
	lx("!!tool.doApply");


	#turning MOVE tool and LINEAR falloff off
	lx("tool.set xfrm.move off");
	lx("tool.set falloff.linear off");
}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#----------------------------------------SUB ROUTINES-------------------------------------------
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

sub displacement
{
	my ($vert1,$vert2) = @_;
	#lxout("disp vert1,vert2 == $vert1,$vert2");

	my @vertPos1 = lxq("query layerservice vert.pos ? $vert1");
	my @vertPos2 = lxq("query layerservice vert.pos ? $vert2");

	my $disp0 = @vertPos1[0] - @vertPos2[0];
	my $disp1 = @vertPos1[1] - @vertPos2[1];
	my $disp2 = @vertPos1[2] - @vertPos2[2];

	my @disp = ($disp0,$disp1,$disp2);
	return @disp;
}


sub fakeDistance
{
	my ($vert1,$vert2) = @_;
	my @vertPos1 = lxq("query layerservice vert.pos ? $vert1");
	my @vertPos2 = lxq("query layerservice vert.pos ? $vert2");

	my $disp0 = @vertPos1[0] - @vertPos2[0];
	my $disp1 = @vertPos1[1] - @vertPos2[1];
	my $disp2 = @vertPos1[2] - @vertPos2[2];

	my $fakeDist = (abs($disp0)+abs($disp1)+abs($disp2));
	return $fakeDist;
}



#-----------------------------------------------------------------------------------------------------------
#sort Rows subroutine
#-----------------------------------------------------------------------------------------------------------
sub sortRow
{
	#this first part is stupid.  I need it to loop thru one more time than it will:
	my @loopCount = @origEdgeList_edit;
	unshift (@loopCount,1);
	#lxout("How many fucking times will I go thru the loop!? = $#loopCount");

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
#------------[SCRIPT IS FINISHED] SAFETY REIMPLEMENTING-----------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#merge vertices
lx("select.drop vertex");
lx("!!vert.merge fixed dist:[1 um]");

#put the selection mode back to edges if it was being used
if ($selectMode eq "edge"){lx("select.drop edge");}

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







