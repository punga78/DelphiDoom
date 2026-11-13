{******************************************************************************}
{                                                                              }
{  DelphiDoom: fakes for the tests of the Quake III profile of the console     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf;

type
  /// <summary>Collects what Com_Printf and Com_DPrintf get</summary>
  TFakeQ3Log = class(TInterfacedObject, IQ3ConsoleLog)
  strict private
    FPrinted: string;
    FDeveloper: string;
  public
    procedure Print(const AText: string);
    procedure DevPrint(const AText: string);
    /// <summary>The printed text so far; empties it</summary>
    function TakePrinted: string;
    /// <summary>The developer text so far; empties it</summary>
    function TakeDeveloper: string;
    property Printed: string read FPrinted;
    property Developer: string read FDeveloper;
  end;

  /// <summary>A registry that only records the lines it is asked to run</summary>
  TFakeQ3Registry = class(TInterfacedObject, IQ3CommandRegistry)
  strict private
    FLines: TArray<AnsiString>;
  public
    procedure AddCommand(const AName: AnsiString; const AFunction: TQ3CommandFunction);
    procedure RemoveCommand(const AName: AnsiString);
    procedure ExecuteString(const AText: AnsiString);
    function CommandNames: TArray<AnsiString>;
    property Lines: TArray<AnsiString> read FLines;
  end;

  /// <summary>Files by exact name</summary>
  TFakeQ3Files = class(TInterfacedObject, IQ3FileSystem)
  strict private
    FFiles: TDictionary<AnsiString, AnsiString>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddFile(const AName, AText: AnsiString);
    function TryReadFile(const AName: AnsiString; out AText: AnsiString): Boolean;
  end;

  /// <summary>The unhandled lines, as the stub of the parity driver: "forward text"</summary>
  TFakeQ3Unhandled = class(TInterfacedObject, IQ3UnhandledCommands)
  strict private
    FLog: IQ3ConsoleLog;
    FLines: TArray<AnsiString>;
  public
    constructor Create(const ALog: IQ3ConsoleLog);
    function Execute(const AText: AnsiString): Boolean;
    property Lines: TArray<AnsiString> read FLines;
  end;

  /// <summary>
  ///   The info string writer of the tests: the same effect as Info_SetValueForKey on valid text (no length
  ///   limit): refuses a backslash, a semicolon and a quote with the messages of the original, removes the
  ///   old pair, an empty value removes only, the normal variant puts the pair first and the Big one last
  /// </summary>
  TFakeQ3InfoWriter = class(TInterfacedObject, IQ3InfoStringWriter)
  strict private
    FLog: IQ3ConsoleLog;
    class procedure RemovePair(var AInfo: AnsiString; const AKey: AnsiString); static;
    class function Has(const ATexts: array of AnsiString; AChar: AnsiChar): Boolean; static;
  public
    constructor Create(const ALog: IQ3ConsoleLog);
    function SetValueForKey(var AInfo: AnsiString; const AKey, AValue: AnsiString; ABig: Boolean): Boolean;
  end;

implementation

{ TFakeQ3Log }

procedure TFakeQ3Log.Print(const AText: string);
begin
  FPrinted := FPrinted + AText;
end;

procedure TFakeQ3Log.DevPrint(const AText: string);
begin
  FDeveloper := FDeveloper + AText;
end;

function TFakeQ3Log.TakePrinted: string;
begin
  Result := FPrinted;
  FPrinted := '';
end;

function TFakeQ3Log.TakeDeveloper: string;
begin
  Result := FDeveloper;
  FDeveloper := '';
end;

{ TFakeQ3Registry }

procedure TFakeQ3Registry.AddCommand(const AName: AnsiString; const AFunction: TQ3CommandFunction);
begin
end;

procedure TFakeQ3Registry.RemoveCommand(const AName: AnsiString);
begin
end;

procedure TFakeQ3Registry.ExecuteString(const AText: AnsiString);
begin
  SetLength(FLines, Length(FLines) + 1);
  FLines[High(FLines)] := AText;
end;

function TFakeQ3Registry.CommandNames: TArray<AnsiString>;
begin
  Result := nil;
end;

{ TFakeQ3Files }

constructor TFakeQ3Files.Create;
begin
  inherited Create;
  FFiles := TDictionary<AnsiString, AnsiString>.Create;
end;

destructor TFakeQ3Files.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TFakeQ3Files.AddFile(const AName, AText: AnsiString);
begin
  FFiles.AddOrSetValue(AName, AText);
end;

function TFakeQ3Files.TryReadFile(const AName: AnsiString; out AText: AnsiString): Boolean;
begin
  Result := FFiles.TryGetValue(AName, AText);
end;

{ TFakeQ3Unhandled }

constructor TFakeQ3Unhandled.Create(const ALog: IQ3ConsoleLog);
begin
  inherited Create;
  FLog := ALog;
end;

function TFakeQ3Unhandled.Execute(const AText: AnsiString): Boolean;
begin
  SetLength(FLines, Length(FLines) + 1);
  FLines[High(FLines)] := AText;
  if Assigned(FLog) then
    FLog.Print('forward ' + string(AText) + #10);
  Result := False;
end;

{ TFakeQ3InfoWriter }

constructor TFakeQ3InfoWriter.Create(const ALog: IQ3ConsoleLog);
begin
  inherited Create;
  FLog := ALog;
end;

class function TFakeQ3InfoWriter.Has(const ATexts: array of AnsiString; AChar: AnsiChar): Boolean;
var
  LText: AnsiString;
  LIndex: Integer;
begin
  Result := False;
  for LText in ATexts do
    for LIndex := 1 to Length(LText) do
      if LText[LIndex] = AChar then
        Exit(True);
end;

class procedure TFakeQ3InfoWriter.RemovePair(var AInfo: AnsiString; const AKey: AnsiString);
var
  LParts: TArray<string>;
  LIndex: Integer;
  LResult: string;
begin
  LParts := string(AInfo).Split(['\']);
  LResult := '';
  // the text starts with a backslash: the first part is empty, then key, value, key, value...
  LIndex := 1;
  while LIndex < Length(LParts) do
  begin
    if LParts[LIndex] <> string(AKey) then
    begin
      LResult := LResult + '\' + LParts[LIndex] + '\';
      if LIndex + 1 < Length(LParts) then
        LResult := LResult + LParts[LIndex + 1];
    end;
    Inc(LIndex, 2);
  end;
  AInfo := AnsiString(LResult);
end;

function TFakeQ3InfoWriter.SetValueForKey(var AInfo: AnsiString; const AKey, AValue: AnsiString;
  ABig: Boolean): Boolean;
begin
  Result := False;
  if Has([AKey, AValue], '\') then
    FLog.Print('Can''t use keys or values with a \'#10)
  else if Has([AKey, AValue], ';') then
    FLog.Print('Can''t use keys or values with a semicolon'#10)
  else if Has([AKey, AValue], '"') then
    FLog.Print('Can''t use keys or values with a "'#10)
  else
  begin
    RemovePair(AInfo, AKey);
    Result := True;
    if AValue = '' then
      Exit;
    if ABig then
      AInfo := AInfo + '\' + AKey + '\' + AValue
    else
      AInfo := '\' + AKey + '\' + AValue + AInfo;
  end;
end;

end.
