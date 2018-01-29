#perl
#author : Seneca Menard
#this script will copy the current layer's contents to a new scene and save as fbx and close. doesn't save original lxo.

#SCRIPT CVARS
foreach my $arg (@ARGV){
	if ($arg eq "multiExport")	{	our $multiExport = 1;	}
}


#GET LXO NAME
my @layerToDoList;
my $sceneIndex = lxq("query sceneservice scene.index ? current");
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my $LXOName = lxq("query sceneservice scene.file ? current");
$LXOName =~ s/\\/\//g;
$LXOName =~ s/\.lxo//i;
$LXOName =~ s/\/work\//\//;
my $sceneName;


#BUILD LIST OF LAYERS TO EXPORT
if ($multiExport == 1){
	lx("!!scene.save");
	push(@layerToDoList,lxq("query sceneservice selection ? mesh"));
}else{
	push(@layerToDoList,$mainlayerID);
}


#EXPORT EACH LAYER
foreach my $layerID (@layerToDoList){
	#get new fbx file path that's not in source dir, but in game dir.
	my $layerName = lxq("query layerservice layer.name ? {$layerID}");
	$sceneName = $LXOName;
	$sceneName .= "_" . $layerName . ".fbx";
	lxout("exporting $sceneName");

	#copy polys to new layer
	lx("!!select.subItem {$layerID} set mesh;meshInst;triSurf;camera;light;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("!!select.drop polygon");
	lx("!!unhide");
	lx("!!select.copy");
	lx("!!scene.new");
	lx("!!select.paste");
	lx("!!poly.freeze false");
	popup("pausing to get smoothing groups properly exported");
	
	#name layer in new LXO
	my $newLayerID = lxq("query layerservice layer.id ? 1");
	lx("!!item.name name:{$mainlayerName} item:{$newLayerID}");
	
	#delete camera and light
	lx("!!select.drop item");
	lx("!!select.itemType mode:add type:sunLight");
	lx("!!select.itemType mode:add type:camera");
	lx("!!select.itemType mode:add type:groupLocator");
	lx("!!delete");
	#save fbx
	lx("!!scene.saveAs [$sceneName] {fbx} [false]");
	lx("!!scene.close");
	
	#removeBlankUVDataFromFBX($sceneName);
	
	#reselect original scene
	if (lxq("query sceneservice scene.index ? current") != $sceneIndex){	lx("scene.set {$sceneIndex}");	}	
}



#CLEANUP : select original layer again.
lx("!!select.subItem {$mainlayerID} set mesh;meshInst;triSurf;camera;light;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
lx("!!select.drop polygon");
lx("!!select.vertexMap Color rgba replace");
lx("!!select.vertexMap Texture txuv replace");











#-----------------------------------------------------------------------------------------------------------
#OPEN THE FBX TEXT FILE AND DELETE TEH JUNK UV MAPS. (note, it'll have incorrect uv indices but i'm not bothering fixing that because i don't see it breaking anything yet. heh)
#-----------------------------------------------------------------------------------------------------------
sub removeBlankUVDataFromFBX{
	open (FBXFile, "<$_[0]") or die("I couldn't find this FBX : $_[0]");
	my @fbxData;
	my @tempData;
	my $useData = 1; #0=ignore.  1=use.  2=tempUse.
	
	while (<FBXFile>){
		#if paying attention to data.
		if ($useData == 1){
			if ($_ =~ /LayerElementUV: /){
				push(@tempData,$_);
				$useData = 2;
			}else{
				push(@fbxData,$_);
			}
		}
		
		#if ignoring data.
		elsif ($useData == 0){
			if ($_ eq "        }\n"){
				$useData = 1;
			}
		
		}
		
		#if on temporary hold
		else{
			push(@tempData,$_);
			
			if ($_ eq "            Name: \"\"\n"){
				$useData = 0;
				@tempData = "";
			}
			
			elsif ($_ =~ /            Name: \"Texture/){
				$useData = 1;
				for (my $i=0; $i<@tempData; $i++){
					push(@fbxData,$tempData[$i]);
				}
			}
		}
	}
	close(FBXFile);

	#write out new fbx
	open (FBXFile, ">$_[0]") or die("I couldn't find this FBX : $_[0]");
	print FBXFile $_ for @fbxData;
	close(FBXFile);
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

