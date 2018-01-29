#!perl
#Match Edge Length Script
#Dion Burgoyne
#Luxology
#Version 1.1 
#You can now put an argument of "define" which will ask you what length you would like the edges set to
#You can also put in bias 1 or bias 2 as an argument to make the edges scale from that vertex on the edge

#lxtrace();

$arg = $ARGV[0];
$layer = lxq("query layerservice layer.index ? main");
@edges = lxq("query layerservice selection ? edge");
$count = 0;
$argcount = 0;
$bias = 0;
@lengthlist;
$notdefined = 0;

lx("tool.set actr.select on");

if ($#edges < 1)
	{
	lx("dialog.setup info");
	lx("dialog.title {Not Enough Edges!}");
	lx("dialog.msg {Not enough edges selected!\nTool requires at least 2 edges!}");
	lx("dialog.open");
	return;
	}

foreach $edge(@edges)
	{
		@strsplit = split (/[^0-9]/, $edge);
		$repaired = "($strsplit[2],$strsplit[3])";
		$edgelength = lxq("query layerservice edge.length ? $repaired");
		push (@lengthlist, $edgelength);
	}

$lengthref = $lengthlist[$#edges];

foreach $arg(@ARGV)
	{
	$argcount++;
	if($arg eq "define")
		{
			lx("user.defNew lux_edge_length_set distance");
			lx("user.def lux_edge_length_set username {Edge Length}");
			lx("user.def lux_edge_length_set min 0");
			lx("user.value lux_edge_length_set");
			$lengthref = lxq("user.value lux_edge_length_set ?");
			$notdefined = 1;
		}
	if ($arg eq "bias")
		{
		$bias = $ARGV[$argcount];
		$bias = $bias+1;
		if($bias < 2)
			{
			$bias = 0;
			}
		if($bias > 3)
			{
			$bias = 0;
			}
		}
	}

lx("select.drop edge");

foreach $setedge(@edges)
	{
		$edgemath = ($lengthref/$lengthlist[$count]);
		if ($edgemath != 1)
			{
			
			@strsplit = split (/[^0-9]/, $setedge);
			$repaired = "($strsplit[2],$strsplit[3])";
			
			if($bias == 0)
				{
					@pos = lxq("query layerservice edge.pos ? $repaired");

					$cX = $pos[0];
					$cY = $pos[1];
					$cZ = $pos[2];
					
					@vector = lxq("query layerservice edge.vector ? $repaired");

					$aX = $vector[0];
					$aY = $vector[1];
					$aZ = $vector[2];

				}
			else
				{
					@pos = lxq("query layerservice vert.pos ? $strsplit[$bias]");
					
					$cX = $pos[0];
					$cY = $pos[1];
					$cZ = $pos[2];

					@vector = lxq("query layerservice vert.normal ? $strsplit[$bias]");

					$aX = $vector[0];
					$aY = $vector[1];
					$aZ = $vector[2];
				}
			
			@vector = lxq("query layerservice edge.vector ? $repaired");

			$aX = $vector[0];
			$aY = $vector[1];
			$aZ = $vector[2];
			
			lx("select.drop edge");
			
			@strsplit = split (/[^0-9]/, $setedge);
			lx("select.element $strsplit[1] edge add [$strsplit[2]] [$strsplit[3]]");
			lx("tool.set xfrm.stretch on");
			lx("tool.setAttr xfrm.stretch factX $edgemath");
			lx("tool.setAttr xfrm.stretch factZ $edgemath");
			lx("tool.setAttr xfrm.stretch factY $edgemath");
			
			lx("tool.setAttr center.select cenX $cX");
			lx("tool.setAttr center.select cenY $cY");
			lx("tool.setAttr center.select cenZ $cZ");

			lx("tool.setAttr axis.select axisX $aX");
			lx("tool.setAttr axis.select axisY $aY");
			lx("tool.setAttr axis.select axisZ $aZ");
			
			lx("tool.doApply");	
	
			lx("tool.deactivate xfrm.stretch");
			lx("tool.set xfrm.stretch off 0");
			lx("select.drop edge");
			}
		$count++;
	}
	
lx("tool.set actr.auto on");