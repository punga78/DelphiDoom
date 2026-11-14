{******************************************************************************}
{                                                                              }
{  DelphiDoom: helpers of the tests of the FLIC decoder (issue #199)           }
{                                                                              }
{  Builds small FLI/FLC files in memory and reads the data of the parity       }
{  tests (Tests\Data\Cinematic).                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Cinematic.FlicSupport;

interface

uses
  System.SysUtils,
  DelphiDoom.Imaging.Types,
  DelphiDoom.Cinematic.Flic.Types;

type
  /// <summary>Makes the bytes of a FLI/FLC file frame by frame</summary>
  TFlicTestBuilder = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FFli: Boolean;
    FSpeed: Integer;
    FBody: TBytes;
    FFrames: Integer;
    procedure Append(const AData: TBytes);
  public
    constructor Create(AWidth, AHeight: Integer; AFli: Boolean = False; ASpeed: Integer = 100);
    class function Bytes(const AValues: array of Byte): TBytes; static;
    class function Word16(AValue: Integer): TBytes; static;
    class function Concat(const AParts: array of TBytes): TBytes; static;
    /// <summary>Header of 6 bytes (size, type) and the data</summary>
    class function Chunk(AType: Word; const AData: TBytes): TBytes; static;
    /// <summary>COLOR_256 with one packet: ASkip colors skipped, then the colors (r, g, b each)</summary>
    class function Color256(ASkip: Integer; const ARgb: array of Byte): TBytes; static;
    /// <summary>COLOR_64 with one packet: the values are 6 bits</summary>
    class function Color64(ASkip: Integer; const ARgb: array of Byte): TBytes; static;
    /// <summary>BYTE_RUN: every row is one run of the value that the array has for it (the width must be 127 or less)</summary>
    class function ByteRun(AWidth: Integer; const ARowValues: array of Byte): TBytes; static;
    class function Literal(const APixels: TBytes): TBytes; static;
    class function Black: TBytes; static;
    /// <summary>A frame: the chunks and the delay (a FLI uses it when it is not 0)</summary>
    procedure Frame(const AChunks: array of TBytes; ADelay: Word = 0);
    procedure Prefix;
    /// <summary>A frame of type $AAAA with 4 bytes of data, as the videos of TFTD have</summary>
    procedure AudioFrame;
    /// <summary>The file; AHeaderFrames of -1 is the number of frames written</summary>
    function ToBytes(AHeaderFrames: Integer = -1): TBytes;
  end;

  /// <summary>Files of Tests\Data\Cinematic and of the data of Warcraft</summary>
  TFlicTestData = class
  public
    class function Path(const AFileName: string): string; static;
    class function ReadBytes(const AFileName: string): TBytes; static;
    class function ReadLines(const AFileName: string): TArray<string>; static;
    /// <summary>Warcraft: Orcs and Humans data folder (Reference\_dati\warcraft\DATA, or DELPHIDOOM_WAR_DATA), or empty if it is not there</summary>
    class function WarcraftFolder: string; static;
  end;

function IndicesCrc(const AIndices: TBytes): Cardinal;
function PaletteCrc(const APalette: TFlicPalette): Cardinal;

implementation

uses
  System.Classes, System.IOUtils,
  DelphiDoom.MathCore.Crc32;

{ TFlicTestBuilder }

constructor TFlicTestBuilder.Create(AWidth, AHeight: Integer; AFli: Boolean; ASpeed: Integer);
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
  FFli := AFli;
  FSpeed := ASpeed;
end;

class function TFlicTestBuilder.Bytes(const AValues: array of Byte): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AValues));
  for LIndex := 0 to High(AValues) do
    Result[LIndex] := AValues[LIndex];
end;

class function TFlicTestBuilder.Word16(AValue: Integer): TBytes;
begin
  Result := Bytes([AValue and $FF, (AValue shr 8) and $FF]);
end;

class function TFlicTestBuilder.Concat(const AParts: array of TBytes): TBytes;
var
  LIndex, LOld: Integer;
begin
  Result := nil;
  for LIndex := 0 to High(AParts) do
  begin
    LOld := Length(Result);
    SetLength(Result, LOld + Length(AParts[LIndex]));
    if Length(AParts[LIndex]) > 0 then
      Move(AParts[LIndex][0], Result[LOld], Length(AParts[LIndex]));
  end;
end;

class function TFlicTestBuilder.Chunk(AType: Word; const AData: TBytes): TBytes;
var
  LSize: Integer;
begin
  LSize := Length(AData) + 6;
  Result := Concat([Bytes([LSize and $FF, (LSize shr 8) and $FF, (LSize shr 16) and $FF,
    (LSize shr 24) and $FF]), Word16(AType), AData]);
end;

class function TFlicTestBuilder.Color256(ASkip: Integer; const ARgb: array of Byte): TBytes;
var
  LColors: Integer;
begin
  LColors := Length(ARgb) div 3;
  Result := Chunk(4, Concat([Word16(1), Bytes([ASkip, LColors and $FF]), Bytes(ARgb)]));
end;

class function TFlicTestBuilder.Color64(ASkip: Integer; const ARgb: array of Byte): TBytes;
var
  LColors: Integer;
begin
  LColors := Length(ARgb) div 3;
  Result := Chunk(11, Concat([Word16(1), Bytes([ASkip, LColors and $FF]), Bytes(ARgb)]));
end;

class function TFlicTestBuilder.ByteRun(AWidth: Integer; const ARowValues: array of Byte): TBytes;
var
  LRow: Integer;
  LData: TBytes;
begin
  LData := nil;
  for LRow := 0 to High(ARowValues) do
    LData := Concat([LData, Bytes([0, AWidth, ARowValues[LRow]])]);
  Result := Chunk(15, LData);
end;

class function TFlicTestBuilder.Literal(const APixels: TBytes): TBytes;
begin
  Result := Chunk(16, APixels);
end;

class function TFlicTestBuilder.Black: TBytes;
begin
  Result := Chunk(13, nil);
end;

procedure TFlicTestBuilder.Append(const AData: TBytes);
begin
  FBody := Concat([FBody, AData]);
end;

procedure TFlicTestBuilder.Frame(const AChunks: array of TBytes; ADelay: Word);
var
  LData: TBytes;
  LSize: Integer;
begin
  LData := Concat(AChunks);
  LSize := Length(LData) + FLIC_FRAME_HEADER_SIZE;
  Append(Concat([Bytes([LSize and $FF, (LSize shr 8) and $FF, (LSize shr 16) and $FF,
    (LSize shr 24) and $FF]), Word16($F1FA), Word16(Length(AChunks)), Word16(ADelay),
    Bytes([0, 0, 0, 0, 0, 0]), LData]));
  Inc(FFrames);
end;

procedure TFlicTestBuilder.Prefix;
begin
  Append(Concat([Bytes([FLIC_FRAME_HEADER_SIZE, 0, 0, 0]), Word16($F100), Bytes([0, 0, 0, 0, 0,
    0, 0, 0, 0, 0])]));
end;

procedure TFlicTestBuilder.AudioFrame;
begin
  Append(Concat([Bytes([4, 0, 0, 0]), Word16($AAAA), Bytes([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]),
    Bytes([1, 2, 3, 4])]));
end;

function TFlicTestBuilder.ToBytes(AHeaderFrames: Integer): TBytes;
var
  LHeader: TBytes;
  LSize: Integer;
  LType: Word;
begin
  if AHeaderFrames < 0 then
    AHeaderFrames := FFrames;
  LSize := FLIC_HEADER_SIZE + Length(FBody);
  if FFli then
    LType := FLIC_TYPE_FLI
  else
    LType := FLIC_TYPE_FLC;
  SetLength(LHeader, FLIC_HEADER_SIZE);
  LHeader[0] := LSize and $FF;
  LHeader[1] := (LSize shr 8) and $FF;
  LHeader[2] := (LSize shr 16) and $FF;
  LHeader[3] := (LSize shr 24) and $FF;
  LHeader[4] := LType and $FF;
  LHeader[5] := LType shr 8;
  LHeader[6] := AHeaderFrames and $FF;
  LHeader[7] := AHeaderFrames shr 8;
  LHeader[8] := FWidth and $FF;
  LHeader[9] := FWidth shr 8;
  LHeader[10] := FHeight and $FF;
  LHeader[11] := FHeight shr 8;
  LHeader[12] := 8;
  LHeader[16] := FSpeed and $FF;
  LHeader[17] := (FSpeed shr 8) and $FF;
  Result := Concat([LHeader, FBody]);
end;

{ TFlicTestData }

class function TFlicTestData.Path(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\Cinematic\' +
    AFileName);
end;

class function TFlicTestData.ReadBytes(const AFileName: string): TBytes;
begin
  Result := TFile.ReadAllBytes(Path(AFileName));
end;

class function TFlicTestData.ReadLines(const AFileName: string): TArray<string>;
begin
  Result := TFile.ReadAllLines(Path(AFileName));
end;

class function TFlicTestData.WarcraftFolder: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_WAR_DATA');
  if (Result <> '') and TDirectory.Exists(Result) then
    Exit;
  // from the folder of the exe up to the folder that has Reference\_dati\warcraft\DATA
  Result := ExtractFilePath(ParamStr(0));
  while Result <> '' do
  begin
    if TDirectory.Exists(Result + 'Reference\_dati\warcraft\DATA') then
      Exit(Result + 'Reference\_dati\warcraft\DATA');
    if ExcludeTrailingPathDelimiter(Result) = ExtractFileDrive(Result) then
      Break;
    Result := ExtractFilePath(ExcludeTrailingPathDelimiter(Result));
  end;
  Result := '';
end;

function IndicesCrc(const AIndices: TBytes): Cardinal;
begin
  Result := TCrc32.Calculate(AIndices[0], Length(AIndices));
end;

function PaletteCrc(const APalette: TFlicPalette): Cardinal;
var
  LBytes: array[0..767] of Byte;
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
  begin
    LBytes[LIndex * 3] := APalette[LIndex] and $FF;
    LBytes[LIndex * 3 + 1] := (APalette[LIndex] shr 8) and $FF;
    LBytes[LIndex * 3 + 2] := (APalette[LIndex] shr 16) and $FF;
  end;
  Result := TCrc32.Calculate(LBytes[0], SizeOf(LBytes));
end;

end.
