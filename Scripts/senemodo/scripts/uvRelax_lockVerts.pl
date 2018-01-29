#perl
#ver 1.0
#author : Seneca Menard
#This script is for use with the UV relax tool.  It's for when you want to do a relax where 90% of the uvs are supposed to be locked, but you don't want to spend that much time manually clicking on every uv vert one by one to lock them.  So to get around that, what you do is select your polys, select your verts (I usually just convert the selection to verts from polys and then deselect the 3 or so verts that I *DON'T* want locked) and then run the script and it'll lock all the verts that were selected nd turn on the relax tool.


#apply selection set to verts
my $mainlayer = lxq("query layerservice layers ? main");
my @verts = lxq("query layerservice verts ? selected");
my @polys = lxq("query layerservice polys ? selected");
if ((@verts == 0) && (@polys == 0)){die("This script needs both some polys selectd, so it knows what to relax, and some verts selected, so it knows what to lock");}
lx("select.type polygon");
lx("select.convert vertex");
my @allVerts = lxq("query layerservice verts ? selected");
lx("select.editSet {UV Constraints} add");
popup("add");
lx("select.drop vertex");
my @vertsToDeselect = removeListFromArray(\@allVerts,\@verts);
lx("select.element $mainlayer vertex add $_") for @vertsToDeselect;
lx("select.editSet {UV Constraints} remove");
popup("remove");

#turn on the relax tool
lx("select.type polygon");
lx("tool.set uv.relax on");
lx("tool.reset");
lx("tool.attr uv.relax mode unwrap");


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#REMOVE ARRAY2 FROM ARRAY1 SUBROUTINE v1.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @newArray = removeListFromArray(\@full_list,\@small_list);
sub removeListFromArray{
	my @fullList = @{$_[0]};
	for (my $i=0; $i<@{$_[1]}; $i++){
		for (my $u=0; $u<@fullList; $u++){
			if ($fullList[$u] eq ${$_[1]}[$i]){
				splice(@fullList, $u,1);
				last;
			}
		}
	}
	return @fullList;
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#POPUP SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : popup("What I wanna print");
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}