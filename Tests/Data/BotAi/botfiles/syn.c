// synonyms: the first entry of a list is the replacement, the weights drive the random choice
#include "match.h"

CONTEXT_NORMAL
{
	[("hello", 5), ("hi", 3), ("hey", 2)]
	[("goodbye", 1), ("bye", 1), ("cya", 2)]
	CONTEXT_REPLY
	{
		[("i am", 1), ("im", 1), ("i'm", 1)]
	}
}

CONTEXT_ALL
{
	[("kill", 2), ("frag", 1), ("destroy", 1)]
}

CONTEXT_NEARBYITEM
{
	[("armor", 1), ("vest", 1)]
}
