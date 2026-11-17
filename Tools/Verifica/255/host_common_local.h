// Issue #255 (phase 2b): the declaration of idCommonLocal for the second parity harness, with the members of the real
// class of framework\Common.cpp that the extracted life cycle functions use. The members that are not extracted
// (the ones that Common.cpp implements and that are the subject of the first harness, or that need the whole engine)
// are fakes that the driver traces. Written for this repository, included by harness_host.cpp.
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
	virtual const idLangDict *GetLanguageDict( void );

	// extracted from Common.cpp
	void Init( int argc, const char **argv, const char *cmdline );
	void Shutdown( void );
	void InitGame( void );
	void ShutdownGame( bool reloading );
	void Frame( void );
	void GUIFrame( bool execCmd, bool network );
	void SingleAsyncTic( void );
	void Async( void );
	void Quit( void );

	// traced fakes
	void ClearWarnings( const char *reason );
	void PrintWarnings( void );
	void DumpWarnings( void );
	void ParseCommandLine( int argc, const char **argv );
	void ClearCommandLine( void );
	bool AddStartupCommands( void );
	bool SafeMode( void );
	void CheckToolMode( void );
	void CloseLogFile( void );
	void WriteConfiguration( void );
	void InitSIMD( void );
	void InitCommands( void );
	void InitRenderSystem( void );
	void PrintLoadingMessage( const char *msg );
	void SetMachineSpec( void );
	void InitLanguageDict( void );
	void LoadGameDLL( void );
	void UnloadGameDLL( void );

	bool						com_fullyInitialized;
	bool						com_refreshOnPrint;
	int							com_errorEntered;
	bool						com_shuttingDown;
	idStr						warningCaption;
	idStrList					errorList;
	idLangDict					languageDict;
};
