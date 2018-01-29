#perl
#ver 0.5
#author : Seneca Menard

#This script is to assign collision names to the selected meshes.  Use it with the "sen_Unreal Collision" gui. Just press the button that matches the type of collision the selected meshes should have and it will rename them to what unreal expects.

#SETUP
my $mainlayer = lxq("query layerservice layers ? main");

#ARGS
foreach my $arg (@ARGV){
	if		($arg =~ /UBX/i)		{	collision("UBX");	}
	elsif	($arg =~ /USP/i)		{	collision("USP");	}
	elsif	($arg =~ /UCX/i)		{	collision("UCX");	}
	elsif	($arg =~ /splitMeshes/i){	splitMeshes();		}
}

#SPLIT MESH INTO MESHES sub
sub splitMeshes{
	my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
	my $polyCount = lxq("query layerservice poly.n ? all");
	
	while ($polyCount > 0){
		lx("!!select.element {$mainlayer} polygon set {0}");
		lx("!!select.connect");
		lx("!!select.cut");
		lx("!!item.create mesh");
		lx("!!select.paste");
		lx("!!select.subItem {$mainlayerID} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
		$polyCount = lxq("query layerservice poly.n ? all");
	}
	
	lx("!!item.delete mask:{mesh}");
}

#APPLY COLLISION NAMES sub
sub collision{
	my $mainlayerName;
	my %usedNumbers;
	my @meshes = lxq("query sceneservice selection ? mesh");
	my %collisionMeshes;
	my $count;
	
	#find main layer name and log collision items (uses first name that's not mesh or some collision name)
	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$itemCount; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "mesh"){
			my $name = lxq("query sceneservice item.name ? $i");
			my $foundUseForName = 0;
			if ($name !~ /Mesh/){
				if ( ($name !~ /ucx/i) && ($name !~ /ubx/i) && ($name !~ /usp/i)){
					$mainlayerName = $name;
					$mainlayerName =~ s/ \([0-9]+\)$//;
				}else{
					my $meshID = lxq("query sceneservice item.id ? $i");
					$collisionMeshes{$meshID} = 1;
					$count++;
				}
			}
		}
	}
	
	#die if main layer name couldn't be found
	if ($mainlayerName eq ""){	die("Couldn't find a layer with a name that's not 'Mesh' or have UCX or UBX or USP in it so I don't know what to name the collision layers and am thus cancelling the script");	}
	
	#take selected items and give 'em temp names and put 'em in the log
	foreach my $meshID (@meshes){
		if ($firstUnusedNumber < 10){ $firstUnusedNumber = "0" . $firstUnusedNumber;	}
		my $newName = $_[0];
		$collisionMeshes{$meshID} = 1;
		$count++;
		lx("!!item.name name:{$newName} type:{mesh} item:{$meshID}");
	}
	
	#now go through all items in the log and give them proper sequential numbering.
	$count = 1;
	foreach my $meshID (keys %collisionMeshes){
		my $name = lxq("query sceneservice item.name ? {$meshID}");
		my $number;
		if ($count < 10)	{	$number = "0" . $count;	}
		else				{	$number = $count;		}
		$count++;
		$name = substr($name, 0, 3);
		$name .= "_" . $mainlayerName . "_" . $number;
		
		lx("!!item.name name:{$name} type:{mesh} item:{$meshID}");
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