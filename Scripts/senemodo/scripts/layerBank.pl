#perl
#ver 1.0
#author : Seneca Menard

#This script requires the "sen_layerBank" form in order to use it.  It's for saving/recalling which layers are selected / active.

my $textFilePath = "C:\/modo_senLayerBank.cfg";
my $integer = 0;

foreach my $arg (@ARGV){
	if		($arg eq "store")	{	our $store = 1;		}
	elsif	($arg eq "recall")	{	our $recall = 1;	}
	elsif	($arg =~ /[0-9]/)	{	$integer = $arg;	}
}
lxout("integer = $integer");

my %itemTypes;
	$itemTypes{"mesh"} = 1;
	$itemTypes{"meshInst"} = 1;
	$itemTypes{"triSurf"} = 1;
	$itemTypes{"groupLocator"} = 1;

#main
if		($store == 1)	{	store();	}
elsif	($recall == 1)	{	recall();	}


##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##store
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
sub store{
	my $itemCount = lxq("query sceneservice item.n ? all");
	my @items_selected;
	my @items_visible;
	my %textFileContents;

	#build list of visible and selected items
	for (my $i=0; $i<$itemCount; $i++){
		my $type = lxq("query sceneservice item.type ? $i");
		if ($itemTypes{$type} == 1){
			my $id = lxq("query sceneservice item.id ? $i");
			my $visible = lxq("query sceneservice channel.value ? visible");
			my $selected = lxq("query sceneservice item.isSelected ? $i");
			if ($visible eq "default")	{	push(@items_visible,$id);	}
			if ($selected == 1)			{	push(@items_selected,$id);	}
		}
	}

	#force first mesh selection to front of line so mainlayer still works
	my @meshSelection = lxq("query layerservice selection ? mesh");
	if ($meshSelection > 0){
		for (my $i=0; $i<@items_selected; $i++){
			if ($items_selected[$i] eq $meshSelection[0]){
				splice(@items_selected, $i,1);
				unshift(@mylist,$meshSelection[0]);
			}
		}
	}

	#load config file and store data
	readConfig(\%textFileContents);

	#save to config
	open (FILE, ">$textFilePath") or popup("This file doesn't exist : $textFilePath");
	for (my $i=0; $i<8; $i++){
		if ($i == $integer){
			lxout("$integer <> $i ---------");
			my $line = "";
			#if ($mainlayer ne "")				{	my $mainlayerID = lxq("query layerservice layer.id ? main");	$line .= $mainlayerID . ",";	}
			foreach my $id (@items_selected)	{	$line .= $id .",";	}
			chop $line;
			$line .= ";";
			foreach my $id (@items_visible)		{	$line .= $id .",";	}
			chop $line;
			print FILE $line . "\n";
		}

		else{
			my $line = "";
			foreach my $id (@{$textFileContents{$i}{selected}})	{	$line .= $id .",";	}
			chop $line;
			$line .= ";";
			foreach my $id (@{$textFileContents{$i}{visible}})	{	$line .= $id .",";	}
			chop $line;
			$line =~ s/\n//g;
			lxout("line = $line....");
			print FILE $line . "\n";
		}
	}
	close (FILE);

	#foreach my $key (sort { $a <=> $b } keys %textFileContents){
		#foreach my $key2 (keys %{$textFileContents{$key}}){
			#lxout("blah = @{$textFileContents{$key}{$key2}}");
		#}
	#}
}

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##recall
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
sub recall{
	my %textFileContents;
	readConfig(\%textFileContents);

	if    ( lxq( "select.typeFrom {vertex;edge;polygon;item} ?" ) )	{ our $selectType = vertex;		}
	elsif ( lxq( "select.typeFrom {edge;polygon;item;vertex} ?" ) )	{ our $selectType = edge; 		}
	elsif ( lxq( "select.typeFrom {polygon;item;vertex;edge} ?" ) )	{ our $selectType = polygon;	}
	else															{ our $selectType = item;		}

	if ( (@{$textFileContents{$integer}{selected}} == 0) && (@{$textFileContents{$integer}{$visible}} == 0) ){
		die("This block ($integer) is unused currently, so I'm cancelling the script.");
	}

	if (@{$textFileContents{$integer}{selected}} == 0){
		lx("!!select.subItem {@{$textFileContents{$integer}{visible}}[0]} set mesh;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
		lx("select.type item");
		lx("hide.unsel");
	}else{
		lx("!!select.subItem {@{$textFileContents{$integer}{selected}}[0]} set mesh;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
		lx("select.type item");
		lx("hide.unsel");
	}

	for (my $i=1; $i<@{$textFileContents{$integer}{selected}}; $i++){
		lx("select.subItem {@{$textFileContents{$integer}{selected}}[$i]} add mesh;camera;light;backdrop;groupLocator;replicator;locator;deform;locdeform;chanModify;chanEffect 0 0");
	}
	for (my $i=0; $i<@{$textFileContents{$integer}{visible}}; $i++){
		lx("layer.setVisibility {@{$textFileContents{$integer}{visible}}[$i]} 1");
	}

	if ($selectType ne "item"){	lx("select.type {$selectType}");	}
}

##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
##readConfig
##------------------------------------------------------------------------------------------------------------
##------------------------------------------------------------------------------------------------------------
#usage : readConfig(\%textFileContents);
sub readConfig{
	open (FILE, "<$textFilePath") or popup("This file doesn't exist : $textFilePath");
	my $counter = 0;
	while (<FILE>){
		chomp $_;
		my @text = split(/;/, $_);
		my @selected = split(/,/, $text[0]);
		my @visible = split(/,/, $text[1]);
		lxout("$counter <> @selected <> @visible");
		@{$_[0]{$counter}{selected}} = @selected;
		@{$_[0]{$counter}{visible}} = @visible;
		$counter++;
	}

	close (FILE);
}
