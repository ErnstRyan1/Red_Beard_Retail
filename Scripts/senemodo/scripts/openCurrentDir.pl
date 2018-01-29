#perl
#AUTHOR: Seneca Menard
#version 1.1
#This script is to open the dir of the scene you're in.

#(1-21-09 bugfix) : it now selects the file for you in explorer.


my $file = lxq("query sceneservice scene.file ? selected");
system "explorer \/select,$file";