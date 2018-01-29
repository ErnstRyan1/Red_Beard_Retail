#perl
#ver. 1.0
#author : Seneca Menard
#This script will export the currently visible polygons to a new OBJ file with the same name and "_forAnim" appended.

#SCRIPT ARGUMENTS : (append these to the script name to execute them : ie : "@export_OBJForAnim.pl export_all_layers")
#"export_all_Layers" = if you want it to export ALL geometry from all layers




#script arguments
foreach my $arg (@ARGV){
	if ($arg =~ /export_all_layers/i){	our $exportAll = 1;}
}

#setup
my $newName;
my $appendName = "_forAnim";
my $fileName;
my $filePath = lxq("query sceneservice scene.file ? main");
my $sceneIndex = lxq("query sceneservice scene.index ? main");
my $mainlayer = lxq("query layerservice layers ? main");
my @layers = lxq("query layerservice layers ? all");
my @fgLayers = lxq("query layerservice layers ? fg");
my @bgLayers = lxq("query layerservice layers ? bg");

my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
$_ = lxq("query layerservice layer.id ? $_") for @layers;
$_ = lxq("query layerservice layer.id ? $_") for @fgLayers;
$_ = lxq("query layerservice layer.id ? $_") for @bgLayers;

if ($exportAll == 1){lx("select.subItem [$_] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]") for @layers;}
lx("select.drop polygon");
lx("unhide");
lx("select.copy");

#new scene and paste
lx("scene.new");
lx("select.paste");

#go through all materials and rename them.
my $txLayers = lxq("query sceneservice txLayer.count ?");
for (my $i=0; $i<$txLayers; $i++){
	if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
		my $name = lxq("query sceneservice txLayer.name ? $i");
		my $ptag = lxq("query sceneservice channel.value ? ptag");
		if (($ptag =~ /\//) || ($ptag =~ /\\/)){
			my $modName = $ptag;
			$modName =~ s/\\/__/g;
			$modName =~ s/\//__/g;
			lx("poly.renameMaterial [$ptag] [$modName]");
			lxout("renaming : $ptag <><> $modName");
		}
	}
}

#go through all ptags and rename those leftovers.
my $materialCount = lxq("query layerservice material.n ? all");
my @renameMaterials;
for (my $i=0; $i<$materialCount; $i++){
	my $materialName = lxq("query layerservice material.name ? $i");
	if (($materialName =~ /\\/) || ($materialName =~ /\//)){
		push(@renameMaterials,$materialName);
	}
}
foreach my $ptag (@renameMaterials){
	my $modName = $ptag;
	$modName =~ s/\\/__/g;
	$modName =~ s/\//__/g;
	lx("poly.renameMaterial [$ptag] [$modName]");
	lxout("renaming leftover : $ptag <><> $modName");
}


#setup the file save name
if ($filePath =~ /[a-z]/i){
	$fileName = $filePath;
}else{
	lx("dialog.setup style:fileOpen");
	lx("dialog.title [Export OBJ as :]");
	lx("dialog.open");
	if (lxres != 0){	die("The user hit the cancel button");	}
	$fileName = lxq("dialog.result ?");
}

#save the OBJ
$fileName =~ s/\..*//;
$fileName .= $appendName . "\.obj";
lx("scene.saveAs [$fileName] OBJ false");
lx("scene.close");

#restore layer visibility
lx("select.subItem [$mainlayerID] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
lx("select.subItem [$_] add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]") for @fgLayers;
lx("layer.setVisibility [$_] [1] [1]") for @bgLayers;



