#perl
#ver 1.0
#author : Seneca Menard

#This script will create a RAGE shader for your current modo LXO scene and copy it into the windows text copy buffer so you can paste it into a shader.  Your modo LXO must be in a "work" directory, and also must have "_base.lxo" or "_work.lxo" in the filename.

#REQUIREMENTS : This script must have access to the perl library.  You must have perl

BEGIN{
	my $perlDir = "C:\/Perl64\/lib";
	#my $perlDir = "C:\/Perl\/lib";
	#my $perlDir2 = "H:\/Home\/Seneca Menard\/artistTools_Modo\/Perl\/lib";
	@INC = $perlDir;
	#push(@INC,$perlDir2);
}
use Win32::Clipboard;
$CLIP = Win32::Clipboard();


#my $sceneFile = lxq("query sceneservice scene.file ? current");
#if		($sceneFile =~ /_base\./i)	{$sceneFile =~ s/_base\.[a-z]+//i;	}
#elsif	($sceneFile =~ /_work\./i)	{$sceneFile =~ s/_work\.[a-z]+//i;	}
#else								{die("This scene's filename doesn't have '_base.lxo' or '_work.lxo' in it, so I'm cancelling the script.");}
#$sceneFile =~ s/\\/\//g;
#$sceneFile =~ s/W:\/Rage\/base\///i;
#$sceneFile =~ s/\/work\//\//i;
#my $dir;
#my @dirNames = split(/\//,$sceneFile);
#for (my $i=0; $i<$#dirNames; $i++){$dir .= @dirNames[$i]."\/";}
#
#my $string = $sceneFile."\n{\n\trenderbump\t\t\t\t\"-size 1024 1024 -aa 2 -trace \.1 ".$sceneFile."_local.tga ".$dir."work\/".@dirNames[-1]."_hp.lwo\"\n\tpowerMip\t\t\t\t2\n\n\tbumpmap\t\t\t\t\t".$sceneFile."_local\n\tdiffusemap\t\t\t\t".$sceneFile."\n\tspecularmap\t\t\t\t".$sceneFile."_s\n}\n";
#$CLIP->Set($string);


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

