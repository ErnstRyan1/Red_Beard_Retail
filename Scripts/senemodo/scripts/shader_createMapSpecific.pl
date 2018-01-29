#perl
#ver 1.23
#author : Seneca Menard
#this script is NOT done yet!!!  but it's for letting you select N polys and it will do 3 things : swap their materials with a new one with an _ in it's name..  then create new text shaders for those materials...  Then apply a photoshop script on all the loaded images to do the color match and save 'em out to a new name..
#(2-16-10 bugfix) : found a bug with \ brackets in the shadertreetools sub.  i should probably fix that for real in the sub some day.  heh.
#(3-2-10 bugfix) : ptyp fix
#(7-29-10 bugfix) : p4 always returns an "i failed message" 100% of the time and so i was cancelling the script when i shouldn't.
#(8-18-19 bugfix) : added doom4 to the list of m2 paths
#(6-20-11 bugfix) : shaderTreeTools ptag error fix

my $sixtyFourBitQuery = lxq("query platformservice isapp64bit ?");
my $sene_imgEditPath = lxq("user.value sene_imgEditPath ?");
my $gamePath = lxq("user.value sene_matRepairPath ?");
if		($gamePath =~ /rage/i)	{	our $shaderFile = "W:\/Rage\/base\/decls\/m2\/senScriptGenMaterials.m2";	}
elsif	($gamePath =~ /doom/i)	{	our $shaderFile = "W:\/doom4\/base\/decls\/m2\/senScriptGenMaterials.m2";	}
else							{	popup("The 'GAME PATH' option inside the GLOBAL OPTIONS pulldown in the sen_superUVsMini.cfg is not matching rage or doom, so I'm cancelling the script");	}

if (-e $shaderFile){
	unless (-w $shaderFile){
		system("p4 edit \"$shaderFile\"");
		unless (-w $shaderFile){
			die("The material file could not be checked out by perforce and so I'm cancelling the script\n$shaderFile");
		}
	}
}else{
	die("This m2 file doesn't exist so I can't write out the materials to it! :\n$shaderFile");
}
if (!-e $sene_imgEditPath){
	popup("The IMAGE EDITOR PATH specified in the SUPER UVS MINI-->GLOBAL OPTIONS form doesn't point to an EXE that exists.  Please correct that");
	die;
}

#script arguments
foreach my $arg (@ARGV){
	if 		($arg eq "characterAO")		{	our $characterAO = 1;		}
	elsif	($arg eq "applyAOImages")	{	our $applyAOImages = 1;		}
	elsif	($arg eq "force")			{	our $force = 1;				}
	elsif	($arg eq "multipleScenes")	{	our $multipleScenes = 1;	}
}

#args for shader learning
my $gameDir = lxq("user.value sene_matRepairPath ?");
$gameDir =~ s/\\/\//g;
my $lastFoundSlashPosition = rindex($gameDir, "\/") - length($gameDir);
if ($lastFoundSlashPosition != -1){$gameDir .= "\/";}
my %shaderText = ();
my %decipherShaders = ();

if 		($gameDir =~ /rage/i)	{our $shaderDir = "W:\/Rage\/base\/decls\/m2";}
elsif	($gameDir =~ /doom/i)	{our $shaderDir = "W:\/Rage\/base\/m2";}
else							{our $shaderDir = quickDialog("What is your game's material dir ?",string,"W:\/Rage\/base\/decls\/m2","","");}

#run the script on multiple files or just one
if ($multipleScenes == 1){
	my $modoVer = lxq("query platformservice appversion ?");
	lx("dialog.setup fileOpenMulti");
	if ($modoVer > 300)	{	lx("dialog.fileTypeCustom format:[lxo] username:[LXO to load] loadPattern:[*.lxo] saveExtension:[lxo]");	}
	else				{	lx("dialog.fileType scene");																				}
	lx("dialog.title [Select the LXOs you wish to bake AO to...]");
	lx("dialog.open");
	my @files = lxq("dialog.result ?");

	foreach my $file (@files){
		lxout("=============================================================\n[->] : Rendering $file\n=============================================================");
		lx("!!scene.open {$file}");
		lx("!!select.type polygon");
		lx("!!select.all");
		main();
		lx("!!scene.close");
		%shaderTreeIDs = ();
	}
}else{
	main();
}



#main loop
sub main{
	#this is to create the original per-layer poly list
	my %polys = ();
	my @firstLastPolys = createPerLayerElemList(poly,\%polys);
	my %selectedMaterials = ();
	my @oldMaterials = ();
	my @newMaterials = ();
	#args for photoshop
	my @photoshopFiles = ();

	#if ($sixtyFourBitQuery == 0){our $app = "start /min sndrec32 /play /close C:\\WINDOWS\\Media\\Notify.wav";}else{our $app = "start /min c:/sndrec32.exe /play /close C:\\WINDOWS\\Media\\Notify.wav";}  system qx/$app/;
	userValueTools(sene_matGenSuffix,string,config,"Material name suffix :","","","",xxx,xxx,"","_tv");
	my $sene_matGenSuffix = lxq("user.value sene_matGenSuffix ?");
	if ($characterAO == 1)	{	$sene_matGenSuffix = "_" . lxq("query sceneservice scene.name ? current}");	$sene_matGenSuffix =~s/\..*//g;	}
	else					{	$sene_matGenSuffix =	quickDialog("Material name suffix :",string,$sene_matGenSuffix,"","");				}


	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	#MAIN LOOP
	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	foreach my $key (sort {$polys{$a} <=> $polys{$b}} keys %polys){
		#lxout("----------------------------------------------------");
		#lxout("layer=$key <> polys = @{$polys{$key}}");
		#lxout("----------------------------------------------------");
		my $activeLayerID = lxq("query layerservice layer.id ? $key");
		my $activeLayer = $key;
		my %polyMaterialTable = ();
		my @changedPolys = ();
		%shaderText = ();
		%decipherShaders = ();



		#go through this layer's materials and put the polys into a list
		foreach my $poly (@{$polys{$key}}){
			my $material = lxq("query layerservice poly.material ? $poly");
			$selectedMaterials{$material} = 1;
			push(@{$polyMaterialTable{$material}},$poly);
		}

		#material loop (to assign new materials)
		foreach my $material (keys %polyMaterialTable){
			#lxout("Doing this material loop : $key");

			#skip the eye materials if running the characterAO routine
			if (($characterAO == 1) && (($material =~ /eye/i) || ($material =~ /teeth/i) || ($material =~ /tongue/i))){  #/[^a-zA-Z0-9][0-9]*eye[0-9]*[^a-zA-Z0-9]/i
				lxout("Skipping this file because it has the word 'eye', 'teeth', or 'tongue' in it : $material");
				next;
			}

			#sort the poly list
			@{$polyMaterialTable{$material}} = sort {$a <=> $b} @{$polyMaterialTable{$material}};
			returnCorrectIndice(\@{$polyMaterialTable{$material}},\@changedPolys);

			#select this layer's material's polys
			lx("select.drop polygon");
			lx("select.element $activeLayer polygon add {$_}") for @{$polyMaterialTable{$material}};

			#find the smoothing angle for the material we used to be using

			#printHashTableArray(\%shaderTreeIDs,shaderTreeIDs);
			$material =~ s/\\/\//g;
			my $materialID = shaderTreeTools(ptag , materialID , $material);
			lx("select.subItem {$materialID} set textureLayer;render;environment;mediaClip;locator");
			my $smoothing = lxq("item.channel advancedMaterial\$smAngle ?");
			#lxout("materialID = $materialID <> smoothing = $smoothing");


			#see if material already uses the suffix.  if so, keep it.  if not, add it.
			if ($material =~ /$sene_matGenSuffix$/)	{our $newMaterialName = $material;						}
			else									{our $newMaterialName = $material . $sene_matGenSuffix;	}
			lx("poly.setMaterial {$newMaterialName}");
			lx("item.channel advancedMaterial\$smAngle {$smoothing}");
		}
	}


	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	#NOW GO THROUGH ALL THE NEW MATERIALS AND CREATE THE RAGE SHADERS IF THEY DON'T EXIST
	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	foreach my $material (keys %selectedMaterials){
		#skip the eye materials if running the characterAO routine
		if (($characterAO == 1) && (($material =~ /eye/i) || ($material =~ /teeth/i) || ($material =~ /tongue/i))){
			#lxout("SUB2 : skipping this material because it had the word 'eye' in it : $material");
			next;
		}

		if ($material =~ /$sene_matGenSuffix$/)	{
			our $materialName = $material;
			$materialName =~ s/$sene_matGenSuffix$//;
			our $newMaterialName = $material;
		}
		else{
			our $materialName = $material;
			our $newMaterialName = $material . $sene_matGenSuffix;
		}
		push(@oldMaterials,$materialName);
		push(@newMaterials,$newMaterialName);
	}

	opendir($shaderDir,$shaderDir) || die("Cannot opendir $shaderDir");
	@files = (sort readdir($shaderDir));

	createShaderArray(@oldMaterials);
	createShaderArray(@newMaterials);
	close($shaderDir);


	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	#CREATE THE SHADERS
	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	for (my $i=0; $i<@newMaterials; $i++){
		if (!exists $shaderText{@newMaterials[$i]}){
			if (!exists $shaderText{@oldMaterials[$i]}){
				lxout("[<---------------------------------------------------------------->]");
				lxout("[<---------------------------------------------------------------->]");
				lxout("[<---------------------------ALERT!!!!!-------------------------------->]");
				lxout("[<---------------------------------------------------------------->]");
				lxout("[<---------------------------------------------------------------->]");
				lxout("[<- This old material doesn't exist and so I couldn't create the new one! : @oldMaterials[$i] ->]");
				next;
			}
			else{
				lxout("[->] : Creating this new material : @newMaterials[$i]");
				open (FILE, ">>$shaderFile") or popup("This file doesn't exist : \n$shaderFile");
				print FILE "\n" . @newMaterials[$i] . "\n";
				print FILE "{\n";

				foreach my $line (@{$shaderText{@oldMaterials[$i]}}){
					#for (my $i=0; $i<@words; $i++){lxout("word=@words[$i]");}

					if ($line =~ /diffusemap/i){
						#copy/paste the original diffusemap and send the file to the PS open list
						$_ = $line;
						s/\\/\//g;
						my ($oldDiffuseMap) = /([a-zA-Z0-9_\/]+[\/][a-zA-Z0-9_\/]+)/; #must put () around variable and search term for this to work
						$oldDiffuseMap = $gameDir . $oldDiffuseMap . "\.tga"; #TEMP : this is the file i want photoshop to open
						my $newDiffuseMap = $gameDir . @newMaterials[$i] . "\.tga";
						if (!-e $oldDiffuseMap){
							popup("Skipping the copy/paste of this file because it doesn't exist : $oldDiffuseMap\nThus I couldn't create this diffusemap : $newDiffuseMap\nClick OK to allow the script to continue");
						}else{
							if (($characterAO != 1) && (-e $newDiffuseMap)){
								popup("Skipping the creation of this file because it already existed : $newDiffuseMap\nClick OK to allow the script to continue");
							}else{
								#lxout("attempting to copy this file : $oldDiffuseMap\n to this file : $newDiffuseMap");
								$oldDiffuseMap =~ s/\//\\/g;
								$newDiffuseMap =~ s/\//\\/g;
								push(@photoshopFiles,$newDiffuseMap);
								system "copy $oldDiffuseMap $newDiffuseMap";
							}
						}

						#create the diffuse map shader line
						$line = "\tdiffusemap\t\t\t\t" . @newMaterials[$i] . "\n";
					}else{
						my @words = split (/[\t\s]+/, $line);
						my $length = length @words[1];
						my $diff = 29 - ($length+4);
						my $tabs = int(0.5+($diff*.25));
						$line = "\t";

						for (my $i=1; $i<@words; $i++){
							if ($i == 2)						{$line .= "\t" x $tabs;}
							if (($i < 2) || ($i == $#words))	{$line .= @words[$i];}
							else								{$line .= @words[$i]." ";}
						}
						$line .= "\n";
					}
					$line =~ s/\\/\//g;
					print FILE $line;
				}
				print FILE "}";
			}
		}
	}

	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	#GENERATE THE AO
	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	if ($characterAO == 1){
		my $vmapName = &findCorrectUVmap;

		#build vmap table to skip preexisting vmaps
		my %vmapTable;
		my $vmapCount = lxq("query layerservice vmap.n ? all");
		for (my $i=0; $i<$vmapCount; $i++){
			if (lxq("query layerservice vmap.type ? $i") eq "texture"){
				my $name = lxq("query layerservice vmap.name ? $i");
				#lxout("name = $name");
				$vmapTable{$name} = 1;
			}
		}

		#create the new uv sets
		foreach my $material (@newMaterials){
			if (exists $vmapTable{$material}){
				#lxout("[->] : Skipping creating the {$material} vmap because it already existed");
			}else{
				lx("!!select.drop polygon");
				lx("!!select.polygon add material face {$material}");
				lx("!!select.vertexMap {$vmapName} txuv replace");
				lx("!!uv.copy");
				lx("!!vertMap.new {$material} txuv");
				lx("!!uv.paste");
			}
		}

		lx("scene.save");

		#query the TGA SIZE and generate the AO
		my @missingTGAs;
		my $alreadySetProperRenderOutputs = 0;
		foreach my $material (@newMaterials){
			my $dir = $material;
			$dir =~ s/\\/\//g;
			my $tgaPath = $gameDir . $dir . "\.tga";
			my $aoPath = $gameDir . $dir . "_ao\.tga";

			if ((-e $aoPath) && ($force == 0)){
				lxout("[->] : Skipping creating this ao map because it already exists : $aoPath");
			}else{
				my @tgaSize = queryTGASize($tgaPath);

				#run these render output changes every time
				lx("select.subItem [@{$shaderTreeIDs{polyRender}}[0]] set textureLayer;render;environment;mediaClip;locator");
				lx("render.res 0 {@tgaSize[0]}");
				lx("render.res 1 {@tgaSize[1]}");

				#run these render output changes only once
				if ($alreadySetProperRenderOutputs == 0){
					$alreadySetProperRenderOutputs = 1;
					lx("item.channel polyRender\$aa s1");
					lx("item.channel polyRender\$bucketX 4");
					lx("item.channel polyRender\$bucketY 4");

					my @renderOutputs = shaderTreeTools(findAllOfType,renderOutput);
					my $foundFinalColor = 0;
					my $foundAlpha = 0;
					foreach my $id (@renderOutputs){
						lx("select.subItem {$id} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
						my $outputEffect = lxq("shader.setEffect ?");
						if ($outputEffect eq "shade\.color"){
							$foundFinalColor = 1;
							lx("shader.setEffect occl.ambient");
							lx("item.channel renderOutput\$occlRays 256");
						}else{
							lx("select.subItem {$id} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
							lx("texture.delete");
						}
					}

					if ($foundFinalColor == 0){
						lx("select.subItem [@{$shaderTreeIDs{polyRender}}[0]] set textureLayer;render;environment;mediaClip;locator");
						lx("shader.create renderOutput");
						lx("shader.setEffect occl.ambient");
						lx("item.channel renderOutput\$occlRays 256");
					}
					if ($foundAlpha == 0){
						lx("select.subItem [@{$shaderTreeIDs{polyRender}}[0]] set textureLayer;render;environment;mediaClip;locator");
						lx("shader.create renderOutput");
						lx("shader.setEffect shade.alpha");
					}
				}

				#lxout("material = $material");
				lx("!!select.vertexMap {$material} txuv replace");
				lx("bake filename:{$aoPath} format:TGA");
			}
		}
		#if ($sixtyFourBitQuery == 0){our $app = "start /min sndrec32 /play /close C:\\WINDOWS\\Media\\Notify.wav";}else{our $app = "start /min c:/sndrec32.exe /play /close C:\\WINDOWS\\Media\\Notify.wav";}  system qx/$app/;
	}

	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	#NOW SEND THE NEW TGAS TO PHOTOSHOP
	#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	if ((@photoshopFiles > 0) && ($characterAO != 1)){system $sene_imgEditPath,@photoshopFiles;}
}

















#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------SUBROUTINES------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------------------------

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY TGA SIZE SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : queryTGASize($filePath);
#requires readChar sub
sub queryTGASize{
	open (TGA, "<@_[0]") or return(0,0);
	binmode(TGA); #explicitly tells it to be a BINARY file

	#read the TGA header info
	my $buffer;
	my $identSize =			readChar(TGA,1,C);
	my $palette = 			readChar(TGA,1,C);
	my $imageType = 		readChar(TGA,1,C);
	my $colorMapStart = 	readChar(TGA,2,S);
	my $colorMapLength = 	readChar(TGA,2,S);
	my $colorMapBits =		readChar(TGA,1,C);
	my $xStart =			readChar(TGA,2,S);
	my $yStart =			readChar(TGA,2,S);
	my $width =				readChar(TGA,2,S);
	my $height =			readChar(TGA,2,S);
	my $bits =				readChar(TGA,1,C);
	my $descriptor = 		readChar(TGA,1,C);
	my %pixels;
	if ($bits == 24)		{our $readLength=3;}else{our $readLength=4;}
	@currentSize = 			($width,$height);
	$bitMode = 				$bits;
	close(TGA);

	return($width,$height);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#READ BINARY CHARS FROM FILE (there's no offsetting. it's for reading entire file one step at a time)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : readChar(FILEHANDLE,$howManyBytes,$packCharType);
sub readChar{
	read(@_[0], $buffer, @_[1]);
	return unpack(@_[2],$buffer);
}


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#FIND CORRECT UVMAP SUB : (finds the first uv map being used and returns it's indice)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub findCorrectUVmap{
	my $vmapCount = lxq("query layerservice vmap.n ? all");
	my $vmapTest = 0;
	for (my $i=0; $i<$vmapCount; $i++){
		if (lxq("query layerservice vmap.type ? $i") eq "texture"){
			my @testVmapValues = lxq("query layerservice poly.vmapValue ? 0");
			for (my $u=0; $u<@testVmapValues; $u++){
				if (@testVmapValues[$u] != 0){
					#lxout("this vmap value not equal 0");
					$vmapTest = 1;
					last;
				}
			}
			if ($vmapTest == 1){
				#lxout("Automatically selected vmap $i");
				my $name = lxq("query layerservice vmap.name ? $i");
				lx("select.vertexMap {$name} txuv replace");
				return $name;
				last;
			}
		}
	}

	if ($vmapTest == 0){die("The script is being cancelled because apparently this model doesn't have any legal uv maps");}
}



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CREATE A PER LAYER ELEMENT SELECTION LIST (retuns first and last elems, and ordered list for all layers)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#usage : my @firstLastPolys = createPerLayerElemList(poly,\%polys);
sub createPerLayerElemList{
	my $hash = @_[1];
	my @totalElements = lxq("query layerservice selection ? @_[0]");
	if (@totalElements == 0){die("\\\\n.\\\\n[---------------------------------------------You don't have any @_[0]s selected and so I'm cancelling the script.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}

	#build the full list
	foreach my $elem (@totalElements){
		$elem =~ s/[\(\)]//g;
		my @split = split/,/,$elem;
		push(@{$$hash{@split[0]}},@split[1]);
	}

	#return the first and last elements
	return(@totalElements[0],@totalElements[-1]);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RETURN CORRECT INDICES SUB : (this is for finding the new poly indices when they've been corrupted because of earlier poly indice changes)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : returnCorrectIndice(\@currentPolys,\@changedPolys);
#notes : both arrays must be numerically sorted first.  Also, it'll modify both arrays with the new numbers
sub returnCorrectIndice{
	my @firstElems = ();
	my @lastElems = ();
	my %inbetweenElems = ();
	my @newList = ();

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

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SHADER SCALE RETURN SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub shaderScaleReturn{
	my $string;
	my @list;
	my $constantColorCheck=0;
	if (@_[0] =~ /constantcolor/i){
		#lxout("@_[0] : this pass has constantcolor applied");
		my $line = @_[0];
		$line =~ s/constantcolor//i;
		$line =~ tr/() \t//d;
		@list = split(/,/,$line);
		unshift(@list,"constantColor");
		if (@list[4] == ""){@list[4] = 1;}
		$constantColorCheck=1;
	}elsif (@_[0] =~ /scale\(/i){
		#lxout("@_[0] : yes, it has scale applied");
		if (@list[4] == 0){@list[4] == 1;}
		@list = split/,/,@_[0];
		@list[0] =~ s/^.*scale\(//i;
		@list[0] =~ s/\s//g;
		@list[1] = numberReturn(@list[1]);
		@list[2] = numberReturn(@list[2]);
		@list[3] = numberReturn(@list[3]);
		@list[4] = numberReturn(@list[4]);
	}else{
		#lxout("@_[0] : no, it doesn't have scale applied");
		@list[0] = @_[0];
		@list[0] =~ tr/\n \t//d;
		@list[1] = 1;
		@list[2] = 1;
		@list[3] = 1;
		@list[4] = 1;
	}

	#lxout("end list = @list");
	if ($constantColorCheck == 0){
		if (@list[0] !~ /\.tga$/i){@list[0] .= ".tga"}
		$string = $gameDir.@list[0].",".@list[1].",".@list[2].",".@list[3].",".@list[4];
	}else{
		$string = @list[0].",".@list[1].",".@list[2].",".@list[3].",".@list[4];
	}
	return ($string);
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DECIPHER SHADER SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# requires %decipherShaders;
# requires shaderScaleReturn subroutine
sub decipherShaders{ #(0=renderbump 1=powerscale 2=specularscale 3=localmap 4=diffusemap 5=specularmap 6=transmap 7=additivePass)
	my $transMapSearch = 0;
	my $transMapArrayNum = 0;

	foreach my $key (keys %shaderText){
		foreach my $line (@{$shaderText{$key}}){
			#lxout("line = $line");
			if ($transMapSearch != 1){
				#7----------BASICADD---------
				if		(($line =~ /stageProgram/i) && ($line =~ /add/i)){
					$transMapSearch = 1;
					$transMapArrayNum = 7;
				}
				#6---------COVERTRANS--------
				elsif	(($line =~ /customprog/i) && ($line =~ /covert/i)){
					$transMapSearch = 1;
					$transMapArrayNum = 6;
				}
				#5--------SPECULARMAP--------
				elsif	($line =~ /specularmap/i){
					my $printLine = $line;
					$printLine =~ s/^.*specularmap\W*//i;
					$printLine =~ s/\\/\//g;
					$printLine =~ s/\W*clamp\W*//i;
					$printLine = shaderScaleReturn($printLine);
					@{$decipherShaders{$key}}[5] = $printLine;
				}
				#4---------DIFFUSEMAP--------
				elsif	($line =~ /diffusemap/i){
					my $printLine = $line;
					$printLine =~ s/^.*diffusemap\W*//i;
					$printLine =~ s/\\/\//g;
					$printLine =~ s/\W*clamp\W*//i;
					$printLine = shaderScaleReturn($printLine);
					@{$decipherShaders{$key}}[4] = $printLine;
				}
				#3----------BUMPMAP----------
				elsif	($line =~ /bumpmap/i){
					my $printLine = $line;
					$printLine =~ s/^.*bumpmap[\s\t]*//;
					$printLine =~ s/\\/\//g;
					if ($line =~ /addnormals/i){
						my @printLine = split(/heightmap/i, $printLine);
						@printLine[1] =~ s/\n//;				#del \n
						my $bumpAmount = @printLine[1];
						$bumpAmount =~ s/.*,//;					#del (space*,)
						$bumpAmount = numberReturn($bumpAmount);#del non numbers
						@printLine[0] =~ s/^.*\(\W*//;			#del leading*(
						@printLine[0] =~ s/\s*,.*//;			#del ,+
						@printLine[0] =~ s/\W*clamp\W*//i;		#del clamp
						@printLine[1] =~ s/,\s*.*//;			#del ,+
						@printLine[1] =~ tr/() \t//d;			#del tabs, spaces, ()
						@printLine[1] =~ s/\W*clamp\W*//i;		#del clamp

						if (@printLine[0] !~ /\.tga$/i){@printLine[0] .= ".tga"}
						if (@printLine[1] !~ /\.tga$/i){@printLine[1] .= ".tga"}
						if ($bumpAmount ne ""){$bumpAmount = ",".$bumpAmount;}
						@{$decipherShaders{$key}}[3] = "A,".$gameDir.@printLine[0].",".$gameDir.@printLine[1].$bumpAmount;
					}elsif ($line =~ /heightmap/i){
						$printLine =~ s/heightmap\W*//;
						$printLine =~ s/\W*clamp\W*//i;
						my @printLine = split(/,/,$printLine);
						@printLine[1] =~ s/\D//g;
						if (@printLine[0] !~ /\.tga$/i){@printLine[0] .= ".tga"}
						if (@printLine[1] ne ""){@printLine[1] = ",".@printLine[1];}
						@{$decipherShaders{$key}}[3] = "H,".$gameDir.@printLine[0].@printLine[1];
					}else{
						$printLine =~ s/\s$//g;
						$printLine =~ s/\t$//g;
						$printLine =~ s/\n//;
						$printLine =~ s/\W*clamp\W*//i;
						if ($printLine !~ /\.tga$/i){$printLine .= ".tga"}
						@{$decipherShaders{$key}}[3] = "B,".$gameDir.$printLine;
					}
				}
				#2--------SPECULARSCALE---------
				elsif	($line =~ /specularscale/i){
					my $printLine = $line;
					@{$decipherShaders{$key}}[2] = numberReturn($printLine);
				}
				#1----------POWERSCALE----------
				elsif	($line =~ /powerscale/i){
					my $printLine = $line;
					@{$decipherShaders{$key}}[1] = numberReturn($printLine);
				}
				#0----------RENDERBUMP----------
				elsif	($line =~ /renderbump/i){
					@{$decipherShaders{$key}}[0] = 1;
				}
			}else{
				if ($transMapArrayNum == 6){
					if ($line =~ /covermap/o){
						$transMapSearch = 0;
						my $printLine = $line;
						$printLine =~ s/^.*covermap\W*//i;
						$printLine =~ s/\n//;
						$printLine =~ s/\s//g;
						$printLine =~ s/\t//g;
						$printLine =~ s/\\/\//g;
						$printLine =~ s/\W*clamp\W*//i;
						if ($printLine !~ /\.tga$/i){$printLine .= ".tga"}
						@{$decipherShaders{$key}}[6] = $gameDir.$printLine;
					}elsif ($line =~ /}/){
						#lxout("coverTrans : hit the end of the shader group and couldn't find transmap, so i'm turning transmap search off");
						$transMapSearch = 0;
					}
				}elsif ($transMapArrayNum == 7){
					if ($line =~ /transmap/i){
						$transMapSearch = 0;
						my $printLine = $line;
						$printLine =~ s/^.*transmap\W*//i;
						$printLine =~ s/\\/\//g;
						$printLine =~ s/\W*clamp\W*//i;
						$printLine = shaderScaleReturn($printLine);
						@{$decipherShaders{$key}}[7] = $printLine;
					}elsif ($line =~ /}/){
						#lxout("basicadd : hit the end of the shader group and couldn't find transmap, so i'm turning transmap search off");
						$transMapSearch = 0;
					}
				}
			}
		}
	}
}



#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CREATE SHADER LINES HASH TABLE SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub createShaderArray{
	foreach my $shader (@_){
		$shader =~ s/\\/\//g;
		my $startedShaderBrackets = 0;
		my $shaderBrackets = 0;
		if (searchForShader(\@files,$shader) =~ /{/){$shaderBrackets++;}
		while (<m2File>){
			my $string = $_;
			$string =~ s/\/\/.*//;
			if ($string =~ /{/){$shaderBrackets++; $startedShaderBrackets = 1;}
			if ($string =~ /}/){$shaderBrackets--;}
			if ($string =~ /[a-zA-Z0-9_]/){push (@{$shaderText{$shader}},$string);}
			if (($startedShaderBrackets == 1) && ($shaderBrackets == 0)){close(m2File);last;}
		}
	}
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SEARCH M2s FOR SHADER HEADER SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub searchForShader{
	my $shaderName = @_[1];
	$shaderName =~ s/\\/\//g;
	$shaderName =~ s/\//\\\//g;
	my @words = split(/\//,$shaderName);
	#lxout("Looking for this material : $shaderName");

	foreach my $file (@{@_[0]}){
		if ($file !~ /.m2/i){next;}
		my $filePath = $shaderDir . "\/"  . $file;

		open (m2File, "<$filePath") or die("I couldn't find the material file");
		my $i = 1;
		while (<m2File>){
			if ($_ =~ /@words[-1]\b/i){
				if ($_ !~ /^\s*\/\//){
					$_ =~ s/(\/\/|\\\\).*//;
					$_ =~ s/\\/\//g;
					if ( ($_ =~ /^$shaderName[^a-zA-Z0-9_\\\/]/i) || ($_ =~ /^[\s\t]*$shaderName[^a-zA-Z0-9_\\\/]/i) || ($_ =~ /^[\s\t]*material\s+$shaderName[^a-zA-Z0-9_\\\/]/i) ){
						#lxout("Found it here : $file : (line $i)");
						return $_;
					}
				}
			}
			$i++;
		}
		close(m2File);
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

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SHADER TREE TOOLS SUB (ver1.1) (MODDED : all the lxouts are silenced)
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
	#lxout("[->] Running ShaderTreeTools sub <@_[0]> <@_[1]>");
	our %shaderTreeIDs;

	#----------------------------------------------------------
	#PTAG SPECIFIC :
	#----------------------------------------------------------
	if (@_[0] eq "ptag"){
		#MASK ID-------------------------
		if (@_[1] eq "maskID"){
			#lxout("[->] Running maskID sub");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			return($shaderTreeIDs{$ptag}[0]);
		}
		#MATERIAL ID---------------------
		elsif (@_[1] eq "materialID"){
			#lxout("[->] Running materialID sub");
			shaderTreeTools(buildDbase);

			my $ptag = @_[2];
			$ptag =~ s/\\/\//g;
			return($shaderTreeIDs{$ptag}[1]);
		}
		#MASK EXISTS---------------------
		elsif (@_[1] eq "maskExists"){
			#lxout("[->] Running maskExists sub");
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
			#lxout("[->] Running addImage sub");
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
			#lxout("[->] Running delChildType sub (deleting all @_[3]s)");
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
			#lxout("[->] Running createMask sub");
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
			#lxout("[->] Running children sub");
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

			#lxout("[->] Running buildDbase sub");
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
						#lxout("found ptag = $ptag");
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
				#lxout("[->] : Deleting these materials because they're not assigned to one ptag :\n@deleteList");
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