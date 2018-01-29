#perl
#ver 1.0
#author : Seneca Menard
#This script will do a compare between your current scene's render properties and modo's default render properties and print the difference.  It's handy if you know you screwed something up, but don't know what..  :)


my %renderProps = qw(
	aa			s8
	aaFilter	gaussian
	ambColor.B	1
	ambColor.G	1
	ambColor.R	1
	ambRad		0.05
	animNoise	0
	bktOrder	hilbert
	bktRefine	0
	bktReverse	0
	bktSkip		0
	bktWrite	0
	bucketX		40
	bucketY		40
	causEnable	0
	causLocal	32
	causMulti	1
	causTotal	100000
	dispEnable	1
	dispRate	1
	dispRatio	4
	dispSmooth	1
	dof			0
	dpi			300
	edgeMin		0.001
	fineRate	0.25
	fineThresh	0.1
	first		1
	globCaus	refraction
	globEnable	0
	globLimit	1
	globRange	0
	globRays	64
	globScope	all
	globSubs	0
	globSuper	1
	irrCache	1
	irrCache2	1
	irrGrads	both
	irrLEnable	0
	irrRate		2.5
	irrRatio	6
	irrRays		256
	irrSEnable	0
	irrVals		1
	irrWalk		0
	last		120
	mBlur		0
	pAspect		1
	rayShadow	1
	rayThresh	0.005
	reflDepth	8
	refrDepth	8
	region		0
	regX0		0
	regX1		1
	regY0		0
	regY1		1
	rendType	auto
	resUnit		pixels
	resX		640
	resY		480
	step		1
	stereo		0
	subdAdapt	1
	subdRate	10
);
#stack irrLName	irrSName

my %skippedRenderProps = qw(
	bucketX		40
	bucketY		40
	causLocal	32
	causTotal	100000
	globLimit	1
	globRays	64
	irrRays		256
	irrVals		1
	reflDepth	8
	refrDepth	8
	resX		640
	resY		480
);

my %ignoreList = qw(
	ambColor.B	1
	ambColor.G	1
	ambColor.R	1
	bucketX		40
	bucketY		40
	globEnable	0
	regX0		0
	regX1		1
	regY0		0
	regY1		1
	resX		640
	resY		480
);




lx("select.itemType type:polyRender mode:set");
my @renderID = lxq("query sceneservice selection ? polyRender");
my $renderName = lxq("query sceneservice item.name ? @renderID[0]");
my $channelCount = lxq("query sceneservice channel.n ?");
my $counter = 0;
for (my $i=0; $i<$channelCount; $i++){
	my $label = lxq("query sceneservice channel.label ? $i");
	my $name = lxq("query sceneservice channel.name ? $i");
	if ($skippedRenderProps{$name} ne "")	{our $value = lxq("item.channel polyRender\$$name ?");}
	else									{our $value = lxq("query sceneservice channel.value ? $i");	}

	if (($renderProps{$name} ne $value) && ($ignoreList{$name} eq "")){
		$counter++;
		lxout("$label=$value        default=$renderProps{$name}");
	}
}

if ($counter == 0){lxout("All the render settings are set to their default");}


#load a popup window
if (@ARGV[0] ne "noPopup"){
	lx("!!layout.create width:600 height:800");
	lx("!!viewport.restore [] 0 logview");
}
