#perl
#ver 1.33
#author : Seneca Menard
#This script will import multiple models into one scene and place them in a row.
#todo : I might want to snap their positions to the grid because they're all slightly off because of the bbox check.
#note : i'm now ignoring files that have "_hi" or "_hp" in their names.

#(3-2-10 fix) : ptyp fix
#(12-15-10 fix) : shut up a move tool complaint
#(6-20-11 fix) : shaderTreeTools ptag error fix
#(1-10-14 fix) : got the actr storage system up to date with 601

my $modoVer = lxq("query platformservice appversion ?");
my $mainScene = lxq("query sceneservice scene.index ? main");
my $sceneName = lxq("query sceneservice scene.name ? main");
my $sceneChanged = lxq("query sceneservice scene.changed ? main");
if (($sceneName =~ /Untitled/) && ($sceneChanged == 0)){	&alterScene;	}
my @fgLayers = lxq("query layerservice layers ? fg");
my @bgLayers = lxq("query layerservice layers ? bg");
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my @mainSceneBBOX = lxq("query layerservice layer.bounds ?");
my $xPos = int(0.5 + @mainSceneBBOX[3]);

#-----------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO6 FIX)) (modified to go to origin)
#-----------------------------------------------------------------------------------
#sets the ACTR preset
my $seltype;
my $selAxis;
my $selCenter;
my $actr = 1;

if   ( lxq( "tool.set actr.auto ?") eq "on")			{	$seltype = "actr.auto";			}
elsif( lxq( "tool.set actr.select ?") eq "on")			{	$seltype = "actr.select";		}
elsif( lxq( "tool.set actr.border ?") eq "on")			{	$seltype = "actr.border";		}
elsif( lxq( "tool.set actr.selectauto ?") eq "on")		{	$seltype = "actr.selectauto";	}
elsif( lxq( "tool.set actr.element ?") eq "on")			{	$seltype = "actr.element";		}
elsif( lxq( "tool.set actr.screen ?") eq "on")			{	$seltype = "actr.screen";		}
elsif( lxq( "tool.set actr.origin ?") eq "on")			{	$seltype = "actr.origin";		}
elsif( lxq( "tool.set actr.parent ?") eq "on")			{	$seltype = "actr.parent";		}
elsif( lxq( "tool.set actr.local ?") eq "on")			{	$seltype = "actr.local";		}
elsif( lxq( "tool.set actr.pivot ?") eq "on")			{	$seltype = "actr.pivot";		}
elsif( lxq( "tool.set actr.pivotparent ?") eq "on")		{	$seltype = "actr.pivotparent";	}

elsif( lxq( "tool.set actr.worldAxis ?") eq "on")		{	$seltype = "actr.worldAxis";	}
elsif( lxq( "tool.set actr.localAxis ?") eq "on")		{	$seltype = "actr.localAxis";	}
elsif( lxq( "tool.set actr.parentAxis ?") eq "on")		{	$seltype = "actr.parentAxis";	}

else
{
	$actr = 0;
	lxout("custom Action Center");
	
	if   ( lxq( "tool.set axis.auto ?") eq "on")		{	 $selAxis = "auto";				}
	elsif( lxq( "tool.set axis.select ?") eq "on")		{	 $selAxis = "select";			}
	elsif( lxq( "tool.set axis.element ?") eq "on")		{	 $selAxis = "element";			}
	elsif( lxq( "tool.set axis.view ?") eq "on")		{	 $selAxis = "view";				}
	elsif( lxq( "tool.set axis.origin ?") eq "on")		{	 $selAxis = "origin";			}
	elsif( lxq( "tool.set axis.parent ?") eq "on")		{	 $selAxis = "parent";			}
	elsif( lxq( "tool.set axis.local ?") eq "on")		{	 $selAxis = "local";			}
	elsif( lxq( "tool.set axis.pivot ?") eq "on")		{	 $selAxis = "pivot";			}
	else												{	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action AXIS that I couldn't read");}

	if   ( lxq( "tool.set center.auto ?") eq "on")		{	 $selCenter = "auto";			}
	elsif( lxq( "tool.set center.select ?") eq "on")	{	 $selCenter = "select";			}
	elsif( lxq( "tool.set center.border ?") eq "on")	{	 $selCenter = "border";			}
	elsif( lxq( "tool.set center.element ?") eq "on")	{	 $selCenter = "element";		}
	elsif( lxq( "tool.set center.view ?") eq "on")		{	 $selCenter = "view";			}
	elsif( lxq( "tool.set center.origin ?") eq "on")	{	 $selCenter = "origin";			}
	elsif( lxq( "tool.set center.parent ?") eq "on")	{	 $selCenter = "parent";			}
	elsif( lxq( "tool.set center.local ?") eq "on")		{	 $selCenter = "local";			}
	elsif( lxq( "tool.set center.pivot ?") eq "on")		{	 $selCenter = "pivot";			}
	else												{ 	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action CENTER that I couldn't read");}
}
lx("tool.set actr.origin on");


#script arguments
foreach my $arg (@ARGV){
	if		($arg =~ /dontMove/i)		{	our $dontMove = 1;			}
	elsif	($arg =~ /newLayers/i)		{	our $newLayers = 1;			}
	elsif	($arg =~ /deleteTextures/i)	{	our $deleteTextures = 1;	}
}


#file dialog window
lx("dialog.setup fileOpenMulti");
if ($modoVer > 300){lx("dialog.fileTypeCustom format:[sml] username:[Model to load] loadPattern:[*.lxo;*.lwo;*.obj] saveExtension:[lxo]");}
else{				lx("dialog.fileType scene");}
lx("dialog.title [Select the models you wish to import into the scene...]");
lx("dialog.open");
my @files = lxq("dialog.result ?");
if (@files < 1){die("You didn't pick any files so I'm canceling the script");}



foreach my $file (@files){
	if (($file =~ /_hi/i) || ($file =~ /_hp/i)){
		next;
	}else{
		if (-e $file)	{lx("!!scene.open {$file};");}
		else			{die("Either the file ($file) doesn't exist or your drive isn't mapped properly and because I can't load it, I'm cancelling the script.");}

		my $newScene = lxq("query sceneservice scene.index ? main");

		#DELETE TEXTURES
		if ($deleteTextures == 1){shaderTreeTools(delAllOfType,imageMap);	}

		my $currentLayer = lxq("query layerservice layers ? main");
		my @bbox = lxq("query layerservice layer.bounds ?");
		lxout("file=$file\nbbox = @bbox\nxCenter = $xCenter\nxPos=$xPos");
		my $moveDist = $xPos - @bbox[0];
		lx("select.type polygon");
		lx("select.copy");
		lx("scene.set [$mainScene]");
		if ($newLayers != 1){
			lx("select.subItem {$mainlayerID} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
		}else{
			lx("item.create mesh");
			my $layerName = $file;
			$layerName =~ s/.*\\//;
			$layerName =~ s/\.lwo//i;
			$layerName =~ s/_//;
			lx("item.name {$layerName} mesh");
		}
		lx("select.invert");
		lx("!!select.paste");
		lx("select.invert");
		$xPos += 16 + int(.5 + abs(@bbox[3] - @bbox[0]));

		#MOVE
		if ($dontMove != 1){
			lx("tool.set xfrm.move on");
			lx("tool.reset");
			lx("tool.setAttr xfrm.move X [$moveDist]");
			lx("tool.setAttr xfrm.move Y 0");
			lx("tool.setAttr xfrm.move Z 0");
			lx("tool.doApply");
			lx("tool.set xfrm.move off");
		}

		#close temp scene.
		lx("!!scene.set [$newScene]");
		lx("!!scene.close");
	}
}

#restore original scene and layer visibility
my $currentScene = lxq("query sceneservice scene.index ? main");
if ($currentScene != $mainScene){lx("scene.set [$mainScene]");}

for (my $i=1; $i<@fgLayers; $i++){
	lxout("showing this fgLayer : $i");
	my $id = lxq("query layerservice layer.id ? @fgLayers[$i]");
	lx("select.subItem [$id] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
}
for (my $i=0; $i<@bgLayers; $i++){
	lxout("showing this bgLayer : $i");
	my $id = lxq("query layerservice layer.id ? @bgLayers[$i]");
	lx("layer.setVisibility [$id] [-1]");
}



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#ALTER THE SCENE SO IT'S NOT NEW AND OVERWRITTEN SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub alterScene{
	lxout("[->] I kept modo from overwriting this scene because it's name is 'Untitled' and had never been changed");
	lx("!!tool.set xfrm.move on");
	lx("!!tool.setAttr xfrm.move X [0 m]");
	lx("!!tool.setAttr xfrm.move Y [0 m]");
	lx("!!tool.setAttr xfrm.move Z [0 m]");
	lx("!!tool.doApply");
	lx("!!tool.set xfrm.move off");
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
