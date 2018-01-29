#perl
#ver 0.1
#author : Seneca Menard

#this is a super hack hardcoded script that shouldn't be used yet, but it's for renaming files...


#file dialog window
lx("dialog.setup fileOpenMulti");
#if ($modoVer > 300){lx("dialog.fileTypeCustom format:[sml] username:[Model to load] loadPattern:[*.lxo;*.lwo;*.obj] saveExtension:[lxo]");}
#else{				lx("dialog.fileType scene");}
lx("dialog.fileType {}");
lx("dialog.title [Select some files to replace the names on...]");
lx("dialog.open");
my @files = lxq("dialog.result ?");
if (@files < 1){die("You didn't pick any files so I'm canceling the script");}

my $oldName = quickDialog("type in the OLD text\nyou want to replace:",string,"","","");
my $newName = quickDialog("type in the NEW text\nyou want to use:",string,"","","");
my $counter=0;

foreach my $file (@files){
	my @words = split(/\\/,$file);
	my $filePath;
	for (my $i=0; $i<$#words; $i++){$filePath .= @words[$i]."\\";}

	my $nameSwap = @words[-1];
	$nameSwap =~ s/$oldName/$newName/g;
	$filePath .= $nameSwap;

	if ($counter == 0){popup("example rename : \n@words[-1]\n$nameSwap");}
	rename($file,$filePath) || die("The rename failed : \n$file\n$filePath");
	$counter++;
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