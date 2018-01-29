#perl

#TEMP : must nuke all the images in the material that have the same name as the one I'm about to create.

#lxtrace(1);
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
userValueTools(senRenderBumpAO,boolean,config,"Ambient Occlusion","","","",xxx,xxx,"",1);
userValueTools(senRenderBumpFull,boolean,config,"Full render","","","",xxx,xxx,"",1);
userValueTools(senRenderBumpGrnInv,boolean,config,"Invert Green Channel","","","",xxx,xxx,"",1);
userValueTools(senRenderBmpTraceDist,string,config,"Trace Distance","","","",xxx,xxx,"","10%");




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if ($arg =~ /2d/i)			{	our $renderBumpFlat = 1;	}
	if ($arg =~ /dontDelHPUVs/)	{	our $dontDelHPUVs = 1;		}
}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SETUP
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
my $render;
my @fgLayers = lxq("query layerservice layers ? fg");
my @bgLayers = lxq("query layerservice layers ? bg");
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my $traceDist;
my $renderBumpMaterial;

#-----------------------------------
#---------------2D------------------
#-----------------------------------
if ($renderBumpFlat == 1){
	lxout("[->] Running 2d setup");

	#create new vmap
	lx("!!select.vertexMap seneRenderBump txuv 0") or lx("!!vertMap.new seneRenderBump txuv");

	#get bbox
	my @verts = lxq("query layerservice verts ? visible");
	my @bbox = boundingbox(@verts);
	my @bboxCenter = (   (@bbox[0]+@bbox[3])*0.5 , (@bbox[1]+@bbox[4])*0.5 , (@bbox[2]+@bbox[5])*0.5   );
	my @bboxSize = (	@bbox[3]-@bbox[0]	,	@bbox[4]-@bbox[1]	,	@bbox[5]-@bbox[2]	);
	$traceDist = (@bboxSize[2] + (@bboxSize[2]*.2));
	lxout("bbox = @bbox");
	lxout("bboxCenter = @bboxCenter");
	lxout("bboxSize = @bboxSize");
	lxout("traceDist = $traceDist");

	#create poly and select
	lx("tool.set prim.cube on");
	lx("tool.setAttr prim.cube cenX @bboxCenter[0]");
	lx("tool.setAttr prim.cube cenY @bboxCenter[1]");
	lx("tool.setAttr prim.cube cenZ @bbox[5]");
	lx("tool.setAttr prim.cube sizeX @bboxSize[0]");
	lx("tool.setAttr prim.cube sizeY @bboxSize[1]");
	lx("tool.setAttr prim.cube sizeZ 0");
	lx("tool.doApply");
	lx("tool.set prim.cube off");

	my $polyCount = lxq("query layerservice poly.n ? all");
	lx("select.element $mainlayer polygon set [$polyCount-1]");

	#assign material
	lx("poly.setMaterial seneRenderBump [1.0 1.0 1.0] [80.0 %] [20.0 %] [1] [0]");
	lx("$renderBumpMaterial = seneRenderBump");

	#rotate UVs
	lx("uv.rotate");
	lx("uv.rotate");
	lx("uv.rotate");
}

#-----------------------------------
#---------------3D------------------
#-----------------------------------
else{
	lxout("[->] Running 3d setup");

	#make sure a vmap is selected
	my $vmapCount = lxq("query layerservice vmap.n ? all");
	my $fail = 1;
	my @selectedVmaps;
	for (my $i=0; $i<$vmapCount; $i++){
		if (lxq("query layerservice vmap.type ? $i") eq "texture"){
			if (lxq("query layerservice vmap.selected ? $i") == 1){
				push(@selectedVmaps,$i);
				$fail = 0;
			}
		}
	}
	my $name = lxq("query layerservice vmap.name ? @selectedVmaps[0]");
	if (@selectedVmaps > 1){
		popup("Apparently you have multiple vmaps selected.\nIs it ok if I select the first one ($name)\nand deselect the others?  If not, I'll cancel the \nscript and you need to select the correct one.");
		lx("!!select.vertexMap $name txuv 0");
	}elsif (@selectedVmaps == 1){
		lxout("One vmap was selected ($name) and so I rendered using that one.");
	}else{
		die("There are no vmaps selected so I'm cancelling the script");
	}

	#find the renderBump material name
	for (my $i=0; $i<@fgLayers; $i++){
		my $layerName = lxq("query layerservice layer.name ? @fgLayers[$i]");
		my @visiblePolys = lxq("query layerservice polys ? visible");
		if (@visiblePolys > 0){
			my @tags = lxq("query layerservice poly.tags ? @visiblePolys[0]");
			$renderBumpMaterial = @tags[0];
			lxout("layer @fgLayers[$i]");
			last;
		}elsif ($i == @fgLayers){
			die("There are no polys visible in the foreground layers, so I'm cancelling the script");
		}
	}
	my $mainlayerName = lxq("query layerservice layer.name ? $mainlayer");
	lxout("renderBumpMaterial = $renderBumpMaterial");

	#if the user typed in a percentage, get trace dist
	$traceDist = lxq("user.value senRenderBmpTraceDist ?");
	if ($traceDist =~ /%/){
		$traceDist =~ s/%//;
		my @verts = lxq("query layerservice verts ? visible");
		my @bbox = boundingbox(@verts);
		my @bboxSize = (	@bbox[3]-@bbox[0]	,	@bbox[4]-@bbox[1]	,	@bbox[5]-@bbox[2]	);
		if ((@bboxSize[0] >= @bboxSize[1]) && (@bboxSize[0] >= @bboxSize[2]))		{ $traceDist = @bboxSize[0] * ($traceDist/100);	}
		elsif ((@bboxSize[1] >= @bboxSize[0]) && (@bboxSize[1] >= @bboxSize[2]))	{ $traceDist = @bboxSize[1] * ($traceDist/100);	}
		else																		{ $traceDist = @bboxSize[2] * ($traceDist/100);	}
	}
	lxout("traceDist = $traceDist");

	#hide all other materials in main layer
	lx("select.drop polygon");
	lx("select.polygon add material face $renderBumpMaterial");
	lx("select.invert");
	if (lxq("select.count polygon ?") > 0){lx("hide.sel");}

	#delete the vmap from the HP layer(s)
	if ($dontDelHPUVs != 1){
		lxout("[->] Going through all background layers and deleting the ($name) uvs.");
		lx("select.drop item");
		lx("select.subItem [$mainlayerID] set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
		lx("layer.swap");
		lx("uv.delete");
		lx("layer.swap");
	}
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RENDERBUMP
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------

#select render
my $items = lxq("query sceneservice item.n ? all");
for (my $i=0; $i<$items; $i++){
	if (lxq("query sceneservice item.type ? $i") eq "polyRender"){
		$render = lxq("query sceneservice item.id ? $i");
		last;
	}
}

#set AA
lx("item.channel aa [4] set [$render]");

##set resolution
my $resU = lxq("user.value senRenderBumpURes ?");
my $resV = lxq("user.value senRenderBumpVRes ?");
lx("!!item.channel resUnit [0] set [$render]");
lx("!!render.res [0] [$resU]");
lx("!!render.res [1] [$resV]");

#set file path
my $filePath = lxq("query sceneservice scene.file ? current");
if ($filePath eq ""){
	lx("dialog.setup fileSave");
	lx("dialog.title [File save destination]");
	lx("dialog.fileTypeCustom format:[tga] username:[Image to create] loadPattern:[tga] saveExtension:[tga]");
	lx("dialog.open");
	if (lxres != 0){	die("The user hit the cancel button");	}
	$filePath = lxq("dialog.result ?");
}
$filePath =~ s/\//\\/;
my @dirs = split(/\\/, $filePath);
@dirs[-1] =~ s/\.[a-zA-Z0-9]+//;
$filePath = "";
for (my $i=0; $i<@dirs; $i++){
	if ($i != @dirs-1)	{	$filePath .= @dirs[$i]."\\";	}
	else				{	$filePath .= @dirs[$i].".tga";	}
}
lxout("filePath = $filePath");

#-----------------------------------
#render normal map
#-----------------------------------
if (lxq("user.value senRenderBumpNormal ?") == 1){
	#turn off adaptive subDs
	lx("item.channel subdAdapt [True] set [$render]");

	#create TGA
	if (-e $filePath){unlink $filePath;}
	newTGA($filePath,$resU,$resV,24);

	#load TGA and set to normal and invert green   #TEMP!  should only create new TGA if it wasn't already in the shader group.
	my $itemCount = lxq("query sceneservice item.n ? all");
	my $materialID;
	for (my $i=0; $i<$itemCount; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "mask"){
			my $id = lxq("query sceneservice item.id ? $i");
			lx("select.subItem [$id] set textureLayer;render;environment;mediaClip;locator");
			if (lxq("mask.setPTag ?") eq $renderBumpMaterial){
				$materialID = $id;
				last;
			}
		}
	}

	lx("!!texture.new [$filePath]");
	lx("!!texture.parent $materialID");
	lx("!!item.channel imageMap\$greenInv [True]");
	lx("!!shader.setEffect normal");

	#bake
	lx("bake.objToTexture $traceDist");
	my $senSaveDir = 'C:/yoyo.tga';
	lx("clip.saveAs filename:[$senSaveDir]");
		#my $clipCount = lxq("query layerservice clip.n ? all");
		#my $clipID = lxq("query layerservice clip.id ? [$clipCount-1]");
		#lx("select.subItem [$clipID] set mediaClip");
		#popup("pause");

	#lx("clip.save");
	#popup("clipID = $clipID");

	#my @clips = lxq("query sceneservice selection ? txtrLocator");
	#popup("filePath = $filePath <><> clips = @clips");
	#lx("clip.saveAs");
	#lx("select.subItem @clips[0] set textureLayer;render;environment");
	#lx("texture.delete");
}

#-----------------------------------
#render diffuse map
#-----------------------------------
if (lxq("user.value senRenderBumpColor ?") == 1){

}

#-----------------------------------
#render specular map
#-----------------------------------
if (lxq("user.value senRenderBumpSpecular ?") == 1){

}

#-----------------------------------
#render AO map
#-----------------------------------
if (lxq("user.value senRenderBumpAO ?") == 1){

}

#-----------------------------------
#render FULL
#-----------------------------------
if (lxq("user.value senRenderBumpFull ?") == 1){

}




#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CLEANUP
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#reselect the layers
foreach my $layer (@fgLayers){
	my $id = lxq("query layerservice layer.id ? $layer");
	lx("select.subItem [$id] add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform [0] [0]");
}





#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#RENDER PROPERTIES SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub setRenderProps{
	#make sure the render outputs are deleted
	my $items = lxq("query sceneservice item.n ? all");
	my $dir = "C:\\Documents and Settings\\seneca.EDEN.000\\Desktop\\";
	my @outputs;

	#clear the render outputs
	if (@_[1] eq "delete"){
		for (my $i=0; $i<$items; $i++){
			if (lxq("query sceneservice item.type ? $i") eq "renderOutput"){push(@outputs,lxq("query sceneservice item.id ? $i"));}
		}
		foreach my $output (@outputs){
			lx("select.subItem [$output] set textureLayer;locator;render;environment;mediaClip");
			lx("!!texture.delete");
		}
	}

	#recreate the render outputs
	if (@_[0] eq "normalMap"){
		my $path = $dir."normal";
		lx("!!shader.create renderOutput");
		lx("!!shader.setEffect shade.normal");
	}elsif (@_[0] eq "colorMap"){
		my $path = $dir."color";
		lx("!!shader.create renderOutput");
		lx("!!shader.setEffect mat.diffuse");
	}elsif (@_[0] eq "AO"){
		my $path = $dir."AO";
		my $rays = lxq("user.value senRenderBumpAORays ?");
		lx("!!shader.create renderOutput");
		lx("!!shader.setEffect occl.ambient");
		lx("!!item.channel renderOutput\$occlRays $rays");
	}
	if (@_[1] eq "last"){
		my $path = $dir."alpha";
		lx("!!shader.create renderOutput");
		lx("!!shader.setEffect shade.alpha");
		lx("!!item.channel renderOutput\$filename [$path]");
		lx("!!item.channel renderOutput\$format PSD");
	}

	#change the render property channels
	lx("!!item.channel region [False] set [$render]");
	#--
	lx("!!item.channel mBlur [False] set [$render]");
	lx("!!item.channel dof [False] set [$render]");
	#--
	lx("!!item.channel ambRad 0 set [$render]");
	#--
	lx("!!item.channel subdAdapt [False] set [$render]");
	lx("!!item.channel dispEnable [False] set [$render]");

	if ((@_[0] eq "normalMap") || (@_[0] eq "colorMap") || (@_[0] eq "specularMap")){
		lx("!!item.channel rayShadow [False] set [$render]");
		lx("!!item.channel globEnable [False] set [$render]");
	}else{
		lx("!!item.channel rayShadow [True] set [$render]");
		lx("!!item.channel reflDepth 8 set [$render]");
		lx("!!item.channel refrDepth 8 set [$render]");
		lx("!!item.channel rayThresh [0.5%] set [$render]");
		#--
		lx("!!item.channel globEnable [True] set [$render]");
		lx("!!item.channel irrCache [False] set [$render]");
		lx("!!item.channel globRays 512 set [$render]");
		lx("!!item.channel globLimit [1] set [$render]");
		lx("!!item.channel globRange [0] set [$render]");
	}

	lx("select.subItem [$render] set textureLayer;locator;render;environment;mediaClip");
	#popup("Setting up the render properties for @_[0]\nDo they look ok?");
}










#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BOUNDING BOX   (modded for vert.wpos)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @bbox = boundingbox(@selectedVerts);
sub boundingbox #minX-Y-Z-then-maxX-Y-Z
{
	my @bbVerts = @_;
	my $firstVert = @bbVerts[0];
	my @firstVertPos = lxq("query layerservice vert.wpos ? $firstVert");
	my $minX = @firstVertPos[0];
	my $minY = @firstVertPos[1];
	my $minZ = @firstVertPos[2];
	my $maxX = @firstVertPos[0];
	my $maxY = @firstVertPos[1];
	my $maxZ = @firstVertPos[2];
	my @bbVertPos;

	foreach my $bbVert(@bbVerts)
	{
		@bbVertPos = lxq("query layerservice vert.wpos ? $bbVert");
		#minX
		if (@bbVertPos[0] < $minX)	{	$minX = @bbVertPos[0];	}

		#minY
		if (@bbVertPos[1] < $minY)	{	$minY = @bbVertPos[1];	}

		#minZ
		if (@bbVertPos[2] < $minZ)	{	$minZ = @bbVertPos[2];	}

		#maxX
		if (@bbVertPos[0] > $maxX)	{	$maxX = @bbVertPos[0];	}

		#maxY
		if (@bbVertPos[1] > $maxY)	{	$maxY = @bbVertPos[1];	}

		#maxZ
		if (@bbVertPos[2] > $maxZ)	{	$maxZ = @bbVertPos[2];	}
	}
	my @bbox = ($minX,$minY,$minZ,$maxX,$maxY,$maxZ);
	return @bbox;
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
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
			if (@_[10] eq ""){popup("woah.  there's no value in the userVal sub!");	}		}
		elsif (@_[10] == ""){popup("woah.  there's no value in the userVal sub!");		}
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
