#perl
#ver. 0.85
#author : Seneca Menard
#This script is to clean up some uvs after you do a vert merge...  Just select the verts (or edges) and run script.

#(7-26-10 bugfix) : the script now ignores duplicate uv values and thus gets a better average.

if( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) ) {lx("select.convert vertex");}

lx("tool.viewType uv");
lx("tool.set actr.auto on");

my $mainlayer = lxq("query layerservice layers ? main");
my @verts = lxq("query layerservice verts ? selected");
my @vmaps = lxq("query layerservice vmaps ? texture");
my $vmap = selectVmapNew(0);
my $vmapName = lxq("query layerservice vmap.name ? $vmap");

foreach my $vert (@verts){
	my @polys = lxq("query layerservice vert.polyList ? $vert");
	my %polyPartList;

	foreach my $poly (@polys){
		my $part = lxq("query layerservice poly.part ? $poly");
		push(@{$polyPartList{$part}},$poly);
	}

	foreach my $part (keys %polyPartList){
		my $avgPos;

		#grab all the uv values from the polys with the same part and put them in an array so we can check if they're the same or not.
		if (@{$polyPartList{$part}} > 1){
			my @uvPosList;
			my $discoUVs = 0;

			foreach my $poly (@{$polyPartList{$part}}){
				my @vertList = lxq("query layerservice poly.vertList ? $poly");
				my @vmapValues = lxq("query layerservice poly.vmapValue ? $poly");
				my $polyVertIndex;

				for (my $i=0; $i<@vertList; $i++){
					if ($vert == @vertList[$i]){
						$polyVertIndex = $i;
						$last;
					}
				}
				push(@uvPosList,@vmapValues[$polyVertIndex*2].",".@vmapValues[$polyVertIndex*2+1]);
			}

			#go through the stored uv values for that vert and see if it's disco or not
			my $discoUVTest = @uvPosList[0];
			foreach my $uv (@uvPosList){
				if ($uv ne $discoUVTest){
					$discoUVs = 1;
					last;
				}
			}

			if ($discoUVs == 1){
				lxout("going to merge this vert ($vert) for these polys : (@{$polyPartList{$part}})");
				my @avgUVPos;
				lx("select.drop vertex");

				my %tempUVTable = (); #this is to get rid of dupes
				for (my $i=0; $i<@{$polyPartList{$part}}; $i++){
					lx("select.element $mainlayer vertex add index:$vert index3:@{$polyPartList{$part}}[$i]");
					$tempUVTable{@uvPosList[$i]} = 1;
				}

				foreach my $key (keys %tempUVTable){
					my @uvPos = split(/,/, $key);
					@avgUVPos = ($avgUVPos[0]+$uvPos[0] , $avgUVPos[1]+$uvPos[1]);
				}

				@avgUVPos = ($avgUVPos[0]/(keys %tempUVTable) , $avgUVPos[1]/(keys %tempUVTable));
				lxout("   merging to this position : @avgUVPos");
				lxout("-----------------------------------------------------");

				lx("tool.set xfrm.stretch on");
				lx("tool.reset");
				lx("tool.setAttr center.auto cenU @avgUVPos[0]");
				lx("tool.setAttr center.auto cenV @avgUVPos[1]");
				lx("tool.attr xfrm.stretch factX 0");
				lx("tool.attr xfrm.stretch factY 0");
				lx("tool.doApply");
				lx("tool.set xfrm.stretch off");
			}
		}
	}
}















#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT VMAP NEW
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : 		selectVmapNew(0|1,zeroVmapsSelected,allVmaps);
#requirements : (@vmaps = array of uv only vmaps)
#returns : 		(vmap indice of chosen vmap)
#notes :		(0|1 = whether or not to create new or select unused vmap if no used ones found) (zeroVmapsSelected = loop uses this automatically) (allVmaps=return all)
sub selectVmapNew{
	my @selectedVmaps;
	foreach my $vmap (@vmaps){	if (lxq("query layerservice vmap.selected ? $vmap") == 1){push(@selectedVmaps,$vmap);}}

	#[----------------------------------------------------------------------------]
	#[------------------------------return all vmaps------------------------------]
	#[----------------------------------------------------------------------------]
	if (@_[2] eq "allVmaps"){
		lxout("[->] SELECTVMAP SUB : Returning ALL selected vmaps.");
		my $mode = lxq("user.value senRenderBmpUVMode ?");  #0=Use Name Pattern   1=Use Selected UVmaps   2=Use All UVmaps
		my @foundVmaps;

		if ($mode eq "Use Name Pattern"){
			my $namePattern = lxq("user.value senRenderBmpUVName ?");
			foreach my $vmap (@vmaps){
				if (lxq("query layerservice vmap.name ? $vmap") =~ /$namePattern/){
					push(@foundVmaps,$vmap);
				}
			}
		}elsif ($mode eq "Use Selected UVmaps"){
			@foundVmaps = @selectedVmaps;
		}elsif ($mode eq "Use All UVmaps"){
			@foundVmaps = @vmaps;
		}else{
			die("SELECTVMAPNEW SUB ERROR ! : The mode name doesn't match the atual name");
		}

		#drop all foundvmaps that aren't being used.
		for (my $i=0; $i<@foundVmaps; $i++){
			my $vmapName = lxq("query layerservice vmap.name ? @foundVmaps[$i]");
			if (lxq("query layerservice uv.N ? selected") == 0){
				splice(@foundVmaps, $i,1);
				$i--;
			}
		}

		return @foundVmaps;
	}

	#[----------------------------------------------------------------------------]
	#[-------------------------------return one vmap------------------------------]
	#[----------------------------------------------------------------------------]
	else{
		#[------------------------------------]
		#[----------no vmaps selected---------]
		#[------------------------------------]
		if (@_[1] eq "zeroVmapsSelected"){
			my $vmapAmount = 0;
			my $winner = -1;

			#desel all vmaps
			foreach my $vmap (@vmaps){
				if (lxq("query layerservice vmap.selected ? $vmap") == 1){
					my $name = lxq("query layerservice vmap.name $vmap");
					lx("select.vertexMap {$name} txuv remove");
				}
			}
			#go thru all vmaps and find the winner
			foreach my $vmap (@vmaps){
				my $name = lxq("query layerservice vmap.name ? $vmap");
				my $amount = lxq("query layerservice uv.N ? visible");
				if ($amount >= $vmapAmount){
					$vmapAmount = $amount;
					$winner = $vmap;
				}
			}
			#if a winner was found, select it and return.
			if ($winner != -1){
				my $name = lxq("query layerservice vmap.name ? $winner");
				lx("select.vertexMap {$name} txuv replace");
				lxout("[->] SELECTVMAP SUB : No vmaps were selected, so I selected the one with the most polys being used : ($name)");
				return $winner;
			}
			#if no winner was found, that means we need to create a new vmap or cancel script depending on case.
			else{
				#don't create new vmap
				if (@_[0] == 0){
					die("I'm cancelling the script because the current layer doesn't have any usable uvs.");
				}
				#select or create new vmap
				else{
					foreach my $vmap (@vmaps){
						if (lxq("query layerservice vmap.name ? $vmap") eq "Texture"){
							lxout("I'm selecting the (Texture) vmap because no vmaps were selected or being used and it's the default");
							lx("select.vertexMap Texture txuv replace");
							return $vmap;
						}
					}
					lx("vertMap.new Texture txuv false {0.78 0.78 0.78} 1.0");
					lxout("[->] SELECTVMAP SUB : No vmaps were selected or being used, so I created (Texture)");
					my @currentVmaps = lx("query layerservice vmaps ? texture");
					return @currentVmaps[-1];
				}
			}
		}

		#[------------------------------------]
		#[---------some vmaps selected--------]
		#[------------------------------------]
		else{
			#[									  ]
			#[-------multiple vmaps selected------]
			#[									  ]
			if (@selectedVmaps > 1){
				my $vmapAmount = 0;
				my $winner = -1;

				#go thru all vmaps and find the winner
				foreach my $vmap (@selectedVmaps){
					my $vmapName = lxq("query layerservice vmap.name ? $vmap");
					my $amount = lxq("query layerservice uv.N ? visible");
					if ($amount >= $vmapAmount){
						$winner = $vmap;
						$vmapAmount = $amount;
					}
				}
				#if a winner was found, deselect all the losers
				if ($winner != -1){
					my $name = lxq("query layerservice vmap.name ? $winner");
					lx("select.vertexMap {$name} txuv replace");
					lxout("[->] SELECTVMAP SUB : There were multiple vmaps selected, so I deselected all but ($name) because it had the most uvs");
					return $winner;
				}
				#if a winner was NOT found, deselect all vmaps and run this sub again.
				else{
					lxout("[->] SELECTVMAP SUB : looping sub because more than one vmap (@selectedVmaps) was selected, but they're not being used");
					selectVmapNew(@_[0],zeroVmapsSelected);
				}
			}

			#[									  ]
			#[----------one vmap selected---------]
			#[									  ]
			elsif (@selectedVmaps == 1){
				my $name = lxq("query layerservice vmap.name ? @selectedVmaps[0]");
				if (lxq("query layerservice uv.N ? visible") > 0){
					lxout("[->] SELECTVMAP SUB : ($name) vmap already selected");
					return @selectedVmaps[0];
				}else{
					lxout("[->] SELECTVMAP SUB : looping sub because one vmap ($name) was selected, but it's not being used by this layer");
					selectVmapNew(@_[0],zeroVmapsSelected);
				}
			}

			#[									  ]
			#[-----------no vmap selected---------]
			#[									  ]
			else{
				selectVmapNew(@_[0],zeroVmapsSelected);
			}
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
