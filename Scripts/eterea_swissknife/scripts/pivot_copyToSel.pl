#perl
#ver 1.2
#author : Seneca Menard

#This script is to copy the pivot position from one mesh to the others that are selected.
#note : it doesn't take item positions into account.  It assumes all items are at 0,0,0 for now.

#(12-18-08 fix) : I went and removed the square brackets so that the numbers will always be read as metric units and also because my prior safety check would leave the unit system set to metric system if the script was canceled because changing that preference doesn't get undone if a script is cancelled.

my $id;
my @selection = lxq("query sceneservice selection ? mesh");
my @layers = lxq("query layerservice layers ? selected");
my @pos = m3PivPos(get,@selection[0]);
my $name = lxq("query sceneservice item.name ? @selection[0]");

for (my $i=1; $i<@selection; $i++){
	lx("select.subItem {@selection[$i]} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0") or popup("@selection[$i] wtf???");
	my $layerName = lxq("query layerservice layer.name ? main");
	m3PivPos(set,@selection[$i],@pos);
}

#restore layer visibility
lx("select.subItem {@selection[$i]} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
for (my $i=1; $i<@selection; $i++){
	lx("select.subItem {@selection[$i]} add mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
}



#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#GET OR SET THE PIVOT POINT FOR AN OBJECT (ver 1.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : m3PivPos(set,lxq("query layerservice layer.id ? $mainlayer"),34,22.5,37);
#USAGE : my @pos = m3PivPos(get,lxq("query layerservice layer.id ? $mainlayer"));
sub m3PivPos{
	#find out if pivot "translation" exists and if not, create it.
	my $pivotID = lxq("query sceneservice item.xfrmPiv ? @_[1]");
	if ($pivotID eq ""){
		my $name = lxq("query sceneservice item.name ? @_[1]");
		lx("select.subItem {@_[1]} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0");
		lx("transform.add type:piv");
		$pivotID = lxq("query sceneservice item.xfrmPiv ? @_[1]");
	}
	#get the pivot point
	if (@_[0] eq "get"){
		my $name = lxq("query sceneservice item.name ? @_[1]");
		lxout("[->] Getting pivot position ($name) <> (@_[1]) <> ($pivotID)");
		my $xPos = lxq("item.channel pos.X [?] set [$pivotID]");
		my $yPos = lxq("item.channel pos.Y [?] set [$pivotID]");
		my $zPos = lxq("item.channel pos.Z [?] set [$pivotID]");
		return($xPos,$yPos,$zPos);
	}
	#set the pivot point
	elsif (@_[0] eq "set"){
		lxout("[->] Setting pivot position (@_[2],@_[3],@_[4])");
		lx("item.channel pos.X {@_[2]} set [$pivotID]");
		lx("item.channel pos.Y {@_[3]} set [$pivotID]");
		lx("item.channel pos.Z {@_[4]} set [$pivotID]");
	}else{
		popup("[m3PivPos sub] : You didn't tell me whether to GET or SET the pivot point!");
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
