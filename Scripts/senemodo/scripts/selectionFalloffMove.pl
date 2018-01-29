#perl
# SELECTION FALLOFF MOVE TOOL SCRIPT
#BY: Seneca Menard
#version 1.1 (modo2)

# --This script's a silly little script where it will look at whatever elements you have selected and then apply a sloping vertex map gradation inside it and then automatically bring up the MOVE TOOL for you.
# --Just don't forget that I'm turning VERTEX MAP FALLOFF ON.....  I tend to forget that and wonder why in the world I can't create a cube or whatever later..  :P
# --It's also got a feature called "plateau", where you can stop the gradation falloff at a certain number.  Like, if you want the gradation falloff to only extend 3 polygons into your selection, just run the script with "plateau" appended
# to the script and when you run the script, it'll pop up a little window to ask you far in the falloff should go.  #EXAMPLE : @{C:\Program Files\Luxology\modo\senescripts\selectionFalloff.pl} plateau
#fixed for modo2


#========================================
#========================================
#SETUP
#========================================
#========================================
#mainlayer
my $mainlayer  = lxq("query layerservice layers ? main");
lxout("GRADATED SELECTION FALLOFF MOVE TOOL is ON---------------------------------");


#turn vmap falloff off
lx("tool.set falloff.vertexMap off");

#remember the selection type.
if		( lxq( "select.typeFrom {vertex;polygon;item;edge} ?" ) ) { our $selectType = vertex; our @verts = lxq("query layerservice verts ? selected");}
elsif	( lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ) ) { our $selectType = edge; }
elsif	( lxq( "select.typeFrom {polygon;item;edge;vertex} ?" ) ) { our $selectType = polygon; }


#ARGS  (The only ARG used in this script is for making a plateau falloff.
if (@ARGV[0] eq "plateau")
{
	lxout("-Plateau is ON.");

	#create new variable if it doesn't exist.
	if (lxq("query scriptsysservice userValue.isdefined ? senePlateau") == 0){ lxout("-The senePlateau cvar doesn't exist yet so I'm creating one."); lx("user.defNew senePlateau integer"); }

	#bring the window up.
	lx("user.def senePlateau username {Falloff Polygons:}");
	lx("user.value senePlateau");
	our $plateauNum = lxq("user.value senePlateau ?");
}






#========================================
#========================================
#WEIGHTMAP SETUP
#========================================
#========================================
my @vmaps = lxq("query layerservice vmaps ?");
my $vmapName;
my $correctVmap = "none";

#check if the weightmap already exists.
foreach my $vmap (@vmaps)
{
	$vmapName = lxq("query layerservice vmap.name ? $vmap");
	if ($vmapName eq "seneWeight")
	{
		#lxout("The correct vmap is $vmap");
		$correctVmap = $vmap;
	}
}

#if the weightmap already exists, just select it.
if ($correctVmap ne "none")
{
	#lxout("The vmap already exists and so I'm selecting it.");
	lx("select.vertexMap seneWeight wght replace $vmap");
}
#if the weightmap doesn't exist, create a new one.
else
{
	#lxout("The Vmap doesn't exist so I'm creating a new one");
	lx("vertMap.new seneWeight wght");
}








#========================================
#========================================
#LOOP THE WEIGHTMAP APPLICATION
#========================================
#========================================
#convert the selection to verts
if ($selectType ne "vertex") { lx("select.convert vertex"); } else { lxout("-I'm skipping the vertex conversion");}

#loop----------------------------------------------------------------
my $loopNum = 1;
my $loopStop = 0;
lx("tool.set vertMap.setWeight on");
lx("tool.reset");

while ($loopStop == 0)
{
	#lxout("WEIGHTMAP LOOP NUM $loopNum");
	lx("tool.setAttr vertMap.setWeight weight [5*$loopNum]");  #5's a bad number.  It has a cap...  :(
	lx("tool.doApply");

	lx("select.contract");
	#popup("pause");
	$loopNum++;

	#plateau check!
	if ($plateauNum != "")
	{
		if ($loopNum > $plateauNum)
		{
			#popup("PLATEAU : ending the loop because it's hit the plateau limit");
			$loopStop = 1;
		}
	}


	#end the loop if there are no more verts
	if (lxq("select.count vertex ?") == 0)
	{
		lx("tool.set vertMap.setWeight off");
		$loopStop = 1;
	}
}






#========================================
#========================================
#CLEANUP
#========================================
#========================================
#SET SELECT TYPE BACK <><> TURN MOVE ON <><> TURN VMAP FALLOFF ON
lxout("-Remember, I just turned VERTEX MAP FALLOFF ON!");

#vertex mode selection setup
if ($selectType eq "vertex")
{
	foreach my $vert (@verts)
	{
		lx("select.element $mainlayer vertex add $vert");
	}
}
#edge + polygon mode selection setup
else
{
	lx("select.type $selectType");
	lxout("-setting selection to $selectType");
}

lx("tool.set xfrm.move on");
lx("tool.set falloff.vertexMap on");









#========================================
#========================================
#SUBROUTINES
#========================================
#========================================
sub popup() #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
