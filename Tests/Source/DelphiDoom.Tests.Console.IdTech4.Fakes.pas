{******************************************************************************}
{                                                                              }
{  DelphiDoom: fakes for the tests of the idTech 4 profile of the console      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.IdTech4.Fakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Console.CmdSystem.Intf;

type
  /// <summary>Records what the code prints (common->Printf) and warns</summary>
  TFakeIdLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FEntries: TStringList;
    FText: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
    /// <summary>Everything printed, as one text</summary>
    property Text: string read FText;
    /// <summary>One entry for each call: "P: text" or "W: text", the text escaped</summary>
    property Entries: TStringList read FEntries;
    procedure Clear;
    /// <summary>The text in one line: line feeds as \n, backslashes as \\, other control characters as \xNN</summary>
    class function Escape(const AText: string): string; static;
  end;

  TFakeSession = class(TInterfacedObject, IConsoleSession)
  public
    Multiplayer: Boolean;
    ClientActive: Boolean;
    function IsMultiplayer: Boolean;
    function IsNetworkClientActive: Boolean;
  end;

  /// <summary>Files in memory, by name (not case sensitive)</summary>
  TFakeIdFileSystem = class(TInterfacedObject, IIdLibFileSystem)
  strict private
    FFiles: TDictionary<string, AnsiString>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddFile(const AName: string; const AText: AnsiString);
    function TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean; out AFile: TIdLibFileData): Boolean;
    function WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
  end;

  /// <summary>
  ///   A list of names that answers ListFiles with the ones in the directory that end with the
  ///   extension ("/" lists the sub folders); counts how many times it was asked
  /// </summary>
  TFakeFileLister = class(TInterfacedObject, ICmdFileLister)
  strict private
    FNames: TStringList;
  public
    Calls: Integer;
    constructor Create;
    destructor Destroy; override;
    /// <summary>Names as the file system gives them (with the folder), a folder ends with "/"</summary>
    procedure AddName(const AName: string);
    function ListFiles(const ADirectory, AExtension: AnsiString; const ASort, AFullRelativePath: Boolean): TArray<AnsiString>;
  end;

implementation

{ TFakeIdLog }

constructor TFakeIdLog.Create;
begin
  inherited Create;
  FEntries := TStringList.Create;
end;

destructor TFakeIdLog.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

procedure TFakeIdLog.Printf(const AMessage: string);
begin
  FText := FText + AMessage;
  FEntries.Add('P: ' + Escape(AMessage));
end;

procedure TFakeIdLog.Warning(const AMessage: string);
begin
  FEntries.Add('W: ' + Escape(AMessage));
end;

procedure TFakeIdLog.Clear;
begin
  FText := '';
  FEntries.Clear;
end;

class function TFakeIdLog.Escape(const AText: string): string;
var
  LChar: Char;
begin
  Result := '';
  for LChar in AText do
    case LChar of
      '\': Result := Result + '\\';
      #10: Result := Result + '\n';
      #13: Result := Result + '\r';
      #9: Result := Result + '\t';
    else
      if (Ord(LChar) < 32) or (Ord(LChar) > 126) then
        Result := Result + '\x' + IntToHex(Ord(LChar) and $FF, 2)
      else
        Result := Result + LChar;
    end;
end;

{ TFakeSession }

function TFakeSession.IsMultiplayer: Boolean;
begin
  Result := Multiplayer;
end;

function TFakeSession.IsNetworkClientActive: Boolean;
begin
  Result := ClientActive;
end;

{ TFakeIdFileSystem }

constructor TFakeIdFileSystem.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, AnsiString>.Create;
end;

destructor TFakeIdFileSystem.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TFakeIdFileSystem.AddFile(const AName: string; const AText: AnsiString);
begin
  FFiles.AddOrSetValue(LowerCase(AName), AText);
end;

function TFakeIdFileSystem.TryReadFile(const AName: AnsiString; const AIsOsPath: Boolean;
  out AFile: TIdLibFileData): Boolean;
var
  LText: AnsiString;
begin
  Result := FFiles.TryGetValue(LowerCase(string(AName)), LText);
  if Result then
  begin
    SetLength(AFile.Data, Length(LText));
    if Length(LText) > 0 then
      Move(LText[1], AFile.Data[0], Length(LText));
    AFile.FullPath := AName;
    AFile.Timestamp := 0;
  end;
end;

function TFakeIdFileSystem.WriteFile(const AName: AnsiString; const AData: TBytes): Boolean;
begin
  Result := False;
end;

{ TFakeFileLister }

constructor TFakeFileLister.Create;
begin
  inherited Create;
  FNames := TStringList.Create;
end;

destructor TFakeFileLister.Destroy;
begin
  FNames.Free;
  inherited Destroy;
end;

procedure TFakeFileLister.AddName(const AName: string);
begin
  FNames.Add(AName);
end;

function TFakeFileLister.ListFiles(const ADirectory, AExtension: AnsiString; const ASort, AFullRelativePath: Boolean): TArray<AnsiString>;
var
  LName, LPrefix, LRest: string;
  LList: TStringList;
  LIndex: Integer;
begin
  Inc(Calls);
  LPrefix := LowerCase(string(ADirectory)) + '/';
  LList := TStringList.Create;
  try
    for LName in FNames do
    begin
      if not LowerCase(LName).StartsWith(LPrefix) then
        Continue;
      LRest := Copy(LName, Length(LPrefix) + 1, MaxInt);
      if string(AExtension) = '/' then
      begin
        // a sub folder: the name up to the first slash, once
        if (Pos('/', LRest) > 0) and (LList.IndexOf(string(ADirectory) + '/' + Copy(LRest, 1, Pos('/', LRest) - 1)) < 0) then
          LList.Add(string(ADirectory) + '/' + Copy(LRest, 1, Pos('/', LRest) - 1));
      end
      else if (Pos('/', LRest) = 0) and LowerCase(LName).EndsWith(LowerCase(string(AExtension))) then
        LList.Add(LName);
    end;
    if ASort then
      LList.Sort;
    SetLength(Result, LList.Count);
    for LIndex := 0 to LList.Count - 1 do
      Result[LIndex] := AnsiString(LList[LIndex]);
  finally
    LList.Free;
  end;
end;

end.
