#perl
#BY: Seneca Menard
#version 0.9 (modo2)
#This script is to expand or contract the edge rows selected.  To expand, just run the script.  To contract, run the script with "contract" appended.
#(8-14-05) This script remembers selection order now.
#(5-25-06) This script now handles edges better

my $mainlayer = lxq("query layerservice layers ? main");

#-----------------------------------------------------------------------------------------------------------
#EDGE SELECTION ROW CONTRACT
#-----------------------------------------------------------------------------------------------------------
if( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ){	lxout("[->] EDGE MODE");}
else{	die("You must be in edge mode");}


if (@ARGV[0] eq "contract")
{
	#Get and edit the original edge list *throw away all edges that aren't in mainlayer* (FIXED FOR MODO2)
	our @origEdgeList = lxq("query layerservice selection ? edge");
	my @tempEdgeList;
	foreach my $edge (@origEdgeList){	if ($edge =~ /\($mainlayer/){	push(@tempEdgeList,$edge);		}	}
	#[remove layer info] [remove ( ) ]
	@origEdgeList = @tempEdgeList;
	s/\(\d{0,},/\(/  for @origEdgeList;
	tr/()//d for @origEdgeList;

	our @origEdgeList_edit = @origEdgeList;
	our @vertRow;
	our @vertRowList;

	our @vertList;
	our %vertPosTable;
	our %endPointVectors;

	our @vertMergeOrder;
	our @edgesToRemove;
	our $removeEdges = 0;


	#Begin sorting the [edge list] into different [vert rows].
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
	lxout("- - -DONE: There are ($#vertRowList+1) edge rows total");
	for ($i = 0; $i < ($#vertRowList + 1) ; $i++) {	lxout("- - -vertRow # ($i) = @vertRowList[$i]"); }




	#Now look at the end edges and deselect the end edges.
	foreach my $vertRow (@vertRowList)
	{
		my @vertRowList = split (/[^0-9]/, $vertRow);
		lxout("@vertRowList[0],@vertRowList[1] <><> @vertRowList[-1],@vertRowList[-2]");
		lx("select.element [$mainlayer] edge remove index:[@vertRowList[0]] index2:[@vertRowList[1]]");
		lx("select.element [$mainlayer] edge remove index:[@vertRowList[1]] index2:[@vertRowList[0]]");
		lx("select.element [$mainlayer] edge remove index:[@vertRowList[-1]] index2:[@vertRowList[-2]]");
		lx("select.element [$mainlayer] edge remove index:[@vertRowList[-2]] index2:[@vertRowList[-1]]");
	}
}


#-----------------------------------------------------------------------------------------------------------
#EDGE SELECTION ROW EXPAND
#-----------------------------------------------------------------------------------------------------------
elsif (@ARGV[0] ne "contract")
{
	#Get and edit the original edge list *throw away all edges that aren't in mainlayer* (FIXED FOR MODO2)
	my @origEdgeList = lxq("query layerservice selection ? edge");
	my @tempEdgeList;
	foreach my $edge (@origEdgeList){	if ($edge =~ /\($mainlayer/){	push(@tempEdgeList,$edge);		}	}
	#[remove layer info] [remove ( ) ]
	@origEdgeList = @tempEdgeList;
	s/\(\d{0,},/\(/  for @origEdgeList;
	tr/()//d for @origEdgeList;


	#Convert the original edge selection to a vert array for easy use
	my @origEdgeVerts;
	foreach my $edge (@origEdgeList)
	{
		my @tempVerts = split (/[^0-9]/, $edge);
		push (@origEdgeVerts,@tempVerts);
	}
	#lxout("origEdgeVerts ($#origEdgeVerts+1) = @origEdgeVerts");



	#Backup original edge list and select row
	lx("select.editSet orig add");
	lx("select.loop");
	lx("select.useSet orig deselect");


	#Get the loop edge selection *throw away all edges that aren't in mainlayer* (FIXED FOR MODO2)
	my @rowEdgeList = lxq("query layerservice selection ? edge");
	my @tempEdgeList;
	foreach my $edge (@rowEdgeList){	if ($edge =~ /\($mainlayer/){	push(@tempEdgeList,$edge);		}	}
	#[remove layer info] [remove ( ) ]
	@rowEdgeList = @tempEdgeList;
	s/\(\d{0,},/\(/  for @rowEdgeList;
	tr/()//d for @rowEdgeList;
	#lxout("rowEdgeList = @rowEdgeList");


	#Now go thru and find the touching edges
	my @touchingEdges;
	foreach my $edge (@rowEdgeList)
	{
		my @tempVerts = split (/[^0-9]/, $edge);
		foreach my $vert (@origEdgeVerts)
		{
			if ((@tempVerts[0] == $vert) || (@tempVerts[1] == $vert))
			{
				#lxout("This vert ($vert) is an end vert and this edge(@tempVerts) is touching it");
				my $tempVertsString = "@tempVerts[0] @tempVerts[1]";
				push @touchingEdges,$tempVertsString;
			}
		}
		#lxout("touchingEdges($#touchingEdges+1) = @touchingEdges");
	}

	#Now select the the original and touching edges and remove all the edgeNaming
	lx("select.drop edge");

	#lx("select.useSet orig select");		#TEMP  This is faster, but loses the selection order
	foreach my $edge (@origEdgeList)	#TEMP  This is slower, but keeps the selection order
	{
		my @tempVerts = split (/[^0-9]/, $edge);
		lx("select.element [$mainlayer] edge add index:[@tempVerts[0]] index2:[@tempVerts[1]]");
	}

	foreach my $edge (@touchingEdges)
	{
		my @tempVerts = split (/[^0-9]/, $edge);
		lx("select.element [$mainlayer] edge add index:[@tempVerts[0]] index2:[@tempVerts[1]]");
	}

	lx("select.editSet orig remove");
}


#-----------------------------------------------------------------------------------------------------------
#VERT SELECTION ROW EXPAND
#-----------------------------------------------------------------------------------------------------------
#if (@ARGV[0] eq "contract")
#{
	##Get the original vert selection and back it up
	#my @origVertList = lxq("query layerservice verts ? selected");
	#lxout("origVertList = @origVertList");
	#lx("select.editSet orig add");
#
	##Get the row loop vert list
	#lx("select.loop");
	#lx("select.useSet orig deselect");
	#my @rowVertList = lxq("query layerservice verts ? selected");
	#lxout("rowVertList = @rowVertList");
#}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#--------------------------------------------SUBROUTINES--------------------------------------------
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

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

#-----------------------------------------------------------------------------------
#SORT ROWS subroutine
#-----------------------------------------------------------------------------------
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
