#perl
#ver 1.0
#author : Seneca Menard

#This script is to read a text file and copy it's contents to the windows copy buffer. I wrote it because the perl that comes with modo doesn't support the clipboard module and you can't reference it manually because it's not compliant with modo's perl.  So you have to run this as a system command externally.

#usage : perl copyFileTextToWinCopyBuffer.pl "C:\Users\smenard\AppData\Roaming\Luxology\Scripts\unreal_clipboard.txt"


BEGIN{	@INC = ( "C:\/strawberry\/perl\/lib" , "C:\/Strawberry\/perl\/site\/lib" );	}
use Win32::Clipboard;
my $fileContents;

#my $response = <STDIN>;

open (FILE, "<@ARGV[0]") or popup("This file doesn't exist : @ARGV[0]");
while (<FILE>){$fileContents .= $_;}
close (FILE);




Win32::Clipboard::Set($fileContents);
