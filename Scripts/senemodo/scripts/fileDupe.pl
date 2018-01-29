#perl
#ver 1.0
#author : Seneca Menard
#This script will save the current scene and duplicate the file with a number appended for backup purposes.
#note : requires senFileTools.exe, so here's an example of how you use the script : @fileDupe.pl "C:/senFileTools.exe"

my $exe = "C:\/senFiles\/seneMisc\/senFileTools.exe";
foreach my $arg (@ARGV){
	if ($arg =~ /skipSave/i)	{	our $skipSave = 1;	}
	else						{	$exe = $arg;		}
}

if ($skipSave != 1){lx("scene.save");}

my $sceneFile = lxq("query sceneservice scene.file ? current");
if ($sceneFile ne ""){
	my $command = $exe . " dupeFile " . $sceneFile;
	$command =~ s/\\/\//g;
	lxout("command = $command");
	system $command;
}else{
	popup("Couldn't dupe the file because this scene hasn't been saved yet.");
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
