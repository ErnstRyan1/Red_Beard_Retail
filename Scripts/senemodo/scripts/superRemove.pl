#perl
#AUTHOR: Seneca Menard
#version 2.0

#This script does two things depending on whether you're in vert mode or edge mode :
#vert mode : merges all polys touching the selected verts.
#edge mode : merges all polys touching the selected edges, and removes any leftover verts based off of the angle between the two edges touching the vert (if there are only two).

#SCRIPT ARGUMENTS :
# any number : will be the cutoff angle which I use to determine whether to delete the verts or not.  The default will be 30 degrees.  For example : "@superRemove.pl 5" would delete any remaining colinear verts if the angle of the two touching edges is above 5 degrees.
# "skipDelFloatingVerts" : right now the edge remove will leave verts floating in space because of a modo bug and so I delete ALL visible floating verts once the script is done.  If you want to skip that, that's what this cvar is for.


my $cutoffAngle = 30;
foreach my $arg (@ARGV){
	if		($arg =~ /[0-9]/)					{	$cutoffAngle = $arg;			}
	elsif	($arg =~ /skipDelFloatingVerts/i)	{	our $skipDelFloatingVerts = 1;	}
}

my $pi=3.14159265358979323;
my $mainlayer = lxq("query layerservice layers ? main");
my $cutoffDP = $cutoffAngle*($pi/180);	#convert angle to radian.
$cutoffDP = cos($cutoffDP);				#convert radian to DP.
$cutoffDP = -1 + 1 - $cutoffDP;

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#MAIN ROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
if		(lxq("select.typeFrom {vertex;edge;polygon;item} ?")){
																	vertexRemove();
}elsif	(lxq("select.typeFrom {edge;polygon;item;vertex} ?")){
	if ($oldAlgo == 0)	{											edgeRemove();			}
	else				{											edgeRemove_oldAlgo();	}
}elsif	(lxq("select.typeFrom {polygon;item;vertex;edge} ?")){
																	lx("remove");
}else{
	die("You're not in vertex, edge, or polygon mode, so I'm canceling the script.	");
}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#VERTEX REMOVE SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub vertexRemove{
	if (lxq("select.count vertex ?") > 0){
		my @verts = lxq("query layerservice verts ? selected");
		my %polyTable;

		foreach my $vert (@verts){
			my @polyList = lxq("query layerservice vert.polyList ? $vert");
			$polyTable{$_} = 1 for @polyList;
		}

		lx("select.drop polygon");
		lx("select.element $mainlayer polygon add $_") for (keys %polyTable);
		lx("poly.merge");
		lx("select.type vertex");

		my $vertSelCount = lxq("query layerservice vert.n ? selected");
		if ($vertSelCount > 0){lx("delete");}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#EDGE REMOVE SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub edgeRemove{
	if (lxq("select.count edge ?") > 0){
		lx("!!select.convert vertex");
		lx("!!select.editSet remove add");
		lx("!!select.type edge");
		lx("!!remove");

		lx("!!select.drop vertex");
		lx("!!select.useSet remove select");
		lx("!!select.editSet remove remove");

		my @badVerts;
		my @vertsToCheck = lxq("query layerservice verts ? selected");
		foreach my $vert (@vertsToCheck){
			my @vertList = lxq("query layerservice vert.vertList ? $vert");
			if (@vertList == 2){
				my @pos0 = lxq("query layerservice vert.pos ? $vert");
				my @pos1 = lxq("query layerservice vert.pos ? $vertList[0]");
				my @pos2 = lxq("query layerservice vert.pos ? $vertList[1]");
				my @vec1 = unitVector(arrMath(@pos1,@pos0,subt));
				my @vec2 = unitVector(arrMath(@pos2,@pos0,subt));

				my $dp = dotProduct(\@vec1,\@vec2);
				if ($dp < $cutoffDP){
					push(@badVerts,$vert);
				}
			}
		}

		if (@badVerts > 0){
			lx("!!select.drop vertex");
			lx("!!select.element $mainlayer vertex add $_") for @badVerts;
			lx("!!remove");
		}

		if ($skipDelFloatingVerts != 1){
			lx("!!select.drop vertex");
			lx("select.vertex add poly equal 0");
			if (lxq("select.count vertex ?") > 0){lx("delete");}
		}

		lx("select.type edge");
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#OLD EDGE REMOVE OLD SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub edgeRemove_oldAlgo{
	my $selected = lxq("select.count vertex ?");
	lxmonInit($selected*2);
	#if something's selected, delete it, otherwise do nothing
	if ($selected != "0"){
		#if edges are selected, delete the end verts!
		if( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) && ($selected < 200) ){
			lx("select.convert vertex"); #this will remove those dangling edge verts
			lx("select.editSet remove add");
			lx("select.typeFrom {edge;vertex;polygon;item} 1");
			lx("select.editSet remove add");  #assign the selection set

			#-----------------------------------------------------------------------------------------------------------
			#this is a REMOVE rewrite
			#-----------------------------------------------------------------------------------------------------------
			my $looping = 1;
			while ($looping == 1)
			{
				if (!lxmonStep){die("User aborted");}
				lxmonStep;

				#SELECT the edges with the selection set.

				lx("!!select.drop edge");
				lx("!!select.useSet remove select");

				#CREATE the edgelist and stop the script if it found nothing
				our @origEdgeList = lxq("query layerservice edges ? selected");
				if (@origEdgeList < 1){
					$looping = 0;
					last;
				}

				my @polys = lxq("query layerservice edge.polyList ? @origEdgeList[0]");
				if (@polys < 2){
					#not merging, so remove the selSet.
					lx("!!select.editSet remove remove");
				}else{
					#now merge the two polys touching this edge
					lx("select.drop polygon");
					foreach my $poly (@polys){	lx("select.element $mainlayer polygon add $poly");	}
					lx("!!poly.merge");
				}
			}
			#-----------------------------------------------------------------------------------------------------------



			#-----------------------------------------------------------------------------------------------------------
			#THIS WHOLE SEGMENT IS TO FIND THE BAD VERTS THAT ARE LEFT BEHIND
			#-----------------------------------------------------------------------------------------------------------
			lx("select.drop vertex");
			lx("select.useSet remove select");
			lx("select.editSet remove remove");
			lx("select.vertex remove edge more 2");
			lx("select.vertex remove poly less 1");
			lx("select.vertex remove poly more 2");

			my @prunedVerts = lxq("query layerservice verts ? selected");
			if (@prunedVerts > 0){
				my @badPrunedVerts;
				foreach my $prunedVert(@prunedVerts){
					if (!lxmonStep){die("User aborted");}
					lxmonStep;
					lx("select.drop vertex");
					lx("select.element [$mainlayer] vertex add index:[$prunedVert]");
					lx("select.expand");
					my @onlyImportantVerts; #this clears it out
					my @edgeVerts = lxq("query layerservice verts ? selected");

					#this is where we start learning the dist between the endpoints and corner points
					foreach my $edgeVert(@edgeVerts){
						if ($edgeVert != $prunedVert){ #this makes sure to not pay attention to the corner vert
							push(@onlyImportantVerts,$edgeVert);
							#lxout("these are the important Verts:@onlyImportantVerts");
						}
					}
					#actually doing the Dist checks now for the end verts
					my @endVert1 = lxq("query layerservice vert.pos ? @onlyImportantVerts[0]");
					my @endVert2 = lxq("query layerservice vert.pos ? @onlyImportantVerts[1]");
					#lxout("@endVert1");
					#lxout("@endVert2");
					@dist[0,1,2] = (@endVert2[0]-@endVert1[0],@endVert2[1]-@endVert1[1],@endVert2[2]-@endVert1[2]); #3D distance between points
					#lxout("fake dist = @dist");
					#now getting true 3d dist
					@dist[0,1,2] = (@dist[0]*@dist[0],@dist[1]*@dist[1],@dist[2]*@dist[2]);
					my $trueDist = sqrt(@dist[0]+@dist[1]+@dist[2]);
					#lxout("true 3d dist = $trueDist"); #remove sqrt

					#now that we have the dist, we need to check the edge lengths
					lx("select.convert edge");
					my @selectedEdges = lxq("query layerservice edges ? selected");
					my $edge1Length = lxq("query layerservice edge.length ? @selectedEdges[0]");
					my $edge2Length = lxq("query layerservice edge.length ? @selectedEdges[1]");
					my $totalLength = ($edge1Length + $edge2Length);
					#lxout("1=$edge1Length, 2=$edge2Length, total=$totalLength"); #remove sqrt

					#now we'll compare the 2 end verts dist to the length of the 2 edges
					my $distDiff = ($trueDist/$totalLength);
					#lxout("this is the difference between the two lengths $distDiff");

					#now we'll see if the corner vert is a good dist away
					#and check the script arguments.
					if (@ARGV[0] eq "value"){
						#lxout("this is the value you're giving me: @ARGV[1]");
						if ($distDiff > @ARGV[1]){
							push(@badPrunedVerts,$prunedVert);
						}
					}
					else{
						#lxout("you're not giving me a value");
						if ($distDiff > 0.95){
							push(@badPrunedVerts,$prunedVert);
						}
					}
				}
				#lxout("the list of bad pruned verts=@badPrunedVerts");
				#lxout("i'm done");

				#now, we'll delete those bad verts
				lx("select.drop vertex");
				foreach my $badPrunedVert(@badPrunedVerts){
					lx("select.element [$mainlayer] vertex add index:[$badPrunedVert]");
				}
				$vertexselected = lxq("query layerservice vert.n ? selected");
				if ($vertexselected != 0){
					lx("remove");
					lx("select.drop edge");
				}
				else{
					lx("select.drop edge");
				}
			}
			#-----------------------------------------------------------------------------------------------------------
			#DONE
			#-----------------------------------------------------------------------------------------------------------
			else{
				#lxout("i'm dying! i'm dying because the verts need to be left alone!");
				lx("select.typeFrom {edge;vertex;polygon;item} 1");
			}
		}
		elsif( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" )){
			popup("This script is slow for this many edges and so I'm going to fire modo's remove");
			lx("remove");
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#--------------------------------------------SUBROUTINES---------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

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
#DOT PRODUCT subroutine (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	return (	(${$_[0]}[0]*${$_[1]}[0])+(${$_[0]}[1]*${$_[1]}[1])+(${$_[0]}[2]*${$_[1]}[2])	);
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

#-----------------------------------------------------------------------------------------------------------
#POPUP SUBROUTINE
#-----------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
