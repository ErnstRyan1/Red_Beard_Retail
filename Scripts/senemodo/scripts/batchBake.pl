#perl
#ver : 0.62 (not even remotely close to being finished)
#author : Seneca Menard
#This script is for running batch 3d bakes, 2d bakes, and self bakes.  It treats the currently active layers as the "low poly" layers and the background layers as the "high poly" layers...  blah blah blah....

#NOTES : specularmap? that'd have to be a special case where I convert all bumps to diffuse and bake
#NOTES : bumpmap?  that'd have to be a special case where I convert all bumps to diffuse and bake
#NOTES : disp : need disp rate to use percentage or popup





#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#cvars
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#userValueTools(name,type,life,username,list,listnames,argtype,min,max,action,value);
userValueTools(senRenderBumpURes,integer,config,Width,"","","",64,8192,"",512);
userValueTools(senRenderBumpVRes,integer,config,Height,"","","",64,8192,"",512);
userValueTools(senRenderBumpAORays,integer,config,"Ambient Occlusion Rays","","","",16,4096,"",512);
userValueTools(senRenderBumpNormal,boolean,config,"Normal map","","","",xxx,xxx,"",1);
userValueTools(senRenderBumpColor,boolean,config,"Diffuse map","","","",xxx,xxx,"",1);
userValueTools(senRenderBumpSpecular,boolean,config,"Specular map","","","",xxx,xxx,"",1);
userValueTools(senRenderBumpHeight,boolean,config,"Heightmap Bump","","","",xxx,xxx,"",1);
userValueTools(senRenderBumpAO,boolean,config,"Ambient Occlusion","","","",xxx,xxx,"",1);
userValueTools(senRenderBumpFull,boolean,config,"Full render","","","",xxx,xxx,"",1);
userValueTools(senRenderBumpGrnInv,boolean,config,"Invert Green Channel","","","",xxx,xxx,"",1);
userValueTools(senRenderBmpTraceDist,string,config,"Trace Distance","","","",xxx,xxx,"","10%");
userValueTools(senRenderBmpLoader,integer,config,"Loader:","Batch Bake;Current Layers","","",xxx,xxx,"",1);

userValueTools(senRenderBmpUVs,integer,config,"UV Mode:","All UV Groups;One UV Group","","",xxx,xxx,"",1);
userValueTools(senRenderBmpMaterial,integer,config,"Render per Material:","idTech5 Bake per Material;Ignore Materials;Bake per Material","","",xxx,xxx,"",0);
userValueTools(senRenderBmpUVMode,integer,config,"UVv Sel Mode:","Use Name Pattern;Use Selected UVmaps;Use All UVmaps","","",xxx,xxx,"",2);
userValueTools(senRenderBmpUVName,string,config,"UV Name Pattern","","","",xxx,xxx,"","bake");
userValueTools(senRenderBumpDelHPUV,boolean,config,"Delete HP UVs?","","","",xxx,xxx,"","");
userValueTools(senRenderBmpFileName,integer,config,"File Suffix Name:","Scene_Layer_Material_UV Name;Scene_Layer_Material Name;Scene_Layer Name;Scene Name;Layer Name;Material Name","","",xxx,xxx,"",5);
userValueTools(senRenderBmpGrpHPName,string,config,"Group HP Name","","","",xxx,xxx,"","HP");
userValueTools(senRenderBumpImgNamRmvPath,boolean,config,"Only keep last name","","","",xxx,xxx,"",1);
userValueTools(senRenderBumpForceLPSmth,boolean,config,"Force LP model smoothing","","","",xxx,xxx,"",1);

userValueTools(senRenderBumpFileType,integer,config,"File Save Type","Save Dialog;Save TGAs;Save PSD","","",xxx,xxx,"",0);
userValueTools(senRenderLPHPVisToggle,boolean,config,"Use LP/HP vis hack","","","",xxx,xxx,"",0);

userValueTools(senRenderBmpDisp,integer,config,"Displacement Loader:","Material Name Based;Model Name Based;Use Current Scene","","",xxx,xxx,"",2);
userValueTools(senRenderBmpBBDistMode,integer,config,"BatchBake disp amount setting:","Ask for a distance every time;Use GLOBAL distance","","",xxx,xxx,"",1);
userValueTools(senRenderBmpBBDist,string,config,"BatchBake Global disp dist:","","","",xxx,xxx,"","10%");
userValueTools(senRenderBmpBBDispName,string,config,"BatchBake disp file suffix:","","","",xxx,xxx,"","_disp");
userValueTools(senRenderBmpBBHPName,string,config,"BatchBake HP file suffix:","","","",xxx,xxx,"","_hp");

userValueTools(senRenderBmpBakeNormalName,string,config,"Normal map suffix:","","","",xxx,xxx,"","_normal");
userValueTools(senRenderBmpBakeMapsName,string,config,"Maps suffix:","","","",xxx,xxx,"","_maps");
userValueTools(senRenderBmpBakeColorName,string,config,"Final Color suffix:","","","",xxx,xxx,"","_finalColor");

if (lxq("user.value senRenderBumpDelHPUV ?") == 1){	lxout("The (DELETE UVS ON HP) option is on in the advanced options, so I will be deleting ALL of the HP uv maps that are used by the LP models");}
my $resU = lxq("user.value senRenderBumpURes ?");
my $resV = lxq("user.value senRenderBumpVRes ?");
my $senRenderLPHPVisToggle = lxq("user.value senRenderLPHPVisToggle ?");
my $fileDialogResult = "";
my @vmaps;

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if ($arg =~ /2d/i)			{	our $renderBumpFlat = 1;	}
	if ($arg =~ /bakeSelf/i)	{	our $bakeSelf = 1;			}
}




#main routine
my $os = lxq("query platformservice ostype ?");
my $osSlash = findOSSlash();
my $modoVer = lxq("query platformservice appversion ?");
my $mainscene = lxq("query sceneservice scene.index ? current");
my $mainlayer = lxq("query layerservice layers ? main");
our @itemList_unhide;
our @itemList_select;
my $bbox;

if (lxq("user.value senRenderBmpMaterial ?") eq "idTech5 Bake per Material"){
	our $sene_matRepairPath = lxq("user.value sene_matRepairPath ?");
	&validateGameDir;
}

shaderTreeTools(buildDbase);
if ((lxq("user.value senRenderBmpMaterial ?") eq "Ignore Materials") && (lxq("user.value senRenderBumpFileType ?") ne "Save Dialog")){&getFilePath;}
&loader;

#show items again
lx("layer.setVisibility $_ 1") for @itemList_select;
lx("layer.setVisibility $_ 1") for @itemList_unhide;
lx("select.subItem $_ add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;locator;deform;locdeform 0 0") for @itemList_select;

#remove selection set
lx("!!unhide");
lx("!!select.drop polygon");
lx("!!select.useSet seneBatchBake select");
lx("!!select.editSet seneBatchBake remove");
lx("!!hide.unsel");
lx("!!select.drop polygon");






#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#LOADER SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub loader{

	#[------------------------------------]
	#[-----current layer or layers--------]
	#[------------------------------------]
	if (lxq("user.value senRenderBmpLoader ?") eq "Current Layers"){
		my @selection = lxq("query sceneservice selection ? locator");
		my $GroupLPNameFilter = lxq("user.value senRenderBmpGrpHPName ?");
		my @groups;
		my @meshes;
		my @hideList;
		my %meshGroupParents;
		my %meshGroupChildren;

		foreach my $item (@selection){
			my $type = lxq("query sceneservice item.type ? $item");
			if    ($type eq "groupLocator")	{push(@groups,$item); push(@hideList,$item); push(@itemList_select,$item);}
			elsif ($type =~ "mesh")			{push(@meshes,$item); push(@hideList,$item); push(@itemList_select,$item);}
		}
		if ((@meshes == 0) && (@groups == 0)){
			my $id = lxq("query layerservice layer.id ? $mainlayer");
			push(@meshes,$id);
			push(@itemList_select,$id);
		}

		#go through all groups and add their LP meshes to the mesh list
		foreach my $groupID (@groups){
			my @children = lxq("query sceneservice locator.children ? {$groupID}");
			foreach my $child (@children){
				if ((lxq("query sceneservice item.type ? $child") eq "mesh") && (lxq("query layerservice layer.visible ? $child") ne "none")){
					push(@itemList_unhide,$child);

					if (lxq("query sceneservice item.name ? $child") !~ /$GroupLPNameFilter/){
						push(@meshes,$child);
						push(@{$meshGroupChildren{$groupID}},$child);
						$meshGroupParents{$child} = $groupID;
					}
				}
			}
		}

		#loop for finding items and their vmaps
		foreach my $id (@meshes){
			@vmaps = lxq("query layerservice vmaps ? texture");

			foreach my $itemID (@hideList){
				if ($id eq $itemID) {lx("select.subItem {$id} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;locator;deform;locdeform 0 0"); lx("layer.setVisibility {$itemID} 1");}
				else				{lx("layer.setVisibility {$itemID} 0");}
			}

			#set visibility for this layer only
			lx("select.subItem {$id} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;locator;deform;locdeform 0 0");
			hideAllBut($id,\@meshes,\%meshGroupParents,\%meshGroupChildren);

			lx("select.drop polygon");
			lx("select.editSet seneBatchBake add");

			my $layerName = lxq("query layerservice layer.name ? $id");

			#not per material
			if (lxq("user.value senRenderBmpMaterial ?") eq "Ignore Materials"){

				#find uv maps and renderbump
				if (lxq("user.value senRenderBmpUVs ?") eq "One UV Group"){
					my @vmapResults = selectVmapNew(0);
					foreach my $vmap (@vmapResults){renderBump($vmap);}
				}elsif (lxq("user.value senRenderBmpUVs ?") eq "All UV Groups"){
					lx("select.type vertex");
					lx("select.all");
					my @vmapResults = selectVmapNew(0,"",allVmaps);
					foreach my $vmap (@vmapResults){renderBump($vmap);}
				}else{
					die("LOADER ERROR! : the senRenderBmpUVs value doesn't match");
				}
			}

			#per material
			elsif ( (lxq("user.value senRenderBmpMaterial ?") eq "Bake per Material") || (lxq("user.value senRenderBmpMaterial ?") eq "idTech5 Bake per Material") ){
				 my @materials = lxq("query layerservice materials ?");
				 foreach my $material (@materials){
					 $material = lxq("query layerservice material.name ? $material");

					#sel polys and hide everything but
					lx("unhide");
					lx("select.drop polygon");

					lx("select.polygon add material face {$material}");
					lx("hide.unsel");

					#find uv maps and renderbump
					if (lxq("user.value senRenderBmpUVs ?") eq "One UV Group"){
						my @vmapResults = selectVmapNew(0);
						foreach my $vmap (@vmapResults){renderBump($vmap,$material);}
					}elsif (lxq("user.value senRenderBmpUVs ?") eq "All UV Groups"){
						lx("select.type vertex");
						lx("select.all");
						my @vmapResults = selectVmapNew(0,"",allVmaps);
						foreach my $vmap (@vmapResults){renderBump($vmap,$material);}
					}else{
						die("LOADER ERROR! : the senRenderBmpUVs value doesn't match");
					}
				 }
			}else{
				die("LOADER ERROR! : the senRenderBmpMaterial value doesn't match");
			}
		}
	}


	#[------------------------------------]
	#[-------------batch bake-------------]
	#[------------------------------------]
	else{


	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RENDERBUMP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : renderBump($vmap,$ptag);
sub renderBump{
	my $bakeDist = lxq("user.value senRenderBmpTraceDist ?");
	my $maskID;
	if (@_[1] ne ""){
		our $materialName = @_[1];
		#$materialName =~ s/.*[\/]//g;
	}

	#[------------------------------------]
	#[0:1] : Calculate Bake Dist
	#[------------------------------------]
	if ($bakeDist =~ /%/){
		my @bbox = lxq("query layerservice layer.bounds ?");
		my $xBboxSize = abs(@bbox[3]-@bbox[0]);
		my $yBboxSize = abs(@bbox[4]-@bbox[1]);
		my $zBboxSize = abs(@bbox[5]-@bbox[2]);
		my $maxSize = $xBboxSize;
		if ($yBboxSize > $maxSize){$maxSize = $yBboxSize;}
		if ($zBboxSize > $maxSize){$maxSize = $zBboxSize;}
		$bakeDist =~ s/[^0-9.]//g;
		#chomp($bakeDist);
		$bakeDist = $maxSize * ($bakeDist / 100);
		$bakeDist .= " m";
		lxout("[->] BAKE : The bake distance is $bakeDist m");
	}

	#[------------------------------------]
	#[0:2] : Delete HP uv map
	#[------------------------------------]
	if (lxq("user.value senRenderBumpDelHPUV ?") == 1){
		lx("!!layer.swap");
		lx("!!uv.delete");
		lx("!!layer.swap");
	}

	#[------------------------------------]
	#[0:3] : Create the material group if needed
	#[------------------------------------]
	if (lxq("user.value senRenderBmpMaterial ?") eq "Bake per Material"){
		if (shaderTreeTools(ptag,maskExists,@_[1]) != 0){
			$maskID = @{$shaderTreeIDs{@_[1]}}[0];
		}else{
			shaderTreeTools(ptag,createMask,@_[1]);
			$maskID = @{$shaderTreeIDs{@_[1]}}[0];
		}
	}else{
		my @materials = lxq("query layerservice materials ?");
		foreach my $material (@materials){
			my $name = lxq("query layerservice material.name ? $material");
			if (shaderTreeTools(ptag,maskExists,$name) != 0){
				#do nothing
			}else{
				shaderTreeTools(ptag,createMask,$name);
			}
		}
	}

	#[------------------------------------]
	#[0:3] : Set LP smoothing to 180
	#[------------------------------------]
	if (lxq("user.value senRenderBumpForceLPSmth ?") == 1){
		our %forcedLPSmthMaterials;
		my @materials;

		if (lxq("user.value senRenderBmpMaterial ?") eq "Bake per Material"){
			@materials = @_[1];
		}else{
			my @materials = lxq("query layerservice materials ?");
			for (my $i=0; $i<@materials; $i++){@materials[$i] = lxq("query layerservice material.name ? @materials[$i]");}
		}

		foreach my $material (@materials){
			my $materialID = shaderTreeTools(ptag,materialID,$material);

			lx("!!select.subItem {$materialID} set textureLayer;render;environment;mediaClip;locator");
			my $amount = lxq("item.channel advancedMaterial\$smooth ?");
			my $angle = lxq("item.channel advancedMaterial\$smAngle ?");

			if (($amount != 1) || ($angle != 180)){
				@{$forcedLPSmthMaterials{$materialID}} = ($amount,$angle);
				lx("item.channel advancedMaterial\$smooth 1");
				lx("item.channel advancedMaterial\$smAngle 180");
			}
		}
	}

	#[------------------------------------]
	#[1] : NORMAL MAP
	#[------------------------------------]
	if (lxq("user.value senRenderBumpNormal ?") == 1){
		setAA("high,gaussian");

		#if baking per material
		if ( (lxq("user.value senRenderBmpMaterial ?") eq "Bake per Material") || (lxq("user.value senRenderBmpMaterial ?") eq "idTech5 Bake per Material") ){
			#load the image #temp.  need to remove it if running script again
			my $vmapName = lxq("query layerservice vmap.name ? @_[0]");
			my $imagePath = findImageExportFilename(lxq("user.value senRenderBmpBakeNormalName ?"),tga,$materialName);
			lxout("normal map = $imagePath");

			if ($senRenderLPHPVisToggle == 1){showExclusiveItems("HP");}

			newImageAndDeleteOld(@_[1],$imagePath);
			lx("bake.objToTexture [$bakeDist]");
			if (lxres != 0){	die("The user hit the cancel button");	}
			lx("clip.saveAs filename:[$imagePath]");
		}

		#if baking per layer
		elsif (lxq("user.value senRenderBmpMaterial ?") eq "Ignore Materials"){
			my $layerName = lxq("query layerservice layer.name ?");
			my $imagePath = $filePath . "_" . $layerName . ".tga";

			newImageAndDeleteOld(polyRender,$imagePath);
			lx("bake.objToTexture [$bakeDist]");
			if (lxres != 0){	die("The user hit the cancel button");	}
			lx("clip.saveAs filename:[$imagePath]");
		}

		else{
			die("NORMAL MAP ERROR! : the senRenderBmpMaterial value doesn't match");
		}
	}

	#[------------------------------------]
	#[2] : MAPS
	#[------------------------------------]
	if ((lxq("user.value senRenderBumpAO ?") == 1) || (lxq("user.value senRenderBumpColor ?") == 1) || (lxq("user.value senRenderBumpSpecular ?") == 1) || (lxq("user.value senRenderBumpHeight ?") == 1)){

		setAA("low,box");
		#if ($senRenderLPHPVisToggle == 1){showExclusiveItems("LP");} #temp hack : can't remember why i put this in there...heh

		#turn off all render outputs
		my @renderOutputs = @{$shaderTreeIDs{renderOutput}};
		my @disabledRenderOutputs;
		foreach my $id (@renderOutputs){
			my $name = lxq("query sceneservice item.name ? $id");
			if (lxq("query sceneservice channel.value ? 0") == 1){
				lx("!!shader.setVisible {$id} 0");
				push(@disabledRenderOutputs,$id);
			}
		}

		#turn off render settings (shadows , radiosity)
		my $renderID = $shaderTreeIDs{polyRender}[0];
		my @disabledRenderFlags;

		lx("select.subItem {$renderID} set textureLayer;locator;render;environment;mediaClip");
		if (lxq("item.channel rayShadow ?") == 1){
			lx("!!item.channel rayShadow 0");
			push(@disabledRenderFlags,"rayShadow");
		}
		if (lxq("item.channel polyRender\$globEnable ?") == 1){
			lx("!!item.channel polyRender\$globEnable 0");
			push(@disabledRenderFlags,"polyRender\$globEnable");
		}
		#TEMP : what about displacement ? should i turn that on???  plus there's

		#turn off render region.
		if (lxq("item.channel polyRender\$region ?") == 1){
			lx("item.channel polyRender\$region false");
		}

		#change render resolution
		my $currentResU = lxq("render.res 0 ?");
		my $currentResV = lxq("render.res 1 ?");
		if ($currentResU != $resU)	{lx("!!render.res 0 $resU");}
		else						{$currentResU = "";			}
		if ($currentResV != $resV)	{lx("!!render.res 1 $resV");}
		else						{$currentResV = "";			}


		#set material diff amounts to 100%
		if ((lxq("user.value senRenderBumpColor ?") == 1) || (lxq("user.value senRenderBumpHeight ?") == 1) || (lxq("user.value senRenderBumpSpecular ?") == 1)){
			our $disabledMaterialBrightness;
			my $items = lxq("query sceneservice item.n ? all");
			for (my $i=0; $i<$items; $i++){
				if (lxq("query sceneservice item.type ? $i") eq "advancedMaterial"){
					my $id = lxq("query sceneservice item.id ? $i");
					lx("select.subItem {$id} set textureLayer;render;environment;mediaClip;locator");
					my $brightness = lxq("item.channel advancedMaterial\$diffAmt ?");

					if ($brightness != 1){
						lx("!!item.channel advancedMaterial\$diffAmt 1");
						$disabledMaterialBrightness{$id} = $brightness;
					}
				}
			}
		}

	#[------------------------------------]
	#[2a] : RENDER
	#[------------------------------------]

		#create new render outputs
		my @tempRenderOutputs;
		my $alphaOutputID;

		#alpha
		lx("select.subItem {$renderID} set textureLayer;locator;render;environment;mediaClip");
		lx("shader.create renderOutput");
		lx("!!item.channel renderOutput\$gamma 1.0");
		push(@tempRenderOutputs,lxq("query sceneservice selection ? renderOutput"));
		$alphaOutputID = $tempRenderOutputs[-1];
		lx("select.subItem {@tempRenderOutputs[-1]} set textureLayer;locator;render;environment;mediaClip");
		lx("shader.setEffect shade.alpha");


		#ao
		if (lxq("user.value senRenderBumpAO ?") == 1){
			setAA("high,gaussian");
			lx("!!select.subItem {$renderID} set textureLayer;locator;render;environment;mediaClip");
			lx("!!shader.create renderOutput");
			lx("!!item.channel renderOutput\$gamma 1.0");
			push(@tempRenderOutputs,lxq("query sceneservice selection ? renderOutput"));
			lx("!!select.subItem {@tempRenderOutputs[-1]} set textureLayer;locator;render;environment;mediaClip");
			my $rays = lxq("user.value senRenderBumpAORays ?");
			lx("shader.setEffect occl.ambient");
			lx("item.channel renderOutput\$occlRays {$rays}");

			lx("select.subItem {$alphaOutputID} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
			lx("texture.parent {$renderID} -1");

			if (lxq("user.value senRenderBumpFileType ?") ne "Save PSD"){
				my $imagePath = findImageExportFilename(_ao,tga,$materialName);
				lxout("AO map = $imagePath");
				lx("bake.obj filename:{$imagePath} format:TGA dist:[$bakeDist]");
				if (lxres != 0){	die("The user hit the cancel button");	}
			}
		}

		#diff
		if (lxq("user.value senRenderBumpColor ?") == 1){
			setAA("low,box");
			lx("!!select.subItem {$renderID} set textureLayer;locator;render;environment;mediaClip");
			lx("!!shader.create renderOutput");
			lx("!!item.channel renderOutput\$gamma 1.0");
			push(@tempRenderOutputs,lxq("query sceneservice selection ? renderOutput"));
			lx("!!select.subItem {@tempRenderOutputs[-1]} set textureLayer;locator;render;environment;mediaClip");
			lx("!!shader.setEffect mat.diffuse");

			lx("select.subItem {$alphaOutputID} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
			lx("texture.parent {$renderID} -1");

			if (lxq("user.value senRenderBumpFileType ?") ne "Save PSD"){
				if (@tempRenderOutputs > 2){lx("item.channel enable {0} set {$tempRenderOutputs[-2]}");}
				my $imagePath = findImageExportFilename("",tga,$materialName);
				lxout("diffuse map = $imagePath");
				lx("bake.obj filename:{$imagePath} format:TGA dist:[$bakeDist]");
				if (lxres != 0){	die("The user hit the cancel button");	}
			}
		}

		#if (lxq("user.value senRenderBumpHeight ?") == 1){ #TEMP : there's no bumpmap baker output. doh!
			#lx("!!select.subItem {$renderID} set textureLayer;locator;render;environment;mediaClip");
			#lx("!!shader.create renderOutput");
			#push(@tempRenderOutputs,lxq("query sceneservice selection ? renderOutput"));
		#}

		#spec
		if (lxq("user.value senRenderBumpSpecular ?") == 1){
			setAA("low,box");
			lx("!!select.subItem {$renderID} set textureLayer;locator;render;environment;mediaClip");
			lx("!!shader.create renderOutput");
			lx("!!item.channel renderOutput\$gamma 1.0");
			push(@tempRenderOutputs,lxq("query sceneservice selection ? renderOutput"));
			lx("!!shader.setEffect mat.specular");

			lx("select.subItem {$alphaOutputID} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
			lx("texture.parent {$renderID} -1");

			if (lxq("user.value senRenderBumpFileType ?") ne "Save PSD"){
				if (@tempRenderOutputs > 2){lx("item.channel enable {0} set {$tempRenderOutputs[-2]}");}
				my $imagePath = findImageExportFilename(_s,tga,$materialName);
				lxout("specular map = $imagePath");
				lx("bake.obj filename:{$imagePath} format:TGA dist:[$bakeDist]");
				if (lxres != 0){	die("The user hit the cancel button");	}
			}
		}

		#TEMP : RENDER OUT PSD : obviously need to put in code for 2d and selfBake still..
		if (lxq("user.value senRenderBumpFileType ?") eq "Save PSD"){
			my $imagePath = findImageExportFilename();
			lx("bake.obj filename:{$imagePath} format:PSD dist:[$bakeDist]");
			if (lxres != 0){	die("The user hit the cancel button");	}
		}



	#[------------------------------------]
	#[2b] : RESTORE SHADER TREE SETTINGS
	#[------------------------------------]

		#restore LP smoothing values
		foreach my $key (keys %forcedLPSmthMaterials){
			lx("select.subItem {$key} set textureLayer;render;environment;mediaClip;locator");
			lx("item.channel advancedMaterial\$smooth @{$forcedLPSmthMaterials{$key}}[0]");
			lx("item.channel advancedMaterial\$smAngle @{$forcedLPSmthMaterials{$key}}[1]");
		}

		#restore render outputs
		if (@disabledRenderOutputs > 0){
			foreach my $id (@disabledRenderOutputs){
				lx("!!shader.setVisible {$id} 1");
			}
		}

		#delete temp render outputs
		foreach my $renderID (@tempRenderOutputs){
			lx("!!select.subItem {$renderID} set textureLayer;locator;render;environment;mediaClip");
			lx("!!texture.delete");
		}

		#restore render settings (shadows , radiosity)
		if (@disabledRenderFlags > 0){
			lx("select.subItem {$renderID} set textureLayer;locator;render;environment;mediaClip");
			foreach my $name (@disabledRenderFlags){
				lx("!!item.channel $name 1");
			}
		}

		#restore render resolution
		if ($currentResU != ""){
			lx("!!select.subItem {$renderID} set textureLayer;locator;render;environment;mediaClip");
			lx("!!render.res 0 $resU");
		}
		if ($currentResV != ""){
			lx("!!select.subItem {$renderID} set textureLayer;locator;render;environment;mediaClip");
			lx("!!render.res 0 $resV");
		}

		#restore material diff
		if (keys %disabledMaterialBrightness > 0){
			foreach my $key (keys %disabledMaterialBrightness){
				lx("!!select.subItem {$key} set textureLayer;render;environment;mediaClip;locator");

				my $value = $disabledMaterialBrightness{$key};
				lx("!!item.channel advancedMaterial\$diffAmt {$disabledMaterialBrightness{$key}}");
			}
		}

	#[------------------------------------]
	#[2c] : RENDER
	#[------------------------------------]


	}

	#[------------------------------------]
	#[3] : FINAL RENDER
	#[------------------------------------]
	if (lxq("user.value senRenderBumpFull ?") == 1){


	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#NEW IMAGE (AND DELETE OLD ONE)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : newImageAndDeleteOld($ptag,$imageName);
sub newImageAndDeleteOld{
	my $parentID = shaderTreeTools(ptag,maskID,@_[0]);

	#find old image and delete it.  (TEMP! : file path could be different!!)
	my $items = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$items; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "imageMap"){
			my $id = lxq("query sceneservice item.id ? $i");
			lx("!!select.subItem {$id} set textureLayer;render;environment");
			my $fileName = lxq("texture.setIMap ?");
			my @imagePath = split(/$osSlash/, @_[1]);
			@imagePath[-1] =~ s/\..*//;

			if (lc($fileName) eq lc(@imagePath[-1])){
				my $id = lxq("query sceneservice item.id ? $i");
				my $parent = lxq("query sceneservice item.parent ? $id");

				if ($parent eq $parentID){
					lxout("Deleting this texture : $id");
					lx("!!texture.delete");
				}
			}
		}
	}

	#delete the clip
	my $clipCount = lxq("query layerservice clip.n ? all");
	for (my $i=0; $i<$clipCount; $i++){
		my $clipFile = lxq("query layerservice clip.file ? $i");
		if ($clipFile eq $_[1]){
			lxout("deleting this clip : $clipFile");
			my $id = lxq("query layerservice clip.id ? $i");
			lx("select.subItem {$id} set mediaClip");
			lx("clip.delete");
		}
	}

	#create new image now.
	newTGA(@_[1],$resU,$resV,24);
	if (lxq("user.value senRenderBumpGrnInv ?") == 1)	{shaderTreeTools(ptag,addImage,@_[0],@_[1],normal,0,$vmapName,"",yes,yes);}
	else												{shaderTreeTools(ptag,addImage,@_[0],@_[1],normal,0,$vmapName,"","",yes);}
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND IMAGE EXPORT FILENAME
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#requires global $fileDialogResult cvar
#usage example 1 : findImageExportFilename("_s",tga,$material);
#usage example 2 : findImageExportFilename("",tga,$material);
#usage example 3 : findImageExportFilename(lxq("user.value senRenderBmpBakeMapsName ?"),tga);
#arg 0 = suffix
#arg 1 = extension
#arg 2 = materialName or layerName
sub findImageExportFilename{
	my $imagePath;

	if (lxq("user.value senRenderBumpFileType ?") eq "Save Dialog"){
		if ($fileDialogResult eq ""){
			lx("dialog.setup fileSave");
			lx("dialog.fileTypeCustom format:[tga] username:[Targa Files] loadPattern:[*.tga] saveExtension:[tga]");
			lx("dialog.title {Image to Save}");
			lx("dialog.open");
			$fileDialogResult = lxq("dialog.result ?");
			if (lxres != 0){	die("The user hit the cancel button");	}
		}
		$imagePath = $fileDialogResult;
		$imagePath =~ s/\..*//;
		$imagePath =~ s/\\/\//g;
		$imagePath .= $_[0] . "." . $_[1];
	}elsif (lxq("user.value senRenderBmpMaterial ?") eq "idTech5 Bake per Material"){
		my $material = $_[2];
		$material =~ s/\\/\//g;
		$imagePath = $sene_matRepairPath . $material . $_[0] . "." . $_[1];
	}else{
		$imagePath = $filePath . "_" . $_[2] . $_[0] . "." . $_[1];
	}

	return $imagePath;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#VALIDATE GAME DIR mod (now forces the path to be filled)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub validateGameDir{
	if ($sene_matRepairPath =~ /[a-z0-9]/i){
		OSPathNameFix($sene_matRepairPath);
		$sene_matRepairPath =~ s/\s*$//;
		my $lastChar = substr($sene_matRepairPath, -1, 1);
		if (($lastChar ne "\\") && ($lastChar ne "\/")){
			if ($osSlash eq "\\")	{$sene_matRepairPath .= "\\";}
			else					{$sene_matRepairPath .= "\/";}
		}
		if (-e $sene_matRepairPath){}else{popup("----------------MATERIAL REPAIR ERROR SO I'M NOW CANCELLING THE SCRIPT----------------\nThe shader system works by having materials with names linked to their assigned image path, \nand the user value to mention which folders to remove from the material names doesn't exist.  \nThis is the current user value : $sene_matRepairPath"); die;}
	}else{
		popup("THE batch bake 'Matr' option is set to 'idTech5 Bake per Material' but the 'GAME PATH' option from the super_UVTools form is blank, so I'm cancelling the script.  Please put 'W:/Rage/base' or whatever game path you're using into that GAME PATH option box and run script again.");
		die;
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND OS SLASH
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub findOSSlash{
	if ($os =~ /win/i){
		return "\/";
	}else{
		return "\\";
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PATH NAME FIX SUB : make sure the / syntax is correct for the various OSes.
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub OSPathNameFix{
	if ($os =~ /win/i){
		@_[0] =~ s/\\/\//g;
	}else{
		@_[0] =~ s/\//\\/g;
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET THE FILE PATH FOR THE IMAGE SAVER
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub getFilePath{
	our $filePath = lxq("query sceneservice scene.file ? current");

	if ($filePath eq ""){
		lx("dialog.setup fileOpen");
		lx("dialog.title {No scene filename, so select a filename for the images}");
		lx("dialog.fileType \"\"");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
		$filePath = lxq("dialog.result ?");
		$filePath =~ s/\..*//;
	}else{
		OSPathNameFix($filePath);
		$filePath =~ s/\..*//;
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#HIDE ALL LAYERS BUT THIS ONE SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : hideAllBut($id,\@listOfIDs,%idParentTable,%idParentChildren);
#this will hide all @listOfIDs except for the main $id and then unhide it's parent if there is one.
sub hideAllBut{
	my $groupHPNamePattern = lxq("user.value senRenderBmpGrpHPName ?");

	foreach my $id (@{@_[1]}){
		if (@_[0] eq $id)	{lx("layer.setVisibility {$id} 1");}
		else				{lx("layer.setVisibility {$id} 0");}
	}

	#unhide group parent
	my $hash = @_[2];
	if (exists $$hash{@_[0]}){
		lx("layer.setVisibility $$hash{@_[0]} 1");
		our $groupID = $$hash{@_[0]};
	}

	#hide other group children (if they're not HP)
	my $hash2 = @_[3];
	foreach my $id (@{$$hash2{$groupID}}){
		my $currentName = lxq("query layerservice layer.name ? @_[0]");
		my $name = lxq("query layerservice layer.name ? $id");

		if (lxq("query layerservice layer.name ? $id") =~ /$groupHPNamePattern/){
			lx("layer.setVisibility {$id} 1");
		}else{
			if (@_[0] ne $id){
				lx("layer.setVisibility {$id} 0");
			}else{
				lx("layer.setVisibility {$id} 1");
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
#BOUNDING BOX
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage setAA( high|low , box|gaussian );
sub setAA{
	my $renderID = $shaderTreeIDs{polyRender}[0];
	if ($_[0] =~ /high/i)	{	lx("item.channel aa {s8} set {$renderID}");				}
	else					{	lx("item.channel aa {s1} set {$renderID}");				}
	if ($_[1] ne "")		{	lx("item.channel aaFilter {$_[1]} set {$renderID}");	}
}


#-----------------------------------------------------------------------------------
#BOUNDING BOX subroutine (ver 1.5)
#-----------------------------------------------------------------------------------
sub boundingbox  #minX-Y-Z-then-maxX-Y-Z
{
	lxout("[->] Using boundingbox (math) subroutine");
	my @firstVertPos = lxq("query layerservice vert.pos ? $_[0]");
	my $minX = $firstVertPos[0];
	my $minY = $firstVertPos[1];
	my $minZ = $firstVertPos[2];
	my $maxX = $firstVertPos[0];
	my $maxY = $firstVertPos[1];
	my $maxZ = $firstVertPos[2];
	my @bbVertPos;

	foreach my $bbVert (@_){
		@bbVertPos = lxq("query layerservice vert.pos ? $bbVert");
		if ($bbVertPos[0] < $minX)	{	$minX = $bbVertPos[0];	}
		if ($bbVertPos[0] > $maxX)	{	$maxX = $bbVertPos[0];	}
		if ($bbVertPos[1] < $minY)	{	$minY = $bbVertPos[1];	}
		if ($bbVertPos[1] > $maxY)	{	$maxY = $bbVertPos[1];	}
		if ($bbVertPos[2] < $minZ)	{	$minZ = $bbVertPos[2];	}
		if ($bbVertPos[2] > $maxZ)	{	$maxZ = $bbVertPos[2];	}
	}
	return ($minX,$minY,$minZ,$maxX,$maxY,$maxZ);
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


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SHADER TREE TOOLS SUB (ver1.2 ptyp)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#HASH TABLE : 0=MASKID 1=MATERIALID   if $shaderTreeIDs{(all)} exists, that means there's some materials that effect all and should be nuked.
#PTAG : MASKID : (PTAG , MASKID , $PTAG) : returns the ptag mask group ID.
#PTAG : MATERIALID : (PTAG , MATERIALID , $PTAG) : returns the first materialID found in the ptag mask group.
#PTAG : MASKEXISTS : (PTAG , MASKEXISTS , $PTAG) : finds out if a ptag mask group exists or not.  0=NO 1=YES 2=YES,BUTNOMATERIALINIT
#PTAG : ADDIMAGE : (0=PTAG , 1=ADDIMAGE , 2=$PTAG , 3=IMAGEPATH , 4=EFFECT , 5=BLENDMODE , 6=UVMAP , 7=BRIGHTNESS , 8=INVERTGREEN , 9=AA) : adds an image to the ptag mask group w/ options.
#PTAG : DELCHILDTYPE : (PTAG , DELCHILDTYPE , $PTAG , TYPE) : deletes all the TYPE items in this ptag's mask group.
#PTAG : CREATEMASK : (PTAG , CREATEMASK , $PTAG) : create a material if it didn't exist before.
#PTAG : CHILDREN : (PTAG , CHILDREN , $PTAG , TYPE) : returns all the children from the ptag mask group.  Only returns children of a certain type if TYPE appended.
#GLOBAL : BUILDDBASE : (BUILDDBASE , ?FORCEUPDATE?) : creates the database to find a ptag's mask or material.  skips routine if the database isn't empty.  use forceupdate to force it again.
#GLOBAL : FINDPTAGFROMID : (FINDPTAGFROMID , ARRAYVALNAME , ARRAYNUMBER) : returns the hash key of the element you sent it and the pos in the array.
#GLOBAL : FINDALLOFTYPE : (FINDALLOFTYPE , TYPE) : returns all IDs that match the type.
#GLOBAL : TOGGLEALLOFTYPE : (TOGGLEALLOFTYPE , ONOFF , TYPE1 , TYPE2, ETC) : will turn everything of a type on or off
#GLOBAL : DELETEALLOFTYPE : (DELETEALLOFTYPE , TYPE) : deletes all of the selected type in the shader tree and updates database
#GLOBAL : DELETEALLALL : (DELETEALLALL) : deletes all the materials in the scene that effect ALL in the scene.
sub shaderTreeTools{
	lxout("[->] Running ShaderTreeTools sub <@_[0]> <@_[1]>");
	our %shaderTreeIDs;

	#----------------------------------------------------------
	#PTAG SPECIFIC :
	#----------------------------------------------------------
	if (@_[0] eq "ptag"){
		#MASK ID-------------------------
		if (@_[1] eq "maskID"){
			lxout("[->] Running maskID sub");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			return($shaderTreeIDs{$ptag}[0]);
		}
		#MATERIAL ID---------------------
		elsif (@_[1] eq "materialID"){
			lxout("[->] Running materialID sub");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			return($shaderTreeIDs{$ptag}[1]);
		}
		#MASK EXISTS---------------------
		elsif (@_[1] eq "maskExists"){
			lxout("[->] Running maskExists sub");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			if (exists $shaderTreeIDs{$ptag}){
				if (@{$shaderTreeIDs{$ptag}}[1] =~ /advancedMaterial/){
					return 1;
				}else{
					return 2;
				}
			}else{
				return 0;
			}
		}
		#ADD IMAGE-----------------------
		elsif (@_[1] eq "addImage"){
			lxout("[->] Running addImage sub");
			shaderTreeTools(buildDbase);

			if (@_[6] ne ""){lx("select.vertexMap @_[6] txuv replace");}

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			my $id = $shaderTreeIDs{$ptag}[0];
			lx("texture.new [@_[3]]");
			lx("texture.parent [$id] [-1]");

			if (@_[4] ne ""){lx("shader.setEffect @_[4]");}
			if (@_[7] ne ""){lx("item.channel imageMap\$max @_[7]");}
			if (@_[8] ne ""){lx("item.channel imageMap\$greenInv @_[8]");}
			if (@_[9] ne ""){lx("item.channel imageMap\$aa 0");  lx("item.channel imageMap\$pixBlend 0");}
		}
		#DEL CHILD TYPE-------------------
		elsif (@_[1] eq "delChildType"){
			lxout("[->] Running delChildType sub (deleting all @_[3]s)");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			my $id = $shaderTreeIDs{$ptag}[0];
			my @children = shaderTreeTools(ptag,children,$ptag,@_[3]);

			if (@children > 0){
				for (my $i=0; $i<@children; $i++){
					if ($i > 0)	{lx("select.subItem [@children[$i]] add textureLayer;render;environment;mediaClip;locator");}
					else		{lx("select.subItem [@children[$i]] set textureLayer;render;environment;mediaClip;locator");}
				}
				lx("texture.delete");
			}
		}
		#CREATE MASK---------------------
		elsif (@_[1] eq "createMask"){
			lxout("[->] Running createMask sub");
			shaderTreeTools(buildDbase);

			lx("select.subItem [@{$shaderTreeIDs{polyRender}}[0]] set textureLayer;render;environment;mediaClip;locator");
			lx("shader.create mask");
			my @masks = lxq("query sceneservice selection ? mask");
			lx("mask.setPTagType Material");
			lx("mask.setPTag @_[2]");
			lx("shader.create advancedMaterial");
			my @materials = lxq("query sceneservice selection ? advancedMaterial");
			@{$shaderTreeIDs{@_[2]}} = (@masks[0],@materials[0]);
		}
		#CHILDREN------------------------
		elsif (@_[1] eq "children"){
			lxout("[->] Running children sub");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			if (@_[3] eq ""){
				return (lxq("query sceneservice item.children ? $shaderTreeIDs{$ptag}[0]"));
			}else{
				my @children = lxq("query sceneservice item.children ? $shaderTreeIDs{$ptag}[0]");
				my @prunedChildren;
				foreach my $child (@children){
					if (lxq("query sceneservice item.type ? $child") eq @_[3]){
						push(@prunedChildren,$child);
					}
				}
				return (@prunedChildren);
			}
		}
	}

	#----------------------------------------------------------
	#GENERAL EDITING :
	#----------------------------------------------------------
	else{
		#BUILD DATABASE------------------
		if (@_[0] eq "buildDbase"){
			if (((keys %shaderTreeIDs) > 1) && (@_[1] ne "forceUpdate")){return;}
			if ($_[1] eq "forceUpdate"){%shaderTreeIDs = ();}

			lxout("[->] Running buildDbase sub");
			for (my $i=0; $i<lxq("query sceneservice item.N ? all"); $i++){
				my $type = lxq("query sceneservice item.type ? $i");

				#masks
				if ($type eq "mask"){
					if ((lxq("query sceneservice channel.value ? ptyp") eq "Material") || (lxq("query sceneservice channel.value ? ptyp") eq "")){
						my $id = lxq("query sceneservice item.id ? $i");
						my $ptag = lxq("query sceneservice channel.value ? ptag");
						$ptag =~ s/\\/\//g;

						if ($ptag eq "(all)"){
							push(@{$shaderTreeIDs{"(all)"}},$id);
						}else{
							my @children = lxq("query sceneservice item.children ? $i");
							@{$shaderTreeIDs{$ptag}}[0] = $id;
							foreach my $child (@children){
								if (lxq("query sceneservice item.type ? $child") eq "advancedMaterial"){
									@{$shaderTreeIDs{$ptag}}[1] = $child;
								}
							}
						}
					}else{
						@{$shaderTreeIDs{$ptag}}[0] = "noPtag";
						push(@{$shaderTreeIDs{$ptag}},$id);
					}
				}

				#outputs
				elsif ($type eq "renderOutput"){
					my $id = lxq("query sceneservice item.id ? $i");
					push(@{$shaderTreeIDs{renderOutput}},$id);
				}

				#shaders
				elsif ($type eq "defaultShader"){
					my $id = lxq("query sceneservice item.id ? $i");
					push(@{$shaderTreeIDs{defaultShader}},$id);
				}

				#render output
				elsif ($type eq "polyRender"){
					my $id = lxq("query sceneservice item.id ? $i");
					push(@{$shaderTreeIDs{polyRender}},$id);
				}
			}
		}
		#FIND PTAG FROM ID---------------
		elsif (@_[0] eq "findPtag"){
			foreach my $key (keys %shaderTreeIDs){
				if (@{$shaderTreeIDs{$key}}[1] eq @_[@_[2]]){
					return $key;
				}
			}
		}
		#FIND ALL OF TYPE----------------
		elsif (@_[0] eq "findAllOfType"){
			my @list;
			for (my $i=0; $i<lxq("query sceneservice txLayer.n ?"); $i++){
				if (lxq("query sceneservice txLayer.type ? $i") eq @_[1]){
					push(@list,lxq("query sceneservice txLayer.id ? $i"));
				}
			}
			return @list;
		}
		#TOGGLE ALL OF TYPE--------------
		elsif (@_[0] eq "toggleAllOfType"){
			for (my $i=0; $i<lxq("query sceneservice item.N ? all"); $i++){
				my $type = lxq("query sceneservice item.type ? $i");
				for (my $u=2; $u<$#_+1; $u++){
					if ($type eq @_[$u]){
						my $id = lxq("query sceneservice item.id ? $i");
						lx("select.subItem [$id] set textureLayer;render;environment");
						lx("item.channel textureLayer\$enable @_[1]");
					}
				}
			}
		}
		#DELETE ALL OF TYPE--------------
		elsif (@_[0] eq "delAllOfType"){
			my @deleteList;

			for (my $i=0; $i<lxq("query sceneservice txLayer.n ?"); $i++){
				if (lxq("query sceneservice txLayer.type ? $i") eq @_[1]){
					my $id = lxq("query sceneservice txLayer.id ? $i");
					push(@deleteList,$id);

					if (@_[1] eq "mask"){
						my $ptag = shaderTreeTools(findPtag,$id,1);
						delete $shaderTreeIDs{$ptag};
					}elsif  (@_[1] eq "advancedMaterial"){
						my $ptag = shaderTreeTools(findPtag,$id,1);
						lxout("found ptag = $ptag");
						if ($ptag ne ""){delete @{$shaderTreeIDs{$ptag}}[1];}
					}
				}
			}
			foreach my $id (@deleteList){
				lx("select.subItem [$id] set textureLayer;render;environment");
				lx("texture.delete");
			}

		}
		#DELETE ALL (ALL) MATERIALS------
		elsif (@_[0] eq "deleteAllALL"){
			shaderTreeTools(buildDbase);
			my @deleteList;

			if (exists $shaderTreeIDs{"(all)"}){
				foreach my $id (@{$shaderTreeIDs{"(all)"}}){push(@deleteList,$id);}
				delete $shaderTreeIDs{"(all)"};
			}
			foreach my $key (keys %shaderTreeIDs){
				if (@{$shaderTreeIDs{$key}}[0] eq "noPtag"){
					for (my $i=1; $i<@{$shaderTreeIDs{$key}}; $i++){
						push(@deleteList,@{$shaderTreeIDs{$key}}[$i]);
					}
					delete $shaderTreeIDs{$key};
				}
			}

			if (@deleteList > 0){
				lxout("[->] : Deleting these materials because they're not assigned to one ptag :\n@deleteList");
				for (my $i=0; $i<@deleteList; $i++){
					if ($i > 0)	{	lx("select.subItem [@deleteList[$i]] add textureLayer;render;environment");}
					else		{	lx("select.subItem [@deleteList[$i]] set textureLayer;render;environment");}
				}
				lx("texture.delete");
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SHOW EXCLUSIVE ITEMS (hack to show HP layers for normal and LP layers for diff)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : showExclusiveItems("HP");
sub showExclusiveItems{
	if ($_[0] eq "HP")	{	our @hideShow = (1,0);	}
	else				{	our @hideShow = (0,1);	}

	my %itemTypeList;
	$itemTypeList{"mesh"} = 1;
	$itemTypeList{"meshInst"} = 1;
	$itemTypeList{"triSurf"} = 1;

	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$itemCount; $i++){
		my $type = lxq("query sceneservice item.type ? $i");
		if ($itemTypeList{$type} == 1){
			my $name = lxq("query sceneservice item.name ? $i");
			if ($name =~ /HP/){
				my $id = lxq("query sceneservice item.id ? $i");
				lx("layer.setVisibility {$id} $hideShow[0]");
			}elsif ($name =~ /LP$/){
				my $id = lxq("query sceneservice item.id ? $i");
				lx("layer.setVisibility {$id} $hideShow[1]");
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE A NEW TGA TO THE HARD DRIVE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : newTGA("C://testImage.tga",512,256,24);
sub newTGA{
	#$buf = pack("C", 255);				#for packing 0-255
	#$buf = pack("A*", "Hello World!");	#for packing strings
	#$buf = pack("S", 666);				#for packing unsigned shorts (higher than 255, but not by that much i guess)
	if (@_[3] == ""){die("You can't run the newTGA sub without arguments!");}

	my $file = @_[0];
	my @size = (@_[1],@_[2]);
	my $bits = @_[3];
	lxout("[->] Creating a new TGA here : $file");
	open (TGA, ">$file") or die("I can't open the TGA");
	binmode(TGA);

	my $identSize = 		pack("C", 0);
	my $palette = 			pack("C", 0);
	my $imageType = 		pack("C", 2);
	my $colorMapStart = 	pack("S", 0);
	my $colorMapLength = 	pack("S", 0);
	my $colorMapBits =		pack("C", 0);
	my $xStart =			pack("S", 0);
	my $yStart =			pack("S", 0);
	my $width =				pack("S", @size[0]);
	my $height =			pack("S", @size[1]);
	my $bits =				pack("C", 24);
	my $descriptor =		pack("C", 0);
	my $black =				pack("CCC",0,0,0);

	print TGA $identSize;
	print TGA $palette;
	print TGA $imageType;
	print TGA $colorMapStart;
	print TGA $colorMapLength;
	print TGA $colorMapBits;
	print TGA $xStart;
	print TGA $yStart;
	print TGA $width;
	print TGA $height;
	print TGA $bits;
	print TGA $descriptor;

	for (my $i=0; $i<(@size[0]*@size[1]); $i++){
		print TGA $black;
	}

	close(TGA);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB v2.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {$_[0]}");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 1){
			lx("user.defDelete seneTempDialog");
		}
		lx("user.defNew name:[seneTempDialog] type:{$_[1]} life:[momentary]");		
		lx("user.def seneTempDialog username [$_[0]]");
		if (($_[3] != "") && ($_[4] != "")){
			lx("user.def seneTempDialog min [$_[3]]");
			lx("user.def seneTempDialog max [$_[4]]");
		}
		lx("user.value seneTempDialog [$_[2]]");
		lx("user.value seneTempDialog ?");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
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
