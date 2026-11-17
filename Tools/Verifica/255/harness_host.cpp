// Issue #255 (Doom 3, phases 2a-2c): driver of the second parity harness. Written for this repository. It is linked
// with the REAL idlib, the REAL framework\KeyInput.cpp, EditField.cpp (without Draw), UsercmdGen.cpp, the REAL bodies
// of the functions of framework\Console.cpp (everything but the drawing) and of framework\Common.cpp (Init, Shutdown,
// InitGame, ShutdownGame, Frame, GUIFrame, SingleAsyncTic, Async, Quit), cut out of the source by
// Build-Harness-Host.ps1, against fakes of the engine that trace every call.
//
// Usage: harness_host.exe <scenario.scn> <golden.txt>
//
// SCENARIO: one command per line; empty lines and '#' lines are skipped; every command is echoed as "CMD <line>".
// A text command takes the rest of the line with the escapes \n \t \r \" \\ and \xHH. An idException ends the command
// and prints "THROW <text>"; Sys_Quit and Sys_Error end it and print "EXIT quit" or "EXIT error".
//
//   the fakes:  time <ms>  evms <ms>  cvar <name> <value>  fail <point|none>  ret <name> <0|1> (already startupcmds safemode
//               fpuempty soundworld specfile net)  dedicated <n>  clipboard <text|none>  consolekey <a> <b>
//               cmds <names...>  cvarnames <names...>  argcomp <cmd> <values...>  cvarargcomp <cmd> <values...>
//               keyq <key> <0|1>   mouseq <action> <value>   (the system queues that usercmd reads)
//   keys:       keyinit keyshutdown s2k <str> k2s <n> <0|1> exec <command line> getbinding <n> action <n> execbinding <n>
//               keysfrom <str> bindfrom <str> writebinds numbinds <str> unbindb <str> isbound <n> <str> prelim <n> <0|1>
//               isdown <n> clearstates overstrike [<0|1>] argkeyname <cmd>
//   field:      fnew fclear fwidth <n> fbuf <text> fchar <n> fkey <n> fauto fcursor <n> fclearauto fpaste fshow
//   usercmd:    ucinit ucnewmap ucshutdown ucclear ucangles ucinhibit <0|1> <0|1> uctic <n> ucint ucdirect ucbutton <n>
//               uckey <n> ucmouse ucnames ucdata <str> ticnum <n> ucstate
//   console:    coninit conshutdown conclear conprint <text> conevent <type> <v> <v2> <force> conactive conclose condump
//               conshow <n> conframe <ms> context
//   life cycle: init <words> | initcmd <text> shutdown initgame shutdowngame <0|1> frame guiframe <0|1> <0|1> async
//               singletic quit state
#include "../hostinc/precompiled.h"
#pragma hdrstop

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
	fputs( buf, g_golden ); fputc( '\n', g_golden ); fflush( g_golden );
}
static void outs( const char *tag, const std::string &text ) { fprintf( g_golden, "%s %s\n", tag, esc( text ).c_str() ); fflush( g_golden ); }

// ---------------------------------------------------------------- the fakes
#include <setjmp.h>
// a call that never returns in the engine (Sys_Quit, Sys_Error, FatalError) leaves by longjmp: bcc32c crashes when a
// C++ exception that is not an idException unwinds through a function with a try block (Frame)
static jmp_buf g_exitJmp; static const char *g_exitWhy = "";
static void leave( const char *why ) { g_exitWhy = why; longjmp( g_exitJmp, 1 ); }
static int g_time = 0, g_evms = 0, g_dedicated = 0;
static bool g_already = false, g_startupCmds = false, g_safeMode = false, g_fpuEmpty = true, g_soundWorld = false, g_specFile = false, g_net = false;
static int g_consoleKeyA = 96, g_consoleKeyB = 126;
static std::string g_failAt;
static bool g_hasClipboard = false; static std::string g_clipboard;
int com_editors = 0, com_ticNumber = 0, com_frameTime = 0, com_frameNumber = 0;
int time_gameFrame = 0, time_gameDraw = 0, time_frontend = 0, time_backend = 0;
int idLib::frameNumber = 0;
static std::map<std::string, idCVar *> &registry() { static std::map<std::string, idCVar *> r; return r; }
static std::map<std::string, std::string> g_vars;
static std::vector<std::string> g_cmdNames, g_cvarNames;
static std::map<std::string, std::vector<std::string> > g_argComp, g_cvarArgComp;
static std::vector<std::pair<int, bool> > g_keyQueue; static std::vector<std::pair<int, int> > g_mouseQueue;
static int g_modFlags = 0;
struct cmdEntry { std::string name; cmdFunction_t fn; };
static std::vector<cmdEntry> g_cmds;

// a trace point that the scenario can make fail (an idException, like Error of a drop)
static void tr( const char *name ) {
	outs( "CALL", name );
	if ( g_failAt == name ) throw idException( "injected failure" );
	if ( g_failAt == std::string( name ) + "!" ) { leave( "exit" ); }
}

idCVar::idCVar( const char *name, const char *value, int flags, const char *description, float valueMin, float valueMax, argCompletion_t valueCompletion ) {
	n = name; v = value; modified = false; registry()[name] = this;
}
void idCVar::RegisterStaticVars() { tr( "cvar.RegisterStaticVars" ); }
void idCVarSystem::Init() { tr( "cvar.Init" ); }
void idCVarSystem::Shutdown() { tr( "cvar.Shutdown" ); }
bool idCVarSystem::IsInitialized() const { return true; }
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
void idCVarSystem::SetCVarInteger( const char *name, const int value, int flags ) {
	out( "CVARSETI %s %d", name, value );
	char t[32]; sprintf( t, "%d", value );
	std::map<std::string, idCVar *>::iterator i = registry().find( name );
	if ( i != registry().end() ) i->second->SetString( t ); else g_vars[name] = t;
}
void idCVarSystem::CommandCompletion( void(*callback)( const char *s ) ) { for ( size_t i = 0; i < g_cvarNames.size(); i++ ) callback( g_cvarNames[i].c_str() ); }
void idCVarSystem::ArgCompletion( const char *cmdString, void(*callback)( const char *s ) ) {
	idCmdArgs a; a.TokenizeString( cmdString, false );
	std::map<std::string, std::vector<std::string> >::iterator i = g_cvarArgComp.find( a.Argv( 0 ) );
	if ( i != g_cvarArgComp.end() ) for ( size_t k = 0; k < i->second.size(); k++ ) callback( i->second[k].c_str() );
}
void idCVarSystem::SetModifiedFlags( int flags ) { g_modFlags |= flags; out( "MODFLAGS set %d", flags ); }
int idCVarSystem::GetModifiedFlags() const { return g_modFlags; }
void idCVarSystem::ClearModifiedFlags( int flags ) { g_modFlags &= ~flags; out( "MODFLAGS clear %d", flags ); }
static idCVarSystem cvarSystemLocal;
idCVarSystem *cvarSystem = &cvarSystemLocal;

static const char *execName( cmdExecution_t e ) { return e == CMD_EXEC_NOW ? "now" : e == CMD_EXEC_INSERT ? "insert" : "append"; }
void idCmdSystem::Init() { tr( "cmd.Init" ); }
void idCmdSystem::Shutdown() { tr( "cmd.Shutdown" ); }
void idCmdSystem::AddCommand( const char *cmdName, cmdFunction_t function, int flags, const char *description, argCompletion_t argCompletion ) {
	out( "ADDCMD %s %d", cmdName, flags );
	for ( size_t i = 0; i < g_cmds.size(); i++ ) if ( g_cmds[i].name == cmdName ) return;
	cmdEntry e; e.name = cmdName; e.fn = function; g_cmds.push_back( e );
}
void idCmdSystem::RemoveCommand( const char *cmdName ) {
	out( "RMCMD %s", cmdName );
	for ( size_t i = 0; i < g_cmds.size(); i++ ) if ( g_cmds[i].name == cmdName ) { g_cmds.erase( g_cmds.begin() + i ); return; }
}
void idCmdSystem::BufferCommandText( cmdExecution_t exec, const char *text ) { outs( ( std::string( "BUFTEXT " ) + execName( exec ) ).c_str(), text ); }
void idCmdSystem::ExecuteCommandBuffer() { out( "BUFEXEC" ); }
void idCmdSystem::CommandCompletion( void(*callback)( const char *s ) ) { for ( size_t i = 0; i < g_cmdNames.size(); i++ ) callback( g_cmdNames[i].c_str() ); }
void idCmdSystem::ArgCompletion( const char *cmdString, void(*callback)( const char *s ) ) {
	idCmdArgs a; a.TokenizeString( cmdString, false );
	std::map<std::string, std::vector<std::string> >::iterator i = g_argComp.find( a.Argv( 0 ) );
	if ( i != g_argComp.end() ) for ( size_t k = 0; k < i->second.size(); k++ ) callback( i->second[k].c_str() );
}
static idCmdSystem cmdSystemLocal;
idCmdSystem *cmdSystem = &cmdSystemLocal;

void idSessionFake::Init() { tr( "session.Init" ); }
void idSessionFake::Shutdown() { tr( "session.Shutdown" ); }
void idSessionFake::Stop() { out( "SESSION stop" ); }
void idSessionFake::UpdateScreen( bool outOfSequence ) { out( "SESSION update %d", outOfSequence ? 1 : 0 ); }
void idSessionFake::StartMenu( bool playIntro ) { out( "SESSION startmenu %d", playIntro ? 1 : 0 ); }
void idSessionFake::Frame() { tr( "session.Frame" ); }
void idSessionFake::GuiFrameEvents() { out( "SESSION guiframeevents" ); }
void idSessionFake::WriteCDKey() { out( "SESSION writecdkey" ); }
static idSessionFake sessionLocal; idSessionFake *session = &sessionLocal;
void idRenderSystemFake::Init() { tr( "render.Init" ); }
void idRenderSystemFake::Shutdown() { tr( "render.Shutdown" ); }
void idRenderSystemFake::GetCardCaps( bool &oldCard, bool &nv10or20 ) { oldCard = false; nv10or20 = false; }
static idRenderSystemFake renderLocal; idRenderSystemFake *renderSystem = &renderLocal;
void idSoundWorld::StopAllSounds() { out( "SOUND stopall" ); }
static idSoundWorld soundWorldLocal;
void idSoundSystemFake::Init() { tr( "sound.Init" ); }
void idSoundSystemFake::Shutdown() { tr( "sound.Shutdown" ); }
void idSoundSystemFake::ClearBuffer() { out( "SOUND clearbuffer" ); }
idSoundWorld *idSoundSystemFake::GetPlayingSoundWorld() { return g_soundWorld ? &soundWorldLocal : NULL; }
void idSoundSystemFake::AsyncUpdate( int inTime ) { out( "SOUND asyncupdate %d", inTime ); }
void idSoundSystemFake::AsyncUpdateWrite( int inTime ) { out( "SOUND asyncupdatewrite %d", inTime ); }
static idSoundSystemFake soundLocal; idSoundSystemFake *soundSystem = &soundLocal;
void idDeclManagerFake::Init() { tr( "decl.Init" ); }
void idDeclManagerFake::Shutdown() { tr( "decl.Shutdown" ); }
static idDeclManagerFake declLocal; idDeclManagerFake *declManager = &declLocal;
void idUIManagerFake::Init() { tr( "ui.Init" ); }
void idUIManagerFake::Shutdown() { tr( "ui.Shutdown" ); }
static idUIManagerFake uiLocal; idUIManagerFake *uiManager = &uiLocal;
void idAsyncServerFake::Kill() { out( "NET server.Kill" ); }
void idAsyncServerFake::InitPort() { out( "NET server.InitPort" ); }
void idAsyncClientFake::Shutdown() { out( "NET client.Shutdown" ); }
void idAsyncNetwork::Init() { tr( "net.Init" ); }
void idAsyncNetwork::Shutdown() { tr( "net.Shutdown" ); }
void idAsyncNetwork::RunFrame() { out( "NET RunFrame" ); }
bool idAsyncNetwork::IsActive() { return g_net; }
idCVar idAsyncNetwork::serverDedicated( "net_serverDedicated", "0", CVAR_INTEGER, "" );
idAsyncServerFake idAsyncNetwork::server; idAsyncClientFake idAsyncNetwork::client;
void idEventLoop::Init() { tr( "events.Init" ); }
void idEventLoop::Shutdown() { tr( "events.Shutdown" ); }
int idEventLoop::RunEventLoop( bool commandExecution ) { out( "EVENTS run %d", commandExecution ? 1 : 0 ); return 0; }
int idEventLoop::Milliseconds() { return g_evms; }
static char g_eventLoopStorage[16]; idEventLoop *eventLoop = (idEventLoop *)g_eventLoopStorage;
void idSIMDFake::InitProcessor( const char *module, bool forceGeneric ) {}
void Mem_EnableLeakTest( const char *name ) { outs( "MEMLEAKTEST", name ); }
versionFake version = { "DOOM 3 harness 1.0" };

const char *idLangDict::GetString( const char *id ) const { static std::string r[8]; static int k = 0; k = ( k + 1 ) & 7; r[k] = std::string( "<" ) + id + ">"; return r[k].c_str(); }

int Sys_Milliseconds( void ) { return g_time; }
sysEvent_t Sys_GetEvent( void ) { sysEvent_t e; memset( &e, 0, sizeof( e ) ); return e; }
void Sys_Printf( const char *fmt, ... ) {}
void Sys_DebugPrintf( const char *fmt, ... ) { char buf[4096]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( buf, sizeof( buf ), fmt, ap ); va_end( ap ); outs( "DEBUGPRINT", buf ); }
void Sys_Quit( void ) { out( "SYSQUIT" ); leave( "quit" ); }
void Sys_Error( const char *error, ... ) { char buf[16384]; va_list ap; va_start( ap, error ); idStr::vsnPrintf( buf, sizeof( buf ), error, ap ); va_end( ap ); outs( "SYSERR", buf ); leave( "error" ); }
void Sys_Init( void ) { tr( "sys.Init" ); }
void Sys_InitNetworking( void ) { tr( "sys.InitNetworking" ); }
bool Sys_AlreadyRunning( void ) { out( "SYS AlreadyRunning %d", g_already ? 1 : 0 ); return g_already; }
void Sys_Shutdown( void ) { tr( "sys.Shutdown" ); }
void Sys_DoPreferences( void ) { tr( "sys.DoPreferences" ); }
void Sys_GenerateEvents( void ) { tr( "sys.GenerateEvents" ); }
void Sys_EnterCriticalSection( int index ) { out( "SYS enter" ); }
void Sys_LeaveCriticalSection( int index ) { out( "SYS leave" ); }
bool Sys_FPU_StackIsEmpty( void ) { return g_fpuEmpty; }
const char *Sys_FPU_GetState( void ) { return "FPU state\n"; }
int Sys_GetConsoleKey( bool shifted ) { return shifted ? g_consoleKeyB : g_consoleKeyA; }
void Sys_GrabMouseCursor( bool grabIt ) { out( "SYS grabmouse %d", grabIt ? 1 : 0 ); }
char *Sys_GetClipboardData( void ) {
	if ( !g_hasClipboard ) return NULL;
	char *p = (char *)Mem_Alloc( (int)g_clipboard.size() + 1 ); memcpy( p, g_clipboard.c_str(), g_clipboard.size() + 1 ); return p;
}
unsigned char Sys_MapCharForKey( int key ) { return (unsigned char)key; }
static std::vector<std::pair<int, bool> > g_keyBatch; static std::vector<std::pair<int, int> > g_mouseBatch;
int Sys_PollKeyboardInputEvents( void ) { g_keyBatch = g_keyQueue; g_keyQueue.clear(); return (int)g_keyBatch.size(); }
int Sys_ReturnKeyboardInputEvent( const int n, int &ch, bool &state ) { if ( n < 0 || n >= (int)g_keyBatch.size() ) return 0; ch = g_keyBatch[n].first; state = g_keyBatch[n].second; return 1; }
void Sys_EndKeyboardInputEvents( void ) { g_keyBatch.clear(); }
int Sys_PollMouseInputEvents( void ) { g_mouseBatch = g_mouseQueue; g_mouseQueue.clear(); return (int)g_mouseBatch.size(); }
int Sys_ReturnMouseInputEvent( const int n, int &action, int &value ) { if ( n < 0 || n >= (int)g_mouseBatch.size() ) return 0; action = g_mouseBatch[n].first; value = g_mouseBatch[n].second; return 1; }
void Sys_EndMouseInputEvents( void ) { g_mouseBatch.clear(); }

int idFile::Write( const void *buffer, int len ) { std::string chunk( (const char *)buffer, len ); data += chunk; outs( ( std::string( "FW " ) + name ).c_str(), chunk ); return len; }
int idFile::Read( void *buffer, int len ) { return 0; }
void idFile::Flush() {} void idFile::ForceFlush() {}
int idFile::Printf( const char *fmt, ... ) {
	char buf[4096]; va_list ap; va_start( ap, fmt ); idStr::vsnPrintf( buf, sizeof( buf ), fmt, ap ); va_end( ap );
	return Write( buf, (int)strlen( buf ) );
}
void idFileSystem::Init() { tr( "files.Init" ); }
void idFileSystem::Shutdown( bool reloading ) { out( "CALL files.Shutdown %d", reloading ? 1 : 0 ); if ( g_failAt == "files.Shutdown" ) throw idException( "injected failure" ); }
idFile *idFileSystem::OpenFileWrite( const char *relativePath, const char *basePath ) { out( "OPENW %s %s", relativePath, basePath ); idFile *f = new idFile; f->name = relativePath; f->writing = true; return f; }
idFile *idFileSystem::OpenExplicitFileRead( const char *OSPath ) { if ( !g_specFile ) { out( "OPENX %s fail", OSPath ); return NULL; } out( "OPENX %s ok", OSPath ); idFile *f = new idFile; f->name = OSPath; return f; }
const char *idFileSystem::RelativePathToOSPath( const char *relativePath, const char *basePath ) { static std::string s; s = std::string( "OS:" ) + basePath + "/" + relativePath; return s.c_str(); }
void idFileSystem::CloseFile( idFile *f ) { out( "CLOSE %s", f ? f->name.c_str() : "(null)" ); delete f; }
static idFileSystem fileSystemLocal; idFileSystem *fileSystem = &fileSystemLocal;

idSys *idLib::sys = 0; idCommon *idLib::common = 0; idFileSystem *idLib::fileSystem = 0; idCVarSystem *idLib::cvarSystem = 0;
void idLib::Init() { tr( "idlib.Init" ); }
void idLib::ShutDown() { tr( "idlib.ShutDown" ); }
void idLib::Error( const char *fmt, ... ) {} void idLib::Warning( const char *fmt, ... ) {}
idSys *sys = 0; idCommon *common = 0;
#include "math/Simd_Generic.h"
static idSIMD_Generic simdGeneric;
idSIMDProcessor *SIMDProcessor = &simdGeneric;

idCVar com_forceGenericSIMD( "com_forceGenericSIMD", "0", CVAR_BOOL|CVAR_SYSTEM, "" );
idCVar com_speeds( "com_speeds", "0", CVAR_BOOL|CVAR_SYSTEM, "" );
idCVar com_asyncInput( "com_asyncInput", "0", CVAR_BOOL|CVAR_SYSTEM, "" );
idCVar com_asyncSound( "com_asyncSound", "1", CVAR_INTEGER|CVAR_SYSTEM, "" );
idCVar com_preciseTic( "com_preciseTic", "1", CVAR_BOOL|CVAR_SYSTEM, "" );
idCVar com_timescale( "timescale", "1", CVAR_SYSTEM|CVAR_FLOAT, "" );

// ---------------------------------------------------------------- the real framework code
#include "../hostfw/key_extract.inc"
#include "../hostfw/field_extract.inc"
#include "../hostfw/usercmd_extract.inc"
#include "../hostfw/console_extract.inc"

// ---------------------------------------------------------------- idCommonLocal: life cycle
#include "host_common_local.h"
#include "../hostfw/common_extract.inc"
idCommonLocal::idCommonLocal() { com_fullyInitialized = false; com_refreshOnPrint = false; com_errorEntered = 0; com_shuttingDown = false; }
static void emitPrint( const char *tag, const char *fmt, va_list ap ) { char buf[16384]; idStr::vsnPrintf( buf, sizeof( buf ), fmt, ap ); outs( tag, buf ); }
void idCommonLocal::Printf( const char *fmt, ... ) { va_list ap; va_start( ap, fmt ); emitPrint( "PRINTF", fmt, ap ); va_end( ap ); }
void idCommonLocal::DPrintf( const char *fmt, ... ) { va_list ap; va_start( ap, fmt ); emitPrint( "DPRINTF", fmt, ap ); va_end( ap ); }
void idCommonLocal::Warning( const char *fmt, ... ) { va_list ap; va_start( ap, fmt ); emitPrint( "WARNING", fmt, ap ); va_end( ap ); }
void idCommonLocal::DWarning( const char *fmt, ... ) { va_list ap; va_start( ap, fmt ); emitPrint( "DWARNING", fmt, ap ); va_end( ap ); }
void idCommonLocal::Error( const char *fmt, ... ) { va_list ap; va_start( ap, fmt ); char buf[16384]; idStr::vsnPrintf( buf, sizeof( buf ), fmt, ap ); va_end( ap ); outs( "ERROR", buf ); throw idException( buf ); }
static void throwFatal( const char *text ) { outs( "FATALERROR", text ); leave( "fatal" ); }
void idCommonLocal::FatalError( const char *fmt, ... ) { va_list ap; va_start( ap, fmt ); char buf[16384]; idStr::vsnPrintf( buf, sizeof( buf ), fmt, ap ); va_end( ap ); throwFatal( buf ); }
void idCommonLocal::StartupVariable( const char *match, bool once ) { out( "STARTUPVAR %s %d", match ? match : "(null)", once ? 1 : 0 ); }
const idLangDict *idCommonLocal::GetLanguageDict( void ) { return &languageDict; }
void idCommonLocal::ClearWarnings( const char *reason ) { outs( "CALL ClearWarnings", reason ); }
void idCommonLocal::PrintWarnings( void ) { tr( "PrintWarnings" ); }
void idCommonLocal::DumpWarnings( void ) { tr( "DumpWarnings" ); }
void idCommonLocal::ParseCommandLine( int argc, const char **argv ) {
	std::string s; for ( int i = 0; i < argc; i++ ) { if ( i ) s += "|"; s += argv[i]; }
	outs( "CALL ParseCommandLine", s );
}
void idCommonLocal::ClearCommandLine( void ) { tr( "ClearCommandLine" ); }
bool idCommonLocal::AddStartupCommands( void ) { out( "CALL AddStartupCommands -> %d", g_startupCmds ? 1 : 0 ); return g_startupCmds; }
bool idCommonLocal::SafeMode( void ) { out( "CALL SafeMode -> %d", g_safeMode ? 1 : 0 ); return g_safeMode; }
void idCommonLocal::CheckToolMode( void ) { tr( "CheckToolMode" ); }
void idCommonLocal::CloseLogFile( void ) { tr( "CloseLogFile" ); }
void idCommonLocal::WriteConfiguration( void ) { tr( "WriteConfiguration" ); }
void idCommonLocal::InitSIMD( void ) { tr( "InitSIMD" ); com_forceGenericSIMD.ClearModified(); }
void idCommonLocal::InitCommands( void ) { tr( "InitCommands" ); }
void idCommonLocal::InitRenderSystem( void ) { tr( "InitRenderSystem" ); }
void idCommonLocal::PrintLoadingMessage( const char *msg ) { outs( "CALL PrintLoadingMessage", msg ); }
void idCommonLocal::SetMachineSpec( void ) { tr( "SetMachineSpec" ); }
void idCommonLocal::InitLanguageDict( void ) { tr( "InitLanguageDict" ); }
void idCommonLocal::LoadGameDLL( void ) { tr( "LoadGameDLL" ); }
void idCommonLocal::UnloadGameDLL( void ) { tr( "UnloadGameDLL" ); }
void Com_ExecMachineSpec_f( const idCmdArgs &args ) { tr( "Com_ExecMachineSpec_f" ); }
static idCommonLocal commonLocal;

// ---------------------------------------------------------------- the driver
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
static void printUsercmd( const char *tag, const usercmd_t &c ) {
	out( "%s frame=%d time=%d dup=%d buttons=%d fwd=%d right=%d up=%d angles=%d,%d,%d mx=%d my=%d impulse=%d flags=%d seq=%d", tag, c.gameFrame, c.gameTime,
		c.duplicateCount, c.buttons, c.forwardmove, c.rightmove, c.upmove, c.angles[0], c.angles[1], c.angles[2], c.mx, c.my, c.impulse, c.flags, c.sequence );
}
static idEditField g_field;
static void showField() {
	char t[512]; std::string ac;
	sprintf( t, "FIELD cursor=%d scroll=%d width=%d len=%d valid=%d match=%d index=%d", g_field.cursor, g_field.scroll, g_field.widthInChars, g_field.autoComplete.length,
		g_field.autoComplete.valid ? 1 : 0, g_field.autoComplete.matchCount, g_field.autoComplete.matchIndex );
	out( "%s", t ); outs( "FBUF", g_field.buffer ); outs( "FCOMP", g_field.autoComplete.completionString ); outs( "FMATCH", g_field.autoComplete.currentMatch );
}
static void runCommand( const std::string &cmd, const std::string &rest ) {
	std::vector<std::string> w = words( rest );
	std::string text = unesc( rest );
	// ---- fakes
	if ( cmd == "time" ) g_time = atoi( w[0].c_str() );
	else if ( cmd == "evms" ) g_evms = atoi( w[0].c_str() );
	else if ( cmd == "cvar" ) cvarSystem->SetCVarString( w[0].c_str(), w.size() > 1 ? w[1].c_str() : "" );
	else if ( cmd == "fail" ) g_failAt = w[0] == "none" ? "" : w[0];
	else if ( cmd == "ret" ) {
		bool v = atoi( w[1].c_str() ) != 0;
		if ( w[0] == "already" ) g_already = v; else if ( w[0] == "startupcmds" ) g_startupCmds = v; else if ( w[0] == "safemode" ) g_safeMode = v;
		else if ( w[0] == "fpuempty" ) g_fpuEmpty = v; else if ( w[0] == "soundworld" ) g_soundWorld = v; else if ( w[0] == "specfile" ) g_specFile = v; else if ( w[0] == "net" ) g_net = v;
	}
	else if ( cmd == "dedicated" ) idAsyncNetwork::serverDedicated.SetString( w[0].c_str() );
	else if ( cmd == "clipboard" ) { g_hasClipboard = text != "none"; g_clipboard = text; }
	else if ( cmd == "consolekey" ) { g_consoleKeyA = atoi( w[0].c_str() ); g_consoleKeyB = atoi( w[1].c_str() ); }
	else if ( cmd == "cmds" ) g_cmdNames = w;
	else if ( cmd == "cvarnames" ) g_cvarNames = w;
	else if ( cmd == "argcomp" ) g_argComp[w[0]] = std::vector<std::string>( w.begin() + 1, w.end() );
	else if ( cmd == "cvarargcomp" ) g_cvarArgComp[w[0]] = std::vector<std::string>( w.begin() + 1, w.end() );
	else if ( cmd == "keyq" ) g_keyQueue.push_back( std::make_pair( atoi( w[0].c_str() ), atoi( w[1].c_str() ) != 0 ) );
	else if ( cmd == "mouseq" ) g_mouseQueue.push_back( std::make_pair( atoi( w[0].c_str() ), atoi( w[1].c_str() ) ) );
	// ---- keys
	else if ( cmd == "keyinit" ) idKeyInput::Init();
	else if ( cmd == "keyshutdown" ) idKeyInput::Shutdown();
	else if ( cmd == "s2k" ) out( "RET %d", idKeyInput::StringToKeyNum( text.c_str() ) );
	else if ( cmd == "k2s" ) outs( "RETS", idKeyInput::KeyNumToString( atoi( w[0].c_str() ), atoi( w[1].c_str() ) != 0 ) );
	else if ( cmd == "exec" ) {
		idCmdArgs a; a.TokenizeString( text.c_str(), false ); bool found = false;
		for ( size_t i = 0; i < g_cmds.size(); i++ ) if ( g_cmds[i].name == a.Argv( 0 ) ) { g_cmds[i].fn( a ); found = true; break; }
		if ( !found ) outs( "NOCMD", a.Argv( 0 ) );
	}
	else if ( cmd == "getbinding" ) outs( "RETS", idKeyInput::GetBinding( atoi( w[0].c_str() ) ) );
	else if ( cmd == "action" ) out( "RET %d", idKeyInput::GetUsercmdAction( atoi( w[0].c_str() ) ) );
	else if ( cmd == "execbinding" ) out( "RET %d", idKeyInput::ExecKeyBinding( atoi( w[0].c_str() ) ) ? 1 : 0 );
	else if ( cmd == "keysfrom" ) outs( "RETS", idKeyInput::KeysFromBinding( text.c_str() ) );
	else if ( cmd == "bindfrom" ) { const char *r = idKeyInput::BindingFromKey( text.c_str() ); outs( "RETS", r ? r : "(null)" ); }
	else if ( cmd == "writebinds" ) { idFile f; f.name = "bindings"; idKeyInput::WriteBindings( &f ); }
	else if ( cmd == "numbinds" ) out( "RET %d", idKeyInput::NumBinds( text.c_str() ) );
	else if ( cmd == "unbindb" ) out( "RET %d", idKeyInput::UnbindBinding( text.c_str() ) ? 1 : 0 );
	else if ( cmd == "isbound" ) out( "RET %d", idKeyInput::KeyIsBoundTo( atoi( w[0].c_str() ), tail( rest, 1 ).c_str() ) ? 1 : 0 );
	else if ( cmd == "prelim" ) idKeyInput::PreliminaryKeyEvent( atoi( w[0].c_str() ), atoi( w[1].c_str() ) != 0 );
	else if ( cmd == "isdown" ) out( "RET %d", idKeyInput::IsDown( atoi( w[0].c_str() ) ) ? 1 : 0 );
	else if ( cmd == "clearstates" ) idKeyInput::ClearStates();
	else if ( cmd == "overstrike" ) { if ( !w.empty() ) idKeyInput::SetOverstrikeMode( atoi( w[0].c_str() ) != 0 ); out( "RET %d", idKeyInput::GetOverstrikeMode() ? 1 : 0 ); }
	else if ( cmd == "argkeyname" ) {
		idCmdArgs a; a.TokenizeString( text.c_str(), false );
		struct Cb { static void f( const char *s ) { outs( "COMP", s ); } };
		idKeyInput::ArgCompletion_KeyName( a, Cb::f );
	}
	// ---- the edit field
	else if ( cmd == "fnew" ) { g_field.Clear(); }
	else if ( cmd == "fclear" ) { g_field.Clear(); }
	else if ( cmd == "fwidth" ) g_field.SetWidthInChars( atoi( w[0].c_str() ) );
	else if ( cmd == "fbuf" ) g_field.SetBuffer( text.c_str() );
	else if ( cmd == "fchar" ) g_field.CharEvent( atoi( w[0].c_str() ) );
	else if ( cmd == "fkey" ) g_field.KeyDownEvent( atoi( w[0].c_str() ) );
	else if ( cmd == "fauto" ) g_field.AutoComplete();
	else if ( cmd == "fcursor" ) g_field.SetCursor( atoi( w[0].c_str() ) );
	else if ( cmd == "fclearauto" ) g_field.ClearAutoComplete();
	else if ( cmd == "fpaste" ) g_field.Paste();
	else if ( cmd == "fshow" ) showField();
	// ---- usercmd
	else if ( cmd == "ucinit" ) usercmdGen->Init();
	else if ( cmd == "ucnewmap" ) usercmdGen->InitForNewMap();
	else if ( cmd == "ucshutdown" ) usercmdGen->Shutdown();
	else if ( cmd == "ucclear" ) usercmdGen->Clear();
	else if ( cmd == "ucangles" ) usercmdGen->ClearAngles();
	else if ( cmd == "ucinhibit" ) usercmdGen->InhibitUsercmd( (inhibit_t)atoi( w[0].c_str() ), atoi( w[1].c_str() ) != 0 );
	else if ( cmd == "uctic" ) printUsercmd( "UCTIC", usercmdGen->TicCmd( atoi( w[0].c_str() ) ) );
	else if ( cmd == "ucint" ) usercmdGen->UsercmdInterrupt();
	else if ( cmd == "ucdirect" ) printUsercmd( "UCDIRECT", usercmdGen->GetDirectUsercmd() );
	else if ( cmd == "ucbutton" ) out( "RET %d", usercmdGen->ButtonState( atoi( w[0].c_str() ) ) );
	else if ( cmd == "uckey" ) out( "RET %d", usercmdGen->KeyState( atoi( w[0].c_str() ) ) );
	else if ( cmd == "ucmouse" ) { int x, y, b; bool d; usercmdGen->MouseState( &x, &y, &b, &d ); out( "MOUSE %d %d %d %d", x, y, b, d ? 1 : 0 ); }
	else if ( cmd == "ucnames" ) { out( "NUM %d", usercmdGen->GetNumUserCommands() ); outs( "NAME0", usercmdGen->GetUserCommandName( 0 ) ); { const char *last = usercmdGen->GetUserCommandName( usercmdGen->GetNumUserCommands() - 1 ); outs( "NAMEN", last ? last : "" ); } outs( "NAMEBAD", usercmdGen->GetUserCommandName( -1 ) ); }
	else if ( cmd == "ucdata" ) out( "RET %d", usercmdGen->CommandStringUsercmdData( text.c_str() ) );
	else if ( cmd == "ticnum" ) com_ticNumber = atoi( w[0].c_str() );
	else if ( cmd == "ucstate" ) {
		idUsercmdGenLocal &u = localUsercmdGen;
		out( "UCSTATE view=%.4f,%.4f,%.4f flags=%d impulse=%d inhibit=%d init=%d run=%d,%d crouch=%d,%d zoom=%d,%d", u.viewangles[0], u.viewangles[1], u.viewangles[2], u.flags, u.impulse,
			u.inhibitCommands, u.initialized ? 1 : 0, u.toggled_run.on, u.toggled_run.held ? 1 : 0, u.toggled_crouch.on, u.toggled_crouch.held ? 1 : 0, u.toggled_zoom.on, u.toggled_zoom.held ? 1 : 0 );
		out( "UCSTATE mouse=%d,%d down=%d button=%d dx=%d dy=%d", u.continuousMouseX, u.continuousMouseY, u.mouseDown ? 1 : 0, u.mouseButton, u.mouseDx, u.mouseDy );
	}
	// ---- the console
	else if ( cmd == "coninit" ) console->Init();
	else if ( cmd == "conshutdown" ) console->Shutdown();
	else if ( cmd == "conclear" ) localConsole.Clear();
	else if ( cmd == "conprint" ) console->Print( text.c_str() );
	else if ( cmd == "conevent" ) {
		sysEvent_t e; memset( &e, 0, sizeof( e ) ); e.evType = (sysEventType_t)atoi( w[0].c_str() ); e.evValue = atoi( w[1].c_str() ); e.evValue2 = atoi( w[2].c_str() );
		out( "RET %d", console->ProcessEvent( &e, atoi( w[3].c_str() ) != 0 ) ? 1 : 0 );
	}
	else if ( cmd == "conactive" ) out( "RET %d", console->Active() ? 1 : 0 );
	else if ( cmd == "conclose" ) console->Close();
	else if ( cmd == "condump" ) localConsole.Dump( text.c_str() );
	else if ( cmd == "conframe" ) com_frameTime = atoi( w[0].c_str() );
	else if ( cmd == "conscroll" ) localConsole.Scroll();
	else if ( cmd == "conupdate" ) localConsole.UpdateDisplayFraction();
	else if ( cmd == "contimes" ) out( "TIMES %d %d %d %d", localConsole.times[0], localConsole.times[1], localConsole.times[2], localConsole.times[3] );
	else if ( cmd == "conshow" ) {
		int n = atoi( w[0].c_str() );
		for ( int l = localConsole.current - n + 1; l <= localConsole.current; l++ ) {
			if ( l < 0 ) continue;
			std::string s, c; short *line = localConsole.text + ( l % TOTAL_LINES ) * LINE_WIDTH;
			for ( int i = 0; i < LINE_WIDTH; i++ ) { s += (char)( line[i] & 0xff ); c += (char)( '0' + ( ( line[i] >> 8 ) & 0xf ) ); }
			char t[32]; sprintf( t, "CONLINE %d", l ); outs( t, s ); sprintf( t, "CONCOLOR %d", l ); outs( t, c );
		}
	}
	else if ( cmd == "context" ) {
		out( "CONSOLE catching=%d current=%d x=%d display=%d lastKey=%d nextKey=%d frac=%.3f final=%.3f fracTime=%d history=%d,%d", localConsole.keyCatching ? 1 : 0, localConsole.current, localConsole.x,
			localConsole.display, localConsole.lastKeyEvent, localConsole.nextKeyEvent, localConsole.displayFrac, localConsole.finalFrac, localConsole.fracTime, localConsole.nextHistoryLine, localConsole.historyLine );
		outs( "CONFIELD", localConsole.consoleField.buffer ); out( "CONFIELDCURSOR %d %d", localConsole.consoleField.cursor, localConsole.consoleField.scroll );
		for ( int i = 0; i < COMMAND_HISTORY; i++ ) if ( localConsole.historyEditLines[i].buffer[0] ) { char t[32]; sprintf( t, "HIST %d", i ); outs( t, localConsole.historyEditLines[i].buffer ); }
	}
	// ---- life cycle
	else if ( cmd == "init" ) { std::vector<const char *> argv; for ( size_t i = 0; i < w.size(); i++ ) argv.push_back( w[i].c_str() ); commonLocal.Init( (int)argv.size(), argv.empty() ? NULL : &argv[0], NULL ); }
	else if ( cmd == "initcmd" ) commonLocal.Init( 0, NULL, text.c_str() );
	else if ( cmd == "shutdown" ) commonLocal.Shutdown();
	else if ( cmd == "initgame" ) commonLocal.InitGame();
	else if ( cmd == "shutdowngame" ) commonLocal.ShutdownGame( atoi( w[0].c_str() ) != 0 );
	else if ( cmd == "frame" ) commonLocal.Frame();
	else if ( cmd == "guiframe" ) commonLocal.GUIFrame( atoi( w[0].c_str() ) != 0, atoi( w[1].c_str() ) != 0 );
	else if ( cmd == "async" ) commonLocal.Async();
	else if ( cmd == "singletic" ) commonLocal.SingleAsyncTic();
	else if ( cmd == "quit" ) commonLocal.Quit();
	else if ( cmd == "errorentered" ) commonLocal.com_errorEntered = atoi( w[0].c_str() );
	else if ( cmd == "state" ) {
		out( "STATE tic=%d frameTime=%d frame=%d fully=%d shutting=%d lastTic=%d lastlib=%d", com_ticNumber, com_frameTime, com_frameNumber, commonLocal.com_fullyInitialized ? 1 : 0, commonLocal.com_shuttingDown ? 1 : 0,
			lastTicMsec, idLib::frameNumber );
		for ( int i = 0; i < 4; i++ ) { int t = ( com_ticNumber - 1 - i ); if ( t < 0 ) break; out( "ASYNC %d ms=%d delta=%d consumed=%d", t, com_asyncStats[t & ( MAX_ASYNC_STATS - 1 )].milliseconds, com_asyncStats[t & ( MAX_ASYNC_STATS - 1 )].deltaMsec, com_asyncStats[t & ( MAX_ASYNC_STATS - 1 )].timeConsumed ); }
	}
	else out( "UNKNOWN %s", cmd.c_str() );
}

static void runGuarded( const std::string &cmd, const std::string &rest ) {
	try { runCommand( cmd, rest ); }
	catch ( idException &e ) { outs( "THROW", e.error ); }
}

int main( int argc, char **argv ) {
	if ( argc < 3 ) { fprintf( stderr, "usage: harness_host <scenario> <golden>\n" ); return 2; }
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
		if ( setjmp( g_exitJmp ) == 0 ) runGuarded( cmd, rest );
		else out( "EXIT %s", g_exitWhy );
	}
	fclose( scn ); fclose( g_golden );
	return 0;
}
