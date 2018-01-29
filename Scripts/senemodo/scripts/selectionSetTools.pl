#perl
#ver 0.5
#author : Seneca Menard

#This script is for applying/removing selection sets

#script arguments
foreach my $arg (@ARGV){
	if		($arg eq "apply")		{	our $mode = 0; applySelSet();	}
	elsif	($arg eq "remove")		{	our $mode = 1; applySelSet();	}
	elsif	($arg eq "assignSet1")	{	assignSet(1);					}
	elsif	($arg eq "assignSet2")	{	assignSet(2);					}
	elsif	($arg eq "assignSet3")	{	assignSet(3);					}
	elsif	($arg eq "assignSet4")	{	assignSet(4);					}
	elsif	($arg eq "removeAll")	{	removeAll();					}
	else							{	our $miscArg = $arg;			}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SETUP USER VALUES
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
userValueTools(sen_selSetName1,string,config,"SelSet1","","","",xxx,xxx,"","name1");
userValueTools(sen_selSetName2,string,config,"SelSet2","","","",xxx,xxx,"","name2");
userValueTools(sen_selSetName3,string,config,"SelSet3","","","",xxx,xxx,"","name3");
userValueTools(sen_selSetName4,string,config,"SelSet4","","","",xxx,xxx,"","name4");


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#ASSIGN SET FROM USER VALUE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub assignSet{
	removeAll();
	
	my $selSet;
	if		($_[0] == 1){	$selSet = lxq("user.value sen_selSetName1 ?");	}
	elsif	($_[0] == 2){	$selSet = lxq("user.value sen_selSetName2 ?");	}
	elsif	($_[0] == 3){	$selSet = lxq("user.value sen_selSetName3 ?");	}
	elsif	($_[0] == 4){	$selSet = lxq("user.value sen_selSetName4 ?");	}
	
	lx("select.editSet {$selSet} add {}");
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#REMOVE ALL SELECTION SETS sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub removeAll{
	lxout("[->] : Removing all selection sets from the selected elements");
	my ($elems,$mode) = buildElemSelTable();
	my %selSetTable;
	foreach my $layer (keys %{$elems}){
		my $layerName = lxq("query layerservice layer.name ? $layer");
		foreach my $elem (@{$elems{$layer}}){
			my @selSets = lxq("query layerservice $mode.selSets ? $elem");
			$selSetTable{$_} = 1 for @selSets;
		}
	}
	
	foreach my $key (keys %selSetTable){
		if ($key ne ""){
			lxout("Removing \"$key\" selection set");
			lx("select.editSet {$key} remove {}");
		}
	}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#APPLY SELECTION SET subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub applySelSet{
	if ($miscArg eq "")	{	our $miscArg = quickDialog("Selection Set to add or remove:",string,"","","");	}
	if ($mode == 1)		{	lx("select.editSet {$miscArg} remove {}");										}
	else				{	lx("select.editSet {$miscArg} add");											}
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#BUILD ELEMENT SELECTION TABLE (return a table of each layer's selection)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my ($elems,$mode) = buildElemSelTable();  foreach my $elem (keys %{$elems}){do something};
#NOTE : returns a element mode string ("vert"|"edge"|"poly") and hash table pointer for all the selection
#NOTE : when querying edges, it by default returns a string list like this (23,68).
#ARG1 : "edgeArrays" : use this arg to get an edge list that returns vert array refs, instead of the normal strings with () characters.
#ARG2 : "vert" | "edge" | "poly" : use any of these args to force a specific selection mode because it normally uses whatever mode you're currently in.
sub buildElemSelTable{
	our %elems;
	my $selMode;

	if		(lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ))	{	$selMode = "vert";	}
	elsif	(lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ))	{	$selMode = "edge";	}
	elsif	(lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ))	{	$selMode = "poly";	}
	else{	die("You're not in vertex, edge, or polygon selection mode so I'm cancelling the script");	}
	
	#args
	foreach my $arg (@_){
		if 		($arg eq "vert")		{	$selMode = "vert";	}
		elsif	($arg eq "edge")		{	$selMode = "edge";	}
	 	elsif	($arg eq "poly")		{	$selMode = "poly";	}
		elsif	($arg eq "edgeArrays")	{	our $edgeMode = 1;	}
	}
	
	#build table
	my @elems = lxq("query layerservice selection ? $selMode");
	if ($selMode eq "edge"){
		if ($edgeMode == 1){
			foreach my $elem (@elems){
				my @data = split (/[^0-9]/, $elem);
				my @array = ($data[2],$data[3]);
				push(@{$elems{$data[1]}},\@array);
			}
		}else{
			foreach my $elem (@elems){
				my @data = split (/[^0-9]/, $elem);
				push(@{$elems{$data[1]}},"(".$data[2].",".$data[3].")");
			}
		}
	}else{
		foreach my $elem (@elems){
			my @data = split (/[^0-9]/, $elem);
			push(@{$elems{$data[1]}},$data[2]);
		}
	}
	
	return (\%elems,$selMode);
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
#SET UP THE USER VALUE OR VALIDATE IT   (no popups)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#userValueTools(name,type,life,username,list,listnames,argtype,min,max,action,value);
sub userValueTools{
	if (lxq("query scriptsysservice userValue.isdefined ? @_[0]") == 0){
		lxout("Setting up @_[0]--------------------------");
		lxout("Setting up @_[0]--------------------------");
		lxout("0=@_[0],1=@_[1],2=@_[2],3=@_[3],4=@_[4],5=@_[6],6=@_[6],7=@_[7],8=@_[8],9=@_[9],10=@_[10]");
		lxout("@_[0] didn't exist yet so I'm creating it.");
		lx( "user.defNew name:[@_[0]] type:[@_[1]] life:[@_[2]]");
		if (@_[3] ne "")	{	lxout("running user value setup 3");	lx("user.def [@_[0]] username [@_[3]]");	}
		if (@_[4] ne "")	{	lxout("running user value setup 4");	lx("user.def [@_[0]] list [@_[4]]");		}
		if (@_[5] ne "")	{	lxout("running user value setup 5");	lx("user.def [@_[0]] listnames [@_[5]]");	}
		if (@_[6] ne "")	{	lxout("running user value setup 6");	lx("user.def [@_[0]] argtype [@_[6]]");		}
		if (@_[7] ne "xxx")	{	lxout("running user value setup 7");	lx("user.def [@_[0]] min @_[7]");			}
		if (@_[8] ne "xxx")	{	lxout("running user value setup 8");	lx("user.def [@_[0]] max @_[8]");			}
		if (@_[9] ne "")	{	lxout("running user value setup 9");	lx("user.def [@_[0]] action [@_[9]]");		}
		if (@_[1] eq "string"){
			if (@_[10] eq ""){lxout("woah.  there's no value in the userVal sub!");							}		}
		elsif (@_[10] == ""){lxout("woah.  there's no value in the userVal sub!");									}
								lx("user.value [@_[0]] [@_[10]]");		lxout("running user value setup 10");
	}else{
		#STRING-------------
		if (@_[1] eq "string"){
			if (lxq("user.value @_[0] ?") eq ""){
				lxout("user value @_[0] was a blank string");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#BOOLEAN------------
		elsif (@_[1] eq "boolean"){

		}
		#LIST---------------
		elsif (@_[4] ne ""){
			if (lxq("user.value @_[0] ?") == -1){
				lxout("user value @_[0] was a blank list");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#ALL OTHER TYPES----
		elsif (lxq("user.value @_[0] ?") == ""){
			lxout("user value @_[0] was a blank number");
			lx("user.value [@_[0]] [@_[10]]");
		}
	}
}


