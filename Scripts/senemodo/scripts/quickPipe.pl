#perl
#AUTHOR: Seneca Menard
#version 1.01
#this script is to create a pipe using the selected points.  It uses the thickness and number of segments of the last created TUBE PRIMITIVE
#(1-1-07 : new feature) : It now works with edgeloops, so you can have say, 6 edgerows selected and it will create a pipe out of each one.
#(12-18-08 fix) : I went and removed the square brackets so that the numbers will always be read as metric units and also because my prior safety check would leave the unit system set to metric system if the script was canceled because changing that preference doesn't get undone if a script is cancelled.


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#STARTUP
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
my $mainlayer = lxq("query layerservice layers ? main");
#symm
our $symmAxis = lxq("select.symmetryState ?");
if ($symmAxis ne "none"){
	lx("select.symmetryState none");
}

#Remember what the workplane was and turn it off
our @WPmem;
@WPmem[0] = lxq ("workPlane.edit cenX:? ");
@WPmem[1] = lxq ("workPlane.edit cenY:? ");
@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
@WPmem[3] = lxq ("workPlane.edit rotX:? ");
@WPmem[4] = lxq ("workPlane.edit rotY:? ");
@WPmem[5] = lxq ("workPlane.edit rotZ:? ");
lx("workPlane.reset ");



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#EDGE MODE
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if (lxq( "select.typeFrom {edge;polygon;item;vertex} ?" )){
	my @edges = lxq("query layerservice edges ? selected");
	sortRowStartup(edgesSelected,@edges);

	#Run the peeler script on each edge Row.
	foreach my $vertRow (@vertRowList){
		my @verts = split (/[^0-9]/, $vertRow);
		buildPipe(@verts);
	}
}



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#VERT MODE
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
else{
	if (lxq("query layerservice vert.n ? selected") != 0){
		my @verts =lxq("query layerservice  verts ? selected");
		buildPipe(@verts);
	}
}



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#BUILD PIPE SUBROUTINE
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub buildPipe{
	my @verts = @_;
	lx("tool.set prim.tube on");
	lx("tool.setAttr prim.tube mode add");
	for (my $i=0; $i<@verts; $i++){
		my @pos = lxq("query layerservice vert.pos ? @verts[$i]");
		my $u=$i+1;
		lx("tool.setAttr prim.tube number {$u}");
		lx("tool.setAttr prim.tube ptX {@pos[0]}");
		lx("tool.setAttr prim.tube ptY {@pos[1]}");
		lx("tool.setAttr prim.tube ptZ {@pos[2]}");
	}
	lx("tool.doApply");
	lx("tool.set prim.tube off");
}



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CLEANUP
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#symmetry restore
if ($symmAxis ne "none"){
	lxout("turning symm back on ($symmAxis)"); lx("select.symmetryState $symmAxis");
}

#Put the workplane back
lx("workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");








#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------SUBROUTINES------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SORT ROWS SETUP subroutine
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SORT ROWS subroutine
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
