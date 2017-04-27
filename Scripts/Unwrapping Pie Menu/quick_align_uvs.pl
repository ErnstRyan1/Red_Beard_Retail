#perl

# Quick Align UVs
# Version 1.02
# Author: James O'Hare - http://www.hull-breach.com/Talon

# It's a script that will align the UV island(s) of 1
# selected UV edge or any 2 selected UV verts with the nearest axis*

# It's a companion for modo's default "Orient UVs" tool, which isn't
# always perfect, especially on organic shapes.

# Instructions;
# - Ensure you are in the UV viewport.
# - Select the edge or any two vertices you want to align their islands to.
# - Run the script.

#*If you only want to align only the selected verts or edge
# (i.e. not their entire island) then add the argument "element" to the shortcut.
# e.g. @quickAlignUVs.pl element

# Update (v1.02);
# You can now align only the selected polygons.
# Simply have the polygons selected and then run the script in vertex or edge mode as normal.
# If you'd prefer the script to leave the polgyons alone (if you want to just keep your seletion, for example),
# add the argument "onlypolys" to the shortcut.
# e.g. @quickAlignUVs.pl onlypolys
#
# Also works across multiple selected layers now, too.
# There is a bug in modo that means if you select an edge to align to that has a connected edge and it's not
# in the main foreground layer, then it will break. Sorry, but there's no workaround for this I can see.

# Thanks to Seneca Menard and Kim DongJoo for their excellent script examples.

$mainLayer = lxq("query layerservice layer.id ? main");

# Ensure UV viewport is the active one.
$viewport = lxq("query view3dservice view.type ? selected");
if ($viewport eq "UV2D") {

	if (lxq("select.typeFrom {edge;polygon;item;vertex} ?")) {
		if (lxq("query layerservice edge.N ? selected") == 1) {
			lx("select.convert vertex");
			lx("select.drop edge");
			lx("select.typeFrom vertex;edge;polygon;item;pivot;center;ptag 1");
			$valid = "edge";
		}
	}
	elsif (lxq("select.typeFrom {vertex;edge;polygon;item} ?"))
	{
			# There's no real easy validation of how many verts you have selected
			# as one vertex could be many vertices in the UV map. Just use your
			# common sense and, you'll be fine.
			# Seem to have to drop edges here, otherwise it gets confused when determining the centre to rotate around.
			# Will look for a better fix later.
			#lx("select.drop edge");
			$valid = "vertex";
	}


	if (($valid eq "vertex") || ($valid eq "edge")) {
	
		# Run through all the foreground layers and check each for selected vertices. Then add them to a big array of UV positions.

		@activeLayers = lxq("query layerservice layers ? fg");
		foreach $layer (@activeLayers) {
			$layerID = lxq("query layerservice layer.id ? $layer");
			push(@activeLayerIDs, $layerID);

			@selectedPolys = lxq("query layerservice polys ? selected");
			if (@selectedPolys > 0) {
				lx("select.typeFrom polygon;edge;vertex;item;pivot;center;ptag 1");
				$polys = "true";
				lx("select.editSet quickAlignUVs_polySelection add");
				lx("select.typeFrom vertex;edge;polygon;item;pivot;center;ptag 1");
			}
			@selectedUVs = lxq("query layerservice uvs ? selected");
			foreach $UVVert (@selectedUVs) {
				@UVVertPos = lxq("query layerservice uv.pos ? $UVVert");
				push(@UVVertList, @UVVertPos);
			}
		}
		
		# Pull the first set of UV coords as our first vertex.

		push(@UVPosList1, @UVVertList[0]);
		push(@UVPosList1, @UVVertList[1]);
		
		# Search for a second vertex by comparing the rest of the verts positions against the first until we find a differing set.
		
		$i = "2";
		foreach $UVVert (@UVVertList) {
			@UVPosListTemp[0] = @UVVertList[$i];
			@UVPosListTemp[1] = @UVVertList[$i+1];
			if ((@UVPosListTemp[0] != @UVPosList1[0]) || (@UVPosListTemp[1] != @UVPosList1[1])) {
				#lxout("Pair found!");
				@UVPosList2 = @UVPosListTemp;
				last;
			}
			#else
			#{
			#	lxout("No pair found!");
			#}
			$i += 2;
		}

		if (@UVPosList2[0]) {

			# Get the difference between the two coords' U and V then use trig to work out the angle they're offset to.
			$diffU = @UVPosList1[0] - @UVPosList2[0];
			$diffV = @UVPosList1[1] - @UVPosList2[1];

			# Get the average position of the two verts to use as the action centre.
			$centreU = (@UVPosList1[0] + @UVPosList2[0]) / 2;
			$centreV = (@UVPosList1[1] + @UVPosList2[1]) / 2;
			
			# Trig stuff from Seneca's script example.
			$angle = atan2($diffU,$diffV);
			$pi = 4 * atan2(1, 1);
			$angle = ($angle*180)/$pi;
			
			# Fix angle needs to be the shallowest angle to the nearest UV axis.
			# There's probably a far more efficient way to work this out.
			if (($angle == 0) || ($angle == 90) || ($angle == -90) || ($angle == -180)) {
			#	lxout("Angle is aligned already.");
			}
			elsif (($angle > 0) && ($angle < 45)) {
				$fixangle = $angle * -1;
			#	lxout("Angle is 0 & 45: ".$angle);
			}
			elsif ($angle == 45) {
				$fixangle = -45;
			#	lxout("Angle is 45: ".$angle);
			}
			elsif (($angle > 45) && ($angle < 90)) {
				$fixangle = 90 - $angle;
			#	lxout("Angle is 45 & 90: ".$angle);
			}
			elsif (($angle > 90) && ($angle < 135)) {
				$fixangle = ($angle - 90) * -1;
			#	lxout("Angle is 90 & 135: ".$angle);
			}
			elsif ($angle == 135) {
				$fixangle = 45;
			#	lxout("Angle is 135: ".$angle);
			}
			elsif (($angle > 135) && ($angle < 180)) {
				$fixangle = 180 - $angle;
			#	lxout("Angle is 135 & 180: ".$angle);
			}
			elsif (($angle < 0) && ($angle > -45)) {
				$fixangle = $angle * -1;
			#	lxout("Angle is 0 & -45: ".$angle);
			}
			elsif ($angle == -45) {
				$fixangle = 45;
			#	lxout("Angle is -45: ".$angle);
			}
			elsif (($angle < -45) && ($angle > -90)) {
				$fixangle = -90 + ($angle * -1);
			#	lxout("Angle is -45 & -90: ".$angle);
			}
			elsif (($angle < -90) && ($angle > -135)) {
				$fixangle = ($angle + 90) * -1;
			#	lxout("Angle is -90 & -135: ".$angle);
			}
			elsif ($angle == -135) {
				$fixangle = -45;
			#	lxout("Angle is -135: ".$angle);
			}
			elsif (($angle < -135) && ($angle > -180)) {
				$fixangle = -180 + ($angle * -1);
			#	lxout("Angle is -135 & -180: ".$angle);
			}
			#else
			#{
			#	lxout("Angle is : ".$angle);
			#	lxout("But isn't getting caught.");
			#}
			
			if ($fixangle) {
				$fixangle = $fixangle * -1;
			#	lxout("Fixangle: ".$fixangle);
				if (@ARGV[0] ne "element") {
					lx("select.vertexConnect uv");
				}
				
				# Have we got any polygons selected on any layers? Then select them to rotate those instead...
				# ...assuming we're told to and we're not only aligning the element.
				if (($polys eq "true") && (@ARGV[0] eq "onlypolys") && (@ARGV[0] ne "element")) {
					lx("select.typeFrom polygon;edge;vertex;item;pivot;center;ptag 1");
					lx("select.useSet quickAlignUVs_polySelection select");
				}
				
				lx("tool.set Transform on");
				lx("tool.set actr.auto on 0");
				lx("tool.setAttr center.auto cenU ".$centreU);
				lx("tool.setAttr center.auto cenV ".$centreV);
				lx("tool.setAttr xfrm.transform TX 0.0");
				lx("tool.setAttr xfrm.transform TY 0.0");
				lx("tool.setAttr xfrm.transform TZ 0.0");
				lx("tool.setAttr xfrm.transform RX 0.0");
				lx("tool.setAttr xfrm.transform RY 0.0");
				lx("tool.setAttr xfrm.transform RZ ".$fixangle);
				lx("tool.setAttr xfrm.transform SX 1.0");
				lx("tool.setAttr xfrm.transform SY 1.0");
				lx("tool.setAttr xfrm.transform SZ 1.0");
				lx("tool.doApply");
				
				lx("select.typeFrom polygon;edge;vertex;item;pivot;center;ptag 1");
				lx("select.editSet quickAlignUVs_polySelection remove");
			}
			else
			{
				lxout("For some reason, I can't resolve an angle.");
			}

		}
		else
		{
			lxout("Couldn't get a second UV coord, looks like you've only got one UV vert selected.");
		}

		lx("select.drop vertex");
		
		# Can't easily restore the original UV selection, sadly, so I'm defaulting to just dropping the selection altogether.
		lx("select.drop ".$valid);
		
	}
	else
	{
		lxout("Please select only one edge.");
	}
}

