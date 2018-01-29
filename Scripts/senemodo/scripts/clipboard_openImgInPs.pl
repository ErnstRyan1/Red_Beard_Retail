#perl
#author : Seneca Menard
#This script is to look at your windows clipboard and it assumes there's a copied shader image path in there, and it will then open that image in photoshop

BEGIN{
	@INC = "C:\/strawberry\/perl\/lib";
	#@INC = "C:\/strawberry\/perl\/lib\/Win32";
}
use Win32::Clipboard;
$clipboard = Win32::Clipboard();
$clipboard = "w:\/Rage\/base\/" . $clipboard;
$clipboard =~ s/\s+//g;
$clipboard =~ s/\t+//g;
$clipboard =~ s/\..*//g;
$clipboard .= ".tga";
#system qw(C:\Program Files (x86)\Adobe\Adobe Photoshop CS4\Photoshop.exe $clipboard);

system qw(C:\Program Files\Adobe\Adobe Photoshop CS5 (64 Bit)\Photoshop.exe $clipboard);
