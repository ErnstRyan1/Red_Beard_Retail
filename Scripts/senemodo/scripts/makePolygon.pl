#perl
#AUTHOR: Seneca Menard
#version 1.6 (modo2)
#This script is just like the regular MAKE POLYGON TOOL, only if you're selecting edges and run the tool, it will deselect non-border edges, so you can really quickly fill mesh holes.
#-The reason why I find this very useful is because I always have open edges on my models, and so selecting ALL border edges and hitting P would be a catastrophe.
#-This script will now makePolygons on random-ordered edgeRows as well.
#-MODO2 FIX. The only thing I fixed was popup.  :|
#-When in edge mode, I ignore all edge loops that only have one edge.
#-(12-15-06) : The script now only pays attention to edges in the main layer (before, it'd just generate garbage if you had other layers' edges selected)

lxout("MAKE POLYGON SCRIPT");

if(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) && lxq( "select.count vertex ?" ))
{
	lx("poly.make auto false");
}

elsif(lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ))
{
	#remove unwanted edges
	lx("select.edge remove poly equal 2");

	#only run script if there are some edges selected.
	if (lxq( "select.count edge ?" ))
	{
		our $mainlayer = lxq("query layerservice layers ? main");
		our @origEdgeList;
		our @origEdgeList_edit;
		our @vertRow;
		our @vertRowList;
		our %usedVerts;
		our $crossRoadsCheck = 0;

		#---------------------------------------------------------------------------------------------------------
		#GENERATE and EDIT the original edge list.  [remove layer info] [remove ( ) ]
		#---------------------------------------------------------------------------------------------------------
		my @tempEdgeList = lxq("query layerservice selection ? edge");
		foreach my $edge (@tempEdgeList){	if ($edge =~ /\($mainlayer/){push(@origEdgeList,$edge);}	}
		s/\(\d{0,},/\(/  for @origEdgeList;
		tr/()//d for @origEdgeList;
		@origEdgeList_edit = @origEdgeList;

		#EDGE CROSSROADS SAFETY CHECK:
		&crossRoadsCheck;
		if ($crossRoadsCheck == 1)
		{
			lx("poly.make auto false");
		}
		else
		{
			while (($#origEdgeList_edit + 1) != 0)
			{
				#this is a loop to go thru and sort the edge loops
				@vertRow = split(/,/, @origEdgeList_edit[0]);
				shift(@origEdgeList_edit);
				&sortRow;

				#take the new edgesort array and add it to the big list of edges.
				push(@vertRowList, "@vertRow");
			}

			my $numVertRows = ($#vertRowList+1);
			lxout("-There are $numVertRows VertRow(s)");

			#---------------------------------------------------------------------------------------------------------
			#NOW MAKE POLYGON for EACH EDGE ROW
			#---------------------------------------------------------------------------------------------------------
			#split the sorted vertRow into an array
			foreach my $vertRow (@vertRowList)
			{
				#build this edgeRow's current Vert List
				my @verts = split (/[^0-9]/, $vertRow);

				#re-select 'em in the proper order
				lx("select.drop vertex");
				foreach my $vert (@verts)
				{
					lx("select.element $mainlayer vertex add $vert");
				}
				if (@verts > 2){
					lx("poly.make auto false");
				}
			}

			#put the selection mode back
			lx("select.drop edge");
		}
	}
}



#***********************************************************************************
#*******************************SUBROUTINES***********************************
#***********************************************************************************
sub crossRoadsCheck
{
	#CREATE and EDIT the original edge list.  [remove layer info] [remove () ]
	my @crossRoadVerts;
	my %vertTable;

	#run every edge's verts into the table.
	foreach my $edge(@origEdgeList)
	{
		#split up the edge into two verts
		my @verts = split(/,/, $edge);

		#add each vert to the vert table
		foreach my $vert (@verts)
		{
			if ($vertTable{$vert}[0] == "")
			{
				$vertTable{$vert}[0] = 1;
			}
			else
			{
				$vertTable{$vert}[0] = ($vertTable{$vert}[0]+1);
			}
		}
	}

	#now check for crossroad verts!
	foreach my $key (%vertTable)
	{
		if ($vertTable{$key}[0] > 2)
		{
			lxout("-There's more than one edgeLoop that are selected and they're touching each other, so I'm ignoring the edgeLoops");
			$crossRoadsCheck =1;
			last;
		}
	}
}




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

#$start = times;
sub timer
{
	$end = times;
	lxout("start=$start");
	lxout("end=$end");
	$time = $end-$start;
	lxout("             (@_ TIMER==>>$time)");
}

sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

