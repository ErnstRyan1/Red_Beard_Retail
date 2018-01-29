#perl
#BY: Seneca Menard
#version 1.7
#This script is to open/close custom windows.  Basically, to get this script to work you have to type a line of commands into the hotkey in a specific order, and there's a lot of commands, so let me go over 'em one by one:

#(1) : COOKIE : Basically, it's just so modo knows whether to open or close a window.  If there's no viewports onscreen that are using that cookie, then it'll open a new window.  If there is a viewport onscreen that uses that cookie, it'll close that window.  You should try to get all your windows to have different cookies so there's no open/close conflicts.
#(2) : NAME : This will be the displayed name of the viewport
#(3) : VIEWPORT : This is the important part.  This is to tell me what to open.  You can open either a LAYOUT or a VIEWPORT.  If you want a viewport, just type in the viewport name.  If you want a layout, you have to prepend the letters "layout=" to the name.  For example:
#----------VIEWPORT : if you typed in "@window.pl 7 Clips clip 550 5 256 1530", that would tell me you wanted to spawn the CLIP VIEWER VIEWPORT.
#----------FORM : if you typed in "@window.pl 7 Clips form={82459650471:sheet} 550 5 256 1530", that would tell me that you wanted to spawn the form view and load the "CURVE" form into it.  Well, how exactly do we tell it to load the CURVE form?  Well, we have to find the form id, and the way I do that is by finding a form in the form editor and right clicking on it and choosing "bind to key" and it'll print the form id there in that hotkey bind window. Just look for the part that looks like this : {82459650471:sheet}
#----------LAYOUT : if you typed in "@window.pl 3 "Form Editor" layout=Form_Editor_layout 1750 5 800 1530", that would tell me you want to spawn the FORM EDITOR LAYOUT.
#----------HOW TO FIND THE VIEWPORT NAMES?  The way you find the actual layout or viewport names is to open one of those windows and look in the command history.  For example, if you turn on the clips window, you'll get this : "viewport.restore Clips [0] clip"   "Clips" is the displayed viewport name and "clip" is the actual viewport name. "clip" is the one you need.
#(4) : X : This specifies where the left side of the new window will be on the screen.
#(5) : Y : This specifies where the top side of the new window will be on the screen.
#(6) : WIDTH : Width of window
#(7) : HEIGHT : Height of window
#(8) : PERSISTENT : This option (0 or 1) is so that if you move/resize the window and toggle it on/off, it'll keep it's size/shape..
#(9) : STYLE : This option (standard, palette, popoverClickOff, popoverRollOff) is to determine the type of window it'll be.

#Also, modo might crash if you misspell the viewport name, so be careful with that.  Also, save your modo cfg the second you get these hotkeys bound, so if modo does crash, you don't have to type them in again. :)

#(3-17-07 fix) : I fixed a bug where if you would open/close windows very fast, modo could overwrite one window's setttings with another's....
#(3-07-09 fix) : I fixed a small 401 bug
#(2-23-10 feature) : It allows window styles now (argument # 9)
#(9-15-10 feature) : You can now load a form without having to save a layout.  You do that by typing in form= and the viewport id into script argument #3.  For example : form={82459650471:sheet}

my $cookie =		@ARGV[0];
my $name = 			@ARGV[1];
my $viewport  = 	@ARGV[2];
my $X = 			@ARGV[3];
my $Y = 			@ARGV[4];
my $width = 		@ARGV[5];
my $height = 		@ARGV[6];
my $persistent =	@ARGV[7];
my $style = 		@ARGV[8];
if ($persistent == ""){$persistent = 0;}

lxout("Cookie      = $cookie\nName        = $name\nViewport   = $viewport\nX position  = $X\nY position  = $Y\nWidth        = $width\nHeight       = $height\nPersistent = $persistent");
if ((@ARGV[0]eq"") || (@ARGV[1]eq"") || (@ARGV[2]eq"") || (@ARGV[3]eq"") || (@ARGV[4]eq"") || (@ARGV[5]eq"") || (@ARGV[6]eq"")){
	die("\n.\n[---------------------------------------You're missing some arguments so I'm killing the script-------------------------------------]\nCookie      = $cookie\nName        = $name\nViewport   = $viewport\nX position  = $X\nY position  = $Y\nWidth        = $width\nHeight       = $height\nPersistent = $persistent\n[--PLEASE TURN OFF THIS WARNING WINDOW by clicking on the (In the future) button and choose (Hide Message)--] \n[-----------------------------------This window is not supposed to come up, but I can't control that.---------------------------]\n.\n");
}
if ($viewport =~ /layout=/i){
	our $layout = $viewport;
	$layout =~ s/layout=//;
}

#SPAWN OR CLOSE WINDOW
my $layoutCount1 = lxq("layout.count ?");
lxout("layoutCount1 = $layoutCount1");
if ($layout eq "")	{	lx("layout.createOrClose cookie:[$cookie] title:[$name] layout:[clear] x:[$X] y:[$Y] width:[$width] height:[$height] persistent:[$persistent] style:[$style]");				}
else			{	lx("layout.createOrClose cookie:[$cookie] title:[$name] layout:[$layout] x:[$X] y:[$Y] width:[$width] height:[$height] persistent:[$persistent] style:[$style]");	}
my $layoutCount2 = lxq("layout.count ?");
lxout("layoutCount2 = $layoutCount2");
lxout("layout = $layout");

#RESTORE VIEWPORT (if supposed to)
if (($layoutCount2 > $layoutCount1) && ($layout eq "")){
	lxout("Viewport variable ($viewport) didn't have the letters 'layout=' in it, so it appears you're trying to open a viewport, not a layout");
	if ($viewport =~ /form=/i){
		$viewport =~ s/form=//i;
		$viewport =~ s/[\{\}]//g;
		lx("viewport.restore {} false attrform");
		lx("attr.viewExport {$viewport} set");
		lx("!!viewport.restore name:[] tweak:[1] newType:[$viewport]");
	}else{
		lx("!!viewport.restore name:[] tweak:[1] newType:[$viewport]");
	}

}