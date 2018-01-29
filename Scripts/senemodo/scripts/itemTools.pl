#perl
#ver 0.62
#author : Seneca Menard

#setItemPosToVert : sets selected items' positions to be the avg position of the selected verts.  To set pos in only X,Y,Z, use those args.
#selectNewestByType : selects the newest item of a certain type, sorted by creation date.  The type is the arg.
#selectAllGradValues : if you have 20 grads selected, and want to select all the keys, run this.  (you'll need the "rgb" arg if you want to sel rgb instead of value.)
#moveScreen : moves selected items forwards or backwards in world space or screen space.  args=(forward,backward,large,small,worldAxis)
#rectifyItemXfrms : will go through all items and give them transforms, and on meshInstances, it will give them unique transforms so you won't get inadvertent transforms occurring in the future because of the stupid modo feature that creates transform links from meshes to their instances.
#selSiblingsSameType : whatever items you have selected, it will select all sibling items of same type
#parentToGroup : will parent selected items to a preexisting group of choice
#flipScale : flips scale values of selected items with axis cvar.
#moveToLine : places the selected meshes or meshInstances in a row in one dimension. it doesn't change the other 2 dimensions.  Handy if you want to essily see all your meshes at once and they're normally all at 0,0,0
#selSamePos : will select all items that have the same position as others. (but will leave out the original items from the selection)
#transferWPToItemPos : say you have some polys floating in space and you want to give it a symmetrical intance, but can't because the polys aren't along the origin.  this script is for doing exactly that.  set the workplane up how you'd want the geometry positioned and then run this script and it'll move/rotate the geometry to that origin and then give it item transforms to put it right back to where it was initially.  now you can instance it and give the instance a -100% scale and you've got a symmetrically instanced model now.
#instanceToEdges : will instance your selected background objects to the currently selected edges' positions/rotations/lengths.
#randomizeChannels : it will randomize the selected channels by said amount.
#channelSelTool : this is to select or deselect items based off of their said channel values. (ie, deselect all objects whose visibity flag is set to off, etc)

#(2-27-12 fix) : forces mesh instance replacements to take on same visibility state as original.
#(2-27-12 fix) : moveToMousePos now works with multiple items selected and resets workplane properly.
#(3-2-12 fix) : 601 changed item.duplicate syntax so it's now updated
#(3-7-12 feature) : moveToLine now supports meshInstances, but can't support static meshes or static mesh instances yet.
#(3-20-12 feature) : makeInstsUnique : modo allows you to instance an instance and so if you do that and delete the instance that defines another instance, the other instance gets deleted as well.  that's terrible and so this script will make all instances of instances to be instances of the sources so that can't happen anymore.
#(3-20-12 feature) : instance : if you want to instance a bunch of crap (meshes, meshInstances, etc), you just select it and run instance.  But that's not good because modo actually allows you to instance another instance and because of the current bug, if you delete any of those instances later on, there's a high percentage chance that it was the source for another instance and now you also just deleted an UNKOWN amount of other instances without meaning to.  You SHOULD feel safe in instancing things that the only way to delete them is to delete the source mesh and that's it.  and this script makes it that way.
#(3-22-12 fix) : argument error is fixed.
#(4-24-12 feature) : hide sub to work in combination with the @unhide.pl namePatternCheck script.
#(4-25-12 fix) : fixed some commands that didn't have their ids wrapped in {}
#(6-4-12 feature) : transferWPToItemPos : say you have some polys floating in space and you want to give it a symmetrical intance, but can't because the polys aren't along the origin.  this script is for doing exactly that.  set the workplane up how you'd want the geometry positioned and then run this script and it'll move/rotate the geometry to that origin and then give it item transforms to put it right back to where it was initially.  now you can instance it and give the instance a -100% scale and you've got a symmetrically instanced model now.
#(10-19-12 fix) : makeInstsUnique : put in a safety check for the item.delete to stop complaints if nothing was found to delete.
#(10-24-12 fix) : put in hack fix to get around a bug with modo's multiple choice windows.
#(10-24-12 fix) : replaceInstances : you can now select a group and your meshes will be swapped with random meshes in that group.
#(2-1-13 fix) : findMeshInstSource sub had an infinite loop with trisurfs.
#(9-3-14 fix) : transferWPToItemPos : fixed an 801 bug where the actr wasn't resetting to 0,0,0 like it should.
#(1-12-15 fix) : quickdialog sub had a typo
#(1-23-15 feature) : added the ability to randomly deselect items.
#(3-1-15 feature) : added SCALESHIFT ability.  Which will let you pad your items' scale by a set amount.  good for making brick objects a little bigger evenly where a scale tool would fail because scales are multiplies and because your object has uneven widths, the long sides would grow much faster than short sides.
#(3-4-15 feature) : added COPYPASTECHANNELS tool.  It's for copying/pasting channels between objects. (only their current channels, not their animated channels)
#(3-7-15 feature) : added QUANTIZEITEMBBOX tool.  it's for snapping your selected item's bboxes to whole units by scaling the items.
#(3-12-15 feature) : added batchReplaceInsts tool. It will look at your selected meshes/instances/staticMeshes and replace them with other mesh instances that have the same name as the original, but with "_lp" at the end.  I use it for example because i have a brick wall made of tons of instances of really high poly brick items and i need to get that data into 3dcoat and i can't convert them to meshes and save as LWO, because teh polycount is wayyy too high, so instead i'll use the LOD tool mentioned above to create all the new lOD'd meshes and then use this to swap all my current instances for teh much lower poly variant, then i convert those to meshes and export to 3dcoat.
#(3-30-15 feature) : modded RANDOMIZE CHANNELS : you can now get a MULTIPLE CHOICE option
#(4-2-15 feature) : modded INSTANCE sub : now supports proxy meshes.
#(4-3-15 feature) : added BATCHREPLACEINSTS sub : you can batch replace all your selected meshes/meshInsts/triSurfs/refs with other instances by doing a basic name find/replace
#(4-3-15 feature) : added TOGGLEMESHTRISURF sub : will toggle the currently selected meshes to trisurfs or vice versa
#(4-15-15 feature) : instanceToEdges : now lets you instance either bg meshes, a specific mesh, or the meshes/trisurfs in a group.  
#(4-21-15 fix) : put in rotation order support for replaceInstances sub

#This script has a number of item tools.  Right now there's only one.
foreach my $arg (@ARGV){
	if		($arg eq "X")						{	our $x = 1;					}
	elsif	($arg eq "Y")						{	our $y = 1;					}
	elsif	($arg eq "Z")						{	our $z = 1;					}
	elsif	($arg eq "set")						{	our $selMode = "set";		}
	elsif	($arg eq "add")						{	our $selMode = "add";		}
	elsif	($arg eq "small")					{	our $small = 1;				}
	elsif	($arg eq "large")					{	our $large = 1;				}
	elsif	($arg eq "worldAxis")				{	our $worldAxis = 1;			}
	elsif	($arg eq "selNewTypeDlg")			{	our $selNewTypeDlg = 1;		}
	elsif	($arg eq "gui")						{	our $gui = 1;				}
	elsif	($arg eq "instance")				{	instance();					}
	elsif	($arg eq "hide")					{	hide();						}
	elsif	($arg eq "ungroup")					{	ungroup();					}
	elsif	($arg =~ /setItemPosToVert/i)		{	setItemPosToVert();			}
	elsif	($arg =~ /selectNewest/i)			{	selectNewestByType();		}
	elsif	($arg =~ /selectAllGrad/i)			{	selectAllGradValues();		}
	elsif	($arg =~ /moveToLine/i)				{	moveToLine();				}
	elsif	($arg =~ /moveScreen/i)				{	moveScreen();				}
	elsif	($arg =~ /printRagePos/i)			{	printRagePos();				}
	elsif	($arg =~ /moveToRagePos/i)			{	moveToRagePos();			}
	elsif	($arg =~ /moveToMousePos/i)			{	moveToMousePos();			}
	elsif	($arg =~ /rectifyItemXfrms/i)		{	rectifyItemXfrms();			}
	elsif	($arg =~ /replaceInstances/i)		{	replaceInstances();			}
	elsif	($arg =~ /replInsts_batch/i)		{	replInsts_batch();			}
	elsif	($arg =~ /makeInstsUnique/i)		{	makeInstsUnique();			}
	elsif	($arg =~ /cnvInstToMeshWPart/i)		{	cnvInstToMeshWPart();		}
	elsif	($arg =~ /delEmptyMshsNGrps/i)		{	delEmptyMshsNGrps();		}
	elsif	($arg =~ /selSiblingsSameType/i)	{	selSiblingsSameType();		}
	elsif	($arg =~ /parentToGroup/i)			{	parentToGroup();			}
	elsif	($arg =~ /flipScale/i)				{	flipScale();				}
	elsif	($arg =~ /selSamePos/i)				{	selSamePos();				}
	elsif	($arg =~ /transferWPToItemPos/i)	{	transferWPToItemPos();		}
	elsif	($arg =~ /instanceToEdges/i)		{	instanceToEdges();			}
	elsif	($arg =~ /randomizeChannels/i)		{	randomizeChannels();		}
	elsif	($arg =~ /channelSelTool/i)			{	channelSelTool();			}
	elsif	($arg =~ /applyLabel/i)				{	applyLabel();				}
	elsif	($arg =~ /itemList_sort/i)			{	itemList_sort();			}
	elsif	($arg =~ /exportSelected/i)			{	exportSelected();			}
	elsif	($arg =~ /exportToObjs/i)			{	exportToObjs();				}
	elsif	($arg =~ /enumerate/i)				{	enumerate();				}
	elsif	($arg =~ /prefix/i)					{	prefix("prefix");			}
	elsif	($arg =~ /suffix/i)					{	prefix("suffix");			}
	elsif	($arg =~ /item_findReplace/i)		{	item_findReplace();			}
	elsif	($arg =~ /instToSelItemPostns/i)	{	instToSelItemPostns();		}
	elsif	($arg =~ /randItemDesel/i)			{	randItemDesel();			}
	elsif	($arg =~ /scaleShift/i)				{	scaleShift();				}
	elsif	($arg =~ /copyPasteChannels/i)		{	copyPasteChannels();		}
	elsif	($arg =~ /quantizeItemBBOX/i)		{	quantizeItemBBOX();			}
	elsif	($arg =~ /LODMeshes/i)				{	LODMeshes();				}
	elsif	($arg =~ /batchReplaceInsts/i)		{	batchReplaceInsts();		}
	elsif	($arg =~ /setupUnrealRotOrder/i)	{	setupUnrealRotOrder();		}
	elsif	($arg =~ /toggleMeshTriSurf/i)		{	toggleMeshTriSurf();		}
	elsif	($arg =~ /quantizeScale_unreal/i)	{	quantizeScale_unreal();		}
	else										{	our $miscArg = $arg;		}
}

srand;

#SETUP USER VALUES
userValueTools(sene_unrealRotOrder,boolean,config,sene_unrealRotOrder,"","","",xxx,xxx,"",1);

#quantize item scales to instance friendly values
sub quantizeScale_unreal{
	my @sizes = (.125, .25, .5, .75, 1, 1.25, 1.5, 2, 3, 4, 8);
	my @meshInsts = lxq("query sceneservice selection ? meshInst");
	
	foreach my $id (@meshInsts){
		my $sclX = roundToClosestInList(lxq("item.channel locator\$scl.X {?} set {$id}") , \@sizes);
		my $sclY = roundToClosestInList(lxq("item.channel locator\$scl.Y {?} set {$id}") , \@sizes);;
		my $sclZ = roundToClosestInList(lxq("item.channel locator\$scl.Z {?} set {$id}") , \@sizes);;
		
		lx("!!item.channel locator\$scl.X {$sclX} set {$id}");
		lx("!!item.channel locator\$scl.Y {$sclY} set {$id}");
		lx("!!item.channel locator\$scl.Z {$sclZ} set {$id}");
	}
}

#round the value to the most similar in predefined list
sub roundToClosestInList{
	my $closestDiff = 99999999999999999999999999;
	my $closest = 0;
	
	foreach my $value (@{$_[1]}){
		my $diff = abs(abs($_[0]) - abs($value));
		if ($diff < $closestDiff){
			$closestDiff = $diff;
			$closest = $value;
		}
	}
	
	if ($_[0] < 0){$closest *= -1;}
	
	return $closest;
}

#toggle selection between meshes and trisurfs. if both are selected, it'll go to trisurfs
sub toggleMeshTriSurf{
	popup("Do you wish to convert meshes to trisurfs and back?");
	my @meshes = lxq("query sceneservice selection ? mesh");
	my @triSurfs = lxq("query sceneservice selection ? triSurf");
	if (@meshes > 0){
		lx("!!item.setType triSurf locator");
	}elsif (@triSurfs > 0){
		lx("!!item.setType mesh locator");
		lx("!!select.vertexMap normals norm replace");
		lx("!!vertMap.delete norm");
	}
}

#make all items in scene use XYZ rot order and warn for those meshes that couldn't be auto converted.
sub setupUnrealRotOrder{
	my $itemCount = lxq("query sceneservice item.n ? all");
	my @meshesAndInstances;
	my @itemsToSelect;
	
	#build list of meshes and instances
	for (my $i=0; $i<$itemCount; $i++){
		if ((lxq("query sceneservice item.type ? $i") eq "mesh") || (lxq("query sceneservice item.type ? $i") eq "meshInst")){
			my $id = lxq("query sceneservice item.id ? $i");
			push(@meshesAndInstances,$id);
		}
	}
	
	#go through all items and if their rot order is not XYZ, set it to that (or add to list if they're not but already have rotation values)
	foreach my $id (@meshesAndInstances){
		my $rotXfrmID = lxq("query sceneservice item.xfrmRot ? {$id}");
		if ($rotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$id}");}
		$rotXfrmID = lxq("query sceneservice item.xfrmRot ? {$id}");
		my $rotOrder = lxq("!!item.channel order {?} set {$rotXfrmID}");
		if ($rotOrder ne "xyz"){
			my $xRot = lxq("!!item.channel rot.X {?} set {$id}");
			my $yRot = lxq("!!item.channel rot.Y {?} set {$id}");
			my $zRot = lxq("!!item.channel rot.Z {?} set {$id}");
			if (($xRot != 0) && ($yRot != 0) && ($zRot != 0))	{	push(@itemsToSelect,$id);							}
			else												{	lx("!!item.channel order {xyz} set {$rotXfrmID}");	}
		}
	}
	
	#select items that couldn't be automatically fixed and popup warning
	if (@itemsToSelect > 0){
		lx("select.drop item");
		lxout("These items have rotations so i can't automatically force the rotation order : ");
		popup("These items aren't using the XYZ rotation order and I can't set that because they already have rotation values that will be corrupted if I do.  So these will have to be fixed manually");
		foreach my $id (@itemsToSelect){
			my $name = lxq("query sceneservice item.name ? {$id}");
			lx("select.subItem {$id} add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
		}
	}
}


#batch replace instances. it replaces the original "meshName" for "meshName_lp"
sub batchReplaceInsts{
	my %itemIDTable;
	my %swapMeshTable;
	my @newMeshInstances;
	my @selection = lxq("query sceneservice selection ? locator");
	my $itemCount = lxq("query sceneservice item.n ? all");
	my $textReplace = quickDialog("Meshnames find/replace",string,"*,*_lp","","");
	my $forceBbox = quickDialog("Force BBOX display?",boolean,0,"","");
	
	#build table of all source item names/ids
	for (my $i=0; $i<$itemCount; $i++){
		my $name = lxq("query sceneservice item.name ? $i");
		my $type = lxq("query sceneservice item.type ? $i");
		if (($type eq "mesh") || ($type eq "triSurf")){
			my $id = lxq("query sceneservice item.id ? $i");
			$name =~ s/ \([0-9]+\)$//;
			$name =~ s/ \([a-zA-Z_]+\)$//; #temp hack to remove " (proxies)" from reference scene item names
			$itemIDTable{$name} = $id;
		}
	}
	
	#go through selection and swap for new instances
	foreach my $id (@selection){
		my $type = lxq("query sceneservice item.type ? {$id}");
		if (($type ne "mesh") && ($type ne "meshInst") && ($type ne "triSurf")){next;}
		my @children = lxq("query sceneservice item.children ? {$id}");
		if (@children > 0){
			popup("oh shit!  this item has children!  can't swap it yet..");
		}
		my $name = lxq("query sceneservice item.name ? {$id}");
		$name =~ s/ \([0-9]+\)$//;
		$name =~ s/ \([a-zA-Z_]+\)$//; #temp hack to remove " (proxies)" from reference scene item names
		$name = findReplace($name,$textReplace);
		
		if (exists $itemIDTable{$name}){
		
			#query visibility and xfrms
			my $visibility = lxq("layer.setVisibility {$id} ?");
			my $parent = lxq("query sceneservice item.parent ? {$id}");
			my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$id}");
			my $rotXfrmID = lxq("query sceneservice item.xfrmRot ? {$id}");
			my $sclXfrmID = lxq("query sceneservice item.xfrmScl ? {$id}");

			#create transforms if missing
			if ($posXfrmID eq ""){lx("!!transform.add type:{pos} item:{$id}");}
			if ($rotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$id}");}
			if ($sclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$id}");}

			#query transforms
			my $xPos = lxq("!!item.channel pos.X {?} set {$id}");
			my $yPos = lxq("!!item.channel pos.Y {?} set {$id}");
			my $zPos = lxq("!!item.channel pos.Z {?} set {$id}");
			my $xRot = lxq("!!item.channel rot.X {?} set {$id}");
			my $yRot = lxq("!!item.channel rot.Y {?} set {$id}");
			my $zRot = lxq("!!item.channel rot.Z {?} set {$id}");
			my $xScl = lxq("!!item.channel scl.X {?} set {$id}");
			my $yScl = lxq("!!item.channel scl.Y {?} set {$id}");
			my $zScl = lxq("!!item.channel scl.Z {?} set {$id}");
			my $rotOrder = lxq("!!item.channel order {?} set {$rotXfrmID}");

			#query bbox state
			my $bboxVisibility = lxq("!!item.channel drawShape {?} set {$id}");
			if ($forceBbox == 1){$bboxVisibility = 1;}
			
			#dupe LP item and give it the transforms
			lx("!!select.item {$itemIDTable{$name}} set");
			lx("!!item.duplicate instance:[1] type:[locator]");
			my @meshInsts = lxq("query sceneservice selection ? meshInst");
			push(@newMeshInstances,$meshInsts[-1]);

			my $newPosXfrmID = lxq("query sceneservice item.xfrmPos ? {$meshInsts[0]}");
			my $newRotXfrmID = lxq("query sceneservice item.xfrmRot ? {$meshInsts[0]}");
			my $newSclXfrmID = lxq("query sceneservice item.xfrmScl ? {$meshInsts[0]}");

			if ($newPosXfrmID eq ""){lx("!!transform.add type:{pos} item:{$meshInsts[0]}");}
			if ($newRotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$meshInsts[0]}");}
			if ($newSclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$meshInsts[0]}");}

			lx("!!item.channel pos.X {$xPos} set {$meshInsts[0]}");
			lx("!!item.channel pos.Y {$yPos} set {$meshInsts[0]}");
			lx("!!item.channel pos.Z {$zPos} set {$meshInsts[0]}");
			lx("!!item.channel rot.X {$xRot} set {$meshInsts[0]}");
			lx("!!item.channel rot.Y {$yRot} set {$meshInsts[0]}");
			lx("!!item.channel rot.Z {$zRot} set {$meshInsts[0]}");
			lx("!!item.channel scl.X {$xScl} set {$meshInsts[0]}");
			lx("!!item.channel scl.Y {$yScl} set {$meshInsts[0]}");
			lx("!!item.channel scl.Z {$zScl} set {$meshInsts[0]}");
			$newRotXfrmID = lxq("query sceneservice item.xfrmRot ? {$meshInsts[0]}");
			lx("!!item.channel order {$rotOrder} set {$newRotXfrmID}");
			lx("!!item.channel drawShape {$bboxVisibility} set {$meshInsts[0]}");
			if ($parent ne ""){lx("!!item.parent item:{$meshInsts[0]} parent:{$parent} inPlace:{0}");}
			lx("!!layer.setVisibility {$meshInsts[-1]} {$visibility}");

			#delete old item.
			lx("!!select.item {$id} set");
			lx("!!item.delete");
		}
		else{
			popup("can't find a replacement item for this mesh : $name");
		}
	}
}

#LOD meshes
sub LODMeshes{
	my $groupName = quickDialog("What should the new group name be?",string,"LOD Group","","");
	my $polyCountMult = quickDialog("LOD percentage?",float,0.2,0.01,0.999);
	my @selection = lxq("query sceneservice selection ? all");
	my $groupID;
	
	#create group and name it
	lx("!!select.drop item");
	lx("!!item.create groupLocator");
	lx("!!item.name {$groupName} groupLocator ");
	my @groupLocatorIDs = lxq("query sceneservice selection ? groupLocator");
	$groupID = $groupLocatorIDs[-1];
	
	#progress meter
	lxmonInit($#selection);
	
	#go through items and dupe em and lod em
	foreach my $id (@selection){
		my $type = lxq("query sceneservice item.type ? {$id}");
		if (($type eq "mesh") || ($type eq "triSurf")){
			my $name = lxq("query sceneservice item.name ? {$id}");
			lx("!!select.subItem {$id} set mesh;meshInst;triSurf;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
			lx("!!item.duplicate false locator true true");
			if ($type eq "triSurf"){	
				lx("!!item.setType mesh locator");	
				my @currSel = lxq("query sceneservice selection ? locator");
				$id = $currSel[-1];
			}
			
			my $layerName = lxq("query layerservice layer.name ? {$id}");
			$layerName =~ s/ \([0-9]+\)$//;
			my $newName = $layerName . "_lp";
			my $polyCount = lxq("query layerservice poly.n ? all");
			my $newPolyCount = $polyCount * $polyCountMult;
			
			lx("!!tool.set poly.reduct on");
			lx("!!tool.reset");
			lx("!!tool.attr poly.reduct number $newPolyCount");
			lx("!!tool.doApply");
			lx("!!tool.set poly.reduct off");
			
			lx("!!item.name {$newName} locator");
			lx("!!item.parent {$id} {$groupID} 0 inPlace:1");
			lx("!!item.setType triSurf locator");	
			
			lxmonStep;
		}
	}
}


#quantize item scales
sub quantizeItemBBOX{
	my $axisFilter = quickDialog("Quantize Which Axes?",string,"XYZ","","");
	my @selection = lxq("query sceneservice selection ? all");
	
	foreach my $id (@selection){
		my $type = lxq("query sceneservice item.type ? {$id}");
		if (($type ne "mesh") && ($type ne "meshInst") && ($type ne "triSurf")){next;}
		
		verifySclXfrm($id);
		
		my @bounds = queryBounds($id);
		my @meshSize = ( $bounds[3]-$bounds[0] , $bounds[4]-$bounds[1] , $bounds[5]-$bounds[2] );

		my $xfrm_scaleX = lxq("item.channel scl.X {?} set {$id}");
		my $xfrm_scaleY = lxq("item.channel scl.Y {?} set {$id}");
		my $xfrm_scaleZ = lxq("item.channel scl.Z {?} set {$id}");

		my @negScale = (1,1,1);
		
		if ($xfrm_scaleX < 0)	{	$negScale[0] = -1;		$xfrm_scaleX = abs($xfrm_scaleX);	}
		if ($xfrm_scaleY < 0)	{	$negScale[1] = -1;		$xfrm_scaleY = abs($xfrm_scaleY);	}
		if ($xfrm_scaleZ < 0)	{	$negScale[2] = -1;		$xfrm_scaleZ = abs($xfrm_scaleZ);	}
		
		my $finalSizeX = $xfrm_scaleX * $meshSize[0];
		my $finalSizeY = $xfrm_scaleY * $meshSize[1];
		my $finalSizeZ = $xfrm_scaleZ * $meshSize[2];
		
		my $finalSizeX_quantized = int($finalSizeX + .5);
		my $finalSizeY_quantized = int($finalSizeY + .5);
		my $finalSizeZ_quantized = int($finalSizeZ + .5);
		
		if ($finalSizeX_quantized == 0)	{	$finalSizeX_quantized = 1;	}
		if ($finalSizeY_quantized == 0)	{	$finalSizeY_quantized = 1;	}
		if ($finalSizeZ_quantized == 0)	{	$finalSizeZ_quantized = 1;	}
		
		my $scaleAmtX = ($finalSizeX_quantized / $finalSizeX) * ($xfrm_scaleX * $negScale[0]);
		my $scaleAmtY = ($finalSizeY_quantized / $finalSizeY) * ($xfrm_scaleY * $negScale[1]);
		my $scaleAmtZ = ($finalSizeZ_quantized / $finalSizeZ) * ($xfrm_scaleZ * $negScale[2]);
		
		if ($axisFilter =~ /x/i)	{	lx("item.channel scl.X {$scaleAmtX} set {$id}");	}
		if ($axisFilter =~ /y/i)	{	lx("item.channel scl.Y {$scaleAmtY} set {$id}");	}
		if ($axisFilter =~ /z/i)	{	lx("item.channel scl.Z {$scaleAmtZ} set {$id}");	}
	}
}

#copy paste channels (it's hardcoded to copy/paste xfrm channels regardless of item type.  might need to change that)
sub copyPasteChannels{
	my @selection = lxq("query sceneservice selection ? all");
	my @channels = lxq("query sceneservice selection ? channels");
	my %channelList;
	my %channels_firstUsed;
	my %itemTypes;
	my %itemChannels;
	my @transforms = ("pos.X","pos.Y","pos.Z","rot.X","rot.Y","rot.Z","scl.X","scl.Y","scl.Z");

	#build list of channels per item type and list of item types
	foreach my $id (@selection){
		my $type = lxq("query sceneservice item.type ? {$id}");
		if (!exists $itemTypes{$type}){
			$itemTypes{$type} = 1;
			my $channelCount = lxq("query sceneservice channel.n ?");
			for (my $i=0; $i<$channelCount; $i++){
				my $channelName = lxq("query sceneservice channel.name ? $i");
				${itemChannels{$type}}{$channelName} = 1;
			}
			for (my $i=0; $i<@transforms; $i++){
				${itemChannels{$type}}{$transforms[$i]} = 1;
			}
		}
	}

	#go through each channel type and copy/paste the values
	foreach my $channel (@channels){
		$channel =~ s/[()]//g;
		my @values = split(/,/, $channel);
		
		if (!exists $channelList{$values[2]}){
			$channelList{$values[2]} = 1;

			foreach my $id (@selection){
				my $type = lxq("query sceneservice item.type ? {$id}");
				if (${$itemChannels{$type}}{$values[2]} == 1){
					if (!exists $channels_firstUsed{$values[2]}){
						my $value = lxq("item.channel {$values[2]} {?} set {$id}");
						lxout("copying value : $id : $values[2] : $value");
						$channels_firstUsed{$values[2]} = $value;
					}else{
						lxout("pasting value : $id : $values[2] : $channels_firstUsed{$values[2]}");
						lx("!!item.channel {$values[2]} {$channels_firstUsed{$values[2]}} set {$id}");
					}
				}
			}
		}
	}
}

#offset the bbox size of your selected meshes/insts/trisurfs
sub scaleShift{
	our $padAmt = quickDialog("Scale Pad Amt",float,0.1,"","");
	our $axisFilter = quickDialog("Scale Which Axes?",string,"XYZ","","");
	our @meshes = lxq("query sceneservice selection ? mesh");
	our @instances = lxq("query sceneservice selection ? meshInst");
	our @triSurfs = lxq("query sceneservice selection ? triSurf");

	verifySclXfrm($_) for @meshes;
	verifySclXfrm($_) for @instances;
	verifySclXfrm($_) for @triSurfs;

	padScale($_) for @meshes;
	padScale($_) for @instances;
	padScale($_) for @triSurfs;
}

#randomly deselect some items
sub randItemDesel{
	my $randChance = quickDialog("Percentage chance to deselect item:",float,50,"","") * .01;
	my @items = lxq("query sceneservice selection ? locator");
	foreach my $id (@items){
		if (rand(1) <= $randChance){
			lx("select.subItem {$id} remove mesh;meshInst;camera;light;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
		}
	}

}

#exports the selected meshes to objs by copying/pasting polys to new scene.
sub exportToObjs{
	my @files = fileDialog("save","Export As","*.obj","obj");
	if (lxres != 0){	die("The user hit the cancel button");	}
	$files[-1] =~ s/\..*//;

	my $sceneIndex = lxq("query sceneservice scene.index ? main");
	my @selection = lxq("query sceneservice selection ? all");
	foreach my $id (@selection){
		if (lxq("query sceneservice item.type ? {$id}") eq "mesh"){
			my $layerName = lxq("query sceneservice item.name ? {$id}");
			my $path = $files[-1] . "_" . $layerName . ".obj";
			lx("!!select.subItem {$id} set mesh;triSurf;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
			lx("!!select.drop polygon");
			lx("!!select.copy");
			lx("!!scene.new");
			lx("!!select.paste");
			lx("!!scene.saveAs {$path} wf_OBJ false");
			lx("!!scene.close");
			lx("!!scene.set {$sceneIndex}");
		}else{
			lxout("skipping this because it's not a mesh : {$id}");
		}
	}
}

#will look at your selection and instance the last selected item to the positions of all the other selected items.
sub instToSelItemPostns{
	my @selection = lxq("query sceneservice selection ? all");
	my @newItemIDs;
	for (my $i=0; $i<$#selection; $i++){
		my @worldPos = lxq("query sceneservice item.worldPos ? $selection[$i]");
		lxout("worldPos = @worldPos");
		
		lx("select.subItem {$selection[-1]} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
		lx("!!item.duplicate true locator");
		my $currSelID = lxq("query sceneservice selection ? all");
		lx("item.channel pos.X {$worldPos[0]} set {$currSelID}");
		lx("item.channel pos.Y {$worldPos[1]} set {$currSelID}");
		lx("item.channel pos.Z {$worldPos[2]} set {$currSelID}");
		push(@newItemIDs,$currSelID);
	}
	lx("select.subItem {$selection[-1]} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
	lx("select.subItem {$_} add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0") for @newItemIDs;
}

sub enumerate{
	my $number = quickDialog("Number to start at:",integer,1,"","");		
	my $printNumber;
	my $padding = quickDialog("Number Padding?:",integer,0,"","");
	my $underscore = quickDialog("Use an underscore?",boolean,1,"","");
	if ($underscore == 1)	{	$underscore = "_";	}
	else					{	$underscore = "";	}
	
	my @itemSel = lxq("query sceneservice selection ? locator");
	foreach my $id (@itemSel){
		my $name = lxq("query sceneservice item.name ? {$id}");
		$name =~ s/ \([0-9]+\)$//;
		if ($padding > 0)	{	$printNumber = roundIntString($number,$padding,0);  }
		else				{	$printNumber = $number;								}
		$name .= $underscore . $printNumber;
		lx("!!item.name name:{$name} item:{$id}");
		
		$number++;
	}
}

#export selected (hardcoded to export LWOs.  should put in support for any file format, center selected or not, 0 padding in numbers, auto conversion of static mesh, etc)
sub exportSelected{
	my $sceneIndex = lxq("query sceneservice scene.index ? current");
	my @files = fileDialog("save","Export As","*.lxo;*.lwo;*.obj","lwo");
	$files[-1] =~ s/\..*//;
	my $count = 0;

	my @selection = lxq("query sceneservice selection ? mesh");
	foreach my $id (@selection){
		$count++;
		my $path = $files[-1];
		$path .= "_" . $count . ".lwo";

		lx("select.subItem {$id} set mesh;meshInst;triSurf;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
		lx("select.drop polygon");
		lx("select.copy");

		lx("scene.new");
		lx("select.paste");
		lx("!!scene.saveAs {$path} \$NLWO2 false");
		lx("!!scene.close");
		lx("!!scene.set {$sceneIndex}");
	}
}

#sort itemList alphabetically  (is ignoring case btw)
sub itemList_sort{
	my @nameList;
	my %itemNameList;
	my @itemSel = lxq("query sceneservice selection ? locator");
	foreach my $id (@itemSel){
		my $name = lc(lxq("query sceneservice item.name ? {$id}"));
		$itemNameList{$name} = $id;
		push(@nameList,$name);
	}
	
	my @sortedNameList;
	sortTextAndNumberArray(\@sortedNameList,\@nameList);
	for (my $i=0; $i<@sortedNameList; $i++){
		lxout("$sortedNameList[$i]");
	}
	
	my $itemListPos = lxq("query sceneservice item.rootIndex ? {$itemSel[0]}") + 1;
	lxout("itemListPos = $itemListPos");
	for (my $i=0; $i<@sortedNameList; $i++){
		$itemListPos++;
		my $currentItemListPos = lxq("query sceneservice item.rootIndex ? {$itemNameList{$sortedNameList[$i]}}");	
		lx("!!select.subItem {$itemNameList{$sortedNameList[$i]}} set mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
		lx("!!layer.move $currentItemListPos {$itemListPos} 0");
	}
	
	lx("select.drop item");
	lx("!!select.subItem {$_} add mesh;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0") for @itemSel;
	
}

#FIND REPLACE (to selected items' names)
sub item_findReplace{
	my $findText = quickDialog("Find Text:",string,"","","");
	my $replaceText = quickDialog("Replace Text:",string,"","","");
	
	my @itemSel = lxq("query sceneservice selection ? all");
	foreach my $id (@itemSel){
		my $name = lxq("query sceneservice item.name ? {$id}");
		$name =~ s/\s\([0-9]+\)$//;
		$name =~ s/$findText/$replaceText/g;
		lx("item.name name:{$name} item:{$id}");
	}
}

#PREFIX (apply prefix to selected items' names)
sub prefix{
	my @itemSel = lxq("query sceneservice selection ? all");
	if (@itemSel == 0){die("You don't have any items selected and so I'm cancelling the script");}
	my $text = quickDialog("text to add to item names",string,"","","");

	if ($_[0] eq "prefix"){
		foreach my $id (@itemSel){
			my $name = lxq("query sceneservice item.name ? {$id}");
			$name =~ s/\s\([0-9]+\)$//;
			$name = $text . $name;
			lx("item.name name:{$name} item:{$id}");
		}
	}else{
		foreach my $id (@itemSel){
			my $name = lxq("query sceneservice item.name ? {$id}");
			$name =~ s/\s\([0-9]+\)$//;
			$name .= $text;
			lx("item.name name:{$name} item:{$id}");
		}
	}
}


#APPLY LABEL
sub applyLabel{
	my $label = quickDialog("Label:",string,"","","");
	lx("!!item.channel locator\$ihShowLabel true");
	lx("!!item.help add label {$label}");
}

#UNGROUP GROUPLOCATOR WHILE KEEPING OBJECT TRANSFORMS
sub ungroup{
	my @groupSel = lxq("query sceneservice selection ? groupLocator");
	foreach my $groupID (@groupSel){
		my @children = lxq("query sceneservice item.children ? {$groupID}");
		my $parent = lxq("query sceneservice item.parent ? {$groupID}");
		foreach my $childID (@children){
			lx("item.parent {$childID} {$parent} {-1} inPlace:1");
		}
	}

	lx("!!select.drop item");
	lx("!!select.subItem {$_} add mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0") for @groupSel;
	lx("!!item.delete mask:groupLocator");
}


#CHANNEL SELECTION TOOL
sub channelSelTool{
	#get selection mode
	my $selMode = popupMultChoice("Selection Mode?","add;remove;toggle",0);
	my @selection;

	#gather list of items
	if ($selMode eq "add"){
		my $itemCount = lxq("query sceneservice item.n ? all");
		for (my $i=0; $i<$itemCount; $i++){
			push(@selection,lxq("query sceneservice item.id ? $i"));
		}
	}else{
		@selection = lxq("query sceneservice selection ? all");
	}

	#gather list of channels
	my %channelList;
	my @channels = lxq("query sceneservice selection ? channels");
	foreach my $channel (@channels){
		$channel =~ s/.*,//g;
		$channel =~ s/\)//;
		$channelList{$channel} = 1;
	}

	#get which channel to pay attention to
	my $channelList;
	$channelList .= $_ . ";" for (keys %channelList);
	$channelList =~ s/\;$//;
	my $channelName = popupMultChoice("Query which channel?",$channelList,0);

	#get which value to look for
	my %channelValues;
	foreach my $id (@selection){
		my $value = lxq("!!item.channel {$channelName} ? set {$id}");
		if ($value eq ""){next;}
		$channelValues{$value} = 1;
	}

	my $searchType;
	my $expressionMode = 0;
	my $channelValueList;
	$channelValueList .= $_ . ";" for (keys %channelValues);
	$channelValueList =~ s/\;$//;
	my $channelValue;
	if ($channelValueList =~ /[a-zA-Z_]/i ){
		$channelValue = popupMultChoice("Use which value?",$channelValueList,0);
	}else{
		$channelValue = quickDialog("Value Expression: (!,<,>,>=,<=)",string,"!0","","");
		if ($channelValue =~ />=/){
			$channelValue =~ s/\>\=//;
			$expressionMode = 1;
		}elsif	($channelValue =~ /<=/){
			$channelValue =~ s/\<\=//;
			$expressionMode = 2;
		}elsif	($channelValue =~ /</){
			$channelValue =~ s/\<//;
			$expressionMode = 3;
		}elsif	($channelValue =~ />/){
			$channelValue =~ s/\>//;
			$expressionMode = 4;
		}elsif	($channelValue =~ /!/){
			$channelValue =~ s/\!//;
			$expressionMode = 5;
		}
	}

	if ($channelValue =~ /[0-9.]/)	{	$searchType = 0;	}
	else							{	$searchType = 1;	}

	#go through items and select them.
	foreach my $id (@selection){
		my $value = lxq("!!item.channel {$channelName} ? set {$id}");
		if ($value eq ""){next;}

		if ($searchType == 0){
			if		(($expressionMode == 0) && ($value == $channelValue))	{lx("select.subItem {$id} {$selMode} mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");	}
			elsif	(($expressionMode == 1) && ($value >= $channelValue))	{lx("select.subItem {$id} {$selMode} mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");	}
			elsif	(($expressionMode == 2) && ($value <= $channelValue))	{lx("select.subItem {$id} {$selMode} mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");	}
			elsif	(($expressionMode == 3) && ($value < $channelValue))	{lx("select.subItem {$id} {$selMode} mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");	}
			elsif	(($expressionMode == 4) && ($value > $channelValue))	{lx("select.subItem {$id} {$selMode} mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");	}
			elsif	(($expressionMode == 5) && ($value != $channelValue))	{lx("select.subItem {$id} {$selMode} mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");	}
		}elsif ($value eq $channelValue){
			lx("select.subItem {$id} {$selMode} mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
		}
	}
}

#RANDOMIZE CHANNELS
sub randomizeChannels{
	my @selection = lxq("query sceneservice selection ? all");
	my @channels = lxq("query sceneservice selection ? channels");
	my %channelList;

	#get alteration amount
	my $scaleType = popupMultChoice("Randomization Type?","Addition;Multiplication;RandMultBetween;MultipleChoice",0);
	my $randAmount;
	if ($scaleType eq "RandMultBetween"){
		$randAmount = quickDialog("Random Multiplier Between",string,".5,1");
		$randAmount =~ s/\s//g;
		our @values = split(/,/, $randAmount);
		$randAmount = $values[1]-$values[0];
	}elsif ($scaleType eq "MultipleChoice"){
		$randAmount = quickDialog("Possible Choices:",string,"0,1,2");
		$randAmount =~ s/\s//g;
		our @values = split(/,/, $randAmount);
	}else{
		$randAmount = quickDialog("Randomization Amount",float,1,0.00001,1000000000);
	}


	#gather list of channels
	foreach my $channel (@channels){
		$channel =~ s/.*,//g;
		$channel =~ s/\)//;
		$channelList{$channel} = 1;
	}

	#go through items and alter channels
	foreach my $id (@selection){
		foreach my $channel (keys %channelList){
			my $value = lxq("!!item.channel {$channel} ? set {$id}");

			if ($value !~ /[0-9.]/){
				next;
			}elsif ($scaleType eq "Addition"){
				$value += rand($randAmount*2) - $randAmount;
			}elsif ($scaleType eq "Multiplication"){
				my $mult = 1 + (rand($randAmount*2) - $randAmount);
				$value *= 1 + (rand($randAmount*2) - $randAmount);
			}elsif ($scaleType eq "MultipleChoice"){
				$value = $values[int(rand($#values+.5))];
			}else{
				$value *= $values[0] + rand($randAmount);
			}

			lx("!!item.channel {$channel} {$value} set {$id}");
		}
	}
}

#INSTANCE THE BACKGROUND MESHES TO ALL THE SELECTED EDGES.
#note : meshes should be along Y axis and 1 meter tall.
sub instanceToEdges{
	my @upVec = (0,1,0);
	our $mainlayer = lxq("query layerservice layers ? main");
	my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");
	my @edges = lxq("query layerservice edges ? selected");
	if (@edges == 0){die("You don't have any edges selected, so I'm cancelling the script");}
	my $scaleType = popupMultChoice("Which type of scale?","Uniform;Length Only;None",0);
	
	
	#get list of items to intance with
	my $typesOfItems = popupMultChoice("Which types of items to instance?","Background Layers;Specific Mesh;Group;",0);
	my @bgLayerIDs;
	
	#a : bg layers
	if ($typesOfItems eq "Background Layers"){
		my @bgLayers = lxq("query layerservice layers ? bg");	
		for (my $i=0; $i<@bgLayers; $i++){ @bgLayerIDs[$i] = lxq("query layerservice layer.id ? $bgLayers[$i]"); }
	}
	
	#b : specific mesh
	elsif ($typesOfItems eq "Specific Mesh"){
		my $itemCount = lxq("query sceneservice item.n ? all");
		my %tempList;
		my $guiTextLine;
		for (my $i=0; $i<$itemCount; $i++){
			if ( (lxq("query sceneservice item.type ? $i") eq "mesh") || (lxq("query sceneservice item.type ? $i") eq "triSurf") ){
				my $name = lxq("query sceneservice item.name ? $i");
				my $id = lxq("query sceneservice item.id ? $i");
				$tempList{$name} = $id;
			}
		}
		
		foreach my $key (sort keys %tempList){	$guiTextLine .= $key . ";";	}
		$guiTextLine =~ s/\;$//;
		my $answer = popupMultChoice("Which mesh to instance?",$guiTextLine,0);
		@bgLayerIDs = $tempList{$answer};
	}
	
	#c : group (not group locator)
	elsif ($typesOfItems eq "Group"){
		my $itemCount = lxq("query sceneservice item.n ? all");
		my %tempList;
		my $guiTextLine;

		for (my $i=0; $i<$itemCount; $i++){
			if (lxq("query sceneservice item.type ? $i") eq "group"){
				my $name = lxq("query sceneservice item.name ? $i");
				my $id = lxq("query sceneservice item.id ? $i");
				$tempList{$name} = $id;
			}
		}
		
		foreach my $key (sort keys %tempList){	$guiTextLine .= $key . ";";	}
		$guiTextLine =~ s/\;$//;
		my $answer = popupMultChoice("Which Group to instance with?",$guiTextLine,0);
		my $groupID = $tempList{$answer};

		lx("group.scan group:{$groupID}");
		my @meshes = lxq("query sceneservice selection ? mesh");
		my @triSurfs = lxq("query sceneservice selection ? triSurf");
		push(@bgLayerIDs, @meshes);
		push(@bgLayerIDs, @triSurfs);
	}

	#create group locator
	lx("item.create groupLocator");
	our $groupLocID = lxq("query sceneservice selection ? locator");
	lx("!!item.parent {$groupLocID} {$mainlayerID} -1");
	lx("!!item.name name:{meshInstances} item:{$groupLocID}");

	foreach my $edge (@edges){
		my $layerName = lxq("query layerservice layer.name ? $mainlayer");
		#get vector
		my @verts = split (/[^0-9]/, $edge);
		lxout("verts = @verts");
		my @vertPos1 = lxq("query layerservice vert.pos ? $verts[1]");
		my @vertPos2 = lxq("query layerservice vert.pos ? $verts[2]");
		my @vector = arrMath(@vertPos2,@vertPos1,subt);
		my $length =  dist(@vector);
		my @center = arrMath(arrMath(@vertPos1,@vertPos2,add),.5,.5,.5,mult);
		
		#convert to matrix
		my @xVec;
		my @yVec = unitVector(@vector);
		my @zVec;
		getTwoCPVecsFromOneVec(\@yVec,\@xVec,\@zVec);
		
		#convert to angles.
		my @matrix = ([@xVec],[@yVec],[@zVec]);
		@matrix = transposeRotMatrix_3x3(\@matrix);
		#my @angles = Eul_FromMatrix(\@matrix,"ZXYs","degrees");	#normal
		my @angles = Eul_FromMatrix(\@matrix,"XYZs","degrees");		#unreal
		
		#determine scale amount
		my $itemID = $bgLayerIDs[int(rand($#bgLayerIDs)+.5)];
		my @bounds = lxq("query layerservice layer.bounds ? {$itemID}");
		#my $scaleAmt = $length;	#normal
		my $scaleAmt = $length / ($bounds[4]-$bounds[1]);	#unreal

		#instance item.
		lx("select.subItem {$itemID} set mesh;meshInst;camera;light;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
		lx("!!item.duplicate true locator");
		my $instID = lxq("query sceneservice selection ? meshInst");

		#create instance transforms if missing
		my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$instID}");
		my $rotXfrmID = lxq("query sceneservice item.xfrmRot ? {$instID}");
		my $sclXfrmID = lxq("query sceneservice item.xfrmScl ? {$instID}");
		if ($posXfrmID eq ""){lx("!!transform.add type:{pos} item:{$instID}");}
		if ($rotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$instID}");}
		if ($sclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$instID}");}

		#now apply transform
		lx("!!item.channel pos.X {$center[0]} set {$instID}");
		lx("!!item.channel pos.Y {$center[1]} set {$instID}");
		lx("!!item.channel pos.Z {$center[2]} set {$instID}");

		lx("!!transform.channel order xyz"); #unreal
		lx("!!item.channel rot.X {$angles[0]} set {$instID}");
		lx("!!item.channel rot.Y {$angles[1]} set {$instID}");
		lx("!!item.channel rot.Z {$angles[2]} set {$instID}");

		if ($scaleType eq "Uniform"){
			lx("!!item.channel scl.X {$scaleAmt} set {$instID}");
			lx("!!item.channel scl.Y {$scaleAmt} set {$instID}");
			lx("!!item.channel scl.Z {$scaleAmt} set {$instID}");
		}elsif ($scaleType eq "Length Only"){
			lx("!!item.channel scl.Y {$scaleAmt} set {$instID}");
		}

		#now group item.
		lx("!!item.parent $instID $groupLocID -1");
	}
}

#usage : createTextLocMatrix(\@matrix_3x3,$scaleAmt,\@center); or createDebugMatrix(\@matrix_4x4,$scaleAmt);
#requires arrMath and createTextLoc
sub createTextLocMatrix{
	my @center;
	my @xPos;
	my @yPos;
	my @zPos;

	if ($#_ == 2)	{	@center = @{$_[2]};											}
	else			{	@center = (${$_[0]}[0][3],${$_[0]}[1][3],${$_[0]}[2][3]);	}

	@xPos = arrMath(	arrMath(	${$_[0]}[0][0],${$_[0]}[0][1],${$_[0]}[0][2],		$_[1],$_[1],$_[1],mult),		@center,add);
	@yPos = arrMath(	arrMath(	${$_[0]}[1][0],${$_[0]}[1][1],${$_[0]}[1][2],		$_[1],$_[1],$_[1],mult),		@center,add);
	@zPos = arrMath(	arrMath(	${$_[0]}[2][0],${$_[0]}[2][1],${$_[0]}[2][2],		$_[1],$_[1],$_[1],mult),		@center,add);

	createTextLoc($center[0],$center[1],$center[2],"O",.01);
	createTextLoc($xPos[0],$xPos[1],$xPos[2],"X",.01);
	createTextLoc($yPos[0],$yPos[1],$yPos[2],"Y",.01);
	createTextLoc($zPos[0],$zPos[1],$zPos[2],"Z",.01);
}



#TEMP : THIS IS THE SUB WRITTEN FOR MORGAN.  IT NEEDS TO BE REWRITTEN INTO A PROPER INSTANCE REPLACER.
sub blah{
	my $itemCount = lxq("query sceneservice item.n ? all");
	my @groups;
	my @instances;
	my @aasInstances;
	my $groupID;
	my %aasItemIdTable;

	#create new group to put end result instances into
	lx("select.drop item");
	lx("item.create groupLocator");
	lx("item.name {aasInstances} groupLocator");
	my @groupSel = lxq("query sceneservice selection ? groupLocator");
	$groupID = $groupSel[-1];

	#build list of groupLocators
	for (my $i=0; $i<$itemCount; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "groupLocator"){
			push(@groups,lxq("query sceneservice item.id ? $i"));
		}elsif (lxq("query sceneservice item.type ? $i") eq "meshInst"){
			push(@instances,lxq("query sceneservice item.id ? $i"));
		}
	}

	#now go build table for AAS mesh IDs.
	foreach my $id (@groups){
		if (lxq("query sceneservice item.name ? {$id}") =~ /AAS/i){
			my @children = lxq("query sceneservice item.children ? {$id}");
			foreach my $id (@children){
				my $name = lxq("query sceneservice item.name ? {$id}");
				$name =~ s/\s\([0-9]+\)$//;
				$aasItemIdTable{$name} = $id;
			}
		}
	}

	foreach my $key (keys %aasItemIdTable){
		lxout("-$key- = $aasItemIdTable{$key}");
	}

	#now go through all instances and build dupes that are of the original AAS files.
	foreach my $id (@instances){
		my $sourceMeshID = findMeshInstSource($id) or die("$item is not a meshInst");
		my $sourceMeshName = lxq("query sceneservice item.name ? {$sourceMeshID}");
		$sourceMeshName =~ s/\s\([0-9]+\)$//;
		lxout("sourceMeshName = -$sourceMeshName-");
		my $aasMeshID = $aasItemIdTable{$sourceMeshName};
		if ($aasMeshID eq ""){
			lxout("WARNING! : the AAS model of name ($sourceMeshName) couldn't be found!");
			next;
		}

		#instance the AAS mesh
		lx("select.item {$aasMeshID} set");
		lx("item.duplicate instance:true type:locator");
		my @currMeshInstSel = lxq("query sceneservice selection ? meshInst");
		push(@aasInstances,$currMeshInstSel[-1]);

		#create transforms if missing
		my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$id}");
		my $rotXfrmID = lxq("query sceneservice item.xfrmRot ? {$id}");
		my $sclXfrmID = lxq("query sceneservice item.xfrmScl ? {$id}");
		if ($posXfrmID eq ""){lx("!!transform.add type:{pos} item:{$id}");}
		if ($rotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$id}");}
		if ($sclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$id}");}

		#query transform of original instance
		my $xPos = lxq("!!item.channel pos.X {?} set {$id}");
		my $yPos = lxq("!!item.channel pos.Y {?} set {$id}");
		my $zPos = lxq("!!item.channel pos.Z {?} set {$id}");
		my $xRot = lxq("!!item.channel rot.X {?} set {$id}");
		my $yRot = lxq("!!item.channel rot.Y {?} set {$id}");
		my $zRot = lxq("!!item.channel rot.Z {?} set {$id}");
		my $xScl = lxq("!!item.channel scl.X {?} set {$id}");
		my $yScl = lxq("!!item.channel scl.Y {?} set {$id}");
		my $zScl = lxq("!!item.channel scl.Z {?} set {$id}");

		#set transform onto new instance
		my $newPosXfrmID = lxq("query sceneservice item.xfrmPos ? {$currMeshInstSel[-1]}");
		my $newRotXfrmID = lxq("query sceneservice item.xfrmRot ? {$currMeshInstSel[-1]}");
		my $newSclXfrmID = lxq("query sceneservice item.xfrmScl ? {$currMeshInstSel[-1]}");
		if ($newPosXfrmID eq ""){lx("!!transform.add type:{pos} item:{$currMeshInstSel[-1]}");}
		if ($newRotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$currMeshInstSel[-1]}");}
		if ($newSclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$currMeshInstSel[-1]}");}

		lx("!!item.channel pos.X {$xPos} set {$currMeshInstSel[-1]}");
		lx("!!item.channel pos.Y {$yPos} set {$currMeshInstSel[-1]}");
		lx("!!item.channel pos.Z {$zPos} set {$currMeshInstSel[-1]}");
		lx("!!item.channel rot.X {$xRot} set {$currMeshInstSel[-1]}");
		lx("!!item.channel rot.Y {$yRot} set {$currMeshInstSel[-1]}");
		lx("!!item.channel rot.Z {$zRot} set {$currMeshInstSel[-1]}");
		lx("!!item.channel scl.X {$xScl} set {$currMeshInstSel[-1]}");
		lx("!!item.channel scl.Y {$yScl} set {$currMeshInstSel[-1]}");
		lx("!!item.channel scl.Z {$zScl} set {$currMeshInstSel[-1]}");

		#parent new instance to aasInstances group
		lx("item.parent {$currMeshInstSel[-1]} {$groupID} 0 inPlace:1");
	}
}

#transfer the mainlayer geo to the workplane origin and then put item transforms in to put it back where it was.
sub transferWPToItemPos{
	my $mainlayer = lxq("query layerservice layers ? main");
	my $mainlayerID = lxq("query layerservice layer.id ? $mainlayer");

	#query workplane
	my @WPmem;
	@WPmem[0] = lxq ("workPlane.edit cenX:? ");
	@WPmem[1] = lxq ("workPlane.edit cenY:? ");
	@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
	@WPmem[3] = lxq ("workPlane.edit rotX:? ");
	@WPmem[4] = lxq ("workPlane.edit rotY:? ");
	@WPmem[5] = lxq ("workPlane.edit rotZ:? ");
	lx("workplane.reset");

	#create transforms if missing
	my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$mainlayerID}");
	my $rotXfrmID = lxq("query sceneservice item.xfrmRot ? {$mainlayerID}");
	if ($posXfrmID eq ""){lx("!!transform.add type:{pos} item:{$mainlayerID}");}
	if ($rotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$mainlayerID}");}

	$_ *= -1 for @WPmem;

	lx("select.drop polygon");

	lx("tool.set actr.auto on");
	lx("tool.set xfrm.move on");
	lx("tool.reset");
	lx("tool.setAttr axis.auto startX {0}");
	lx("tool.setAttr axis.auto startY {0}");
	lx("tool.setAttr axis.auto startZ {0}");
	lx("tool.setAttr xfrm.move X {$WPmem[0]}");
	lx("tool.setAttr xfrm.move Y {$WPmem[1]}");
	lx("tool.setAttr xfrm.move Z {$WPmem[2]}");
	lx("tool.doApply");
	lx("tool.set xfrm.move off");

	lx("tool.set xfrm.rotate on");
	lx("tool.reset");
	lx("tool.attr axis.auto axis 2");
	lx("tool.attr center.auto cenX 0");
	lx("tool.attr center.auto cenY 0");
	lx("tool.attr center.auto cenZ 0");
	lx("tool.setAttr xfrm.rotate angle {$WPmem[5]}");
	lx("tool.doApply");
	lx("tool.set xfrm.rotate off");	

	lx("tool.set xfrm.rotate on");
	lx("tool.reset");
	lx("tool.attr center.auto cenX 0");
	lx("tool.attr center.auto cenY 0");
	lx("tool.attr center.auto cenZ 0");
	lx("tool.attr axis.auto axis 0");
	lx("tool.setAttr xfrm.rotate angle {$WPmem[3]}");
	lx("tool.doApply");
	lx("tool.set xfrm.rotate off");

	lx("tool.set xfrm.rotate on");
	lx("tool.reset");
	lx("tool.attr center.auto cenX 0");
	lx("tool.attr center.auto cenY 0");
	lx("tool.attr center.auto cenZ 0");
	lx("tool.attr axis.auto axis 1");
	lx("tool.setAttr xfrm.rotate angle {$WPmem[4]}");
	lx("tool.doApply");
	lx("tool.set xfrm.rotate off");

	$_ *= -1 for @WPmem;

	lx("!!item.channel pos.X {$WPmem[0]} set {$mainlayerID}");
	lx("!!item.channel pos.Y {$WPmem[1]} set {$mainlayerID}");
	lx("!!item.channel pos.Z {$WPmem[2]} set {$mainlayerID}");
	lx("!!item.channel rot.X {$WPmem[3]} set {$mainlayerID}");
	lx("!!item.channel rot.Y {$WPmem[4]} set {$mainlayerID}");
	lx("!!item.channel rot.Z {$WPmem[5]} set {$mainlayerID}");
}

#hides selected meshes,meshInsts,triSurfs
sub hide{
	my @selection = lxq("query sceneservice selection ? all");
	my %itemFilterTable;
			$itemFilterTable{mesh} = 1;
			$itemFilterTable{meshInst} = 1;
			$itemFilterTable{triSurf} = 1;
			$itemFilterTable{groupLocator} = 1;
			$itemFilterTable{locator} = 1;
			$itemFilterTable{light} = 1;
			$itemFilterTable{areaLight} = 1;
			$itemFilterTable{cylinderLight} = 1;
			$itemFilterTable{domeLight} = 1;
			$itemFilterTable{photometryLight} = 1;
			$itemFilterTable{pointLight} = 1;
			$itemFilterTable{spotLight} = 1;
			$itemFilterTable{sunLight} = 1;
			$itemFilterTable{portal} = 1;
			$itemFilterTable{camera} = 1;

	foreach my $id (@selection){
		if ($itemFilterTable{lxq("query sceneservice item.type ? {$id}")} == 1){
			lx("layer.setVisibility item:{$id} visible:{0} recur:{0}");
		}
	}
}

#does an instance command, only forces meshInsts to NOT be instances of instances or else you run into all sorts of problems.
sub instance{
	my @selection = lxq("query sceneservice selection ? all");
	my @nonInstances;
	my @instancesToSelect;

	foreach my $id (@selection){
		if ( (lxq("query sceneservice item.type ? {$id}") eq "meshInst") || (lxq("query sceneservice item.type ? {$id}") eq "proxy") ){
			my $sourceID = findMeshInstSource($id);
			lxout("sourceID = $sourceID");

			my $visibility = lxq("layer.setVisibility {$id} ?");
			my $bboxState = lxq("!!item.channel drawShape {?} set {$id}");
			my $parent = lxq("query sceneservice item.parent ? {$id}");
			my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$id}");
			my $rotXfrmID = lxq("query sceneservice item.xfrmRot ? {$id}");
			my $sclXfrmID = lxq("query sceneservice item.xfrmScl ? {$id}");
			my $rotOrder = lxq("!!item.channel order {?} set {$rotXfrmID}");

			#create transforms if missing
			if ($posXfrmID eq ""){lx("!!transform.add type:{pos} item:{$id}");}
			if ($rotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$id}");}
			if ($sclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$id}");}
			
			#query transforms
			my $xPos = lxq("!!item.channel pos.X {?} set {$id}");
			my $yPos = lxq("!!item.channel pos.Y {?} set {$id}");
			my $zPos = lxq("!!item.channel pos.Z {?} set {$id}");
			my $xRot = lxq("!!item.channel rot.X {?} set {$id}");
			my $yRot = lxq("!!item.channel rot.Y {?} set {$id}");
			my $zRot = lxq("!!item.channel rot.Z {?} set {$id}");
			my $xScl = lxq("!!item.channel scl.X {?} set {$id}");
			my $yScl = lxq("!!item.channel scl.Y {?} set {$id}");
			my $zScl = lxq("!!item.channel scl.Z {?} set {$id}");

			#dupe original item and give back transforms and parent
			lx("!!select.item {$sourceID} set");
			lx("!!item.duplicate instance:[true] type:[locator] all:[true] mods:[true]");
			my $newID = getNewItemID();

			my $newPosXfrmID = lxq("query sceneservice item.xfrmPos ? {$newID}");
			my $newRotXfrmID = lxq("query sceneservice item.xfrmRot ? {$newID}");
			my $newSclXfrmID = lxq("query sceneservice item.xfrmScl ? {$newID}");

			if ($newPosXfrmID eq ""){lx("!!transform.add type:{pos} item:{$newID}");}
			if ($newRotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$newID}");}
			if ($newSclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$newID}");}

			#fix or force rotation order
			$newRotXfrmID = lxq("query sceneservice item.xfrmRot ? {$newID}");
			if (lxq("user.value sene_unrealRotOrder ?") == 1)	{	lx("!!item.channel order {xyz} set {$newRotXfrmID}");		}
			else												{	lx("!!item.channel order {$rotOrder} set {$newRotXfrmID}");	}
			
			#resume setting transform channels
			lx("!!item.channel pos.X {$xPos} set {$newID}");
			lx("!!item.channel pos.Y {$yPos} set {$newID}");
			lx("!!item.channel pos.Z {$zPos} set {$newID}");
			lx("!!item.channel rot.X {$xRot} set {$newID}");
			lx("!!item.channel rot.Y {$yRot} set {$newID}");
			lx("!!item.channel rot.Z {$zRot} set {$newID}");
			lx("!!item.channel scl.X {$xScl} set {$newID}");
			lx("!!item.channel scl.Y {$yScl} set {$newID}");
			lx("!!item.channel scl.Z {$zScl} set {$newID}");
			if ($parent ne ""){lx("!!item.parent item:{$newID} parent:{$parent} inPlace:{0}");}
			lx("!!layer.setVisibility {$newID} {$visibility}");
			lx("!!item.channel drawShape {$bboxState} set {$newID}");

			#add instance to selection array
			push(@instancesToSelect,$newID);
		}else{
			push(@nonInstances,$id);
		}
	}

	#instance non-instances (only meshes and trisurfs)
	foreach my $id (@nonInstances){
		my $type = lxq("query sceneservice item.type ? {$id}");
		if ( ($type ne "mesh") && ($type ne "triSurf") ){next;}
		lx("!!select.subItem {$id} set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;deform.wrap;softLag;ABCdeform.sample;chanModify;chanEffect;defaultShader;defaultShader 0 0");
		lx("!!item.duplicate instance:[true] type:[locator] all:[true] mods:[true]");
		my $newID = getNewItemID();
		push(@instancesToSelect,$newID);
		
		#force XYZ rot order for unreal meshes
		if (lxq("user.value sene_unrealRotOrder ?") == 1){
			my $newRotXfrmID = lxq("query sceneservice item.xfrmRot ? {$newID}");
			if ($newRotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$newID}");}
			$newRotXfrmID = lxq("query sceneservice item.xfrmRot ? {$newID}");
			lx("!!item.channel order {xyz} set {$newRotXfrmID}");
		}
	}

	#restore selection
	lx("select.drop item");
	lx("!!select.item {$_} add") for @instancesToSelect;
}

#junk subroutine to run after you instance a mesh to return the new id
sub getNewItemID{
	my @meshInsts = lxq("query sceneservice selection ? meshInst");
	my @triSurfs = lxq("query sceneservice selection ? triSurf");
	my @proxies = lxq("query sceneservice selection ? proxy");
	
	if		(@meshInsts > 0)	{	return $meshInsts[-1];	}
	elsif	(@triSurfs > 0)		{	return $triSurfs[-1];	}
	elsif	(@proxies > 0)		{	return $proxies[-1];	}
	else						{	die("GETNEWITEMID sub : you just instanced an item but it didn't generate a mesh instance or proxy item so something doesn't seem right.  canceling script");	}
}


#go through all instances and make them NOT be instances of instances
sub makeInstsUnique{
	my $itemCount = lxq("query sceneservice item.n ? all");
	my %itemsToReplace;

	#find instances of instances
	for (my $i=0; $i<$itemCount; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "meshInst"){
			my $id = lxq("query sceneservice item.id ? $i");
			my $fakeSource = lxq("query sceneservice item.source ? {$id}");
			my $trueSource = findMeshInstSource($id);
			if ($fakeSource ne $trueSource){
				lxout("id = $id");
				$itemsToReplace{$id} = $trueSource;
			}
		}
	}

	#go through and build new instances
	foreach my $id (keys %itemsToReplace){
		my $visibility = lxq("layer.setVisibility {$id} ?");
		my $parent = lxq("query sceneservice item.parent ? {$id}");
		my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$id}");
		my $rotXfrmID = lxq("query sceneservice item.xfrmRot ? {$id}");
		my $sclXfrmID = lxq("query sceneservice item.xfrmScl ? {$id}");

		#create transforms if missing
		if ($posXfrmID eq ""){lx("!!transform.add type:{pos} item:{$id}");}
		if ($rotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$id}");}
		if ($sclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$id}");}

		#query transforms
		my $xPos = lxq("!!item.channel pos.X {?} set {$id}");
		my $yPos = lxq("!!item.channel pos.Y {?} set {$id}");
		my $zPos = lxq("!!item.channel pos.Z {?} set {$id}");
		my $xRot = lxq("!!item.channel rot.X {?} set {$id}");
		my $yRot = lxq("!!item.channel rot.Y {?} set {$id}");
		my $zRot = lxq("!!item.channel rot.Z {?} set {$id}");
		my $xScl = lxq("!!item.channel scl.X {?} set {$id}");
		my $yScl = lxq("!!item.channel scl.Y {?} set {$id}");
		my $zScl = lxq("!!item.channel scl.Z {?} set {$id}");

		#dupe original item and give back transforms and parent
		lx("!!select.item {$itemsToReplace{$id}} set");
		lx("!!item.duplicate instance:[1] type:[locator]");
		my @meshInsts = lxq("query sceneservice selection ? meshInst");

		my $newPosXfrmID = lxq("query sceneservice item.xfrmPos ? {$meshInsts[0]}");
		my $newRotXfrmID = lxq("query sceneservice item.xfrmRot ? {$meshInsts[0]}");
		my $newSclXfrmID = lxq("query sceneservice item.xfrmScl ? {$meshInsts[0]}");

		if ($newPosXfrmID eq ""){lx("!!transform.add type:{pos} item:{$meshInsts[0]}");}
		if ($newRotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$meshInsts[0]}");}
		if ($newSclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$meshInsts[0]}");}

		lx("!!item.channel pos.X {$xPos} set {$meshInsts[0]}");
		lx("!!item.channel pos.Y {$yPos} set {$meshInsts[0]}");
		lx("!!item.channel pos.Z {$zPos} set {$meshInsts[0]}");
		lx("!!item.channel rot.X {$xRot} set {$meshInsts[0]}");
		lx("!!item.channel rot.Y {$yRot} set {$meshInsts[0]}");
		lx("!!item.channel rot.Z {$zRot} set {$meshInsts[0]}");
		lx("!!item.channel scl.X {$xScl} set {$meshInsts[0]}");
		lx("!!item.channel scl.Y {$yScl} set {$meshInsts[0]}");
		lx("!!item.channel scl.Z {$zScl} set {$meshInsts[0]}");
		if ($parent ne ""){lx("!!item.parent item:{$meshInsts[0]} parent:{$parent} inPlace:{0}");}
		lx("!!layer.setVisibility {$meshInsts[-1]} {$visibility}");
	}

	#delete old instances
	if ((keys %itemsToReplace) > 0){
		lx("select.drop item");
		lx("select.item {$_} add") for (keys %itemsToReplace);
		lx("item.delete");
	}else{
		lxout("[->] : Couldn't find any instances of instances to replace.");
	}
}

#select itemes with same positions as other minus originals
sub selSamePos{
	my $itemCount = lxq("query sceneservice item.n ? all");
	my %itemFilterTable;
		$itemFilterTable{mesh} = 1;
		$itemFilterTable{meshInst} = 1;
		#$itemFilterTable{triSurf} = 1;

	my %itemPosTable;
	my $maxDistDiff = quickDialog("max position difference",float,1,0.00001,1000000000);

	for (my $i=0; $i<$itemCount; $i++){
		if ($itemFilterTable{lxq("query sceneservice item.type ? $i")} == 1){
			my $id = lxq("query sceneservice item.id ? $i");

			my @pos = ( int(lxq("!!item.channel pos.X {?} set {$id}")) , int(lxq("!!item.channel pos.Y {?} set {$id}")) , int(lxq("!!item.channel pos.Z {?} set {$id}")) );
			#my $xRot = lxq("!!item.channel rot.X {?} set {$id}");
			#my $yRot = lxq("!!item.channel rot.Y {?} set {$id}");
			#my $zRot = lxq("!!item.channel rot.Z {?} set {$id}");
			#my $xScl = lxq("!!item.channel scl.X {?} set {$id}");
			#my $yScl = lxq("!!item.channel scl.Y {?} set {$id}");
			#my $zScl = lxq("!!item.channel scl.Z {?} set {$id}");

			if (($pos[0] == 0) && ($pos[1] == 0) && ($pos[2] == 0)){
				lxout("ignoring $id because it's at 0,0,0");
				next;
			}

			my $foundSimilar = 0;
			foreach my $key (keys %itemPosTable){
				my @keyPos = split(/,/, $key);
				my @disp = arrMath(@pos,@keyPos,subt);
				my $fakeDisp = abs($disp[0]) + abs($disp[1]) + abs($disp[2]);
				if ($fakeDisp < $maxDistDiff){
					push(@{$itemPosTable{$key}},$id);
					$foundSimilar = 1;
					last;
				}
			}

			if ($foundSimilar == 0){
				my $string = $pos[0] .",". $pos[1] .",". $pos[2];  #.",". $xRot .",". $yRot .",". $zRot .",". $xScl .",". $yScl .",". $zScl;
				push(@{$itemPosTable{$string}},$id);
			}
		}
	}

	lx("select.drop item");
	foreach my $key (keys %itemPosTable){
		if (@{$itemPosTable{$key}} > 1){
			for (my $i=1; $i<@{$itemPosTable{$key}}; $i++){
				lx("select.subItem {@{$itemPosTable{$key}}[$i]} add mesh;meshInst;camera;light;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
			}
		}
	}
}

#flip item scale
sub flipScale{
	my $scaleAxis;
	if		($x == 1)	{$scaleAxis = "X";}
	elsif	($y == 1)	{$scaleAxis = "Y";}
	elsif	($z == 1)	{$scaleAxis = "Z";}

	#item mode
	if(lxq( "select.typeFrom {item;edge;vertex;polygon} ?" )){
		my %itemFilterTable;
			$itemFilterTable{mesh} = 1;
			$itemFilterTable{meshInst} = 1;
			$itemFilterTable{triSurf} = 1;
			$itemFilterTable{groupLocator} = 1;
			$itemFilterTable{locator} = 1;
			$itemFilterTable{light} = 1;
			$itemFilterTable{sunLight} = 1;
			$itemFilterTable{camera} = 1;

		my @selection = lxq("query sceneservice selection ? all");

		foreach my $id (@selection){
			if ($itemFilterTable{lxq("query sceneservice item.type ? {$id}")} == 1){
				my $sclXfrmID = lxq("query sceneservice item.xfrmScl ? {$id}");
				if ($sclXfrmID eq ""){lx("transform.add type:{scl} item:{$id}");}
				my $sclAmt = lxq("item.channel scl.$scaleAxis {?} set {$id}") * -1;
				lx("item.channel scl.$scaleAxis {$sclAmt} set {$id}");
			}
		}
	}
	#elem mode
	else{
		lx("tool.setAttr xfrm.transform S$scaleAxis -1");
		lx("tool.doApply");
		lx("poly.flip");
	}
}

#parent selected items to
sub parentToGroup{
	my @selection = lxq("query sceneservice selection ? all");
	my %nameTable;
	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=0; $i<$itemCount; $i++){
		if (lxq("query sceneservice item.type ? $i") eq "groupLocator"){
			$nameTable{lxq("query sceneservice item.name ? $i")} = lxq("query sceneservice item.id ? $i");
		}
	}

	my @keys = keys %nameTable;
	my @sortedKeys;
	sortTextAndNumberArray(\@sortedKeys,\@keys);
	my $popupDlgString;
	$popupDlgString .= $_ . ";" for (@sortedKeys);
	$popupDlgString =~ s/\;$//;

	my $answer = popupMultChoice("Parent to group:",$popupDlgString,0);
	foreach my $id (@selection){
		lx("!!item.parent item:{$id} parent:{$nameTable{$answer}} position:[-1] inPlace:{1}");
	}
}

#selects brothers with same type as currently selected items.
sub selSiblingsSameType{
	my @selection  = lxq("query sceneservice selection ? all");
	my %parents;
	my %types;
	foreach my $id (@selection){
		$parents{lxq("query sceneservice item.parent ? {$id}")} = 1;
		$types{lxq("query sceneservice item.type ? {$id}")} = 1;
	}
	foreach my $parent (keys %parents){
		my @children = lxq("query sceneservice item.children ? {$parent}");
		foreach my $id (@children){
			if ($types{lxq("query sceneservice item.type ? {$id}")} == 1){
				lx("select.subItem {$id} add mesh;meshInst;camera;light;backdrop;groupLocator;replicator;surfGen;locator;deform;locdeform;deformGroup;deformMDD2;morphDeform;itemInfluence;genInfluence;softDeform;ABCdeform.sample;chanModify;chanEffect 0 0");
			}
		}
	}
}


#deletes empty meshes and groups.  (if mesh has children, won't delete so youd have to run it twice)
sub delEmptyMshsNGrps{
	lx("!!select.drop item");
	lx("!!select.itemType mesh");
	my @meshSel = lxq("query sceneservice selection ? mesh");

	foreach my $id (@meshSel){
		my $layerName = lxq("query layerservice layer.name ? {$id}");
		my $vertCount = lxq("query layerservice vert.n ? all");
		if ($vertCount == 0){
			my $childCount = lxq("query sceneservice item.numChildren ? {$id}");
			if ($childCount == 0){
				lx("select.item {$id} set");
				lx("item.delete");
			}else{
				lxout("--couldn't delete '$layerName' ($id) because it had children");
			}
		}
	}

	lx("!!select.drop item");
	lx("!!select.itemType groupLocator");
	my @groupSel = lxq("query sceneservice selection ? groupLocator");

	foreach my $id (@groupSel){
		my $childCount = lxq("query sceneservice item.numChildren ? {$id}");
		if ($childCount == 0){
			lx("select.item {$id} set") or next;
			lx("item.delete");
		}else{
			my $name = lxq("query sceneservice item.name ? {$id}");
			lxout("--couldn't delete '$name' ($id) because it had children");
		}
	}
}


#convert meshes to instances and apply a random part name to each.
sub cnvInstToMeshWPart{
	my %itemTypes;
		$itemTypes{"mesh"} = 1;
		$itemTypes{"meshInst"} = 1;

	my @selection = lxq("query sceneservice selection ? all");

	foreach my $id (@selection){
		if		(lxq("query sceneservice item.type ? {$id}") eq "mesh"){
			lx("select.item {$id} set");
		}elsif	(lxq("query sceneservice item.type ? {$id}") eq "meshInst"){
			lx("select.item {$id} set");
			lx("item.setType mesh locator");
		}

		my $partName = "";
		my @alphabet = (0,1,2,3,4,5,6,7,8,9,0,"a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z");
		for (my $i=0; $i<12; $i++){$partName .= @alphabet[rand(35)];}
		lxout("partName = $partName");
		lx("!!select.type polygon");
		lx("!!poly.setPart {$partName}");
	}
}


#ignoring pivot, rot order and mult transforms. (piv queries fail, the others are just laziness)
sub replaceInstances{
	my %itemTypes;
		$itemTypes{"mesh"} = 1;
		$itemTypes{"meshInst"} = 1;
		$itemTypes{"triSurf"} = 1;

	my @completeSelection = lxq("query sceneservice selection ? all");
	my @selection;
	my $foundMeshID = "";
	my $chosenItemType = "mesh";
	my @groupMembers;
	my $groupOrder;
	my $groupIndice;

	#create list of only meshes and meshinstances and static meshes.
	foreach my $id (@completeSelection){
		my $type = lxq("query sceneservice item.type ? {$id}");
		if (($type eq "mesh") || ($type eq "meshInst") || ($type eq "triSurf")){
			push(@selection,$id);
		}
	}

	#find source mesh : option 1 : use gui
	if ($gui == 1){
		my %meshTable;
		my $guiTextLine;
		my $itemCount = lxq("query sceneservice item.n ? all");
		my @instances = lxq("query sceneservice selection ? meshInst");
		my @newMeshInstances;
		my $sourceMeshID = findMeshInstSource($instances[-1]) or die("No mesh instances selected, so I'm cancelling the script.");
		my $defaultChoiceInt;

		my %itemTypes;
			$itemTypes{"mesh"} = 1;
			$itemTypes{"group"} = 1;
			$itemTypes{"triSurf"} = 1;

		for (my $i=0; $i<$itemCount; $i++){
			if ($itemTypes{lxq("query sceneservice item.type ? $i")} == 1){
				my $name = lxq("query sceneservice item.name ? $i");
				my $id = lxq("query sceneservice item.id ? $i");
				$meshTable{$name} = $id;
			}
		}
		foreach my $key (sort keys %meshTable){$guiTextLine .= $key . ";";}

		my $counter = 0;
		foreach my $key (sort keys %meshTable){
			if ($meshTable{$key} eq $sourceMeshID){
				$defaultChoiceInt = $counter;
			}
			$counter++;
		}

		#pull up gui to request which mesh (or group) to use.
		$guiTextLine =~ s/\;$//;
		my $answer = popupMultChoice("replace instances with:",$guiTextLine,$defaultChoiceInt);
		$foundMeshID = $meshTable{$answer};

		#if a group was chosen, build a list of meshIDs from it.
		if (lxq("query sceneservice item.type ? {$foundMeshID}") eq "group"){
			$chosenItemType = "group";
			lx("group.scan item:{$foundMeshID}");
			@groupMembers = lxq("query sceneservice selection ? mesh");
			if (@groupMembers < 1){die("You chose to replace your instances with the contents of a GROUP, but that group didn't have any meshes in it and so I'm cancelling the script");}

			#query whether to use items in order or random
			$groupOrder = popupMultChoice("Use the group's meshes in this order:","Random;Sequentially",0);
		}
	}
	
	#find source mesh : option 3 : use first selected mesh
	else{
		if (lxq("query sceneservice item.type ? {$selection[0]}") eq "mesh"){
			$foundMeshID = $selection[0];
		}else{
			$foundMeshID = findMeshInstSource($selection[0]);
		}
	}

	#go through all other selected meshes and replace them with first found mesh.
	foreach my $id (@selection){
		if (lxq("query sceneservice item.type ? {$id}") eq "meshInst"){

			my $visibility = lxq("layer.setVisibility {$id} ?");
			my $parent = lxq("query sceneservice item.parent ? {$id}");
			my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$id}");
			my $rotXfrmID = lxq("query sceneservice item.xfrmRot ? {$id}");
			my $sclXfrmID = lxq("query sceneservice item.xfrmScl ? {$id}");

			#create transforms if missing
			if ($posXfrmID eq ""){lx("!!transform.add type:{pos} item:{$id}");}
			if ($rotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$id}");}
			if ($sclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$id}");}

			#query transforms
			my $xPos = lxq("item.channel pos.X {?} set {$id}");
			my $yPos = lxq("item.channel pos.Y {?} set {$id}");
			my $zPos = lxq("item.channel pos.Z {?} set {$id}");
			my $xRot = lxq("item.channel rot.X {?} set {$id}");
			my $yRot = lxq("item.channel rot.Y {?} set {$id}");
			my $zRot = lxq("item.channel rot.Z {?} set {$id}");
			my $xScl = lxq("item.channel scl.X {?} set {$id}");
			my $yScl = lxq("item.channel scl.Y {?} set {$id}");
			my $zScl = lxq("item.channel scl.Z {?} set {$id}");
			my $rotOrder = lxq("item.channel order {?} set {$rotXfrmID}");

			#query bbox state
			my $bboxVisibility = lxq("!!item.channel drawShape {?} set {$id}");


			#groups : pick which mesh is next to be replaced by.
			if ($chosenItemType eq "group"){
				if ($groupOrder eq "Random"){
					$foundMeshID = $groupMembers[rand($#groupMembers+.5)];
				}else{
					$foundMeshID = $groupMembers[$groupIndice++];
					if ($groupIndice > $#groupMembers){$groupIndice = 0;}
				}
			}

			#dupe original item and give back transforms and parent
			lx("!!select.item {$foundMeshID} set");
			lx("!!item.duplicate instance:[1] type:[locator]");
			my @meshInsts = lxq("query sceneservice selection ? meshInst");
			push(@newMeshInstances,$meshInsts[-1]);

			my $newPosXfrmID = lxq("query sceneservice item.xfrmPos ? {$meshInsts[0]}");
			my $newRotXfrmID = lxq("query sceneservice item.xfrmRot ? {$meshInsts[0]}");
			my $newSclXfrmID = lxq("query sceneservice item.xfrmScl ? {$meshInsts[0]}");

			if ($newPosXfrmID eq ""){lx("!!transform.add type:{pos} item:{$meshInsts[0]}");	$newPosXfrmID = lxq("query sceneservice item.xfrmPos ? {$meshInsts[0]}");	}
			if ($newRotXfrmID eq ""){lx("!!transform.add type:{rot} item:{$meshInsts[0]}");	$newRotXfrmID = lxq("query sceneservice item.xfrmRot ? {$meshInsts[0]}");	}
			if ($newSclXfrmID eq ""){lx("!!transform.add type:{scl} item:{$meshInsts[0]}");	$newSclXfrmID = lxq("query sceneservice item.xfrmScl ? {$meshInsts[0]}");	}

			lx("!!item.channel pos.X {$xPos} set {$meshInsts[0]}");
			lx("!!item.channel pos.Y {$yPos} set {$meshInsts[0]}");
			lx("!!item.channel pos.Z {$zPos} set {$meshInsts[0]}");
			lx("!!item.channel rot.X {$xRot} set {$meshInsts[0]}");
			lx("!!item.channel rot.Y {$yRot} set {$meshInsts[0]}");
			lx("!!item.channel rot.Z {$zRot} set {$meshInsts[0]}");
			lx("!!item.channel scl.X {$xScl} set {$meshInsts[0]}");
			lx("!!item.channel scl.Y {$yScl} set {$meshInsts[0]}");
			lx("!!item.channel scl.Z {$zScl} set {$meshInsts[0]}");
			lx("!!item.channel order {$rotOrder} set {$newRotXfrmID}");
			lx("!!item.channel drawShape {$bboxVisibility} set {$meshInsts[0]}");
			if ($parent ne ""){lx("!!item.parent item:{$meshInsts[0]} parent:{$parent} inPlace:{0}");}
			lx("!!layer.setVisibility {$meshInsts[-1]} {$visibility}");

			#delete old item.
			lx("!!select.item {$id} set");
			lx("!!item.delete");
		}
	}

	lx("!!select.drop item");
	lx("!!select.item {$_} add") for @newMeshInstances;
}


sub rectifyItemXfrms{
	my %itemTypes;
		$itemTypes{"mesh"} = 1;
		$itemTypes{"meshInst"} = 1;
		$itemTypes{"groupLocator"} = 1;

	#force all items to have pos,rot,scl channels
	my @selection = lxq("query sceneservice selection ? all");
	foreach my $id (@selection){
		if ($itemTypes{lxq("query sceneservice item.type ? {$id}")} == 1){
			if (lxq("query sceneservice item.xfrmPos ? {$id}") eq "")	{	lxout("eh? pos");	lx("transform.add type:pos item:{$id}");	}
			if (lxq("query sceneservice item.xfrmRot ? {$id}") eq "")	{	lxout("eh? rot");	lx("transform.add type:rot item:{$id}");	}
			if (lxq("query sceneservice item.xfrmScl ? {$id}") eq "")	{	lxout("eh? scl");	lx("transform.add type:scl item:{$id}");	}
		}
	}

	#force overwrite all translation channels in each instance
	foreach my $id (@selection){
		if (lxq("query sceneservice item.type ? {$id}") eq "meshInst"){
			my $itemName = lxq("query sceneservice item.name ? {$id}");
			my $id_xfrmPos = lxq("query sceneservice item.xfrmPos ? {$id}");
			my $id_xfrmRot = lxq("query sceneservice item.xfrmRot ? {$id}");
			my $id_xfrmScl = lxq("query sceneservice item.xfrmScl ? {$id}");

			my $posX = lxq("item.channel pos.X {?} set {$id_xfrmPos}");
			my $posY = lxq("item.channel pos.Y {?} set {$id_xfrmPos}");
			my $posZ = lxq("item.channel pos.Z {?} set {$id_xfrmPos}");

			my $rotX = lxq("item.channel rot.X {?} set {$id_xfrmRot}");
			my $rotY = lxq("item.channel rot.Y {?} set {$id_xfrmRot}");
			my $rotZ = lxq("item.channel rot.Z {?} set {$id_xfrmRot}");

			my $sclX = lxq("item.channel scl.X {?} set {$id_xfrmScl}");
			my $sclY = lxq("item.channel scl.Y {?} set {$id_xfrmScl}");
			my $sclZ = lxq("item.channel scl.Z {?} set {$id_xfrmScl}");

			my $posXTemp = $posX + 1;
			my $posYTemp = $posY + 1;
			my $posZTemp = $posZ + 1;

			my $rotXTemp = $rotX + 1;
			my $rotYTemp = $rotY + 1;
			my $rotZTemp = $rotZ + 1;

			my $sclXTemp = $sclX + 1;
			my $sclYTemp = $sclY + 1;
			my $sclZTemp = $sclZ + 1;

			lx("item.channel pos.X {$posXTemp} set {$id_xfrmPos}");
			lx("item.channel pos.Y {$posYTemp} set {$id_xfrmPos}");
			lx("item.channel pos.Z {$posZTemp} set {$id_xfrmPos}");

			lx("item.channel rot.X {$rotXTemp} set {$id_xfrmRot}");
			lx("item.channel rot.Y {$rotYTemp} set {$id_xfrmRot}");
			lx("item.channel rot.Z {$rotZTemp} set {$id_xfrmRot}");

			lx("item.channel scl.X {$sclXTemp} set {$id_xfrmScl}");
			lx("item.channel scl.Y {$sclYTemp} set {$id_xfrmScl}");
			lx("item.channel scl.Z {$sclZTemp} set {$id_xfrmScl}");

			lx("item.channel pos.X {$posX} set {$id_xfrmPos}");
			lx("item.channel pos.Y {$posY} set {$id_xfrmPos}");
			lx("item.channel pos.Z {$posZ} set {$id_xfrmPos}");

			lx("item.channel rot.X {$rotX} set {$id_xfrmRot}");
			lx("item.channel rot.Y {$rotY} set {$id_xfrmRot}");
			lx("item.channel rot.Z {$rotZ} set {$id_xfrmRot}");

			lx("item.channel scl.X {$sclX} set {$id_xfrmScl}");
			lx("item.channel scl.Y {$sclY} set {$id_xfrmScl}");
			lx("item.channel scl.Z {$sclZ} set {$id_xfrmScl}");
		}
	}
}

#move selected object to mouse position. (only works when mouse is over a mesh)
sub moveToMousePos{
	my %itemFilterTable;
		$itemFilterTable{mesh} = 1;
		$itemFilterTable{meshInst} = 1;
		$itemFilterTable{triSurf} = 1;
		$itemFilterTable{groupLocator} = 1;
		$itemFilterTable{locator} = 1;
		$itemFilterTable{light} = 1;
		$itemFilterTable{sunLight} = 1;
		$itemFilterTable{camera} = 1;

	#Remember what the workplane was
	my @WPmem;
	@WPmem[0] = lxq ("workPlane.edit cenX:? ");
	@WPmem[1] = lxq ("workPlane.edit cenY:? ");
	@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
	@WPmem[3] = lxq ("workPlane.edit rotX:? ");
	@WPmem[4] = lxq ("workPlane.edit rotY:? ");
	@WPmem[5] = lxq ("workPlane.edit rotZ:? ");

	lx("!!workPlane.fitGeometry");
	my $posX = lxq ("workPlane.edit cenX:? ");
	my $posY = lxq ("workPlane.edit cenY:? ");
	my $posZ = lxq ("workPlane.edit cenZ:? ");

	my @selection = lxq("query sceneservice selection ? all");
	for (my $i=0; $i<@selection; $i++){
		my $type = lxq("query sceneservice item.type ? {$selection[$i]}");
		if ($itemFilterTable{$type} == 1){
			my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$selection[$i]}");
			if ($posXfrmID eq ""){lx("transform.add type:{pos} item:{$selection[$i]}");}
			if ($y == 0)	{	lx("item.channel pos.X {$posX} set {$selection[$i]}");	}
								lx("item.channel pos.Y {$posY} set {$selection[$i]}");
			if ($y == 0)	{	lx("item.channel pos.Z {$posZ} set {$selection[$i]}");	}
		}
	}

	lx("workplane.reset");
	lx("workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");
}

#move selected objects into a straight line from origin.
sub moveToLine{
	my %itemFilterTable;
		$itemFilterTable{mesh} = 1;
		$itemFilterTable{meshInst} = 1;
		$itemFilterTable{triSurf} = 1;

	my $frcAlphOrder = quickDialog("force alphabetical order?",yesNo,1,"","");
	my $offset = quickDialog("space inbetween meshes",float,64,0,1000000000000);
	my $answer = popupMultChoice("Create line along which axis","X;Y;Z",0);
	if		($answer eq "X")	{our $answerIndex = 0;}
	elsif	($answer eq "Y")	{our $answerIndex = 1;}
	elsif	($answer eq "Z")	{our $answerIndex = 2;}

	my @selection = lxq("query sceneservice selection ? all");
	if ($frcAlphOrder eq "ok"){
		my %nameTable;
		foreach my $id (@selection){$nameTable{lxq("query sceneservice item.name ? {$id}")} = $id;}
		my @keys = (keys %nameTable);
		sortTextAndNumberArray(\@sortedKeys,\@keys);
		@selection = ();
		foreach my $key (@sortedKeys){push(@selection,$nameTable{$key});}
	}
	my @currentOffset = (0,0,0);

	foreach my $id (@selection){
		my $type = lxq("query sceneservice item.type ? {$id}");
		if ($itemFilterTable{$type} == 1){
			my $layerIndice = lxq("query layerservice layer.index ? {$id}");
			if		($type eq "mesh"){
				our @bounds = lxq("query layerservice layer.bounds ? $layerIndice");
			}elsif	($type eq "meshInst"){
				my $sourceMeshID = findMeshInstSource($id) or die("$id is not a meshInst");
				our @bounds = lxq("query layerservice layer.bounds ? {$sourceMeshID}");
			}elsif	($type eq "triSurf"){
				our @bounds = lxq("query sceneservice item.bounds ? {$id}");
			}else{
				die("this type $type is not supported in this script");
			}
			my @bbox = ( $bounds[3]-$bounds[0] , $bounds[4]-$bounds[1] , $bounds[5]-$bounds[2] );
			$currentOffset[$answerIndex] += ($bbox[$answerIndex] * .5) + ($offset * .5);
			my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$id}");
			if ($posXfrmID eq ""){lx("transform.add type:{pos} item:{$id}");}
			lx("item.channel pos.$answer {$currentOffset[$answerIndex]} set {$id}");
			$currentOffset[$answerIndex] += ($bbox[$answerIndex] * .5) + ($offset * .5);
		}
	}
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																GENERAL SUBROUTINES																	  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#

#print the transforms of currently selected items in an idstudio compliant format.
sub printRagePos{
	my %itemFilterTable;
		$itemFilterTable{mesh} = 1;
		$itemFilterTable{meshInst} = 1;
		$itemFilterTable{triSurf} = 1;
		$itemFilterTable{groupLocator} = 1;
		$itemFilterTable{locator} = 1;
		$itemFilterTable{light} = 1;
		$itemFilterTable{sunLight} = 1;
		$itemFilterTable{camera} = 1;

	my @selection = lxq("query sceneservice selection ? all");
	foreach my $id (@selection){
		if ($itemFilterTable{lxq("query sceneservice item.type ? {$id}")} == 1){
			my $name = lxq("query sceneservice item.name ? {$id}");
			my $posXfrmID = lxq("query sceneservice item.xfrmPos ? {$id}");
			my $rotXfrmID = lxq("query sceneservice item.xfrmRot ? {$id}");
			my $sclXfrmID = lxq("query sceneservice item.xfrmScl ? {$id}");

			lxout("========================");
			if ($posXfrmID ne ""){
				my $posX = lxq("item.channel pos.X {?} set {$id}");
				my $posY = lxq("item.channel pos.Y {?} set {$id}");
				my $posZ = lxq("item.channel pos.Z {?} set {$id}") * -1;
				lxout("$name : pos = $posX $posZ $posY");
			}
			if ($rotXfrmID ne ""){
				my $rotX = lxq("item.channel rot.X {?} set {$id}");
				my $rotY = lxq("item.channel rot.Y {?} set {$id}");
				my $rotZ = lxq("item.channel rot.Z {?} set {$id}");
				lxout("$name : rot = $rotX $rotY $rotZ");
			}
			if ($sclXfrmID ne ""){
				my $sclX = lxq("item.channel scl.X {?} set {$id}");
				my $sclY = lxq("item.channel scl.Y {?} set {$id}");
				my $sclZ = lxq("item.channel scl.Z {?} set {$id}");
				lxout("$name : scl = $sclX $sclY $sclZ");
			}
		}
	}
}


##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#FILE DIALOG WINDOW SUB
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##USAGE : my @files = fileDialog("open"|"save","title","*.lxo;*.lwo;*.obj","lxo");
##0=open or save #1=title #2=loadExt #3=saveExt
sub fileDialog{
	if ($_[0] eq "open")	{	lx("dialog.setup fileOpenMulti");	}
	else					{	lx("dialog.setup fileSave");		}

	lx("dialog.title {$_[1]}");
	lx("dialog.fileTypeCustom format:[stp] username:[$_[1]] loadPattern:[$_[2]] saveExtension:[$_[3]]");
	lx("dialog.open");
	my @fileNames = lxq("dialog.result ?") or die("The file saver window was cancelled, so I'm cancelling the script.");
	return (@fileNames);
}


#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB v2.1 (modded to not die if user press no to yesno)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if ($_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {$_[0]}");
		lx("dialog.open");
		return (lxq("dialog.result ?"));
	}else{
		if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog") == 1){
			lx("user.defDelete seneTempDialog");
		}
		lx("user.defNew name:[seneTempDialog] type:{$_[1]} life:[momentary]");		
		lx("user.def seneTempDialog username [$_[0]]");
		if (($_[3] != "") && ($_[4] != "")){
			lx("user.def seneTempDialog min [$_[3]]");
			lx("user.def seneTempDialog max [$_[4]]");
		}
		lx("user.value seneTempDialog [$_[2]]");
		lx("user.value seneTempDialog ?");
		if (lxres != 0){	die("The user hit the cancel button");	}
		return(lxq("user.value seneTempDialog ?"));
	}
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

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#POPUP MULTIPLE CHOICE (ver 3) (forces return of your word choice because modo sometimes would return a number instead of word)
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#USAGE : my $answer = popupMultChoice("question name","yes;no;maybe;blahblah",$defaultChoiceInt);
sub popupMultChoice{
	if (lxq("query scriptsysservice userValue.isdefined ? seneTempDialog2") == 1){lx("user.defDelete {seneTempDialog2}");	}
	lx("user.defNew name:[seneTempDialog2] type:[integer] life:[momentary]");
	lx("user.def seneTempDialog2 username [$_[0]]");
	lx("user.def seneTempDialog2 list {$_[1]}");
	lx("user.value seneTempDialog2 {$_[2]}");

	lx("user.value seneTempDialog2");
	if (lxres != 0){	die("The user hit the cancel button");	}
	
	my $answer = lxq("user.value seneTempDialog2 ?");
	if ($answer =~ /[^0-9]/){
		return($answer);
	}else{
		my @guiTextArray = split (/\;/, $_[1]);
		return($guiTextArray[$answer]);
	}
}

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#SORT TEXT ARRAY THAT HAS NUMBERS IN TEXT (tye_from_perlmonks)
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#usage : sortTextAndNumberArray(\@sortedArray,\@originalArray);
sub sortTextAndNumberArray{
	@{$_[0]} = @{$_[1]}[
		map { unpack "N", substr($_,-4) }
		sort
		map {
			my $key = ${$_[1]}[$_];
			$key =~ s[(\d+)][ pack "N", $1 ]ge;
			$key . pack "N", $_
		} 0..$#{$_[1]}
	];
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																MODO SUBROUTINES																	  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
##PAD SCALE sub : pads the objects' current scales by a certain volume
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub padScale{
	my @bounds = queryBounds($_[0]);
	my @meshSize = ( $bounds[3]-$bounds[0] , $bounds[4]-$bounds[1] , $bounds[5]-$bounds[2] );
	
	my $xfrm_scaleX = lxq("item.channel scl.X {?} set {$_[0]}");
	my $xfrm_scaleY = lxq("item.channel scl.Y {?} set {$_[0]}");
	my $xfrm_scaleZ = lxq("item.channel scl.Z {?} set {$_[0]}");
	
	my $finalSizeX;
	my $finalSizeY;
	my $finalSizeZ;
	
	if ($xfrm_scaleX >= 0)	{	$finalSizeX = $meshSize[0] * $xfrm_scaleX + $padAmt;	}
	else					{	$finalSizeX = $meshSize[0] * $xfrm_scaleX - $padAmt;	}
	if ($xfrm_scaleY >= 0)	{	$finalSizeY = $meshSize[1] * $xfrm_scaleY + $padAmt;	}
	else					{	$finalSizeY = $meshSize[1] * $xfrm_scaleY - $padAmt;	}
	if ($xfrm_scaleZ >= 0)	{	$finalSizeZ = $meshSize[2] * $xfrm_scaleZ + $padAmt;	}
	else					{	$finalSizeZ = $meshSize[2] * $xfrm_scaleZ - $padAmt;	}
	
	my $scaleAmtX = $finalSizeX / $meshSize[0];
	my $scaleAmtY = $finalSizeY / $meshSize[1];
	my $scaleAmtZ = $finalSizeZ / $meshSize[2];
	
	if ($axisFilter =~ /x/i)	{	lx("item.channel scl.X {$scaleAmtX} set {$_[0]}");	}
	if ($axisFilter =~ /y/i)	{	lx("item.channel scl.Y {$scaleAmtY} set {$_[0]}");	}
	if ($axisFilter =~ /z/i)	{	lx("item.channel scl.Z {$scaleAmtZ} set {$_[0]}");	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
##QUERY BOUNDS sub : temp sub to be able to query bounds so meshes, meshinsts, trisurfs, and trisurf instances
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub queryBounds{
	my $id = $_[0];
	my @bounds;
	my $type = lxq("query sceneservice item.type ? {$id}");
	if ($type eq "meshInst"){
		$id = findMeshInstSource($id) or die("$item is not a meshInst");
		$type = lxq("query sceneservice item.type ? {$id}");
	}
	
	if ($type eq "mesh")		{	return (lxq("query layerservice layer.bounds ? {$id}"));										}
	elsif ($type eq "triSurf")	{	return (lxq("query sceneservice item.bounds ? {$id}"));											}
	else						{	die("queryBounds sub : This mesh source is not a mesh or triSurf so i'm canceling the script");	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
##VERIFYSCLXFRM sub : makes sure a scale xfrm exists on the item
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub verifySclXfrm{
	my $sclXfrmID = lxq("query sceneservice item.xfrmScl ? {$_[0]}");
	if ($sclXfrmID eq "")	{	lx("!!transform.add type:{scl} item:{$_[0]}");	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE TEXT LOCATOR ITEM (v2)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : createTextLoc($x,$y,$z,$text,$locSize);
sub createTextLoc{
	lx("item.create locator");
	my @locatorSelection = lxq("query sceneservice selection ? locator");
	lx("transform.channel pos.X {$_[0]}");
	lx("transform.channel pos.Y {$_[1]}");
	lx("transform.channel pos.Z {$_[2]}");

	lx("!!item.name item:{$locatorSelection[-1]} name:{$_[3]}");
	lx("!!item.help add label {$_[3]}");
	lx("!!item.channel size {$_[4]} set {$locatorSelection[-1]}");
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CREATE AXIS WEDGE FROM MATRIX (works on 3x3 and 4x4)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : createAxisWedge(\@matrix);
sub createAxisWedge{
	my $matrix = $_[0];
	my @offset = (0,0,0);
	if (@$matrix == 4){	@offset = ($$matrix[0][3] , $$matrix[1][3] , $$matrix[2][3]);	}
	my @pos1 = ($$matrix[0][0]+$offset[0] , $$matrix[0][1]+$offset[1] , $$matrix[0][2]+$offset[2]);
	my @pos2 = ($$matrix[1][0]+$offset[0] , $$matrix[1][1]+$offset[1] , $$matrix[1][2]+$offset[2]);
	my @pos3 = ($$matrix[2][0]+$offset[0] , $$matrix[2][1]+$offset[1] , $$matrix[2][2]+$offset[2]);

	lx("!!vert.new $offset[0] $offset[1] $offset[2]");
	lx("!!vert.new $pos1[0] $pos1[1] $pos1[2]");
	lx("!!vert.new $pos2[0] $pos2[1] $pos2[2]");
	lx("!!vert.new $pos3[0] $pos3[1] $pos3[2]");

	my $vertCount = lxq("query layerservice vert.n ? all");
	my $vert1 = $vertCount - 4;
	my $vert2 = $vertCount - 3;
	my $vert3 = $vertCount - 2;
	my $vert4 = $vertCount - 1;

	lx("select.type vertex");
	lx("select.element $mainlayer vertex set $vert1");
	lx("select.element $mainlayer vertex add $vert2");
	lx("select.element $mainlayer vertex add $vert3");
	lx("poly.makeFace");
	lx("select.element $mainlayer vertex set $vert1");
	lx("select.element $mainlayer vertex add $vert3");
	lx("select.element $mainlayer vertex add $vert4");
	lx("poly.makeFace");
	lx("select.element $mainlayer vertex set $vert1");
	lx("select.element $mainlayer vertex add $vert4");
	lx("select.element $mainlayer vertex add $vert2");
	lx("poly.makeFace");
}

#move item to rage world position
sub moveToRagePos{
	my %itemFilterTable;
		$itemFilterTable{mesh} = 1;
		$itemFilterTable{meshInst} = 1;
		$itemFilterTable{triSurf} = 1;
		$itemFilterTable{groupLocator} = 1;
		$itemFilterTable{locator} = 1;
		$itemFilterTable{light} = 1;
		$itemFilterTable{sunLight} = 1;
		$itemFilterTable{camera} = 1;


	my @selection = lxq("query sceneservice selection ? all");
	my $text = quickDialog("type in the idstudio position:",string,"100,200,300","","");
	my @pos = split(/,/, $text);
	my @newPos = ($pos[0], $pos[2], $pos[1] * -1);

	foreach my $item (@selection){
		my $type = lxq("query sceneservice item.type ? {$item}");
		if ($itemFilterTable{$type} == 1){
			my $xfrmPosID = lxq("query sceneservice item.xfrmPos ? {$item}");
			if ($xfrmPosID eq ""){lx("transform.add type:pos item:{$item}");}

			lx("item.channel pos.X {$newPos[0]} set {$item}");
			lx("item.channel pos.Y {$newPos[1]} set {$item}");
			lx("item.channel pos.Z {$newPos[2]} set {$item}");
		}
	}
}

#sub move item in screen space
sub moveScreen{
	my %itemFilterTable;
		$itemFilterTable{mesh} = 1;
		$itemFilterTable{meshInst} = 1;
		$itemFilterTable{triSurf} = 1;
		$itemFilterTable{groupLocator} = 1;
		$itemFilterTable{locator} = 1;
		$itemFilterTable{light} = 1;
		$itemFilterTable{sunLight} = 1;
		$itemFilterTable{camera} = 1;

	#find the grid numeric system
	if (lxq("pref.value units.system ?") eq "game")	{	our $power = 2;		}
	else											{	our $power = 10;	}

	#find viewport dir
	my $viewport = lxq("query view3dservice mouse.view ?");
	my @viewAxis = lxq("query view3dservice view.axis ? $viewport");
	my @frame = lxq("query view3dservice view.frame ?");
	my $scale = lxq("query view3dservice view.scale ? $viewport");
	my @viewBbox = lxq("query view3dservice view.rect ? $viewport");
	my @viewScale = (($scale * @viewBbox[2]),($scale * @viewBbox[3]));
	my @div = (($viewScale[0]/16),($viewScale[1]/16));
	my $log = int(.65 + (log(@div[0])/log($power)));
	my $grid = $power ** $log;

	#=============================
	#world axis
	#=============================

	#find primary axis
	my @xAxis = (1,0,0);
	my @yAxis = (0,1,0);
	my @zAxis = (0,0,1);
	my $dp0 = dotProduct(\@viewAxis,\@xAxis);
	my $dp1 = dotProduct(\@viewAxis,\@yAxis);
	my $dp2 = dotProduct(\@viewAxis,\@zAxis);
	if 		((abs($dp0) >= abs($dp1)) && (abs($dp0) >= abs($dp2)))	{	our $axis = 0;	lxout("[->] : Using world X axis");}
	elsif	((abs($dp1) >= abs($dp0)) && (abs($dp1) >= abs($dp2)))	{	our $axis = 1;	lxout("[->] : Using world Y axis");}
	else															{	our $axis = 2;	lxout("[->] : Using world Z axis");}

	#flip move pos if cam facing away from positive axis
	my @posChannelName = ("pos.X","pos.Y","pos.Z");
	if		($axis == 0)	{	our $axisViewDP = dotProduct(\@viewAxis,\@xAxis);	}
	elsif	($axis == 1)	{	our $axisViewDP = dotProduct(\@viewAxis,\@xAxis);	}
	elsif	($axis == 2)	{	our $axisViewDP = dotProduct(\@viewAxis,\@xAxis);	}
	if ($axisViewDP < 0)	{	$axisViewDP = -1;									}
	else					{	$axisViewDP = 1;									}

	#determine move amount scalar
	if		($small == 1)	{	our $moveScalar = .25;	}
	elsif	($large == 1)	{	our $moveScalar = 4;	}
	else					{	our $moveScalar = 1;	}

	my @selection = lxq("query sceneservice selection ? all");
	foreach my $id (@selection){
		my $type = lxq("query sceneservice item.type ? {$id}");
		if ($itemFilterTable{$type} == 1){
			my $xfrmPosID = lxq("query sceneservice item.xfrmPos ? {$id}");
			if ($xfrmPosID eq ""){lx("transform.add type:pos item:{$id}");}

			#move in world space
			if ($worldAxis == 1){
				my $axisPos = lxq("item.channel {$posChannelName[$axis]} {?} set {$id}");
				if ($miscArg eq "forward")	{	$axisPos += ($grid * $axisViewDP * $moveScalar);	}
				else						{	$axisPos -= ($grid * $axisViewDP * $moveScalar);	}
				lx("item.channel {$posChannelName[$axis]} {$axisPos} set {$id}");
			}
			#move in screen space
			else{
				my $axisPosX = lxq("item.channel pos.X {?} set {$id}");
				my $axisPosY = lxq("item.channel pos.Y {?} set {$id}");
				my $axisPosZ = lxq("item.channel pos.Z {?} set {$id}");

				if ($miscArg eq "forward"){
					our $newPosX = $axisPosX + ($viewAxis[0] * $grid * $moveScalar);
					our $newPosY = $axisPosY + ($viewAxis[1] * $grid * $moveScalar);
					our $newPosZ = $axisPosZ + ($viewAxis[2] * $grid * $moveScalar);
				}else{
					our $newPosX = $axisPosX - ($viewAxis[0] * $grid * $moveScalar);
					our $newPosY = $axisPosY - ($viewAxis[1] * $grid * $moveScalar);
					our $newPosZ = $axisPosZ - ($viewAxis[2] * $grid * $moveScalar);
				}

				lx("item.channel pos.X {$newPosX} set {$id}");
				lx("item.channel pos.Y {$newPosY} set {$id}");
				lx("item.channel pos.Z {$newPosZ} set {$id}");
			}
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT ALL GRADATION VALUES
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub selectAllGradValues{
	my @gradationSelection = lxq("query sceneservice selection ? gradient");
	foreach my $id (@gradationSelection){
		if ($miscArg =~ /rgb/i){
			lx("select.channel {$id:color.R} add");
			lx("select.channel {$id:color.G} add");
			lx("select.channel {$id:color.B} add");
		}else{
			lx("select.channel {$id:value} add");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SELECT NEWEST ITEM BY TYPE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub selectNewestByType{
	if ($selNewTypeDlg == 1){
		$itemTypesList = "mesh;meshInst;triSurf;groupLocator;locator;camera;sunLight;pointLight;spotLight;photometryLight;domeLight;cylinderLight;areaLight";
		our $miscArg = popupMultChoice("Item type:",$itemTypesList,0);
	}
	if ($selMode eq ""){$selMode = "set";}
	my $itemCount = lxq("query sceneservice item.n ? all");
	for (my $i=$itemCount-1; $i>-1; $i--){
		my $type = lxq("query sceneservice item.type ? $i");
		if (lxq("query sceneservice item.type ? $i") eq $miscArg){
			my $id = lxq("query sceneservice item.id ? $i");
			lx("select.item item:{$id} mode:{$selMode}");
			last;
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#FIND MESH INSTANCE SOURCE (ver 1.2) (now supports proxies)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage : my $sourceMeshID = findMeshInstSource($item) or die("$item is not a meshInst");
sub findMeshInstSource{
	if ( (lxq("query sceneservice item.type ? {$_[0]}") ne "meshInst") && (lxq("query sceneservice item.type ? {$_[0]}") ne "proxy") ){return 0;}
	my $currentItem = $_[0];

	while (1){
		my $source = 			lxq("query sceneservice item.source ? {$currentItem}");
		if ($source eq "")	{	return $currentItem;													}
		else				{	$currentItem = lxq("query sceneservice item.source ? {$currentItem}");	}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SET ITEM POS TO VERT POS SUB
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
sub setItemPosToVert{
	lxout("[->] : Moving selected items to selected vert(s) position");
	my @selection = lxq("query sceneservice selection ? all");
	my $mainlayer = lxq("query layerservice layers ? main");
	my @verts = lxq("query layerservice verts ? selected");
	if (@verts == 0){die("You don't have any verts selected and so I'm cancelling the script");}
	my @pos = (0,0,0);
	my %itemFilterTable;
		$itemFilterTable{mesh} = 1;
		$itemFilterTable{meshInst} = 1;
		$itemFilterTable{triSurf} = 1;
		$itemFilterTable{groupLocator} = 1;
		$itemFilterTable{locator} = 1;
		$itemFilterTable{light} = 1;
		$itemFilterTable{sunLight} = 1;
		$itemFilterTable{camera} = 1;

	foreach my $vert (@verts){
		my @vertPos = lxq("query layerservice vert.pos ? $vert");
		@pos = arrMath(@pos,@vertPos,add);
	}
	@pos = arrMath(@pos,$#verts+1,$#verts+1,$#verts+1,div);

	foreach my $id (@selection){
		my $type = lxq("query sceneservice item.type ? {$id}");
		if ($itemFilterTable{$type} == 1){
			my $xfrmPosID = lxq("query sceneservice item.xfrmPos ? {$id}");
			if ($xfrmPosID eq ""){lx("transform.add type:pos item:{$id}");}

			if (($x == 1) || ($y == 1) || ($z == 1)){
				if ($x == 1)	{	lx("item.channel pos.X {$pos[0]} set {$id}");	}
				if ($y == 1)	{	lx("item.channel pos.Y {$pos[1]} set {$id}");	}
				if ($z == 1)	{	lx("item.channel pos.Z {$pos[2]} set {$id}");	}
			}else{
				lx("item.channel pos.X {$pos[0]} set {$id}");
				lx("item.channel pos.Y {$pos[1]} set {$id}");
				lx("item.channel pos.Z {$pos[2]} set {$id}");
			}
		}
	}
}

#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																MATH SUBROUTINES																	  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#2 CROSSPRODUCT VECTORS FROM 1 VECTOR (in=1vec+2returnVecs) (v.2)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE :
#requires UNITVECTOR
#requires CROSSPRODUCT
#getTwoCPVecsFromOneVec(\@inputVec,\@outputVec1,\@outputVec2);
sub getTwoCPVecsFromOneVec{
	my @vector1 = unitVector(@{$_[0]});

	#create the fake vector
	my @vector2 = (0,1,0);
	if (abs(@vector1[0]*@vector2[0] + @vector1[1]*@vector2[1] + @vector1[2]*@vector2[2]) > .95){	@vector2 = (1,0,0);	}

	#create the first and second crossProduct
	@{$_[1]} = unitVector(crossProduct(\@vector1,\@vector2));
	@{$_[2]} = crossProduct(\@vector1,\@{$_[1]});
	@{$_[1]} = crossProduct(\@vector1,\@{$_[2]});
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#PERFORM MATH FROM ONE ARRAY TO ANOTHER subroutine
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @disp = arrMath(@pos2,@pos1,subt);
sub arrMath{
	my @array1 = (@_[0],@_[1],@_[2]);
	my @array2 = (@_[3],@_[4],@_[5]);
	my $math = @_[6];

	my @newArray;
	if		($math eq "add")	{	@newArray = (@array1[0]+@array2[0],@array1[1]+@array2[1],@array1[2]+@array2[2]);	}
	elsif	($math eq "subt")	{	@newArray = (@array1[0]-@array2[0],@array1[1]-@array2[1],@array1[2]-@array2[2]);	}
	elsif	($math eq "mult")	{	@newArray = (@array1[0]*@array2[0],@array1[1]*@array2[1],@array1[2]*@array2[2]);	}
	elsif	($math eq "div")	{	@newArray = (@array1[0]/@array2[0],@array1[1]/@array2[1],@array1[2]/@array2[2]);	}
	return @newArray;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#UNIT VECTOR SUBROUTINE
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @unitVector = unitVector(@vector);
sub unitVector{
	my $dist1 = sqrt((@_[0]*@_[0])+(@_[1]*@_[1])+(@_[2]*@_[2]));
	@_ = ((@_[0]/$dist1),(@_[1]/$dist1),(@_[2]/$dist1));
	return @_;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DOT PRODUCT subroutine (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	return (	(${$_[0]}[0]*${$_[1]}[0])+(${$_[0]}[1]*${$_[1]}[1])+(${$_[0]}[2]*${$_[1]}[2])	);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CROSSPRODUCT SUBROUTINE (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @crossProduct = crossProduct(\@vector1,\@vector2);
sub crossProduct{
	return ( (${$_[0]}[1]*${$_[1]}[2])-(${$_[1]}[1]*${$_[0]}[2]) , (${$_[0]}[2]*${$_[1]}[0])-(${$_[1]}[2]*${$_[0]}[0]) , (${$_[0]}[0]*${$_[1]}[1])-(${$_[1]}[0]*${$_[0]}[1]) );
}


#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																MATRIX SUBROUTINES																	  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#
#																																					  #
#																																					  #
#																																					  #
#																																					  #
#-----------------------------------------------------------------------------------------------------------------------------------------------------#

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT   (no popups)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#userValueTools(name,type,life,username,list,listnames,argtype,min,max,action,value);
sub userValueTools{
	if (lxq("query scriptsysservice userValue.isdefined ? @_[0]") == 0){
		lxout("Setting up @_[0]--------------------------");
		lxout("Setting up @_[0]--------------------------");
		lxout("0=@_[0],1=@_[1],2=@_[2],3=@_[3],4=@_[4],5=@_[6],6=@_[6],7=@_[7],8=@_[8],9=@_[9],10=@_[10]");
		lxout("@_[0] didn't exist yet so I'm creating it.");
		lx( "user.defNew name:[@_[0]] type:[@_[1]] life:[@_[2]]");
		if (@_[3] ne "")	{	lxout("running user value setup 3");	lx("user.def [@_[0]] username [@_[3]]");	}
		if (@_[4] ne "")	{	lxout("running user value setup 4");	lx("user.def [@_[0]] list [@_[4]]");		}
		if (@_[5] ne "")	{	lxout("running user value setup 5");	lx("user.def [@_[0]] listnames [@_[5]]");	}
		if (@_[6] ne "")	{	lxout("running user value setup 6");	lx("user.def [@_[0]] argtype [@_[6]]");		}
		if (@_[7] ne "xxx")	{	lxout("running user value setup 7");	lx("user.def [@_[0]] min @_[7]");			}
		if (@_[8] ne "xxx")	{	lxout("running user value setup 8");	lx("user.def [@_[0]] max @_[8]");			}
		if (@_[9] ne "")	{	lxout("running user value setup 9");	lx("user.def [@_[0]] action [@_[9]]");		}
		if (@_[1] eq "string"){
			if (@_[10] eq ""){lxout("woah.  there's no value in the userVal sub!");							}		}
		elsif (@_[10] == ""){lxout("woah.  there's no value in the userVal sub!");									}
								lx("user.value [@_[0]] [@_[10]]");		lxout("running user value setup 10");
	}else{
		#STRING-------------
		if (@_[1] eq "string"){
			if (lxq("user.value @_[0] ?") eq ""){
				lxout("user value @_[0] was a blank string");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#BOOLEAN------------
		elsif (@_[1] eq "boolean"){

		}
		#LIST---------------
		elsif (@_[4] ne ""){
			if (lxq("user.value @_[0] ?") == -1){
				lxout("user value @_[0] was a blank list");
				lx("user.value [@_[0]] [@_[10]]");
			}
		}
		#ALL OTHER TYPES----
		elsif (lxq("user.value @_[0] ?") == ""){
			lxout("user value @_[0] was a blank number");
			lx("user.value [@_[0]] [@_[10]]");
		}
	}
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#CONVERT 3X3 MATRIX TO EULERS (in any rotation order)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my @angles = Eul_FromMatrix(\@3x3matrix,"XYZs",degrees|radians);
# - the output will be radians unless the third argument is "degrees" in which case the sub will convert it to degrees for you.
# - returns XrotAmt, YrotAmt, ZrotAmt, rotOrder;
# - resulting matrix must be inversed or transposed for it to be correct in modo.
sub Eul_FromMatrix{
	my ($m, $order) = @_;
	my @ea = (0,0,0,0);
	my $orderBackup = $order;

	my $pi = 3.14159265358979323;
	my $FLT_EPSILON = 0.00000000000000000001;
	my $EulFrmS = 0;
	my $EulFrmR = 1;
	my $EulRepNo = 0;
	my $EulRepYes = 1;
	my $EulParEven = 0;
	my $EulParOdd = 1;
	my @EulSafe = (0,1,2,0);
	my @EulNext = (1,2,0,1);

	#convert order text to indice
	my %rotOrderSetup = (
		"XYZs" , 0,		"XYXs" , 2,		"XZYs" , 4,		"XZXs" , 6,
		"YZXs" , 8,		"YZYs" , 10,	"YXZs" , 12,	"YXYs" , 14,
		"ZXYs" , 16,	"ZXZs" , 18,	"ZYXs" , 20,	"ZYZs" , 22,
		"ZYXr" , 1,		"XYXr" , 3,		"YZXr" , 5,		"XZXr" , 7,
		"XZYr" , 9,		"YZYr" , 11,	"ZXYr" , 13,	"YXYr" , 15,
		"YXZr" , 17,	"ZXZr" , 19,	"XYZr" , 21,	"ZYZr" , 23
	);
	$order = $rotOrderSetup{$order};


	$o=$order&31;
	$f=$o&1;
	$o>>=1;
	$s=$o&1;
	$o>>=1;
	$n=$o&1;
	$o>>=1;
	$i=@EulSafe[$o&3];
	$j=@EulNext[$i+$n];
	$k=@EulNext[$i+1-$n];
	$h=$s?$k:$i;

	if ($s == $EulRepYes) {
		$sy = sqrt($$m[$i][$j]*$$m[$i][$j] + $$m[$i][$k]*$$m[$i][$k]);
		if ($sy > 16*$FLT_EPSILON) {
			$ea[0] = atan2($$m[$i][$j], $$m[$i][$k]);
			$ea[1] = atan2($sy, $$m[$i][$i]);
			$ea[2] = atan2($$m[$j][$i], -$$m[$k][$i]);
		}else{
			$ea[0] = atan2(-$$m[$j][$k], $$m[$j][$j]);
			$ea[1] = atan2($sy, $$m[$i][$i]);
			$ea[2] = 0;
		}
	}else{
		$cy = sqrt($$m[$i][$i]*$$m[$i][$i] + $$m[$j][$i]*$$m[$j][$i]);
		if ($cy > 16*$FLT_EPSILON) {
			$ea[0] = atan2($$m[$k][$j], $$m[$k][$k]);
			$ea[1] = atan2(-$$m[$k][$i], $cy);
			$ea[2] = atan2($$m[$j][$i], $$m[$i][$i]);
		}else{
			$ea[0] = atan2(-$$m[$j][$k], $$m[$j][$j]);
			$ea[1] = atan2(-$$m[$k][$i], $cy);
			$ea[2] = 0;
		}
	}
	if ($n == $EulParOdd)	{	$ea[0] = -$ea[0]; $ea[1] = -$ea[1]; $ea[2] = -$ea[2];	}
	if ($f == $EulFrmR)		{	$t = $ea[0]; $ea[0] = $ea[2]; $ea[2] = $t;				}
	$ea[3] = $order;

	#convert radians to degrees if user wanted
	if ($_[2] eq "degrees"){
		$ea[0] *= 180/$pi;
		$ea[1] *= 180/$pi;
		$ea[2] *= 180/$pi;
	}

	#convert rot order back to lowercase text
	$ea[3] = lc($orderBackup);
	$ea[3] =~ s/[sr]//;

	#reorder rotations so they're always in X, Y, Z display order.
	my @eularOrder;
	$eularOrder[0] = substr($ea[3], 0, 1);
	$eularOrder[1] = substr($ea[3], 1, 1);
	$eularOrder[2] = substr($ea[3], 2, 1);
	my @eaBackup = @ea;
	for (my $i=0; $i<@eularOrder; $i++){
		if ($eularOrder[$i] =~ /x/i){$ea[0] = $eaBackup[$i];}
		if ($eularOrder[$i] =~ /y/i){$ea[1] = $eaBackup[$i];}
		if ($eularOrder[$i] =~ /z/i){$ea[2] = $eaBackup[$i];}
	}

	return @ea;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#3 X 3 ROTATION MATRIX FLIP (only works on rotation-only matrices though)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage @matrix = transposeRotMatrix_3x3(\@matrix);
sub transposeRotMatrix_3x3{
	my @matrix = (
		[ @{$_[0][0]}[0],@{$_[0][1]}[0],@{$_[0][2]}[0] ],	#[a00,a10,a20,a03],
		[ @{$_[0][0]}[1],@{$_[0][1]}[1],@{$_[0][2]}[1] ],	#[a01,a11,a21,a13],
		[ @{$_[0][0]}[2],@{$_[0][1]}[2],@{$_[0][2]}[2] ],	#[a02,a12,a22,a23],
	);
	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#4 X 4 MATRIX INVERSION sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : @inverseMatrix = inverseMatrix(\@matrix);
sub inverseMatrix{
	my ($m) = $_[0];
	my @matrix = (
		[$$m[0][0],$$m[0][1],$$m[0][2],$$m[0][3]],
		[$$m[1][0],$$m[1][1],$$m[1][2],$$m[1][3]],
		[$$m[2][0],$$m[2][1],$$m[2][2],$$m[2][3]],
		[$$m[3][0],$$m[3][1],$$m[3][2],$$m[3][3]]
	);

	$matrix[0][0] =  $$m[1][1]*$$m[2][2]*$$m[3][3] - $$m[1][1]*$$m[2][3]*$$m[3][2] - $$m[2][1]*$$m[1][2]*$$m[3][3] + $$m[2][1]*$$m[1][3]*$$m[3][2] + $$m[3][1]*$$m[1][2]*$$m[2][3] - $$m[3][1]*$$m[1][3]*$$m[2][2];
	$matrix[1][0] = -$$m[1][0]*$$m[2][2]*$$m[3][3] + $$m[1][0]*$$m[2][3]*$$m[3][2] + $$m[2][0]*$$m[1][2]*$$m[3][3] - $$m[2][0]*$$m[1][3]*$$m[3][2] - $$m[3][0]*$$m[1][2]*$$m[2][3] + $$m[3][0]*$$m[1][3]*$$m[2][2];
	$matrix[2][0] =  $$m[1][0]*$$m[2][1]*$$m[3][3] - $$m[1][0]*$$m[2][3]*$$m[3][1] - $$m[2][0]*$$m[1][1]*$$m[3][3] + $$m[2][0]*$$m[1][3]*$$m[3][1] + $$m[3][0]*$$m[1][1]*$$m[2][3] - $$m[3][0]*$$m[1][3]*$$m[2][1];
	$matrix[3][0] = -$$m[1][0]*$$m[2][1]*$$m[3][2] + $$m[1][0]*$$m[2][2]*$$m[3][1] + $$m[2][0]*$$m[1][1]*$$m[3][2] - $$m[2][0]*$$m[1][2]*$$m[3][1] - $$m[3][0]*$$m[1][1]*$$m[2][2] + $$m[3][0]*$$m[1][2]*$$m[2][1];
	$matrix[0][1] = -$$m[0][1]*$$m[2][2]*$$m[3][3] + $$m[0][1]*$$m[2][3]*$$m[3][2] + $$m[2][1]*$$m[0][2]*$$m[3][3] - $$m[2][1]*$$m[0][3]*$$m[3][2] - $$m[3][1]*$$m[0][2]*$$m[2][3] + $$m[3][1]*$$m[0][3]*$$m[2][2];
	$matrix[1][1] =  $$m[0][0]*$$m[2][2]*$$m[3][3] - $$m[0][0]*$$m[2][3]*$$m[3][2] - $$m[2][0]*$$m[0][2]*$$m[3][3] + $$m[2][0]*$$m[0][3]*$$m[3][2] + $$m[3][0]*$$m[0][2]*$$m[2][3] - $$m[3][0]*$$m[0][3]*$$m[2][2];
	$matrix[2][1] = -$$m[0][0]*$$m[2][1]*$$m[3][3] + $$m[0][0]*$$m[2][3]*$$m[3][1] + $$m[2][0]*$$m[0][1]*$$m[3][3] - $$m[2][0]*$$m[0][3]*$$m[3][1] - $$m[3][0]*$$m[0][1]*$$m[2][3] + $$m[3][0]*$$m[0][3]*$$m[2][1];
	$matrix[3][1] =  $$m[0][0]*$$m[2][1]*$$m[3][2] - $$m[0][0]*$$m[2][2]*$$m[3][1] - $$m[2][0]*$$m[0][1]*$$m[3][2] + $$m[2][0]*$$m[0][2]*$$m[3][1] + $$m[3][0]*$$m[0][1]*$$m[2][2] - $$m[3][0]*$$m[0][2]*$$m[2][1];
	$matrix[0][2] =  $$m[0][1]*$$m[1][2]*$$m[3][3] - $$m[0][1]*$$m[1][3]*$$m[3][2] - $$m[1][1]*$$m[0][2]*$$m[3][3] + $$m[1][1]*$$m[0][3]*$$m[3][2] + $$m[3][1]*$$m[0][2]*$$m[1][3] - $$m[3][1]*$$m[0][3]*$$m[1][2];
	$matrix[1][2] = -$$m[0][0]*$$m[1][2]*$$m[3][3] + $$m[0][0]*$$m[1][3]*$$m[3][2] + $$m[1][0]*$$m[0][2]*$$m[3][3] - $$m[1][0]*$$m[0][3]*$$m[3][2] - $$m[3][0]*$$m[0][2]*$$m[1][3] + $$m[3][0]*$$m[0][3]*$$m[1][2];
	$matrix[2][2] =  $$m[0][0]*$$m[1][1]*$$m[3][3] - $$m[0][0]*$$m[1][3]*$$m[3][1] - $$m[1][0]*$$m[0][1]*$$m[3][3] + $$m[1][0]*$$m[0][3]*$$m[3][1] + $$m[3][0]*$$m[0][1]*$$m[1][3] - $$m[3][0]*$$m[0][3]*$$m[1][1];
	$matrix[3][2] = -$$m[0][0]*$$m[1][1]*$$m[3][2] + $$m[0][0]*$$m[1][2]*$$m[3][1] + $$m[1][0]*$$m[0][1]*$$m[3][2] - $$m[1][0]*$$m[0][2]*$$m[3][1] - $$m[3][0]*$$m[0][1]*$$m[1][2] + $$m[3][0]*$$m[0][2]*$$m[1][1];
	$matrix[0][3] = -$$m[0][1]*$$m[1][2]*$$m[2][3] + $$m[0][1]*$$m[1][3]*$$m[2][2] + $$m[1][1]*$$m[0][2]*$$m[2][3] - $$m[1][1]*$$m[0][3]*$$m[2][2] - $$m[2][1]*$$m[0][2]*$$m[1][3] + $$m[2][1]*$$m[0][3]*$$m[1][2];
	$matrix[1][3] =  $$m[0][0]*$$m[1][2]*$$m[2][3] - $$m[0][0]*$$m[1][3]*$$m[2][2] - $$m[1][0]*$$m[0][2]*$$m[2][3] + $$m[1][0]*$$m[0][3]*$$m[2][2] + $$m[2][0]*$$m[0][2]*$$m[1][3] - $$m[2][0]*$$m[0][3]*$$m[1][2];
	$matrix[2][3] = -$$m[0][0]*$$m[1][1]*$$m[2][3] + $$m[0][0]*$$m[1][3]*$$m[2][1] + $$m[1][0]*$$m[0][1]*$$m[2][3] - $$m[1][0]*$$m[0][3]*$$m[2][1] - $$m[2][0]*$$m[0][1]*$$m[1][3] + $$m[2][0]*$$m[0][3]*$$m[1][1];
	$matrix[3][3] =  $$m[0][0]*$$m[1][1]*$$m[2][2] - $$m[0][0]*$$m[1][2]*$$m[2][1] - $$m[1][0]*$$m[0][1]*$$m[2][2] + $$m[1][0]*$$m[0][2]*$$m[2][1] + $$m[2][0]*$$m[0][1]*$$m[1][2] - $$m[2][0]*$$m[0][2]*$$m[1][1];

	return @matrix;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#THIS WILL ROUND THE CURRENT INTEGER to the string length you define (will fill in empty space with 0s)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $roundedIntegerString = roundIntString(1,3,0|space);  #outputs "001";
#note : arg "0|space" is so you can pad the number with either zeroes or spaces.
sub roundIntString{
	my $padChar = "0";
	if ($_[2] eq "space"){$padChar = " ";}
	my $roundedNumber = int($_[0] + .5);
	$_ = $roundedNumber;
	my $count = s/.//g;

	if  ($count < @_[1]){
		$roundedNumber  = $padChar x ((@_[1]) - $count) . $roundedNumber;
	}
	return($roundedNumber);
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#SIMPLE FIND/REPLACE SUB v1 (barebones find/replace sub.  replaces all found instances, not just first found)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#usage1 : my $newText = "poo_shit"; $newText = findReplace($newText,"_shit,");  #replaces "_shit" for nothing so you get "poo"
#usage2 : my $newText = "poo";      $newText = findReplace($newText,"*,*_shit") #replaces "poo" for "poo_shit"
sub findReplace{
	my @findReplace = split(/,/, $_[1]);
	my $newText = $_[0];
	
	#if findReplace has a * in it, i'm going to just swap the star in the repl section for the input word
	if ($findReplace[1] =~ /\*/){
		$newText = $findReplace[1];
		$newText =~ s/\*/$_[0]/g;
	}
	#if no *, i'm just going to do a find/replace
	else{
		$newText =~ s/$findReplace[0]/$findReplace[1]/g;
	}
	return $newText;
}

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#DISTANCE sub
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dist = dist(@vector);
sub dist{
	my $dist = sqrt(($_[0]*$_[0])+($_[1]*$_[1])+($_[2]*$_[2]));
	return($dist);
}