#perl
#ver 1.0
#author : Seneca Menard

#This script is to cut the current render up into regions and render those regions out individually.  This script is built because sometimes when rendering very complex scenes, the memory required for the displacement goes through the roof and the render falls apart, while it's quite easily possible to render it out as chunks.

#SCRIPT ARGUMENTS :
# saveAll : this argument is to save out the individual images one by one.  If you don't turn this on, only one image will be saved.  The price is either A:be more safe with a bit of render slowdown or B:save on render time, but cut the risk that if modo crashes, you lose all the preexisting regions.


#setup
my $renderPercentage = quickDialog("Cut renders to what percent?",percent,25,1,100);
my $cuts = 1/$renderPercentage;
if ($cuts != int($cuts)){die("This percentage does not cut the render into even units and so I'm cancelling the script.");}
my $scene = lxq("query sceneservice scene ? current");
my $itemCount = lxq("query sceneservice item.n ? all");
my $renderID;

#script arguments
foreach my $arg (@ARGV){
	if ($arg =~ /saveAll/i)	{our $saveAll = 1;}
}

#file save dialog
lx("dialog.setup fileSave");
lx("dialog.fileType type:image");
lx("dialog.title {Images to save}");
lx("dialog.open");
my $filePath = lxq("dialog.result ?");
if ($filePath eq ""){die("The user cancelled the save dialog window, so the script is being cancelled.");}
my $ext = $filePath;
$filePath =~ s/\..*//;
$ext =~ s/.*\.//;

#find render output
for (my $i=0; $i<$itemCount; $i++){
	if (lxq("query sceneservice item.type ? $i") eq "polyRender"){
		$renderID = lxq("query sceneservice item.id ? $i");
		last;
	}
}

#turn render region on
if (lxq("item.channel region {?} set {$renderID}") == 0){lx("item.channel region {1} set {$renderID}");}

#render out frames
my $count = 1;
for (my $u=0; $u<$cuts; $u++){
	for (my $v=0; $v<$cuts; $v++){
		my $uMin = $renderPercentage * $u;
		my $uMax = $renderPercentage * $u + $renderPercentage;
		my $vMin = $renderPercentage * $v;
		my $vMax = $renderPercentage * $v + $renderPercentage;

		lx("item.channel regX0 {$uMin} set {$renderID}");
		lx("item.channel regX1 {$uMax} set {$renderID}");
		lx("item.channel regY0 {$vMin} set {$renderID}");
		lx("item.channel regY1 {$vMax} set {$renderID}");

		if ($saveAll == 1){
			my $imageName = $filePath . $count;
			lx("render.visible filename:{$imageName} format:{TGA}");
		}elsif ($count == ($cuts * $cuts)){
			my $imageName = $filePath;
			lx("render.visible filename:{$imageName} format:{TGA}");
		}else{
			lx("render.visible");
		}

		if (lxres != 0){	die("The user hit the cancel button");	}
		$count++;
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