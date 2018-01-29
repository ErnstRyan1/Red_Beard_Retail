#perl
#this script is just to open up a bunch of LWOs and save 'em out as OBJs on the desktop.

lx("dialog.setup fileOpenMulti");
lx("dialog.title {FILES to IMPORT}");
lx("dialog.open");
my @files = lxq("dialog.result ?");


foreach my $file (@files){
	my @names = split(/\\/,$file);
	my $name = @names[-1];
	$name =~ s/.lwo/.obj/;
	$name = "C:\/Documents and Settings\/seneca\.EDEN\.000\/Desktop\/".$name;
	#popup("name = @names[-1]\n$name");

	lx("!!scene.open [$file]");
	lx("!!poly.setPart Default");
	lx("!!poly.setMaterial Default [1.0 1.0 1.0] [80.0 %] [20.0 %] [1] [0]");
	lx("!!scene.saveAs [$name] OBJ [False]");
	lx("!!scene.close");

}


