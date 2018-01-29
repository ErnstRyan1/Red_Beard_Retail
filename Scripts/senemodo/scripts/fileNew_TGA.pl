#perl
#ver 1.2
#author : Seneca Menard
#This script will create a 24 bit TGA image and add it to the shader tree.  The reason why I wrote this is because modo's image creator won't let you create rectangular images.

#(7-29-15 feature) : UE4Localmap : use this cvar to create the tga and set it to be a MIKKT normal map for ue4.



#SCRIPT ARGUMENTS
foreach my $arg (@ARGV){
	if ($arg eq "UE4Localmap")	{	our $UE4Localmap = 1;	}
}

my $modoVer = lxq("query platformservice appversion ?");
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? main");

#check to see if mesh and uvmap is selected first before you run script if UE4LOCALMAP is on.
if ($UE4Localmap == 1){
	if ($modoVer < 900)						{	die("Doh!  Can't setup the MIKK tangents for ue4 because this version of modo is older than 901!");	}
	if ($mainlayer eq "")					{	die("You don't have a layer selected so i'm cancelling the script");								}
	if (queryIfAnyUvmapIsSelected() == 0)	{	die("You don't have a uvmap selected so i'm cancelling the script");								}
	lx("select.type item");
	lx("select.subItem {$mainlayerID} set mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;modSculpt;ABCCurvesDeform.sample;ABCdeform.sample;defaultShader;defaultShader 0 0");
}


lx("dialog.setup fileSave");
#lx("dialog.fileType tga");
lx("dialog.fileTypeCustom format:[tga] username:[Targa Files] loadPattern:[*.tga] saveExtension:[tga]");
lx("dialog.open");
my $file = lxq("dialog.result ?") or die("The user cancelled the dialog window so I'm cancelling the script");
$file =~ s/\..*/.tga/;
my $size = quickDialog("Image size:",string,"512,512","","");
my @size = split(/,/, $size);
if ((@size[0] > 0) && (@size[1] > 0)){}else{die("It appears you typed in an illegal size.  Please try again");}

my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
my $id;
for (my $i=0; $i<$txLayerCount; $i++){
	if (lxq("query sceneservice txLayer.isSelected ? $i") == 1){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			$id = lxq("query sceneservice txLayer.id ? $i");
			last;
		}else{
			my $parent = lxq("query sceneservice txLayer.parent ? $i");
			my $parentType = lxq("query sceneservice txLayer.type ? $parent");
			if (($parentType eq "polyRender") || ($parentType eq "mask")){
				$id = lxq("query sceneservice txLayer.id ? $parent");
				last;
			}
		}
	}
}

if ($id eq ""){
	my $itemCount = lxq("query sceneservice item.N ? all");

	for (my $i=0; $i<$itemCount; $i++){
		my $type = lxq("query sceneservice item.type ? $i");
		if ($type eq "polyRender"){
			$id = lxq("query sceneservice item.id ? $i");
			last;
		}
	}
}

if ($id eq ""){die("I couldn't find which txLayer to parent the new image to so I'm cancelling the script");}
newTGA($file,@size[0],@size[1],24);
lx("texture.new [$file]");
lx("texture.parent [$id] [-1]");

if ($UE4Localmap == 1){
	lx("!!item.channel imageMap\$greenInv true");
	lx("!!item.channel txtrLocator\$tngtType dpducross");
	lx("!!item.channel videoStill\$colorspace \"nuke-default:linear\"");
	lx("!!shader.setEffect normal");
	lx("mesh.mikktspacegen");
	
	my @txtrLocatorSel = lxq("query sceneservice selection ? txtrLocator");
	if (@txtrLocatorSel < 1){
		popup("doh!  i created one image, but don't have a texture locator selected and so i can't set the tangent vector type to dpducross");
		return;
	}elsif (@txtrLocatorSel > 1){
		lxout("hmm. i created one image, but somehow have more than one texture locator selected.  something might be wrong?");
	}
	
	lx("select.type polygon");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUERY IF ANY UV MAP IS SELECTED sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#return 1 if a uvmap is selected, 0 if there isn't.
sub queryIfAnyUvmapIsSelected{
	my $vmapCount = lxq("query layerservice vmap.n ? all");
	for (my $i=0; $i<$vmapCount; $i++){
		if ((lxq("query layerservice vmap.type ? $i") eq "texture") && (lxq("query layerservice vmap.selected ? $i") == 1)){
			return 1;
		}
	}
	return 0;
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
	my $bitMode = @_[3];

	lxout("[->] Creating a new TGA here : $file");
	open (TGA, ">$file") or die("I can't open the TGA");
	binmode(TGA); #explicitly tells it to be a RAW file

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
	my $bits =				pack("C", $bitMode);
	my $descriptor =		pack("C", 0);
	if ($bitMode == 32){
		our $black =		pack("C4",1,0,0,0);  #note, C4=CCCC. C*=Cinfinite.  also, the read order is backwards, so alpha comes first. lastly, ("CCC",0,0,0) = ("C",0) run three times
	}else{
		our $black =		pack("CCC",0,0,0);
	}


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

