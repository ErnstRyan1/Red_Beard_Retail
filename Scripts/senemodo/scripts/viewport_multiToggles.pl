#perl
#ver 1.5
#author : Seneca Menard

#This script will toggle the viewport display properties in all the viewports.

#(2-6-12 bugfix) : syntax changed in 501 so it's been updated.

my $modoVer = lxq("query platformservice appversion ?");

userValueTools(sen_VP_Cameras,boolean,config,"Cameras:","","","",xxx,xxx,"\@viewport_multiToggles.pl showCameras","");
userValueTools(sen_VP_Lights,boolean,config,"Lights:","","","",xxx,xxx,"\@viewport_multiToggles.pl showLights","");
userValueTools(sen_VP_Indices,boolean,config,"Indices:","","","",xxx,xxx,"\@viewport_multiToggles.pl showIndices","");
userValueTools(sen_VP_Backdrop,boolean,config,"Backdrop:","","","",xxx,xxx,"\@viewport_multiToggles.pl showBackdrop","");
userValueTools(sen_VP_TXLocators,boolean,config,"TX Locators:","","","",xxx,xxx,"\@viewport_multiToggles.pl showTexLocators","");
userValueTools(sen_VP_Deformers,boolean,config,"Deformers:","","","",xxx,xxx,"\@viewport_multiToggles.pl deformers","");

#gather arguments
foreach my $arg (@ARGV){
	our $argument = $arg;
	if 		($arg eq "showCameras")		{	our $value = lxq("user.value sen_VP_Cameras ?");	}
	elsif	($arg eq "showLights")		{	our $value = lxq("user.value sen_VP_Lights ?");		}
	elsif	($arg eq "showIndices")		{	our $value = lxq("user.value sen_VP_Indices ?");	}
	elsif	($arg eq "showBackdrop")	{	our $value = lxq("user.value sen_VP_Backdrop ?");	}
	elsif	($arg eq "showTexLocators")	{	our $value = lxq("user.value sen_VP_TXLocators ?");	}
	elsif	($arg eq "deformers")		{	our $value = lxq("user.value sen_VP_Deformers ?");	}
	else								{	return;												}
}

#cvars changed in 501, so updating.
my %argTranslate501;
	$argTranslate501{"showCameras"} = 		"view3d.showCameras";
	$argTranslate501{"showLights"} = 		"view3d.showLights";
	$argTranslate501{"showIndices"} = 		"view3d.showVertexIndices";
	$argTranslate501{"showBackdrop"} = 		"view3d.showBackdrop";
	$argTranslate501{"showTexLocators"} = 	"view3d.showTextureLocators";
	$argTranslate501{"deformers"} = 		"view3d.enableDeformers";
if ($modoVer > 500){
	$argument = $argTranslate501{$argument} . " {" . $value . "}";
}else{
	$argument = "viewport.3dView " . $argument . ":{" . $value . "}";
}

#apply changes to viewports
my $layouts = lxq("layout.count ?");
for (my $i=0; $i<$layouts; $i++){
	lx("!!select.viewport viewport:[0] frame:[$i]");
	my $frames = lxq("viewport.count ?");
	for (my $u=0; $u<$frames; $u++){
		lx("!!select.viewport viewport:[$u] frame:[$i]");
		my $type = lxq("viewport.type ?");
		if ($type eq "3Dmodel"){
			lx("$argument");
		}
	}
}


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT  #modded
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}

