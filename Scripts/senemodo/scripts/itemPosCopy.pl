#perl
#AUTHOR: Seneca Menard
#version 2.6

#this script is to copy the item position from the first selected item to all the others that are selected.

#SCRIPT ARGUMENTS :
# if no arguments are used, then it will perform a copy of the first selected item's position to all the others that are selected.
# "COPY" : if this argument is used, it'll copy the position of first selected item to the copy buffer.
# "paste" : if this argument is used, it'll paste the position from the copy buffer onto the selected items.
# "dontMov" : will skip the item move(s)
# "dontRot" : will skip the item rotate(s)
# "dontScl"	: will skip the item scale(s)
# "gui_whichXfrm" : will popup a gui and ask for only one transform to copy/paste.

#(12-22-11 feature) : you can now skip certain transforms with the "dontMov", "dontRot", and "dontScl" arguments
#(1-16-12 feature) : gui_whichXfrm : a popup gui to ask which transform type you want to copy instead of having to use cvars.

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SETUP
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
my $pi=3.1415926535897932384626433832795;
my @items = lxq("query sceneservice selection ? locator");
push(@items, lxq("query sceneservice selection ? mesh"));
push(@items, lxq("query sceneservice selection ? light"));
push(@items, lxq("query sceneservice selection ? camera"));

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#USER VALUES
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#create the sene_copyPastePos variable if it didn't already exist.
if (lxq("query scriptsysservice userValue.isdefined ? sene_copyPastePos") == 0)
{
	lxout("-The sene_copyPastePos cvar didn't exist so I just created one");
	lx( "user.defNew sene_copyPastePos type:[string] life:[config]");
	lx("user.value sene_copyPastePos [0,0,0,0,0,0,1,1,1,0]");
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#script options
foreach my $arg (@ARGV){
	if		($arg =~ /dontMov/i)		{	our $dontMov = 1;	}
	elsif	($arg =~ /dontRot/i)		{	our $dontRot = 1;	}
	elsif	($arg =~ /dontScl/i)		{	our $dontScl = 1;	}
	elsif	($arg =~ /gui_whichXfrm/i)	{	gui_whichXfrm();	}
}
#which editing process to run
if (@ARGV > 0){
	foreach my $arg (@ARGV){
		if 		($arg =~ /copy/i)		{	&copy;				}
		elsif	($arg =~ /paste/i)		{	&paste;				}
		else							{	&copyPaste;			}
	}
}else{
											&copyPaste;
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#MAIN ROUTINES
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

sub gui_whichXfrm{
	my $answer = popupMultChoice("Copy/Paste Only:","Move;Rotate;Scale",0);
	if		($answer eq "Move")		{	our $dontRot = 1;	our $dontScl = 1;	}
	elsif	($answer eq "Rotate")	{	our $dontMov = 1;	our $dontScl = 1;	}
	elsif	($answer == "Scale")	{	our $dontMov = 1;	our $dontRot = 1;	}
}

sub copy{
	my @pos = lxq("query sceneservice item.pos ? @items[0]");
	my @rot = lxq("query sceneservice item.rot ? @items[0]");
	my @scale = lxq("query sceneservice item.scale ? @items[0]");
	my $rotOrder = lxq("query sceneservice item.rotOrder ? @items[0]");
	@rot = ( (@rot[0]*180)/$pi , (@rot[1]*180)/$pi , (@rot[2]*180)/$pi);
	lxout("Copying this item position : \n    Item Pos = @pos\n    Item Rot = @rot\n    Item Sca = @scale\n    Item RotOrder = $rotOrder");

	lx("user.value sene_copyPastePos [@pos[0],@pos[1],@pos[2],@rot[0],@rot[1],@rot[2],@scale[0],@scale[1],@scale[2],$rotOrder]");
}


sub paste{
	my $pos = lxq("user.value sene_copyPastePos ?");
	my @pos = split(/,/, $pos);
	lxout("Pasting this Item Position :\n    Item Pos = @pos[0],@pos[1],@pos[2]\n    Item Rot = @pos[3],@pos[4],@pos[5]\n    Item Sca = @pos[6],@pos[6],@pos[7]\n    Item RotOrder = @pos[8]");

	move(@pos);
}


sub copyPaste{
	my @pos = lxq("query sceneservice item.pos ? @items[0]");
	my @rot = lxq("query sceneservice item.rot ? @items[0]");
	my @scale = lxq("query sceneservice item.scale ? @items[0]");
	my $rotOrder = lxq("query sceneservice item.rotOrder ? @items[0]");
	@rot = ( (@rot[0]*180)/$pi , (@rot[1]*180)/$pi , (@rot[2]*180)/$pi);

	my $name = lxq("query sceneservice item.name ? @items[0]");
	lxout("Copying and pasting the position from ($name) : \n    Item Pos = @pos\n    Item Rot = @rot\n    Item Sca = @scale\n    Item RotOrder = $rotOrder");

	move(@pos,@rot,@scale,$rotOrder);
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SUBROUTINES
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

#MOVE SUBROUTINE : (@pos,@rot,@scale)
sub move{
	lxout("dontMov = $dontMov");
	lxout("dontRot = $dontRot");
	lxout("dontScl = $dontScl");
	if ($dontMov != 1){
		lx("!!item.channel locator\$pos.X @_[0]");
		lx("!!item.channel locator\$pos.Y @_[1]");
		lx("!!item.channel locator\$pos.Z @_[2]");
	}

	if ($dontRot != 1){
		lx("!!item.channel locator\$rot.X @_[3]");
		lx("!!item.channel locator\$rot.Y @_[4]");
		lx("!!item.channel locator\$rot.Z @_[5]");
		lx("!!item.channel locator(rotation)\$order @_[9]");
	}

	if ($dontScl != 1){
		lx("!!item.channel locator\$scl.X @_[6]");
		lx("!!item.channel locator\$scl.Y @_[7]");
		lx("!!item.channel locator\$scl.Z @_[8]");
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
