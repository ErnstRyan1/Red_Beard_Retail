#perl
#ver 1.0
#author : Seneca Menard
#This script looks at the selected masks in the shader tree and lets you perform a batch rename on them.

#note : the script doesn't work with "Matr: terrain\wasteland1\northern_highway\nh_sharp_cliffs_04"
#note : haven't hosted it to the X: server yet.

#=============================================================================================
#=============================================================================================
#batch material rename (uses selected masks in current scene)
#=============================================================================================
#=============================================================================================
#requires quick dialog sub
my $txLayerCount = lxq("query sceneservice txLayer.n ? all");
my $runCount = 0;
my $textToReplace;
my $textToReplaceWith;
my $newPtagName;
my $popupFail = 0;

for (my $i=0; $i<$txLayerCount; $i++){
	if ((lxq("query sceneservice txlayer.isSelected ? $i") == 1) && (lxq("query sceneservice txLayer.type ? $i") eq "mask")){
		my $ptag = lxq("query sceneservice channel.value ? ptag");

		if ($runCount == 0){
			$textToReplace = quickDialog("Text you wish to replace:",string,$ptag);
			$textToReplaceWith = quickDialog("Text you want it to have:",string,$textToReplace);
			$newPtagName = $ptag;
			$newPtagName =~ s/$textToReplace/$textToReplaceWith/gi;
			$runCount++;
			popup("OLD NAME : $ptag \nNEW NAME : $newPtagName \nDoes that look correct?");
		}else{
			$newPtagName = $ptag;
			$newPtagName =~ s/$textToReplace/$textToReplaceWith/gi;
		}

		if ($popupFail == 0){
			lx("!!poly.renameMaterial {$ptag} {$newPtagName}");
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


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POPUP SUB (modified so that it doesn't cancel the script.
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : popup("What I wanna print");

sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){$popupFail = 1;}
}

