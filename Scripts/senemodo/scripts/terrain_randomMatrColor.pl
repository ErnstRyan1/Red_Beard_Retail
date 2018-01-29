#perl
#ver 1.5
#author : Seneca Menard
#This script will apply a random color to each material in the scene except the one called "Default"
#It will also apply a matching color to each of the "clip" materials.

srand;
my @clipMaterialList;
my %colorTable;

#apply colors to regular materials
my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
for (my $i=0; $i<$txLayerCount; $i++){
	if (lxq("query sceneservice txLayer.type ? $i") eq "advancedMaterial"){
		my $id = lxq("query sceneservice txLayer.id ? $i");
		my @parentInfo = findShaderGroupParent($id);
		my $materialName = lxq("query sceneservice txLayer.name ? @parentInfo[0]");

		if (@parentInfo < 1){lxout("no parentInfo! : id=$id <> materialName=$materialName");}

		#ignore "Default" ptag
		if ((@parentInfo < 1) || (lxq("query sceneservice channel.value ? ptag") eq "Default")){
			next;
		}
		#apply color
		else{
			my @split = split(/&/, $materialName);
			if (exists $colorTable{@split[-1]}){
				our $red = @{$colorTable{@split[-1]}}[0];
				our $green = @{$colorTable{@split[-1]}}[1];
				our $blue = @{$colorTable{@split[-1]}}[2];
			}else{
				our $red = rand;
				our $green = rand;
				our $blue = rand;
				@{$colorTable{@split[-1]}}=($red,$green,$blue);
			}

			lx("select.subItem {$id} set textureLayer;render;environment;mediaClip;locator");
			lx("!!item.channel advancedMaterial\$diffCol {$red $green $blue}");
			if ($materialName =~ /textures[\\\/]common[\\\/]collision/i){lx("!!item.channel advancedMaterial\$tranAmt 0.5");}
		}
	}
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND SHADER GROUP PARENT
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my @parentInfo = findShaderGroupParent(advancedMaterial021);
#returns : (id,ptag);
sub findShaderGroupParent{
	#popup("_[0] = @_[0]");
	my $currentID = @_[0];
	my $shaderGroupParent;
	my $debugCounter = 0;

	while ($shaderGroupParent eq ""){
		$debugCounter++; if ($debugCounter == 50){popup("pause : if this window keeps coming up, grab me so I can debug this case.\ncurrentID = $currentID <> parent = $parent"); $debugCounter=0;}

		my $parent = lxq("query sceneservice txLayer.parent ? $currentID");
		if ($parent !~ /[a-z0-9]/i){
			return();
		}elsif (lxq("query sceneservice txLayer.type ? $parent") eq "mask"){
			my $ptyp = lxq("query sceneservice channel.value ? ptyp");
			if (($ptyp eq "Material") || ($ptyp eq "")){  #TEMP! : i shouldn't be allowing "", but i'm doing that because some ptyp queries are failing!
				$shaderGroupParent = $parent;
				my $ptag = lxq("query sceneservice channel.value ? ptag");
				return($parent,$ptag);
			}else{
				$currentID = $parent;
			}
		}else{
			$currentID = $parent;
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
