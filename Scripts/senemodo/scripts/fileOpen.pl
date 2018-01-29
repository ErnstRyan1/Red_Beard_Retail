#perl
#ver 1.0
#author : Seneca Menard
#This script is to replace modo's file open command.  The only diff is that it only allows you to see LWOs,LXOs, and OBJs, whereas modo's was filling the browser with PSDs and whatnot.

lx("dialog.setup fileOpenMulti");
lx("dialog.title [Scenes to open:]");
lx("dialog.fileTypeCustom format:[sml] username:[Model to load] loadPattern:[*.lxo;*.lwo;*.obj;*.fbx] saveExtension:[lxo]");
lx("dialog.open");
my @files = lxq("dialog.result ?");
if (lxres != 0){	die("The user hit the cancel button");	}
foreach my $file (@files){lx("scene.open {$file}");}
