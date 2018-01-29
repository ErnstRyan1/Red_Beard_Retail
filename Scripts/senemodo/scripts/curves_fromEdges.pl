#perl
#ver 1.1
#author : Seneca Menard
#This script will convert your edge or poly-border selection into curves. (and if you're in vert mode, it'll do what modo normally does)

#11-17-11 : changed the script so it doesn't use cvars anymore and instead has a popup gui.  Also put in the ability to run it on edges or edgeloops.

#script cvar initializations :
my $edgeOrEdgeLoop = popupMultChoice("Create Curves From Edges or EdgeLoops?","Edges;EdgeLoops",0);
my $openOrClosed = popupMultChoice("Curves Are Open or Closed?","Open;Closed",0);
if ($openOrClosed eq "Closed")	{	our $arg = "poly.makeCurveClosed";	}
else							{	our $arg = "poly.makeCurveOpen";	}

lxout("edgeOrEdgeLoop = $edgeOrEdgeLoop");
lxout("openOrClosed = $openOrClosed");

#setup
my $mainlayer = lxq("query layerservice layers ? main");
our %edges;


if (lxq("select.typeFrom {vertex;edge;polygon;item} ?")){lx("$arg");}
elsif ( (lxq("select.typeFrom {edge;polygon;item;vertex} ?")) || (lxq("select.typeFrom {polygon;item;vertex;edge} ?")) ){
	if (lxq("select.typeFrom {polygon;item;vertex;edge} ?")){
		lx("select.drop edge");
		lx("select.type polygon");
		lx("select.boundary");
	}

	my @firstLastEdges = createPerLayerElemList(edge,\%edges);
	printHashTableArray(\%edges,edges);
	foreach my $layer (keys %edges){curveCreate($layer);}
}else{
	die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");
}

sub curveCreate{
	my $layerName = lxq("query layerservice layer.name ? @_[0]");

	#run for individual edges
	if ($edgeOrEdgeLoop eq "Edges"){
		lxout("INDIVIDUAL EDGES");
		foreach my $edge (@{$edges{@_[0]}}){
			lxout("edge = $edge");
			my @verts = split (/[^0-9]/, $edge);
			lx("select.drop vertex");
			lx("select.element {@_[0]} vertex add $_") for @verts;
			lx("$arg");
		}
	}
	#run for edge loops
	else{
		lxout("EDGE LOOPS");
		sortRowStartup(dontFormat,@{$edges{@_[0]}});
		foreach my $vertRow (@vertRowList){
			my @verts = split (/[^0-9]/, $vertRow);
			lx("select.drop vertex");
			lx("select.element {@_[0]} vertex add $_") for @verts;
			lx("$arg");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE A PER LAYER ELEMENT SELECTION LIST ver 2.0! (retuns first and last elems, and ordered list for all layers)  (THIS VERSION DOES SUPPORT EDGES!)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my @firstLastPolys = createPerLayerElemList(poly,\%polys);
sub createPerLayerElemList{
	my $hash = @_[1];
	my @totalElements = lxq("query layerservice selection ? @_[0]");
	if (@totalElements == 0){die("\\\\n.\\\\n[---------------------------------------------You don't have any @_[0]s selected and so I'm cancelling the script.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

	#build the full list
	foreach my $elem (@totalElements){
		$elem =~ s/[\(\)]//g;
		my @split = split/,/,$elem;
		if (@_[0] eq "edge"){
			push(@{$$hash{@split[0]}},@split[1].",".@split[2]);
		}else{
			push(@{$$hash{@split[0]}},@split[1]);
		}

	}

	#return the first and last elements
	return(@totalElements[0],@totalElements[-1]);
}

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



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#PRINT ALL THE ELEMENTS IN A HASH TABLE FULL OF ARRAYS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#usage : printHashTableArray(\%table,table);
sub printHashTableArray{
	lxout("          ------------------------------------Printing @_[1] list------------------------------------");
	my $hash = @_[0];
	foreach my $key (sort keys %{$hash}){
		lxout("          KEY = $key");
		for (my $i=0; $i<@{$$hash{$key}}; $i++){
			lxout("             $i = @{$$hash{$key}}[$i]");
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


##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#POPUP MULTIPLE CHOICE (ver 2)
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#USAGE : my $answer = popupMultChoice("question name","yes;no;maybe;blahblah",$defaultChoiceInt);
sub popupMultChoice{
	if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog2") == 1){lx("user.defDelete {seneTempDialog2}");	}
	lx("user.defNew name:[seneTempDialog2] type:[integer] life:[momentary]");
	lx("user.def seneTempDialog2 username [$_[0]]");
	lx("user.def seneTempDialog2 list {$_[1]}");
	lx("user.value seneTempDialog2 {$_[2]}");

	lx("user.value seneTempDialog2");
	if (lxres != 0){	die("The user hit the cancel button");	}
	return(lxq("user.value seneTempDialog2 ?"));
}
