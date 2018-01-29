#perl
#ver 0.7
#author : Seneca Menard
#this script is to select or deselect items based off of certain values they have. so for example you wanted to select all the hidden area lights, you could.

my $selOrDeselAnswer = popupMultChoice("Do you wish to select or deselect?","select;deselect",0);
if ($selOrDeselAnswer eq "select")	{	our $selMode = "add";		}
else								{	our $selMode = "remove";	}

my $typeString;
my $itemCount = lxq("query sceneservice item.n ? all");
my %itemTypes;
for (my $i=0; $i<$itemCount; $i++){
	my $id = lxq("query sceneservice item.id ? $i");
	push(@{$itemTypes{lxq("query sceneservice item.type ? $i")}},$id);
}

foreach my $key (sort keys %itemTypes){$typeString .= $key . ";";}
$typeString =~ s/\;$//;
my $typeAnswer = popupMultChoice("which item type to $selOrDeselAnswer:",$typeString,1);

my $randItemName = lxq("query sceneservice item.name ? {@{$itemTypes{$typeAnswer}}[0]}");
my $channelCount = lxq("query sceneservice channel.n ?");
my @channelList;
my $channelString;
my %channelNameInteger;

for (my $i=0; $i<$channelCount; $i++){
	my $name = lxq("query sceneservice channel.name ? $i");
	#my $type = lxq("query sceneservice channel.type ? $i");
	#lxout("channelName=$name channelType=$type");
	push(@channelList,$name);
	$channelNameInteger{$name} = $i;
}
@channelList = (sort @channelList);
for (my $i=0; $i<@channelList; $i++){
	$channelString .= $channelList[$i] . ";";
}
$channelString =~ s/\;$//;

my $chanAnswer = popupMultChoice("which channel type to query:",$channelString,1);
my $channelType = lxq("query sceneservice channel.type ? $channelNameInteger{$chanAnswer}");
my $channelValue = lxq("query sceneservice channel.value ? $channelNameInteger{$chanAnswer}");

my $mathSignAnswer = popupMultChoice("which math test to run:","=;>;<;>=;<=;",1);
my $mathValueAnswer = quickDialog("value",float,0,"","");

foreach my $id (@{$itemTypes{$typeAnswer}}){
	my $name = lxq("query sceneservice item.name ? {$id}");
	#my $channelCount = lxq("query sceneservice channel.n ? ");
	my $channelName = lxq("query sceneservice channel.name ? $channelNameInteger{$chanAnswer}");
	my $currentChannelValue = lxq("query sceneservice channel.value ? $channelNameInteger{$chanAnswer}");
	#my $channelType = lxq("query sceneservice channel.type ? $channelNameInteger{$chanAnswer}");

	if		($currentChannelValue eq "off")		{	$currentChannelValue = 0;	}
	elsif	($currentChannelValue eq "allOff")	{	$currentChannelValue = 0;	}
	elsif	($currentChannelValue eq "default")	{	$currentChannelValue = 1;	}

	#lxout("name=$name channelName=$channelName channelNum=$channelNameInteger{$chanAnswer} channelType=$channelType currentChannelValue=$currentChannelValue mathValueAnswer=$mathValueAnswer mathSignAnswer=$mathSignAnswer");
	if		($mathSignAnswer == 0){
		if ($currentChannelValue == $mathValueAnswer){	lx("select.item {$id} $selMode");	lxout("=");}
	}elsif	($mathSignAnswer == 1){
		if ($currentChannelValue > $mathValueAnswer){	lx("select.item {$id} $selMode");	lxout(">");}
	}elsif	($mathSignAnswer == 2){
		if ($currentChannelValue < $mathValueAnswer){	lx("select.item {$id} $selMode");	lxout("<");}
	}elsif	($mathSignAnswer == 3){
		if ($currentChannelValue >= $mathValueAnswer){	lx("select.item {$id} $selMode");	lxout(">=");}
	}elsif	($mathSignAnswer == 4){
		if ($currentChannelValue <= $mathValueAnswer){	lx("select.item {$id} $selMode");	lxout("<=");}
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

