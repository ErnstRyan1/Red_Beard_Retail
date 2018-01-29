#perl
#ver 1.3
#this script is to get around a modo bug...  The modo bug is this:  Say I'm in ACTR:ELEMENT and I turn on a custom tool preset that has an ACTR saved into it....  When I drop that tool preset, modo will not return me to the ACTR I was previously in, and will unfortunately set it to ACTR:NONE.  This script is to remember your ACTRs before you go into a preset and then restore it when you drop the preset.
#(10-22-08 fix) : it now works with material, pivot, and center selection modes.
#(9-30-10 fix) : now supports 501's snapping system.

my $modoVer = lxq("query platformservice appversion ?");
my $selCenter;
my $selAxis;





#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#USER VARIABLES
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#create the sene_selCenter variable if it didn't already exist.
if (lxq("query scriptsysservice userValue.isdefined ? sene_selCenter") == 0)
{
	lxout("-The sene_selCenter cvar didn't exist so I just created one");
	lx("user.defNew sene_selCenter string");
	lx("user.value sene_selCenter auto");
}

#create the sene_selAxis variable if it didn't already exist.
if (lxq("query scriptsysservice userValue.isdefined ? sene_selAxis") == 0)
{
	lxout("-The sene_selAxis cvar didn't exist so I just created one");
	lx("user.defNew sene_selAxis string");
	lx("user.value sene_selAxis auto");
}

#create the sene_selAxis variable if it didn't already exist.
if (lxq("query scriptsysservice userValue.isdefined ? sene_presetInUse") == 0)
{
	lxout("-The sene_presetInUse cvar didn't exist so I just created one");
	lx("user.defNew sene_presetInUse integer");
	lx("user.value sene_presetInUse 0");
}

#variables
my $currentCustom = lxq("user.value sene_presetInUse ?");







#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if ($arg eq "custom"){
		our $custom = 1;
	}elsif ($arg eq "snap:true"){
		our $snapTrue = 1;
	}elsif ($arg eq "selectNext"){
		lx("select.nextMode");
		if ($currentCustom == 1)		{	lx("user.value sene_presetInUse 0");	&restoreACTR;	}
		else							{	lx("user.value sene_presetInUse 0");	&rememberACTR;	}
	}elsif ($arg eq "deselectAll"){
		&deselectAll;
		if ($currentCustom == 1)		{	lx("user.value sene_presetInUse 0");	&restoreACTR;	}
		else							{	lx("user.value sene_presetInUse 0");	&rememberACTR;	}
	}else{

		#trying to hackishly-try to deselect the tool
		if   ( lxq( "select.typeFrom vertex;edge;polygon;ptag;item;pivot;center ?" ) )	{	lx("select.nextMode "); lx("select.type vertex");	}
		elsif( lxq( "select.typeFrom edge;polygon;ptag;item;pivot;center;vertex ?" ) )	{	lx("select.nextMode "); lx("select.type edge");		}
		elsif( lxq( "select.typeFrom polygon;ptag;item;pivot;center;vertex;edge ?" ) )	{	lx("select.nextMode "); lx("select.type polygon");	}
		elsif( lxq( "select.typeFrom ptag;item;pivot;center;vertex;edge;polygon ?" ) )	{	lx("select.nextMode "); lx("select.type ptag");		}
		elsif( lxq( "select.typeFrom item;pivot;center;vertex;edge;polygon;ptag ?" ) )	{	lx("select.nextMode "); lx("select.type item");		}
		elsif( lxq( "select.typeFrom pivot;center;vertex;edge;polygon;ptag;item ?" ) )	{	lx("select.nextMode "); lx("select.type pivot");	}
		elsif( lxq( "select.typeFrom center;vertex;edge;polygon;ptag;item;pivot ?" ) )	{	lx("select.nextMode "); lx("select.type center");	}

		if ($currentCustom == 1){
			lx("[->] The tool you're using now is custom");
			if ($custom  == 1)				{	lx("user.value sene_presetInUse 1");																			}
			else							{	lx("user.value sene_presetInUse 0");	&restoreACTR;															}
		}else{
			if ($custom  == 1)				{	lx("user.value sene_presetInUse 1");	&rememberACTR;	lx("[->] The tool you're about to turn on is custom");	}
			else							{	lx("user.value sene_presetInUse 0");	&rememberACTR;															}
		}

		lxout("[->] Turning this tool on : $arg");
		if ($modoVer > 500){
			if ($snapTrue == 1)	{	lx("tool.set preset:{$arg} snap:{true} mode:{on}");	}
			else				{	lx("tool.set {$arg} on");							}
		}else{
			lx("tool.set {$arg} on");
		}
	}
}








#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#DESELECT ALL SUBROUTINE
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub deselectAll{
	my $type;
	if( lxq( "select.typeFrom {edge;vertex;polygon;item} ?" ) ) {
	$type = "edge";
	} elsif( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) ) {
	$type = "vertex";
	} elsif( lxq( "select.typeFrom {polygon;vertex;edge;item} ?" ) ) {
	$type = "polygon";
	} elsif( lxq( "select.typeFrom {item;vertex;edge;polygon} ?" ) ) {
	$type = "item";
	}

	#drop elements
	if ($type ne "item"){
		lx( "select.drop edge" );
		lx( "select.drop polygon" );
		lx( "select.drop vertex" );
		lx( "select.drop ptag");
		lx( "select.nextMode" );
	}
	#drop items
	else{
		lx("select.drop item");
	}

	lx("select.nextMode");
	lx( "select.type {$type}" );
}







#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#RESTORE SELECTION SETTINGS
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub restoreACTR{
	lxout("[->] Restoring the last used ACTR");

	$selCenter = lxq("user.value sene_selCenter ?");
	$selAxis = lxq("user.value sene_selAxis ?");
	lxout("reading : selCenter=$selCenter <><> selAxis=$selAxis");

	lx("tool.set center.$selCenter on");
	lx("tool.set axis.$selAxis on");
}






#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#REMEMBER SELECTION SETTINGS (modded)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub rememberACTR{
	lxout("[->] Remembering the current ACTR");

	if( lxq( "tool.set actr.select ?") eq "on")				{	$selCenter = "select";			$selAxis = "select";		}
	elsif( lxq( "tool.set actr.selectauto ?") eq "on")		{	$selCenter = "select";			$selAxis = "auto";			}
	elsif( lxq( "tool.set actr.element ?") eq "on")			{	$selCenter = "element";		$selAxis = "element";		}
	elsif( lxq( "tool.set actr.screen ?") eq "on")			{	$selCenter = "auto";			$selAxis = "view";			}
	elsif( lxq( "tool.set actr.origin ?") eq "on")			{	$selCenter = "origin";			$selAxis = "origin";		}
	elsif( lxq( "tool.set actr.local ?") eq "on")				{	$selCenter = "local";			$selAxis = "local";		}
	elsif( lxq( "tool.set actr.pivot ?") eq "on")				{	$selCenter = "pivot";			$selAxis = "pivot";		}
	elsif( lxq( "tool.set actr.auto ?") eq "on")				{	$selCenter = "auto";			$selAxis = "auto";			}
	else
	{
		lxout("custom Action Center");
		if( lxq( "tool.set axis.select ?") eq "on")			{	 $selAxis = "select";			}
		elsif( lxq( "tool.set axis.element ?") eq "on")		{	 $selAxis = "element";			}
		elsif( lxq( "tool.set axis.view ?") eq "on")			{	 $selAxis = "view";			}
		elsif( lxq( "tool.set axis.origin ?") eq "on")		{	 $selAxis = "origin";			}
		elsif( lxq( "tool.set axis.local ?") eq "on")			{	 $selAxis = "local";			}
		elsif( lxq( "tool.set axis.pivot ?") eq "on")			{	 $selAxis = "pivot";			}
		else										{	 $selAxis = "auto";			}

		if( lxq( "tool.set center.select ?") eq "on")		{	 $selCenter = "select";		}
		elsif( lxq( "tool.set center.element ?") eq "on")	{	 $selCenter = "element";		}
		elsif( lxq( "tool.set center.view ?") eq "on")		{	 $selCenter = "view";			}
		elsif( lxq( "tool.set center.origin ?") eq "on")		{	 $selCenter = "origin";		}
		elsif( lxq( "tool.set center.local ?") eq "on")		{	 $selCenter = "local";			}
		elsif( lxq( "tool.set center.pivot ?") eq "on")		{	 $selCenter = "pivot";			}
		else										{	 $selCenter = "auto";			}
	}

	#write the cvars.
	lxout("writing : selCenter=$selCenter <><> selAxis=$selAxis");
	lx("user.value sene_selCenter $selCenter");
	lx("user.value sene_selAxis $selAxis");
}