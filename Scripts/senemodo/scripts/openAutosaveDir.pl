#perl
#AUTHOR: Seneca Menard
#version 1.1
#This script is to open the autosave dir

my $dir = lxq("pref.value autosave.directory ?");
system "explorer $dir";