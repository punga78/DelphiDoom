// Issue #110 (id Tech 4 script): driver of the parity harness. Written for this repository; it is linked with the
// REAL Script_Compiler.cpp, Script_Program.cpp, Script_Interpreter.cpp, Script_Thread.cpp, Event.cpp, Class.cpp and
// idlib of Doom 3 (scratch copy, see Build-Harness.ps1) and with the fake game of Game_local.h.
//
// Usage: harness.exe <root of the fake file system> <scenario.scn> <golden.txt>
//
// ---------------------------------------------------------------------------------------------------------------
// FILE SYSTEM. A relative path R is the file <root>/R (or a file made by "genfile"). Its OS path is "/base/" + R:
// RelativePathToOSPath adds the prefix, OSPathToRelativePath removes it (and answers "" when it is not there, so the
// program keeps the full name, as the original). OpenFileRead takes relative paths only and the full path of a file it
// opened is the OS path. So "#include" relative to the including file never works (the first attempt of the parser is
// "/base/script/<name>", an OS path) and the second attempt, relative to the root, does: like the real game.
//
// SCENARIO. One command per line; empty lines and lines that start with '#' are skipped. Arguments are separated by
// blanks; an argument in double quotes may contain blanks and the escapes \" \\ \n \t. "<<EOF" as last argument
// takes the following lines up to a line that is exactly "EOF" as text (lines joined with \n, a \n after the last).
// Every command is echoed as "CMD <line>" (the here text is not echoed). An Error of the game (common->Error,
// gameLocal.Error, savefile->Error) ends the command and prints "ERROR <text>".
//
//   startup <script>               idProgram::Startup( script ); "startup -" = Startup( "" )
//   begin | finish | restart       idProgram::BeginCompilation | FinishCompilation | Restart
//   compilefile <file>             idProgram::CompileFile
//   compiletext <name> <0|1> <<EOF idProgram::CompileText( name, text, console ); prints "RESULT <0|1>"
//   compilefunction <name> <<EOF   idProgram::CompileFunction; prints "FUNCTION <index|-1>"
//   genfile <name> <count> <<EOF   makes the file <name> in memory: the text repeated <count> times, with every '@'
//                                  replaced by the index (0..count-1) of the repetition
//   dump program                   files, types, defs, functions, statements, globals, checksum (format below)
//   dump statements <first> <n>    only the STMT lines
//   dump globals                   only GLOBALS and G lines
//   dump disasm                    the real idProgram::Disassemble: one "DISASM <line>" per line of script/disasm.txt
//   dump threads                   CURRENT, THREADINDEX, THREAD and CALL lines
//   dump stacks                    one "STACK <thread> <hex>" per thread (localstack[0..localstackUsed))
//   dump events                    the event queue: EVENT lines
//   dump entities                  the fake entities: ENTITY lines
//   dump return                    "RETURN <w0> <w1> <w2> <string>": the three words of returnDef and returnStringDef
//   spawn <num> <class> <name> [key value]...   a fake entity (classes below) in slot <num>; the pairs are its spawn
//                                  args; program.SetEntity( name, ent ). No script object.
//   setobject <num> <type>         scriptObject.SetType( type ) (prints "SETTYPE <0|1>") and, if it worked,
//                                  idEntity::ConstructScriptObject (thread named as the entity, CallFunction( ent,
//                                  constructor, true ), DelayedStart( 0 ), then ClearObject)
//   remove <num>                   delete the entity (destructor: "HOST free", DeconstructScriptObject, Free,
//                                  Signal( SIG_REMOVE ), SetEntity( name, NULL ))
//   thread <function>              new idThread( FindFunction( name ) ); DelayedStart( 0 ); prints "THREADNUM <n>"
//   objthread <num> <function>     new idThread(); SetThreadName( ent->name ); CallFunction( ent,
//                                  ent->scriptObject.GetFunction( name ), true ); DelayedStart( 0 ); "THREADNUM <n>"
//   callnow <function>             new idThread( FindFunction( name ) ); Start(); prints "DONE <0|1>" and RETURN
//   frame <n>                      n times: time += msec (16); realClientTime = time; framenum++;
//                                  idEvent::ServiceEvents(); then "FRAME time=<t> framenum=<n> events=<queue length>"
//                                  and the THREAD lines (no CALL lines)
//   displayinfo <thread>           idThread::DisplayInfo
//   listthreads                    idThread::ListThreads_f
//   getvar <thread> <name> [depth] idInterpreter::GetRegisterValue (depth -1 if missing): "GETVAR <0|1> <text>"
//   setcvar <name> <value>         sets a cvar directly (no HOST line): g_debugScript, developer, g_disasm,
//                                  g_debugTriggers or any other name
//   set <what> <value>             host state: isClient, isMultiplayer, influence (of the player), time, msec
//   settrace <fraction> <ent> <id> what the next traces of the fake clip answer (fraction as decimal text)
//   event <num> <event> [args]     ent->ProcessEvent( event, args ) from the host; prints "PROCESSED <0|1>"
//   postevent <num> <ms> <event> [args]   ent->PostEventMS( event, ms, args ); prints "POSTED <0|1>"
//                                  args by the format of the event: f decimal, d integer, s text, v "x y z" in
//                                  quotes, e/E entity number or "null"
//   signal <num> <signal>          ent->Signal( signal )
//   movedone <thread> <num>        idThread::ObjectMoveDone( thread, ent )
//   killthread <name|number>       idThread::KillThread( name ) or, if all digits, KillThread( number )
//   endthread <thread>             idThread::End of that thread
//   debuginfo <thread> <0|1>       idThread::DisableDebugInfo | EnableDebugInfo (the debug flag of its interpreter)
//   save                           the composite save below; keeps the buffer; prints SAVE lines
//   restore                        restores from the buffer of the last save (below)
//   findfunction <name>            "FUNCTION <index|-1>" (idProgram::FindFunction)
//   scriptvar <num> <name> <type>  idScriptObject::GetVariable( name, type ), type = float|vector|string|boolean|
//                                  entity|object: "SCRIPTVAR <offset|-1> <value>"
//
// GOLDEN. ASCII only, one fact per line. Floats are always "#XXXXXXXX" (the bits of the single). Text is escaped:
// \\ \n \r \t \" and \xHH for anything outside 32..126.
//   PRINT <text>      a whole line printed by gameLocal.Printf / common->Printf (the \n is not shown)
//   PRINT+ <text>     printed text that was not followed by a \n when another line had to be written
//   DPRINT / DPRINT+  the same for DPrintf
//   WARN <text>       gameLocal.Warning, common->Warning, DWarning (one call = one line)
//   ERROR <text>      the Error that ended the command
//   HOST <api> ...    a call to a stub of the game (list below)
//   Two kinds of printed lines are normalized because they hold sizes of C++ objects or real time:
//     "Compiled '<name>': <ms> ms"   -> the number becomes "?"
//     the memory lines of idProgram::CompileStats ("     Strings:", "  Statements:", "   Functions:", "    Mem used:",
//     " Static data:", "   Allocated:", " Thread size:") -> every number after the first comma, or the only number,
//     becomes "?" ("   Variables: N bytes" is exact and is kept)
//
// dump program:
//   FILE <i> <name>
//   TYPE <i> name=<text> etype=<n> size=<n> aux=<name|-> def=<def> parms=[<type name>:<parm name>,...] funcs=[<function index>,...]
//   DEF <num> name=<text> type=<type name>/<etype> scope=<def> init=<0 uninitialized|1 variable|2 constant|3 stack>
//       users=<n> value=<value>
//       <value>: stack:<offset> | func:<index|-1> | jump:<n> | args:<n> | virt:<n> | ptr:<offset> (a member of an
//       object) | global:<offset>[=<content>] with content #bits (float), #x,#y,#z (vector), "text" (string), an
//       integer (entity, boolean, object, field, pointer)
//       <def>: the number of a def of the program, or @<type name> for one of the predefined defs (def_namespace...)
//   FUNC <i> name=<text> event=<event name|-> def=<def> first=<n> num=<n> parmTotal=<n> locals=<n> filenum=<n> parmSize=[n,...]
//   STMT <i> <opcode name> a=<def|-> b=<def|-> c=<def|-> line=<n> file=<n>
//   TOP functions=<n> statements=<n> types=<n> defs=<n> files=<n>
//   GLOBALS <numVariables>, then "G <offset, 6 hex digits> <up to 32 bytes in hex>" (rows that are all zero are skipped)
//   CHECKSUM <8 hex digits>   (idProgram::CalculateChecksum)
// dump threads:
//   CURRENT <thread number|0>
//   THREADINDEX <n>
//   THREAD <num> name=<text> dying=<0|1> done=<0|1> waitingFor=<entity number, 4095 = none> waitingUntil=<n>
//       waitingForThread=<num|0> lastExec=<n> created=<n> manual=<0|1> depth=<callStackDepth> used=<localstackUsed>
//       base=<localstackBase> maxDepth=<n> maxUsed=<n> ip=<instructionPointer> func=<index|-1> popParms=<n>
//       multiFrame=<event name|-> eventEntity=<number|-> terminateOnExit=<0|1> debug=<0|1> spawnArgs=[key=value,...]
//   CALL <i> s=<n> f=<function index|-1> base=<n>        (for i in 0..depth-1)
// dump events:
//   EVENT time=<n> name=<event> class=<class name> object=<thread:<num>|ent:<num>> args=<hex of the event data>
// dump entities:
//   ENTITY <num> class=<class> name=<text> value=#bits origin=#x,#y,#z owner=<n> object=<type name|-> data=<hex>
//
// SAVE (command "save"), four parts in one buffer:
//   1. idProgram::Save
//   2. int count, then idThread::Save of every thread of threadList, in order
//   3. idEvent::Save
//   4. for every entity (by number): int number, idScriptObject::Save; then int -1
//   Primitives as the real SaveGame.cpp: int, float 4 bytes little endian; bool, byte 1 byte; string = int length +
//   bytes; vec3 12 bytes; dict = int count + key and value strings (-1 if NULL). WriteObject writes one int: -1 for
//   NULL, <index in threadList> + 1 for a thread, 0x40000000 | entityNumber for an entity.
//   The golden shows: "SAVE program <hex>", "SAVE thread <i> <hex without the local stack>" and "SAVE stack <i> <hex of
//   the local stack>" (the stack may hold real pointers: temporaries of OP_ADDRESS), "SAVE events <hex>",
//   "SAVE objects <hex>".
// RESTORE (command "restore"): idProgram::Restart (it deletes the threads), idEvent::ClearEventList,
//   idProgram::Restore (prints "RESTORE program <0|1>"), read the count and make that many "new idThread()", Restore
//   each one, idEvent::Restore, then the script objects (the entities must still exist). After it threadIndex is the
//   number of restored threads, as in the original.
//
// FAKE ENTITIES. Class (super): event "name" format[:return] -> what it does. Every handler prints
// "HOST event <entity number> <event name> <args>" first (args: #bits, integers, "text", #x,#y,#z, ent:<n> or null).
//   idEntity (idClass):
//     "activate" e            nothing else
//     "setShaderParm" df      nothing else       "cacheSoundShader" s    nothing else
//     "getName" :s            returns the name   "setName" s             sets it, program.SetEntity old -> NULL, new -> ent
//     "setValue" f            value = f          "getValue" :f           returns value
//     "setOrigin" v           origin = v         "getOrigin" :v          returns origin
//     "setOwner" E            owner              "getOwner" :e           returns the owner (or NULL)
//     "bind" e                nothing else (an 'e' argument: a NULL entity ends the calling thread)
//     "setKey" ss             spawnArgs.Set      "getKey" s:s            spawnArgs.GetString( key, "" )
//     "addInts" dd:d          returns a + b (idThread::ReturnInt)
//     "mix" fdvsE:f           returns f + d
//     "<hostping>" d          d >= 0: nothing else; d < 0: does not print and posts itself again with 0 ms (endless)
//     "remove" (idClass)      PostEventMS( EV_Remove, 0 ) -> delete
//   idMover (idEntity):
//     "moveTo" vf             dest = v, moving = true, move_thread = 0, PostEventSec( "<movedone>", f )
//     "<movedone>"            moving = false, origin = dest; if move_thread: idThread::ObjectMoveDone( move_thread,
//                             this ), move_thread = 0
//     "isMoving" :f           returns moving
//     "<script_setcallback>"  (EV_Thread_SetCallback, used by sys.waitFor) if moving and no move_thread: move_thread =
//                             idThread::CurrentThreadNum(), ReturnInt( true ); else ReturnInt( false )
//     "slowTurn" f            multi frame event: if idThread::BeginMultiFrameEvent( this, ev ) then turnLeft = int( f )
//                             and prints "HOST slowTurn begin <n>"; turnLeft--; prints "HOST slowTurn tick <turnLeft>";
//                             when turnLeft <= 0: idThread::EndMultiFrameEvent and "HOST slowTurn end"
//   idCamera (idEntity), idAFEntity_Base (idEntity): no events of their own
//   idPlayer (idEntity): no events; the last idPlayer spawned is gameLocal.GetLocalPlayer()
//   Three events exist only in the table, no class answers them: "traceArg" t, "traceRet" :t and "spare" f (the
//   last one is not declared by script/doom_defs.script).
//   Signal( n ): "HOST Signal <ent> <n>", then as the original: for every (thread, function) set on that signal (the
//   list is cleared first) thread->CallFunction( function, true ); thread->Execute().
//   SetSignal: "HOST SetSignal <ent> <signal> <thread number> <function index>"; ClearSignalThread: "HOST
//   ClearSignalThread <ent> <signal> <thread number>".
//
// OTHER HOST LINES (stubs of the game reached by the sys events):
//   HOST FindEntity "name"                        -> the entity with that name (idStr::Icmp), or NULL
//   HOST SpawnEntityDef key=value ...             -> "classname" is the C++ class; the entity takes the first free slot
//        from 32, the name of the key "name" or "<classname>_<number>", the key "scriptobject" makes the object as
//        setobject; then "HOST spawned ent:<n> class=<c> name=<text>" or "HOST spawned null" (unknown class)
//   HOST SetCVarString "name" "value"   HOST GetCVarString "name"   (unknown cvar = "")
//   HOST BufferCommandText "text"
//   HOST TracePoint <start> <end> <mask> <pass>   HOST TraceBounds <start> <end> <mins> <maxs> <mask> <pass>
//        -> fraction, entity and id of the last settrace (default 1, 4095, 0), endpos = start + ( end - start ) *
//        fraction, normal = ( 0, 0, 1 ); the joint name of an idAFEntity_Base is "joint<handle>", its body "body<id>"
//   HOST SetCamera <ent|null>   HOST Fade <color r,g,b,a> <ms>   HOST PlayShaderDirectly "name"
//   HOST RadiusDamage <origin> <inflictor> <attacker> <ignoreDamage> <ignorePush> "def" #power
//   HOST FindSound "name"   HOST TriggerGuis <ent>
//   HOST DebugLine <color> <start> <end> <ms>   HOST DebugArrow <color> <start> <end> <size> <ms>
//   HOST DebugCircle <color> <origin> <dir> #radius <steps> <ms>   HOST DebugBounds <color> <mins> <maxs> <org> <ms>
//   HOST DrawText "text" <origin> #scale <color> <align> <ms>
//   HOST free <ent>                               -> the destructor of an entity
// gameLocal.random is the real idRandom with seed 0; gameLocal.msec is 16; time starts at 0.
// ---------------------------------------------------------------------------------------------------------------
#include "precompiled.h"
#include "../game/Game_local.h"
#include <fstream>

// ---- idlib statics ----
static idSys theSys;
static idCommon theCommon;
static idFileSystem theFs;
idSys *idLib::sys = &theSys;
idCommon *idLib::common = &theCommon;
idFileSystem *idLib::fileSystem = &theFs;
idCommon *common = &theCommon;
idSys *sys = &theSys;
idFileSystem *fileSystem = &theFs;
#include "math/Simd_Generic.h"
static idSIMD_Generic simdGeneric;
idSIMDProcessor *SIMDProcessor = &simdGeneric;
bool Swap_IsBigEndian( void ) { return false; }

static FILE *out = NULL;
static bool quiet = false;
static std::string fsRoot;
static std::map<std::string, std::string> memFiles;

// ---- output ----
static std::string esc( const char *s, int n ) {
	std::string r;
	for ( int i = 0; i < n; i++ ) {
		unsigned char c = ( unsigned char )s[ i ];
		char b[ 8 ];
		if ( c == '\\' ) r += "\\\\";
		else if ( c == '\n' ) r += "\\n";
		else if ( c == '\r' ) r += "\\r";
		else if ( c == '\t' ) r += "\\t";
		else if ( c == '"' ) r += "\\\"";
		else if ( c < 32 || c > 126 ) { sprintf( b, "\\x%02X", c ); r += b; }
		else r += ( char )c;
	}
	return r;
}
static std::string esc( const char *s ) { return esc( s, ( int )strlen( s ) ); }
static std::string q( const char *s ) { return "\"" + esc( s ) + "\""; }
static std::string fb( float f ) { unsigned int u; memcpy( &u, &f, 4 ); char b[ 16 ]; sprintf( b, "#%08X", u ); return b; }
static std::string v3( const idVec3 &v ) { return fb( v.x ) + "," + fb( v.y ) + "," + fb( v.z ); }
static std::string v4( const idVec4 &v ) { return fb( v.x ) + "," + fb( v.y ) + "," + fb( v.z ) + "," + fb( v.w ); }
static std::string num( int n ) { char b[ 16 ]; sprintf( b, "%d", n ); return b; }
static std::string hex( const void *p, int n ) {
	std::string r; char b[ 4 ];
	for ( int i = 0; i < n; i++ ) { sprintf( b, "%02X", ( ( const unsigned char * )p )[ i ] ); r += b; }
	return r;
}
static std::string entRef( const idEntity *e ) { return e ? "ent:" + num( e->entityNumber ) : std::string( "null" ); }

static std::string pending[ 2 ];		// 0 = Printf, 1 = DPrintf
static const char *pendingTag[ 2 ] = { "PRINT", "DPRINT" };

static void flushPending( void ) {
	for ( int i = 0; i < 2; i++ ) {
		if ( !pending[ i ].empty() ) {
			fprintf( out, "%s+ %s\n", pendingTag[ i ], esc( pending[ i ].c_str(), ( int )pending[ i ].size() ).c_str() );
			pending[ i ].clear();
		}
	}
}

static void line( const std::string &s ) {
	if ( quiet ) return;
	flushPending();
	fprintf( out, "%s\n", s.c_str() );
}

static std::string replaceNumbers( const std::string &s, size_t from ) {
	std::string r = s.substr( 0, from );
	size_t i = from;
	while ( i < s.size() ) {
		if ( isdigit( ( unsigned char )s[ i ] ) ) {
			while ( i < s.size() && ( isdigit( ( unsigned char )s[ i ] ) || s[ i ] == '.' ) ) i++;
			r += '?';
		} else {
			r += s[ i++ ];
		}
	}
	return r;
}

static std::string normalize( const std::string &s ) {
	static const char *mem[] = { "     Strings:", "  Statements:", "   Functions:", "    Mem used:", " Static data:", "   Allocated:", " Thread size:", NULL };
	if ( s.compare( 0, 10, "Compiled '" ) == 0 ) {
		size_t p = s.rfind( "': " );
		if ( p != std::string::npos ) return replaceNumbers( s, p + 3 );
	}
	for ( int i = 0; mem[ i ]; i++ ) {
		if ( s.compare( 0, strlen( mem[ i ] ), mem[ i ] ) == 0 ) {
			size_t p = s.find( ',' );
			return replaceNumbers( s, p == std::string::npos ? strlen( mem[ i ] ) : p );
		}
	}
	return s;
}

static void printed( int kind, const char *text ) {
	if ( quiet ) return;
	if ( !pending[ 1 - kind ].empty() ) flushPending();
	pending[ kind ] += text;
	size_t p;
	while ( ( p = pending[ kind ].find( '\n' ) ) != std::string::npos ) {
		std::string l = normalize( pending[ kind ].substr( 0, p ) );
		pending[ kind ].erase( 0, p + 1 );
		fprintf( out, "%s %s\n", pendingTag[ kind ], esc( l.c_str(), ( int )l.size() ).c_str() );
	}
}

#define VFORMAT( b ) char b[ 8192 ]; { va_list ap; va_start( ap, fmt ); vsprintf( b, fmt, ap ); va_end( ap ); }
static void throwError( const char *text ) { harnessError e; strncpy( e.text, text, sizeof( e.text ) - 1 ); e.text[ sizeof( e.text ) - 1 ] = 0; throw e; }

void idCommon::Printf( const char *fmt, ... ) { VFORMAT( b ); printed( 0, b ); }
void idCommon::DPrintf( const char *fmt, ... ) { VFORMAT( b ); printed( 1, b ); }
void idCommon::Warning( const char *fmt, ... ) { VFORMAT( b ); line( "WARN " + esc( b ) ); }
void idCommon::DWarning( const char *fmt, ... ) { VFORMAT( b ); line( "WARN " + esc( b ) ); }
void idCommon::Error( const char *fmt, ... ) { VFORMAT( b ); throwError( b ); }
void idCommon::FatalError( const char *fmt, ... ) { VFORMAT( b ); throwError( b ); }
void idLib::Error( const char *fmt, ... ) { VFORMAT( b ); throwError( b ); }
void idLib::Warning( const char *fmt, ... ) { VFORMAT( b ); line( "WARN " + esc( b ) ); }
void gameError( const char *fmt, ... ) { VFORMAT( b ); throwError( b ); }

// ---- file system ----
static bool isOsPath( const char *n ) { return memcmp( n, "/base/", strlen( n ) < 6 ? strlen( n ) + 1 : 6 ) == 0; }
static bool readWhole( const char *n, std::string &data ) {
	if ( isOsPath( n ) ) return false;
	std::map<std::string, std::string>::iterator it = memFiles.find( n );
	if ( it != memFiles.end() ) { data = it->second; return true; }
	std::string path = fsRoot + "/" + n;
	FILE *f = fopen( path.c_str(), "rb" );
	if ( !f ) return false;
	data.clear();
	char buf[ 4096 ]; size_t r;
	while ( ( r = fread( buf, 1, sizeof( buf ), f ) ) > 0 ) data.append( buf, r );
	fclose( f );
	return true;
}
idFile *idFileSystem::OpenFileRead( const char *n ) {
	std::string data;
	if ( !readWhole( n, data ) ) return NULL;
	idFile *f = new idFile; f->rd = data; f->name = n; f->full = std::string( "/base/" ) + n; return f;
}
idFile *idFileSystem::OpenExplicitFileRead( const char *n ) {
	if ( !isOsPath( n ) ) return NULL;
	return OpenFileRead( n + 6 );
}
idFile *idFileSystem::OpenFileWrite( const char *n ) { idFile *f = new idFile; f->name = n; f->writing = true; return f; }
idFile *idFileSystem::OpenFileByMode( const char *n, fsMode_t mode ) { return mode == FS_READ ? OpenFileRead( n ) : OpenFileWrite( n ); }
void idFileSystem::CloseFile( idFile *f ) {
	if ( f->writing ) {
		// a written file is shown line by line
		std::string tag = ( f->name == "script/disasm.txt" ) ? "DISASM" : ( "FILEOUT " + f->name );
		size_t start = 0;
		while ( start < f->out.size() ) {
			size_t p = f->out.find( '\n', start );
			if ( p == std::string::npos ) p = f->out.size();
			line( tag + " " + esc( f->out.c_str() + start, ( int )( p - start ) ) );
			start = p + 1;
		}
	}
	delete f;
}
int idFileSystem::ReadFile( const char *n, void **b, ID_TIME_T *t ) {
	std::string data;
	if ( !readWhole( n, data ) ) { if ( b ) *b = NULL; return -1; }
	char *buf = ( char * )malloc( data.size() + 1 );
	memcpy( buf, data.data(), data.size() ); buf[ data.size() ] = 0;
	if ( b ) *b = buf; else free( buf );
	return ( int )data.size();
}
void idFileSystem::FreeFile( void *b ) { free( b ); }
const char *idFileSystem::RelativePathToOSPath( const char *rel ) { static char b[ 1024 ]; sprintf( b, "/base/%s", rel ); return b; }
const char *idFileSystem::OSPathToRelativePath( const char *os ) {
	static char b[ 1024 ];
	if ( isOsPath( os ) ) strcpy( b, os + 6 ); else b[ 0 ] = 0;
	return b;
}

// ---- cvars, commands, declarations, renderer, sound ----
idCVar *idCVar::list = NULL;
idCVar::idCVar( const char *n, const char *v ) : name( n ), value( v ) { next = list; list = this; }
idCVar g_disasm( "g_disasm", "0" );
idCVar g_debugScript( "g_debugScript", "0" );
idCVar g_debugTriggers( "g_debugTriggers", "0" );
idCVar developer( "developer", "0" );
static idCVar *findCVar( const char *name, bool create ) {
	for ( idCVar *c = idCVar::list; c; c = c->next ) if ( idStr::Icmp( c->name.c_str(), name ) == 0 ) return c;
	return create ? new idCVar( name, "" ) : NULL;
}
static idCVarSystem theCVarSystem; idCVarSystem *cvarSystem = &theCVarSystem;
void idCVarSystem::SetCVarString( const char *name, const char *value, int ) {
	line( "HOST SetCVarString " + q( name ) + " " + q( value ) );
	findCVar( name, true )->SetString( value );
}
const char *idCVarSystem::GetCVarString( const char *name ) const {
	line( "HOST GetCVarString " + q( name ) );
	idCVar *c = findCVar( name, false );
	return c ? c->GetString() : "";
}
static idCmdSystem theCmdSystem; idCmdSystem *cmdSystem = &theCmdSystem;
void idCmdSystem::BufferCommandText( cmdExecution_t, const char *text ) { line( "HOST BufferCommandText " + q( text ) ); }
static idDeclManager theDeclManager; idDeclManager *declManager = &theDeclManager;
static idMaterial theMaterial; static idSoundShader theSound;
const idMaterial *idDeclManager::FindMaterial( const char *name, bool ) { line( "HOST FindMaterial " + q( name ) ); return &theMaterial; }
const idSoundShader *idDeclManager::FindSound( const char *name, bool ) { line( "HOST FindSound " + q( name ) ); return &theSound; }
static idRenderWorld theRenderWorld; idRenderWorld *gameRenderWorld = &theRenderWorld;
void idRenderWorld::DebugLine( const idVec4 &color, const idVec3 &start, const idVec3 &end, const int lifetime ) {
	line( "HOST DebugLine " + v4( color ) + " " + v3( start ) + " " + v3( end ) + " " + num( lifetime ) );
}
void idRenderWorld::DebugArrow( const idVec4 &color, const idVec3 &start, const idVec3 &end, int size, const int lifetime ) {
	line( "HOST DebugArrow " + v4( color ) + " " + v3( start ) + " " + v3( end ) + " " + num( size ) + " " + num( lifetime ) );
}
void idRenderWorld::DebugCircle( const idVec4 &color, const idVec3 &origin, const idVec3 &dir, const float radius, const int numSteps, const int lifetime ) {
	line( "HOST DebugCircle " + v4( color ) + " " + v3( origin ) + " " + v3( dir ) + " " + fb( radius ) + " " + num( numSteps ) + " " + num( lifetime ) );
}
void idRenderWorld::DebugBounds( const idVec4 &color, const idBounds &bounds, const idVec3 &org, const int lifetime ) {
	line( "HOST DebugBounds " + v4( color ) + " " + v3( bounds[ 0 ] ) + " " + v3( bounds[ 1 ] ) + " " + v3( org ) + " " + num( lifetime ) );
}
void idRenderWorld::DrawText( const char *text, const idVec3 &origin, float scale, const idVec4 &color, const idMat3 &, const int align, const int lifetime ) {
	line( "HOST DrawText " + q( text ) + " " + v3( origin ) + " " + fb( scale ) + " " + v4( color ) + " " + num( align ) + " " + num( lifetime ) );
}
static idSoundWorld theSoundWorld; idSoundWorld *gameSoundWorld = &theSoundWorld;
void idSoundWorld::PlayShaderDirectly( const char *name ) { line( "HOST PlayShaderDirectly " + q( name ) ); }

// ---- clip ----
static float traceFraction = 1.0f;
static int traceEntity = ENTITYNUM_NONE;
static int traceId = 0;
static void fillTrace( trace_t &t, const idVec3 &start, const idVec3 &end ) {
	memset( &t, 0, sizeof( t ) );
	t.fraction = traceFraction;
	t.endpos = start + ( end - start ) * traceFraction;
	t.endAxis.Identity();
	t.c.normal.Set( 0.0f, 0.0f, 1.0f );
	t.c.entityNum = traceEntity;
	t.c.id = traceId;
}
bool idClip::TracePoint( trace_t &results, const idVec3 &start, const idVec3 &end, int contentMask, const idEntity *passEntity ) {
	line( "HOST TracePoint " + v3( start ) + " " + v3( end ) + " " + num( contentMask ) + " " + entRef( passEntity ) );
	fillTrace( results, start, end );
	return results.fraction < 1.0f;
}
bool idClip::TraceBounds( trace_t &results, const idVec3 &start, const idVec3 &end, const idBounds &bounds, int contentMask, const idEntity *passEntity ) {
	line( "HOST TraceBounds " + v3( start ) + " " + v3( end ) + " " + v3( bounds[ 0 ] ) + " " + v3( bounds[ 1 ] ) + " " + num( contentMask ) + " " + entRef( passEntity ) );
	fillTrace( results, start, end );
	return results.fraction < 1.0f;
}
idAFBody *idPhysics_AF::GetBody( const int id ) { body.name = va( "body%d", id ); return &body; }
const char *idAnimator::GetJointName( int handle ) const { return va( "joint%d", handle ); }

// ---- save games ----
static int threadIndexInList( const idThread *t ) {
	idList<idThread *> &l = idThread::GetThreads();
	for ( int i = 0; i < l.Num(); i++ ) if ( l[ i ] == t ) return i;
	return -1;
}
void idSaveGame::WriteDict( const idDict *dict ) {
	if ( !dict ) { WriteInt( -1 ); return; }
	int n = dict->GetNumKeyVals();
	WriteInt( n );
	for ( int i = 0; i < n; i++ ) {
		const idKeyValue *kv = dict->GetKeyVal( i );
		WriteString( kv->GetKey() );
		WriteString( kv->GetValue() );
	}
}
void idSaveGame::WriteObject( const idClass *obj ) {
	if ( !obj ) { WriteInt( -1 ); return; }
	if ( obj->IsType( idThread::Type ) ) { WriteInt( threadIndexInList( static_cast<const idThread *>( obj ) ) + 1 ); return; }
	WriteInt( 0x40000000 | static_cast<const idEntity *>( obj )->entityNumber );
}
void idRestoreGame::Error( const char *fmt, ... ) { VFORMAT( b ); throwError( b ); }
void idRestoreGame::Read( void *buffer, int len ) {
	if ( len < 0 || pos + ( size_t )len > buf.size() ) throwError( "harness: read past the end of the save buffer" );
	memcpy( buffer, buf.data() + pos, len ); pos += len;
}
void idRestoreGame::ReadString( idStr &string ) {
	int len; ReadInt( len );
	if ( len < 0 || pos + ( size_t )len > buf.size() ) throwError( "harness: read past the end of the save buffer" );
	string = idStr( buf.substr( pos, len ).c_str() ); pos += len;
}
void idRestoreGame::ReadDict( idDict *dict ) {
	int n; idStr key, value;
	ReadInt( n );
	if ( n == -1 ) return;
	dict->Clear();
	for ( int i = 0; i < n; i++ ) { ReadString( key ); ReadString( value ); dict->Set( key, value ); }
}
void idRestoreGame::ReadObject( idClass *&obj ) {
	int n; ReadInt( n );
	if ( n == -1 ) obj = NULL;
	else if ( n & 0x40000000 ) obj = gameLocal.entities[ n & ( MAX_GENTITIES - 1 ) ];
	else if ( n >= 1 && n <= idThread::GetThreads().Num() ) obj = idThread::GetThreads()[ n - 1 ];
	else obj = NULL;
}

// ---- gameLocal ----
idGameLocal gameLocal;
idGameLocal::idGameLocal() {
	memset( entities, 0, sizeof( entities ) );
	memset( spawnIds, -1, sizeof( spawnIds ) );
	memset( globalShaderParms, 0, sizeof( globalShaderParms ) );
	spawnCount = INITIAL_SPAWN_COUNT;
	framenum = 0; time = 0; msec = 16; realClientTime = 0;
	isClient = false; isMultiplayer = false; localPlayer = NULL; camera = NULL;
}
void idGameLocal::Printf( const char *fmt, ... ) const { VFORMAT( b ); printed( 0, b ); }
void idGameLocal::DPrintf( const char *fmt, ... ) const { VFORMAT( b ); printed( 1, b ); }
void idGameLocal::Warning( const char *fmt, ... ) const { VFORMAT( b ); line( "WARN " + esc( b ) ); }
void idGameLocal::DWarning( const char *fmt, ... ) const { VFORMAT( b ); line( "WARN " + esc( b ) ); }
void idGameLocal::Error( const char *fmt, ... ) const { VFORMAT( b ); throwError( b ); }
idEntity *idGameLocal::FindEntity( const char *name ) const {
	line( "HOST FindEntity " + q( name ) );
	for ( int i = 0; i < MAX_GENTITIES; i++ ) {
		if ( entities[ i ] && idStr::Icmp( entities[ i ]->name.c_str(), name ) == 0 ) return entities[ i ];
	}
	return NULL;
}
static idEntity *makeEntity( int number, const char *classname, const char *name, const idDict &args ) {
	idTypeInfo *cls = idClass::GetClass( classname );
	if ( !cls || !cls->IsType( idEntity::Type ) ) return NULL;
	idEntity *ent = static_cast<idEntity *>( cls->CreateInstance() );
	ent->entityNumber = number;
	ent->name = name;
	ent->spawnArgs = args;
	gameLocal.entities[ number ] = ent;
	gameLocal.spawnIds[ number ] = gameLocal.spawnCount++;
	if ( cls == &idPlayer::Type ) gameLocal.localPlayer = static_cast<idPlayer *>( ent );
	gameLocal.program.SetEntity( name, ent );
	return ent;
}
bool idGameLocal::SpawnEntityDef( const idDict &args, idEntity **ent ) {
	std::string s = "HOST SpawnEntityDef";
	for ( int i = 0; i < args.GetNumKeyVals(); i++ ) {
		const idKeyValue *kv = args.GetKeyVal( i );
		s += " " + esc( kv->GetKey().c_str() ) + "=" + esc( kv->GetValue().c_str() );
	}
	line( s );
	if ( ent ) *ent = NULL;
	const char *classname = args.GetString( "classname" );
	int number;
	for ( number = MAX_CLIENTS; number < ENTITYNUM_WORLD; number++ ) if ( !entities[ number ] ) break;
	idStr name = args.GetString( "name", va( "%s_%d", classname, number ) );
	idEntity *e = makeEntity( number, classname, name, args );
	if ( !e ) { line( "HOST spawned null" ); return false; }
	line( "HOST spawned ent:" + num( number ) + " class=" + classname + " name=" + q( name ) );
	const char *objType = args.GetString( "scriptobject" );
	if ( objType[ 0 ] && e->scriptObject.SetType( objType ) ) e->ConstructScriptObject();
	if ( ent ) *ent = e;
	return true;
}
void idGameLocal::SetCamera( idCamera *cam ) { line( "HOST SetCamera " + entRef( cam ) ); camera = cam; }
void idGameLocal::RadiusDamage( const idVec3 &origin, idEntity *inflictor, idEntity *attacker, idEntity *ignoreDamage, idEntity *ignorePush, const char *damageDefName, float dmgPower ) {
	line( "HOST RadiusDamage " + v3( origin ) + " " + entRef( inflictor ) + " " + entRef( attacker ) + " " + entRef( ignoreDamage ) + " " + entRef( ignorePush ) + " " + q( damageDefName ) + " " + fb( dmgPower ) );
}
void idPlayerView::Fade( idVec4 color, int time ) { line( "HOST Fade " + v4( color ) + " " + num( time ) ); }

// ---- fake entities ----
const idEventDef EV_Activate( "activate", "e" );
const idEventDef EV_SetShaderParm( "setShaderParm", "df" );
const idEventDef EV_CacheSoundShader( "cacheSoundShader", "s" );
const idEventDef EV_GetName( "getName", NULL, 's' );
const idEventDef EV_SetName( "setName", "s" );
const idEventDef EV_SetValue( "setValue", "f" );
const idEventDef EV_GetValue( "getValue", NULL, 'f' );
const idEventDef EV_SetOrigin( "setOrigin", "v" );
const idEventDef EV_GetOrigin( "getOrigin", NULL, 'v' );
const idEventDef EV_SetOwner( "setOwner", "E" );
const idEventDef EV_GetOwner( "getOwner", NULL, 'e' );
const idEventDef EV_Bind( "bind", "e" );
const idEventDef EV_SetKey( "setKey", "ss" );
const idEventDef EV_GetKey( "getKey", "s", 's' );
const idEventDef EV_AddInts( "addInts", "dd", 'd' );
const idEventDef EV_Mix( "mix", "fdvsE", 'f' );
const idEventDef EV_HostPing( "<hostping>", "d" );
const idEventDef EV_MoveTo( "moveTo", "vf" );
const idEventDef EV_MoveDone( "<movedone>", NULL );
const idEventDef EV_IsMoving( "isMoving", NULL, 'f' );
const idEventDef EV_SlowTurn( "slowTurn", "f" );
const idEventDef EV_TraceArg( "traceArg", "t" );
const idEventDef EV_TraceRet( "traceRet", NULL, 't' );
const idEventDef EV_Spare( "spare", "f" );

static std::string evHead( const idEntity *e, const idEventDef &ev ) { return "HOST event " + num( e->entityNumber ) + " " + ev.GetName(); }

CLASS_DECLARATION( idClass, idEntity )
	EVENT( EV_Activate,			idEntity::Event_Activate )
	EVENT( EV_SetShaderParm,	idEntity::Event_SetShaderParm )
	EVENT( EV_CacheSoundShader,	idEntity::Event_CacheSoundShader )
	EVENT( EV_GetName,			idEntity::Event_GetName )
	EVENT( EV_SetName,			idEntity::Event_SetName )
	EVENT( EV_SetValue,			idEntity::Event_SetValue )
	EVENT( EV_GetValue,			idEntity::Event_GetValue )
	EVENT( EV_SetOrigin,		idEntity::Event_SetOrigin )
	EVENT( EV_GetOrigin,		idEntity::Event_GetOrigin )
	EVENT( EV_SetOwner,			idEntity::Event_SetOwner )
	EVENT( EV_GetOwner,			idEntity::Event_GetOwner )
	EVENT( EV_Bind,				idEntity::Event_Bind )
	EVENT( EV_SetKey,			idEntity::Event_SetKey )
	EVENT( EV_GetKey,			idEntity::Event_GetKey )
	EVENT( EV_AddInts,			idEntity::Event_AddInts )
	EVENT( EV_Mix,				idEntity::Event_Mix )
	EVENT( EV_HostPing,			idEntity::Event_HostPing )
END_CLASS

idEntity::idEntity() { entityNumber = ENTITYNUM_NONE; value = 0.0f; origin.Zero(); owner = 0; }
idEntity::~idEntity() {
	line( "HOST free " + num( entityNumber ) );
	DeconstructScriptObject();
	scriptObject.Free();
	Signal( SIG_REMOVE );
	if ( gameLocal.localPlayer == this ) gameLocal.localPlayer = NULL;
	if ( gameLocal.entities[ entityNumber ] == this ) {
		gameLocal.entities[ entityNumber ] = NULL;
		gameLocal.program.SetEntity( name, NULL );
	}
}
idThread *idEntity::ConstructScriptObject( void ) {
	idThread *thread;
	const function_t *constructor;
	scriptObject.ClearObject();
	constructor = scriptObject.GetConstructor();
	if ( constructor ) {
		thread = new idThread();
		thread->SetThreadName( name.c_str() );
		thread->CallFunction( this, constructor, true );
		thread->DelayedStart( 0 );
	} else {
		thread = NULL;
	}
	scriptObject.ClearObject();
	return thread;
}
void idEntity::DeconstructScriptObject( void ) {
	idThread *thread;
	const function_t *destructor;
	destructor = scriptObject.GetDestructor();
	if ( destructor ) {
		thread = new idThread();
		thread->SetThreadName( name.c_str() );
		thread->CallFunction( this, destructor, true );
		thread->Execute();
		delete thread;
	}
}
void idEntity::Signal( signalNum_t signalnum ) {
	line( "HOST Signal " + num( entityNumber ) + " " + num( signalnum ) );
	std::vector<harnessSignal_t> sigs = signals[ signalnum ];
	signals[ signalnum ].clear();
	for ( size_t i = 0; i < sigs.size(); i++ ) {
		idThread *thread = idThread::GetThread( sigs[ i ].threadnum );
		if ( thread ) {
			thread->CallFunction( sigs[ i ].function, true );
			thread->Execute();
		}
	}
}
void idEntity::SetSignal( signalNum_t signalnum, idThread *thread, const function_t *function ) {
	line( "HOST SetSignal " + num( entityNumber ) + " " + num( signalnum ) + " " + num( thread->GetThreadNum() ) + " " + num( gameLocal.program.GetFunctionIndex( function ) ) );
	harnessSignal_t s; s.threadnum = thread->GetThreadNum(); s.function = function;
	for ( size_t i = 0; i < signals[ signalnum ].size(); i++ ) {
		if ( signals[ signalnum ][ i ].threadnum == s.threadnum && signals[ signalnum ][ i ].function == function ) return;
	}
	signals[ signalnum ].push_back( s );
}
void idEntity::ClearSignalThread( signalNum_t signalnum, idThread *thread ) {
	line( "HOST ClearSignalThread " + num( entityNumber ) + " " + num( signalnum ) + " " + num( thread->GetThreadNum() ) );
	std::vector<harnessSignal_t> &l = signals[ signalnum ];
	for ( size_t i = 0; i < l.size(); ) { if ( l[ i ].threadnum == thread->GetThreadNum() ) l.erase( l.begin() + i ); else i++; }
}
void idEntity::TriggerGuis( void ) { line( "HOST TriggerGuis " + num( entityNumber ) ); }
void idEntity::Event_Activate( idEntity *activator ) { line( evHead( this, EV_Activate ) + " " + entRef( activator ) ); }
void idEntity::Event_SetShaderParm( int parmnum, float v ) { line( evHead( this, EV_SetShaderParm ) + " " + num( parmnum ) + " " + fb( v ) ); }
void idEntity::Event_CacheSoundShader( const char *soundName ) { line( evHead( this, EV_CacheSoundShader ) + " " + q( soundName ) ); }
void idEntity::Event_GetName( void ) { line( evHead( this, EV_GetName ) ); idThread::ReturnString( name ); }
void idEntity::Event_SetName( const char *newname ) {
	line( evHead( this, EV_SetName ) + " " + q( newname ) );
	gameLocal.program.SetEntity( name, NULL );
	name = newname;
	gameLocal.program.SetEntity( name, this );
}
void idEntity::Event_SetValue( float v ) { line( evHead( this, EV_SetValue ) + " " + fb( v ) ); value = v; }
void idEntity::Event_GetValue( void ) { line( evHead( this, EV_GetValue ) ); idThread::ReturnFloat( value ); }
void idEntity::Event_SetOrigin( idVec3 &org ) { line( evHead( this, EV_SetOrigin ) + " " + v3( org ) ); origin = org; }
void idEntity::Event_GetOrigin( void ) { line( evHead( this, EV_GetOrigin ) ); idThread::ReturnVector( origin ); }
void idEntity::Event_SetOwner( idEntity *o ) { line( evHead( this, EV_SetOwner ) + " " + entRef( o ) ); owner = o ? o->entityNumber + 1 : 0; }
void idEntity::Event_GetOwner( void ) { line( evHead( this, EV_GetOwner ) ); idThread::ReturnEntity( owner ? gameLocal.entities[ owner - 1 ] : NULL ); }
void idEntity::Event_Bind( idEntity *master ) { line( evHead( this, EV_Bind ) + " " + entRef( master ) ); }
void idEntity::Event_SetKey( const char *key, const char *v ) { line( evHead( this, EV_SetKey ) + " " + q( key ) + " " + q( v ) ); spawnArgs.Set( key, v ); }
void idEntity::Event_GetKey( const char *key ) { line( evHead( this, EV_GetKey ) + " " + q( key ) ); idThread::ReturnString( spawnArgs.GetString( key, "" ) ); }
void idEntity::Event_AddInts( int a, int b ) { line( evHead( this, EV_AddInts ) + " " + num( a ) + " " + num( b ) ); idThread::ReturnInt( a + b ); }
void idEntity::Event_Mix( float f, int d, idVec3 &v, const char *s, idEntity *e ) {
	line( evHead( this, EV_Mix ) + " " + fb( f ) + " " + num( d ) + " " + v3( v ) + " " + q( s ) + " " + entRef( e ) );
	idThread::ReturnFloat( f + d );
}
void idEntity::Event_HostPing( int v ) {
	if ( v < 0 ) { PostEventMS( &EV_HostPing, 0, v ); return; }
	line( evHead( this, EV_HostPing ) + " " + num( v ) );
}

CLASS_DECLARATION( idEntity, idMover )
	EVENT( EV_MoveTo,				idMover::Event_MoveTo )
	EVENT( EV_MoveDone,				idMover::Event_MoveDone )
	EVENT( EV_IsMoving,				idMover::Event_IsMoving )
	EVENT( EV_Thread_SetCallback,	idMover::Event_SetCallback )
	EVENT( EV_SlowTurn,				idMover::Event_SlowTurn )
END_CLASS
idMover::idMover() { moving = false; move_thread = 0; dest.Zero(); turnLeft = 0; }
void idMover::Event_MoveTo( idVec3 &d, float time ) {
	line( evHead( this, EV_MoveTo ) + " " + v3( d ) + " " + fb( time ) );
	dest = d; moving = true; move_thread = 0;
	PostEventSec( &EV_MoveDone, time );
}
void idMover::Event_MoveDone( void ) {
	line( evHead( this, EV_MoveDone ) );
	moving = false; origin = dest;
	if ( move_thread ) { idThread::ObjectMoveDone( move_thread, this ); move_thread = 0; }
}
void idMover::Event_IsMoving( void ) { line( evHead( this, EV_IsMoving ) ); idThread::ReturnFloat( moving ? 1.0f : 0.0f ); }
void idMover::Event_SetCallback( void ) {
	line( evHead( this, EV_Thread_SetCallback ) );
	if ( moving && !move_thread ) { move_thread = idThread::CurrentThreadNum(); idThread::ReturnInt( true ); }
	else idThread::ReturnInt( false );
}
void idMover::Event_SlowTurn( float frames ) {
	line( evHead( this, EV_SlowTurn ) + " " + fb( frames ) );
	if ( idThread::BeginMultiFrameEvent( this, &EV_SlowTurn ) ) {
		turnLeft = ( int )frames;
		line( "HOST slowTurn begin " + num( turnLeft ) );
	}
	turnLeft--;
	line( "HOST slowTurn tick " + num( turnLeft ) );
	if ( turnLeft <= 0 ) {
		idThread::EndMultiFrameEvent( this, &EV_SlowTurn );
		line( "HOST slowTurn end" );
	}
}

CLASS_DECLARATION( idEntity, idCamera )
END_CLASS
CLASS_DECLARATION( idEntity, idPlayer )
END_CLASS
idPlayer::idPlayer() { viewAngles.Zero(); influenceLevel = 0; }
CLASS_DECLARATION( idEntity, idAFEntity_Base )
END_CLASS

// ---- dumps ----
static bool isProgramDef( const idVarDef *d ) {
	idProgram &p = gameLocal.program;
	return d->num >= 0 && d->num < p.varDefs.Num() && p.varDefs[ d->num ] == d;
}
static std::string defRef( const idVarDef *d ) {
	if ( !d ) return "-";
	if ( isProgramDef( d ) ) return num( d->num );
	return std::string( "@" ) + ( d->TypeDef() ? d->TypeDef()->Name() : "?" );
}
static int funcIndex( const function_t *f ) {
	idProgram &p = gameLocal.program;
	if ( !f ) return -1;
	int i = ( int )( f - &p.functions[ 0 ] );
	return ( i >= 0 && i < p.functions.Num() ) ? i : -2;
}
static std::string defValue( const idVarDef *d ) {
	idProgram &p = gameLocal.program;
	etype_t t = d->Type();
	if ( d->initialized == idVarDef::stackVariable ) return "stack:" + num( d->value.stackOffset );
	if ( t == ev_function ) return "func:" + num( funcIndex( d->value.functionPtr ) );
	if ( t == ev_jumpoffset ) return "jump:" + num( d->value.jumpOffset );
	if ( t == ev_argsize ) return "args:" + num( d->value.argSize );
	if ( t == ev_virtualfunction ) return "virt:" + num( d->value.virtualFunction );
	if ( d->scope && d->scope->TypeDef() && d->scope->TypeDef()->Inherits( &type_object ) ) return "ptr:" + num( d->value.ptrOffset );
	int off = ( int )( d->value.bytePtr - p.variables );
	if ( off < 0 || off > MAX_GLOBALS ) return "?";
	std::string r = "global:" + num( off );
	switch ( t ) {
	case ev_float:	r += "=" + fb( *d->value.floatPtr ); break;
	case ev_vector:	r += "=" + v3( *d->value.vectorPtr ); break;
	case ev_string:	r += "=" + q( d->value.stringPtr ); break;
	case ev_entity: case ev_boolean: case ev_object: case ev_field: case ev_pointer:
		r += "=" + num( *d->value.intPtr ); break;
	default: break;
	}
	return r;
}
static void dumpStatements( int first, int count ) {
	idProgram &p = gameLocal.program;
	for ( int i = first; i < first + count && i < p.statements.Num(); i++ ) {
		statement_t &s = p.statements[ i ];
		line( "STMT " + num( i ) + " " + idCompiler::opcodes[ s.op ].opname + " a=" + defRef( s.a ) + " b=" + defRef( s.b ) + " c=" + defRef( s.c ) +
			" line=" + num( s.linenumber ) + " file=" + num( s.file ) );
	}
}
static void dumpGlobals( void ) {
	idProgram &p = gameLocal.program;
	line( "GLOBALS " + num( p.numVariables ) );
	for ( int o = 0; o < p.numVariables; o += 32 ) {
		int n = p.numVariables - o; if ( n > 32 ) n = 32;
		bool zero = true;
		for ( int i = 0; i < n; i++ ) if ( p.variables[ o + i ] ) zero = false;
		if ( zero ) continue;
		char b[ 16 ]; sprintf( b, "%06X", o );
		line( std::string( "G " ) + b + " " + hex( &p.variables[ o ], n ) );
	}
}
static void dumpProgram( void ) {
	idProgram &p = gameLocal.program;
	int i, j;
	for ( i = 0; i < p.fileList.Num(); i++ ) line( "FILE " + num( i ) + " " + esc( p.fileList[ i ].c_str() ) );
	for ( i = 0; i < p.types.Num(); i++ ) {
		idTypeDef *t = p.types[ i ];
		std::string s = "TYPE " + num( i ) + " name=" + q( t->Name() ) + " etype=" + num( t->Type() ) + " size=" + num( t->Size() ) +
			" aux=" + ( t->auxType ? esc( t->auxType->Name() ) : std::string( "-" ) ) + " def=" + defRef( t->def ) + " parms=[";
		for ( j = 0; j < t->NumParameters(); j++ ) {
			if ( j ) s += ",";
			s += esc( t->GetParmType( j )->Name() ) + ":" + esc( t->GetParmName( j ) );
		}
		s += "] funcs=[";
		for ( j = 0; j < t->NumFunctions(); j++ ) { if ( j ) s += ","; s += num( funcIndex( t->GetFunction( j ) ) ); }
		line( s + "]" );
	}
	for ( i = 0; i < p.varDefs.Num(); i++ ) {
		idVarDef *d = p.varDefs[ i ];
		line( "DEF " + num( d->num ) + " name=" + q( d->Name() ) + " type=" + esc( d->TypeDef()->Name() ) + "/" + num( d->Type() ) +
			" scope=" + defRef( d->scope ) + " init=" + num( d->initialized ) + " users=" + num( d->numUsers ) + " value=" + defValue( d ) );
	}
	for ( i = 0; i < p.functions.Num(); i++ ) {
		function_t &f = p.functions[ i ];
		std::string s = "FUNC " + num( i ) + " name=" + q( f.Name() ) + " event=" + ( f.eventdef ? esc( f.eventdef->GetName() ) : std::string( "-" ) ) +
			" def=" + defRef( f.def ) + " first=" + num( f.firstStatement ) + " num=" + num( f.numStatements ) + " parmTotal=" + num( f.parmTotal ) +
			" locals=" + num( f.locals ) + " filenum=" + num( f.filenum ) + " parmSize=[";
		for ( j = 0; j < f.parmSize.Num(); j++ ) { if ( j ) s += ","; s += num( f.parmSize[ j ] ); }
		line( s + "]" );
	}
	dumpStatements( 0, p.statements.Num() );
	line( "TOP functions=" + num( p.top_functions ) + " statements=" + num( p.top_statements ) + " types=" + num( p.top_types ) +
		" defs=" + num( p.top_defs ) + " files=" + num( p.top_files ) );
	dumpGlobals();
	char b[ 16 ]; sprintf( b, "%08X", ( unsigned int )p.CalculateChecksum() );
	line( std::string( "CHECKSUM " ) + b );
}
static void dumpThreads( bool calls ) {
	idList<idThread *> &l = idThread::GetThreads();
	if ( calls ) {
		line( "CURRENT " + num( idThread::CurrentThreadNum() ) );
		line( "THREADINDEX " + num( idThread::threadIndex ) );
	}
	for ( int i = 0; i < l.Num(); i++ ) {
		idThread *t = l[ i ];
		idInterpreter &in = t->interpreter;
		std::string s = "THREAD " + num( t->threadNum ) + " name=" + q( t->threadName.c_str() ) + " dying=" + num( in.threadDying ) + " done=" + num( in.doneProcessing ) +
			" waitingFor=" + num( t->waitingFor ) + " waitingUntil=" + num( t->waitingUntil ) +
			" waitingForThread=" + num( t->waitingForThread ? t->waitingForThread->threadNum : 0 ) +
			" lastExec=" + num( t->lastExecuteTime ) + " created=" + num( t->creationTime ) + " manual=" + num( t->manualControl ) +
			" depth=" + num( in.callStackDepth ) + " used=" + num( in.localstackUsed ) + " base=" + num( in.localstackBase ) +
			" maxDepth=" + num( in.maxStackDepth ) + " maxUsed=" + num( in.maxLocalstackUsed ) + " ip=" + num( in.instructionPointer ) +
			" func=" + num( funcIndex( in.currentFunction ) ) + " popParms=" + num( in.popParms ) +
			" multiFrame=" + ( in.multiFrameEvent ? esc( in.multiFrameEvent->GetName() ) : std::string( "-" ) ) +
			" eventEntity=" + ( in.eventEntity ? num( in.eventEntity->entityNumber ) : std::string( "-" ) ) +
			" terminateOnExit=" + num( in.terminateOnExit ) + " debug=" + num( in.debug ) + " spawnArgs=[";
		for ( int k = 0; k < t->spawnArgs.GetNumKeyVals(); k++ ) {
			const idKeyValue *kv = t->spawnArgs.GetKeyVal( k );
			if ( k ) s += ",";
			s += esc( kv->GetKey().c_str() ) + "=" + esc( kv->GetValue().c_str() );
		}
		line( s + "]" );
		if ( calls ) {
			for ( int c = 0; c < in.callStackDepth && c < MAX_STACK_DEPTH; c++ ) {
				line( "CALL " + num( c ) + " s=" + num( in.callStack[ c ].s ) + " f=" + num( funcIndex( in.callStack[ c ].f ) ) + " base=" + num( in.callStack[ c ].stackbase ) );
			}
		}
	}
}
extern idLinkList<idEvent> &harnessEventQueue( void );
static int eventCount( void ) { return harnessEventQueue().Num(); }
static void dumpEvents( void ) {
	for ( idEvent *e = harnessEventQueue().Next(); e != NULL; e = e->eventNode.Next() ) {
		std::string o;
		if ( e->object->IsType( idThread::Type ) ) o = "thread:" + num( static_cast<idThread *>( e->object )->GetThreadNum() );
		else o = "ent:" + num( static_cast<idEntity *>( e->object )->entityNumber );
		line( "EVENT time=" + num( e->time ) + " name=" + esc( e->eventdef->GetName() ) + " class=" + e->typeinfo->classname + " object=" + o +
			" args=" + hex( e->data, e->data ? ( int )e->eventdef->GetArgSize() : 0 ) );
	}
}
static void dumpEntities( void ) {
	for ( int i = 0; i < MAX_GENTITIES; i++ ) {
		idEntity *e = gameLocal.entities[ i ];
		if ( !e ) continue;
		line( "ENTITY " + num( i ) + " class=" + e->GetClassname() + " name=" + q( e->name.c_str() ) + " value=" + fb( e->value ) + " origin=" + v3( e->origin ) +
			" owner=" + num( e->owner ) + " object=" + ( e->scriptObject.HasObject() ? esc( e->scriptObject.GetTypeName() ) : std::string( "-" ) ) +
			" data=" + ( e->scriptObject.HasObject() ? hex( e->scriptObject.data, e->scriptObject.GetTypeDef()->Size() ) : std::string( "" ) ) );
	}
}
static void dumpReturn( void ) {
	idProgram &p = gameLocal.program;
	if ( !p.returnDef ) { line( "RETURN -" ); return; }
	unsigned int *w = ( unsigned int * )p.returnDef->value.bytePtr;
	char b[ 64 ]; sprintf( b, "RETURN %08X %08X %08X ", w[ 0 ], w[ 1 ], w[ 2 ] );
	line( b + q( p.returnStringDef->value.stringPtr ) );
}

// ---- save and restore ----
static std::string lastSave;
static void doSave( void ) {
	idSaveGame s;
	gameLocal.program.Save( &s );
	line( "SAVE program " + hex( s.buf.data(), ( int )s.buf.size() ) );
	size_t mark = s.buf.size();
	idList<idThread *> &l = idThread::GetThreads();
	s.WriteInt( l.Num() );
	for ( int i = 0; i < l.Num(); i++ ) {
		size_t start = s.buf.size();
		l[ i ]->Save( &s );
		// the local stack is the block after callStackDepth * 12 + 4 + 4 (maxStackDepth) + 4 (localstackUsed), which
		// follow threadNum, waitingForThread, waitingFor, waitingUntil (16 bytes)
		idInterpreter &in = l[ i ]->interpreter;
		size_t stackAt = start + 16 + 4 + ( size_t )in.callStackDepth * 12 + 4 + 4;
		std::string whole = s.buf.substr( start );
		std::string noStack = s.buf.substr( start, stackAt - start ) + s.buf.substr( stackAt + in.localstackUsed );
		line( "SAVE thread " + num( i ) + " " + hex( noStack.data(), ( int )noStack.size() ) );
		line( "SAVE stack " + num( i ) + " " + hex( s.buf.data() + stackAt, in.localstackUsed ) );
	}
	mark = s.buf.size();
	idEvent::Save( &s );
	line( "SAVE events " + hex( s.buf.data() + mark, ( int )( s.buf.size() - mark ) ) );
	mark = s.buf.size();
	for ( int i = 0; i < MAX_GENTITIES; i++ ) {
		if ( gameLocal.entities[ i ] ) { s.WriteInt( i ); gameLocal.entities[ i ]->scriptObject.Save( &s ); }
	}
	s.WriteInt( -1 );
	line( "SAVE objects " + hex( s.buf.data() + mark, ( int )( s.buf.size() - mark ) ) );
	lastSave = s.buf;
}
static void doRestore( void ) {
	idRestoreGame r;
	r.buf = lastSave;
	gameLocal.program.Restart();
	idEvent::ClearEventList();
	bool ok = gameLocal.program.Restore( &r );
	line( "RESTORE program " + num( ok ) );
	int n, i;
	r.ReadInt( n );
	for ( i = 0; i < n; i++ ) new idThread();
	for ( i = 0; i < n; i++ ) idThread::GetThreads()[ i ]->Restore( &r );
	idEvent::Restore( &r );
	for ( ;; ) {
		r.ReadInt( i );
		if ( i < 0 ) break;
		if ( i >= MAX_GENTITIES || !gameLocal.entities[ i ] ) throwError( "harness: entity of the save is missing" );
		gameLocal.entities[ i ]->scriptObject.Restore( &r );
	}
}

// ---- scenario ----
static std::vector<std::string> split( const std::string &s ) {
	std::vector<std::string> r;
	size_t i = 0;
	while ( i < s.size() ) {
		while ( i < s.size() && ( s[ i ] == ' ' || s[ i ] == '\t' ) ) i++;
		if ( i >= s.size() ) break;
		std::string t;
		if ( s[ i ] == '"' ) {
			i++;
			while ( i < s.size() && s[ i ] != '"' ) {
				if ( s[ i ] == '\\' && i + 1 < s.size() ) {
					i++;
					if ( s[ i ] == 'n' ) t += '\n'; else if ( s[ i ] == 't' ) t += '\t'; else t += s[ i ];
					i++;
				} else t += s[ i++ ];
			}
			i++;
		} else {
			while ( i < s.size() && s[ i ] != ' ' && s[ i ] != '\t' ) t += s[ i++ ];
		}
		r.push_back( t );
	}
	return r;
}
static bool allDigits( const std::string &s ) {
	if ( s.empty() ) return false;
	for ( size_t i = 0; i < s.size(); i++ ) if ( !isdigit( ( unsigned char )s[ i ] ) ) return false;
	return true;
}
static idEntity *entArg( const std::string &s ) {
	if ( s == "null" ) return NULL;
	int n = atoi( s.c_str() );
	if ( n < 0 || n >= MAX_GENTITIES || !gameLocal.entities[ n ] ) throwError( "harness: no such entity" );
	return gameLocal.entities[ n ];
}
static idThread *threadArg( const std::string &s ) {
	idThread *t = idThread::GetThread( atoi( s.c_str() ) );
	if ( !t ) throwError( "harness: no such thread" );
	return t;
}
static etype_t typeArg( const std::string &s ) {
	if ( s == "float" ) return ev_float; if ( s == "vector" ) return ev_vector; if ( s == "string" ) return ev_string;
	if ( s == "boolean" ) return ev_boolean; if ( s == "entity" ) return ev_entity; if ( s == "object" ) return ev_object;
	throwError( "harness: unknown type" ); return ev_void;
}
// the arguments of an event sent by the host; vectors and strings live until the end of the command
static std::vector<idVec3 *> argVecs;
static std::vector<std::string *> argStrs;
static void buildArgs( const idEventDef *ev, const std::vector<std::string> &a, size_t first, idEventArg *args ) {
	const char *format = ev->GetArgFormat();
	int n = ev->GetNumArgs();
	if ( ( int )( a.size() - first ) != n ) throwError( "harness: wrong number of event arguments" );
	for ( int i = 0; i < n; i++ ) {
		const std::string &s = a[ first + i ];
		switch ( format[ i ] ) {
		case D_EVENT_FLOAT:		args[ i ] = idEventArg( ( float )atof( s.c_str() ) ); break;
		case D_EVENT_INTEGER:	args[ i ] = idEventArg( atoi( s.c_str() ) ); break;
		case D_EVENT_STRING:	argStrs.push_back( new std::string( s ) ); args[ i ] = idEventArg( argStrs.back()->c_str() ); break;
		case D_EVENT_VECTOR: {
			idVec3 *v = new idVec3; float x = 0, y = 0, z = 0;
			sscanf( s.c_str(), "%f %f %f", &x, &y, &z ); v->Set( x, y, z );
			argVecs.push_back( v ); args[ i ] = idEventArg( *v ); break;
		}
		case D_EVENT_ENTITY: case D_EVENT_ENTITY_NULL:
			args[ i ] = idEventArg( ( const idEntity * )entArg( s ) ); break;
		default: throwError( "harness: event argument type not supported" );
		}
	}
}
static void freeArgs( void ) {
	for ( size_t i = 0; i < argVecs.size(); i++ ) delete argVecs[ i ];
	for ( size_t i = 0; i < argStrs.size(); i++ ) delete argStrs[ i ];
	argVecs.clear(); argStrs.clear();
}
static bool sendEvent( idEntity *e, const idEventDef *ev, idEventArg *a, bool post, int ms ) {
	switch ( ev->GetNumArgs() ) {
	case 0: return post ? e->PostEventMS( ev, ms ) : e->ProcessEvent( ev );
	case 1: return post ? e->PostEventMS( ev, ms, a[ 0 ] ) : e->ProcessEvent( ev, a[ 0 ] );
	case 2: return post ? e->PostEventMS( ev, ms, a[ 0 ], a[ 1 ] ) : e->ProcessEvent( ev, a[ 0 ], a[ 1 ] );
	case 3: return post ? e->PostEventMS( ev, ms, a[ 0 ], a[ 1 ], a[ 2 ] ) : e->ProcessEvent( ev, a[ 0 ], a[ 1 ], a[ 2 ] );
	case 4: return post ? e->PostEventMS( ev, ms, a[ 0 ], a[ 1 ], a[ 2 ], a[ 3 ] ) : e->ProcessEvent( ev, a[ 0 ], a[ 1 ], a[ 2 ], a[ 3 ] );
	case 5: return post ? e->PostEventMS( ev, ms, a[ 0 ], a[ 1 ], a[ 2 ], a[ 3 ], a[ 4 ] ) : e->ProcessEvent( ev, a[ 0 ], a[ 1 ], a[ 2 ], a[ 3 ], a[ 4 ] );
	default: throwError( "harness: too many event arguments" ); return false;
	}
}

static void run( const std::vector<std::string> &a, const std::string &text ) {
	idProgram &p = gameLocal.program;
	const std::string &c = a[ 0 ];
	#define NEED( n ) if ( ( int )a.size() < ( n ) + 1 ) throwError( "harness: missing arguments" )
	if ( c == "startup" ) { NEED( 1 ); p.Startup( a[ 1 ] == "-" ? "" : a[ 1 ].c_str() ); }
	else if ( c == "begin" ) p.BeginCompilation();
	else if ( c == "finish" ) p.FinishCompilation();
	else if ( c == "restart" ) p.Restart();
	else if ( c == "compilefile" ) { NEED( 1 ); p.CompileFile( a[ 1 ].c_str() ); }
	else if ( c == "compiletext" ) { NEED( 2 ); bool r = p.CompileText( a[ 1 ].c_str(), text.c_str(), atoi( a[ 2 ].c_str() ) != 0 ); line( "RESULT " + num( r ) ); }
	else if ( c == "compilefunction" ) { NEED( 1 ); const function_t *f = p.CompileFunction( a[ 1 ].c_str(), text.c_str() ); line( "FUNCTION " + num( funcIndex( f ) ) ); }
	else if ( c == "genfile" ) {
		NEED( 2 );
		std::string r; int n = atoi( a[ 2 ].c_str() );
		for ( int i = 0; i < n; i++ ) {
			std::string idx = num( i );
			for ( size_t k = 0; k < text.size(); k++ ) { if ( text[ k ] == '@' ) r += idx; else r += text[ k ]; }
		}
		memFiles[ a[ 1 ] ] = r;
	}
	else if ( c == "dump" ) {
		NEED( 1 );
		if ( a[ 1 ] == "program" ) dumpProgram();
		else if ( a[ 1 ] == "statements" ) { NEED( 3 ); dumpStatements( atoi( a[ 2 ].c_str() ), atoi( a[ 3 ].c_str() ) ); }
		else if ( a[ 1 ] == "globals" ) dumpGlobals();
		else if ( a[ 1 ] == "disasm" ) p.Disassemble();
		else if ( a[ 1 ] == "threads" ) dumpThreads( true );
		else if ( a[ 1 ] == "stacks" ) {
			idList<idThread *> &l = idThread::GetThreads();
			for ( int i = 0; i < l.Num(); i++ ) line( "STACK " + num( l[ i ]->threadNum ) + " " + hex( l[ i ]->interpreter.localstack, l[ i ]->interpreter.localstackUsed ) );
		}
		else if ( a[ 1 ] == "events" ) dumpEvents();
		else if ( a[ 1 ] == "entities" ) dumpEntities();
		else if ( a[ 1 ] == "return" ) dumpReturn();
		else throwError( "harness: unknown dump" );
	}
	else if ( c == "spawn" ) {
		NEED( 3 );
		int n = atoi( a[ 1 ].c_str() );
		if ( n < 0 || n >= ENTITYNUM_WORLD || gameLocal.entities[ n ] ) throwError( "harness: bad entity slot" );
		idDict args;
		for ( size_t i = 4; i + 1 < a.size(); i += 2 ) args.Set( a[ i ].c_str(), a[ i + 1 ].c_str() );
		if ( !makeEntity( n, a[ 2 ].c_str(), a[ 3 ].c_str(), args ) ) throwError( "harness: unknown entity class" );
	}
	else if ( c == "setobject" ) {
		NEED( 2 );
		idEntity *e = entArg( a[ 1 ] );
		bool ok = e->scriptObject.SetType( a[ 2 ].c_str() );
		line( "SETTYPE " + num( ok ) );
		if ( ok ) e->ConstructScriptObject();
	}
	else if ( c == "remove" ) { NEED( 1 ); delete entArg( a[ 1 ] ); }
	else if ( c == "thread" ) {
		NEED( 1 );
		const function_t *f = p.FindFunction( a[ 1 ].c_str() );
		if ( !f ) throwError( "harness: function not found" );
		idThread *t = new idThread( f );
		t->DelayedStart( 0 );
		line( "THREADNUM " + num( t->GetThreadNum() ) );
	}
	else if ( c == "objthread" ) {
		NEED( 2 );
		idEntity *e = entArg( a[ 1 ] );
		const function_t *f = e->scriptObject.GetFunction( a[ 2 ].c_str() );
		if ( !f ) throwError( "harness: function not found" );
		idThread *t = new idThread();
		t->SetThreadName( e->name.c_str() );
		t->CallFunction( e, f, true );
		t->DelayedStart( 0 );
		line( "THREADNUM " + num( t->GetThreadNum() ) );
	}
	else if ( c == "callnow" ) {
		NEED( 1 );
		const function_t *f = p.FindFunction( a[ 1 ].c_str() );
		if ( !f ) throwError( "harness: function not found" );
		idThread *t = new idThread( f );
		bool done = t->Start();
		line( "DONE " + num( done ) );
		dumpReturn();
	}
	else if ( c == "frame" ) {
		int n = a.size() > 1 ? atoi( a[ 1 ].c_str() ) : 1;
		for ( int i = 0; i < n; i++ ) {
			gameLocal.time += gameLocal.msec;
			gameLocal.realClientTime = gameLocal.time;
			gameLocal.framenum++;
			idEvent::ServiceEvents();
			line( "FRAME time=" + num( gameLocal.time ) + " framenum=" + num( gameLocal.framenum ) + " events=" + num( eventCount() ) );
			dumpThreads( false );
		}
	}
	else if ( c == "displayinfo" ) { NEED( 1 ); threadArg( a[ 1 ] )->DisplayInfo(); }
	else if ( c == "listthreads" ) { idCmdArgs args; idThread::ListThreads_f( args ); }
	else if ( c == "getvar" ) {
		NEED( 2 );
		idStr o;
		bool ok = threadArg( a[ 1 ] )->interpreter.GetRegisterValue( a[ 2 ].c_str(), o, a.size() > 3 ? atoi( a[ 3 ].c_str() ) : -1 );
		line( "GETVAR " + num( ok ) + " " + esc( o.c_str() ) );
	}
	else if ( c == "setcvar" ) { NEED( 2 ); findCVar( a[ 1 ].c_str(), true )->SetString( a[ 2 ].c_str() ); }
	else if ( c == "set" ) {
		NEED( 2 );
		int v = atoi( a[ 2 ].c_str() );
		if ( a[ 1 ] == "isClient" ) gameLocal.isClient = v != 0;
		else if ( a[ 1 ] == "isMultiplayer" ) gameLocal.isMultiplayer = v != 0;
		else if ( a[ 1 ] == "influence" ) { if ( !gameLocal.localPlayer ) throwError( "harness: no player" ); gameLocal.localPlayer->influenceLevel = v; }
		else if ( a[ 1 ] == "time" ) { gameLocal.time = v; gameLocal.realClientTime = v; }
		else if ( a[ 1 ] == "msec" ) gameLocal.msec = v;
		else throwError( "harness: unknown set" );
	}
	else if ( c == "settrace" ) { NEED( 3 ); traceFraction = ( float )atof( a[ 1 ].c_str() ); traceEntity = atoi( a[ 2 ].c_str() ); traceId = atoi( a[ 3 ].c_str() ); }
	else if ( c == "event" || c == "postevent" ) {
		bool post = ( c == "postevent" );
		NEED( post ? 3 : 2 );
		idEntity *e = entArg( a[ 1 ] );
		size_t at = post ? 3 : 2;
		const idEventDef *ev = idEventDef::FindEvent( a[ at ].c_str() );
		if ( !ev ) throwError( "harness: unknown event" );
		idEventArg args[ D_EVENT_MAXARGS ];
		buildArgs( ev, a, at + 1, args );
		bool r;
		try { r = sendEvent( e, ev, args, post, post ? atoi( a[ 2 ].c_str() ) : 0 ); } catch ( ... ) { freeArgs(); throw; }
		freeArgs();
		line( std::string( post ? "POSTED " : "PROCESSED " ) + num( r ) );
	}
	else if ( c == "signal" ) { NEED( 2 ); entArg( a[ 1 ] )->Signal( ( signalNum_t )atoi( a[ 2 ].c_str() ) ); }
	else if ( c == "movedone" ) { NEED( 2 ); idThread::ObjectMoveDone( atoi( a[ 1 ].c_str() ), entArg( a[ 2 ] ) ); }
	else if ( c == "killthread" ) { NEED( 1 ); if ( allDigits( a[ 1 ] ) ) idThread::KillThread( atoi( a[ 1 ].c_str() ) ); else idThread::KillThread( a[ 1 ].c_str() ); }
	else if ( c == "endthread" ) { NEED( 1 ); threadArg( a[ 1 ] )->End(); }
	else if ( c == "debuginfo" ) { NEED( 2 ); if ( atoi( a[ 2 ].c_str() ) ) threadArg( a[ 1 ] )->EnableDebugInfo(); else threadArg( a[ 1 ] )->DisableDebugInfo(); }
	else if ( c == "save" ) doSave();
	else if ( c == "restore" ) doRestore();
	else if ( c == "findfunction" ) { NEED( 1 ); line( "FUNCTION " + num( funcIndex( p.FindFunction( a[ 1 ].c_str() ) ) ) ); }
	else if ( c == "scriptvar" ) {
		NEED( 3 );
		idEntity *e = entArg( a[ 1 ] );
		etype_t t = typeArg( a[ 3 ] );
		byte *d = e->scriptObject.GetVariable( a[ 2 ].c_str(), t );
		if ( !d ) { line( "SCRIPTVAR -1" ); return; }
		std::string v;
		switch ( t ) {
		case ev_float:	v = fb( *( float * )d ); break;
		case ev_vector:	v = v3( *( idVec3 * )d ); break;
		case ev_string:	v = q( ( const char * )d ); break;
		default:		v = num( *( int * )d ); break;
		}
		line( "SCRIPTVAR " + num( ( int )( d - e->scriptObject.data ) ) + " " + v );
	}
	else throwError( "harness: unknown command" );
}

int main( int argc, char **argv ) {
	if ( argc < 4 ) { fprintf( stderr, "usage: harness <root> <scenario> <golden>\n" ); return 2; }
	fsRoot = argv[ 1 ];
	out = fopen( argv[ 3 ], "wb" );
	if ( !out ) { fprintf( stderr, "cannot write %s\n", argv[ 3 ] ); return 2; }
	std::ifstream in( argv[ 2 ], std::ios::binary );
	if ( !in ) { fprintf( stderr, "cannot read %s\n", argv[ 2 ] ); return 2; }
	std::vector<std::string> lines; std::string ln;
	while ( std::getline( in, ln ) ) { if ( !ln.empty() && ln[ ln.size() - 1 ] == '\r' ) ln.erase( ln.size() - 1 ); lines.push_back( ln ); }

	// HARNESS_TRACE=1 echoes every command on stderr (to find the command that crashes the original)
	bool trace = getenv( "HARNESS_TRACE" ) != NULL;
	idMath::Init();
	idDict::Init();
	quiet = true;
	idEvent::Init();
	idClass::Init();
	quiet = false;
	gameLocal.random.SetSeed( 0 );

	for ( size_t i = 0; i < lines.size(); i++ ) {
		std::string l = lines[ i ];
		size_t s = l.find_first_not_of( " \t" );
		if ( s == std::string::npos || l[ s ] == '#' ) continue;
		std::vector<std::string> a = split( l );
		std::string text;
		if ( !a.empty() && a.back() == "<<EOF" ) {
			a.pop_back();
			for ( i++; i < lines.size() && lines[ i ] != "EOF"; i++ ) { text += lines[ i ]; text += "\n"; }
		}
		line( "CMD " + l );
		if ( trace ) { fprintf( stderr, "%s\n", l.c_str() ); fflush( out ); }
		try {
			run( a, text );
		} catch ( harnessError &e ) {
			line( "ERROR " + esc( e.text ) );
		}
		flushPending();
	}
	flushPending();
	fclose( out );
	// no orderly shutdown: the statics of the game are not destroyed
	fflush( NULL );
	_exit( 0 );
}
