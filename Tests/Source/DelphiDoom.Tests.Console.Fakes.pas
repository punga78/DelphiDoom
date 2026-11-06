{******************************************************************************}
{                                                                              }
{  DelphiDoom: fakes for the tests of the console library                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Fakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Logging.Intf,
  DelphiDoom.GameState.Intf, DelphiDoom.Console.Types, DelphiDoom.Console.Intf;

type
  /// <summary>Keeps everything that is written, as the screen would show it</summary>
  TFakeOutput = class(TInterfacedObject, IConsoleOutput)
  private
    FText: string;
  public
    procedure Write(const AText: string);
    procedure Clear;
    property Text: string read FText;
  end;

  /// <summary>A log that writes the warnings in the output, with a mark, to see the order</summary>
  TFakeLog = class(TInterfacedObject, ILog)
  private
    FOutput: TFakeOutput;
  public
    constructor Create(AOutput: TFakeOutput);
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
  end;

  TFakeGameContext = class(TInterfacedObject, IGameContext)
  private
    FNetGame: Boolean;
  public
    function IsDeveloperMode: Boolean;
    function IsNetGame: Boolean;
    function IsDemoRecording: Boolean;
    function IsDemoPlayback: Boolean;
    function IsPaused: Boolean;
    function GameTic: Integer;
    property NetGame: Boolean read FNetGame write FNetGame;
  end;

  /// <summary>A variable that keeps its value in the object (the engine keeps it in a global)</summary>
  TFakeVariable = class(TInterfacedObject, IConsoleVariable)
  private
    FName: string;
    FKind: TConsoleVariableKind;
    FAccess: TConsoleAccess;
  public
    IntegerValue: Integer;
    BooleanValue: Boolean;
    StringValue: string;
    constructor Create(const AName: string; AKind: TConsoleVariableKind; AAccess: TConsoleAccess);
    function Name: string;
    function Kind: TConsoleVariableKind;
    function Access: TConsoleAccess;
    function GetInteger: Integer;
    procedure SetInteger(AValue: Integer);
    function GetBoolean: Boolean;
    procedure SetBoolean(AValue: Boolean);
    function GetString: string;
    procedure SetString(const AValue: string);
  end;

  TFakeVariableSource = class(TInterfacedObject, IConsoleVariableSource)
  private
    FVariables: TList<IConsoleVariable>;
  public
    constructor Create;
    destructor Destroy; override;
    function AddInteger(const AName: string; AAccess: TConsoleAccess; AValue: Integer): TFakeVariable;
    function AddBoolean(const AName: string; AAccess: TConsoleAccess; AValue: Boolean): TFakeVariable;
    function AddString(const AName: string; AAccess: TConsoleAccess; const AValue: string): TFakeVariable;
    function Count: Integer;
    function Item(AIndex: Integer): IConsoleVariable;
    function Find(const AName: string): IConsoleVariable;
  end;

  /// <summary>Files from a dictionary of names and lines, or from a folder when a name is not there</summary>
  TFakeFileSystem = class(TInterfacedObject, IConsoleFileSystem)
  private
    FBaseFolder: string;
    FFiles: TDictionary<string, TArray<string>>;
  public
    /// <summary>ABaseFolder may be empty: then only the files added are known</summary>
    constructor Create(const ABaseFolder: string);
    destructor Destroy; override;
    procedure AddFile(const AFileName: string; const ALines: TArray<string>);
    function ExpandFileName(const AFileName: string): string;
    function FileExists(const AFileName: string): Boolean;
    function ReadLines(const AFileName: string): TArray<string>;
  end;

  /// <summary>A runner that only remembers what it was asked to run, in the order</summary>
  TRecordingRunner = class(TInterfacedObject, IConsoleScriptRunner)
  public
    Calls: string;
    Files: string;
    procedure RunFile(const AFileName: string);
    procedure RunText(const AText: string);
  end;

  TFakeStartupSource = class(TInterfacedObject, IConsoleStartupSource)
  public
    AutoExec: string;
    DefaultExists: Boolean;
    LumpTexts: TArray<string>;
    CommandLineFile: string;
    CreatedLines: TArray<string>;
    function AutoExecFileName: string;
    function DefaultAutoExecExists: Boolean;
    procedure CreateDefaultAutoExec(const ALines: TArray<string>);
    function AutoExecLumpTexts: TArray<string>;
    function CommandLineFileName: string;
  end;

implementation

uses
  System.IOUtils;

{ TFakeOutput }

procedure TFakeOutput.Write(const AText: string);
begin
  FText := FText + AText;
end;

procedure TFakeOutput.Clear;
begin
  FText := '';
end;

{ TFakeLog }

constructor TFakeLog.Create(AOutput: TFakeOutput);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TFakeLog.Info(const AText: string);
begin
  FOutput.Write(AText);
end;

procedure TFakeLog.Warning(const AText: string);
begin
  FOutput.Write('[warn] ' + AText);
end;

procedure TFakeLog.DevWarning(const AText: string);
begin
  FOutput.Write('[devwarn] ' + AText);
end;

procedure TFakeLog.Error(const AText: string);
begin
  FOutput.Write('[error] ' + AText);
end;

{ TFakeGameContext }

function TFakeGameContext.IsDeveloperMode: Boolean;
begin
  Result := False;
end;

function TFakeGameContext.IsNetGame: Boolean;
begin
  Result := FNetGame;
end;

function TFakeGameContext.IsDemoRecording: Boolean;
begin
  Result := False;
end;

function TFakeGameContext.IsDemoPlayback: Boolean;
begin
  Result := False;
end;

function TFakeGameContext.IsPaused: Boolean;
begin
  Result := False;
end;

function TFakeGameContext.GameTic: Integer;
begin
  Result := 0;
end;

{ TFakeVariable }

constructor TFakeVariable.Create(const AName: string; AKind: TConsoleVariableKind;
  AAccess: TConsoleAccess);
begin
  inherited Create;
  FName := AName;
  FKind := AKind;
  FAccess := AAccess;
end;

function TFakeVariable.Name: string;
begin
  Result := FName;
end;

function TFakeVariable.Kind: TConsoleVariableKind;
begin
  Result := FKind;
end;

function TFakeVariable.Access: TConsoleAccess;
begin
  Result := FAccess;
end;

function TFakeVariable.GetInteger: Integer;
begin
  Result := IntegerValue;
end;

procedure TFakeVariable.SetInteger(AValue: Integer);
begin
  IntegerValue := AValue;
end;

function TFakeVariable.GetBoolean: Boolean;
begin
  Result := BooleanValue;
end;

procedure TFakeVariable.SetBoolean(AValue: Boolean);
begin
  BooleanValue := AValue;
end;

function TFakeVariable.GetString: string;
begin
  Result := StringValue;
end;

procedure TFakeVariable.SetString(const AValue: string);
begin
  StringValue := AValue;
end;

{ TFakeVariableSource }

constructor TFakeVariableSource.Create;
begin
  inherited Create;
  FVariables := TList<IConsoleVariable>.Create;
end;

destructor TFakeVariableSource.Destroy;
begin
  FVariables.Free;
  inherited Destroy;
end;

function TFakeVariableSource.AddInteger(const AName: string; AAccess: TConsoleAccess;
  AValue: Integer): TFakeVariable;
begin
  Result := TFakeVariable.Create(AName, cvkInteger, AAccess);
  Result.IntegerValue := AValue;
  FVariables.Add(Result);
end;

function TFakeVariableSource.AddBoolean(const AName: string; AAccess: TConsoleAccess;
  AValue: Boolean): TFakeVariable;
begin
  Result := TFakeVariable.Create(AName, cvkBoolean, AAccess);
  Result.BooleanValue := AValue;
  FVariables.Add(Result);
end;

function TFakeVariableSource.AddString(const AName: string; AAccess: TConsoleAccess;
  const AValue: string): TFakeVariable;
begin
  Result := TFakeVariable.Create(AName, cvkString, AAccess);
  Result.StringValue := AValue;
  FVariables.Add(Result);
end;

function TFakeVariableSource.Count: Integer;
begin
  Result := FVariables.Count;
end;

function TFakeVariableSource.Item(AIndex: Integer): IConsoleVariable;
begin
  Result := FVariables[AIndex];
end;

function TFakeVariableSource.Find(const AName: string): IConsoleVariable;
var
  LVariable: IConsoleVariable;
begin
  for LVariable in FVariables do
    if LVariable.Name = AName then
      Exit(LVariable);
  Result := nil;
end;

{ TFakeFileSystem }

constructor TFakeFileSystem.Create(const ABaseFolder: string);
begin
  inherited Create;
  FBaseFolder := ABaseFolder;
  FFiles := TDictionary<string, TArray<string>>.Create;
end;

destructor TFakeFileSystem.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TFakeFileSystem.AddFile(const AFileName: string; const ALines: TArray<string>);
begin
  FFiles.AddOrSetValue(UpperCase(AFileName), ALines);
end;

function TFakeFileSystem.ExpandFileName(const AFileName: string): string;
begin
  if FBaseFolder = '' then
    Result := AFileName
  else
    Result := System.SysUtils.ExpandFileName(IncludeTrailingPathDelimiter(FBaseFolder) + AFileName);
end;

function TFakeFileSystem.FileExists(const AFileName: string): Boolean;
begin
  Result := FFiles.ContainsKey(UpperCase(AFileName)) or
    ((FBaseFolder <> '') and System.SysUtils.FileExists(AFileName));
end;

function TFakeFileSystem.ReadLines(const AFileName: string): TArray<string>;
var
  LLines: TStringList;
begin
  if FFiles.TryGetValue(UpperCase(AFileName), Result) then
    Exit;
  LLines := TStringList.Create;
  try
    if System.SysUtils.FileExists(AFileName) then
      LLines.LoadFromFile(AFileName);
    Result := LLines.ToStringArray;
  finally
    LLines.Free;
  end;
end;

{ TRecordingRunner }

procedure TRecordingRunner.RunFile(const AFileName: string);
begin
  Files := Files + '[' + AFileName + ']';
  Calls := Calls + 'file(' + AFileName + ') ';
end;

procedure TRecordingRunner.RunText(const AText: string);
begin
  Calls := Calls + 'text(' + AText + ') ';
end;

{ TFakeStartupSource }

function TFakeStartupSource.AutoExecFileName: string;
begin
  Result := AutoExec;
end;

function TFakeStartupSource.DefaultAutoExecExists: Boolean;
begin
  Result := DefaultExists;
end;

procedure TFakeStartupSource.CreateDefaultAutoExec(const ALines: TArray<string>);
begin
  CreatedLines := ALines;
end;

function TFakeStartupSource.AutoExecLumpTexts: TArray<string>;
begin
  Result := LumpTexts;
end;

function TFakeStartupSource.CommandLineFileName: string;
begin
  Result := CommandLineFile;
end;

end.
