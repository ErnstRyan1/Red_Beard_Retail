#perl
#AUTHOR: Seneca Menard
#Version 1.46 (WARNING : NOT FOR ANY VERSIONS OF MODO EARLIER THAN 401!)

#This script's been rewritten for modo202.  I took all my vert and wireframe toggle scripts and merged 'em into one.
#To run them, you have to append a word to the end of the script command to tell it which of 'em you want to run:
#(10-29-06 bugfix) : "toggleAll" was putting the wireframe back when it shouldn't have, if you toggled all off while wireframes were hidden.
#(14-14-07 feature) : "toggleFGBG" was added.  This is toggle both the FG and BG displays to be the opposite of one another.  It's really handy when you're building low poly models on top of a high poly model, so you can flip back and forth between the two.
#(5-12-08 tweak) : I put in a little more granularity to the wireframe fade in and fade out scripts..
#(3-26-09 bugfix) : 401 had the syntax changed, so i had to update the script.
#(9-29-09 tweak) : toggleGrid now toggles the uv window's grid as well.
#(9-14-10 feature) : increaseBrightness, decreaseBrightness, and resetBrightness : these cvars are for brightening and darkening the gl viewport lights.
#(7-8-11 feature) : I swapped what "togglePersp" does.  It now toggles between the 3d view and whichever 2d view is the most similar in axis.  I can't roll the 2d vieworts however and so if you're looking upside down in the 3dview or whatnot, I can't match that..
#(3-9-12 feature) : "toggleBGItemHide" : this is for toggling inactive mesh display from what it currently is set to, to invisible and back.
#(9-1-15 fix) : toggleFGBG : put in reverse support for 601

#1) TOGGLE VERTS: This is to toggle vert display on and off.
#1) example:  @viewport_displayToggles.pl toggleVerts
#---------
#2) TOGGLE WIREFRAME: This is toggle wireframe  and vert display on and off.
#2) example:  @viewport_displayToggles.pl toggleWireFrame
#---------
#3) TOGGLE WIREFRAME COLOR : This is to toggle the wireColor between UNIFORM and STANDARD.
#3) example:  @viewport_displayToggles.pl toggleWireColor
#---------
#4) TOGGLE ALL: This is toggle wireframe display, vert display, and selection display.
#4) example:  @viewport_displayToggles.pl toggleAll
#---------
#5) TOGGLE VIEWPORT : This is to toggle the viewport's display between WIREFRAME and (WHATEVER IT WAS BEFORE)
#5) example: @viewport_displayToggles.pl toggleViewport
#---------
#6) TOGGLE WEIGHTING: This is to toggle the viewport between WEIGHTMAP and (WHATEVER IT WAS BEFORE)
#6) example:  @viewport_displayToggles.pl toggleWeighting
#---------
#7) TOGGLE GRID: This is to toggle the GRID and WORKPLANE on/off.
#7) example:  @viewport_displayToggles.pl toggleGrid
#---------
#8) TOGGLE BACKGROUND SHADING: This is to toggle the BACKGROUND DISPLAY from WIRE to FLAT and back.
#8) example:  @viewport_displayToggles.pl toggleBGShading
#---------
#9) TOGGLE BACKFACE SELECTION: This is to toggle the ability to select BACKFACING ELEMENTS.
#9) example:  @viewport_displayToggles.pl toggleBFSelection
#---------
#10) EXPAND VERT SIZE: This is to expand the size of the dislayed verts
#10) example:  @viewport_displayToggles.pl expandVertSize
#---------
#11) CONTRACT VERT SIZE: This is to contract the size of the dislayed verts
#11) example:  @viewport_displayToggles.pl contractVertSize
#---------
#12) WIREFRAME FADE IN: This is to fade in the wireframe opacity
#12) example:  @viewport_displayToggles.pl wireFadeIn
#---------
#13) WIREFRAME FADE OUT: This is to fade out the wireframe opacity
#13) example:  @viewport_displayToggles.pl wireFadeOut
#---------
#14) TOGGLE HANDLE : This is to toggle the display of tool handles on/off.
#14) (if you only want to toggle the handle of the current active tool, append "singleHandle".  If you want to use 'Advanced' tool handles instead of 'Preference', append "advanced")
#14) (the little purple tool axes aren't displayed by default.  If you want them displayed, just append "axisVisible" to the script)  Also, please put the "toggleHandle" cvar in last so the ordering is correct.
#14) example:  @viewport_displayToggles.pl toggleHandle
#14) example:  @viewport_displayToggles.pl singleHandle advanced axisVisible toggleHandle
#---------
#15) TOGGLE PERSPECTIVE : This is to toggle a viewport between perspective and front.
#15) example:  @viewport_displayToggles.pl togglePersp
#---------
#16) TOGGLE FOREGROUND AND BACKGROUND : This is toggle both the FG and BG displays to be the opposite of one another.  It's really handy when you're building low poly models on top of a high poly model, so you can flip back and forth between the two.
#16) example: @viewport_displayToggles.pl toggleFGBG
#---------
#17) TOGGLE ITEM REF : This is toggle your main layer into layer reference mode and back again. (It's for when your main layer has a transform on it, you can hide that transform and work on it again as if it didn't have that transform applied)
#17) example: @viewport_displayToggles.pl toggleItemRef
#---------
#18) INCREASE VIEWPORT BRIGHTNESS : This will increase the brightness of the viewport's standard gl lights by 10%. (it assumes there's only two lights, as that's true by default)
#18) example: @viewport_displayToggles.pl increaseBrightness
#---------
#19) DECREASE VIEWPORT BRIGHTNESS : This will decrease the brightness of the viewport's standard gl lights by 10%. (it assumes there's only two lights, as that's true by default)
#19) example: @viewport_displayToggles.pl decreaseBrightness
#---------
#20) RESET VIEWPORT BRIGHTNESS : This will reset the brightness of the viewport's standard gl lights. (by default in modo, their brightnesses are 70% and 30%)
#20) example: @viewport_displayToggles.pl resetBrightness
#---------
#21) TOGGLE BG ITEM MODE FROM CURRENT VALUE TO INVISIBLE AND BACK : this is for toggling inactive mesh display from what it currently is set to, to invisible and back.
#21) NOTE : you can also have it not be a toggle, but instead force it to be on or off. "forceOff" and "forceOn" are those arguments.
#21) example: @viewport_displayToggles.pl toggleBGItemHide
#21) example: @viewport_displayToggles.pl forceOff toggleBGItemHide
#21) example: @viewport_displayToggles.pl forceOn toggleBGItemHide
#---------
#22) 801 TOGGLE BG DISPLAY MODES : this is for 801 to change the viewport modes between wire-->flatShaded-->sameAsActive
#22) example: @viewport_displayToggles.pl 801_toggleBGDispModes
#---------
#23) 801 SET SHADE MODE : this sets the viewport mode for both active layers and background layers. (and retains current wireframe display coloring)
#23) example : @viewport_displayToggles.pl advgl setShadeMode

my $modoVer = lxq("query platformservice appversion ?");

#--------------------------------------------------------------------------------------------------
#create the cvars if they doesn't exist
#--------------------------------------------------------------------------------------------------
userValueTools(senWireColor,string,config,"wireframe color","","","",xxx,xxx,"",uniform);
userValueTools(senDisplayWire,integer,config,"wireframe display","","","",0,1,"",1);
userValueTools(senDisplayVerts,integer,config,"vertex display","","","",0,1,"",0);
userValueTools(senViewMode,string,config,"viewport display mode","","","",xxx,xxx,"",tex);
userValueTools(senBGItemMode,string,config,"background item display mode","","","",xxx,xxx,"",flat);
userValueTools(senBGShadeMode,string,config,"background item shade mode","","","",xxx,xxx,"",wire);
userValueTools(senFGWireMode,boolean,config,"allow FG to go to wire","","","",xxx,xxx,"",1);

#--------------------------------------------------------------------------------------------------
#ARGS
#--------------------------------------------------------------------------------------------------
foreach my $arg(@ARGV){
	if 	  ($arg eq "skipVPSel")				{	our $skipVPSel = 1;				}
	elsif ($arg eq "forceOff")				{	our $forceOff = 1;				}
	elsif ($arg eq "forceOn")				{	our $forceOn = 1;				}
	elsif ($arg =~ /togglewirecolor/i)		{	&toggleWireColor;				}
	elsif ($arg =~ /togglewireframe/i)		{	&toggleWireFrame;				}
	elsif ($arg =~ /toggleall/i)			{	&toggleAll;						}
	elsif ($arg =~ /toggleverts/i)			{	&toggleVerts;					}
	elsif ($arg =~ /toggleviewport/i)		{	&toggleViewport;				}
	elsif ($arg =~ /toggleweighting/i)		{	&toggleWeighting;				}
	elsif ($arg =~ /togglegrid/i)			{	&toggleGrid;					}
	elsif ($arg =~ /togglebgshading/i)		{	&toggleBGShading;				}
	elsif ($arg =~ /togglebfselection/i)	{	&toggleBFSelection;				}
	elsif ($arg =~ /expandvertsize/i)		{	&expandVertSize;				}
	elsif ($arg =~ /contractvertsize/i)		{	&contractVertSize;				}
	elsif ($arg =~ /wirefadein/i)			{	&wireFadeIn;					}
	elsif ($arg =~ /wirefadeout/i)			{	&wireFadeOut;					}
	elsif ($arg =~ /advanced/i)				{	our $toolStyle = "advanced";	} #this is for the toggleHandle sub.
	elsif ($arg =~ /singlehandle/i)			{	our $singleHandle = 1;			} #this is for the toggleHandle sub.
	elsif ($arg =~ /axisvisible/i)			{	our $axisVisible = 1;			} #this is for the toggleHandle sub.
	elsif ($arg =~ /togglehandle/i)			{	&toggleHandle;					}
	elsif ($arg =~ /togglepersp/i)			{	&togglePersp;					}
	elsif ($arg =~ /toggleFGBG/i)			{	&toggleFGBG;					}
	elsif ($arg =~ /toggleItemRef/i)		{	&toggleItemRef;					}
	elsif ($arg =~ /toggleBGItemHide/i)		{	&toggleBGItemHide;				}
	elsif ($arg =~ /increaseBrightness/i)	{	&increaseBrightness;			}
	elsif ($arg =~ /decreaseBrightness/i)	{	&decreaseBrightness;			}
	elsif ($arg =~ /resetBrightness/i)		{	&resetBrightness;				}
	elsif ($arg =~ /toggleBGDispModes/i)	{ 	&toggleBGDispModes;				}
	elsif ($arg =~ /setShadeMode/i)			{	&setShadeMode;					}
	else									{	our $miscArg = $arg;			}
}

#--------------------------------------------------------------------------------------------------
#801 SET SHADE MODE (for fg and bg) : 
#--------------------------------------------------------------------------------------------------
sub setShadeMode{
	my $wireMode = lxq("view3d.wireframeOverlay mode:?");
	lx("!!view3d.shadingStyle {$miscArg} active");
	lx("!!view3d.shadingStyle {$miscArg} inactive");
	lx("!!view3d.wireframeOverlay none inactive");
	lx("!!view3d.wireframeOverlay mode:{$wireMode}");
}

#--------------------------------------------------------------------------------------------------
#801 TOGGLE BG DISPLAY SHADING MODES : 
#--------------------------------------------------------------------------------------------------
sub toggleBGDispModes{
	my $mode = lxq("user.value senBGItemMode ?");
	
	#wire
	if ($mode eq "same"){
		lx("!!user.value senBGItemMode wire");
		lx("!!view3d.sameAsActive false");
		lx("view3d.shadingStyle wire inactive");
		lx("view3d.wireframeAlpha 1 inactive");
	}
	
	#shaded
	elsif ($mode eq "wire"){
		lx("!!user.value senBGItemMode shaded");
		lx("!!view3d.sameAsActive false");
		lx("!!view3d.shadingStyle shade inactive");
		lx("!!view3d.wireframeOverlay none inactive");
		lx("!!view3d.smoothing false inactive");
	}
	
	#same
	else{
		lx("!!user.value senBGItemMode same");
		my $activeShadeStyle = lxq("view3d.shadingStyle style:?");
		lx("!!view3d.shadingStyle {$activeShadeStyle} inactive");
		lx("!!view3d.wireframeOverlay none inactive");
		lx("!!view3d.smoothing true inactive");
		#lx("!!view3d.sameAsActive true");
	}
	
	
}

#--------------------------------------------------------------------------------------------------
#TOGGLE BG ITEM MODE FROM CURRENT TO INVISIBLE AND BACK
#--------------------------------------------------------------------------------------------------
sub toggleBGItemHide{
	if ($modoVer < 600){die("This script only works in 601 and later");}
	my $mode = lxq("viewport.3dView background:?");
	if ($mode eq ""){die("Killing script because apparently you're not in a 3d view");}

	#force off
	if ($forceOff == 1){
		if ($mode ne "invisible"){
			lx("!!user.value senBGItemMode {$mode}");
			lx("!!viewport.3dView background:{invisible}");
		}
	}
	#force on
	elsif ($forceOn == 1){
		if ($mode eq "invisible"){
			$senBGItemMode = lxq("user.value senBGItemMode ?");
			lx("!!viewport.3dView background:{$senBGItemMode}");
		}
	}
	#toggle
	else{
		if ($mode eq "invisible"){
			$senBGItemMode = lxq("user.value senBGItemMode ?");
			lx("!!viewport.3dView background:{$senBGItemMode}");
		}else{
			lx("!!user.value senBGItemMode {$mode}");
			lx("!!viewport.3dView background:{invisible}");
		}
	}
}

#--------------------------------------------------------------------------------------------------
#WIREFRAME FADE IN SUB
#--------------------------------------------------------------------------------------------------
sub wireFadeIn{
	#select window mouse is over
	if ($skipVPSel != 1){if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}}

	my $wireAlpha = lxq("view3d.wireframeAlpha ?");
	if ($wireAlpha == 0){$wireAlpha = .05;}
	else				{$wireAlpha *= 1.3;}

	if ($wireAlpha < 0.95){
		lx("view3d.wireframeAlpha $wireAlpha");
	}
	else{
		lxout("Hitting the cap");
		lx("view3d.wireframeAlpha 1");
	}
}


#--------------------------------------------------------------------------------------------------
#WIREFRAME FADE OUT SUB
#--------------------------------------------------------------------------------------------------
sub wireFadeOut{
	#select window mouse is over
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}

	my $wireAlpha = lxq("view3d.wireframeAlpha ?");
	if ($wireAlpha > 0.05){
		$wireAlpha *= .65;
		lx("view3d.wireframeAlpha $wireAlpha");
	}else{
		lxout("Hitting the cap");
		lx("view3d.wireframeAlpha 0");
	}
	lxout("A wireAlpha = $wireAlpha");
}


#--------------------------------------------------------------------------------------------------
#CONTRACT VERT SIZE SUB
#--------------------------------------------------------------------------------------------------
sub contractVertSize{
	#select window mouse is over
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}

	my $displaySize = lxq("pref.value opengl.glPointSize ?");
	if ($displaySize > 3){
		$displaySize--;
		lx("pref.value opengl.glPointSize $displaySize");
		lxout("handlesize is now $displaySize");
	}
}


#--------------------------------------------------------------------------------------------------
#CONTRACT VERT SIZE SUB
#--------------------------------------------------------------------------------------------------
sub expandVertSize{
	#select window mouse is over
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}

	my $displaySize = lxq("pref.value opengl.glPointSize ?");
	$displaySize++;
	lx("pref.value opengl.glPointSize $displaySize");
	lxout("handlesize is now $displaySize");
}


#--------------------------------------------------------------------------------------------------
#TOGGLE BACKFACE SELECTIONS SUB
#--------------------------------------------------------------------------------------------------
sub toggleBFSelection{
	#select window mouse is over
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}

	#TOGGLE BACKFACE SELECTION
	if (lxq("pref.value remapping.backfaceSelect ?") == 1){
		lx("pref.value remapping.backfaceSelect 0");
	}else{
		lx("pref.value remapping.backfaceSelect 1");
	}
}

#--------------------------------------------------------------------------------------------------
#TOGGLE BACKGROUND SHADING
#--------------------------------------------------------------------------------------------------
sub toggleBGShading{
	#select window mouse is over
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}
	my $senwirecheck = lxq("view3d.bgLayerDisplay ?");
	lxout("Bground shading = $senwirecheck");

	#TOGGLE BACKGROUND SHADING
	if ($senwirecheck eq "wire"){
		lx("view3d.bgLayerDisplay flat");
	}else{
		lx("view3d.bgLayerDisplay wire");
	}
}

#--------------------------------------------------------------------------------------------------
#TOGGLE GRID and WORKPLANE SUB
#--------------------------------------------------------------------------------------------------
sub toggleGrid{
	#select window mouse is over
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}
	my $viewport = lxq("query view3dservice mouse.view ?");
	my $type = lxq("query view3dservice view.type ? $viewport");

	#TOGGLE 3D VIEW GRID+WORKPLANE DISPLAY
	if ($type eq "MO3D"){
		if (lxq("view3d.showGrid ?") == 1){
			lx("view3d.showGrid 0");
			lx("view3d.showWorkPlane 0");
		}else{
			lx("view3d.showGrid 1");
			lx("view3d.showWorkPlane 1");
		}
	}

	#TOGGLE UV VIEW GRID
	elsif ($type eq "UV2D"){
		if (lxq("viewuv.showGrid ?") == 1)	{	our $onOff = 0;	}
		else								{	our $onOff = 1;	}

		lx("!!viewuv.showGrid $onOff");
		lx("!!viewuv.showInsideLabel $onOff");
		lx("!!viewuv.showAxis $onOff");
	}
}


#--------------------------------------------------------------------------------------------------
#TOGGLE VERT DISPLAY SUB
#--------------------------------------------------------------------------------------------------
sub toggleVerts{
	#select window mouse is over
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}

	#ONLY TOGGLE VERT DISPLAY IF WIREFRAME IS DISPLAYED RIGHT NOW!!!
	if (lxq("view3d.wireframeOverlay ?") ne "none"){
		#TOGGLE VERT DISPLAY
		if (lxq("view3d.showVertices ?") == 1){
			lx("user.value senDisplayVerts off");
			lx("view3d.showVertices 0");
		}else{
			lx("user.value senDisplayVerts on");
			lx("view3d.showVertices 1");
		}
	}else{
		lxout("-I'm not toggling vert display because wireframes aren't shown right now");
	}
}

#--------------------------------------------------------------------------------------------------
#TOGGLE WIREFRAME SUB
#--------------------------------------------------------------------------------------------------
sub toggleWireFrame{
	#ONLY RUN IT IF SELECTIONS ARE VISIBLE!
	if (lxq("view3d.showSelections ?") == 1){
		#SELECT WINDOW UNDER MOUSE--------------------
		if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}


		#TURN OFF WIREFRAME----------------------------------
		if (lxq("view3d.wireframeOverlay ?") ne "none"){
			lxout("-turning off wireframe");

			#REMEMBER WIRE COLOR
			my $color = lxq("view3d.wireframeOverlay ?");
			if (($color ne "uniform") && ($color ne "colored")){	popup("wireframe color failure <> color = $color");	} #TEMP
			lx("user.value senWireColor $color");
			lx("view3d.wireframeOverlay none");

			#remember and turn off vert display
			my $vertDisplay = lxq("view3d.showVertices ?");
			lx("user.value senDisplayVerts  $vertDisplay");
			lx("view3d.showVertices 0");
		}


		#TURN ON WIREFRAME----------------------------------
		else{
			lxout("-turning on wireframe");
			my $color = lxq("user.value senWireColor ?");
			lxout("color = $color");
			#wireframe color safety check.
			if (($color eq "none") || ($color eq "")){
				popup("--DOH!  My wireframe color safety check failed!");
				$color = "uniform";
				lx("user.value senWireColor uniform");
			}
			lx("view3d.wireframeOverlay $color");


			#turn on vert display if needed.
			if (lxq("user.value senDisplayVerts ?") == 1){
				lx("view3d.showVertices 1");
			}else{
				lx("view3d.showVertices 0");
			}
		}
	}else{
		lxout("-I'm actually toggling ALL, because toggleWireframe was run and selections weren't being drawn");
		&toggleAll;
	}
}


#--------------------------------------------------------------------------------------------------
#TOGGLE WIRE COLOR SUB
#--------------------------------------------------------------------------------------------------
sub toggleWireColor{
	#SELECT WINDOW UNDER MOUSE
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}

	#ONLY TOGGLE VERT DISPLAY IF WIREFRAME IS DISPLAYED RIGHT NOW!!!
	if (lxq("view3d.wireframeOverlay ?") ne "none"){
		lxout("-toggling wireframe color");

		#TOGGLE FROM UNIFORM TO COLORED
		if (lxq("view3d.wireframeOverlay ?") eq "uniform"){
			lxout("TOGGLE FROM UNIFORM TO COLORED");
			lx("view3d.wireframeOverlay colored");
			lx("user.value senWireColor colored");
		}

		#TOGGLE FROM COLORED TO UNIFORM
		elsif (lxq("view3d.wireframeOverlay ?") eq "colored"){
			lxout("TOGGLE FROM COLORED TO UNIFORM");
			lx("view3d.wireframeOverlay uniform");
			lx("user.value senWireColor uniform");
		}
	}
}


#--------------------------------------------------------------------------------------------------
#TOGGLE ALL SUB
#--------------------------------------------------------------------------------------------------
sub toggleAll{
	#SELECT WINDOW UNDER MOUSE
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}
	lxout("-Now toggling ALL");

	#TURN OFF ALL
	if (lxq("view3d.showSelections ?") == 1){
		#remember the settings
		my $wireColor = lxq("view3d.wireframeOverlay ?");
		my $vertDisplay = lxq("view3d.showVertices ?");
		lxout("wireColor = $wireColor <><> vertDisplay = $vertDisplay");

		#only write down wirecolor if there is one.
		if ($wireColor eq "none"){
			lx("user.value senDisplayWire 0");
		}else{
			lx("user.value senDisplayWire 1");
			lx("user.value senWireColor $wireColor");
		}
		lx("user.value senDisplayVerts $vertDisplay");

		lx("view3d.showSelections 0");
		lx("view3d.wireframeOverlay none");
		lx("view3d.showVertices 0");
	}

	#TURN ON ALL
	else{
		my $vertDisplay	= lxq("user.value senDisplayVerts ?");
		my $wireColor	= lxq("user.value senWireColor ?");
		my $wireDisplay	= lxq("user.value senDisplayWire ?");
		lxout("wireDisplay = $wireDisplay");

		lx("view3d.showSelections 1");
		lx("view3d.showVertices $vertDisplay");
		if ($wireDisplay == 1){	lx("view3d.wireframeOverlay $wireColor");	}
	}
}


#----------------------------------------------------------------------------------------------------
#TOGGLE VIEWPORT FROM WIREFRAME AND BACK.
#----------------------------------------------------------------------------------------------------
sub toggleViewport{
	#SELECT WINDOW UNDER MOUSE
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}

	lxout("-Toggling viewport to and from WIREFRAME");
	if (lxq("view3d.shadingStyle ?") ne "wire"){
		my $viewMode = lxq("view3d.shadingStyle ?");
		lx("user.value senViewMode $viewMode");
		lx("view3d.shadingStyle wire");
	}else{
		#check for shade mode uservalue. #if it didn't exist, use "shaded".
		my $senViewMode = lxq("user.value senViewMode ?");
		if (($senViewMode eq "temp") || ($senViewMode eq "wire")){
			$senViewMode = "shade";
		}
		lx("view3d.shadingStyle $senViewMode");
	}
}


#----------------------------------------------------------------------------------------------------
#TOGGLE VIEWPORT FROM WEIGHTMAP AND BACK.
#----------------------------------------------------------------------------------------------------
sub toggleWeighting{
	lxout("-Toggling viewport to and from WEIGHTMAP");
	my @weightMaps = lxq("query layerservice vmaps ? weight");
	my $weightMapSelected = 0;

	#SELECT WINDOW UNDER MOUSE
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}

	foreach my $weightMap (@weightMaps){
		lxout("weightMap = $weightMap");
		if (lxq("query layerservice vmap.selected ? $weightMap") == 1){
			lxout("-There was a weightmap already selected, so I'm keeping it selected");
			$weightMapSelected = 1;
		}
	}

	if (lxq("view3d.shadingStyle ?") ne "vmap"){
		my $viewMode = lxq("view3d.shadingStyle ?");
		lx("user.value senViewMode $viewMode");

		#only select "subdivision" if no vmaps are selected.
		if ($weightMapSelected == 0){	lx("select.vertexMap Subdivision subd replace");	}

		lx("view3d.shadingStyle vmap");
	}else{
		#check for shade mode uservalue. #if it didn't exist, use "shaded".
		my $senViewMode = lxq("user.value senViewMode ?");
		if (($senViewMode eq "temp") || ($senViewMode eq "vmap")){
			$senViewMode = "shade";
		}
		lx("view3d.shadingStyle $senViewMode");
	}
}


#----------------------------------------------------------------------------------------------------
#TOGGLE TOOL HANDLE VISIBILITY
#----------------------------------------------------------------------------------------------------
sub toggleHandle{
	if ($toolStyle ne "advanced")	{	$toolStyle = "basic";	}
	if ($singleHandle != 1)			{	$singleHandle = 0;	}

	#TOGGLE ONLY THE SINGLE TOOL HANDLE
	if ($singleHandle == 1){
		lxout("[->] Toggling only this single handle");
		my $a = lxq("tool.handleStyle style:?");
		if($a == 0){ #TEMP
			lxout("this tool handle is now VISIBLE?");
			$a = 3;
		}else{
			lxout("this tool handle is now HIDDEN");
			our $drawHandles = 0;
			$a = 0;
		}
		lx("tool.handleStyle $a");
	}


	#TOGGLE ALL TOOL HANDLES
	else{
		lxout("[->] Toggling All TOOL HANDLES");
		if (lxq("pref.value handles.toolHandleUnsel ?") ne "invisible" ){
			lxout("tool handles are now INVISIBLE");
			lx("pref.value handles.toolHandleUnsel invisible");
			lx("pref.value handles.toolHandleSel invisible");
			our $drawHandles = 0;
		}else{
			lxout("tool handles are now VISIBLE");
			lx("pref.value handles.toolHandleUnsel $toolStyle");
			lx("pref.value handles.toolHandleSel $toolStyle");
			our $drawHandles = 1;
		}
	}


	#HIDE OR SHOW THE AXIS HANDLES.
	if (($axisVisible == 1) && ($drawHandles != 0)){	$axisVisible = basic;	}
	else{												$axisVisible = none;	}
	lx("!!tool.flag center.auto visible [$axisVisible]");
	lx("!!tool.flag center.select visible [$axisVisible]");
	lx("!!tool.flag center.element visible [$axisVisible]");
	lx("!!tool.flag center.view visible [$axisVisible]");
	lx("!!tool.flag center.origin visible [$axisVisible]");
	lx("!!tool.flag center.local visible [$axisVisible]");
	lx("!!tool.flag center.pivot visible [$axisVisible]");
	lx("!!tool.flag axis.auto visible [$axisVisible]");
	lx("!!tool.flag axis.select visible [$axisVisible]");
	lx("!!tool.flag axis.element visible [$axisVisible]");
	lx("!!tool.flag axis.view visible [$axisVisible]");
	lx("!!tool.flag axis.origin visible [$axisVisible]");
	lx("!!tool.flag axis.local visible [$axisVisible]");
	lx("!!tool.flag axis.pivot visible [$axisVisible]");
}


#----------------------------------------------------------------------------------------------------
#TOGGLE VIEWPORT BETWEEN FRONT AND PERSPECTIVE
#----------------------------------------------------------------------------------------------------
sub togglePersp{
	#select window mouse is over
	lxout("sdfl");
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}

	if (lxq("view3d.projection ?") eq "psp"){
		my $view = lxq("query view3dservice mouse.view ?");
		my @viewAxis = lxq("query view3dservice view.axis ? $view");
		lxout("viewAxis = @viewAxis");
		my $greatestDP = 0;
		my $winnerViewport = "";

		my @axisFront =		(0,0,-1);
		my @axisBack =		(0,0,1);
		my @axisTop =		(0,-1,0);
		my @axisBottom =	(0,1,0);
		my @axisLeft =		(1,0,0);
		my @axisRight =		(-1,0,0);

		my $dp_front =		dotProduct(\@viewAxis,\@axisFront);
		my $dp_back =		dotProduct(\@viewAxis,\@axisBack);
		my $dp_top =		dotProduct(\@viewAxis,\@axisTop);
		my $dp_bottom =		dotProduct(\@viewAxis,\@axisBottom);
		my $dp_left =		dotProduct(\@viewAxis,\@axisLeft);
		my $dp_right =		dotProduct(\@viewAxis,\@axisRight);
		lxout("dp_front = $dp_front");

		if ($dp_front > $greatestDP)	{	$winnerViewport = "fnt";	$greatestDP = $dp_front;	lxout("yes : fnt");}
		if ($dp_back > $greatestDP)		{	$winnerViewport = "bck";	$greatestDP = $dp_back;		lxout("yes : bak");}
		if ($dp_top > $greatestDP)		{	$winnerViewport = "top";	$greatestDP = $dp_top;		lxout("yes : top");}
		if ($dp_bottom > $greatestDP)	{	$winnerViewport = "bot";	$greatestDP = $dp_bottom;	lxout("yes : bot");}
		if ($dp_left > $greatestDP)		{	$winnerViewport = "lft";	$greatestDP = $dp_left;		lxout("yes : lft");}
		if ($dp_right > $greatestDP)	{	$winnerViewport = "rgt";	$greatestDP = $dp_right;	lxout("yes : rgt");}


		lx("view3d.projection {$winnerViewport}");
	}else{
		lx("view3d.projection psp");
	}
}


#----------------------------------------------------------------------------------------------------
#TOGGLE FOREGROUND AND BACKGROUND SHADING
#----------------------------------------------------------------------------------------------------
sub toggleFGBG{
	#SELECT WINDOW UNDER MOUSE
	if ($skipVPSel != 1){lx("select.viewport fromMouse:1");}

	lxout("-Toggling viewport from to and from WIREFRAME");
	if ($modoVer > 700){
		if (lxq("view3d.shadingStyle ?") ne "wire"){
			my $viewMode = lxq("view3d.shadingStyle ?");
			lx("user.value senViewMode $viewMode");
			lx("view3d.shadingStyle wire");
			lx("view3d.bgLayerDisplay flat");
			lx("view3d.wireframeOverlay none inactive");
		}else{
			#check for shade mode uservalue. #if it didn't exist, use "shaded".
			my $senViewMode = lxq("user.value senViewMode ?");
			if (($senViewMode eq "temp") || ($senViewMode eq "wire")){
				$senViewMode = "shade";
			}
			lx("view3d.shadingStyle $senViewMode");

			#when you toggle the fg from wire to shade or not, one mode is for used regularly and the other mode is good for when you're building over a static mesh which normally doens't draw wireframes correctly
			if (lxq("user.value senFGWireMode ?") == 1)	{	lx("view3d.bgLayerDisplay wire");			}
			else										{	lx("!!view3d.shadingStyle shade inactive");	}

			lx("!!view3d.wireframeOverlay none inactive");
			lx("!!view3d.smoothing false inactive");


			if (lxq("user.value senDisplayWire ?") == 1){
				my $wireColor = lxq("user.value senWireColor ?");
				lx("view3d.wireframeOverlay {$wireColor}");
			}
		}
	}else{
		if (lxq("view3d.shadingStyle ?") ne "wire"){
			my $viewMode = lxq("view3d.shadingStyle ?");
			lx("user.value senViewMode $viewMode");
			lx("view3d.shadingStyle wire");
			lx("view3d.bgLayerDisplay flat");
		}else{
			#check for shade mode uservalue. #if it didn't exist, use "shaded".
			my $senViewMode = lxq("user.value senViewMode ?");
			if (($senViewMode eq "temp") || ($senViewMode eq "wire")){
				$senViewMode = "shade";
			}
			lx("view3d.shadingStyle $senViewMode");
			lx("view3d.bgLayerDisplay wire");
			if (lxq("user.value senDisplayWire ?") == 1){
				my $wireColor = lxq("user.value senWireColor ?");
				lx("view3d.wireframeOverlay {$wireColor}");
			}
		}
	}
}

#----------------------------------------------------------------------------------------------------
#TOGGLE ITEM REFERENCE ON/OFF
#----------------------------------------------------------------------------------------------------
sub toggleItemRef{
	my $mainlayer = lxq("query layerservice layers ? main");
	my $mainlayerID = lxq("query layerservice layer.id ? $main");
	my $currentReference = lxq("item.refSystem ?");

	if ($currentReference eq $mainlayerID){
		lxout("[-->] : Clearing Item Reference System");
		lx("item.refSystem {}");
	}else{
		lxout("[-->] : Setting the Item Reference System to use $mainlayerID");
		lx("item.refSystem $mainlayerID");
	}
}

#----------------------------------------------------------------------------------------------------
#INCREASE VIEWPORT BRIGHTNESS
#----------------------------------------------------------------------------------------------------
sub increaseBrightness{
	lx("tool.set viewport.lightRig on");
	lx("tool.apply");
	lx("tool.attr viewport.lightRig current 0");

	my $brightness = lxq("tool.attr viewport.lightRig intensity ?");
	$brightness = $brightness * .1 + $brightness;
	lx("tool.attr viewport.lightRig intensity {$brightness}");

	lx("tool.attr viewport.lightRig current 1");
	$brightness = lxq("tool.attr viewport.lightRig intensity ?");
	$brightness = $brightness * .1 + $brightness;
	lx("tool.attr viewport.lightRig intensity {$brightness}");
	lx("tool.set viewport.lightRig off");
}

#----------------------------------------------------------------------------------------------------
#INCREASE VIEWPORT BRIGHTNESS
#----------------------------------------------------------------------------------------------------
sub decreaseBrightness{
	lx("tool.set viewport.lightRig on");
	lx("tool.attr viewport.lightRig current 0");
	my $brightness = lxq("tool.attr viewport.lightRig intensity ?");
	$brightness = $brightness - $brightness * .1;
	lx("tool.attr viewport.lightRig intensity {$brightness}");

	lx("tool.attr viewport.lightRig current 1");
	$brightness = lxq("tool.attr viewport.lightRig intensity ?");
	$brightness = $brightness - $brightness * .1;
	lx("tool.attr viewport.lightRig intensity {$brightness}");
	lx("tool.set viewport.lightRig off");
}

#----------------------------------------------------------------------------------------------------
#INCREASE VIEWPORT BRIGHTNESS
#----------------------------------------------------------------------------------------------------
sub resetBrightness{
	lx("tool.set viewport.lightRig on");
	lx("tool.attr viewport.lightRig current 0");
	lx("tool.attr viewport.lightRig intensity {0.7}");

	lx("tool.attr viewport.lightRig current 1");
	lx("tool.attr viewport.lightRig intensity {0.3}");
	lx("tool.set viewport.lightRig off");
}



#========================================
#========================================
#SUBROUTINES
#========================================
#========================================
sub popup() #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){!!die;}
}

#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SET UP THE USER VALUE OR VALIDATE IT   (no popups)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
#DOT PRODUCT subroutine (ver 1.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $dp = dotProduct(\@vector1,\@vector2);
sub dotProduct{
	return (	(${$_[0]}[0]*${$_[1]}[0])+(${$_[0]}[1]*${$_[1]}[1])+(${$_[0]}[2]*${$_[1]}[2])	);
}

