#perl

# rebuildCurve.pl by Chris Hague
# Shared here: http://forums.luxology.com/topic.aspx?f=37&t=66803
# Rebuild the selected curve with the user amount of CVs (horrible hack)

lx("select.copy");
lx("item.create mesh");
lx("select.paste");

lx("select.itemType cmMatrixCompose");
my @ExCMs = lxq("query sceneservice selection ? cmMatrixCompose");

if( !lxq( "query scriptsysservice userValue.isDefined ? SplineVERTS" ) ) 
{
lx("!user.defNew SplineVERTS type:integer life:momentary");
lx("!user.def SplineVERTS username {Number of Vertices}");
}
lx("user.value SplineVERTS 3");
lxeval("?user.value SplineVERTS");
my $nControls = lxq("user.value SplineVERTS ?");
$nControls = ($nControls - 1);
my $Perc = (1 / $nControls);
my $PercVal = 1;

my $SourceC = lxq("query layerservice layer.id ? main");

my @VertPos;
my @LCoords;
my $TempLOC;
my $TempMOD;
my @Coords;

while ($nControls > -1)
{
lx("select.drop item");
lx("item.create locator");
$TempLOC = lxq("query sceneservice selection ? locator");
lx("select.item $SourceC add");
lx("constraintCurve path both");
$TempMOD = lxq("query sceneservice selection ? cmPathConstraint");
lx("item.channel percent $PercVal");
@LCoords = lxq("query sceneservice item.worldPos ? $TempLOC");
push (@VertPos, @LCoords);
lx("select.item $TempLOC set");
lx("!!item.delete");
lx("select.item $TempMOD set");
lx("!!item.delete");
$PercVal = ($PercVal - $Perc);
$nControls = ($nControls - 1);
}


my $VNum = 1;
lx("item.create mesh");
lx("item.name {Rebuilt Curve}");

#Create vertices for the target curve

#Rounding each value

foreach my $VertPos(@VertPos)
{
$VertPos = sprintf("%.3f", $VertPos);
}

my $nPoints = scalar (@VertPos);
lx("tool.set prim.curve on");
lx("tool.setAttr prim.curve mode add");

while ($nPoints > 1)
{
@Coords = splice(@VertPos, 0, 3);
lx("tool.setAttr prim.curve number $VNum");
lx("tool.setAttr prim.curve ptX $Coords[0]");
lx("tool.setAttr prim.curve ptY $Coords[1]");
lx("tool.setAttr prim.curve ptZ $Coords[2]");
lx("tool.noChange");
$VNum = ($VNum + 1);
$nPoints = scalar (@VertPos);
}
lx("tool.doApply");
lx("escape");
lx("escape");

##Cleanup

lx("select.item $SourceC set");
lx("item.delete");
lx("select.itemType cmMatrixCompose");
foreach my $ExCMs(@ExCMs)
{
lx("select.item $ExCMs remove");
}
lx("item.delete");