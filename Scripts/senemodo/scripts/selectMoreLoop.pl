#perl
#author : Seneca Menard
#ver 1.0

#This script is to just fire "select.more" repeatedly until it fails to select any new elements.  It's basically just so you can select one-way-loops, or selection patterns such as every other polygon until it can't select anymore.

foreach my $arg (@ARGV){
	if ($arg eq "stopAtNgon")	{our $stopAtNgon = 1;}
}


if		( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )	{ our $selMode = "vertex";	}
elsif	( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ) 	{ our $selMode = "edge";	}
elsif	( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )	{ our $selMode = "polygon";	}
else																{die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

#stop at ngon selection mode.
if ($stopAtNgon == 1){
	if ( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) ){
		my $loop = 1;
		lxmonInit(1000);
		my $counter = 0;
		my $selectionCount = 0;
		while ($loop == 1){
			$counter++;

			lx("select.more") or $loop = 0;

			my @polySel = lxq("query layerservice polys ? selected");
			my @vertCount = lxq("query layerservice poly.vertList ? $polySel[-1]");
			if (@vertCount != 4){
				lx("select.less");
				break;
			}

			if (!lxmonStep){$loop = 0;}
			if ($counter > 50){
				$counter = 0;
				my $currentSelectionCount = lxq("select.count $selMode ?");
				if ($currentSelectionCount == $selectionCount){
					$loop = 0;
				}else{
					$selectionCount = $currentSelectionCount;
				}
			}
		}
	}else{
		die("'Stop At Ngon' : only works with polys and you're not in polygon selection mode so the script is being canceled");
	}
}


#regular loop selection
else{
	my $loop = 1;
	lxmonInit(1000);
	my $counter = 0;
	my $selectionCount = 0;
	while ($loop == 1){
		$counter++;

		lx("select.more") or $loop = 0;
		if (!lxmonStep){$loop = 0;}
		if ($counter > 50){
			$counter = 0;
			my $currentSelectionCount = lxq("select.count $selMode ?");
			if ($currentSelectionCount == $selectionCount){
				$loop = 0;
			}else{
				$selectionCount = $currentSelectionCount;
			}
		}
	}
}
