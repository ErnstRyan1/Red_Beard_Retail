#perl
#QUICK BOOLEANS AND DRILLS
#AUTHOR : Seneca Menard
#version 1.84 #added a new feature
#(11-9-07 fix) : it now properly restores visibility of the background instances.
#(4-8-08 feature) : now has a new "BOOLEAN : DOUBLE (custom)" feature.  This will actually do two "tunnel" stencil drills on the selected and unselected geometry.  It's basically the same as "boolean union", only it doesn't destroy your UVs and also doesn't merge the vertices yet, which is good if you want to do a bit of cleanup with the collapse tool first (which would normally corrupt the UVs if the two meshes were merged).  Also, make sure your geometry is tripled and all holes are sealed if you want the best results.
#(1-22-09 fix) : I renamed the stencil drill names to make them a little bit more obvious.  (i can never figure out what CORE or TUNNEL will do..)
#(1-29-09 fix) : It's now properly restoring visibility of mesh instances.
#(1-30-09 fix) : removed a meaningless popup that would occur the first time you run the script.
#(3-31-09 fix) : updated the script for 401 and fixed a user.value error because i changed the names a while ago
#(10-30-15 fix) : put in {} around the material name for poly drill to stop errors if multiple words are used.

#------DESCRIPTION:-------
#This script is set up so you can just select a single poly or vert or edge and it will select the rest, convert it to polygons and cut/paste it into a BG layer and do a boolean or drill or whatnot with one click.
#note1: It only performs the drill/boolean on whatever geometry was in the MAIN LAYER.  It doesn't work across multiple layers.

#------TO INSTALL THE SCRIPT AND FORM:-------
#1)Copy the quickBooleanDrills.pl file into the Scripts user directory (ie, C:\Documents and Settings\seneca\Application Data\Luxology\Scripts)
#2)Copy the quickBooleanDrills.cfg to any directory and import it into modo.
#3)Then, go into the TOOLBAR-->FORM EDITOR-->Quick Booleans, right click on it and choose "Bind to Key"

#-------SCRIPT OPTIONS:--------
#The very first time you bring up the form, the options won't show up until you run the script.  Once you run it, the options will be there from then on.
#1) DRILL STYLE : That's so you can choose the diff. 2d Drill styles.
#2) MATERIAL? : If you use DRILL-->STENCIL, it will apply the material you type in on this line to the cut part of the mesh.
#3) UNWELD? : That's so if you're like me and you sometimes unweld your drilling-mesh before you drill so you can cut ALL it's edges into the mesh not just it's silhouette edges.  It defaults to OFF so you don't use it on accident.
#4) DELETE MESH? : This option is to decide whether or not to delete the booleaning or drilling geometry for you.  It's nice to have it do it's job and go away in one click.  :)



#================================================================================
#safety check
#================================================================================
if (lxq("select.count polygon ?") < 1)
{
	die("You must have at least one polygon selected so I know what to cut the geometry with");
}

#================================================================================
#================================================================================
#setup
#================================================================================
#================================================================================
#mainlayer(s)
lxout("QUICK BOOLEANS AND DRILLS SCRIPT----------------------------------");
my $modoVer = lxq("query platformservice appversion ?");
my $mainlayer  = lxq("query layerservice layers ? main");
my @fgLayers = lxq("query layerservice layers ? fg");
my @bgLayers = lxq("query layerservice layers ? bg");

#convert the layer indices to itemids.
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
for (my $i = 0; $i<@fgLayers; $i++)	{	@fgLayers[$i] = lxq("query layerservice layer.id ? @fgLayers[$i]");	}
for (my $i=0; $i<@bgLayers; $i++)	{	@bgLayers[$i] = lxq("query layerservice layer.id ? @bgLayers[$i]");	}

#add the visible mesh instances to the bgLayers list
addInstancesToBGList(\@bgLayers);

#remember selection type
if    ( lxq( "select.typeFrom {vertex;polygon;item;edge} ?" ) )	{ our $selectType = vertex;		}
elsif ( lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ) )	{ our $selectType = edge; 		}
elsif ( lxq( "select.typeFrom {polygon;item;edge;vertex} ?" ) )	{ our $selectType = polygon;	}


#================================================================================
#================================================================================
#SCRIPT ARGUMENTS
#================================================================================
#================================================================================
$booleanSub = 0;
$booleanAdd = 0;
$booleanInter = 0;
$solidDrill = 0;
$drillX = 0;
$drillY = 0;
$drillZ = 0;

foreach my $arg (@ARGV)
{
	if ($arg eq "booleanSub")				{	$booleanSub = 1; 				}
	elsif ($arg eq "booleanUnion")			{	$booleanUnion = 1; 				}
	elsif ($arg eq "booleanAdd")			{	$booleanAdd = 1; 				}
	elsif ($arg eq "booleanInter")			{	$booleanInter = 1;				}
	elsif ($arg eq "solidDrill")			{	$solidDrill = 1; 				}
	elsif ($arg eq "drillX")				{	$drillX = 1; 					}
	elsif ($arg eq "drillY")				{	$drillY = 1; 					}
	elsif ($arg eq "drillZ")				{	$drillZ = 1; 					}
	elsif ($arg eq "solidDrillDouble")		{	our $solidDrillDouble = 1;		}
	elsif ($arg eq "solidDrillDoubleCut")	{	our $solidDrillDoubleCut = 1;	}
}


#================================================================================
#================================================================================
#USER VARIABLES
#================================================================================
#================================================================================
userValueTools(seneDrillMaterial,string,config,"Material name for STENCIL","","","",xxx,xxx,"",Default);
userValueTools(seneDrillUnweld,integer,config,"Unweld the vertices?","Unweld=YES;Unweld=NO","","",0,1,"",1);
userValueTools(seneDrillStyle,integer,config,"POLY DRILL style :","SLICE;STENCIL(uses_Material);CORE(Keep Touching);TUNNEL(Delete Touching)","","",0,3,"",0);
userValueTools(seneDrillDelete,integer,config,"Delete mesh afterwards?","DeleteMesh=YES;DeleteMesh=NO","","",0,1,"",0);

if ($solidDrillDouble == 1){
	&solidDrillDouble;
}

elsif ($solidDrillDoubleCut == 1){
	solidDrillDoubleCut();
}

else{
	#drill material setup
	if (($drillX == 1) || ($drillY == 1) || ($drillZ == 1)){
		our $materialName = lxq("user.value seneDrillMaterial ?");
		lxout("-Using this material : $materialName");
	}

	#drill style setup
	if    (lxq( "user.value seneDrillStyle ?" ) eq "SLICE")						{	lxout("-you chose : SLICE");	our $drillStyle = slice;	}
	elsif (lxq( "user.value seneDrillStyle ?" ) eq "STENCIL(uses_Material)")	{	lxout("-you chose : STENCIL");	our $drillStyle = stencil;	}
	elsif (lxq( "user.value seneDrillStyle ?" ) eq "CORE(Keep Touching)")		{	lxout("-you chose : CORE");		our $drillStyle = core;		}
	elsif (lxq( "user.value seneDrillStyle ?" ) eq "TUNNEL(Delete Touching)")	{	lxout("-you chose : TUNNEL");	our $drillStyle = tunnel;	}



	#================================================================================
	#================================================================================
	#BOOLEAN OPERATION
	#================================================================================
	#================================================================================
	#select rest
	lx("select.connect");

	#make sure polys are what's selected.
	if ($selectType ne "polygon") { lx("select.convert polygon"); }

	#cut polygons
	lx("select.cut");

	#make new layer and paste into it.
	lx("layer.newItem mesh");
	lx("select.paste");

	#unweld before DRILL (if specified)
	if (($drillX == 1) || ($drillY == 1) || ($drillZ == 1)){
		if (lxq("user.value seneDrillUnweld ?") eq "Unweld=YES"){  #god damnit.  shouldn't i be able to use the list number and not the list name?
			lxout("-I'm unwelding");
			lx("vert.split");
		}
	}

	#set new layer as BG layer and put original layer as FG layer
	my $tempLayer = lxq("query layerservice layers ? main");
	$tempLayer = lxq("query layerservice layer.id ? $tempLayer");
	lx("select.subItem {$mainlayerID} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
	lx("layer.setVisibility $tempLayer [1] [1]");


	#------------------------------------------------
	#perform whichever boolean or drill
	#------------------------------------------------
	if ($booleanSub == 1)							{ 	lx("poly.boolean subtract");									lxout("-using BOOLEAN SUBTRACT"); 	}
	elsif ($booleanUnion == 1)						{ 	lx("poly.boolean union");										lxout("-using BOOLEAN UNION");		}
	elsif ($booleanAdd == 1) 						{ 	lx("poly.boolean add");											lxout("-using BOOLEAN ADD");		}
	elsif ($booleanInter == 1)						{ 	lx("poly.boolean intersect"); 									lxout("-using BOOLEAN INTERSECT");	}
	elsif ($drillX == 1) 							{ 	lx("poly.drill {$drillStyle} x {$materialName}"); 				lxout("-using DRILL X"); 			}
	elsif ($drillY == 1) 							{ 	lx("poly.drill {$drillStyle} y {$materialName}"); 				lxout("-using DRILL Y"); 			}
	elsif ($drillZ == 1)							{ 	lx("poly.drill {$drillStyle} z {$materialName}"); 				lxout("-using DRILL Z"); 			}
	elsif (($solidDrill == 1) && ($modoVer < 400)) 	{ 	lx("poly.solidDrill {$drillStyle}");							lxout("-using SOLID DRILL");		}
	elsif (($solidDrill == 1) && ($modoVer > 400)) 	{ 	lx("poly.solidDrill mode:{$drillStyle} cutmesh:background");	lxout("-using SOLID DRILL");		}
	
	#do cleanup
	cleanup();
}

##------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##SOLID DRILL DOUBLE (CUT)
##------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub solidDrillDoubleCut{
	lxout("-using SOLID DRILL DOUBLE CUT");
	
	my @bgLayerIDs = lxq("query layerservice layers ? bg");
	for (my $i=0; $i<@bgLayerIDs; $i++){	$bgLayerIDs[$i] = lxq("query layerservice layer.id ? {$bgLayerIDs[$i]}");	}
	my $blah = lxq("query layerservice layer.name ? {$mainlayer}");
	my @polys = lxq("query layerservice polys ? selected");
	my @polys_cutter = listTouchingPolys2($polys[0]);
	my @polys_rest = listTouchingPolys2($polys[-1]);
	my $layerID_cutter1;
	my $layerID_cutter2;
	my $layerID_rest1;
	my $layerID_rest2;
	
	if ((@polys_cutter == 0) || (@polys_rest == 0) || ($polys_cutter[0] == $polys_rest[0])){	die("Your first selected poly and last selected poly are not on different mesh islands and thus i'm cancelling the script");	}
	
	#copy polys_cutter to two new layers
	lx("!!select.drop polygon");
	lx("!!select.element {$mainlayer} polygon add $_") for @polys_cutter;
	lx("!!select.copy");
	lx("!!layer.newItem mesh");
	lx("!!select.paste");
	$layerID_cutter1 = lxq("query layerservice layers ? main");
	$layerID_cutter1 = lxq("query layerservice layer.id ? $layerID_cutter1");
	lx("!!layer.newItem mesh");
	lx("!!select.paste");
	$layerID_cutter2 = lxq("query layerservice layers ? main");
	$layerID_cutter2 = lxq("query layerservice layer.id ? $layerID_cutter2");
	
	#copy polys_rest to two new layers
	lx("!!select.subItem {$mainlayerID} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
	lx("!!select.drop polygon");
	lx("!!select.element {$mainlayer} polygon add $_") for @polys_rest;
	lx("!!select.copy");
	lx("!!layer.newItem mesh");
	lx("!!select.paste");
	$layerID_rest1 = lxq("query layerservice layers ? main");
	$layerID_rest1 = lxq("query layerservice layer.id ? $layerID_rest1");
	lx("!!layer.newItem mesh");
	lx("!!select.paste");
	$layerID_rest2 = lxq("query layerservice layers ? main");
	$layerID_rest2 = lxq("query layerservice layer.id ? $layerID_rest2");
	
	#hide the layers and do cut 1
	my $layerCount = lxq("query layerservice layer.n ? all");
	for (my $i=1; $i<$layerCount+1; $i++){
		my $id = lxq("query layerservice layer.id ? $i");
		my $name = lxq("query layerservice layer.name ? $i");
		lx("!!layer.setVisibility {$id} 0 0");
	}
	lx("!!layer.setVisibility {$layerID_rest1} 1 0");
	lx("!!select.subItem {$layerID_cutter1} set mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("!!poly.solidDrill core cutmesh:background");
	
	#hide the layers and do cut2
	lx("!!layer.setVisibility {$layerID_rest1} 0 0");
	lx("!!layer.setVisibility {$layerID_cutter2} 1 0");
	lx("!!select.subItem {$layerID_rest2} set mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("!!poly.solidDrill tunnel cutmesh:background");
	
	#cut the polys from the last cut layer
	lx("!!select.cut");

	#delete original polys in mainlayer
	lx("!!select.subItem {$mainlayerID} set mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("!!select.element {$mainlayer} polygon add $_") for @polys_cutter;
	lx("!!select.element {$mainlayer} polygon add $_") for @polys_rest;
	lx("!!delete");
	
	#paste polys from last cut layer
	lx("select.paste");
	
	#cut/paste the polys from the first cut layer
	lx("!!select.subItem {$layerID_cutter1} set mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("!!select.cut");
	lx("!!select.subItem {$mainlayerID} set mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("!!select.paste");
	
	#delete the temp layers
	lx("select.drop item");
	lx("!!select.subItem {$layerID_cutter1} add mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("!!select.subItem {$layerID_cutter2} add mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("!!select.subItem {$layerID_rest1} add mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("!!select.subItem {$layerID_rest2} add mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("item.delete");
	
	#go back to mainlayer and restore layer visibilities
	lx("!!select.subItem {$mainlayerID} set mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
	lx("!!layer.setVisibility {$mainlayerID} 1 0");
	lx("!!layer.setVisibility {$_} 1 0") for @bgLayerIDs;
}


##------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##SOLID DRILL DOUBLE (MERGE)
##------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub solidDrillDouble{
	lxout("-using SOLID DRILL DOUBLE");
	if ($selectType ne "polygon") { lx("!!select.convert polygon"); }

	if (lxq("select.count polygon ?") > 0){
		lx("!!select.connect");
		lx("!!select.cut");
		lx("!!layer.newItem mesh");
		lx("!!select.paste");
		lx("!!layer.newItem mesh");
		lx("!!select.paste");
		lx("!!select.subItem {$mainlayerID} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
		lx("!!select.cut");
		lx("!!layer.newItem mesh");
		lx("!!select.paste");

		#cut pasted layer
		my $mainlayerName = lxq("query layerservice layer.name ? {$mainlayerID}");
		my @layers = lxq("query layerservice layers ? all");
		for (my $i=0; $i<@layers; $i++){@layers[$i] = lxq("query layerservice layer.id ? @layers[$i]");}

		lx("!!select.subItem {@layers[-2]} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
		lx("layer.setVisibility {@layers[-1]} 1");
		lx("poly.solidDrill tunnel");

		#cut original layer
		lx("!!select.subItem {@layers[-1]} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
		lx("!!layer.setVisibility {@layers[-3]} 1");
		if ($modoVer < 400)	{lx("!!poly.solidDrill tunnel");}
		else				{lx("poly.solidDrill mode:tunnel cutmesh:background");}

		#now put polys back
		lx("!!select.subItem {@layers[-1]} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
		lx("!!select.subItem {@layers[-2]} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
		lx("!!select.cut");
		lx("!!select.subItem {$mainlayerID} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
		lx("!!select.paste");

		#delete 2 layers
		lx("!!select.subItem {@layers[-3]} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
		lx("!!select.subItem {@layers[-2]} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
		lx("!!select.subItem {@layers[-1]} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 1");
		lx("!!item.delete xfrmcore");

		#set the mainlayer back.
		lx("select.subItem {$mainlayerID} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");

		#set all the other FG layers back.
		foreach my $fgLayer (@fgLayers){
			#ignore the mainlayer
			if ($fgLayer ne $mainlayer){
				lx("select.subItem $fgLayer add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [0]");
			}else{
				next;
			}
		}

		#set all the other BG layers back.
		foreach my $bgLayer (@bgLayers){
			lx("layer.setVisibility $bgLayer [1] [1]");
		}
	}else{
		die("You don't have any polys selected, so I'm cancelling the script.");
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



#================================================================================
#================================================================================
#CLEANUP
#================================================================================
#================================================================================
#delete the new layer.
sub cleanup{
	lx("layer.swap");
	lx("layer.delete");

	#go back to the original layer.
	lx("select.subItem {$mainlayerID} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");

	#put the boolean geometry back if they want it back
	if (lxq("user.value seneDrillDelete ?") eq "DeleteMesh=NO"){
		lxout("-I'm putting the original boolean/drill geometry back");
		lx("select.paste");
	}

	#Turn UNWELD option OFF again so they don't use it on accident!
	#lx("user.value seneDrillUnweld 1");

	#set all the other FG layers back.
	foreach my $fgLayer (@fgLayers){
		#ignore the mainlayer
		if ($fgLayer ne $mainlayer){
			lx("select.subItem $fgLayer add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [0]");
		}else{
			next;
		}
	}

	#set all the other BG layers back.
	foreach my $bgLayer (@bgLayers){
		lx("layer.setVisibility $bgLayer [1] [1]");
	}
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#OPTIMIZED SELECT TOUCHING POLYGONS sub  (if only visible polys, you put a "hidden" check before vert.polyList point)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @connectedPolys = listTouchingPolys2(@polys[-$i]);
sub listTouchingPolys2{
	lxout("[->] LIST TOUCHING subroutine");
	my @lastPolyList = @_;
	my $stopScript = 0;
	our %totalPolyList = ();
	my %vertList;
	my %vertWorkList;
	my $vertCount;
	my $i = 0;

	#create temp vertList
	foreach my $poly (@lastPolyList){
		my @verts = lxq("query layerservice poly.vertList ? $poly");
		foreach my $vert (@verts){
			if ($vertList{$vert} == ""){
				$vertList{$vert} = 1;
				$vertWorkList{$vert}=1;
			}
		}
	}

	#--------------------------------------------------------
	#FIND CONNECTED VERTS LOOP
	#--------------------------------------------------------
	while ($stopScript == 0)
	{
		my @currentList = keys(%vertWorkList);
		%vertWorkList=();

		foreach my $vert (@currentList){
			my @verts = lxq("query layerservice vert.vertList ? $vert");
			foreach my $vert(@verts){
				if ($vertList{$vert} == ""){
					$vertList{$vert} = 1;
					$vertWorkList{$vert}=1;
				}
			}
		}

		$i++;

		#stop script when done.
		if (keys(%vertWorkList) == 0){
			#popup("round ($i) : it says there's no more verts in the hash table <><> I've hit the end of the loop");
			$stopScript = 1;
		}
	}

	#--------------------------------------------------------
	#CREATE CONNECTED POLY LIST
	#--------------------------------------------------------
	foreach my $vert (keys %vertList){
		my @polys = lxq("query layerservice vert.polyList ? $vert");
		foreach my $poly(@polys){
			$totalPolyList{$poly} = 1;
		}
	}

	return (keys %totalPolyList);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SUBROUTINES
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
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
#ADD THE INSTANCES TO THE BGLAYERS LIST SO THAT YOU CAN UNHIDE THEM WHEN THE SCRIPT'S DONE (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : addInstancesToBGList(\@bgLayers);
sub addInstancesToBGList{
	my $items = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$items; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "meshInst"){
			my $id = lxq("query sceneservice item.id ? $i");
			my $visible = lxq("layer.setVisibility {$id} ?");
			if ($visible == 1){push (@{$_[0]},$id);}
		}
	}
}
