// fuzzy weights written for the tests
weight "WP_A"
{
	switch(1)
	{
		case 1: return 0;
		case 5:
		{
			switch(2)
			{
				case 3: return 100;
				default: return balance(200, 100, 300);
			}
		}
		default: return balance(50, 10, 90);
	}
}
weight "WP_B" return 300;
weight "WP_C" { return balance(1, 0.5, 2); }
weight "WP_D"
{
	switch(0)
	{
		case 10: return 1;
		case 20: return 2;
		case 30: return 3;
	}
}
weight "WP_E"
{
	switch(3)
	{
		case 2: return 8;
		case 4: { return balance(2, 1, 5); }
		case 6: return 9;
		default: return 7;
	}
}