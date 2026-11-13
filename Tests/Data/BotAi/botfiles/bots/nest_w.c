weight "N1"
{
	switch(1)
	{
		case 5:
		{
			switch(2)
			{
				case 3: return 10;
				default: return balance(20, 10, 30);
			}
		}
		case 9:
		{
			switch(2)
			{
				case 3: return 30;
				default: return balance(40, 30, 50);
			}
		}
		default: return 50;
	}
}