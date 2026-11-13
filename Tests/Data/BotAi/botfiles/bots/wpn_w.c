weight "Blade" return 100;
weight "Cannon"
{
	switch(2)
	{
		case 5: return 0;
		case 20: return 250;
		default: return 500;
	}
}
weight "Launcher"
{
	switch(3)
	{
		case 1: return 0;
		default: return balance(300, 200, 400);
	}
}
weight "Unused" return 5;