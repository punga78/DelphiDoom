{******************************************************************************}
{                                                                              }
{  DelphiDoom: Script - contract shared by the DLL and its clients             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Script.Intf;

interface

uses
  System.SysUtils;

const
  // Result codes (zero is success, every error is negative)
  SCRIPT_OK = 0;
  SCRIPT_ERROR_ARGUMENT = -1;   // nil pointer, empty text, invalid kind or declaration
  SCRIPT_ERROR_BUFFER = -2;     // the caller buffer is too small: the size needed is returned
  SCRIPT_ERROR_COMPILE = -3;    // the source has errors: read them with GetMessageInfo
  SCRIPT_ERROR_LOAD = -4;       // the bytecode is not valid or a host function is missing
  SCRIPT_ERROR_STATE = -5;      // no bytecode loaded, or already loaded
  SCRIPT_ERROR_NOTFOUND = -6;   // no such procedure or global variable
  SCRIPT_ERROR_RUNTIME = -7;    // the script stopped with an error: GetLastErrorText
  SCRIPT_ERROR_TYPE = -8;       // wrong number or type of arguments, or of the variable
  SCRIPT_ERROR_MEMORY = -9;     // out of memory
  SCRIPT_ERROR_INTERNAL = -10;  // unexpected failure inside the library

  // Kinds of TScriptValue
  SCRIPT_VALUE_NONE = 0;        // procedure without result
  SCRIPT_VALUE_INTEGER = 1;     // IntegerValue (Byte..Int64, Char as ordinal for arguments)
  SCRIPT_VALUE_DOUBLE = 2;      // DoubleValue (Single, Double, Extended, Currency)
  SCRIPT_VALUE_TEXT = 3;        // Text: ANSI string (the script type "string")

  // Kinds of compiler message (TScriptMessageInfo.Kind)
  SCRIPT_MESSAGE_ERROR = 0;
  SCRIPT_MESSAGE_WARNING = 1;
  SCRIPT_MESSAGE_HINT = 2;

  // Calling conventions of the host functions (AddHostFunction)
  SCRIPT_CALL_REGISTER = 0;     // Delphi "register": the convention of the engine functions
  SCRIPT_CALL_PASCAL = 1;
  SCRIPT_CALL_CDECL = 2;
  SCRIPT_CALL_STDCALL = 3;
  SCRIPT_CALL_SAFECALL = 4;

  // Kinds of a global variable of the script (GetGlobalInfo)
  SCRIPT_GLOBAL_OTHER = 0;
  SCRIPT_GLOBAL_INTEGER = 1;
  SCRIPT_GLOBAL_DOUBLE = 2;
  SCRIPT_GLOBAL_TEXT = 3;

  // Name of the DLL and of its only export
  DDSCRIPT_LIBRARY_NAME = 'DDScript.dll';
  DDSCRIPT_CREATE_EXPORT = 'DDScriptCreate';

type
  /// <summary>
  ///   Called by the interpreter before every line of the script (the
  ///   application uses it to count instructions or to interrupt loops);
  ///   AUserData is the pointer given to SetEventHandlers
  /// </summary>
  TScriptRunLineHandler = procedure(AUserData: Pointer); stdcall;

  /// <summary>
  ///   Called when the script raises an exception: ACode is the interpreter
  ///   error number, AProcedure the number of the procedure and APosition the
  ///   position in its code
  /// </summary>
  TScriptExceptionHandler = procedure(AUserData: Pointer; ACode: Integer;
    AProcedure, APosition: Cardinal); stdcall;

  /// <summary>
  ///   Value exchanged with the script: argument of a call or its result.
  ///   The layout is fixed (packed) because it crosses the DLL boundary
  /// </summary>
  /// <remarks>
  ///   As an argument, Text is a zero terminated string owned by the caller
  ///   and TextSize is ignored. As a result, Text is a buffer of the caller
  ///   with room for TextSize bytes (zero included); on return TextSize is the
  ///   number of bytes needed (zero included). A result of kind TEXT whose
  ///   buffer is too small is reported with SCRIPT_ERROR_BUFFER, but the
  ///   procedure HAS run: take the text with IScriptExecutor.GetResultText
  ///   instead of calling again
  /// </remarks>
  TScriptValue = packed record
    Kind: Integer;
    TextSize: Cardinal;
    IntegerValue: Int64;
    DoubleValue: Double;
    Text: PAnsiChar;
  end;
  PScriptValue = ^TScriptValue;

  /// <summary>
  ///   Position and kind of a message of the compiler; the text is copied
  ///   in a buffer of the caller
  /// </summary>
  TScriptMessageInfo = packed record
    Kind: Integer;
    /// <summary>Offset (1 based) of the token in the source, in bytes</summary>
    Position: Cardinal;
    /// <summary>Line (1 based)</summary>
    Row: Cardinal;
    /// <summary>Column (1 based)</summary>
    Col: Cardinal;
  end;

  /// <summary>
  ///   Compiles Pascal Script sources into bytecode
  /// </summary>
  /// <remarks>
  ///   Only raw buffers and integers cross the DLL boundary: the caller owns
  ///   every buffer, the DLL never allocates memory the caller has to free.
  ///   Methods are stdcall so that the binary layout does not depend on the
  ///   compiler settings of the client. An instance must be used from one
  ///   thread at a time
  /// </remarks>
  IScriptCompiler = interface
    ['{5C2E7A14-93B0-4D6F-A8E1-0B4F6D92C753}']

    /// <summary>
    ///   Declares a function of the application that the sources can call, as
    ///   text: 'function Name(a: Integer): Integer;'. The same text, with the
    ///   address of the function, must be given to the executor that will run
    ///   the bytecode (IScriptExecutor.AddHostFunction)
    /// </summary>
    /// <returns>
    ///   SCRIPT_OK; SCRIPT_ERROR_ARGUMENT if the text is nil, is not a
    ///   function or procedure declaration, or the name is already declared
    /// </returns>
    function AddHostFunction(ADeclaration: PAnsiChar): Integer; stdcall;

    /// <summary>
    ///   Forgets everything declared: functions, types and constants of
    ///   every unit; the current unit goes back to SYSTEM
    /// </summary>
    function ClearHostFunctions: Integer; stdcall;

    /// <summary>
    ///   Chooses the unit the following declarations (functions, types and
    ///   constants) belong to: a source sees them when it names the unit in
    ///   its uses clause. The unit SYSTEM (the default) is always visible
    /// </summary>
    /// <returns>
    ///   SCRIPT_OK; SCRIPT_ERROR_ARGUMENT if the name is nil or is not an
    ///   identifier
    /// </returns>
    function SelectUnit(AUnitName: PAnsiChar): Integer; stdcall;

    /// <summary>
    ///   Declares a type in the current unit: AName is the new name and
    ///   ADefinition how the language would write it, for example
    ///   'array of integer' or 'single'
    /// </summary>
    /// <returns>
    ///   SCRIPT_OK; SCRIPT_ERROR_ARGUMENT for a nil or invalid name or
    ///   definition, or a name already declared
    /// </returns>
    function AddType(AName, ADefinition: PAnsiChar): Integer; stdcall;

    /// <summary>
    ///   Declares an integer constant in the current unit. ATypeName is the
    ///   type of the constant (integer, longword, int64...); nil means integer
    /// </summary>
    function AddConstantInteger(AName: PAnsiChar; AValue: Int64;
      ATypeName: PAnsiChar): Integer; stdcall;

    /// <summary>
    ///   Declares a floating point constant (extended) in the current unit
    /// </summary>
    function AddConstantDouble(AName: PAnsiChar; AValue: Double): Integer; stdcall;

    /// <summary>
    ///   Declares a string constant in the current unit
    /// </summary>
    function AddConstantString(AName, AValue: PAnsiChar): Integer; stdcall;

    /// <summary>
    ///   Compiles ASource (ANSI text, ASourceSize bytes, no terminator needed)
    ///   into bytecode. ADestSize is the size of ADest on input and the size
    ///   of the bytecode on output
    /// </summary>
    /// <returns>
    ///   SCRIPT_OK; SCRIPT_ERROR_COMPILE if the source has errors (messages
    ///   available, bytecode not produced); SCRIPT_ERROR_BUFFER if ADest is
    ///   nil or too small, and then ADestSize is the size needed (call again
    ///   with a buffer of that size and the same source: the compiled code is
    ///   kept until the next call that completes, the source is not compiled
    ///   twice); SCRIPT_ERROR_ARGUMENT; or another error code.
    ///   The messages of the last compilation (errors, warnings and hints) are
    ///   readable after any of these results
    /// </returns>
    function Compile(ASource: Pointer; ASourceSize: Cardinal; ADest: Pointer;
      var ADestSize: Cardinal): Integer; stdcall;

    /// <summary>
    ///   Number of messages of the last compilation
    /// </summary>
    function GetMessageCount(out ACount: Cardinal): Integer; stdcall;

    /// <summary>
    ///   Kind and position of message AIndex (zero based) and its text, a
    ///   zero terminated ANSI string copied in AText. ATextSize is the size of
    ///   AText on input and the size needed (zero included) on output
    /// </summary>
    /// <returns>
    ///   SCRIPT_OK; SCRIPT_ERROR_BUFFER if AText is nil or too small (AInfo is
    ///   filled anyway); SCRIPT_ERROR_ARGUMENT if AIndex does not exist
    /// </returns>
    function GetMessageInfo(AIndex: Cardinal; out AInfo: TScriptMessageInfo;
      AText: PAnsiChar; var ATextSize: Cardinal): Integer; stdcall;
  end;

  /// <summary>
  ///   Runs bytecode: calls its procedures and reads and writes its global
  ///   variables
  /// </summary>
  /// <remarks>
  ///   Host functions: the application passes, for each function, the same
  ///   declaration given to the compiler, the address of the function and its
  ///   calling convention (SCRIPT_CALL_*). The engine functions use the Delphi
  ///   register convention (SCRIPT_CALL_REGISTER) and the script type "string"
  ///   is an AnsiString. A function of the application is called by the DLL
  ///   with the arguments laid out as a Delphi call of that convention would:
  ///   parameters of type string reach it as a pointer to a reference counted
  ///   AnsiString that it must only read (declare them const). A function that
  ///   RETURNS a string, or that changes a var string, allocates memory the
  ///   DLL will free: it works only if the application and the DLL share the
  ///   memory manager (ShareMem or the same FastMM instance); otherwise use
  ///   Integer, Double and PAnsiChar parameters and results.
  ///   An instance must be used from one thread at a time
  /// </remarks>
  IScriptExecutor = interface
    ['{E1A94B07-3D52-4C8A-B6F0-72D5A8C1394E}']

    /// <summary>
    ///   Registers a function of the application. Must be called before
    ///   LoadBytecode, for every host function the bytecode uses
    /// </summary>
    /// <remarks>
    ///   Memory: when the library runs inside DDScript.dll, a function that
    ///   returns a string, an array or a variant, or takes one as var or out,
    ///   would allocate on one heap and free on the other, so it is refused.
    ///   Give the strings by value (the Delphi parameter is const) and use
    ///   Integer, Double and PAnsiChar for the results. The DLL accepts them if it is built
    ///   with the symbol SCRIPT_SHARED_MEMORY, which requires the application
    ///   and the DLL to share the memory manager (ShareMem or the same FastMM
    ///   instance). The library linked into the executable has no limit
    /// </remarks>
    /// <returns>
    ///   SCRIPT_OK; SCRIPT_ERROR_ARGUMENT for a nil text or address, an
    ///   invalid declaration, an unknown convention, a duplicate name or a
    ///   function the DLL cannot call safely (see the remarks);
    ///   SCRIPT_ERROR_STATE if the bytecode is already loaded
    /// </returns>
    function AddHostFunction(ADeclaration: PAnsiChar; AAddress: Pointer;
      AConvention: Integer): Integer; stdcall;

    /// <summary>
    ///   Loads bytecode produced by IScriptCompiler.Compile, replacing the
    ///   one loaded before (its global variables are lost). Does not run
    ///   anything
    /// </summary>
    /// <returns>
    ///   SCRIPT_OK; SCRIPT_ERROR_LOAD if the data is not valid bytecode or
    ///   uses a host function that was not registered (GetLastErrorText says
    ///   which)
    /// </returns>
    function LoadBytecode(ABytecode: Pointer; ABytecodeSize: Cardinal): Integer; stdcall;

    /// <summary>
    ///   Runs the main block of the script (the begin..end. of the program),
    ///   which initializes the global variables
    /// </summary>
    function RunMain: Integer; stdcall;

    /// <summary>
    ///   Calls the procedure or function AName (case insensitive) with
    ///   AArgumentCount values taken from the array AArguments, in the order
    ///   of the declaration. AResult receives the result; see TScriptValue
    ///   for the text results
    /// </summary>
    /// <returns>
    ///   SCRIPT_OK; SCRIPT_ERROR_NOTFOUND; SCRIPT_ERROR_TYPE for a wrong
    ///   number of arguments or an argument the parameter cannot take;
    ///   SCRIPT_ERROR_RUNTIME if the script stopped with an error
    ///   (GetLastErrorText); SCRIPT_ERROR_BUFFER for a text result that does
    ///   not fit; SCRIPT_ERROR_STATE if nothing is loaded
    /// </returns>
    function CallProcedure(AName: PAnsiChar; AArguments: PScriptValue;
      AArgumentCount: Cardinal; var AResult: TScriptValue): Integer; stdcall;

    /// <summary>
    ///   Text result of the last call, copied in ABuffer. ABufferSize is the
    ///   size of ABuffer on input and the size needed (zero included) on
    ///   output
    /// </summary>
    function GetResultText(ABuffer: PAnsiChar; var ABufferSize: Cardinal): Integer; stdcall;

    /// <summary>
    ///   Value of the global variable AName of the script (any integer type)
    /// </summary>
    function GetGlobalInteger(AName: PAnsiChar; out AValue: Int64): Integer; stdcall;

    /// <summary>
    ///   Assigns the global variable AName of the script (any integer type)
    /// </summary>
    function SetGlobalInteger(AName: PAnsiChar; AValue: Int64): Integer; stdcall;

    /// <summary>
    ///   Number of the global variables the application can reach by name
    /// </summary>
    function GetGlobalCount(out ACount: Cardinal): Integer; stdcall;

    /// <summary>
    ///   Kind (SCRIPT_GLOBAL_*) and name (upper case) of global variable
    ///   AIndex, zero based. ANameSize is the size of AName on input and the
    ///   size needed (zero included) on output
    /// </summary>
    function GetGlobalInfo(AIndex: Cardinal; out AKind: Integer;
      AName: PAnsiChar; var ANameSize: Cardinal): Integer; stdcall;

    function GetGlobalDouble(AName: PAnsiChar; out AValue: Double): Integer; stdcall;
    function SetGlobalDouble(AName: PAnsiChar; AValue: Double): Integer; stdcall;

    /// <summary>
    ///   Reads and assigns a global variable of type string or char; the
    ///   buffer rules are those of GetResultText
    /// </summary>
    function GetGlobalText(AName: PAnsiChar; ABuffer: PAnsiChar;
      var ABufferSize: Cardinal): Integer; stdcall;
    function SetGlobalText(AName, AValue: PAnsiChar): Integer; stdcall;

    /// <summary>
    ///   Sets the handlers called while the script runs; nil removes one. The
    ///   handlers survive a new LoadBytecode
    /// </summary>
    function SetEventHandlers(ARunLine: TScriptRunLineHandler;
      AException: TScriptExceptionHandler; AUserData: Pointer): Integer; stdcall;

    /// <summary>
    ///   Text of the last error of LoadBytecode, RunMain or CallProcedure,
    ///   copied in ABuffer (same rules as GetResultText)
    /// </summary>
    function GetLastErrorText(ABuffer: PAnsiChar; var ABufferSize: Cardinal): Integer; stdcall;
  end;

  /// <summary>
  ///   Root of the DLL: creates compilers and executors. Every object created
  ///   must be released before the DLL is unloaded
  /// </summary>
  IScriptLibrary = interface
    ['{9D3B6F28-1A47-4E05-8C92-F4E07B5A1D36}']
    function CreateCompiler(out ACompiler: IScriptCompiler): Integer; stdcall;
    function CreateExecutor(out AExecutor: IScriptExecutor): Integer; stdcall;
  end;

  /// <summary>
  ///   Signature of the export DDSCRIPT_CREATE_EXPORT of the DLL. Returns
  ///   SCRIPT_OK and an IScriptLibrary on success
  /// </summary>
  TDDScriptCreate = function(out ALibrary: IScriptLibrary): Integer; stdcall;

  /// <summary>
  ///   Raised by the classes that wrap the DLL
  /// </summary>
  EScriptException = class(Exception)
  private
    FCode: Integer;
  public
    constructor CreateCode(ACode: Integer); overload;
    constructor CreateCode(ACode: Integer; const ADetail: string); overload;
    class function TextOf(ACode: Integer): string; static;
    property Code: Integer read FCode;
  end;

implementation

{ EScriptException }

constructor EScriptException.CreateCode(ACode: Integer);
begin
  FCode := ACode;
  inherited CreateFmt('Script error %d: %s', [ACode, TextOf(ACode)]);
end;

constructor EScriptException.CreateCode(ACode: Integer; const ADetail: string);
begin
  FCode := ACode;
  inherited CreateFmt('Script error %d: %s (%s)', [ACode, TextOf(ACode), ADetail]);
end;

class function EScriptException.TextOf(ACode: Integer): string;
begin
  case ACode of
    SCRIPT_OK:             Result := 'OK';
    SCRIPT_ERROR_ARGUMENT: Result := 'Invalid argument';
    SCRIPT_ERROR_BUFFER:   Result := 'Buffer too small';
    SCRIPT_ERROR_COMPILE:  Result := 'Compilation failed';
    SCRIPT_ERROR_LOAD:     Result := 'Cannot load the bytecode';
    SCRIPT_ERROR_STATE:    Result := 'Invalid state';
    SCRIPT_ERROR_NOTFOUND: Result := 'Not found';
    SCRIPT_ERROR_RUNTIME:  Result := 'Script runtime error';
    SCRIPT_ERROR_TYPE:     Result := 'Type or argument count mismatch';
    SCRIPT_ERROR_MEMORY:   Result := 'Insufficient memory';
    SCRIPT_ERROR_INTERNAL: Result := 'Internal error';
  else
    Result := 'Unknown error';
  end;
end;

end.
