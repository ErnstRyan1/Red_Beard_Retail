#perl

#Chris_Hague has provided this script as is, with no guarantee that it actually does anything useful

#Define some variables

my $Parent = 1;
my @wPos;
my $Loc;
my $meshlayer = lxq("query layerservice layers ? main");
my $mesh = lxq("query layerservice layer.id ? $meshlayer");
my @verts = lxq("query layerservice verts ? selected");
lx("select.type item");

#Create a couple of user channels for naming and display size

lx("!user.defNew HiArchName type:string life:momentary");
lx("!user.def HiArchName username {Joint Hierarchy Name}");
lx("!user.value HiArchName Skeleton");
lxeval("?user.value HiArchName");
my $JName = lxq("user.value HiArchName ?");
lx("!user.defNew HiArchDispSize type:float life:momentary");
lx("!user.def HiArchDispSize username {Joint Display Size}");
lx("!user.value HiArchDispSize 0");
my $JSize = lxq("user.value HiArchDispSize ?");

#Cycle through the selected vertices and create joints

foreach my $verts(@verts)
{
@wPos = lxq("query layerservice vert.wpos ? $verts");
lxout("@wPos");
lx("item.create locator"); 
lx("item.setPosition {$wPos[0]} {$wPos[1]} {$wPos[2]} world");
lx("item.name {$JName}");
lx("item.channel drawShape custom");
lx("item.channel isSolid false");
lx("item.channel isShape sphere");
lx("item.channel isStyle replace");
lx("item.channel isRadius $JSize");
lx("item.channel link custom");
lx("item.channel lsShape rhombus");
lx("item.channel lsSolid false");
$Loc = lxq("query sceneservice selection ? locator");
if ($Parent ne "1")
{
lx("select.item $Parent add");
lx("item.parent inPlace:1");
}
$Parent = $Loc;
}
lx("select.type vertex");