#perl
#ver 1.4
#author : Seneca Menard

#This script is to look at the visible polys onscreen and frame the camera to them from the Z-axis and then changes the render properties to set the resolution equal to the size of the geometry bbox in meters.

#(4-21-15 fix) : now works in 801


my $modoVer = lxq("query platformservice appversion ?");
my $multChoice = popupMultChoice("Render on which axis?","X+;Y+;Z+;X-;Y-;Z-",2);
if		($multChoice =~ /x/i)	{	our $axis = "x";	}
elsif	($multChoice =~ /y/i)	{	our $axis = "y";	}
elsif	($multChoice =~ /z/i)	{	our $axis = "z";	}
if		($multChoice =~ /-/)	{	our $direction = -1;}
else							{	our $direction = 1; }

#get bbox
my $mainlayer = lxq("query layerservice layers ? main");
my @verts = lxq("query layerservice verts ? visible");
my $items = lxq("query sceneservice item.n ? all");
my @bbox = boundingbox(@verts);
my @bboxCenter = (   (@bbox[0]+@bbox[3])*0.5 , (@bbox[1]+@bbox[4])*0.5 , (@bbox[2]+@bbox[5])*0.5);
my @bboxSize = ( @bbox[3] - @bbox[0] , @bbox[4]-@bbox[1] , @bbox[5]-@bbox[2] );
if ($axis eq "x"){
	our $UBounds = abs(@bbox[5]-@bbox[2]);
	our $VBounds = abs(@bbox[4]-@bbox[1]);
	our @size = (@bbox[5]-@bbox[2],@bbox[4]-@bbox[1]);
}elsif ($axis eq "y"){
	our $UBounds = abs(@bbox[3]-@bbox[0]);
	our $VBounds = abs(@bbox[5]-@bbox[2]);
	our @size = (@bbox[3]-@bbox[0],@bbox[5]-@bbox[2]);
}else{
	our $UBounds = abs(@bbox[3]-@bbox[0]);
	our $VBounds = abs(@bbox[4]-@bbox[1]);
	our @size = (@bbox[3]-@bbox[0],@bbox[4]-@bbox[1]);
}

if (@size[0] > @size[1])	{	our $greater = 0;	}
else						{	our $greater = 1;	}
my $cameraDistance;

if		($axis eq "x"){
	if (@bboxSize[0] < .0001){
		$cameraDistance = @bboxCenter[0]+(@size[$greater]*$direction) ;
	}else{
		$cameraDistance = @bboxCenter[0]+($bboxSize[0] * 0.51 * $direction) ;
	}
}elsif	($axis eq "y"){
	if (@bboxSize[1] < .0001){
		$cameraDistance = @bboxCenter[1]+(@size[$greater]*$direction);
	}else{
		$cameraDistance = @bboxCenter[1]+($bboxSize[1] * 0.51 * $direction);
	}
}else{
	if (@bboxSize[2] < .0001){
		$cameraDistance = @bboxCenter[2]+(@size[$greater]*$direction);
	}else{
		$cameraDistance = @bboxCenter[2]+($bboxSize[2] * 0.51 * $direction);
	}
}


#------------------------------------------------------------------------------------------------------------
#find the first camera (and turn on DOF so you can change the camera focus dist)
#------------------------------------------------------------------------------------------------------------
my $itemCount = lxq("query sceneservice item.n ? all");
my $renderOutputID;
for (my $i=0; $i<$itemCount; $i++){
	if (lxq("query sceneservice item.type ? $i") eq "polyRender"){
		$renderOutputID = lxq("query sceneservice item.id ? $i");
		last;
	}
}

lx("select.subItem {$renderOutputID} set textureLayer;locator;render;environment;mediaClip");
my $camera = lxq("render.camera ?");
if ($camera eq ""){die("You don't have a RENDER CAMERA chosen in the render properties window, so I'm cancelling the script.");}

#turn on DOF for focus distance setting
if ($modoVer < 700){
	my $DOF = lxq("item.channel polyRender\$dof ? set {$renderOutputID}");
	if ($DOF == 0){lx("item.channel polyRender\$dof 1 set {$renderOutputID}");}
}else{
	lx("item.channel dof 1 set {$camera}");
}


#------------------------------------------------------------------------------------------------------------
#set camera pos
#------------------------------------------------------------------------------------------------------------
#find out if pivot "translation" exists and if not, create it.
my $pivotID = lxq("query sceneservice item.xfrmPiv ? $camera");
my $pivotID2 = lxq("query sceneservice item.xfrmPivC ? $camera");
if ($pivotID ne ""){
	lxout("[->] Resetting the pivot position on the camera");
	lx("!!item.channel pos.X 0 set {$pivotID}");
	lx("!!item.channel pos.Y 0 set {$pivotID}");
	lx("!!item.channel pos.Z 0 set {$pivotID}");
}
if ($pivotID2 ne ""){
	lxout("[->] Resetting the pivot compensation position on the camera");
	lx("!!item.channel pos.X 0 set {$pivotID2}");
	lx("!!item.channel pos.Y 0 set {$pivotID2}");
	lx("!!item.channel pos.Z 0 set {$pivotID2}");
}
lx("transform.purge $camera");


if		($axis eq "x"){
	lx("!!item.channel pos.X {$cameraDistance} set {$camera}");
	lx("!!item.channel pos.Y {@bboxCenter[1]} set {$camera}");
	lx("!!item.channel pos.Z {@bboxCenter[2]} set {$camera}");
	lx("!!item.channel rot.X {0} set {$camera}");
	if ($direction == 1){
		lx("!!item.channel rot.Y {90} set {$camera}");
	}else{
		lx("!!item.channel rot.Y {270} set {$camera}");
	}

	lx("!!item.channel rot.Z {0} set {$camera}");
}


elsif	($axis eq "y"){
	lx("!!item.channel pos.X {@bboxCenter[0]} set {$camera}");
	lx("!!item.channel pos.Y {$cameraDistance} set {$camera}");
	lx("!!item.channel pos.Z {@bboxCenter[2]} set {$camera}");
	if ($direction == 1){
		lx("!!item.channel rot.X {-90} set {$camera}");
	}else{
		lx("!!item.channel rot.X {90} set {$camera}");
	}
	lx("!!item.channel rot.Y {0} set {$camera}");
	lx("!!item.channel rot.Z {0} set {$camera}");
}

else{
	lx("!!item.channel pos.X {@bboxCenter[0]} set {$camera}");
	lx("!!item.channel pos.Y {@bboxCenter[1]} set {$camera}");
	lx("!!item.channel pos.Z {$cameraDistance} set {$camera}");
	lx("!!item.channel rot.X {0} set {$camera}");
	if ($direction == 1){
		lx("!!item.channel rot.Y {0} set {$camera}");
	}else{
		lx("!!item.channel rot.Y {180} set {$camera}");
	}
	lx("!!item.channel rot.Z {0} set {$camera}");
}


if ($axis eq "x"){
	if (1){ #(@bboxSize[0] < .0001){
		lx("!!item.channel focalLen {$size[$greater]} set {$camera}");
		lx("!!item.channel focusDist {$size[$greater]} set {$camera}");
	}else{
		lx("!!item.channel focalLen {$bboxSize[0]} set {$camera}");
		lx("!!item.channel focusDist {$bboxSize[0]} set {$camera}");
	}
}elsif	($axis eq "y"){
	if (1){ #(@bboxSize[1] < .0001){
		lx("!!item.channel focalLen {$size[$greater]} set {$camera}");
		lx("!!item.channel focusDist {$size[$greater]} set {$camera}");
	}else{
		lx("!!item.channel focalLen {$bboxSize[1]} set {$camera}");
		lx("!!item.channel focusDist {$bboxSize[1]} set {$camera}");
	}
}else{
	if (1){ #(@bboxSize[2] < .0001){
		lx("!!item.channel focalLen {$size[$greater]} set {$camera}");
		lx("!!item.channel focusDist {$size[$greater]} set {$camera}");
	}else{
		lx("!!item.channel focalLen {$bboxSize[2]} set {$camera}");
		lx("!!item.channel focusDist {$bboxSize[2]} set {$camera}");
	}
}
lx("!!item.channel fStop {4} set {$camera}");
lx("!!item.channel apertureX {$UBounds} set {$camera}");
lx("!!item.channel apertureY {$VBounds} set {$camera}");
lx("!!item.channel projType {ortho} set {$camera}");


#------------------------------------------------------------------------------------------------------------
#change render properties
#------------------------------------------------------------------------------------------------------------
for (my $i=0; $i<$items; $i++){
	if (lxq("query sceneservice item.type ? $i") eq "polyRender"){
		$render = lxq("query sceneservice item.id ? $i");
		last;
	}
}

lx("!!render.camera [$camera]");
lx("!!item.channel resUnit [0] set [$render]");
lx("!!render.res [0] {$UBounds}");
lx("!!render.res [1] {$VBounds}");

#set dof back
if ($modoVer < 700) {lx("item.channel dof {0} set {$renderOutputID}");	}
else				{lx("item.channel dof {0} set {$camera}");			}

#create and set depth output
my $renderOutputID;
for (my $i=0; $i<$items; $i++){
	if (lxq("query sceneservice item.type ? $i") eq "renderOutput"){
		my $id = lxq("query sceneservice item.id ? $i");
		lx("!!select.subItem {$id} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
		if (lxq("shader.setEffect ?") eq "depth"){
			$renderOutputID = lxq("query sceneservice item.id ? $i");
			lx("!!select.subItem {$renderOutputID} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
			last;
		}
	}
}

if ($renderOutputID eq ""){
	lx("!!select.subItem {$render} set textureLayer;locator;render;environment;mediaClip");
	lx("!!shader.create renderOutput");
	$renderOutputID = lxq("query sceneservice selection ? renderOutput");
	lx("!!select.subItem {$renderOutputID} set textureLayer;render;environment;light;camera;mediaClip;txtrLocator");
	lx("!!shader.setEffect depth");
}
lxout("renderOutputID = $renderOutputID");

if		($modoVer > 700){lx("item.channel remap {1} set {$renderOutputID}");				}
if		($axis eq "x")	{lx("item.channel depthMax {$bboxSize[0]} set {$renderOutputID}");	}
elsif	($axis eq "y")	{lx("item.channel depthMax {$bboxSize[1]} set {$renderOutputID}");	}
else					{lx("item.channel depthMax {$bboxSize[2]} set {$renderOutputID}");	}










#-----------------------------------------------------------------------------------
#BOUNDING BOX subroutine (ver 1.5)
#-----------------------------------------------------------------------------------
sub boundingbox  #minX-Y-Z-then-maxX-Y-Z
{
	lxout("[->] Using boundingbox (math) subroutine");
	my @firstVertPos = lxq("query layerservice vert.pos ? $_[0]");
	my $minX = $firstVertPos[0];
	my $minY = $firstVertPos[1];
	my $minZ = $firstVertPos[2];
	my $maxX = $firstVertPos[0];
	my $maxY = $firstVertPos[1];
	my $maxZ = $firstVertPos[2];
	my @bbVertPos;

	foreach my $bbVert (@_){
		@bbVertPos = lxq("query layerservice vert.pos ? $bbVert");
		if ($bbVertPos[0] < $minX)	{	$minX = $bbVertPos[0];	}
		if ($bbVertPos[0] > $maxX)	{	$maxX = $bbVertPos[0];	}
		if ($bbVertPos[1] < $minY)	{	$minY = $bbVertPos[1];	}
		if ($bbVertPos[1] > $maxY)	{	$maxY = $bbVertPos[1];	}
		if ($bbVertPos[2] < $minZ)	{	$minZ = $bbVertPos[2];	}
		if ($bbVertPos[2] > $maxZ)	{	$maxZ = $bbVertPos[2];	}
	}
	return ($minX,$minY,$minZ,$maxX,$maxY,$maxZ);
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

#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#QUICK DIALOG SUB v2.1
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : quickDialog(username,float,initialValue,min,max);
sub quickDialog{
	if (@_[1] eq "yesNo"){
		lx("dialog.setup yesNo");
		lx("dialog.msg {$_[0]}");
		lx("dialog.open");
		if (lxres != 0){	die("The user hit the cancel button");	}
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