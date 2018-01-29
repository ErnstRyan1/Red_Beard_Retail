#perl
#AUTHOR: Seneca Menard
#version 1.23
#This script is to take a card cfg and build a layer for each card in the cfg, and will build polys for each button.
#This script comes with a modo form, because it's got a number of buttons and user variables.
#The way this script assigns values to cards or buttons are through USER VARIABLES and POLYGON PARTS.

#It'd take too long to type out all the information about this script and so I'll make a video to illustrate how to use this script.
#But, I'll type out where exactly I store/read the data that's in the card form.

#	-I store the UI ELEMENTS data as one single USER.VARIABLE.  You'll see it as the "COLOR SETS:" line in the the CARD CREATION TOOLS form. (colorScheme,eachColorName,eachColorRGB)
#	-I store the CARD DEFINITION DATA as USER.VARIABLES.  You'll see them displayed in the CARD CREATION TOOLS form. (cardSetName,cardSetUsername,cardSetDescription,cardSetScheme,cardSetColor,cardSetTransition)
#	-I store the CARD SETTINGS DATA as POLYGON PARTS applied to the "background polygon" eg : (cardUsername,cardDescription,cardIndex,cardColor).  (I store the CARD NAME in the layer's name, and I store the CARD IMAGE as the image applied to the polygons in that layer)
#	-I store the BUTTON COMMANDS as POLYGON PARTS applied to each button.  eg : (name,command)

#Oh, and here's a list of stuff not to do..  :P
#	-Don't put any spaces after the commas when you type in the data using the POLY.SETPART tool.  I'm not removing any spaces in the script...
#	-Don't leave any extra polys or layers in the scene, because they might generate junk data in your cfg.
#	-When you add a new card, it's best to fill in all the blanks of my popups so you don't possibly corrupt the card by not supplying enough data.
#	-You shouldn't delete all the info from the form.  If you do, it could corrupt the card, and so that's why I put in the RESET VALUES button, so you can use the data that Brad used with his forms.

#(2-11-07 bugfix) : There was an extra slash in the image path somehow.  That's now fixed.
#(9-7-07 bugfix) : rewrote the uv map selection code
#(4-27-08 bugfix) : The script is now ported to work on the mac
#(12-18-08 fix) : I went and removed the square brackets so that the numbers will always be read as metric units and also because my prior safety check would leave the unit system set to metric system if the script was canceled because changing that preference doesn't get undone if a script is cancelled.
#(1-30-09 fix) : removed a meaningless popup that would occur the first time you run the script.
#(2-16-15 fix) : fixed a bug in the roundNumber sub

my $os =			lxq("query platformservice ostype ?");
my $modoDir =		lxq("query platformservice path.path ? program");
my $userDir =		lxq("query platformservice path.path ? user");
my $mainlayer =		lxq("query layerservice layers ? main");
my $modoVer =		lxq("query platformservice appversion ?");
my $exportCard =	 "C:\/Documents and Settings\/seneca\/Application Data\/Luxology\/scripts\/super_UVToolsCard_new.cfg";
my %buttonTable;
my %schemeTable;
my $count;
my $layerCount = 0;
my $schemeCount = -1;
my %cardInfo;
my $currentLine;

#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#USER VALUES
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
userValueTools(sene_cardCreateColor,string,temporary,"card BG color?","","","",xxx,xxx,"","set.bg");
userValueTools(sene_cardCreateIndex,integer,temporary,"card INDEX?","","","",xxx,xxx,"",1);
userValueTools(sene_cardCreateDescription,string,temporary,"card description?","","","",xxx,xxx,"","---");
userValueTools(sene_cardCreateUsername,string,temporary,"card username?","","","",xxx,xxx,"","---");
userValueTools(sene_cardCreateName,string,temporary,"card name?","","","",xxx,xxx,"","---");
#---------------------------------------------------------------------------------------------------------------------------
userValueTools(sene_cardSet,string,config,"(CARD SET) Name","","","",xxx,xxx,"","---");
userValueTools(sene_cardUserName,string,config,"(CARD SET) User Name","","","",xxx,xxx,"","---");
userValueTools(sene_cardDescription,string,config,"(CARD SET) Description","","","",xxx,xxx,"","---");
userValueTools(sene_cardScheme,string,config,"(CARD SET) Scheme","","","",xxx,xxx,"",DefaultCardSet);
userValueTools(sene_cardColorDefault,string,config,"(CARD SET) Color","","","",xxx,xxx,"","set.bg");
userValueTools(sene_cardTransition,string,config,"(CARD SET) Transition Time","","","",xxx,xxx,"","dissolve 500");
userValueTools(sene_cardSetScheme,string,config,"(CARD SET) Scheme","","","",xxx,xxx,"","DefaultCardSet,set.bg=1.0 1.0 1.0,set.text=0.1 0.1 0.3,set.lighttext=0.8 0.8 1.0,set.darktext=0.0 0.0 0.1,set.card2bg=1.0 1.0 1.0,set.card3bg=1.0 1.0 1.0,set.card4bg=.28 .28 .28,set.card5bg=.00 .00 .00");

#make sure they're loaded:
my $sene_cardSet = 			lxq("user.value sene_cardSet ?");
my $sene_cardUserName = 	lxq("user.value sene_cardUserName ?");
my $sene_cardDescription = 	lxq("user.value sene_cardDescription ?");
my $sene_cardScheme = 		lxq("user.value sene_cardScheme ?");
my $sene_cardColorDefault = lxq("user.value sene_cardColorDefault ?");
my $sene_cardTransition = 	lxq("user.value sene_cardTransition ?");
my $sene_cardSetScheme = 	lxq("user.value sene_cardSetScheme ?");







#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SCRIPT ARGUMENTS
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
foreach my $arg (@ARGV){
	if		($arg eq "import")		{	&cardToPolys;	}
	elsif	($arg eq "export")		{	&polysToCard;	}
	elsif	($arg eq "newCard")		{	&newCard;		}
 	elsif	($arg eq "resetValues")	{	&resetValues;	}
}








#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CONVERT A CARD FORM INTO POLYGONS SUBROUTINE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub cardToPolys{
	lx("scene.new");

	#----------------------------------------------------------------------------------------------------------
	#SELECT THE VMAP FIRST
	#----------------------------------------------------------------------------------------------------------
	&selectVmap;

	#----------------------------------------------------------------------------------------------------------
	#LET THE USER CHOOSE WHICH CFG TO IMPORT
	#----------------------------------------------------------------------------------------------------------
	lx("dialog.setup fileOpen");
	lx("dialog.fileType config");
	lx("dialog.title {CFG to IMPORT}");
	lx("dialog.open");
	my $originalCard = lxq("dialog.result ?");
	if ($os =~ "Win"){	$originalCard =~ s/\//\\\//g;	}


	#----------------------------------------------------------------------------------------------------------
	#GO THRU ALL THE LINES IN THE CARD AND SEPERATE THEM INTO A TABLE
	#CARD : 0=name <> 1=username <> 2=description <> 3=index <> 4=color <> 5=image
	#BUTTON : 0=name <> 1-4=bbox <>5=script command.
	#----------------------------------------------------------------------------------------------------------
	open (ORIGINALCARD, "<$originalCard") or die("I couldn't find the original card");
	while ($line = <ORIGINALCARD>){

		#------------------------------------------------------------------
		#CARD INFO + CARD DEFINITION INFO
		#------------------------------------------------------------------
		#CUT OUT THE CARD NAME (OR DEFINITION CARD SET NAME)
		if (($line =~ "type\=\"Card\"") || ($line =~ "hash type\=\"CardSet\"")){
			if ($line =~ "type\=\"Card\""){$layerCount++;}

			my @split = split(/key=/, $line);
			my $name = @split[-1];
			$name =~ s/\"//g;
			$name =~ s/>//g;
			$name =~ s/\n//g;
			@{$cardInfo{$layerCount}}[0] = $name;
		}

		#CUT OUT THE USERNAME (OR DEFINITION USERNAME)
		elsif ($line =~ "type\=\"UserName\""){
			my @split = split(/\">/, $line);
			my $name = @split[-1];
			$name =~ s/\<\/atom\>//g;
			$name =~ s/\n//g;
			@{$cardInfo{$layerCount}}[1] = $name;
		}

		#CUT OUT THE DESCRIPTION (OR DEFINITION DESCRIPTION)
		elsif ($line =~ "type\=\"Desc\""){
			my @split = split(/\">/, $line);
			my $name = @split[-1];
			$name =~ s/\<\/atom\>//g;
			$name =~ s/\n//g;
			@{$cardInfo{$layerCount}}[2] = $name;
		}

		#CUT OUT THE INDEX (OR DEFINITION SCHEME)
		elsif (($line =~ "type\=\"Index\"") || ($line =~ "atom type\=\"Scheme\"")){
			my @split = split(/\">/, $line);
			my $name = @split[-1];
			$name =~ s/\<\/atom\>//g;
			$name =~ s/\n//g;
			@{$cardInfo{$layerCount}}[3] = $name;
		}

		#CUT OUT THE ATOM COLOR (OR DEFINITION COLOR)
		elsif ($line =~ "atom type\=\"Color\""){
			my @split = split(/\">/, $line);
			my $name = @split[-1];
			$name =~ s/\<\/atom\>//g;
			$name =~ s/\n//g;
			@{$cardInfo{$layerCount}}[4] = $name;
		}

		#CUT OUT THE IMAGE (OR DEFINITION TRANSITION)
		elsif (($line =~ "type\=\"ImagePath\"") || ($line =~ "atom type\=\"Transition\">")){
			my @split = split(/\">/, $line);
			my $name = @split[-1];
			$name =~ s/\<\/atom\>//g;
			if ($os =~ "Win"){	#WINDOWS
				$name =~ s/\s+\n//g;
				$name =~ s/\n//g;
				$name =~ s/\//\\/g;
				$name =~ s/Resource:/$modoDir\\resrc\\/;
				$name =~ s/resource:/$modoDir\\resrc\\/;
				$name =~ s/Prefs:/$userDir\\/;
				$name =~ s/prefs:/$userDir\\/;
				$name =~ s/license:/$userDir\\/;
				$name =~ s/user:/$userDir\\/;
			}else{			#MAC
				$modoDir =~ s/Applications\//Applications/;
				$name =~ s/\s+\n//g;
				$name =~ s/\n//g;
				$name =~ s/Resource:/$modoDir\/modo.app\/Contents\/Resources\//;
				$name =~ s/resource:/$modoDir\/modo.app\/Contents\/Resources\//;
				$name =~ s/Prefs:/$userDir\//;
				$name =~ s/prefs:/$userDir\//;
				$name =~ s/license:/$userDir\//;
				$name =~ s/user:/$userDir\//;
			}
			@{$cardInfo{$layerCount}}[5] = $name;
		}

		#------------------------------------------------------------------
		#BUTTON INFO
		#------------------------------------------------------------------
		#CUT OUT THE REGION LINE
		elsif ($line =~ "type\=\"Region\""){
			$count++;
			my @split = split(/key=/, $line);
			my $name = @split[-1];
			$name =~ s/\"//g;
			$name =~ s/>//g;
			$name =~ s/\n//g;
			$currentLine = $name;
		}

		#CUT OUT THE BUTTON SIZE LINE
		elsif ($line =~ "type\=\"Box\""){
			$line =~ s/[^0-9\s]//g;
			my @numbers = split (/\s+/, $line);
			if (@numbers[0] eq "")	{	shift(@numbers);	}
			foreach my $number (@numbers)	{	$currentLine .= "," . $number;	}
		}

		#CUT OUT THE ACTUAL SCRIPT LINE
		elsif ($line =~ "type\=\"Command\""){
			my @split = split (/mand\">/, $line);
			my $script = @split[-1];
			$script =~ s/<\/atom>//;
			$script =~ s/\n//g;
			$currentLine .= "," . $script;

			#add the current "line" to the hash table
			push(@{$buttonTable{$layerCount}},$currentLine);
			#lxout("($layerCount) currentLine = $currentLine");
		}

		#CUT OUT THE LINK LINE
		elsif ($line =~ "type\=\"CardName\""){
			my @split = split (/Name\">/, $line);
			my $link = @split[-1];
			$link =~ s/<\/atom>//;
			$link =~ s/\n//g;
			$currentLine .= ",LINK\=" . $link;

			#add the current "line" to the hash table
			push(@{$buttonTable{$layerCount}},$currentLine);
			#lxout("($layerCount) currentLine = $currentLine");
		}

		#------------------------------------------------------------------
		#UI ELEMENTS INFO
		#------------------------------------------------------------------
		#CUT OUT THE HASH SCHEME
		elsif ($line =~ "hash type\=\"Scheme\""){
			$schemeCount++;
			my @split = split(/\=\"/, $line);
			my $name = @split[-1];
			$name =~ tr/\">//d;
			$name =~ s/\n//g;
			push (@{$schemeTable{$schemeCount}}, $name);
		}

		#CUT OUT THE HASH COLOR
		elsif ($line =~ "hash type\=\"Color\""){
			my @split = split(/key\=\"/, $line);
			my $name = @split[-1];
			$name =~ tr/\">//d;
			$name =~ s/\n//g;
			push (@{$schemeTable{$schemeCount}}, $name);
		}

		#CUT OUT THE ATOM RGB
		elsif ($line =~ "atom type\=\"RGB\""){
			my @split = split(/RGB\">/, $line);
			my $name = @split[-1];
			$name =~ s/\<\/atom\>//g;
			$name =~ s/\n//g;
			push (@{$schemeTable{$schemeCount}}, $name);
		}
	}
	close(ORIGINALCARD);


	#print out the total card and button list.
	lxout("There are ($layerCount) cards");
	for (my $i=1; $i<$layerCount+1; $i++){
		#print card info
		lxout("($i) @{$cardInfo{$i}}[0],@{$cardInfo{$i}}[1],@{$cardInfo{$i}}[2],@{$cardInfo{$i}}[3],@{$cardInfo{$i}}[4],@{$cardInfo{$i}}[5],@{$cardInfo{$i}}[6]");

		#print button info
		foreach my $button (@{$buttonTable{$i}}){
			lxout("($i) $button");
		}
	}







	#----------------------------------------------------------------------------------------------------------
	#NOW GO BUILD THE POLYS IN MODO
	#0=name <> 1-4=bbox <>5=script command.
	#----------------------------------------------------------------------------------------------------------
	for (my $i=1; $i<($layerCount+1); $i++){
		if ($i != 1){	lx("layer.new $i");	}
		lx("item.name @{$cardInfo{$i}}[0] mesh");
		$mainlayer = lxq("query layerservice layers ? main");

		#----------------------------------------------------------------------------------------------------------
		#NOW LOAD THE IMAGE, SO I KNOW WHAT SIZE IT IS AND APPLY IT (to nothing)
		#----------------------------------------------------------------------------------------------------------
		lx("poly.setMaterial [@{$cardInfo{$i}}[0]] [1.0 1.0 1.0] [80.0 %] [20.0 %] [1] [1]");
		my $mask;
		my $txLayers = lxq("query sceneservice txLayer.n ?");
		for (my $u=0; $u<$txLayers; $u++){
			if (lxq("query sceneservice txLayer.type ? $u") eq "mask"){
				my $ptag = lxq("query sceneservice channel.value ? ptag");
				if ($ptag eq @{$cardInfo{$i}}[0]){
					$mask = lxq("query sceneservice txLayer.id ? $u");
				}
			}
		}

		if ($mask eq ""){die("Couldn't find the new mask for some reason so I'm cancelling the script.");}
		lx("texture.new [@{$cardInfo{$i}}[5]]");
		lx("texture.parent [$mask] [-1]");

		#find the image size.
		my $clips = lxq("query layerservice clip.n ?");
		my $currentClip = $clips - 1;
		my $clipInfo = lxq("query layerservice clip.info ? $currentClip");
		my $clipID = lxq("query layerservice clip.id ? $currentClip");
		my @clipSize = split(/\D+/, $clipInfo);
		my $width = @clipSize[1];
		my $height = @clipSize[2];


		#----------------------------------------------------------------------------------------------------------
		#BUILD THE BUTTONS
		#----------------------------------------------------------------------------------------------------------
		foreach my $line (@{$buttonTable{$i}}){
			my @button = split(/,/, $line);
			my $cenX =	(@button[1] + @button[3]) * 0.5;
			my $sizX =	(@button[3] - @button[1]);
			my $cenY =	(@button[2] + @button[4]) * -0.5;
			my $sizY =	(@button[4] - @button[2]);
			my $part =	(@button[0] . "," . @button[5]);

			lx("tool.set prim.cube on");
			lx("tool.reset");
			lx("tool.setAttr prim.cube cenX {$cenX}");
			lx("tool.setAttr prim.cube sizeX {$sizX}");
			lx("tool.setAttr prim.cube cenY {$cenY}");
			lx("tool.setAttr prim.cube sizeY {$sizY}");
			lx("tool.setAttr prim.cube cenZ {0}");
			lx("tool.setAttr prim.cube sizeZ {0}");
			lx("tool.setAttr prim.cube axis {1}");
			lx("tool.doApply");
			lx("tool.set prim.cube off");

			#apply the poly part.
			my $polys = lxq("query layerservice poly.n ? all") - 1;
			lx("select.drop polygon");
			lx("select.element $mainlayer polygon set {$polys}");
			lxout("part = $part");
			lx("poly.setPart [$part]");
		}


		#----------------------------------------------------------------------------------------------------------
		#NOW CREATE THE BACK POLY AND APPLY THE UVS.
		#----------------------------------------------------------------------------------------------------------
		my $cenX	= $width * 0.5;
		my $cenY	= $height * -0.5;
		lx("tool.set prim.cube on");
		lx("tool.reset");
		lx("tool.setAttr prim.cube cenX {$cenX}");
		lx("tool.setAttr prim.cube sizeX {$width}");
		lx("tool.setAttr prim.cube cenY {$cenY}");
		lx("tool.setAttr prim.cube sizeY {$height}");
		lx("tool.setAttr prim.cube cenZ {-2}");
		lx("tool.setAttr prim.cube sizeZ {0}");
		lx("tool.setAttr prim.cube axis 1");
		lx("tool.doApply");
		lx("tool.set prim.cube off");

		#apply the part to this polygon
		my $part = "(--CARD--)".",".@{$cardInfo{$i}}[1].",".@{$cardInfo{$i}}[2].",".@{$cardInfo{$i}}[3].",".@{$cardInfo{$i}}[4];
		my $polys = lxq("query layerservice poly.n ? all");
		my $poly = $polys - 1;
		lx("select.drop polygon");
		lx("select.element $mainlayer polygon set {$poly}");
		lx("poly.setPart [$part]");

		lx("select.drop polygon");
		lx("select.invert");
		lx("poly.setMaterial [@{$cardInfo{$i}}[0]] [1.0 1.0 1.0] [80.0 %] [20.0 %] [1] [1]");

		lx("tool.set uv.create on");
		lx("tool.reset");
		lx("tool.attr uv.create proj planar");
		lx("tool.attr uv.create mode manual");
		lx("tool.setAttr uv.create cenX {$cenX}");
		lx("tool.setAttr uv.create cenY {$cenY}");
		lx("tool.setAttr uv.create cenZ {1}");
		lx("tool.setAttr uv.create sizX {$width}");
		lx("tool.setAttr uv.create sizY {$height}");
		lx("tool.setAttr uv.create sizZ {2}");
		lx("tool.setAttr uv.create seam {0}");
		lx("tool.setAttr uv.create axis {2}");
		lx("tool.doApply");
		lx("tool.set uv.create off");
	}

	#----------------------------------------------------------------------------------------------------------
	#NOW GO SET THE USER VALUES
	#----------------------------------------------------------------------------------------------------------
	#popup("@{$cardInfo{0}}[0],@{$cardInfo{0}}[1],@{$cardInfo{0}}[2],@{$cardInfo{0}}[3],@{$cardInfo{0}}[4],@{$cardInfo{0}}[5],@{$cardInfo{0}}[6]");
	my $name		= @{$cardInfo{0}}[0];
	my $username	= @{$cardInfo{0}}[1];
	my $description	= @{$cardInfo{0}}[2];
	my $scheme	= @{$cardInfo{0}}[3];
	my $color		= @{$cardInfo{0}}[4];
	my $transition	= @{$cardInfo{0}}[5];
	my $setScheme	= @{$schemeTable{0}}[0];	#TEMP TEMP. it only pays attention to one scheme.  so if there's multiples, it'll skip the others.
	for (my $i=1; $i<@{$schemeTable{0}}; $i+=2){  $setScheme .= ",".@{$schemeTable{0}}[$i]."=".@{$schemeTable{0}}[$i+1];}

	lx("user.value sene_cardSet [$name]");
	lx("user.value sene_cardUserName [$username]");
	lx("user.value sene_cardDescription [$description]");
	lx("user.value sene_cardScheme [$scheme]");
	lx("user.value sene_cardColorDefault [$color]");
	lx("user.value sene_cardTransition [$transition]");
	lx("user.value sene_cardSetScheme [$setScheme]");
}










#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CONVERT THE SCENE'S LAYERS AND POLYS INTO A CARD FORM SUBROUTINE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub polysToCard{
	#----------------------------------------------------------------------------------------------------------
	#LET THE USER PICK A FILE TO SAVE TO AND OPEN IT.
	#----------------------------------------------------------------------------------------------------------
	lx("dialog.setup fileSave");
	lx("dialog.fileType config");
	lx("dialog.title {EXPORT CFG}");
	lx("dialog.open");
	my $exportCard = lxq("dialog.result ?");
	if ($os =~ "win"){$exportCard =~ s/\//\\\//g;}
	open (EXPORTCARD, ">$exportCard") or die("I can't open the export file");
	my $modoDirMod = $modoDir."\\resrc\\";
	my $userDirMod = $userDir;
	$modoDirMod =~ s/\\/\\\\/g;
	$userDirMod =~ s/\\/\\\\/g;


	#----------------------------------------------------------------------------------------------------------
	#BUILD A LIST OF ALL IMAGES IN EACH MATERIAL.
	#----------------------------------------------------------------------------------------------------------
	&listAllMaterialImageSizes;


	#----------------------------------------------------------------------------------------------------------
	#LOOP THRU ALL LAYERS AND BUILD AN ARRAY OF THEIR DATA.
	#----------------------------------------------------------------------------------------------------------
	my %buttonTable;
	my %cardInfo;
	my $layers = lxq("query layerservice layer.n ? all");

	for (my $layer=1; $layer<$layers+1; $layer++){
		my $layerID = lxq("query layerservice layer.id ? $layer");
		my $layerName = lxq("query layerservice layer.name ? $layer");
		my $polyCount = lxq("query layerservice poly.n ? all");
		my %usedMaterials;

		#select the layer
		lx("select.subItem [$layerID] set mesh;meshInst;camera;light;txtrLocator;backdrop;groupLocator [0] [1]");
		$mainlayer = lxq("query layerservice layers ? main");
		#skip this layer if there's no polys.
		if ($polyCount == 0){	lxout("SKIPPING THIS LAYER ($layer) BECAUSE IT HAS NO POLYS");	next;	}

		for (my $i=0; $i<$polyCount; $i++){
			my $material = lxq("query layerservice poly.material ? $i");
			$usedMaterials{$material}=1;
			my @tags = lxq("query layerservice poly.tags ? $i");
			my @tagArray = split (/,/, @tags[-1]);

			#main card info
			if (@tags[-1] =~ "(--CARD--)"){
				shift(@tagArray);
				#lxout("     -layer($layer) : main card = $i <>@tagArray");
				@{$cardInfo{$layer}} = ($layerName,@tagArray);
			}

			#button info
			elsif (@tags[-1] ne "Default"){
				my @verts = lxq("query layerservice poly.vertList ? $poly");
				my @bbox = boundingbox(@verts);
				for (my $u=0; $u<@bbox ; $u++){		@bbox[$u] = roundNumber(@bbox[$u], 1);	}
				@bbox[1] *= -1;
				@bbox[4] *= -1;
				my $label = @tagArray[0].",".@bbox[0].",".@bbox[4].",".@bbox[3].",".@bbox[1].",".@tagArray[1];
				push(@{$buttonTable{$layer}},$label);
			}

			#reject poly
			else{
				lxout("     -layer($layer) : This poly ($i) doesn't have any pTags, so I'm rejecting it.");
			}

		}

		#assign this layer's chosen image to the cardInfo array.
		my @sizeWinner;
		foreach my $material (keys %usedMaterials){
			if (  (@{$materialList{$material}}[0] > @{$materialList{@sizeWinner[2]}}[0]) || (@{$materialList{$material}}[1] > @{$materialList{@sizeWinner[2]}}[1])  ){
				@sizeWinner = (@{$materialList{$material}}[0],@{$materialList{$material}}[1],$material);
			}
			lxout("sizeWinner = @sizeWinner");
		}
		@{$cardInfo{$layer}}[5] = $materialList{@sizeWinner[2]}[2];
	}


	#----------------------------------------------------------------------------------------------------------
	#CREATE THE UI ELEMENTS TEXT
	#----------------------------------------------------------------------------------------------------------
	print EXPORTCARD"<?xml version\=\"1.0\" encoding\=\"UTF-8\"?>\n";
	print EXPORTCARD"<configuration>\n";
	print EXPORTCARD"\n";
	print EXPORTCARD"  <!-- UI Elements-->\n";
	print EXPORTCARD"\n";
	print EXPORTCARD"  <atom type\=\"UIElements\">\n";

	my $setScheme = lxq("user.value sene_cardSetScheme ?");
	my @schemeArray = split(/,/, $setScheme);
	if ($os =~ /mac/i){for (my $i=0; $i<@schemeArray; $i++){@schemeArray[$i] =~ s/\r//g;}}

	print EXPORTCARD"    <hash type\=\"Scheme\" key\=\"@schemeArray[0]\">\n";
	for (my $i=1; $i<@schemeArray; $i++){
		my @array = split(/\=/, @schemeArray[$i]);
		print EXPORTCARD"      <hash type\=\"Color\" key\=\"@array[0]\">\n";
		print EXPORTCARD"        <atom type\=\"RGB\">@array[1]</atom>\n";
		print EXPORTCARD"      </hash>\n";
	}
	print EXPORTCARD"    </hash>\n";
	print EXPORTCARD"  </atom>\n";
	print EXPORTCARD"\n";


	#----------------------------------------------------------------------------------------------------------
	#CREATE THE CARD DEFINITIONS TEXT
	#----------------------------------------------------------------------------------------------------------
	my $name 		= lxq("user.value sene_cardSet ?");
	my $userName 	= lxq("user.value sene_cardUserName ?");
	my $description	= lxq("user.value sene_cardDescription ?");
	my $scheme		= lxq("user.value sene_cardScheme ?");
	my $color		= lxq("user.value sene_cardColorDefault ?");
	my $transition	= lxq("user.value sene_cardTransition ?");
	if ($os =~ /mac/i){
		$name 			=~ s/\r//g;
		$userName		=~ s/\r//g;
		$description	=~ s/\r//g;
		$scheme			=~ s/\r//g;
		$color			=~ s/\r//g;
		$transition		=~ s/\r//g;
	}

	if (($name eq "---") || ($name eq "SplashCards") || ($name eq "")){popup("Woah!  The CARD SET name is '$name'.  Is that correct?  It seems like an error.  Press YES to continue the script");}
	if (($userName eq "---") || ($userName eq "modo 201") || ($userName eq "")){popup("Woah!  The CARD SET username is '$userName'.  Is that correct?  It seems like an error.  Press YES to continue the script");}

	print EXPORTCARD"  <!-- Card Definitions-->\n";
	print EXPORTCARD"\n";
	print EXPORTCARD"  <atom type\=\"CardDefinitions\">\n";
	print EXPORTCARD"    <hash type\=\"CardSet\" key\=\"$name\">\n";
	print EXPORTCARD"      <atom type\=\"UserName\">$userName</atom>\n";
	print EXPORTCARD"      <atom type\=\"Desc\">$description</atom>\n";
	print EXPORTCARD"      <atom type\=\"Scheme\">$scheme</atom>\n";
	print EXPORTCARD"      <atom type\=\"Backdrop\">\n";
	print EXPORTCARD"        <atom type\=\"Color\">$color</atom>\n";
	print EXPORTCARD"	  </atom>\n";
	print EXPORTCARD"      <atom type\=\"Transition\">$transition</atom>\n";
	print EXPORTCARD"\n";


	#----------------------------------------------------------------------------------------------------------
	#CREATE THE CARDS TEXT
	#----------------------------------------------------------------------------------------------------------
	my @keys = (keys %buttonTable);
	@keys = sort { $a <=> $b } @keys;

	foreach my $layer (@keys){
		my $name		= @{$cardInfo{$layer}}[0];
		my $userName	= @{$cardInfo{$layer}}[1];
		my $description	= @{$cardInfo{$layer}}[2];
		my $index		= @{$cardInfo{$layer}}[3];
		my $color		= @{$cardInfo{$layer}}[4];
		my $image		= @{$cardInfo{$layer}}[5];
		if ($os =~ /mac/i){
			$name 			=~ s/\r//g;
			$userName		=~ s/\r//g;
			$description	=~ s/\r//g;
			$index			=~ s/\r//g;
			$color			=~ s/\r//g;
			$image			=~ s/\r//g;
		}

		if ($os =~ "Win"){		#WINDOWS
			$image =~ 		s/$modoDirMod\\/Resource:/;
			$image =~ 		s/$userDirMod\\/user:/;    #TEMP : which is which?!
		}else{				#MAC
			$image =~ 		s/$modoDir\//Resource:/;
			$image =~ 		s/$userDir\//user:/;
		}

		print EXPORTCARD"  <!-- ($name) card-->\n";
		print EXPORTCARD"\n";
		print EXPORTCARD"      <hash type\=\"Card\" key\=\"$name\">\n";
		print EXPORTCARD"        <atom type\=\"UserName\">$userName</atom>\n";
		print EXPORTCARD"        <atom type\=\"Desc\">$description</atom>\n";
		if ($index ne ""){print EXPORTCARD"        <atom type\=\"Index\">$index</atom>\n";}
		print EXPORTCARD"        <atom type\=\"Backdrop\">\n";
		print EXPORTCARD"          <atom type\=\"Color\">$color</atom>\n";
		print EXPORTCARD"          <atom type\=\"ImagePath\">$image</atom>\n";
		print EXPORTCARD"        </atom>\n";
		print EXPORTCARD"\n";


	#----------------------------------------------------------------------------------------------------------
	#CREATE THE BUTTONS TEXT
	#----------------------------------------------------------------------------------------------------------
		foreach my $list (@{$buttonTable{$layer}}){
			my @array = split(/,/, $list);
			if ($os =~ /mac/i){
				for (my $i=0; $i<@array; $i++){
					@array[$i] =~ s/\r//g;
					@array[$i] =~ s/\n//g;
				}
			}

			print EXPORTCARD"        <hash type\=\"Region\" key\=\"@array[0]\">\n";
			print EXPORTCARD"          <atom type\=\"Box\">@array[1] @array[2] @array[3] @array[4]</atom>\n";
			print EXPORTCARD"          <atom type\=\"Action\">\n";
			if (@array[5] =~ "LINK\="){
				@array[5] =~ s/LINK\=//;
				print EXPORTCARD"            <atom type\=\"CardName\">@array[5]</atom>\n";
			}else{
				print EXPORTCARD"            <atom type\=\"Command\">@array[5]</atom>\n";
			}
			print EXPORTCARD"          </atom>\n";
			print EXPORTCARD"        </hash>\n";
		}
		print EXPORTCARD"      </hash>\n";
		print EXPORTCARD"\n";
	}
	print EXPORTCARD"  </atom>\n";
	print EXPORTCARD"</configuration>\n";
	close(EXPORTCARD);
}










#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#CREATE A NEW CARD SUBROUTINE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub newCard{
	lxout("[->] Creating a new card.");

	#select the vmap first
	&selectVmap;

	#request the image.
	lx("dialog.setup fileOpen");
	lx("dialog.title {Select the image you want for the card?}");
	lx("dialog.fileType image");
	lx("dialog.open");
	my $loadImage = lxq("dialog.result ?");
	if ($loadImage eq ""){die("The image load was canceled");}

	#request the card properties
							lx("user.value sene_cardCreateName []");
							lx("user.value sene_cardCreateName");
	my $cardName =			lxq("user.value sene_cardCreateName ?");

							lx("user.value sene_cardCreateUsername []");
							lx("user.value sene_cardCreateUsername");
	my $cardUsername =	lxq("user.value sene_cardCreateUsername ?");

							lx("user.value sene_cardCreateDescription []");
							lx("user.value sene_cardCreateDescription");
	my $cardDescription =	lxq("user.value sene_cardCreateDescription ?");

							lx("user.value sene_cardCreateIndex");
	my $cardIndex =			lxq("user.value sene_cardCreateIndex ?");

	my $tempColor =			lxq("user.value sene_cardColorDefault ?");
							lx("user.value sene_cardCreateColor $tempColor");
							lx("user.value sene_cardCreateColor");
	my $cardColor =			lxq("user.value sene_cardCreateColor ?");
	lxout("cardName = $cardName\n	cardUsername = $cardUsername\n	cardDescription = $cardDescription\n	cardIndex = $cardIndex\n	cardColor = $cardColor\n	cardImage = $loadImage\n");

	#create the card and apply the image.
	lx("layer.newItem mesh");
	lx("item.name $cardName");


	#----------------------------------------------------------------------------------------------------------
	#NOW LOAD THE IMAGE, SO I KNOW WHAT SIZE IT IS AND APPLY IT (to nothing)
	#----------------------------------------------------------------------------------------------------------
	lx("poly.setMaterial [$cardName] [1.0 1.0 1.0] [80.0 %] [20.0 %] [1] [1]");
	my $mask;
	my $txLayers = lxq("query sceneservice txLayer.n ?");
	my $last1= $txLayers-1;
	my $last2 = $txLayers-2;
	my $nameCheck1 = lxq("query sceneservice txLayer.name ? $last1");
	my $nameCheck2 = lxq("query sceneservice txLayer.name ? $last2");
	$nameCheck1 =~ tr/()//d;
	$nameCheck2 =~ tr/()//d;

	#find the mask to parent the image to.
	if       ($nameCheck1 eq $cardName)	{	$mask = lxq("query sceneservice txLayer.id ? $last1");	}
	elsif ($nameCheck2 eq $cardName)	{	$mask = lxq("query sceneservice txLayer.id ? $last2");	}
	else{
		for (my $u=0; $u<$txLayers; $u++){
			my $name = lxq("query sceneservice txLayer.name ? $u");
			$name =~ tr/()//d;
			if ($name eq $cardName){
				lxout("Interesting, my cheap way to check material names failed");
				$mask = lxq("query sceneservice txLayer.id ? $u");
				last;
			}
		}
	}
	lx("texture.new [$loadImage]");
	lx("texture.parent [$mask] [-1]");

	#find the image size.
	my $clips = lxq("query layerservice clip.n ?");
	my $currentClip = $clips - 1;
	my $clipInfo = lxq("query layerservice clip.info ? $currentClip");
	my $clipID = lxq("query layerservice clip.id ? $currentClip");
	my @clipSize = split(/\D+/, $clipInfo);
	my $width = @clipSize[1];
	my $height = @clipSize[2];


	#----------------------------------------------------------------------------------------------------------
	#NOW CREATE THE BACK POLY AND APPLY THE UVS.
	#----------------------------------------------------------------------------------------------------------
	my $cenX = $width * 0.5;
	my $cenY = $height * -0.5;
	lx("tool.set prim.cube on");
	lx("tool.reset");
	lx("tool.setAttr prim.cube cenX {$cenX}");
	lx("tool.setAttr prim.cube sizeX {$width}");
	lx("tool.setAttr prim.cube cenY {$cenY}");
	lx("tool.setAttr prim.cube sizeY {$height}");
	lx("tool.setAttr prim.cube cenZ {-2}");
	lx("tool.setAttr prim.cube sizeZ {0}");
	lx("tool.setAttr prim.cube axis {1}");
	lx("tool.doApply");
	lx("tool.set prim.cube off");

	#apply the part to this polygon
	my $part = "(--CARD--)".",".$cardUsername.",".$cardDescription.",".$cardIndex.",".$cardColor;
	my $polys = lxq("query layerservice poly.n ? all");
	my $poly = $polys-1;
	lx("select.drop polygon");
	lx("select.element $mainlayer polygon set {$poly}");
	lx("poly.setPart [$part]");

	lx("select.drop polygon");
	lx("select.invert");
	lx("poly.setMaterial [$cardName] [1.0 1.0 1.0] [80.0 %] [20.0 %] [1] [1]");

	my $cenX = $width * 0.5;
	my $cenY = $height * -0.5;
	lx("tool.set uv.create on");
	lx("tool.reset");
	lx("tool.attr uv.create proj planar");
	lx("tool.attr uv.create mode manual");
	lx("tool.setAttr uv.create cenX {$cenX}");
	lx("tool.setAttr uv.create cenY {$cenY}");
	lx("tool.setAttr uv.create cenZ {1}");
	lx("tool.setAttr uv.create sizX {$width}");
	lx("tool.setAttr uv.create sizY {$height}");
	lx("tool.setAttr uv.create sizZ {2}");
	lx("tool.setAttr uv.create seam {0}");
	lx("tool.setAttr uv.create axis {2}");
	lx("tool.doApply");
	lx("tool.set uv.create off");
}









#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#RESET THE USER.VALUES SUBROUTINE
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub resetValues{
	lx("user.value sene_cardSet [SplashCards]");
	lx("user.value sene_cardUserName [modo 201]");
	lx("user.value sene_cardDescription [These are the cards used for the eval splash system]");
	lx("user.value sene_cardScheme [DefaultCardSet]");
	lx("user.value sene_cardColorDefault [set.bg]");
	lx("user.value sene_cardTransition [dissolve 500]");
	lx("user.value sene_cardSetScheme [DefaultCardSet,set.bg=1.0 1.0 1.0,set.text=0.1 0.1 0.3,set.lighttext=0.8 0.8 1.0,set.darktext=0.0 0.0 0.1,set.card2bg=1.0 1.0 1.0,set.card3bg=1.0 1.0 1.0,set.card4bg=.28 .28 .28,set.card5bg=.00 .00 .00]");
}








#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#FIND THE IMAGES PER LAYER AND BUILD A TABLE (note: works off of clip "names", not their files, so it's not 100% accurate)
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub listAllMaterialImageSizes{
	our %materialList=();
	my %clipList;

	#go thru all the clips and find their image sizes
	my $clips = lxq("query layerservice clip.n ?");
	for (my $i=0; $i<$clips; $i++){
		my $name = lxq("query layerservice clip.name ? $i");
		my $info = lxq("query layerservice clip.info ? $i");
		my @clipSize = split(/\D+/, $info);
		my $width = @clipSize[1];
		my $height = @clipSize[2];
		my $file = lxq("query layerservice clip.file ? $i");
		@{$clipList{$name}} = ($width,$height,$file);
	}

	#go thru all txLayers and find the largest assigned image per material.
	my $txLayers = lxq("query sceneservice txLayer.n ?");
	for (my $i=0; $i<$txLayers; $i++){
		if (lxq("query sceneservice txLayer.type ? $i") eq "mask"){
			my $ptag = lxq("query sceneservice channel.value ? ptag");
			my @children = lxq("query sceneservice txLayer.children ? $i");
			foreach my $child (@children){
				if (lxq("query sceneservice txLayer.type ? $child") eq "imageMap"){
					my $name = lxq("query sceneservice txLayer.name ? $child");
					if ($modoVer > 401){
						$name = imageName_format($name);
					}else{
						my @split = split(/: /, $name);
						$name = @split[-1];
					}

					if (exists $materialList{$ptag}){
						if ( (@{$clipList{$name}}[0] > @{$materialList{$ptag}}[0]) || (@{$clipList{$name}}[1] > @{$materialList{$ptag}}[1]) ){
							lxout("This material ($ptag) has more than 1 image, but this one's bigger : $name");
							@{$materialList{$ptag}} = @{$clipList{$name}};
						}
					}else{
						lxout("This material ($ptag) has only one image, so I'm assigning it : $name");
						@{$materialList{$ptag}} = @{$clipList{$name}};
					}
				}
			}
		}
	}
}


#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#IMAGE NAME FORMAT
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub imageName_format{
	$_[0] =~ s/\(image\)//i;
	$_[0] =~ s/\([0-9]+\)//g;
	$_[0] =~ s/\s+$//;
	return $_[0];
}







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
#THIS WILL ROUND THE CURRENT NUMBER to the amount you define. (VER 2.1)
#------------------------------------------------------------------------------------------------------------
#------------------------------------------------------------------------------------------------------------
#USAGE : my $rounded = roundNumber(-1.45,1);
sub roundNumber(){
	my $flip = 0;
	my $number = $_[0];
	my $roundTo = $_[1];
	if ($roundTo < 0)	{	$roundTo *= -1;				}
	if ($number < 0)	{	$number *= -1;	$flip = 1;	}

	#my $result = int(($number * $gridMult /$roundTo)+.5) * $roundTo * $gridDiv;
	my $result = int(($number /$roundTo)+.5) * $roundTo;
	if ($flip == 1)	{	return -$result;	}
	else			{	return $result;		}
}











#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#SELECT THE PROPER VMAP  v2.01 (unreal)
#------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub selectVmap{
	my $defaultVmapName = lxq("pref.value application.defaultTexture ?");
	my $vmaps = lxq("query layerservice vmap.n ? all");
	my %uvMaps;
	my @selectedUVmaps;
	my $finalVmap;

	lxout("-Checking which uv maps to select or deselect");

	for (my $i=0; $i<$vmaps; $i++){
		if (lxq("query layerservice vmap.type ? $i") eq "texture"){
			if (lxq("query layerservice vmap.selected ? $i") == 1){push(@selectedUVmaps,$i);}
			my $name = lxq("query layerservice vmap.name ? $i");
			$uvMaps{$i} = $name;
		}
	}
	lxout("selectedUVmaps = @selectedUVmaps");

	#ONE SELECTED UV MAP
	if (@selectedUVmaps == 1){
		lxout("     -There's only one uv map selected <> $uvMaps{@selectedUVmaps[0]}");
		$finalVmap = @selectedUVmaps[0];
	}

	#MULTIPLE SELECTED UV MAPS  (try to select "$defaultVmapName")
	elsif (@selectedUVmaps > 1){
		my $foundVmap;
		foreach my $vmap (@selectedUVmaps){
			if ($uvMaps{$vmap} eq $defaultVmapName){
				$foundVmap = $vmap;
				last;
			}
		}
		if ($foundVmap != "")	{
			lx("!!select.vertexMap $uvMaps{$foundVmap} txuv replace");
			lxout("     -There's more than one uv map selected, so I'm deselecting all but this one <><> $uvMaps{$foundVmap}");
			$finalVmap = $foundVmap;
		}
		else{
			lx("!!select.vertexMap $uvMaps{@selectedUVmaps[0]} txuv replace");
			lxout("     -There's more than one uv map selected, so I'm deselecting all but this one <><> $uvMaps{@selectedUVmaps[0]}");
			$finalVmap = @selectedUVmaps[0];
		}
	}

	#NO SELECTED UV MAPS (try to select "$defaultVmapName" or create it)
	elsif (@selectedUVmaps == 0){
		lx("!!select.vertexMap {$defaultVmapName} txuv replace") or $fail = 1;
		if ($fail == 1){
			lx("!!vertMap.new {$defaultVmapName} txuv {0} {0.78 0.78 0.78} {1.0}");
			lxout("     -There were no uv maps selected and '$defaultVmapName' didn't exist so I created this one. <><> $defaultVmapName");
		}else{
			lxout("     -There were no uv maps selected, but '$defaultVmapName' existed and so I selected this one. <><> $defaultVmapName");
		}

		my $vmaps = lxq("query layerservice vmap.n ? all");
		for (my $i=0; $i<$vmaps; $i++){
			if (lxq("query layerservice vmap.name ? $i") eq $defaultVmapName){
				$finalVmap = $i;
			}
		}
	}

	#ask the name of the vmap just so modo knows which to query.
	my $name = lxq("query layerservice vmap.name ? $finalVmap");
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
			elsif (@_[10] == ""){lxout("woah.  there's no value in the userVal sub!");								}
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





#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#POPUP SUB
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
sub popup #(MODO2 FIX)
{
	lx("dialog.setup yesNo");
	lx("dialog.msg {@_}");
	lx("dialog.open");
	my $confirm = lxq("dialog.result ?");
	if($confirm eq "no"){die;}
}
