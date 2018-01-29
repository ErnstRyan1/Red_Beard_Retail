#perl
#AUTHOR: Seneca Menard

lxout("EDGE TO CURVE SCRIPT");

if(lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ))
{
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
		#CREATE AND EDIT the edge list.  [remove ( )] (FIXED FOR M2.  I'm not using the multilayer query anymore)
		#---------------------------------------------------------------------------------------------------------
		@origEdgeList = lxq("query layerservice edges ? selected");
		s/\(// for @origEdgeList;
		s/\)// for @origEdgeList;
		@origEdgeList_edit = @origEdgeList;

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
			lx("poly.makeCurveOpen");
		}

		#remove the original edges #TEMP.  This is for removing edges on patches.
		#lx("select.type edge");
		#lx("remove");

		#put the selection mode back
		lx("select.drop edge");
	}
}



#***********************************************************************************
#*******************************SUBROUTINES***********************************
#***********************************************************************************
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

