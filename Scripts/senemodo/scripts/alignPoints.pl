#!perl
#version 1.5 (modo202) #modded by Seneca.
my $mainlayer = lxq("query layerservice layers ? main");
my $selMode = vertex;

#SELECT MODE
if( lxq( "select.typeFrom {vertex;polygon;edge;item;ptag} ?") != 1){
	if( lxq( "select.typeFrom {edge;polygon;vertex;item;ptag} ?") == 1)		{	$selMode = edge;	lxout("edges");										}
	elsif( lxq( "select.typeFrom {polygon;edge;vertex;item;ptag} ?") == 1)	{	$selMode = polygon;	lxout("polys");										}
	else																	{	die("Can't run the script unless you're in VERT,EDGE,or POLY mode");	}
	lx("select.convert vertex");
}
my @verts = lxq("query layerservice verts ? selected");

#SYMMAXIS
my $symmAxis = lxq("select.symmetryState ?");
if		($symmAxis eq "x")	{	$symmAxis = 0;	}
elsif	($symmAxis eq "y")	{	$symmAxis = 1;	}
elsif	($symmAxis eq "z")	{	$symmAxis = 2;	}
else						{	$symmAxis = 3;	}

#SCRIPT AXIS
if ($ARGV[0] =~ /x/i)		{	our $axis = 0;	}
elsif ($ARGV[0] =~ /y/i)	{	our $axis = 1;	}
else 						{	our $axis = 2;	}

#EXECUTION
if (($symmAxis != 3) && ($symmAxis == $axis)){
	lxout("using symmetry");
	my @vertPos1 = lxq("query layerservice vert.pos ? @verts[-1]");
	my @vertPos2 = lxq("query layerservice vert.pos ? @verts[-2]");
	my $pos = abs(@vertPos1[$axis]);
	lx("vert.set $axis $pos");
}else{
	my @lastVertPos = lxq("query layerservice vert.pos ? @verts[-1]");
	lx("vert.set $axis @lastVertPos[$axis]");
}

#CLEANUP
if ($selMode ne "vertex"){
	lx("select.type $selMode");
}









sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
