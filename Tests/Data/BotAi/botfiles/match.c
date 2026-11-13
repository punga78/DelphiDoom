#include "match.h"
// match templates: strings (alternatives with |), variables (numbers) and the message type
CONTEXT_NORMAL
{
	"hello", 1 = (MSG_HELLO, ST_NONE);
	"hi" | "hey", 1 = (MSG_HELLO, ST_PLAYER);
	1, " killed ", 2 = (MSG_KILLED, ST_NONE);
	1, " killed " | " fragged ", 2, " with ", 3 = (MSG_KILLED, ST_PLAYER);
	"give me ", 1 = (MSG_GIVE, ST_NONE);
	"i am " | "im ", 1 = (MSG_NAMED, ST_NONE);
	"say ", 1, " now" = (MSG_LONG, ST_NONE);
	1, " mid ", 2, " end" = (8, 0);
}
CONTEXT_REPLY
{
	"how are you" = (6, 0);
}
CONTEXT_NEARBYITEM
{
	"armor" = (7, 1);
}
