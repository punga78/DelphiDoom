{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - fakes and helpers                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.Support;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf;

type
  /// <summary>The game side: keeps what the library prints (and also writes it to a list if given one)</summary>
  TFakeImport = class(TInterfacedObject, IBotImport)
  strict private
    FLevels: TArray<Integer>;
    FMessages: TArray<string>;
    FOutput: TStrings;
  public
    constructor Create(const AOutput: TStrings = nil);
    procedure Print(const ALevel: Integer; const AMessage: AnsiString);
    procedure LogWrite(const AMessage: AnsiString);
    function Time: Single;
    procedure Command(const AClient: Integer; const ACommand: AnsiString);
    function Count: Integer;
    function Level(const AIndex: Integer): Integer;
    function Message(const AIndex: Integer): string;
  end;

  /// <summary>One file in memory</summary>
  TFakeFiles = class(TInterfacedObject, IBotFileSource)
  strict private
    FName: AnsiString;
    FData: TBytes;
  public
    constructor Create(const AName: AnsiString; const AData: TBytes);
    function TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

  /// <summary>The library variables: only the checksum of the BSP</summary>
  TFakeLibVars = class(TInterfacedObject, IBotLibVars)
  strict private
    FChecksum: AnsiString;
  public
    constructor Create(const AChecksum: AnsiString);
    function GetValue(const AName: AnsiString): Single;
    function GetValueOrCreate(const AName, ADefault: AnsiString): Single;
    function GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
  end;

function Vec(const X, Y, Z: Single): TVec3;
function Bits(const AValue: Single): Cardinal;
function Hex(const AValue: Cardinal): string;
/// <summary>The bytes below 32, above 126 and the backslash as \xNN, as the tool of the C does</summary>
function Escaped(const AText: string): string;

implementation

function Vec(const X, Y, Z: Single): TVec3;
begin
  Result[0] := X;
  Result[1] := Y;
  Result[2] := Z;
end;

function Bits(const AValue: Single): Cardinal;
begin
  Move(AValue, Result, SizeOf(Result));
end;

function Hex(const AValue: Cardinal): string;
begin
  Result := LowerCase(IntToHex(AValue, 8));
end;

function Escaped(const AText: string): string;
var
  LChar: Char;
begin
  Result := '';
  for LChar in AText do
    if (Ord(LChar) < 32) or (Ord(LChar) > 126) or (LChar = '\') then
      Result := Result + '\x' + UpperCase(IntToHex(Ord(LChar), 2))
    else
      Result := Result + LChar;
end;

{ TFakeImport }

constructor TFakeImport.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TFakeImport.Print(const ALevel: Integer; const AMessage: AnsiString);
begin
  FLevels := FLevels + [ALevel];
  FMessages := FMessages + [string(AMessage)];
  if Assigned(FOutput) then
    FOutput.Add('P' + IntToStr(ALevel) + '|' + Escaped(string(AMessage)));
end;

procedure TFakeImport.LogWrite(const AMessage: AnsiString);
begin
end;

function TFakeImport.Time: Single;
begin
  Result := 0;
end;

procedure TFakeImport.Command(const AClient: Integer; const ACommand: AnsiString);
begin
end;

function TFakeImport.Count: Integer;
begin
  Result := Length(FMessages);
end;

function TFakeImport.Level(const AIndex: Integer): Integer;
begin
  Result := FLevels[AIndex];
end;

function TFakeImport.Message(const AIndex: Integer): string;
begin
  Result := FMessages[AIndex];
end;

{ TFakeFiles }

constructor TFakeFiles.Create(const AName: AnsiString; const AData: TBytes);
begin
  inherited Create;
  FName := AName;
  FData := AData;
end;

function TFakeFiles.TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
begin
  Result := APath = FName;
  if Result then
    AData := FData
  else
    AData := nil;
end;

{ TFakeLibVars }

constructor TFakeLibVars.Create(const AChecksum: AnsiString);
begin
  inherited Create;
  FChecksum := AChecksum;
end;

function TFakeLibVars.GetValue(const AName: AnsiString): Single;
begin
  Result := 0;
end;

function TFakeLibVars.GetValueOrCreate(const AName, ADefault: AnsiString): Single;
begin
  Result := 0;
end;

function TFakeLibVars.GetStringOrCreate(const AName, ADefault: AnsiString): AnsiString;
begin
  if AName = 'sv_mapChecksum' then
    Result := FChecksum
  else
    Result := ADefault;
end;

end.
