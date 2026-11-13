// chat files: chat "name" { type "type" { messages } }
chat "bot1"
{
	type "game_enter"
	{
		"hello everyone";
		"hi, I am ", 0, ", ready";
		greeting, " all";
	}
	type "death_insult"
	{
		insult;
		"too bad ", 0, ", ", excuse;
	}
	type "empty"
	{
	}
}
chat "bot2"
{
	type "game_enter"
	{
		"yo";
	}
	type "missing"
	{
		"this uses ", nonexistent, " random";
		"and ", greeting;
	}
}
