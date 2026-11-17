// Issue #255: the declaration of idCommonLocal for the parity harness, with the members of the real class of
// framework\Common.cpp that the extracted functions use (the real class also has the functions of the engine that
// are not extracted: Init, Frame, the localization...). Written for this repository, included by harness.cpp.
idCVar com_developer( "developer", "0", CVAR_BOOL|CVAR_SYSTEM|CVAR_NOCHEAT, "developer mode" );
idCVar com_timestampPrints( "com_timestampPrints", "0", CVAR_SYSTEM, "print time with each console print, 1 = msec, 2 = sec", 0, 2, 0 );
idCVar com_logFile( "logFile", "0", CVAR_SYSTEM | CVAR_NOCHEAT, "1 = buffer log, 2 = flush after each print", 0, 2, 0 );
idCVar com_logFileName( "logFileName", "qconsole.log", CVAR_SYSTEM | CVAR_NOCHEAT, "name of log file, if empty, qconsole.log will be used" );

class idCommonLocal : public idCommon {
public:
	idCommonLocal( void );
	virtual void Printf( const char *fmt, ... );
	virtual void DPrintf( const char *fmt, ... );
	virtual void Warning( const char *fmt, ... );
	virtual void DWarning( const char *fmt, ... );
	virtual void Error( const char *fmt, ... );
	virtual void FatalError( const char *fmt, ... );
	virtual void StartupVariable( const char *match, bool once );
	void VPrintf( const char *fmt, va_list arg );
	void BeginRedirect( char *buffer, int buffersize, void (*flush)( const char * ) );
	void EndRedirect( void );
	void SetRefreshOnPrint( bool set );
	void PrintWarnings( void );
	void ClearWarnings( const char *reason );
	void DumpWarnings( void );
	bool AddStartupCommands( void );
	void ParseCommandLine( int argc, const char **argv );
	void ClearCommandLine( void );
	bool SafeMode( void );
	void CheckToolMode( void );
	void CloseLogFile( void );
	void Shutdown( void ) { out( "SHUTDOWN" ); }

	bool						com_fullyInitialized;
	bool						com_refreshOnPrint;
	int							com_errorEntered;
	bool						com_shuttingDown;
	idFile *					logFile;
	char						errorMessage[MAX_PRINT_MSG_SIZE];
	char *						rd_buffer;
	int							rd_buffersize;
	void						(*rd_flush)( const char *buffer );
	idStr						warningCaption;
	idStrList					warningList;
	idStrList					errorList;
};
