#perl
#This script will mark your current modo scene for add in P4

#SCRIPT ARGUMENTS :
#all : this will add ALL the files that are currently open in modo.


if (@ARGV[0] =~ /all/i){
	my $sceneCount = lxq("query sceneservice scene.n ? all");
	for (my $i=0; $i<$sceneCount; $i++){
		my $filePath = lxq("query sceneservice scene.file ? $i");
		if ($filePath ne ""){system("p4 add \"$filePath\"") or lxout("failed to add this file : $filePath");}
		else{lxout("This file isn't saved yet and so I couldn't add it to P4");}
	}
}else{
	my $filePath = lxq("query sceneservice scene.file ? current");
	if ($filePath ne ""){system("p4 add \"$filePath\"") or lxout("failed to add this file : $filePath");}
	else{lxout("This file isn't saved yet and so I couldn't add it to P4");}
}


