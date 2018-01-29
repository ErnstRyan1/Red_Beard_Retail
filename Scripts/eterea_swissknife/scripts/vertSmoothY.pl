#perl
#ver 1.3
#author : Seneca Menard
#this quick hack of a script will smooth the position of your verts, but only in Y.  The number of smoothing iterations defaults to 65, but if you wish to override that, just run the script with a numeric argument and it will use that number for the smoothing iterations instead.

#script arguments :
# <any number> = this will set the smoothing amount to the number you typed.  example : @vertSmoothY.pl 100
# "gui" = if you want to be able to type in the smoothing number in a gui, you can do that as well.  example : @vertSmoothY.pl gui
# "x" or "y" or "z" = choose which axis upon the vert positions will be smoothed.

#setup
my $mainlayer = lxq("query layerservice layers ? main");
if(lxq("select.typeFrom edge;polygon;vertex ?") == 1)		{lx("select.convert vertex"); our $selMode = "edge";	}
elsif (lxq("select.typeFrom polygon;edge;vertex ?") == 1)	{lx("select.convert vertex"); our $selMode = "polygon";	}
my @verts = lxq("query layerservice verts ? selected");
if (@verts == 0){die("\\\\n.\\\\n[---------------------You don't have any elements selected, so I'm killing the script.------------------------]\\\\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \\\\n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\\\\n.\\\\n");}
my %vertTable;
my $iterations = 65;

#user value setup
userValueTools(seneVertSmoothY,integer,config,"Smoothing iterations:","","","",xxx,xxx,"",40);

#script arguments
foreach my $arg (@ARGV){
	if		($arg =~ /x/i)		{our $axis = "X";}
	elsif	($arg =~ /y/i)		{our $axis = "Y";}
	elsif	($arg =~ /z/i)		{our $axis = "Z";}
	elsif	($arg =~ /[0-9]/)	{$iterations = $arg;}
	elsif	($arg =~ /gui/i)	{$iterations = quickDialog("Smoothing iterations",integer,lxq("user.value seneVertSmoothY ?"),1,1000);  lx("user.value seneVertSmoothY $iterations");}
}

foreach my $vert (@verts){
	push(@{$vertTable{$vert}},lxq("query layerservice vert.pos ? $vert"));
}

lx("tool.set xfrm.smooth on");
lx("tool.reset");
lx("tool.setAttr xfrm.smooth iter $iterations");
lx("tool.doApply");
lx("tool.set xfrm.smooth off");

if		($axis eq "X")	{	foreach my $vert (@verts){lx("vert.move vertIndex:$vert posY:@{$vertTable{$vert}}[1] posZ:@{$vertTable{$vert}}[2]");}	}
elsif	($axis eq "Z")	{	foreach my $vert (@verts){lx("vert.move vertIndex:$vert posX:@{$vertTable{$vert}}[0] posY:@{$vertTable{$vert}}[1]");}	}
else					{	foreach my $vert (@verts){lx("vert.move vertIndex:$vert posX:@{$vertTable{$vert}}[0] posZ:@{$vertTable{$vert}}[2]");}	}

#cleanup
if ($selMode ne ""){lx("select.type $selMode");}






#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {@_[0]}");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 0){
			lxout("-The seneTempDialog cvar didn't exist so I just created one");
			lx("user.defNew name:[seneTempDialog] life:[temporary]");
		}
		lx("user.def seneTempDialog username [@_[0]]");
		lx("user.def seneTempDialog type [@_[1]]");
		if ((@_[3] != "") && (@_[4] != "")){
			lx("user.def seneTempDialog min [@_[3]]");
			lx("user.def seneTempDialog max [@_[4]]");
		}
		lx("user.value seneTempDialog [@_[2]]");
		lx("user.value seneTempDialog ?");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
	}
}


#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT   (no popups)
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

