#perl
#this is to sync the render camera to the view



#Remember what the workplane was and turn it off
my @WPmem;
@WPmem[0] = lxq ("workPlane.edit cenX:? ");
@WPmem[1] = lxq ("workPlane.edit cenY:? ");
@WPmem[2] = lxq ("workPlane.edit cenZ:? ");
@WPmem[3] = lxq ("workPlane.edit rotX:? ");
@WPmem[4] = lxq ("workPlane.edit rotY:? ");
@WPmem[5] = lxq ("workPlane.edit rotZ:? ");
lx("!!workPlane.reset ");


lx("selec.itemType render");
my $cameraID = lxq("render.camera ?");
if ($cameraID == 1){die("There's no camera in the scene");}
lx("select.subItem $cameraID set mesh;meshInst;camera;light;backdrop [0] [1]");
lx("camera.syncView");

#try to set the camera zoom
my $zoom = lxq("pref.value opengl.perspective ?")+.01;
$zoom = .15 + $zoom*11;
lx("item.channel focalLen [$zoom cm] set");


#put the WORKPLANE back
lx("workPlane.edit {@WPmem[0]} {@WPmem[1]} {@WPmem[2]} {@WPmem[3]} {@WPmem[4]} {@WPmem[5]}");


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
