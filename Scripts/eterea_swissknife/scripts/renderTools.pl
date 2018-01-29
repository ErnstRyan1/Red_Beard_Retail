#perl
#author : Seneca Menard
#ver 0.613
#(11-28-10 fix) : new gradient now uses a single popup window.
#(6-20-11 fix) : shaderTreeTools ptag error fix
#(2-16-12 fix) : 601 put in file path suffixes, so this is removing those.
#(3-16-12 fix) : put in a crash if it can't find the atlas texture projection preset. (need to put the gradients in either through code or to put the preset into the kit.)
#(10-15-12 feature) : put in a feature to create an alpha out in an item mask for each of the items you have selected.  : @renderTools.pl createItemAlphas :

#NOTE : gradient linear now uses a coded grad, so that's good.  tri-axis can't yet and that's because of the bug with being able to select newly created curve nodes.  obviously i'll still have to go ahead and convert tri-axis to not use a preset once the new gradient code works so that other folks can use this script.
my $os = lxq("query platformservice ostype ?");
my $userDir = lxq("query platformservice path.path ? user");
my $modoVer = lxq("query platformservice appversion ?");
lxout("modoVer = $modoVer");
OSPathNameFix($userDir);

#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																		CVARS																		====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
userValueTools(sene_AA,integer,config,sene_AA,"","","",0,128,"",0);
userValueTools(sene_blurryRays,integer,config,sene_blurryRays,"","","",0,4096,"",64);


#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#===																SCRIPT ARGUMENTS																====
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
#=====================================================================================================================================
foreach my $arg (@ARGV){
	if		($arg =~ /queryScene/i)			{	our $queryScene = 1;	}
	elsif	($arg == 1)						{	our $scalar = 1;		}
	elsif	($arg =~ /itemList/i)			{	our $itemList = 1;		}
	elsif 	($arg =~ /blurryRefRays/i)		{	&blurryRefRays;			}
	elsif 	($arg =~ /changeSmoothing/i)	{	&changeSmoothing;		}
	elsif	($arg =~ /scaleMatBrightness/i)	{	&scaleMatBrightness;	}
	elsif	($arg =~ /diff_fixGamma/i)		{	&diff_fixGamma;			}
	elsif	($arg =~ /setGamma/i)			{	&setGamma;				}
	elsif	($arg =~ /scaleLighting/i)		{	&scaleLighting;			}
	elsif	($arg =~ /fixMatrGroupEffect/i)	{	&fixMatrGroupEffect;	}
	elsif	($arg =~ /renderDiagnostics/i)	{	&renderDiagnostics;		}
	elsif	($arg =~ /setAreaLightRays/i)	{	&setAreaLightRays;		}
	elsif	($arg =~ /setAllLightRays/i)	{	&setAllLightRays;		}
	elsif	($arg =~ /selectAllByType/i)	{	&selectAllByType;		}
	elsif	($arg =~ /gradientLinear/i)		{	&gradientLinear;		}
	elsif	($arg =~ /triAxisProjection/i)	{	&triAxisProjection;		}
	elsif	($arg =~ /nAxisProjection/i)	{	&nAxisProjection;		}
	elsif	($arg =~ /renderSkyBox/i)		{	&renderSkyBox;			}
	elsif	($arg =~ /createItemAlphas/i)	{	&createItemAlphas;		}
	elsif	($arg =~ /toggleRadiosity/i)	{	&toggleRadiosity;		}
	elsif	($arg eq "resolution")			{	&resolution;			}
	elsif	($arg eq "x")					{	our $axis = 0;			}
	elsif	($arg eq "y")					{	our $axis = 1;			}
	elsif	($arg eq "z")					{	our $axis = 2;			}
	elsif	($arg eq "-")					{	our $direction = "neg";	}
	elsif	($arg eq "keepProportion")		{	our $keepProportion = 1;}
	elsif	($arg =~ /\d.*,\d/)				{	our $resolution = $arg;	}
}

sub toggleRadiosity{
	lx("!!select.itemType type:polyRender mode:add");
	my $renderID = lxq("query sceneservice selection ? polyRender");

	if ($direction eq "neg"){
		lx("!!item.channel polyRender\$globEnable false");
		lx("item.channel ambRad 0.5");
	}else{
		if (lxq("!!item.channel polyRender\$globEnable ?") == 1){
			lx("!!item.channel polyRender\$globEnable false");
			lx("item.channel ambRad 0.5");
		}else{
			lx("!!item.channel polyRender\$globEnable true");
			lx("item.channel ambRad 0.0");
		}
	}
}

sub createItemAlphas{
	my %itemTypes;
		$itemTypes{"mesh"} = 1;
		$itemTypes{"triSurf"} = 1;
		$itemTypes{"group"} = 1;

	#get todoList
	my %todoList;
	my @meshes = lxq("query sceneservice selection ? all");
	foreach my $id (@meshes){
		if ($itemTypes{lxq("query sceneservice item.type ? {$id}")} == 1){
			my $name = lxq("query sceneservice item.name ? {$id}");
			$todoList{$name} = 1;
		}
	}

	#query render output ID
	lx("!!select.itemType type:polyRender mode:add");
	my $renderID = lxq("query sceneservice selection ? polyRender");


	#remove the preexisting item masked alphaoutputs from the todo list.
	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			lx("select.subItem {$id} set textureLayer;render;environment;light;camera;scene;replicator;mediaClip;txtrLocator");
			my $name = lxq("mask.setMesh ?");

			if ($todoList{$name} == 1){
				my @children = lxq("query sceneservice txLayer.children ? {$id}");
				foreach my $child (@children){
					if (lxq("query sceneservice txLayer.type ? {$child}") eq "renderOutput"){
						if (lxq("item.channel effect {?} set {$child}") eq "shade.alpha"){
							lxout("[->] : skipping this id because it already has an item mask with an alphaout in it : '$name'");
							delete $todoList{$name};
							last;
						}
					}
				}
			}
		}
	}

	#build the item masked alphaoutputs for the todo list
	foreach my $name (keys %todoList){
		my $printName = "alpha_" . $name;
		lx("!!select.drop item");
		lx("!!shader.create mask");
		lx("texture.parent {$renderID} -1");
		lx("mask.setMesh {$name}");
		lx("!!shader.create renderOutput");
		lx("shader.setEffect shade.alpha");

		lx("item.name {$printName} renderOutput");
		popup("sldkjf");
		lxout("[->] : created alphaOut for this id : '$name'");
	}

}

#n-axis texture projection
sub nAxisProjection{
	my $currentScene = lxq("query sceneservice scene.index ? active");
	my $mainlayer = lxq("query layerservice layers ? main");
	my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
	my @verts = lxq("query layerservice verts ? selected");
	if (@verts < 2){	die("Canceling script don't have enough verts selected.  You must have at least two selected. (1 for an origin and 2 for the destination)");}
	my @lastVertPos = lxq("query layerservice vert.pos ? $verts[-1]");
	my @clipSize;
	my @textureScale = (1,1,1);

	#figure out which texture to use
	my @selectedClips = clipsSelected();
	my $imagePath;
	my $imageName;
	if (@selectedClips > 0)	{
		$imageName = lxq("query layerservice clip.name ? $selectedClips[0]");
		$imagePath = lxq("query layerservice clip.file ? $selectedClips[0]");
	}else{
		$imagePath = loadImage();
	}

	#ask for how harsh the projection falloff gradations should be
	my $projFalloffReply = quickDialog("Define the start and stop gradation points:",string,"start=0,stop=1","","");
	my @gradStartStop = split(/,/, $projFalloffReply);
	$_ =~ s/[^0-9.]//g for @gradStartStop;

	#ask for how the images are to be used
	my $imageEffect = popupMultChoice("How should these images be used?","Diffuse Color;Diffuse Amount;Specular Color;Specular Amount;Bump;Displacement;Vector Displacement;Normal",0);
	my $dispRange = "(-100% to 100%)";
	if ($imageEffect eq "Displacement"){$dispRange = popupMultChoice("Define the dispmap's value range:","(0% to 100%);(-100% to 100%)",1);}

	#ask for how many times texture should be scaled compared to the bbox
	my $textureTiles = quickDialog("How many times would you like the tex to tile within the bbox?",float,1,.01,100000);

	#determine distance from last vert to each texture locator
	my @layerBboxSize = lxq("query layerservice layer.bounds ? $mainlayer");
	my @bboxSize = arrMath(@layerBboxSize[3],@layerBboxSize[4],@layerBboxSize[5],@layerBboxSize[0],@layerBboxSize[1],@layerBboxSize[2],subt);
	my $largestBboxSize = $bboxSize[0];
	if ($bboxSize[1] > $largestBboxSize)	{	$largestBboxSize = $bboxSize[1];	}
	if ($bboxSize[2] > $largestBboxSize)	{	$largestBboxSize = $bboxSize[2];	}
	my $textureProjDist = $largestBboxSize * 10;

	#find which material to parent these textures to
	my $materialID = findAdvMatToParentTo();
	my $materialIDParent = lxq("query sceneservice txLayer.parent ? $materialID");

	#create locator for all the texture projections to target.
	lx("item.create locator mask:locator");
	my @locatorSelection = lxq("query sceneservice selection ? locator");
	my $locatorToRotateTo = $locatorSelection[-1];
	lx("transform.add type:pos item:{$locatorSelection[-1]}");
	lx("item.channel pos.X {$lastVertPos[0]} set {$locatorSelection[-1]}");
	lx("item.channel pos.Y {$lastVertPos[1]} set {$locatorSelection[-1]}");
	lx("item.channel pos.Z {$lastVertPos[2]} set {$locatorSelection[-1]}");
	lx("channel.create posNoise item:{$locatorSelection[-1]}");
	lx("channel.create rotNoise item:{$locatorSelection[-1]}");

	#create rotation and position jitters
	lx("channel.create posNoise float scalar false 0.0 false 0.0 0.0 {$mainlayerID}");
	lx("channel.create rotNoise float scalar false 0.0 false 0.0 0.0 {$mainlayerID}");

	#now go through each vert and create texture projection
	for (my $i=0; $i<$#verts; $i++){
		my @pos = lxq("query layerservice vert.pos ? $verts[$i]");
		my @vector = arrMath(unitVector(arrMath(@pos,@lastVertPos,subt)),$textureProjDist,$textureProjDist,$textureProjDist,mult);
		my @texturePos = arrMath(@lastVertPos,@vector,add);

		lx("texture.new {$imagePath}");
		lx("texture.parent {$materialIDParent} [-1]");
		my @imageMaps = lxq("query sceneservice selection ? imageMap");
		my @txtrLocators = lxq("query sceneservice selection ? txtrLocator");
		my $imageLocatorID = $txtrLocators[-1];
		if (@clipSize < 2){
			@clipSize = queryImageDimensions($imagePath);
			if		($clipSize[0] > $clipSizep[1])	{	@textureScale[1] = @textureScale[1] / @textureScale[0];	}
			elsif	($clipSize[0] < $clipSizep[1])	{	@textureScale[0] = @textureScale[0] / @textureScale[1];	}
			@textureScale = ($textureScale[0]*$largestBboxSize*1/$textureTiles , $textureScale[1]*$largestBboxSize*1/$textureTiles);
		}
		my $sclTransform = lxq("query sceneservice item.xfrmScl ? $txtrLocators[-1]");
		if ($sclTransform eq ""){lx("transform.add type:scl item:{$txtrLocators[-1]}");}
		lx("item.channel scl.X {@textureScale[0]} set {$txtrLocators[-1]}");
		lx("item.channel scl.Y {@textureScale[1]} set {$txtrLocators[-1]}");
		lx("item.channel scl.Z {@textureScale[1]} set {$txtrLocators[-1]}");
		lx("item.channel pos.X {$texturePos[0]} set {$txtrLocators[-1]}");
		lx("item.channel pos.Y {$texturePos[1]} set {$txtrLocators[-1]}");
		lx("item.channel pos.Z {$texturePos[2]} set {$txtrLocators[-1]}");
		lx("item.channel projType {planar} set {$txtrLocators[-1]}");

		if ($imageEffect ne "Diffuse Color"){lx("item.channel effect {$imageEffect} set {$imageMaps[-1]}");}
		if ( ($imageEffect eq "Vector Displacement") || (($imageEffect eq "Displacement") && ($dispRange eq "(-100% to 100%)")) ){
			lx("item.channel min {-1} set {$imageMaps[-1]}");
		}
		if ($imageEffect eq "Diffuse Color"){
			lx("item.channel aa {0} set {$imageMaps[-1]}");
			lx("item.channel pixBlend {nearest} set {$imageMaps[-1]}");
		}

		my $gradientID = newGradient("input:locatorIncAngle","values:$gradStartStop[0]_1_$gradStartStop[1]_0","blend:linearIn/linearOut","locatorPos:$texturePos[0]_$texturePos[1]_$texturePos[2]");
		popup("please forgive this god damn pause that i have to fucking put in.");
		lx("texture.setMask {$imageMaps[-1]} {$gradientID}");
		my $locatorName = lxq("texture.setLocator locator:?");
		my $locatorID = lxq("query sceneservice item.id ? {$locatorName}");

		lx("select.subItem {$imageLocatorID} set ;txtrLocator;textureLayer;locator");
		lx("select.subItem {$locatorToRotateTo} add mesh;meshInst;triSurf;gear.item;RPC.Mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
		lx("constraintDirection");
		my @constrainIDs = lxq("query sceneservice selection ? cmDirectionConstraint");

		lx("channelModifier.create cmNoise group025");
		my @channelModifiers = lxq("query sceneservice selection ? cmNoise");
		my $rand = rand(10000);
		lx("item.channel seed {$rand} set {$channelModifiers[-1]}");
		my $noisePosID1 = $channelModifiers[-1];

		lx("channelModifier.create cmNoise group025");
		@channelModifiers = lxq("query sceneservice selection ? cmNoise");
		my $rand = rand(10000);
		lx("item.channel seed {$rand} set {$channelModifiers[-1]}");
		my $noisePosID2 = $channelModifiers[-1];

		lx("channelModifier.create cmNoise group025");
		@channelModifiers = lxq("query sceneservice selection ? cmNoise");
		my $rand = rand(10000);
		lx("item.channel seed {$rand} set {$channelModifiers[-1]}");
		my $noiseRotID = $channelModifiers[-1];

		lx("channelModifier.create cmNoise group025");
		@channelModifiers = lxq("query sceneservice selection ? cmNoise");
		my $rand = rand(10000);
		lx("item.channel seed {$rand} set {$channelModifiers[-1]}");
		my $noiseSclID = $channelModifiers[-1];

		lx("channel.link mode:{add} from:{$mainlayerID:posNoise} to:{$noisePosID1:amplitude}");
		lx("channel.link mode:{add} from:{$mainlayerID:posNoise} to:{$noisePosID2:amplitude}");
		lx("channel.link mode:{add} from:{$mainlayerID:rotNoise} to:{$noiseRotID:amplitude}");
		lx("channel.link mode:{add} from:{$mainlayerID:sclNoise} to:{$noiseSclID:amplitude}");

		lx("channel.link mode:{add} from:{$noisePosID1:output} to:{$constrainIDs[-1]:offset.X}");
		lx("channel.link mode:{add} from:{$noisePosID2:output} to:{$constrainIDs[-1]:offset.Y}");
		lx("channel.link mode:{add} from:{$noiseRotID:output} to:{$constrainIDs[-1]:roll}");
	}
}


#render sky box
sub renderSkyBox{
	my $resolution = quickDialog("Render Resolution",integer,128,16,16384);
	if (lxres != 0){	die("The user hit the cancel button");	}

	#file save dialog
	lx("dialog.setup fileSave");
	lx("dialog.title [File save destination]");
	lx("dialog.fileTypeCustom format:[tga] username:[Image to create] loadPattern:[tga] saveExtension:[tga]");
	lx("dialog.open");
	if (lxres != 0){	die("The user hit the cancel button");	}
	my $filePath = lxq("dialog.result ?");

	#remove direction suffix from file name
	if		($filePath =~ /_forward\.tga/i)	{	$filePath =~ s/_forward\.tga//i;	}
	elsif	($filePath =~ /_right\.tga/i)	{	$filePath =~ s/_right\.tga//i;		}
	elsif	($filePath =~ /_back\.tga/i)	{	$filePath =~ s/_back\.tga//i;		}
	elsif	($filePath =~ /_left\.tga/i)	{	$filePath =~ s/_left\.tga//i;		}
	elsif	($filePath =~ /_up\.tga/i)		{	$filePath =~ s/_up\.tga//i;			}
	elsif	($filePath =~ /_down\.tga/i)	{	$filePath =~ s/_down\.tga//i;		}
	if		($filePath =~ /\.tga/i)			{	$filePath =~ s/\.tga//i;			}

	#setup render properties
	lx("select.itemType polyRender");
	my $renderID = lxq("query sceneservice selection ? polyRender");
	my $renderCamera = lxq("render.camera ?");
	my $cameraID = lxq("query sceneservice item.id ? {$renderCamera}");
	lx("render.res 0 {$resolution}");
	lx("render.res 1 {$resolution}");
	lx("item.channel polyRender\$region false");
	lx("item.channel polyRender\$aa s8");
	lx("item.channel polyRender\$aaFilter gaussian");
	if ($modoVer > 600){lx("item.channel outPat <>");}

	#setup camera properties
	lx("select.subItem {$cameraID} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;deform;locdeform;chanModify;chanEffect 0 0");
	lx("item.channel apertureX 1.0");
	lx("item.channel apertureY 1.0");
	lx("camera.hfov 90.0");

	#render frames
	renderSkyBoxFrame(0,0,0,$filePath,"_forward");
	renderSkyBoxFrame(0,270,0,$filePath,"_right");
	renderSkyBoxFrame(0,180,0,$filePath,"_back");
	renderSkyBoxFrame(0,90,0,$filePath,"_left");
	renderSkyBoxFrame(90,0,0,$filePath,"_up");
	renderSkyBoxFrame(-90,0,0,$filePath,"_down");
}

sub renderSkyBoxFrame{
	lx("transform.channel rot.X {$_[0]}");
	lx("transform.channel rot.Y {$_[1]}");
	lx("transform.channel rot.Z {$_[2]}");
	my $fileName = $_[3] . $_[4];

	if ((-e $fileName) && (!-w $fileName)){system("p4 edit \"$fileName\"") or lxout("fail to check this out : $fileName");}
	lx("render.visible filename:{$fileName} format:{TGA}");
}


#set render resolution
sub resolution{
	my @resolution = split(/,/, $resolution);

	lx("select.itemType polyRender");
	lx("render.res 0 {$resolution[0]}");
	lx("render.res 1 {$resolution[1]}");
}

#tri-axis projection
sub triAxisProjection{
	#determine which image to use or cancel script
	my $mainlayer = lxq("query layerservice layers ? main");
	my @selectedClips = clipsSelected();
	my $imagePath;
	my $imageName;
	if (@selectedClips > 0)	{
		$imageName = lxq("query layerservice clip.name ? $selectedClips[0]");
		$imagePath = lxq("query layerservice clip.file ? $selectedClips[0]");
	}else{
		$imagePath = loadImage();
	}

	#load up tri axis preset
	my $materialID = findAdvMatToParentTo();
	my $atlasPresetPath = $userDir . "\/Presets\/atlasTextureProjection.lxp";
	if (!-e $atlasPresetPath){die("This file doesn't exist and so I'm cancelling the script.  ($atlasPresetPath)  This preset file is currently not included in the modo kit and I need to have the script build the preset from scratch that way the script is not dependent on it.");}
	lx("preset.dropShader \$LXP {$atlasPresetPath} {} {$materialID} add");

	my @layers = lxq("query layerservice layers ? fg");
	push(@layers,lxq("query layerservice layers ? bg"));
	my $parentID = lxq("query sceneservice item.parent ? $materialID");
	my @maskIDs = findChildrenByType($parentID,mask);
	my @images = findChildrenByType($maskIDs[0],imageMap);

	#find those two gradient layer masks ( TEMP : hack )
	my $itemCount = lxq("query sceneservice item.n ? all");
	my @gradientIDs;
	for (my $i=$itemCount-1; $i>0; $i--){
		if (lxq("query sceneservice item.type ? $i") eq "gradient"){
			my $id = lxq("query sceneservice item.id ? $i");
			push(@gradientIDs,$id);
			if (@gradientIDs == 2){last;}
		}
	}
	for (my $i=0; $i<@gradientIDs; $i++){
		my @pos = (1000000,0,0);
		if ($i == 1){@pos = (0,1000000,0);}
		lx("!!select.subItem {$gradientIDs[$i]} set textureLayer;render;environment;light;camera;mediaClip");
		my $locatorName = lxq("texture.setLocator locator:?");
		my $locatorID = lxq("query sceneservice item.id ? {$locatorName}");

		lx("item.channel pos.X {$pos[0]} set {$locatorID}");
		lx("item.channel pos.Y {$pos[1]} set {$locatorID}");
		lx("item.channel pos.Z {$pos[2]} set {$locatorID}");
	}

	#query layer bounds
	my @maxBounds = (z,z,z,z,z,z);
	foreach my $layer (@layers){
		my $layerName = lxq("query layerservice layer.name ? $layer");
		if ($layerName =~ /Atlas Texture Ref Object/i){
			next;
		}elsif ($maxBounds[0] eq "z"){
			@maxBounds = lxq("query layerservice layer.bounds ? $layer");
		}else{
			my @layerBounds = lxq("query layerservice layer.bounds ? $layer");
			if ($maxBounds[0] > $layerBounds[0]){$maxBounds[0] = $layerBounds[0];}
			if ($maxBounds[1] > $layerBounds[1]){$maxBounds[1] = $layerBounds[1];}
			if ($maxBounds[2] > $layerBounds[2]){$maxBounds[2] = $layerBounds[2];}
			if ($maxBounds[3] < $layerBounds[3]){$maxBounds[3] = $layerBounds[3];}
			if ($maxBounds[4] < $layerBounds[4]){$maxBounds[4] = $layerBounds[4];}
			if ($maxBounds[5] < $layerBounds[5]){$maxBounds[5] = $layerBounds[5];}
		}
	}
	my @maxBoundsCenter = (($maxBounds[3]+$maxBounds[0])*.5,($maxBounds[4]+$maxBounds[1])*.5,($maxBounds[5]+$maxBounds[2])*.5);
	my @maxBoundsSize = ($maxBounds[3]-$maxBounds[0],$maxBounds[4]-$maxBounds[1],$maxBounds[5]-$maxBounds[2]);
	my $maxBoundsSizeAvg = ($maxBoundsSize[0] + $maxBoundsSize[1] + $maxBoundsSize[2]) * .333;

	#now create the reference cube and position it
	lx("layer.newItem mesh");
	my @meshIDs = lxq("query sceneservice selection ? mesh");
	my $meshIndex = lxq("query layerservice layer.index ? $meshIDs[-1]");
	lx("select.drop item");
	lx("select.subItem {$meshIDs[-1]} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;deform;locdeform;chanModify;chanEffect 0 0");
	lx("item.name {Atlas Texture Ref Object} mesh");
	lx("item.channel render {off} set {$meshIDs[-1]}");

	&rememberACTRSettings;

	lx("tool.set prim.cube on");
	lx("tool.setAttr prim.cube cenX 0.0");
	lx("tool.setAttr prim.cube cenY 0.0");
	lx("tool.setAttr prim.cube cenZ 0.0");
	lx("tool.setAttr prim.cube sizeX 1");
	lx("tool.setAttr prim.cube sizeY 1");
	lx("tool.setAttr prim.cube sizeZ 1");
	lx("tool.doApply");
	lx("tool.set prim.cube off");

	lx("tool.set uv.create on");
	lx("tool.reset");
	lx("tool.attr uv.create proj barycentric");
	lx("tool.doApply");
	lx("tool.set uv.create off");

	lx("select.drop polygon");								#front=2
	lx("select.element {$meshIndex} polygon add 5");		#right=5	fH
	lx("select.element {$meshIndex} polygon add 4");		#back=4		fH
	lx("select.element {$meshIndex} polygon add 3");		#left=0
															#top=3		fH
	lx("tool.viewType UV");									#bottom=1
	lx("tool.set xfrm.stretch on");
	lx("tool.reset");
	lx("tool.xfrmDisco {1}");
	lx("tool.setAttr axis.auto axis {2}");
	lx("tool.setAttr center.auto cenU {0.5}");
	lx("tool.setAttr center.auto cenV {0.5}");
	lx("tool.setAttr xfrm.stretch factX {-1}");
	lx("tool.setAttr xfrm.stretch factY {1}");
	lx("tool.doApply");
	lx("tool.set xfrm.stretch off");

	lx("select.element {$meshIndex} polygon set 4");
	lx("select.element {$meshIndex} polygon add 3");
	lx("uv.rotate");

	lx("transform.add scl pos:post adv:1");
	lx("transform.add rot pos:post adv:1");
	lx("transform.add pos pos:post adv:1");

	my $cubeTransMoveID = lxq("query sceneservice item.xfrmPos ? {$meshIDs[-1]}");
	my $cubeTransRotID = lxq("query sceneservice item.xfrmRot ? {$meshIDs[-1]}");
	my $cubeTransScaleID = lxq("query sceneservice item.xfrmScl ? {$meshIDs[-1]}");

	lx("item.channel pos.X {$maxBoundsCenter[0]} set {$cubeTransMoveID}");
	lx("item.channel pos.Y {$maxBoundsCenter[1]} set {$cubeTransMoveID}");
	lx("item.channel pos.Z {$maxBoundsCenter[2]} set {$cubeTransMoveID}");

	if ($keepProportion == 1){
		lx("item.channel scl.X {$maxBoundsSize[0]} set {$cubeTransScaleID}");
		lx("item.channel scl.Y {$maxBoundsSize[1]} set {$cubeTransScaleID}");
		lx("item.channel scl.Z {$maxBoundsSize[2]} set {$cubeTransScaleID}");
	}else{
		lx("item.channel scl.X {$maxBoundsSizeAvg} set {$cubeTransScaleID}");
		lx("item.channel scl.Y {$maxBoundsSizeAvg} set {$cubeTransScaleID}");
		lx("item.channel scl.Z {$maxBoundsSizeAvg} set {$cubeTransScaleID}");
	}


	#now link the image locators to the cube locator
	for (my $i=0; $i<@images; $i++){
		lx("!!select.subItem {$images[$i]} set textureLayer;render;environment;light;camera;mediaClip");
		my $locatorName = lxq("texture.setLocator locator:?");
		my $locatorID = lxq("query sceneservice item.id ? {$locatorName}");
		my $imageTransMoveID = lxq("query sceneservice item.xfrmPos ? {$locatorID}");
		my $imageTransRotID = lxq("query sceneservice item.xfrmRot ? {$locatorID}");
		my $imageTransScaleID = lxq("query sceneservice item.xfrmScl ? {$locatorID}");

		lx("channel.link mode:{add} from:{$cubeTransMoveID:pos.X} to:{$imageTransMoveID:pos.X}");
		lx("channel.link mode:{add} from:{$cubeTransMoveID:pos.Y} to:{$imageTransMoveID:pos.Y}");
		lx("channel.link mode:{add} from:{$cubeTransMoveID:pos.Z} to:{$imageTransMoveID:pos.Z}");

		lx("channel.link mode:{add} from:{$cubeTransRotID:rot.X} to:{$imageTransRotID:rot.X}");
		lx("channel.link mode:{add} from:{$cubeTransRotID:rot.Y} to:{$imageTransRotID:rot.Y}");
		lx("channel.link mode:{add} from:{$cubeTransRotID:rot.Z} to:{$imageTransRotID:rot.Z}");

		lx("channel.link mode:{add} from:{$cubeTransScaleID:scl.X} to:{$imageTransScaleID:scl.X}");
		lx("channel.link mode:{add} from:{$cubeTransScaleID:scl.Y} to:{$imageTransScaleID:scl.Y}");
		lx("channel.link mode:{add} from:{$cubeTransScaleID:scl.Z} to:{$imageTransScaleID:scl.Z}");
	}

	#now set the images to the correct image map
	if (@selectedClips > 0){
		lx("select.subItem {$images[0]} set textureLayer;render;environment;light;camera;mediaClip");
		lx("select.subItem {$images[1]} add textureLayer;render;environment;light;camera;mediaClip");
		lx("select.subItem {$images[2]} add textureLayer;render;environment;light;camera;mediaClip");
		lx("texture.setIMap {$imageName}");
	}else{
		lx("clip.addStill {$imagePath}");
		@selectedClips = clipsSelected();
		$imageName = lxq("query layerservice clip.name ? {$selectedClips[-1]}");
		lx("select.subItem {$images[0]} set textureLayer;render;environment;light;camera;mediaClip");
		lx("select.subItem {$images[1]} add textureLayer;render;environment;light;camera;mediaClip");
		lx("select.subItem {$images[2]} add textureLayer;render;environment;light;camera;mediaClip");
		lx("texture.setIMap {$imageName}");
	}

	#now give the cube a material and apply the image to it too
	lx("select.itemType polyRender");
	lx("shader.create advancedMaterial");
	lx("item.channel advancedMaterial\$specAmt 0.0");
	lx("item.channel advancedMaterial\$tranAmt 0.7");
	lx("shader.group");
	my @currentMaskIDs = lxq("query sceneservice selection ? mask");
	lx("select.subItem {$currentMaskIDs[-1]} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
	my $meshName = lxq("query sceneservice item.name ? {$meshIDs[-1]}");
	lx("mask.setMesh {$meshName}");
	$imagePath =~ s/\\/\//g;
	lx("texture.new {$imagePath}");
	lx("texture.parent {$currentMaskIDs[-1]} [-1]");

	&restoreACTRSettings;
}

#gradient_linear
sub gradientLinear{
	my $multChoice = popupMultChoice("Apply Gradation From Where?","X+;Y+;Z+;X-;Y-;Z-",1);
	if		($multChoice =~ /x/i)	{	our @pos = (1000000,0,0);			}
	elsif	($multChoice =~ /y/i)	{	our @pos = (0,1000000,0);			}
	elsif	($multChoice =~ /z/i)	{	our @pos = (0,0,1000000);			}
	if		($multChoice =~ /-/)	{	@pos = arrMath(@pos,-1,-1,-1,mult);	}

	my $materialID = findAdvMatToParentTo();

	lx("shader.create gradient");
	my @gradients = lxq("query sceneservice selection ? gradient");
	my $channelR = $gradients[-1].":color.R";
	my $channelG = $gradients[-1].":color.G";
	my $channelB = $gradients[-1].":color.B";

	my $gradName = lxq("query sceneservice item.name ? $gradients[-1]");
	my $channelCount = lxq("query sceneservice channel.n ?");
	my @channelIndices;
	for (my $i=0; $i<$channelCount; $i++){
		my $chanName = lxq("query sceneservice channel.name ? $i");
		if (lxq("query sceneservice channel.name ? $i") eq "color.R"){
			@channelIndices = ($i,$i+1,$i+2);
			last;
		}
	}
	if (@channelIndices == 0){die("The script couldn't find the correct channel indices on the gradient and so the script is being canceled");}
	lx("channel.key time:{1.0} value:{0} channel:{$channelR}");
	lx("channel.key time:{1.0} value:{0} channel:{$channelG}");
	lx("channel.key time:{1.0} value:{0} channel:{$channelB}");
	lx("select.keyRange {$gradients[-1]} {$channelIndices[0]} -0.1645 1.1731 -0.4365 1.2888 add");
	lx("select.keyRange {$gradients[-1]} {$channelIndices[1]} -0.1645 1.1731 -0.4365 1.2888 add");
	lx("select.keyRange {$gradients[-1]} {$channelIndices[2]} -0.1645 1.1731 -0.4365 1.2888 add");
 	lx("key.break slopeWeight"); lx("key.slopeType linearIn in"); 	lx("key.slopeType linearOut out");

	lx("texture.setInput locatorIncAngle");
	my $locatorName = lxq("texture.setLocator locator:?");
	my $locatorID = lxq("query sceneservice item.id ? {$locatorName}");

	lx("item.channel pos.X {$pos[0]} set {$locatorID}");
	lx("item.channel pos.Y {$pos[1]} set {$locatorID}");
	lx("item.channel pos.Z {$pos[2]} set {$locatorID}");
}



#select all the items of the same type that's currently selected :
sub selectAllByType{
	if ($itemList == 1){our $itemListCheck = 1;}else{our $itemListCheck = 0;}
	my $itemCount = lxq("query sceneservice item.n ? all");
	my @selection = lxq("query sceneservice selection ? all");
	my %typeList;
	my %ignoreList;
		$ignoreList{videoStill} = 1;
		$ignoreList{render} = 1;
		$ignoreList{environment} = 1;
		$ignoreList{transform} = 1;
		$ignoreList{translation} = 1;
		$ignoreList{rotation} = 1;
		$ignoreList{xfrmcore} = 1;
		$ignoreList{scene} = 1;
		$ignoreList{polyRender} = 1;

	my %itemList;
		$itemList{locator} = 1;
		$itemList{txtrLocator} = 1;
		$itemList{groupLocator} = 1;
		$itemList{mesh} = 1;
		$itemList{meshInst} = 1;
		$itemList{triSurf} = 1;
		$itemList{sunLight} = 1;
		$itemList{pointLight} = 1;
		$itemList{spotLight} = 1;
		$itemList{areaLight} = 1;
		$itemList{domeLight} = 1;
		$itemList{cylinderLight} = 1;
		$itemList{photometryLight} = 1;
		$itemList{camera} = 1;
		$itemList{backdrop} = 1;
		$itemList{replicator} = 1;

	foreach my $id (@selection){
		my $type = lxq("query sceneservice item.type ? {$id}");
		if (($ignoreList{$type} != 1) && ($itemList{$type} == $itemListCheck)){$typeList{$type} = 1;}
	}

	for (my $i=0; $i<$itemCount; $i++){
		my $type = lxq("query sceneservice item.type ? $i");
		if($typeList{$type} == 1){
			my $id = lxq("query sceneservice item.id ? $i");
			lx("select.subItem {$id} add mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;deform;locdeform;chanModify;chanEffect 0 0");
		}
	}
}

#change how soft ALL the blurry shadows are.
sub setAllLightRays{
	my $quality = quickDialog("Light Quality:\n0 = low (64)\n1 = medium (128)\n2 = high (512)\n3 = ultra (1024)",integer,0,0,3);
	my $itemCount = lxq("query sceneservice item.n ? all");
	my @pointLightQuality =	(64,128,512,1024);
	my @spotLightQuality =	(64,128,512,1024);
	my @areaLightQuality =	(64,128,512,1024);
	my @sunLightQuality =	(64,128,512,1024);

	for (my $i=0; $i<$itemCount; $i++){
		if		(lxq("query sceneservice item.type ? $i") eq "pointLight"){
			my $id = lxq("query sceneservice item.id ? $i");
			if (lxq("item.channel radius {?} set {$id}") > 0){
				lx("select.subItem {$id} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
				lx("item.channel pointLight\$samples {$pointLightQuality[$quality]}");
			}
		}

		elsif	(lxq("query sceneservice item.type ? $i") eq "spotLight"){
			my $id = lxq("query sceneservice item.id ? $i");
			if (lxq("item.channel radius {?} set {$id}") > 0){
				lx("select.subItem {$id} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
				lx("item.channel spotLight\$samples {$spotLightQuality[$quality]}");
			}
		}

		elsif	(lxq("query sceneservice item.type ? $i") eq "areaLight"){
			my $id = lxq("query sceneservice item.id ? $i");
			lx("select.subItem {$id} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
			lx("item.channel light\$samples {$areaLightQuality[$quality]}");
		}

		elsif	(lxq("query sceneservice item.type ? $i") eq "sunLight"){
			my $id = lxq("query sceneservice item.id ? $i");
			if (lxq("item.channel spread {?} set {$id}") > 0){
				lx("select.subItem {$id} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
				lx("item.channel sunLight\$samples {$sunLightQuality[$quality]}");
			}
		}
	}
}

#change how soft the area light blurry shadows are.
sub setAreaLightRays{
	my $rays = quickDialog("Area Light Ray Count:",integer,64,1,4096);
	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$itemCount; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "areaLight"){
			my $id = lxq("query sceneservice item.id ? $i");
			lx("select.subItem {$id} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
			lx("item.channel light\$samples {$rays}");
		}
	}
}

#take all the group masks and set their effect to be "all"
sub fixMatrGroupEffect{
	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			lx("select.subItem {$id} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
			lx("shader.setEffect (all)");
		}
	}
}

#scale the lights in the scene
sub scaleLighting{
	my $lightingScale = quickDialog("Scale Lighting :",float,1.0,0.05,1000);

	#find the final color output and query it's gamma
	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$itemCount; $i++){
		if ((lxq("query sceneservice item.type ? $i") eq "sunLight")
		|| (lxq("query sceneservice item.type ? $i") eq "pointLight")
		|| (lxq("query sceneservice item.type ? $i") eq "spotLight")
		|| (lxq("query sceneservice item.type ? $i") eq "areaLight")
		|| (lxq("query sceneservice item.type ? $i") eq "domeLight")
		|| (lxq("query sceneservice item.type ? $i") eq "cylinderLight")
		|| (lxq("query sceneservice item.type ? $i") eq "photometryLight")){
			my $id = lxq("query sceneservice item.id ? $i");
			lx("!!select.subItem {$id} set mesh;triSurf;meshInst;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
			my $brightness = lxq("item.channel light\$radiance ?") * $lightingScale;
			lx("item.channel light\$radiance $brightness");
		}
	}
}


#set the gamma of the scene and then fix all the diffuse maps
sub setGamma{
	my $setGamma = quickDialog("Gamma Value:",float,1.6,0.1,10);
	my $gamma = 1/$setGamma;
	shaderTreeTools(buildDbase);

	#find the final color output and query it's gamma
	my @renderOutputs = shaderTreeTools(findAllOfType , renderOutput);
	foreach my $id (@renderOutputs){
		lx("select.subItem {$id} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
		if (lxq("shader.setEffect ?") eq "shade.color"){
			lx("!!item.channel renderOutput\$gamma {$setGamma}");
		}
	}

	#find all diffuse maps and change their gamma
	my @txLayers = shaderTreeTools(findAllOfType , imageMap);
	foreach my $id (@txLayers){
		lx("select.subItem {$id} set textureLayer;render;environment;light;camera");
		if (lxq("shader.setEffect ?") eq "diffColor"){
			lx("item.channel imageMap\$gamma $gamma");
		}
	}
}

#fix the gamma for all diffuse maps
sub diff_fixGamma{
	my $gamma = 1;
	shaderTreeTools(buildDbase);

	#find the final color output and query it's gamma
	if ($scalar != 1){
		my @renderOutputs = shaderTreeTools(findAllOfType , renderOutput);
		foreach my $id (@renderOutputs){
			lx("select.subItem {$id} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
			if (lxq("shader.setEffect ?") eq "shade.color"){
				$gamma = 1 / lxq("item.channel renderOutput\$gamma ?");
				last;
			}
		}
	}

	#find all diffuse maps and change their gamma
	my @txLayers = shaderTreeTools(findAllOfType , imageMap);
	foreach my $id (@txLayers){
		lx("select.subItem {$id} set textureLayer;render;environment;light;camera");
		if (lxq("shader.setEffect ?") eq "diffColor"){
			lx("item.channel imageMap\$gamma $gamma");
		}
	}
}

#scale all the material brightness' in the scene
sub scaleMatBrightness{
	my $scale = quickDialog("Scale Amount",float,2,"","");
	my $txLayers = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayers; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "advancedMaterial"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			lx("select.subItem {$id} set textureLayer;render;environment;mediaClip;locator");
			my $brightness = lxq("item.channel advancedMaterial\$diffAmt ?") * $scale;
			lx("item.channel advancedMaterial\$diffAmt $brightness");
		}
	}
}


#change smoothing from 60 to N
sub changeSmoothing{
	my $angle = quickDialog("Smoothing angle",float,20,0,360);
	if ($modoVer <300)	{our $defaultAngle = 60;}
	else				{our $defaultAngle = 45;}
	my $txLayers = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayers; $i++){
		my $type = lxq("query sceneservice txLayer.type ? $i");
		if ($type eq "advancedMaterial"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			my $parent = lxq("query sceneservice txLayer.parent ? $i");
			my $parentName = lxq("query sceneservice txLayer.name ? $parent");
			my $word = "pipe";

			lx("select.subItem [$id] set textureLayer;render;environment;light;mediaClip;txtrLocator");
			my $smoothingAngle = lxq("item.channel advancedMaterial\$smAngle ?");

			if ($parentName =~ /$word/i){
				lxout("This material ($parentName) has the word $word in it and so I'm setting smoothing to 180");
				lx("item.channel advancedMaterial\$smAngle 180");
			}elsif (int($smoothingAngle) == $defaultAngle){
				lx("item.channel advancedMaterial\$smAngle $angle");
			}
			lxout("name=$name <><> parent=$parent <><> parentName=$parentName <><> smoothingAngle=$smoothingAngle");
		}
	}
}


#AAchannels = item.channel polyRender$aa [0]
#set the antialiasing value for the scene.
sub setAA{
	my $value = lxq("user.value sene_AA ?");
	if 		($value < 2)	{	$value = 0;	}
	elsif	($value < 4)	{	$value = 1;	}
	elsif	($value < 8)	{	$value = 2;	}
	elsif	($value < 16)	{	$value = 3;	}
	elsif	($value < 32)	{	$value = 4;	}
	elsif	($value < 64)	{	$value = 5;	}
	else					{	$value = 6;	}

	my $txLayers = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayers; $i++){
		my $type = lxq("query sceneservice txLayer.type ? $i");
		if ($type eq "renderOutput"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			lx("select.subItem [$id] set textureLayer;render;environment;mediaClip;locator");
			lx("item.channel item.channel polyRender\$aa [$value]");
			lx("texture.setUV Texture");
			last;
		}
	}
}

#set the number of blurry reflection rays for the scene.
sub blurryRefRays{
	lxout("[->] Setting the number of rays for all the blurry materials in the scene.");
	lx("user.value sene_blurryRays");
	my $value = lxq("user.value sene_blurryRays ?");
	if 		($value < 1)	{	$value = 1;	}
	elsif 	($value > 512)	{	popup("are you sure you want to tell all the materials to use ($value) blurry reflection rays?!");	}

	my $txLayers = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayers; $i++){
		my $type = lxq("query sceneservice txLayer.type ? $i");
		if ($type eq "advancedMaterial"){
			my $id = lxq("query sceneservice txLayer.id ? $i");
			lx("select.subItem [$id] set textureLayer;render;environment;mediaClip;locator");
			my $name = lxq("query sceneservice txLayer.name ? $i");
			my $reflect = lxq("item.channel advancedMaterial\$reflAmt ?");
			my $fresnel = lxq("item.channel advancedMaterial\$reflFres ?");

			if ((($reflect > 0) || ($fresnel > 0)) && (lxq("item.channel advancedMaterial\$reflBlur ?") > 0)){
				my $ownName = lxq("query sceneservice txLayer.name ? $i");
				my $parent = lxq("query sceneservice txLayer.parent ? $i");
				my $name = lxq("query sceneservice txLayer.name ? $parent");
				lxout("-->Setting $name 's reflection rays to $value");

				lx("item.channel advancedMaterial\$reflRays [$value]");
			}
		}
	}
}

#print out render time diagnostics for the current scene.
sub renderDiagnostics{
	my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
	my @maskIDs;
	my %maskMaterialTable;
	for (my $i=0; $i<$txLayerCount; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $maskID = lxq("query sceneservice txLayer.id ? $i");
			my $foundMaterial = 0;
			my @children = lxq("query sceneservice txLayer.children ? $i");
			foreach my $id (@children){
				if (lxq("query sceneservice txLayer.type ? $id") eq "advancedMaterial"){
					$maskMaterialTable{$maskID} = $id;
					$foundMaterial = 1;
					last;
				}
			}
			if ($foundMaterial == 1){
				push(@maskIDs,$maskID);
			}
		}
	}

	#lxout("================================================");
	lxout("[->] : Reflection report");
	#lxout("================================================");
	foreach my $id (@maskIDs){
		my $maskName = lxq("query sceneservice item.name ? {$id}");
		my $reflectionIsOn = 0;
		my $reflectionAmount =	lxq("item.channel reflAmt {?} set {$maskMaterialTable{$id}}");
		my $fresnelAmount =		lxq("item.channel reflFres {?} set {$maskMaterialTable{$id}}");
		my $blurryReflectionOption;
		my $blurryReflectionRays;


		if (($reflectionAmount == 0) && ($fresnelAmount  == 0)){
			my @foundIDs = findSTChildrenByEffect(reflAmount,$id);
			if (@foundIDs > 0){$reflectionIsOn = 1;}
		}else{
			$reflectionIsOn = 1;
		}

		if ($reflectionIsOn == 1){
			$blurryReflectionOption =	lxq("item.channel reflBlur {?} set {$maskMaterialTable{$id}}");
			$blurryReflectionRays =		lxq("item.channel reflRays {?} set {$maskMaterialTable{$id}}");
		}
		if (($reflectionIsOn == 1) && ($blurryReflectionOption == 0)){
			lxout("           MED : REFLECTION ON : $maskName");
		}elsif($blurryReflectionOption == 1){
			lxout("--------HIGH : BLURRY REFLECTION ON ($blurryReflectionRays) : $maskName");
		}
	}

	#lxout("================================================");
	lxout("[->] : Displacement report");
	#lxout("================================================");
	foreach my $id (@maskIDs){
		my $maskName = lxq("query sceneservice item.name ? {$id}");
		my @foundIDs = findSTChildrenByEffect(displace,$id);
		if (@foundIDs > 0){lxout("--------HIGH : DISPLACEMENT ON : $maskName");}
	}


	#lxout("================================================");
	lxout("[->] : Lightcasting report");
	#lxout("================================================");
	foreach my $id (@maskIDs){
		my $maskName = lxq("query sceneservice item.name ? {$id}");
		my $radiance = lxq("item.channel radiance {?} set {$maskMaterialTable{$id}}");
		if ($radiance == 0){
			my @foundIDs = findSTChildrenByEffect(radiance,$id);
			if (@foundIDs > 0){$radiance = 1;}
		}

		if ($radiance > 0){lxout("           MED : RADIANCE ON : $maskName");}
	}


	#lxout("================================================");
	lxout("[->] : Subsurface report");
	#lxout("================================================");
	foreach my $id (@maskIDs){
		my $maskName = lxq("query sceneservice item.name ? {$id}");
		my $subsurface = lxq("item.channel subsAmt {?} set {$maskMaterialTable{$id}}");
		if ($subsurface == 0){
			my @foundIDs = findSTChildrenByEffect(subsAmt ,$id);
			if (@foundIDs > 0){$subsurface = 1;}
		}

		if ($subsurface > 0){
			#my $subsurfaceRays = lxq("item.channel subsAmt {?} set {$maskMaterialTable{$id}}");
			lxout("--------HIGH : SUBSURFACE SCATTERING IS ON : $maskName");  #temp : i need to find the number of samples to say how bad it actually is, but i can't do that yet.
		}
	}


	#lxout("================================================");
	lxout("[->] : Transparency report");
	#lxout("================================================");
	foreach my $id (@maskIDs){
		my $maskName = lxq("query sceneservice item.name ? {$id}");
		my $transparency = lxq("item.channel tranAmt {?} set {$maskMaterialTable{$id}}");
		my $dispersion = 0;
		if ($transparency == 0){
			my @foundIDs = findSTChildrenByEffect(tranAmt ,$id);
			if (@foundIDs > 0){$transparency = 1;}
		}
		if ($transparency > 0){
			#my $subsurfaceRays = lxq("item.channel subsAmt {?} set {$maskMaterialTable{$id}}");
			{lxout("           MED : TRANSPARENCY ON : $maskName");}
		}
	}


	#lxout("================================================");
	lxout("[->] : Light speed report");
	#lxout("================================================");
	my $itemCount = lxq("query sceneservice item.n ? all");
	my %lightTable;
	for (my $i=0; $i<$itemCount; $i++){
		my $type = lxq("query sceneservice item.type ? $i");

		if ($type =~ /light/i){
			my $name = lxq("query sceneservice item.name ? $i");
			my $id = lxq("query sceneservice item.id ? $i");

			if ($type eq "pointLight"){
				my $radius = lxq("item.channel radius {?} set {$id}");
				if ($radius > 0){
					lxout("           MED : SOFT SHADOWS ON : $name"); #TEMP : i need to be able to query the number of samples used to say how bad it is.
				}
			}

			elsif	($type eq "spotLight"){
				my $radius = lxq("item.channel radius {?} set {$id}");
				if ($radius > 0){
					lxout("           MED : SOFT SHADOWS ON : $name"); #TEMP : i need to be able to query the number of samples used to say how bad it is.
				}
			}

			elsif	($type eq "areaLight"){
				lxout("--------HIGH : AREA LIGHT : $name");  #TEMP : need to print samples
			}

			elsif	($type eq "sunLight"){
				my $spread = lxq("item.channel spread {?} set {$id}");
				if ($spread > 0){
					lxout("           MED : SOFT SHADOWS ON : $name"); #TEMP : need to print samples
				}
			}

			elsif	($type eq "domeLight"){
				lxout("--------HIGH : DOME LIGHT : $name");
			}

			elsif	($type eq "photometryLight"){
				my $softEdge = lxq("item.channel edge {?} set {$id}");
				if ($softEdge > 0){
					lxout("           MED : SOFT SHADOWS ON : $name");
				}
			}

			elsif	($type eq "cylinderLight"){
				lxout("--------HIGH : CYLINDER LIGHT : $name");
			}
		}
	}
}


#usage : findSTChildrenByEffect($effect,$id);
sub findSTChildrenByEffect{
	my @children = lxq("query sceneservice item.children ? {$_[1]}");
	my @idsToReturn;
	foreach my $child (@children){
		my $effect = lxq("item.channel effect {?} set {$child}");
		if (lxq("item.channel effect {?} set {$child}") eq $_[0]){
			push(@idsToReturn,$child);
		}
	}
	return(@idsToReturn);
}


sub userValPopup{
	my $name = @_[0];
	my @args = (@_[1]..@_[@_]);

	lxout("name = $name");
	lxout("args = @args");
	lxout("args 1 = @args[1]");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {@_[0]}");
		lx("dialog.open");
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 0){
			lxout("-The seneTempDialog cvar didn't exist so I just created one");
			lx("user.defNew name:[seneTempDialog] life:[temporary]");
		}
		lx("user.def seneTempDialog username [@_[0]]");
		lx("user.def seneTempDialog type [@_[1]]");
		if ((@_[3] != "") && (@_[4] != "")){
			lx("user.def seneTempDialog min [@_[3]]");
			lx("user.def seneTempDialog max [@_[4]]");
		}
		lx("user.value seneTempDialog [@_[2]]");
		lx("user.value seneTempDialog ?");
		return(lxq("user.value seneTempDialog ?"));
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
#FIND ADVANCED MATERIAL TO PARENT TO (not final, as it can't find select txLocators or layer masks)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $materialID = findAdvMatToParentTo();
#note : requires findChildrenByType sub
sub findAdvMatToParentTo{
	my $materialID;
	my @selection = lxq("query sceneservice selection ? textureLayer");
	foreach my $id (@selection){
		if (lxq("query sceneservice item.type ? $id") eq "advancedMaterial"){
			$materialID = $id;
			last;
		}elsif (lxq("query sceneservice item.type ? $id") eq "mask"){
			my @children = findChildrenByType($id,advancedMaterial);
			if (@children > 0){
				$materialID = $children[0];
				last;
			}
		}else{
			my $parentID = lxq("query sceneservice item.parent ? $id");
			my @children = findChildrenByType($parentID,advancedMaterial);
			if (@children > 0){
				$materialID = $children[0];
				last;
			}
		}
	}

	if ($materialID eq ""){
		lx("select.itemType defaultShader");
		$materialID = lxq("query sceneservice selection ? defaultShader");
	}

	return $materialID;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND CHILD BY TYPE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : findChildrenByType($parentID,$childType);
sub findChildrenByType{
	my @foundIDs;
	my @children = lxq("query sceneservice item.children ? {@_[0]}");
	foreach my $id (@children){
		if (lxq("query sceneservice item.type ? {$id}") eq @_[1]){
			push(@foundIDs,$id);
		}
	}
	if (@foundIDs == 0){
		lxout("This item ($_[0]) has no children of the type ($_[1])");
	}else{
		return(@foundIDs);
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND PARENT BY TYPE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : findParentByType($childID,$parentType);
sub findParentByType{
	my $id = @_[0];
	while (1){
		my $parent = lxq("query sceneservice item.parent ? {$id}");
		if ($parent eq ""){
			lxout("The findParentByType sub couldn't find a parent of the type ($_[1]) from item ($_[0]) because there isn't one");
		}elsif (lxq("query sceneservice item.type ? {$parent}") eq $_[1]){
			return $parent;
		}else{
			$id = $parent;
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


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PERFORM MATH FROM ONE ARRAY TO ANOTHER subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @disp = arrMath(@pos2,@pos1,subt);
sub arrMath{
	my @array1 = (@_[0],@_[1],@_[2]);
	my @array2 = (@_[3],@_[4],@_[5]);
	my $math = @_[6];

	my @newArray;
	if		($math eq "add")	{	@newArray = (@array1[0]+@array2[0],@array1[1]+@array2[1],@array1[2]+@array2[2]);	}
	elsif	($math eq "subt")	{	@newArray = (@array1[0]-@array2[0],@array1[1]-@array2[1],@array1[2]-@array2[2]);	}
	elsif	($math eq "mult")	{	@newArray = (@array1[0]*@array2[0],@array1[1]*@array2[1],@array1[2]*@array2[2]);	}
	elsif	($math eq "div")	{	@newArray = (@array1[0]/@array2[0],@array1[1]/@array2[1],@array1[2]/@array2[2]);	}
	return @newArray;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY CLIP DIMENSIONS SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : queryImageDimensions($imagePath);
sub queryImageDimensions{
	my $clipCount = lxq("query layerservice clip.n ? all");
	my $imagePath = $_[0];
	$imagePath =~ s/\\/\//g;
	$imagePath =~ lc($imagePath);

	for (my $i=0; $i<$clipCount; $i++){
		my $clipFile = lxq("query layerservice clip.file ? $i");
		$clipFile =~ s/\\/\//g;
		$clipFile =~ lc($clipFile);
		if ($clipFile eq $imagePath){
			my $clipInfo = lxq("query layerservice clip.info ? {$i}");
			my @clipSize = split(/\D+/, $clipInfo);
			my $width = @clipSize[1];
			my $height = @clipSize[2];
			return($width,$height);
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#LOAD IMAGE subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE my $filePath = loadImage();
sub loadImage{
	lx("dialog.setup fileOpenMulti");
	lx("dialog.title [Choose image to create a material with. (filter = $imageFilter)]");
	lx("dialog.fileType image");
	lx("dialog.open");
	my @files = lxq("dialog.result ?");
	if (!defined @files[0]){	die("\n.\n[-------------------------------------------There was no file loaded, so I'm killing the script.---------------------------------------]\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");	}
	return($files[0]);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND SELECTED CLIPS subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE my @selectedClips = clipsSelected();
sub clipsSelected{
	my $clips = lxq("query layerservice clip.n ? all");
	my @selectedClips;
	for (my $i=0; $i<$clips; $i++){
		if (lxq("query sceneservice clip.isSelected ? $i") == 1){
			push(@selectedClips,$i);
		}
	}
	return(@selectedClips);
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS and then set it to selectauto  ((MODO2 FIX))
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub rememberACTRSettings{
	our $selAxis;
	our $selCenter;
	our $actr = 1;

	if ($skipActr != 1){
		if( lxq( "tool.set actr.select ?") eq "on")				{	$seltype = "actr.select";		}
		elsif( lxq( "tool.set actr.selectauto ?") eq "on")		{	$seltype = "actr.selectauto";	}
		elsif( lxq( "tool.set actr.element ?") eq "on")			{	$seltype = "actr.element";		}
		elsif( lxq( "tool.set actr.screen ?") eq "on")			{	$seltype = "actr.screen";		}
		elsif( lxq( "tool.set actr.origin ?") eq "on")			{	$seltype = "actr.origin";		}
		elsif( lxq( "tool.set actr.local ?") eq "on")			{	$seltype = "actr.local";		}
		elsif( lxq( "tool.set actr.pivot ?") eq "on")			{	$seltype = "actr.pivot";		}
		elsif( lxq( "tool.set actr.auto ?") eq "on")			{	$seltype = "actr.auto";			}
		else
		{
			$actr = 0;
			lxout("custom Action Center");
			if( lxq( "tool.set axis.select ?") eq "on")			{	 $selAxis = "select";			}
			elsif( lxq( "tool.set axis.element ?") eq "on")		{	 $selAxis = "element";			}
			elsif( lxq( "tool.set axis.view ?") eq "on")		{	 $selAxis = "view";				}
			elsif( lxq( "tool.set axis.origin ?") eq "on")		{	 $selAxis = "origin";			}
			elsif( lxq( "tool.set axis.local ?") eq "on")		{	 $selAxis = "local";			}
			elsif( lxq( "tool.set axis.pivot ?") eq "on")		{	 $selAxis = "pivot";			}
			elsif( lxq( "tool.set axis.auto ?") eq "on")		{	 $selAxis = "auto";				}
			else												{	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action AXIS that I couldn't read");}

			if( lxq( "tool.set center.select ?") eq "on")		{	 $selCenter = "select";			}
			elsif( lxq( "tool.set center.element ?") eq "on")	{	 $selCenter = "element";		}
			elsif( lxq( "tool.set center.view ?") eq "on")		{	 $selCenter = "view";			}
			elsif( lxq( "tool.set center.origin ?") eq "on")	{	 $selCenter = "origin";			}
			elsif( lxq( "tool.set center.local ?") eq "on")		{	 $selCenter = "local";			}
			elsif( lxq( "tool.set center.pivot ?") eq "on")		{	 $selCenter = "pivot";			}
			elsif( lxq( "tool.set center.auto ?") eq "on")		{	 $selCenter = "auto";			}
			else												{ 	 $actr = 1;  $seltype = "actr.auto"; lxout("You were using an action CENTER that I couldn't read");}
		}
		lx("tool.set actr.auto on");
	}
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#RESTORE ACTR SETTINGS
#-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub restoreACTRSettings{
	if ($actr == 1) {	lx( "tool.set {$seltype} on" ); }
	else { lx("tool.set center.$selCenter on"); lx("tool.set axis.$selAxis on"); }
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

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#PATH NAME FIX SUB : make sure the / syntax is correct for the various OSes.
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub OSPathNameFix{
	if ($os =~ /win/i){
		@_[0] =~ s/\\/\//g;
	}else{
		@_[0] =~ s/\\/\//g;
	}
}


##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#NEW GRADIENT SUB
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#usage : my $gradientID = newGradient("input:locatorIncidence","values:4_.5/.5/.5_1_.2/.2/.2","blend:linearIn/linearOut","locatorPos:0_0.5_2","effect:diffColor");
#values example 1 : "values:4_.5/.5/.5_1_.2/.2/.2" : will create two color nodes.  time=4,color=.5,.5,.5 and time=1,color=.2,.2,.2
#values example 2 : "values:2_0_0_1" : will create two nodes.  time=2,value=0 and time=0,value=1
sub newGradient{
	my $effect = "diffColor";
	my $input = "locatorIncidence";
	my @v1 = (0,1); my @v2 = (1,0);
	my @values = (\@v1,\@v2);
	my @blend = (auto,auto);
	my @locatorPos = (0,0,0);
	my $gradientID;
	my @gradientIndices;

	#find polyRender ID
	lx("!!select.itemType polyRender");
	my @polyRenderIDs = lxq("query sceneservice selection ? polyRender");

	#read sub args
	foreach my $arg (@_){
		if ($arg =~ /input:/i){
			$input = $arg;
			$input =~ s/input://;
		}

		elsif ($arg =~ /values:/i){
			@values = ();
			my $line = $arg;
			$line =~ s/values://;
			my @valuesArray = split (/_/, $line);
			for (my $i=0; $i<@valuesArray; $i=$i+2){
				my @array = ();
				if ($valuesArray[$i+1] =~ /\//i){
					our @vectorArray = split (/\//, $valuesArray[$i+1]);
					@array = ($valuesArray[$i],@vectorArray);
				}else{
					@array = ($valuesArray[$i],$valuesArray[$i+1]);
				}

				push(@values,\@array);

				lxout("test : @{$values[0]}");
			}
		}

		elsif ($arg =~ /blend:/i){
			my $line = $arg;
			$line =~ s/blend://;
			@blend = split (/_/, $line);
			for (my $i=0; $i<@blend; $i++){
				if ($blend[$i] =~ /\//){
					my @twoBlendValues = split (/\//, $blend[$i]);
					$blend[$i] = \@twoBlendValues;
				}else{
					my @twoBlendValues = ($blend[$i],$blend[$i]);
					$blend[$i] = \@twoBlendValues;
				}
			}

			if (@blend < @values){
				for (my $i=0; $i<@blend; $i++){
					if ($blend[$i] eq ""){$blend[$i] = $blend[0];}
				}
			}
		}

		elsif ($arg =~ /locatorPos/i){
			my $line = $arg;
			$line =~ s/locatorPos://;
			@locatorPos = split (/_/, $line);
		}

		elsif ($arg =~ /effect:/i){
			my $line = $arg;
			$line =~ s/effect://i;
			$effect = $line;
		}
	}

	#temp print sub args
	lxout("effect  = $effect ");
	lxout("input  = $input ");
	for (my $i=0; $i<@values; $i++){lxout("values : @{$values[$i]}");}
	for (my $i=0; $i<@blend; $i++){lxout("blend : @{$blend[$i]}");}
	lxout("locatorPos  = @locatorPos ");

	#create gradient
	lx("!!select.subItem {@polyRenderIDs[-1]} set ;locator;render;environment;mediaClip;textureLayer");
	lx("!!shader.create gradient");
	my @txtrLocators = lxq("query sceneservice selection ? txtrLocator");
	my @gradients = lxq("query sceneservice selection ? gradient");
	$gradientID = $gradients[-1];
	my $channelR = $gradients[-1].":color.R";
	my $channelG = $gradients[-1].":color.G";
	my $channelB = $gradients[-1].":color.B";
	my $channelV = $gradients[-1].":value";
	if ($effect ne "diffColor")		{lx("shader.setEffect {$effect}");	}
	if ($input ne "incidenceAngle")	{lx("texture.setInput {$input}");	}
	lx("select.channel {$gradientID:value} set");

	#query channel indices
	if (@channelIndices == 0){
		my $gradientName = lxq("query sceneservice item.name ? $gradientID");
		my $channelCount = lxq("query sceneservice channel.n ?");
		for (my $i=0; $i<$channelCount; $i++){
			my $channelName = lxq("query sceneservice channel.name ? $i");
			if		($channelName eq "value")	{	$channelIndices[0] = $i;	}
			elsif	($channelName eq "color.R")	{	$channelIndices[1] = $i;	}
			elsif	($channelName eq "color.G")	{	$channelIndices[2] = $i;	}
			elsif	($channelName eq "color.B")	{	$channelIndices[3] = $i;	}
		}
	}

	#set first key time
	if (@{$values[0]} == 4)	{
		lx("select.keyRange {$gradientID} {$channelIndices[1]} -0.1645 1.1731 -0.4365 1.2888 add");
		lx("select.keyRange {$gradientID} {$channelIndices[2]} -0.1645 1.1731 -0.4365 1.2888 add");
		lx("select.keyRange {$gradientID} {$channelIndices[3]} -0.1645 1.1731 -0.4365 1.2888 add");
	}else{
		lx("select.keyRange {$gradientID} {$channelIndices[0]} -0.1645 1.1731 -0.4365 1.2888 add");
	}
	lx("key.time {@{$values[0]}[0]} true");

	#set first key value
	if (@{$values[0]} == 4)	{
		lx("select.key item:{$gradientID} channel:{$channelIndices[1]} time:{@{$values[0]}[0]} mode:set");
			lx("key.value {@{$values[0]}[1]}");
			if ( (@{$blend[$i]}[0] ne "auto") || (@{$blend[$i]}[1] ne "auto") ){lx("key.break slopeWeight"); lx("key.slopeType {@{$blend[$i]}[0]} in"); 	lx("key.slopeType {@{$blend[$i]}[1]} out");}
		lx("select.key item:{$gradientID} channel:{$channelIndices[2]} time:{@{$values[0]}[0]} mode:set");
			lx("key.value {@{$values[0]}[2]}");
			if ( (@{$blend[$i]}[0] ne "auto") || (@{$blend[$i]}[1] ne "auto") ){lx("key.break slopeWeight"); lx("key.slopeType {@{$blend[$i]}[0]} in"); 	lx("key.slopeType {@{$blend[$i]}[1]} out");}
		lx("select.key item:{$gradientID} channel:{$channelIndices[3]} time:{@{$values[0]}[0]} mode:set");
			lx("key.value {@{$values[0]}[3]}");
			if ( (@{$blend[$i]}[0] ne "auto") || (@{$blend[$i]}[1] ne "auto") ){lx("key.break slopeWeight"); lx("key.slopeType {@{$blend[$i]}[0]} in"); 	lx("key.slopeType {@{$blend[$i]}[1]} out");}
	}else{
		lx("select.key item:{$gradientID} channel:{$channelIndices[0]} time:{@{$values[0]}[0]} mode:set");
			lx("key.value {@{$values[0]}[1]}");
			if ( (@{$blend[$i]}[0] ne "auto") || (@{$blend[$i]}[1] ne "auto") ){lx("key.break slopeWeight"); lx("key.slopeType {@{$blend[$i]}[0]} in"); 	lx("key.slopeType {@{$blend[$i]}[1]} out");}
	}

	#set remaining values #TEMP : THESE SLOPE ASSIGNMENTS DON'T WORK BECAUSE MODO WON'T LET ME SELECT THE NEWLY CREATED NODES.  not with select.key or select.keyrange
	for (my $i=1; $i<@values; $i++){
		if (@{$values[0]} == 4)	{
			lx("channel.key time:{@{$values[$i]}[0]} value:{@{$values[$i]}[1]} channel:{$channelR}");
			lx("channel.key time:{@{$values[$i]}[0]} value:{@{$values[$i]}[2]} channel:{$channelG}");
			lx("channel.key time:{@{$values[$i]}[0]} value:{@{$values[$i]}[3]} channel:{$channelB}");

			if ( (@{$blend[$i]}[0] ne "auto") || (@{$blend[$i]}[1] ne "auto") ){
				lx("select.key item:{$gradientID} channel:{$channelIndices[1]} time:{@{$values[$i]}[0]}");
					lx("key.break slopeWeight"); lx("key.slopeType {@{$blend[$i]}[0]} in"); 	lx("key.slopeType {@{$blend[$i]}[1]} out");
				lx("select.key item:{$gradientID} channel:{$channelIndices[2]} time:{@{$values[$i]}[0]}");
					lx("key.break slopeWeight"); lx("key.slopeType {@{$blend[$i]}[0]} in"); 	lx("key.slopeType {@{$blend[$i]}[1]} out");
				lx("select.key item:{$gradientID} channel:{$channelIndices[3]} time:{@{$values[$i]}[0]}");
					lx("key.break slopeWeight"); lx("key.slopeType {@{$blend[$i]}[0]} in"); 	lx("key.slopeType {@{$blend[$i]}[1]} out");
			}
		}else{
			lx("channel.key time:{@{$values[$i]}[0]} value:{@{$values[$i]}[1]} channel:{$channelV}");
			if ( (@{$blend[$i]}[0] ne "auto") || (@{$blend[$i]}[1] ne "auto") ){
				lx("select.key item:{$gradientID} channel:{$channelIndices[0]} time:{@{$values[$i]}[0]} mode:set");
					lx("key.break slopeWeight"); lx("key.slopeType {@{$blend[$i]}[0]} in"); 	lx("key.slopeType {@{$blend[$i]}[1]} out");
			}
		}
	}

	#set locator pos
	if ( ($locatorPos[0] != 0) || ($locatorPos[1] != 0) || ($locatorPos[2] != 0) ){
		lx("item.channel pos.X {$locatorPos[0]} set {$txtrLocators[-1]}");
		lx("item.channel pos.Y {$locatorPos[1]} set {$txtrLocators[-1]}");
		lx("item.channel pos.Z {$locatorPos[2]} set {$txtrLocators[-1]}");
	}

	return $gradientID;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#UNIT VECTOR SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @unitVector = unitVector(@vector);
sub unitVector{
	my $dist1 = sqrt((@_[0]*@_[0])+(@_[1]*@_[1])+(@_[2]*@_[2]));
	@_ = ((@_[0]/$dist1),(@_[1]/$dist1),(@_[2]/$dist1));
	return @_;
}

