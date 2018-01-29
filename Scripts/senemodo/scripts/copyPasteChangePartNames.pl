#perl
#ver 1.1
#author : Seneca Menard
#This script will copy and paste your currently selected polys and if there are any POLYGON PARTS applied to those polys, it'll assign a random new part name to each of them.  This script is for copying/pasting geometry and having the new geometry not use the same part names as the original geometry and so when you select the rest of the parts (with my selectRest.pl script), you won't select the old geometry on accident.

#SCRIPT ARGUMNENTS :
# applyOnePartToAll : By default, the script is a bit slow to run because changing preexisting part names is a slow procedure because of a lot of poly deselecting and reselecting.  Plus, say you had 3 polys selected and 1 had no parts assigned and 2 and 3 had unique parts assigned.  If you selected one of those polys later on and ran the selectRest.pl script of mine, it'd only grab one of those 3 polys because their part names are not the same.  So with this script command, it'll apply one part name to all 3 polys so it's faster to run and you'll get all 3 when you run selectRest.pl.   But don't forget, if you wanted to keep your polys separate by parts, they won't be separate anymore if you run this script with this cvar...
# move : to have the script turn on the move tool when it's done pasting
# TransformMove : to have the script turn on the TransformMove tool when it's done pasting
# Transform : to have the script turn on the Transform tool when it's done pasting

#(1-24-11 fix) : 501 makes it so that poly part assignments don't change poly indices and so i had to remove my indice correction if you're running that version of modo.

my $modoVer = lxq("query platformservice appversion ?");

foreach my $arg (@ARGV){
	if		($arg eq "applyOnePartToAll")	{	our $applyOnePartToAll = 1; 	}
	elsif	($arg eq "move")				{	our $move = 1;					}
	elsif	($arg eq "TransformMove")		{	our $newMove = 1;				}
	elsif	($arg eq "Transform")			{	our $transform == 1;			}
}

srand;
my $partName;
my @alphabet = (0,1,2,3,4,5,6,7,8,9,0,"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z");
my $mainlayer = lxq("query layerservice layers ? main");
my @changedPolys;
if ((lx("select.typeFrom {polygon;item;vertex;edge}") == 1) && (lxq("select.count polygon ?") > 0)){
	lx("select.copy");
	lx("select.all");
	lx("select.paste");
	lx("select.invert");

	if ($applyOnePartToAll == 1){
		for (my $i=0; $i<12; $i++){$partName .= @alphabet[rand(35)];}
		lx("poly.setPart {$partName}");
	}else{
		my @polys = lxq("query layerservice polys ? selected");  #not sorting for the returnCorrectIndices sub because the paste sorts 'em for me
		my %polyPartTable;

		foreach my $poly (@polys){
			my $part = lxq("query layerservice poly.part ? $poly");
			if (($part ne "Default") && ($part ne "")){
				push(@{$polyPartTable{$part}},$poly);
			}
		}

		if ((keys %polyPartTable) > 0){
			foreach my $key (keys %polyPartTable){
				if ($modoVer < 500){returnCorrectIndice(\@{$polyPartTable{$key}},\@changedPolys);}

				lx("select.drop polygon");
				lx("select.element $mainlayer polygon add $_") for @{$polyPartTable{$key}};
				$partName = "";
				for (my $i=0; $i<12; $i++){$partName .= @alphabet[rand(35)];}
				lx("poly.setPart {$partName}");
			}

			lx("select.drop polygon");
			my $polyCount = lxq("query layerservice poly.n ? all");
			for (my $i=$polyCount-@polys; $i<$polyCount; $i++){
				lx("select.element $mainlayer polygon add $i");
			}
		}
	}

	if		($move == 1)		{lx("!!tool.set xfrm.move on");}
	elsif	($newMove == 1)		{lx("tool.set TransformMove on");}
	elsif	($transform == 1)	{lx("tool.set Transform on");}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RETURN CORRECT INDICES SUB : (this is for finding the new poly indices when they've been corrupted because of earlier poly indice changes)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : returnCorrectIndice(\@currentPolys,\@changedPolys);
#notes : both arrays must be numerically sorted first.  Also, it'll modify both arrays with the new numbers
sub returnCorrectIndice{
	my @firstElems;
	my @lastElems;
	my %inbetweenElems;
	my @newList;

	#1 : find where the elements go in the old array
	foreach my $elem (@{@_[0]}){
		my $loop = 1;
		my $start = 0;
		my $end = $#{@_[1]};

		#less than the array
		if (($elem == 0) || ($elem < @{@_[1]}[0])){
			push(@firstElems,$elem);
		}
		#greater than the array
		elsif ($elem > @{@_[1]}[-1]){
			push(@lastElems,$elem);
		}
		#in the array
		else{
			while($loop == 1){
				my $currentPoint = int((($start + $end) * .5 ) + .5);

				if ($end == $start + 1){
					$inbetweenElems{$elem} = $currentPoint;
					$loop = 0;
				}elsif ($elem > @{@_[1]}[$currentPoint]){
					$start = $currentPoint;
				}elsif ($elem < @{@_[1]}[$currentPoint]){
					$end = $currentPoint;
				}else{
					popup("Oops.  The returnCorrectIndice sub is failing with this element : ($elem)!");
				}
			}
		}
	}

	#2 : now get the new list of elements with their new names
	#inbetween elements
	for (my $i=@firstElems; $i<@{@_[0]} - @lastElems; $i++){
		@{@_[0]}[$i] = @{@_[0]}[$i] - ($inbetweenElems{@{@_[0]}[$i]});
	}
	#last elements
	for (my $i=@{@_[0]}-@lastElems; $i<@{@_[0]}; $i++){
		@{@_[0]}[$i] = @{@_[0]}[$i] - @{@_[1]};
	}

	#3 : now update the used element list
	my $count = 0;
	foreach my $elem (sort { $a <=> $b } keys %inbetweenElems){
		splice(@{@_[1]}, $inbetweenElems{$elem}+$count,0, $elem);
		$count++;
	}
	unshift(@{@_[1]},@firstElems);
	push(@{@_[1]},@lastElems);
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
