#perl
#FIXED FOR MODO2
#this script is to toggle between the two lasso styles I use.


if (lxq("select.lassoStyle ?") eq "lasso")
{
	lx("select.lassoStyle rectangle");
}
else
{
	lx("select.lassoStyle lasso");
}


