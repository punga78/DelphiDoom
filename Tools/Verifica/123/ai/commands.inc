/* The commands of the scenario (included at the end of aigen.c).
 *
 * general:   libvar|name|value  developer|0/1  time|seconds  srand|seed  loadaas|file  entdata|text
 *            model|n|mins(3)|maxs(3)|origin(3)  solid|entnum|mins(3)|maxs(3)  clearsolids
 *            entity|num|valid|type|modelindex|origin(3)|lastvisorigin(3)|weapon|ltime  entityclear
 * genetics:  gen|rank...  gensel|rank...
 * actions:   easetup|maxclients  eainput|client|thinktime  eareset|client
 * goals:     goalsetup  goalinit  goalupdate  golist  gsshutdown  gsalloc|client  gsfree|h  gsreset|h
 *            gsweights|h|file  gsfreeweights|h  gsltg|h|origin(3)|flags|inventory...
 *            gsnbg|h|origin(3)|flags|maxtime|useltg|inventory...  gspush|h|goal(7)  gspop|h  gsempty|h
 *            gstop|h  gssecond|h  gsdumpstack|h  gsdumpavoid|h  gsavoid|h|n  gssetavoid|h|n|time
 *            gsremoveavoid|h|n  gsresetavoid|h  gsname|n|size  gstouch|h|origin(3)  gsvis|h|viewer|eye(3)
 *            gslevelgoal|index|name  gscamp|num  gsloc|name  gsbreed|p1|p2|child  gsmutate|h
 * movement:  mvsetup  mvalloc  mvfree|h  mvreset|h  mvinit|h|origin(3)|velocity(3)|viewoffset(3)|entnum|client|
 *            thinktime|presence|viewangles(3)|orflags  mvavoidspot|h|origin(3)|radius|type  mvresetavoid|h
 *            mvresetlast|h  mvarea|origin(3)|client  mvfuzzy|origin(3)  mvgoal|h|client|travelflags|goal(7) (or null)
 *            mvdir|h|client|dir(3)|speed|type  mvview|h|travelflags|lookahead|goal(7)
 *            mvpredict|origin(3)|area|travelflags|goal(7)  mvsim|h|client|tics|thinktime|origin(3)|travelflags|goal(7)
 * a goal(7) is origin(3), area, entity number, number, flags.
 */

static void read_goal(int i, bot_goal_t *g)
{
	memset(g, 0, sizeof(*g));
	g->origin[0] = fnum(i); g->origin[1] = fnum(i + 1); g->origin[2] = fnum(i + 2);
	g->areanum = (int) num(i + 3);
	g->entitynum = (int) num(i + 4);
	g->number = (int) num(i + 5);
	g->flags = (int) num(i + 6);
	VectorSet(g->mins, -15, -15, -15);
	VectorSet(g->maxs, 15, 15, 15);
}

static int *read_inventory(int first)
{
	static int inv[1024];
	int i;
	memset(inv, 0, sizeof(inv));
	for (i = first; i < numargs && i - first < 1024; i++) inv[i - first] = (int) strtol(args[i], NULL, 0);
	return inv;
}

static void print_top(int h)
{
	bot_goal_t g;
	int r;
	memset(&g, 0, sizeof(g));
	r = BotGetTopGoal(h, &g);
	fprintf(fo, "TOP %d\n", r);
	if (r) print_goal(" G", &g);
}

static void run_sim(int h, int client, int tics, float thinktime, vec3_t origin, int travelflags, bot_goal_t *goal)
{
	vec3_t velocity = {0, 0, 0}, target, delta;
	int t;
	for (t = 0; t < tics; t++)
	{
		bot_initmove_t init;
		bot_moveresult_t result;
		bot_input_t input;
		aas_trace_t trace;
		float step, inv;
		memset(&init, 0, sizeof(init));
		VectorCopy(origin, init.origin);
		VectorCopy(velocity, init.velocity);
		VectorSet(init.viewoffset, 0, 0, 24);
		init.entitynum = 1;
		init.client = client;
		init.thinktime = thinktime;
		init.presencetype = PRESENCE_NORMAL;
		BotInitMoveState(h, &init);
		memset(&result, 0, sizeof(result));
		BotMoveToGoal(&result, h, goal, travelflags);
		EA_GetInput(client, thinktime, &input);
		fprintf(fo, "TIC %d", t);
		pv("O", origin);
		fprintf(fo, "\n");
		print_result(" R", &result);
		print_input(" I", &input);
		/* the world of the simulation: the bot goes where it was told, as far as the AAS lets it */
		step = input.speed * thinktime;
		delta[0] = input.dir[0] * step; delta[1] = input.dir[1] * step; delta[2] = input.dir[2] * step;
		VectorAdd(origin, delta, target);
		trace = AAS_TraceClientBBox(origin, target, PRESENCE_NORMAL, -1);
		inv = 1 / thinktime;
		velocity[0] = (trace.endpos[0] - origin[0]) * inv;
		velocity[1] = (trace.endpos[1] - origin[1]) * inv;
		velocity[2] = (trace.endpos[2] - origin[2]) * inv;
		VectorCopy(trace.endpos, origin);
		EA_ResetInput(client);
	}
}

static void run_command(void)
{
	const char *c = arg(0);
	int h = (int) num(1);
	if (!strcmp(c, "libvar")) LibVarSet(arg(1), arg(2));
	else if (!strcmp(c, "developer")) bot_developer = (int) num(1);
	else if (!strcmp(c, "time")) aasworld.time = fnum(1);
	else if (!strcmp(c, "srand")) srand((unsigned) num(1));
	else if (!strcmp(c, "loadaas")) load_aas(arg(1));
	else if (!strcmp(c, "entdata"))
	{
		static char text[8192];
		strncpy(text, arg(1), sizeof(text) - 1);
		entitydata = text;
		AAS_LoadBSPFile();
	}
	else if (!strcmp(c, "model"))
	{
		int n = (int) num(1);
		if (n < 0 || n >= MAXMODELS) { fprintf(fo, "bad model %d\n", n); exit(3); }
		vnum(2, models[n].mins); vnum(5, models[n].maxs); vnum(8, models[n].origin);
	}
	else if (!strcmp(c, "solid"))
	{
		if (numsolids >= MAXSOLIDS) { fprintf(fo, "too many solids\n"); exit(3); }
		solids[numsolids].ent = (int) num(1);
		vnum(2, solids[numsolids].mins); vnum(5, solids[numsolids].maxs);
		numsolids++;
	}
	else if (!strcmp(c, "clearsolids")) numsolids = 0;
	else if (!strcmp(c, "entity"))
	{
		aas_entityinfo_t *e;
		if (num(1) < 0 || num(1) >= MAXENTS) { fprintf(fo, "bad entity %d\n", (int) num(1)); exit(3); }
		e = &ents[(int) num(1)];
		memset(e, 0, sizeof(*e));
		e->valid = (int) num(2); e->type = (int) num(3); e->modelindex = (int) num(4);
		vnum(5, e->origin); vnum(8, e->lastvisorigin);
		e->weapon = (int) num(11); e->ltime = fnum(12);
		e->number = (int) num(1);
	}
	else if (!strcmp(c, "entityclear")) memset(ents, 0, sizeof(ents));
	else if (!strcmp(c, "gen"))
	{
		float ranks[300];
		int n = numargs - 1, i, p1 = -9, p2 = -9, ch = -9, r;
		for (i = 0; i < n && i < 300; i++) ranks[i] = fnum(i + 1);
		r = GeneticParentsAndChildSelection(n, ranks, &p1, &p2, &ch);
		fprintf(fo, "GEN %d %d %d %d\n", r, p1, p2, ch);
	}
	else if (!strcmp(c, "gensel"))
	{
		float ranks[300];
		int n = numargs - 1, i;
		for (i = 0; i < n && i < 300; i++) ranks[i] = fnum(i + 1);
		fprintf(fo, "SEL %d\n", GeneticSelection(n, ranks));
	}
	else if (!strcmp(c, "world"))
	{
		vec3_t o;
		vnum(1, o);
		fprintf(fo, "WO %d %d %d %d %d\n", AAS_OnGround(o, PRESENCE_NORMAL, -1), AAS_Swimming(o), AAS_AgainstLadder(o), AAS_PointAreaNum(o), BotFuzzyPointReachabilityArea(o));
	}
	else if (!strcmp(c, "ttable"))
	{
		int i, j, n = aasworld.numareas;
		for (i = 1; i < n; i++)
		{
			fprintf(fo, "TT %d", i);
			for (j = 1; j < n; j++) fprintf(fo, " %d", AAS_AreaTravelTimeToGoalArea(i, aasworld.areas[i].center, j, (int) num(1)));
			fprintf(fo, "\n");
		}
	}
	else if (!strcmp(c, "easetup")) { botlibglobals.maxclients = (int) num(1); fprintf(fo, "RC %d\n", EA_Setup()); }
	else if (!strcmp(c, "eainput"))
	{
		bot_input_t in;
		EA_GetInput((int) num(1), fnum(2), &in);
		print_input("IN", &in);
	}
	else if (!strcmp(c, "eareset")) EA_ResetInput((int) num(1));
	else if (!strcmp(c, "goalsetup")) fprintf(fo, "RC %d\n", BotSetupGoalAI());
	else if (!strcmp(c, "goalinit")) BotInitLevelItems();
	else if (!strcmp(c, "goalupdate")) BotUpdateEntityItems();
	else if (!strcmp(c, "golist"))
	{
		levelitem_t *li;
		for (li = levelitems; li; li = li->next)
		{
			fprintf(fo, "LI %d %d %d", li->number, li->iteminfo, li->flags);
			pf("W", li->weight); pv("O", li->origin);
			fprintf(fo, " GA %d", li->goalareanum);
			pv("GO", li->goalorigin);
			fprintf(fo, " E %d", li->entitynum);
			pf("T", li->timeout);
			fprintf(fo, "\n");
		}
		fprintf(fo, "LIN %d\n", numlevelitems);
	}
	else if (!strcmp(c, "gsshutdown")) BotShutdownGoalAI();
	else if (!strcmp(c, "gsalloc")) fprintf(fo, "H %d\n", BotAllocGoalState((int) num(1)));
	else if (!strcmp(c, "gsfree")) BotFreeGoalState(h);
	else if (!strcmp(c, "gsreset")) BotResetGoalState(h);
	else if (!strcmp(c, "gsweights")) fprintf(fo, "RC %d\n", BotLoadItemWeights(h, arg(2)));
	else if (!strcmp(c, "gsfreeweights")) BotFreeItemWeights(h);
	else if (!strcmp(c, "gsltg"))
	{
		vec3_t o;
		int r;
		vnum(2, o);
		r = BotChooseLTGItem(h, o, read_inventory(6), (int) num(5));
		fprintf(fo, "LTG %d\n", r);
		print_top(h);
	}
	else if (!strcmp(c, "gsnbg"))
	{
		vec3_t o;
		bot_goal_t ltg;
		int r, useltg = (int) num(7);
		float maxtime = fnum(6);
		vnum(2, o);
		memset(&ltg, 0, sizeof(ltg));
		if (useltg) BotGetTopGoal(h, &ltg);
		r = BotChooseNBGItem(h, o, read_inventory(8), (int) num(5), useltg ? &ltg : NULL, maxtime);
		fprintf(fo, "NBG %d\n", r);
		print_top(h);
	}
	else if (!strcmp(c, "gspush"))
	{
		bot_goal_t g;
		read_goal(2, &g);
		g.iteminfo = (int) num(9);
		BotPushGoal(h, &g);
	}
	else if (!strcmp(c, "gspop")) BotPopGoal(h);
	else if (!strcmp(c, "gsempty")) BotEmptyGoalStack(h);
	else if (!strcmp(c, "gstop")) print_top(h);
	else if (!strcmp(c, "gssecond"))
	{
		bot_goal_t g;
		int r;
		memset(&g, 0, sizeof(g));
		r = BotGetSecondGoal(h, &g);
		fprintf(fo, "SECOND %d\n", r);
		if (r) print_goal(" G", &g);
	}
	else if (!strcmp(c, "gsdumpstack")) BotDumpGoalStack(h);
	else if (!strcmp(c, "gsdumpavoid")) BotDumpAvoidGoals(h);
	else if (!strcmp(c, "gsavoid")) { fprintf(fo, "AV"); pf("T", BotAvoidGoalTime(h, (int) num(2))); fprintf(fo, "\n"); }
	else if (!strcmp(c, "gssetavoid")) BotSetAvoidGoalTime(h, (int) num(2), fnum(3));
	else if (!strcmp(c, "gsremoveavoid")) BotRemoveFromAvoidGoals(h, (int) num(2));
	else if (!strcmp(c, "gsresetavoid")) BotResetAvoidGoals(h);
	else if (!strcmp(c, "gsname"))
	{
		char name[256];
		int size = (int) num(2);
		memset(name, 'Z', sizeof(name));
		name[sizeof(name) - 1] = 0;
		BotGoalName(h, name, size);
		fprintf(fo, "NAME ");
		print_escaped(fo, name);
		fprintf(fo, "\n");
	}
	else if (!strcmp(c, "gstouch") || !strcmp(c, "gsvis"))
	{
		bot_goal_t g;
		vec3_t o;
		memset(&g, 0, sizeof(g));
		if (!BotGetTopGoal(h, &g)) { fprintf(fo, "NOGOAL\n"); return; }
		if (!strcmp(c, "gstouch")) { vnum(2, o); fprintf(fo, "TOUCH %d\n", BotTouchingGoal(o, &g)); }
		else { vec3_t angles = {0, 0, 0}; vnum(3, o); fprintf(fo, "VIS %d\n", BotItemGoalInVisButNotVisible((int) num(2), o, angles, &g)); }
	}
	else if (!strcmp(c, "gslevelgoal"))
	{
		bot_goal_t g;
		int r;
		memset(&g, 0, sizeof(g));
		r = BotGetLevelItemGoal((int) num(1), arg(2), &g);
		fprintf(fo, "LG %d\n", r);
		if (r >= 0) print_goal(" G", &g);
	}
	else if (!strcmp(c, "gscamp"))
	{
		bot_goal_t g;
		int r;
		memset(&g, 0, sizeof(g));
		r = BotGetNextCampSpotGoal((int) num(1), &g);
		fprintf(fo, "CAMP %d\n", r);
		if (r) print_goal(" G", &g);
	}
	else if (!strcmp(c, "gsloc"))
	{
		bot_goal_t g;
		int r;
		memset(&g, 0, sizeof(g));
		r = BotGetMapLocationGoal(arg(1), &g);
		fprintf(fo, "LOC %d\n", r);
		if (r) print_goal(" G", &g);
	}
	else if (!strcmp(c, "gsbreed")) BotInterbreedGoalFuzzyLogic((int) num(1), (int) num(2), (int) num(3));
	else if (!strcmp(c, "gsmutate")) BotMutateGoalFuzzyLogic(h, fnum(2));
	else if (!strcmp(c, "mvsetup")) fprintf(fo, "RC %d\n", BotSetupMoveAI());
	else if (!strcmp(c, "mvalloc")) fprintf(fo, "H %d\n", BotAllocMoveState());
	else if (!strcmp(c, "mvfree")) BotFreeMoveState(h);
	else if (!strcmp(c, "mvreset")) BotResetMoveState(h);
	else if (!strcmp(c, "mvinit"))
	{
		bot_initmove_t init;
		memset(&init, 0, sizeof(init));
		vnum(2, init.origin); vnum(5, init.velocity); vnum(8, init.viewoffset);
		init.entitynum = (int) num(11); init.client = (int) num(12); init.thinktime = fnum(13);
		init.presencetype = (int) num(14); vnum(15, init.viewangles); init.or_moveflags = (int) num(18);
		BotInitMoveState(h, &init);
	}
	else if (!strcmp(c, "mvavoidspot"))
	{
		vec3_t o;
		vnum(2, o);
		BotAddAvoidSpot(h, o, fnum(5), (int) num(6));
	}
	else if (!strcmp(c, "mvresetavoid")) BotResetAvoidReach(h);
	else if (!strcmp(c, "mvresetlast")) BotResetLastAvoidReach(h);
	else if (!strcmp(c, "mvarea"))
	{
		vec3_t o;
		vnum(1, o);
		fprintf(fo, "AREA %d\n", BotReachabilityArea(o, (int) num(4)));
	}
	else if (!strcmp(c, "mvfuzzy"))
	{
		vec3_t o;
		vnum(1, o);
		fprintf(fo, "AREA %d\n", BotFuzzyPointReachabilityArea(o));
	}
	else if (!strcmp(c, "mvgoal"))
	{
		bot_goal_t g;
		bot_moveresult_t result;
		bot_input_t in;
		int client = (int) num(2), null = !strcmp(arg(4), "null");
		memset(&result, 0xCC, sizeof(result));
		if (!null) read_goal(4, &g);
		BotMoveToGoal(&result, h, null ? NULL : &g, (int) num(3));
		print_result("RES", &result);
		EA_GetInput(client, 0.1f, &in);
		print_input(" IN", &in);
	}
	else if (!strcmp(c, "mvdir"))
	{
		vec3_t d;
		bot_input_t in;
		int client = (int) num(2), r;
		vnum(3, d);
		r = BotMoveInDirection(h, d, fnum(6), (int) num(7));
		fprintf(fo, "DIR %d\n", r);
		EA_GetInput(client, 0.1f, &in);
		print_input(" IN", &in);
	}
	else if (!strcmp(c, "mvview"))
	{
		bot_goal_t g;
		vec3_t target = {0, 0, 0};
		int r;
		read_goal(4, &g);
		r = BotMovementViewTarget(h, &g, (int) num(2), fnum(3), target);
		fprintf(fo, "VT %d", r);
		pv("T", target);
		fprintf(fo, "\n");
	}
	else if (!strcmp(c, "mvpredict"))
	{
		bot_goal_t g;
		vec3_t o, target = {0, 0, 0};
		int r;
		vnum(1, o);
		read_goal(6, &g);
		r = BotPredictVisiblePosition(o, (int) num(4), &g, (int) num(5), target);
		fprintf(fo, "PV %d", r);
		pv("T", target);
		fprintf(fo, "\n");
	}
	else if (!strcmp(c, "mvsim"))
	{
		bot_goal_t g;
		vec3_t o;
		vnum(5, o);
		read_goal(9, &g);
		run_sim(h, (int) num(2), (int) num(3), fnum(4), o, (int) num(8), &g);
	}
	else fprintf(fo, "unknown command %s\n", c);
}
