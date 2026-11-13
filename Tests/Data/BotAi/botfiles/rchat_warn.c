// reply chats that make the checker warn
[ & "key" ] = 1
{
	"only and";
}
[ ( 1, "x" ), "foo" ] = 2
{
	"mixed";
}
[ "abc", ! "b" ] = 3
{
	"inside";
}
[ ( "text here", 1 ), & "zzz" ] = 4
{
	"nospace";
}
[ ( "text ", 1 ), ! "ex" ] = 4
{
	"inside the template";
}
