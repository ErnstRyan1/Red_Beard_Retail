#perl
#ver 1.0
#author : Seneca Menard
#This script is for changing subd levels of subds and/or psubs.  It works with the subpatch_keepsel.pl's "user.value subPatch_keepSel_typeFlip ?" option so it knows whether you want it to default to subds or psubs.

#SCRIPT ARGUMENTS :
# "minus"		:	Type this argument if you want it to decrease levels, not increase.
# "flipModes"	:	Type this argument if you want it to work with psubs instead of subds or vice versa.
# "bothModes"	:	Type this argument if you want the updates to work with both subd mode and psub mode at the same time.


my $currSubdivision;
my $subdType = 1;
my $mult = 1;
my $bothModes = 0;

if (lxq("user.value subPatch_keepSel_typeFlip ?") == 1)	{	$subdType *= -1;	}

foreach my $arg (@ARGV){
	if		($arg =~ /minus/i)		{	$mult = -1;			}
	elsif	($arg =~ /flipModes/i)	{	$subdType *= -1;	}
	elsif	($arg =~ /bothModes/i)	{	$bothModes = 1;		}
}

if ($subdType == 1)	{	$subdType = "mesh.patchSubdiv";	$renderType = "mesh.renderSubdiv";		}
else				{	$subdType = "mesh.psubSubdiv";	$renderType = "mesh.psubRenderSubdiv";	}

$currSubdivision = lxq("$subdType level:?");
$currSubdivision += $mult;
if		($currSubdivision > 100)	{	$currSubdivision = 100;	}
elsif	($currSubdivision < 1)		{	$currSubdivision = 1;	}

if ($bothModes == 1){
	lx("mesh.patchSubdiv {$currSubdivision}");
	lx("mesh.psubSubdiv {$currSubdivision}");
	lx("mesh.psubRenderSubdiv {$currSubdivision}");
	lx("mesh.renderSubdiv {$currSubdivision}");
}else{
	lx("$subdType {$currSubdivision}");
	lx("$renderType {$currSubdivision}");
}
