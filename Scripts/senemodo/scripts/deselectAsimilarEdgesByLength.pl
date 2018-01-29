#perl
#ver 0.52
#author : Seneca Menard
#This script will look at your selected edges and deselect all of them that are not similar enough to the length of the last one that's selected.  You can type in the similarity amount in the popup window.  (so if your last edge is 2m long and you want to deselect all edges that are smaller than 1m or bigger than 3m, you type in 50, which would be 50% of the length of the last selected edge.

userValueTools(seneEdgeSelectPercentage,float,config,"If the last selected edge \nwere the deciding edge \nlength, what percentage of \nthat edge's size would you \ndefine as the cutoff \npoint for allowed selected \nedges?:","","","",xxx,xxx,"",50);
lx("user.value seneEdgeSelectPercentage");
my $percentage = lxq("user.value seneEdgeSelectPercentage ?") or die("The user hit the cancel button");
my $mainlayer = lxq("query layerservice layers ? main");
my @edges = lxq("query layerservice selection ? edge");
my @initialEdgeVerts = split (/[^0-9]/, $edges[-1]);
my $initialEdgeLength = lxq("query layerservice edge.length ? ($initialEdgeVerts[2],$initialEdgeVerts[3])");
my $edgeLengthDiff = $initialEdgeLength * ($percentage/100);

my $printA = $initialEdgeLength - $edgeLengthDiff;
my $printB = $initialEdgeLength + $edgeLengthDiff;
lxout("
==================================
Percentage = $percentage %\n
==================================
   The last selected edge ($initialEdgeVerts[2],$initialEdgeVerts[3]) length = $initialEdgeLength\n
   So all the other edges must be :\n
   greater than : $printA\n
   less than : $printB\n
");


lx("select.drop edge");
foreach my $edge (@edges){
	my @verts = split (/[^0-9]/, $edge);
	my $edgeLength = lxq("query layerservice edge.length ? ($verts[2],$verts[3])");
	my $edgeLengthSimilarity = abs( $edgeLength - $initialEdgeLength );

	if ($edgeLengthSimilarity < $edgeLengthDiff){
		lx("select.element $mainlayer edge add $verts[2] $verts[3]");
	}
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