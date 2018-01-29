#perl
#BY: Seneca Menard
#version 2.31 (I should make it so the rand part apply will apply a rand part per part-group so you can have 3 parts selected and give a new part name to all 3)
#This script is to apply a POLYGON PART if you're in POLY mode and a SELECTION SET if you're in EDGE or VERTEX mode.

#SCRIPT ARGUMENTS :
# swapNullChars = Enter this argument to have it remove all of these characters from the polygon part name to clean it up (){}[],.;:'"
# applyRandomPart = This will apply a randomly generated part name for you so you don't have to bother typing in anything if you use random part names anyways and are too lazy to type it in.

#(4-5-08 bugfix) : a small bugfix about spaces in the part names
#(5-7-09 feature) : applyRandomPart : This will apply a randomly generated part name for you so you don't have to bother typing in anything if you use random part names anyways and are too lazy to type it in.




#-----------------------------------------------------------------------
#SCRIPT ARGUMENTS
#-----------------------------------------------------------------------
foreach my $arg (@ARGV){
	if ($arg =~ /swapNullChars/i)	{our $swapNullChars = 1;}
	if ($arg =~ /applyRandomPart/i)	{our $applyRandomPart = 1;}
}


#-----------------------------------------------------------------------
#MAIN ROUTINE
#-----------------------------------------------------------------------
if( lxq( "select.typeFrom {polygon;item;edge;vertex} ?" ) ){
	if ($applyRandomPart == 1){
		srand;
		my $partName;
		my @alphabet = (0,1,2,3,4,5,6,7,8,9,0,"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z");
		for (my $i=0; $i<12; $i++){$partName .= @alphabet[rand(35)];}
		lx("poly.setPart {$partName}");
	}elsif ($swapNullChars == 1){
		my @selPolys = lxq("query layerservice selection ? poly");
		my @polyInfo = split (/[^0-9]/, @selPolys[0]);
		my $layerName = lxq("query layerservice layer.name ? @polyInfo[1]");
		my @tags = lxq("query layerservice poly.tags ? @polyInfo[2]");
		my @tagTypes = lxq("query layerservice poly.tagTypes ? @polyInfo[2]");
		my $initialPart;
		for (my $i=0; $i<@tagTypes; $i++){
			if (@tagTypes[$i] eq "PART"){
				$initialPart = @tags[$i];
				lxout("eh?");
				last;
			}
		}

		quickDialog("Part Name",string,$initialPart,"","") or die("User hit the CANCEL button");
		my $name = lxq("user.value seneTempDialog ?");
		swapNullChars($name);
		lx("poly.setPart {$name}");
	}else{
		lx("poly.setPart");
	}
}
else{
	if ($applyRandomPart == 1){
		srand;
		my $partName;
		my @alphabet = (0,1,2,3,4,5,6,7,8,9,0,"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z");
		for (my $i=0; $i<12; $i++){$partName .= @alphabet[rand(35)];}
		lx("select.editSet {$partName} add");
	}else{
		lx("select.editSet");
	}
}








#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SWAP NULL CHARACTERS FROM A STRING
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
# swapNullChars($word);
sub swapNullChars{
	srand;
	my @alphabet = (a..z,0..9);
	while ($blah == 0){@_[0] =~ s/\:/@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\;/@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\./@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/,/@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\\/@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\//@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\'/@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\"/@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\[/@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\]/@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\(/@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\)/@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\{/@alphabet[int(@alphabet*rand)]/ or last;}
	while ($blah == 0){@_[0] =~ s/\}/@alphabet[int(@alphabet*rand)]/ or last;}
	return @_[0];
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
#POPUP SUB
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

