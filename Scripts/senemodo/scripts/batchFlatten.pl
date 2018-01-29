#perl
#AUTHOR: Seneca Menard
#version 1.01
#This script is to go thru each poly and merge it's verts.    Or go through each poly set and center it on Z.  Or go through each poly set and flatten it on it's local axis.
#(12-18-08 fix) : I went and removed the square brackets so that the numbers will always be read as metric units and also because my prior safety check would leave the unit system set to metric system if the script was canceled because changing that preference doesn't get undone if a script is cancelled.

my $mainlayer = lxq("query layerservice layers ? main");
my @polys = lxq("query layerservice polys ? selected");


foreach my $arg (@ARGV){
	if ($arg eq "merge")	{&vertMerge;		}
	if ($arg eq "center")	{&centerPolys;	}
	if ($arg eq "flatten")	{&flattenPolys;	}
}

#------------------------------------------------------
#VERT MERGE SUB
#------------------------------------------------------
sub vertMerge{
	my $dist = 2.5;
	my $i=0;
	foreach my $poly (@polys){
		lx("select.element $mainlayer polygon set ($poly-$i)");
		lx("tool.set vert.merge on");
		lx("tool.reset");
		lx("tool.setAttr vert.merge dist {$dist}");
		lx("tool.doApply");
		lx("tool.set vert.merge off");
		$i++;
	}
}

#------------------------------------------------------
#CENTER POLYS SUB
#------------------------------------------------------
sub centerPolys{
	my %totalPolys;
	foreach my $poly (@polys){
		$totalPolys{$poly} = 1;
	}

	while ((keys %totalPolys) > 1){
		my @currentPolys = (keys %totalPolys);
		lx("select.element $mainlayer polygon set @currentPolys[0]");
		lx("select.connect");
		my @connectedPolys = lxq("query layerservice polys ? selected");
		foreach my $poly (@connectedPolys){
			delete $totalPolys{$poly};
		}
		lx("vert.center z");
	}
}

#------------------------------------------------------
#FLATTEN POLYS SUB
#------------------------------------------------------
sub flattenPolys{
	my %totalPolys;
	foreach my $poly (@polys){
		$totalPolys{$poly} = 1;
	}

	while ((keys %totalPolys) > 1){
		my @currentPolys = (keys %totalPolys);
		lx("select.element $mainlayer polygon set @currentPolys[0]");
		lx("select.connect");
		my @connectedPolys = lxq("query layerservice polys ? selected");
		foreach my $poly (@connectedPolys){
			delete $totalPolys{$poly};
		}
		lx("workplane.fitSelect");
		lx("tool.set xfrm.stretch on");
		lx("tool.set actr.auto on");
		lx("tool.reset");
		lx("tool.setAttr center.auto cenX {0}");
		lx("tool.setAttr center.auto cenY {0}");
		lx("tool.setAttr center.auto cenZ {0}");
		lx("tool.setAttr xfrm.stretch factX {1}");
		lx("tool.setAttr xfrm.stretch factY {0}");
		lx("tool.setAttr xfrm.stretch factX {1}");
		lx("tool.doApply");
		lx("tool.set xfrm.stretch off");
	}
	lx("workplane.reset");
}
