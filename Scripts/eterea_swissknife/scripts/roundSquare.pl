#!perl

# AUTHOR : Ariel Chai
# VERSION : 1.0 for modo 3.01 (19.3.2008)
# DESCRIPTION : bevels the side edges of a cube into a cylinder, aimed for parallel dges of equal length but can handle nonperfect ones to a degree.
# USAGE : select two edges and run script.
#   - "@roundSquare.pl ?" : input the round level desired, if none is supplied the default of 2 will be used
#

#---------------------------------------------------------------------------#

# Variables
my $layer = lxq("query layerservice layers ? fg");
my @edges;
my @edgesPos;
my $eDist;
my $roundAmount = 2;

# Main
lxout("-[ script - Init ]-");
&init;			#initilize
&data; 			#sort verts by axis position
&finish;		#restore attributes and finish script

#---------------------------------------------------------------------------#

sub init {
	#get arguements (if supplied)
	if ( ($ARGV[0]) || ($ARGV[0] eq 0) ) {
		lxout("$ARGV[0]");
		$roundAmount = $ARGV[0];
	}

  #terminate if not in edge selection mode 
	if (!lxq("select.typeFrom typelist:{edge;polygon;vertex;item} ? ") ) {
	  die("need to select two edges")
	}
	
	#terminate if number of selected edges isn't 2
	@edges = lxq("query layerservice edges ? selected");
	if ($#edges ne "1") {
	  die("need to select two edges")
	}	
}

sub data {
	#get the avarage position of each edge
	@e1Pos = lxq("query layerservice edge.pos ? @edges[0]");
	@e2Pos = lxq("query layerservice edge.pos ? @edges[1]");

	#calculate the distance between two avarages
	@disp[0,1,2] = ($e2Pos[0]-$e1Pos[0],$e2Pos[1]-$e1Pos[1],$e2Pos[2]-$e1Pos[2]);
	$eDist = sqrt((@disp[0]*@disp[0])+(@disp[1]*@disp[1])+(@disp[2]*@disp[2]));
	$eDist /= 2;

	#bevel at the amount of the distance, with roundAmount
	if (lxq("query platformservice appversion ?") < 300) {
		lx("bevel no"); 
	} else {
		lx("tool.set *.bevel on");
	}
	lx("tool.attr edge.bevel mode inset");
	lx("tool.attr edge.bevel inset $eDist");
	lx("tool.attr edge.bevel level $roundAmount");
	lx("tool.doApply");
	lx("tool.set edge.bevel off 0");
  
	#in case of an imperfect bevel, continue script
	$eLeft = lxq("query layerservice edge.N ? selected");
	if ($eLeft eq "6") {
		&clean;
	}
}

sub clean {
	#convert to poly and back to edge to clean the original edges
	lx("select.convert polygon");
	lx("select.convert edge");
	
	
	#iterate through the edges and find which edges share a poly with more than 4 verticles
	@cEdges = lxq("query layerservice edges ? selected");
	my @lEdges;	
	for ($i = 0; $i <= 3; $i++) {
		@tPolys = lxq("query layerservice edge.polylist ? @cEdges[$i]");
		@tPolysN[0] = lxq("query layerservice poly.numVerts ? @tPolys[0]");
		@tPolysN[1] = lxq("query layerservice poly.numVerts ? @tPolys[0]");
		if ( ($tPolysN[0] > 4) || ($tPolysN[1] > 4) ) {
			push (@lEdges,$cEdges[$i]);
		}
	}
	
  #avarage-join the bottom edges
	for ($i = 0; $i <= 1; $i++) { 
		@tE = lxq("query layerservice edge.vertList ? $lEdges[$i]");
		lx("select.drop edge");
		lx("select.element $layer edge add $tE[0] $tE[1]");
	  lx("vert.join 1");
  }  
}

sub finish {
  #restore edge selection
}