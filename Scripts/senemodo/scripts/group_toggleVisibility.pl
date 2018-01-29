#perl
#This hides or shows the selected items and you use 0, 1, or toggle as the cvars.

if (@ARGV[0] =~ /toggle/i)	{	our $selMode = -1;			}
else						{	our $selMode = @ARGV[0];	}


my @items = lxq("query sceneservice selection ? locator");
lx("layer.setVisibility item:[$_] visible:[$selMode] recur:[0]") for @items;

my @deformers = lxq("query sceneservice selection ? genInfluence");
lx("deformer.enable {$_}") for @deformers;

my @lattices = lxq("query sceneservice selection ? deform.lattice");
lx("layer.setVisibility item:[$_] visible:[$selMode] recur:[0]") for @lattices;
