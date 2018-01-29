#perl
#ver 1.5
#author : Seneca Menard
#This script will take all the poly parts 1-100 and save them each out to individual files (and center them on the axis you choose)

#(2-11-10 feature) : the script now lets you skip missing parts
#(2-19-10 feature) : now checks out the files if needed.
#(11-2-10 fix) : fixed a syntax change for 501
#(6-26-11 feature) : prettied up dialog windows for 601

#script arguments
foreach my $arg (@ARGV){
	if ($arg =~ /exportLayers/i){	our $exportLayers = 1;	}
}

my $modoVer = lxq("query platformservice appversion ?");
if ($modoVer > 500){our $lwoType = "\$NLWO2";} else {our $lwoType = "\$LWO2";}
my $appendix = quickDialog("File appendix name:",string,"","","");

my $center = popupMultChoice("Center on which axis:","X;Y;Z;all;none",3);
while (($center !~ /x/i) && ($center !~ /y/i) && ($center !~ /z/i) && ($center !~ /all/i) && ($center !~ /none/i)){$center = quickDialog("You didn't properly pick one of these:\nCenter on which axis:\nX\nY\nZ\nall",string,"all","","");}
my $axisAlign = popupMultChoice("Align above or below an axis?","none;X+ (over X axis);X- (under X axis);Y+ (over Y axis);Y- (under Y axis);Z+ (over Z axis);Z+ (under Z axis)",0);

my $sceneIndex = lxq("query sceneservice scene.index ? current");
my $sceneFile = lxq("query sceneservice scene.file ? current");
my $mainlayer = lxq("query layerservice layers ? main");
my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
my $layerCount = lxq("query layerservice layer.n ? all");
my $polyCount = lxq("query layerservice poly.n ? visible");
my $textToRemove;
my $check = 0;


for (my $i=1; $i<100; $i++){
	if ($exportLayers == 1){
		my $layer = $i-1;
		if ($layer >= $layerCount){
			last;
			return;
		}
		my $layerID = lxq("query layerservice layer.id ? $i-1");
		lx("select.subItem {$layerID} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0") or die("I was unable to select the main layer");
	}else{
		lx("select.drop polygon");
		lx("select.polygon add part face $i");
		our @polySel = lxq("query layerservice polys ? selected");
		our $part = lxq("query layerservice poly.part ? $polySel[-1]");
	}

	if ( ($part != $i) && ($exportLayers != 1) ){
		lxout("$part <> skipping this round $i");
		next;
	}else{
		lx("select.copy");
		lx("scene.new");
		lx("select.paste");
		lx("vert.center $center");
		if ($axisAlign =~ /[xyz]/i){
			my $newMainLayer = lxq("query layerservice layers ? main");
			my @layerBounds = lxq("query layerservice layer.bounds ? $newMainLayer");
			my $axis = 0;
			my $side = 0;
			if		($axisAlign !~ /\+/){$side = 3;}
			if		($axisAlign =~ /y/i){$axis = 1;}
			elsif	($axisAlign =~ /z/i){$axis = 2;}
			my $moveAxis = $axis + $side;
			my $moveDist = -1 * @layerBounds[$moveAxis];

			lx("tool.set actr.auto on");
			lx("tool.set xfrm.move on");
			lx("tool.reset");
			if ($axis == 0)	{lx("tool.setAttr xfrm.move X {$moveDist}");}
			else			{lx("tool.setAttr xfrm.move X 0");}
			if ($axis == 1)	{lx("tool.setAttr xfrm.move Y {$moveDist}");}
			else			{lx("tool.setAttr xfrm.move Y 0");}
			if ($axis == 2)	{lx("tool.setAttr xfrm.move Z {$moveDist}");}
			else			{lx("tool.setAttr xfrm.move Z 0");}
			lx("tool.doApply");
			lx("tool.set xfrm.move off");
		}

		my $newSceneName = $sceneFile;
		$newSceneName =~ s/\.l[wx]o//i;
		my @words = split(/\\/, $newSceneName);

		if ($check == 0){$textToRemove = quickDialog("Delete any text? :\n@words[-1]",string,"","","");}
		if ($textToRemove ne ""){@words[-1] =~ s/$textToRemove//;}
		my $finalSceneName;
		for (my $i=0; $i<$#words; $i++){$finalSceneName .= @words[$i] . "\\";}
		my $count;
		if ($i < 10){$count = "0".$i;}else{$count = $i;}
		$finalSceneName .= @words[-1] . $appendix . "_$count.lwo";
		if ($check == 0){
			popup("Is this the correct filename to use? : $finalSceneName");
			$check = 1;
		}
		if (!-w $finalSceneName){system("p4 edit \"$finalSceneName\"");}
		lx("scene.saveAs {$finalSceneName} {$lwoType} false");
		lx("!!scene.close");
		if (lxq("query sceneservice scene.index ? current") != $sceneIndex){lx("scene.set $sceneIndex");}
		if ($exportLayers != 1){
			lx("select.subItem {$mainlayerID} set mesh;meshInst;camera;light;backdrop;groupLocator;locator;deform;locdeform 0 0") or die("I was unable to select the main layer");
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


##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#POPUP MULTIPLE CHOICE (ver 3) (forces return of your word choice because modo sometimes would return a number instead of word)
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
	
	my $answer = lxq("user.value seneTempDialog2 ?");
	if ($answer =~ /[^0-9]/){
		return($answer);
	}else{
		my @guiTextArray = split (/\;/, $_[1]);
		return($guiTextArray[$answer]);
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


