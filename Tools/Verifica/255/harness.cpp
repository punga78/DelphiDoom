// Issue #255 (Doom 3, idCommon and the event loop): driver of the parity harness. Written for this repository. It is
// linked with the REAL framework\EventLoop.cpp and idlib of Doom 3 and with the REAL bodies of the functions of
// framework\Common.cpp that Build-Harness.ps1 extracts from the source (common_extract.inc), against fakes of the
// engine (precompiled.h) that trace every call.
//
// Usage: harness.exe <scenario.scn> <golden.txt>
//
// SCENARIO: one command per line; empty lines and lines that start with '#' are skipped. The text commands take the
// rest of the line as text, with the escapes \n \t \r \" \\ and \xHH; the other commands take words separated by
// blanks. Every command is echoed as "CMD <line>". An idException ends the command and prints "THROW <text>"; a
// Sys_Quit or Sys_Error (which never return in the engine) ends the command and prints "EXIT quit" or "EXIT error".
//
//   cvars <0|1>  files <0|1>  opengl <0|1>   the fakes: cvarSystem->IsInitialized, fileSystem->IsInitialized,
//                                            renderSystem->IsOpenGLRunning
//   cvar <name> <value>                      cvarSystem->SetCVarString (developer, com_timestampPrints, logFile,
//                                            logFileName, fs_copyfiles, r_fullscreen, com_journal...)
//   openfail <0|1>                           fileSystem->OpenFileWrite answers NULL
//   time <ms>                                Sys_Milliseconds
//   editors <mask>                           com_editors
//   printf|dprintf|warning|dwarning <text>   idCommon::Printf ("%s" with the text), DPrintf, Warning, DWarning
//   printwarnings | clearwarnings <text> | dumpwarnings
//   error|fatal <text>                       idCommon::Error | FatalError
//   redirect <size> | endredirect | refresh <0|1> | closelog
//   cmdline <words>   safemode   toolmode   startup <name|*> <once 0|1>   addstartup   lines
//   evinit | evshutdown | evsys <type> <v> <v2> [text] (the system queue) | evpush <type> <v> <v2> [text]
//   evget | evrun <0|1> | evms | evlevel | evqueue
//   state | warnlist
//
// GOLDEN: ASCII, one fact per line; the text is escaped like in the scenarios. Lines of the fakes:
//   CON/SYS <text>            console->Print, Sys_Printf
//   OPENW <name> <base> ok|fail, OPENR <name> ok|fail, CLOSE <name>
//   FW <name> <text>          a text written; FWB <name> <hex> for the .dat files (the 4 bytes of the pointer of a
//                             20 byte event are masked)
//   FLUSH/FFLUSH <name>       Flush, ForceFlush
//   SESSION stop|update|pacifier|event <t> <v> <v2> <len>
//   BUFTEXT now|insert|append <text>, BUFARGS now|append <words joined by |>, BUFEXEC
//   CVARSET <name> <text>, CVARSETB <name> 0|1, CLIP <text>, FATALERR <text>, SHUTDOWN, SYSERR <text>
//   KEY <key> 0|1, REDIRECT <text> (the flush of a redirection), GETEV <t> <v> <v2> <len>
// and of the driver: RET <n>, EV <t> <v> <v2> <len> [<text>], LINE <i> <words joined by |>, STATE ..., W/E <i> <text>.
#include "../idlib/precompiled.h"
#pragma hdrstop
#include "../framework/EventLoop.h"

static FILE *g_golden;
static std::string esc( const std::string &s ) {
	std::string r;
	for ( size_t i = 0; i < s.size(); i++ ) {
		unsigned char c = (unsigned char)s[i];
		if ( c == '\\' ) r += "\\\\";
		else if ( c == '\n' ) r += "\\n";
		else if ( c == '\r' ) r += "\\r";
		else if ( c == '\t' ) r += "\\t";
		else if ( c == '"' ) r += "\\\"";
		else if ( c < 32 || c > 126 ) { char t[8]; sprintf( t, "\\x%02X", c ); r += t; }
		else r += (char)c;
	}
	return r;
}
static std::string unesc( const std::string &s ) {
	std::string r;
	for ( size_t i = 0; i < s.size(); i++ ) {
		if ( s[i] != '\\' || i + 1 >= s.size() ) { r += s[i]; continue; }
		char c = s[++i];
		if ( c == 'n' ) r += '\n';
		else if ( c == 't' ) r += '\t';
		else if ( c == 'r' ) r += '\r';
		else if ( c == '"' ) r += '"';
		else if ( c == '\\' ) r += '\\';
		else if ( c == 'x' && i + 2 < s.size() + 0 ) { r += (char)strtol( s.substr( i + 1, 2 ).c_str(), 0, 16 ); i += 2; }
		else { r += '\\'; r += c; }
	}
	return r;
}
static void out( const char *fmt, ... ) {
	char buf[16384]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( buf, sizeof( buf ), fmt, ap ); va_end( ap );
	fputs( buf, g_golden ); fputc( '\n', g_golden );
}
static void outs( const char *tag, const std::string &text ) { fprintf( g_golden, "%s %s\n", tag, esc( text ).c_str() ); }

// ---------------------------------------------------------------- the fakes
struct harnessExit { const char *why; };
static bool g_cvarsInit = true, g_filesInit = true, g_opengl = false, g_openFail = false;
static int g_time = 0;
int com_editors = 0;
static std::map<std::string, idCVar *> &registry() { static std::map<std::string, idCVar *> r; return r; }
static std::map<std::string, std::string> g_vars;
static std::map<std::string, std::string> g_files;
static std::vector<sysEvent_t> g_sysq;

idCVar::idCVar( const char *name, const char *value, int flags, const char *description, float valueMin, float valueMax, argCompletion_t valueCompletion ) {
	n = name; v = value; registry()[name] = this;
}
bool idCVarSystem::IsInitialized() const { return g_cvarsInit; }
const char *idCVarSystem::GetCVarString( const char *name ) const {
	std::map<std::string, idCVar *>::iterator i = registry().find( name );
	if ( i != registry().end() ) return i->second->GetString();
	return g_vars[name].c_str();
}
int idCVarSystem::GetCVarInteger( const char *name ) const { return atoi( GetCVarString( name ) ); }
bool idCVarSystem::GetCVarBool( const char *name ) const { return atoi( GetCVarString( name ) ) != 0; }
void idCVarSystem::SetCVarString( const char *name, const char *value, int flags ) {
	outs( "CVARSET", std::string( name ) + " " + value );
	std::map<std::string, idCVar *>::iterator i = registry().find( name );
	if ( i != registry().end() ) i->second->SetString( value ); else g_vars[name] = value;
}
void idCVarSystem::SetCVarBool( const char *name, const bool value, int flags ) {
	out( "CVARSETB %s %d", name, value ? 1 : 0 );
	std::map<std::string, idCVar *>::iterator i = registry().find( name );
	if ( i != registry().end() ) i->second->SetBool( value ); else g_vars[name] = value ? "1" : "0";
}
static idCVarSystem cvarSystemLocal;
idCVarSystem *cvarSystem = &cvarSystemLocal;

static const char *execName( cmdExecution_t e ) { return e == CMD_EXEC_NOW ? "now" : e == CMD_EXEC_INSERT ? "insert" : "append"; }
void idCmdSystemFake::BufferCommandText( cmdExecution_t exec, const char *text ) { outs( ( std::string( "BUFTEXT " ) + execName( exec ) ).c_str(), text ); }
void idCmdSystemFake::BufferCommandArgs( cmdExecution_t exec, const idCmdArgs &args ) {
	std::string s;
	for ( int i = 0; i < args.Argc(); i++ ) { if ( i ) s += "|"; s += args.Argv( i ); }
	outs( ( std::string( "BUFARGS " ) + execName( exec ) ).c_str(), s );
}
void idCmdSystemFake::ExecuteCommandBuffer() { out( "BUFEXEC" ); }
static idCmdSystemFake cmdSystemLocal;
idCmdSystemFake *cmdSystem = &cmdSystemLocal;

void idConsoleFake::Print( const char *text ) { outs( "CON", text ); }
static idConsoleFake consoleLocal; idConsoleFake *console = &consoleLocal;
void idSessionFake::Stop() { out( "SESSION stop" ); }
void idSessionFake::UpdateScreen() { out( "SESSION update" ); }
void idSessionFake::PacifierUpdate() { out( "SESSION pacifier" ); }
void idSessionFake::ProcessEvent( sysEvent_t *e ) { out( "SESSION event %d %d %d %d", e->evType, e->evValue, e->evValue2, e->evPtrLength ); }
static idSessionFake sessionLocal; idSessionFake *session = &sessionLocal;
bool idRenderSystemFake::IsOpenGLRunning() const { return g_opengl; }
static idRenderSystemFake renderLocal; idRenderSystemFake *renderSystem = &renderLocal;
void idKeyInput::PreliminaryKeyEvent( int key, bool down ) { out( "KEY %d %d", key, down ? 1 : 0 ); }

static bool isDat( const std::string &n ) { return n.size() > 4 && n.substr( n.size() - 4 ) == ".dat"; }
int idFile::Write( const void *buffer, int len ) {
	std::string chunk( (const char *)buffer, len );
	g_files[name] += chunk;
	if ( isDat( name ) ) {
		std::string h;
		for ( int i = 0; i < len; i++ ) { char t[4]; unsigned char c = (unsigned char)chunk[i]; if ( len == 20 && i >= 16 ) c = 0; sprintf( t, "%02X", c ); h += t; }
		out( "FWB %s %s", name.c_str(), h.c_str() );
	} else outs( ( std::string( "FW " ) + name ).c_str(), chunk );
	return len;
}
int idFile::Read( void *buffer, int len ) {
	if ( pos + len > data.size() ) len = (int)( data.size() - pos );
	memcpy( buffer, data.data() + pos, len ); pos += len; return len;
}
void idFile::Flush() { out( "FLUSH %s", name.c_str() ); }
void idFile::ForceFlush() { out( "FFLUSH %s", name.c_str() ); }
int idFile::Printf( const char *fmt, ... ) {
	char buf[4096]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( buf, sizeof( buf ), fmt, ap ); va_end( ap );
	return Write( buf, (int)strlen( buf ) );
}
bool idFileSystem::IsInitialized() const { return g_filesInit; }
idFile *idFileSystem::OpenFileWrite( const char *relativePath, const char *basePath ) {
	if ( g_openFail ) { out( "OPENW %s %s fail", relativePath, basePath ); return NULL; }
	out( "OPENW %s %s ok", relativePath, basePath );
	idFile *f = new idFile; f->name = relativePath; f->writing = true; g_files[relativePath] = ""; return f;
}
idFile *idFileSystem::OpenFileRead( const char *relativePath ) {
	if ( !g_files.count( relativePath ) ) { out( "OPENR %s fail", relativePath ); return NULL; }
	out( "OPENR %s ok", relativePath );
	idFile *f = new idFile; f->name = relativePath; f->data = g_files[relativePath]; return f;
}
void idFileSystem::CloseFile( idFile *f ) { out( "CLOSE %s", f->name.c_str() ); delete f; }
static idFileSystem fileSystemLocal; idFileSystem *fileSystem = &fileSystemLocal;

sysEvent_t Sys_GetEvent( void ) {
	sysEvent_t e;
	if ( g_sysq.empty() ) { memset( &e, 0, sizeof( e ) ); e.evType = SE_NONE; }
	else { e = g_sysq.front(); g_sysq.erase( g_sysq.begin() ); }
	out( "GETEV %d %d %d %d", e.evType, e.evValue, e.evValue2, e.evPtrLength );
	return e;
}
int Sys_Milliseconds( void ) { return g_time; }
void Sys_Printf( const char *fmt, ... ) { char buf[16384]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( buf, sizeof( buf ), fmt, ap ); va_end( ap ); outs( "SYS", buf ); }
void Sys_SetClipboardData( const char *string ) { outs( "CLIP", string ); }
void Sys_SetFatalError( const char *error ) { outs( "FATALERR", error ); }
void Sys_Quit( void ) { out( "SYSQUIT" ); harnessExit x = { "quit" }; throw x; }
void Sys_Error( const char *error, ... ) { char buf[16384]; va_list ap; va_start( ap, error ); idStr::vsnPrintf( buf, sizeof( buf ), error, ap ); va_end( ap ); outs( "SYSERR", buf ); harnessExit x = { "error" }; throw x; }
idSys *idLib::sys = 0; idCommon *idLib::common = 0; idFileSystem *idLib::fileSystem = 0; idCVarSystem *idLib::cvarSystem = 0;
void idLib::Error( const char *fmt, ... ) {} void idLib::Warning( const char *fmt, ... ) {}
idSys *sys = 0; idCommon *common = 0;
#include "math/Simd_Generic.h"
static idSIMD_Generic simdGeneric;
idSIMDProcessor *SIMDProcessor = &simdGeneric;

// ---------------------------------------------------------------- idCommonLocal: the members of the real class
#include "common_defs.inc"
#define asctime(x) harness_asctime(x)
static const char *harness_asctime( void * ) { return "Thu Jan 01 00:00:00 1970\n"; }
#include "common_local.h"
#include "common_extract.inc"
idCommonLocal::idCommonLocal() {
	com_fullyInitialized = false; com_refreshOnPrint = false; com_errorEntered = 0; com_shuttingDown = false;
	logFile = NULL; strcpy( errorMessage, "" ); rd_buffer = NULL; rd_buffersize = 0; rd_flush = NULL;
}
static idCommonLocal commonLocal;

// ---------------------------------------------------------------- the driver
static void redirectFlush( const char *buffer ) { outs( "REDIRECT", buffer ); }
static char g_redirect[65536];
static std::vector<std::string> words( const std::string &s ) {
	std::vector<std::string> w; size_t i = 0;
	while ( i < s.size() ) { while ( i < s.size() && s[i] == ' ' ) i++; size_t j = i; while ( j < s.size() && s[j] != ' ' ) j++; if ( j > i ) w.push_back( s.substr( i, j - i ) ); i = j; }
	return w;
}
static std::string tail( const std::string &s, int n ) {
	size_t i = 0;
	for ( int k = 0; k < n; k++ ) { while ( i < s.size() && s[i] == ' ' ) i++; while ( i < s.size() && s[i] != ' ' ) i++; }
	if ( i < s.size() ) i++;
	return i < s.size() ? s.substr( i ) : "";
}
static sysEvent_t makeEvent( const std::vector<std::string> &w, const std::string &rest ) {
	sysEvent_t e; memset( &e, 0, sizeof( e ) );
	e.evType = (sysEventType_t)atoi( w[0].c_str() ); e.evValue = atoi( w[1].c_str() ); e.evValue2 = atoi( w[2].c_str() );
	if ( !rest.empty() ) { std::string t = unesc( rest ); e.evPtrLength = (int)t.size() + 1; e.evPtr = Mem_ClearedAlloc( e.evPtrLength ); memcpy( e.evPtr, t.c_str(), t.size() ); }
	return e;
}
static void runCommand( const std::string &cmd, const std::string &rest ) {
	std::vector<std::string> w = words( rest );
	std::string text = unesc( rest );
	if ( cmd == "rep" ) {
		int n = atoi( w[0].c_str() ); std::string one = tail( rest, 2 ), all;
		for ( int i = 0; i < n; i++ ) all += one;
		runCommand( w[1], all );
	}
	else if ( cmd == "warnmany" ) { int n = atoi( w[0].c_str() ); for ( int i = 0; i < n; i++ ) commonLocal.Warning( "warning number %d", i ); }
	else if ( cmd == "pushmany" ) { int n = atoi( w[0].c_str() ); for ( int i = 0; i < n; i++ ) { sysEvent_t e; memset( &e, 0, sizeof( e ) ); e.evType = SE_KEY; e.evValue = i; e.evValue2 = 1; eventLoop->PushEvent( &e ); } }
	else if ( cmd == "cvars" ) g_cvarsInit = atoi( w[0].c_str() ) != 0;
	else if ( cmd == "files" ) g_filesInit = atoi( w[0].c_str() ) != 0;
	else if ( cmd == "opengl" ) g_opengl = atoi( w[0].c_str() ) != 0;
	else if ( cmd == "cvar" ) cvarSystem->SetCVarString( w[0].c_str(), w.size() > 1 ? w[1].c_str() : "" );
	else if ( cmd == "openfail" ) g_openFail = atoi( w[0].c_str() ) != 0;
	else if ( cmd == "time" ) g_time = atoi( w[0].c_str() );
	else if ( cmd == "editors" ) com_editors = atoi( w[0].c_str() );
	else if ( cmd == "printf" ) commonLocal.Printf( "%s", text.c_str() );
	else if ( cmd == "dprintf" ) commonLocal.DPrintf( "%s", text.c_str() );
	else if ( cmd == "warning" ) commonLocal.Warning( "%s", text.c_str() );
	else if ( cmd == "dwarning" ) commonLocal.DWarning( "%s", text.c_str() );
	else if ( cmd == "printwarnings" ) commonLocal.PrintWarnings();
	else if ( cmd == "clearwarnings" ) commonLocal.ClearWarnings( text.c_str() );
	else if ( cmd == "dumpwarnings" ) commonLocal.DumpWarnings();
	else if ( cmd == "error" ) commonLocal.Error( "%s", text.c_str() );
	else if ( cmd == "fatal" ) commonLocal.FatalError( "%s", text.c_str() );
	else if ( cmd == "redirect" ) commonLocal.BeginRedirect( g_redirect, atoi( w[0].c_str() ), redirectFlush );
	else if ( cmd == "endredirect" ) commonLocal.EndRedirect();
	else if ( cmd == "refresh" ) commonLocal.SetRefreshOnPrint( atoi( w[0].c_str() ) != 0 );
	else if ( cmd == "closelog" ) commonLocal.CloseLogFile();
	else if ( cmd == "cmdline" ) {
		std::vector<const char *> argv; for ( size_t i = 0; i < w.size(); i++ ) argv.push_back( w[i].c_str() );
		commonLocal.ParseCommandLine( (int)argv.size(), argv.empty() ? NULL : &argv[0] );
	}
	else if ( cmd == "safemode" ) out( "RET %d", commonLocal.SafeMode() ? 1 : 0 );
	else if ( cmd == "toolmode" ) commonLocal.CheckToolMode();
	else if ( cmd == "startup" ) commonLocal.StartupVariable( w[0] == "*" ? NULL : w[0].c_str(), atoi( w[1].c_str() ) != 0 );
	else if ( cmd == "addstartup" ) out( "RET %d", commonLocal.AddStartupCommands() ? 1 : 0 );
	else if ( cmd == "lines" ) {
		for ( int i = 0; i < com_numConsoleLines; i++ ) {
			std::string s; for ( int a = 0; a < com_consoleLines[i].Argc(); a++ ) { if ( a ) s += "|"; s += com_consoleLines[i].Argv( a ); }
			{ char t[16]; sprintf( t, "LINE %d", i ); outs( t, s ); }
		}
		out( "LINES %d", com_numConsoleLines );
	}
	else if ( cmd == "evinit" ) eventLoop->Init();
	else if ( cmd == "evshutdown" ) eventLoop->Shutdown();
	else if ( cmd == "evsys" ) g_sysq.push_back( makeEvent( w, tail( rest, 3 ) ) );
	else if ( cmd == "evpush" ) { sysEvent_t e = makeEvent( w, tail( rest, 3 ) ); eventLoop->PushEvent( &e ); }
	else if ( cmd == "evget" ) {
		sysEvent_t e = eventLoop->GetEvent();
		std::string t; if ( e.evType == SE_CONSOLE && e.evPtr ) t = (const char *)e.evPtr;
		out( "EV %d %d %d %d %s", e.evType, e.evValue, e.evValue2, e.evPtrLength, esc( t ).c_str() );
		if ( e.evPtr ) Mem_Free( e.evPtr );
	}
	else if ( cmd == "evrun" ) out( "RET %d", eventLoop->RunEventLoop( atoi( w[0].c_str() ) != 0 ) );
	else if ( cmd == "evms" ) out( "RET %d", eventLoop->Milliseconds() );
	else if ( cmd == "evlevel" ) out( "RET %d", eventLoop->JournalLevel() );
	else if ( cmd == "evqueue" ) out( "EVQ %d %d", eventLoop->com_pushedEventsHead, eventLoop->com_pushedEventsTail );
	else if ( cmd == "state" ) out( "STATE err=%d refresh=%d editors=%d", commonLocal.com_errorEntered, commonLocal.com_refreshOnPrint ? 1 : 0, com_editors );
	else if ( cmd == "warnlist" ) {
		out( "WARNLIST %d %d", commonLocal.warningList.Num(), commonLocal.errorList.Num() );
		for ( int i = 0; i < commonLocal.warningList.Num(); i++ ) outs( "W", commonLocal.warningList[i].c_str() );
		for ( int i = 0; i < commonLocal.errorList.Num(); i++ ) outs( "E", commonLocal.errorList[i].c_str() );
		outs( "CAPTION", commonLocal.warningCaption.c_str() );
	}
	else out( "UNKNOWN %s", cmd.c_str() );
}

int main( int argc, char **argv ) {
	if ( argc < 3 ) { fprintf( stderr, "usage: harness <scenario> <golden>\n" ); return 2; }
	idLib::common = common = &commonLocal;
	g_golden = fopen( argv[2], "wb" );
	FILE *scn = fopen( argv[1], "rb" );
	if ( !scn || !g_golden ) { fprintf( stderr, "cannot open files\n" ); return 2; }
	char line[8192];
	while ( fgets( line, sizeof( line ), scn ) ) {
		std::string l = line;
		while ( !l.empty() && ( l[l.size() - 1] == '\n' || l[l.size() - 1] == '\r' ) ) l.erase( l.size() - 1 );
		if ( l.empty() || l[0] == '#' ) continue;
		outs( "CMD", l );
		size_t sp = l.find( ' ' );
		std::string cmd = l.substr( 0, sp ), rest = sp == std::string::npos ? "" : l.substr( sp + 1 );
		try { runCommand( cmd, rest ); }
		catch ( idException &e ) { outs( "THROW", e.error ); }
		catch ( harnessExit &x ) { out( "EXIT %s", x.why ); }
	}
	fclose( scn ); fclose( g_golden );
	return 0;
}
