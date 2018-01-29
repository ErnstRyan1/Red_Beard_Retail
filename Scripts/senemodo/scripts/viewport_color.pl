#perl
#this script will apply the input colorscheme.
my $color = @ARGV[0];
lx("viewport.scheme $color.3d");
lx("layer.swap");
lx("layer.swap");
