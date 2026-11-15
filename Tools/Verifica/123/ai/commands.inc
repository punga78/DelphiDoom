/* The commands of the scenario (included at the end of aigen.c). */

static void run_command(void)
{
	const char *c = arg(0);
	if (!strcmp(c, "libvar"))
	{
		LibVarSet(arg(1), arg(2));
	}
	else if (!strcmp(c, "developer"))
	{
		bot_developer = (int) num(1);
	}
	else if (!strcmp(c, "time"))
	{
		aasworld.time = fnum(1);
	}
	else if (!strcmp(c, "srand"))
	{
		srand((unsigned) num(1));
	}
	else if (!strcmp(c, "gen"))
	{
		/* gen|rank|rank|...: GeneticParentsAndChildSelection */
		float ranks[300];
		int n = numargs - 1, i, p1 = -9, p2 = -9, ch = -9, r;
		for (i = 0; i < n && i < 300; i++) ranks[i] = fnum(i + 1);
		r = GeneticParentsAndChildSelection(n, ranks, &p1, &p2, &ch);
		fprintf(fo, "GEN %d %d %d %d\n", r, p1, p2, ch);
	}
	else if (!strcmp(c, "gensel"))
	{
		/* gensel|rank|...: GeneticSelection */
		float ranks[300];
		int n = numargs - 1, i;
		for (i = 0; i < n && i < 300; i++) ranks[i] = fnum(i + 1);
		fprintf(fo, "SEL %d\n", GeneticSelection(n, ranks));
	}
	else
	{
		fprintf(fo, "unknown command %s\n", c);
	}
}
