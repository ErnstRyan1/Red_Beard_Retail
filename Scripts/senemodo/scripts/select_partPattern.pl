#perl
#ver 0.5
#author : Seneca Menard
#This script will ask you a name to type in and when you do, it will select all the polys in the active layers that match that search term.

#this script selects parts with a search term
my $searchTerm = quickDialog("Search term:",string,"","","");
my @fgLayers = lxq("query layerservice layers ? fg");
foreach my $layer (@fgLayers){
	my $layerName = lxq("query layerservice layer.name ? $layer");
	my @parts = lxq("query layerservice parts ? all  ");
	foreach my $part (@parts){
		my $partName = lxq("query layerservice part.name ? $part");
		if ($partName =~ /$searchTerm/){
			lx("select.polygon add part face {$partName}");
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

