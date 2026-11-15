// item weights written for the tests of the goals
weight "item_armor_body"
{
	switch(1)
	{
		case 50: return 300;
		case 100: return 100;
		default: return 0;
	}
}
weight "item_health"
{
	switch(2)
	{
		case 100: return 400;
		default: return balance(60, 20, 90);
	}
}
weight "weapon_rocketlauncher"
{
	switch(3)
	{
		case 1: return 500;
		default: return 100;
	}
}
weight "item_quad" return 700;
weight "ammo_rockets"
{
	switch(5)
	{
		case 20: return 250;
		default: return 50;
	}
}
weight "item_botroam" return 40;
