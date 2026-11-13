{******************************************************************************}
{                                                                              }
{  DelphiDoom: test support of the bot AI library - fakes of the game side     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.BotAi.Support;

interface

uses
  System.SysUtils, System.Classes, System.Zip, System.Generics.Collections, DelphiDoom.BotAi.Import.Intf;

type
  /// <summary>A fake IBotImport that writes what the library prints, logs and sends as lines (P level|text, L|text, E client|command)</summary>
  TFakeBotImport = class(TInterfacedObject, IBotImport)
  strict private
    FLines: TStringList;
    FTime: Single;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
    procedure LogWrite(const AMessage: AnsiString);
    function Time: Single;
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
    /// <summary>Everything the library wrote since the last Clear, bytes below 32 and above 126 as \xNN</summary>
    property Lines: TStringList read FLines;
    property CurrentTime: Single read FTime write FTime;
  end;

  /// <summary>Files in memory by path (botfiles/syn.c)</summary>
  TMemoryBotFiles = class(TInterfacedObject, IBotFileSource)
  strict private
    FFiles: TDictionary<string, AnsiString>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const APath: string; const AText: AnsiString);
    function TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

  /// <summary>The files of a folder (Tests\Data\BotAi)</summary>
  TFolderBotFiles = class(TInterfacedObject, IBotFileSource)
  strict private
    FFolder: string;
  public
    constructor Create(const AFolder: string);
    function TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

  /// <summary>The files of a pk3 (a zip) by path</summary>
  TZipBotFiles = class(TInterfacedObject, IBotFileSource)
  strict private
    FZip: TZipFile;
  public
    constructor Create(const APk3: string);
    destructor Destroy; override;
    function TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
    /// <summary>The paths of the entries of the zip</summary>
    function Names: TArray<string>;
  end;

  /// <summary>A generator that gives the given numbers in turn (the last one for ever)</summary>
  TSequenceRandom = class(TInterfacedObject, IBotRandom)
  strict private
    FValues: TArray<Single>;
    FIndex: Integer;
  public
    constructor Create(const AValues: array of Single);
    function NextFloat: Single;
  end;

/// <summary>The text with bytes below 32, above 126 and the backslash as \xNN (as the C tool writes it)</summary>
function EscapeBotText(const AText: AnsiString): string;
/// <summary>The folder with the data of the tests of the library</summary>
function BotDataFolder: string;

implementation

uses
  System.IOUtils;

function EscapeBotText(const AText: AnsiString): string;
var
  LIndex: Integer;
  LByte: Byte;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
  begin
    LByte := Byte(AText[LIndex]);
    if (LByte < 32) or (LByte > 126) or (LByte = Ord('\')) then
      Result := Result + '\x' + IntToHex(LByte, 2)
    else
      Result := Result + Char(LByte);
  end;
end;

function BotDataFolder: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\Tests\Data\BotAi'));
end;

{ TFakeBotImport }

constructor TFakeBotImport.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TFakeBotImport.Destroy;
begin
  FLines.Free;
  inherited Destroy;
end;

procedure TFakeBotImport.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
  FLines.Add('P' + IntToStr(ALevel) + '|' + EscapeBotText(AMessage));
end;

procedure TFakeBotImport.LogWrite(const AMessage: AnsiString);
begin
  FLines.Add('L|' + EscapeBotText(AMessage));
end;

function TFakeBotImport.Time: Single;
begin
  Result := FTime;
end;

procedure TFakeBotImport.Command(const AClient: Integer; const ACommand: AnsiString);
begin
  FLines.Add('E|' + IntToStr(AClient) + '|' + EscapeBotText(ACommand));
end;

{ TMemoryBotFiles }

constructor TMemoryBotFiles.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, AnsiString>.Create;
end;

destructor TMemoryBotFiles.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TMemoryBotFiles.Add(const APath: string; const AText: AnsiString);
begin
  FFiles.AddOrSetValue(APath, AText);
end;

function TMemoryBotFiles.TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
var
  LText: AnsiString;
begin
  Result := FFiles.TryGetValue(string(APath), LText);
  if Result then
  begin
    SetLength(AData, Length(LText));
    if Length(LText) > 0 then
      Move(LText[1], AData[0], Length(LText));
  end;
end;

{ TFolderBotFiles }

constructor TFolderBotFiles.Create(const AFolder: string);
begin
  inherited Create;
  FFolder := AFolder;
end;

function TFolderBotFiles.TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
var
  LPath: string;
begin
  LPath := TPath.Combine(FFolder, StringReplace(string(APath), '/', '\', [rfReplaceAll]));
  Result := TFile.Exists(LPath);
  if Result then
    AData := TFile.ReadAllBytes(LPath);
end;

{ TZipBotFiles }

constructor TZipBotFiles.Create(const APk3: string);
begin
  inherited Create;
  FZip := TZipFile.Create;
  FZip.Open(APk3, zmRead);
end;

destructor TZipBotFiles.Destroy;
begin
  FZip.Free;
  inherited Destroy;
end;

function TZipBotFiles.TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
begin
  Result := FZip.IndexOf(string(APath)) >= 0;
  if Result then
    FZip.Read(string(APath), AData);
end;

function TZipBotFiles.Names: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, FZip.FileCount);
  for LIndex := 0 to FZip.FileCount - 1 do
    Result[LIndex] := FZip.FileNames[LIndex];
end;

{ TSequenceRandom }

constructor TSequenceRandom.Create(const AValues: array of Single);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FValues, Length(AValues));
  for LIndex := 0 to High(AValues) do
    FValues[LIndex] := AValues[LIndex];
end;

function TSequenceRandom.NextFloat: Single;
begin
  if Length(FValues) = 0 then
    Exit(0);
  Result := FValues[FIndex];
  if FIndex < High(FValues) then
    Inc(FIndex);
end;

end.
