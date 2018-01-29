#perl
#AUTHOR: Seneca Menard
#version 1.2 (modo2)
#This script is to replace the END key.  (workplane.reset).  What it does is first save the current workplane to your modo.cfg and *THEN* resets the workplane.
#This is so you can then use this script to restore the workplane to the last used workplane whenever you want!!!

#- It doesn't save the workplane values if it's already "reset".
#- To reset the workplane, just run the script.
#- To bring the last custom workplane back, run the script with "restore" appended.
#- example:@{C:\Program Files\Luxology\modo\senescripts\workplane_reset_restore.pl}restore

#(12-18-08 fix) : I went and removed the square brackets so that the numbers will always be read as metric units and also because my prior safety check would leave the unit system set to metric system if the script was canceled because changing that preference doesn't get undone if a script is cancelled.


#------------------------------------------------------------------------------------------------------------
#STARTUP
#------------------------------------------------------------------------------------------------------------
my @storedWorkplane;

if (@ARGV[0] eq "restore")
{
	&restore;
}
else
{
	&save;
}


#------------------------------------------------------------------------------------------------------------
#SAVE THE WORKPLANE, THEN RESET
#------------------------------------------------------------------------------------------------------------
#CHECK TO SEE IF WORKPLANE IS ALREADY "RESET"
sub save
{
	if ((lxq ("workPlane.edit cenX:? ") eq 0) && (lxq ("workPlane.edit cenY:? ") eq 0) && (lxq ("workPlane.edit cenZ:? ") eq 0) && (lxq ("workPlane.edit rotX:? ") eq 0) && (lxq ("workPlane.edit rotY:? ") eq 0) && (lxq ("workPlane.edit rotZ:? ") eq 0))
	{
		#ends the script
		die("workplane NOT active");
	}
	else
	{
		#grab the current workplane
		lxout("workplane is active");
		@storedWorkplane[0] = lxq ("workPlane.edit cenX:? ");
		@storedWorkplane[1] = lxq ("workPlane.edit cenY:? ");
		@storedWorkplane[2] = lxq ("workPlane.edit cenZ:? ");
		@storedWorkplane[3] = lxq ("workPlane.edit rotX:? ");
		@storedWorkplane[4] = lxq ("workPlane.edit rotY:? ");
		@storedWorkplane[5] = lxq ("workPlane.edit rotZ:? ");

		#create the new userValues
		userDefCreate(senWorkplane0,senWorkplane0,float,1);
		userDefCreate(senWorkplane1,senWorkplane1,float,1);
		userDefCreate(senWorkplane2,senWorkplane2,float,1);
		userDefCreate(senWorkplane3,senWorkplane3,float,1);
		userDefCreate(senWorkplane4,senWorkplane4,float,1);
		userDefCreate(senWorkplane5,senWorkplane5,float,1);

		#put the current workplane values into the userValues
		lx("user.value senWorkplane0 @storedWorkplane[0]");
		lx("user.value senWorkplane1 @storedWorkplane[1]");
		lx("user.value senWorkplane2 @storedWorkplane[2]");
		lx("user.value senWorkplane3 @storedWorkplane[3]");
		lx("user.value senWorkplane4 @storedWorkplane[4]");
		lx("user.value senWorkplane5 @storedWorkplane[5]");

		#turn off the workplane
		lx("workplane.reset");
	}
}


#------------------------------------------------------------------------------------------------------------
#SET THE WORKPLANE TO THE SAVED WORKPLANE
#------------------------------------------------------------------------------------------------------------
sub restore
{
	lxout("USING RESTORE");
	@storedWorkplane[0] = lxq("user.value senWorkplane0 ?");
	@storedWorkplane[1] = lxq("user.value senWorkplane1 ?");
	@storedWorkplane[2] = lxq("user.value senWorkplane2 ?");
	@storedWorkplane[3] = lxq("user.value senWorkplane3 ?");
	@storedWorkplane[4] = lxq("user.value senWorkplane4 ?");
	@storedWorkplane[5] = lxq("user.value senWorkplane5 ?");

	lx("workPlane.edit {@storedWorkplane[0]} {@storedWorkplane[1]} {@storedWorkplane[2]} {@storedWorkplane[3]} {@storedWorkplane[4]} {@storedWorkplane[5]}");
}



#------------------------------------------------------------------------------------------------------------
#USER DEF CREATION SUB
#------------------------------------------------------------------------------------------------------------
sub userDefCreate{
	my $numberofArgs = $#_+1;
	my $name = 		@_[0];
	my $userName = 	@_[1];
	my $type = 			@_[2];
	my $value = 			@_[3];
	my $list = 			@_[4];
	if ($numberofArgs > 4){
		for (my $i=5; $i<$numberofArgs; $i++){
			$list = $list . ";" . @_[$i];
		}
	}
	#popup("name=$name <> username=$userName <> type=$type <> value=$value <> list=$list");

	#create the XXXX variable if it didn't already exist.
	if (lxq("query scriptsysservice userValue.isdefined ? $name") == 0)
	{
		lx("user.defNew $name $type");
		lx("user.def $name username $userName");
		if ($list =~ /;/)	{ lx("user.def $name list $list"); }
		lx("user.value {$name} {$value}");
	}
}


#------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}