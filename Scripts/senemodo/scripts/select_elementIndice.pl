#perl
#ver. 1.0
#author : Seneca Menard
#This script is to select elements by indice.

if		( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )	{	our $selMode = "vertex";	}
elsif	( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )	{	our $selMode = "edge";		}
elsif	( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )	{	our $selMode = "polygon";	}
else	{die("\\\\n.\\\\n[---------------------------------------------You're not in vert, edge, or polygon mode.--------------------------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}


my $mainlayer = lxq("query layerservice layers ? main");
my $elements = quickDialog("Type in $selMode(s) to select:",string,"","","");
my @elements = split (/[\s]/, $elements);
foreach my $element (@elements){
	if ($selMode eq "edge"){
		my @verts = split (/[^0-9]/, $element);
		lx("select.element [$mainlayer] edge add index:[@verts[0]] index2:[@verts[1]]");
	}else{
		lx("!!select.element $mainlayer $selMode add $element");
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