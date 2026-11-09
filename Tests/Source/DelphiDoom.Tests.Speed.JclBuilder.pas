{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the speed library - containers made in memory          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The same unit is compiled by the harness that ran the old translator of     }
{  the fork (outside the repository) to write the golden of the synthetic      }
{  game, and by the tests: both make the same bytes                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.JclBuilder;

{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  /// <summary>A file of the container: a name, its bytes and the size that the directory declares</summary>
  TJclBuilderFile = record
    Name: string;
    Data: TBytes;
    DeclaredSize: Integer;
  end;

  /// <summary>
  ///   Writes a JCL container: the data one after the other, then the directory (32 bytes a file,
  ///   the start is a distance back from the start of the directory) and at the end the header
  /// </summary>
  TJclBuilder = class
  strict private
    FFiles: TList<TJclBuilderFile>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName: string; const AData: TBytes);
    /// <summary>A file whose declared size is not the size of its data</summary>
    procedure AddWithDeclaredSize(const AName: string; const AData: TBytes; ADeclaredSize: Integer);
    function Build: TBytes;
    /// <summary>Count bytes of a linear congruential generator, each and-ed with AMask</summary>
    class function RandomBytes(ASeed: Cardinal; ACount: Integer; AMask: Byte): TBytes; static;
    /// <summary>An .IS2 picture: runs of pixels with gaps between them, a line per column (or per row)</summary>
    class function Is2(ASeed: Cardinal; AWidth, AHeight: Integer; AHorizontal: Boolean): TBytes; static;
    /// <summary>A .DAT file of a circuit: the tiles, their angles and ThingCount things</summary>
    class function MapFile(ASeed: Cardinal; ATileCount, AThingCount: Integer): TBytes; static;
    /// <summary>A .SEC file with the vertices and the walls of a circuit</summary>
    class function SectorFile(ASeed: Cardinal; AVertices, ASectors: Integer): TBytes; static;
    /// <summary>A .PTH file with ACount points of the path</summary>
    class function PathFile(ASeed: Cardinal; ACount: Integer): TBytes; static;
    /// <summary>The text of CIRCUITS.LST for ACount circuits</summary>
    class function CircuitsText(ACount: Integer): TBytes; static;
    /// <summary>A small game with everything that the translator looks for (some of it missing on purpose)</summary>
    class function SyntheticGame: TBytes; static;
    class function TextBytes(const AText: string): TBytes; static;
  end;

implementation

type
  TLcg = record
    State: Cardinal;
    function Next: Cardinal;
    function Below(ALimit: Integer): Integer;
  end;

function TLcg.Next: Cardinal;
begin
  State := State * 1664525 + 1013904223;
  Result := State shr 8;
end;

function TLcg.Below(ALimit: Integer): Integer;
begin
  Result := Integer(Next mod Cardinal(ALimit));
end;

{ TJclBuilder }

constructor TJclBuilder.Create;
begin
  inherited Create;
  FFiles := TList<TJclBuilderFile>.Create;
end;

destructor TJclBuilder.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TJclBuilder.Add(const AName: string; const AData: TBytes);
begin
  AddWithDeclaredSize(AName, AData, Length(AData));
end;

procedure TJclBuilder.AddWithDeclaredSize(const AName: string; const AData: TBytes; ADeclaredSize: Integer);
var
  LFile: TJclBuilderFile;
begin
  LFile.Name := AName;
  LFile.Data := AData;
  LFile.DeclaredSize := ADeclaredSize;
  FFiles.Add(LFile);
end;

function TJclBuilder.Build: TBytes;
var
  LPositions: TArray<Integer>;
  LIndex: Integer;
  LTotal: Integer;
  LDirectory: Integer;
  LRecord: Integer;
  LCharacter: Integer;
begin
  SetLength(LPositions, FFiles.Count);
  LTotal := 0;
  for LIndex := 0 to FFiles.Count - 1 do
  begin
    LPositions[LIndex] := LTotal;
    Inc(LTotal, Length(FFiles[LIndex].Data));
  end;
  LDirectory := LTotal;
  SetLength(Result, LDirectory + FFiles.Count * 32 + 16);
  FillChar(Result[0], Length(Result), 0);
  for LIndex := 0 to FFiles.Count - 1 do
  begin
    if Length(FFiles[LIndex].Data) > 0 then
      Move(FFiles[LIndex].Data[0], Result[LPositions[LIndex]], Length(FFiles[LIndex].Data));
    LRecord := LDirectory + LIndex * 32;
    for LCharacter := 1 to Length(FFiles[LIndex].Name) do
      Result[LRecord + LCharacter - 1] := Byte(Ord(FFiles[LIndex].Name[LCharacter]));
    PInteger(@Result[LRecord + 24])^ := LDirectory - LPositions[LIndex];
    PInteger(@Result[LRecord + 28])^ := FFiles[LIndex].DeclaredSize;
  end;
  PCardinal(@Result[Length(Result) - 16])^ := Cardinal($DF73B489);
  PInteger(@Result[Length(Result) - 12])^ := FFiles.Count;
  PInteger(@Result[Length(Result) - 8])^ := FFiles.Count;
  PInteger(@Result[Length(Result) - 4])^ := FFiles.Count * 32 + 16;
end;

class function TJclBuilder.TextBytes(const AText: string): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AText));
  for LIndex := 1 to Length(AText) do
    Result[LIndex - 1] := Byte(Ord(AText[LIndex]) and $FF);
end;

class function TJclBuilder.RandomBytes(ASeed: Cardinal; ACount: Integer; AMask: Byte): TBytes;
var
  LLcg: TLcg;
  LIndex: Integer;
begin
  LLcg.State := ASeed;
  SetLength(Result, ACount);
  for LIndex := 0 to ACount - 1 do
    Result[LIndex] := Byte(LLcg.Next) and AMask;
end;

class function TJclBuilder.Is2(ASeed: Cardinal; AWidth, AHeight: Integer; AHorizontal: Boolean): TBytes;
var
  LLcg: TLcg;
  LData: TBytes;
  LLines: Integer;
  LLength: Integer;
  LLine: Integer;
  LSegments: Integer;
  LSegment: Integer;
  LRun: Integer;
  LPixel: Integer;
  LHeader: array[0..23] of Byte;
  LFlags: Cardinal;

  procedure Put(AValue: Byte);
  begin
    SetLength(LData, Length(LData) + 1);
    LData[High(LData)] := AValue;
  end;

begin
  LLcg.State := ASeed;
  if AHorizontal then
    LLines := AHeight
  else
    LLines := AWidth;
  for LLine := 0 to LLines - 1 do
  begin
    Put(Byte(LLcg.Below(4)));
    LSegments := 1 + LLcg.Below(3);
    for LSegment := 0 to LSegments - 1 do
    begin
      if LSegment > 0 then
        Put(Byte(1 + LLcg.Below(3)));
      LRun := 1 + LLcg.Below(8);
      Put(Byte(LRun));
      for LPixel := 1 to LRun do
        Put(Byte(LLcg.Next));
    end;
    Put(0);
  end;
  LLength := Length(LData);
  FillChar(LHeader, SizeOf(LHeader), 0);
  PCardinal(@LHeader[0])^ := Cardinal(844319022);
  PWord(@LHeader[4])^ := AWidth;
  PWord(@LHeader[6])^ := AHeight;
  PSmallInt(@LHeader[8])^ := 1;
  PSmallInt(@LHeader[10])^ := 2;
  PWord(@LHeader[12])^ := 256;
  PWord(@LHeader[14])^ := 256;
  if AHorizontal then
    LFlags := 1
  else
    LFlags := 0;
  PCardinal(@LHeader[16])^ := LFlags;
  PInteger(@LHeader[20])^ := LLength;
  SetLength(Result, 24 + LLength);
  Move(LHeader[0], Result[0], 24);
  if LLength > 0 then
    Move(LData[0], Result[24], LLength);
end;

class function TJclBuilder.MapFile(ASeed: Cardinal; ATileCount, AThingCount: Integer): TBytes;
var
  LLcg: TLcg;
  LIndex: Integer;
  LOffset: Integer;
begin
  LLcg.State := ASeed;
  SetLength(Result, 4 + 4096 * 2 + 4096 + AThingCount * 8);
  FillChar(Result[0], Length(Result), 0);
  for LIndex := 0 to 4095 do
    PSmallInt(@Result[4 + LIndex * 2])^ := LLcg.Below(ATileCount);
  for LIndex := 0 to 4095 do
    Result[4 + 8192 + LIndex] := Byte(LLcg.Below(5));
  LOffset := 4 + 8192 + 4096;
  for LIndex := 0 to AThingCount - 1 do
  begin
    PWord(@Result[LOffset])^ := LLcg.Below(4096);
    PWord(@Result[LOffset + 2])^ := LLcg.Below(4096);
    PWord(@Result[LOffset + 4])^ := LLcg.Below(65536);
    // the types: the star position, an obstacle and some decorations
    case LLcg.Below(4) of
      0: PWord(@Result[LOffset + 6])^ := 241 shl 8 + 1;
      1: PWord(@Result[LOffset + 6])^ := $0600 + LLcg.Below(16);
      2: PWord(@Result[LOffset + 6])^ := $0500;
    else
      PWord(@Result[LOffset + 6])^ := LLcg.Below(300);
    end;
    Inc(LOffset, 8);
  end;
end;

class function TJclBuilder.SectorFile(ASeed: Cardinal; AVertices, ASectors: Integer): TBytes;
var
  LLcg: TLcg;
  LText: string;
  LIndex: Integer;
  LSector: Integer;
  LLine: Integer;
  LLinesInSector: Integer;
  LTotal: Integer;
  LLines: TList<string>;
  LTexture: string;
begin
  LLcg.State := ASeed;
  LLines := TList<string>.Create;
  try
    LTotal := 0;
    for LSector := 0 to ASectors - 1 do
    begin
      LLinesInSector := 1 + LLcg.Below(5);
      LLines.Add(Format('  %d 0x%d', [LLinesInSector, LLcg.Below(2)]));
      for LLine := 1 to LLinesInSector do
      begin
        case LLcg.Below(4) of
          0: LTexture := '""';
          1: LTexture := '"' + IntToStr(1 + LLcg.Below(40)) + '"';
          2: LTexture := '"' + IntToStr(1 + LLcg.Below(9)) + '"';
        else
          LTexture := '""';
        end;
        LLines.Add(Format('    %d %d %s %d', [LLcg.Below(AVertices), LLcg.Below(AVertices), LTexture,
          LLcg.Below(50) - 1]));
        Inc(LTotal);
      end;
    end;
    LText := Format('%d %d %d'#13#10'Vertices'#13#10, [AVertices, ASectors, LTotal]);
    for LIndex := 0 to AVertices - 1 do
      LText := LText + Format('  0x%.8X 0x%.8X'#13#10, [LLcg.Below(65536), LLcg.Below(65536)]);
    LText := LText + 'Sectors'#13#10;
    for LIndex := 0 to LLines.Count - 1 do
      LText := LText + LLines[LIndex] + #13#10;
    LText := LText + 'End'#13#10;
    Result := TextBytes(LText);
  finally
    LLines.Free;
  end;
end;

class function TJclBuilder.PathFile(ASeed: Cardinal; ACount: Integer): TBytes;
var
  LLcg: TLcg;
  LIndex: Integer;
  LOffset: Integer;
begin
  LLcg.State := ASeed;
  SetLength(Result, $100 + ACount * 16);
  FillChar(Result[0], Length(Result), 0);
  PCardinal(@Result[0])^ := $48544150;
  PSmallInt(@Result[196])^ := ACount;
  LOffset := $100;
  for LIndex := 0 to ACount - 1 do
  begin
    PCardinal(@Result[LOffset])^ := Cardinal(LLcg.Below(4096)) shl 20;
    PCardinal(@Result[LOffset + 4])^ := Cardinal(LLcg.Below(4096)) shl 20;
    PCardinal(@Result[LOffset + 8])^ := LLcg.Next shl 8;
    PInteger(@Result[LOffset + 12])^ := LLcg.Below(1000);
    Inc(LOffset, 16);
  end;
end;

class function TJclBuilder.CircuitsText(ACount: Integer): TBytes;
var
  LText: string;
  LIndex: Integer;
begin
  LText := IntToStr(ACount) + #13#10;
  for LIndex := 0 to ACount - 1 do
    LText := LText + Format('Circuit'#13#10'Name "Circuit %d of Speed"'#13#10'Number %d'#13#10 +
      'Level  %d'#13#10'Length %d'#13#10'Best   %d'#13#10'Record %d %d'#13#10'NBack  %d'#13#10,
      [LIndex, LIndex, LIndex mod 3, 2000 + LIndex * 111, 1000 + LIndex * 77, 20 + LIndex, 25 + LIndex, LIndex]);
  Result := TextBytes(LText);
end;

class function TJclBuilder.SyntheticGame: TBytes;
var
  LBuilder: TJclBuilder;
  LIndex: Integer;
  LPalette: TBytes;
begin
  LBuilder := TJclBuilder.Create;
  try
    // the palette of the file: 6 bits per component
    LPalette := RandomBytes(11, 768, 63);
    LBuilder.Add('GRAFS.PAL', LPalette);
    // 70 tiles: the translated one is the 62nd
    LBuilder.Add('GRAFS.DAT', RandomBytes(12, 70 * 4096, 255));
    LBuilder.Add('CIRCUITS.LST', CircuitsText(2));
    // two circuits and the files of a third that is not whole
    LBuilder.Add('MAP00.DAT', MapFile(21, 70, 12));
    LBuilder.Add('MAP00.SEC', SectorFile(22, 9, 6));
    LBuilder.Add('MAP00.PTH', PathFile(23, 7));
    LBuilder.Add('MAP01.DAT', MapFile(31, 40, 5));
    LBuilder.Add('MAP01.SEC', SectorFile(32, 6, 4));
    LBuilder.Add('MAP01.PTH', PathFile(33, 3));
    LBuilder.Add('MAP02.DAT', MapFile(41, 20, 2));
    // the walls: numbers
    LBuilder.Add('1.IS2', Is2(51, 20, 30, False));
    LBuilder.Add('2.IS2', Is2(52, 17, 9, True));
    LBuilder.Add('10.IS2', Is2(53, 8, 64, False));
    // a wall that the directory makes shorter than it is
    LBuilder.AddWithDeclaredSize('3.IS2', Is2(54, 12, 12, False), 100);
    // pictures, sprites and the rest
    LBuilder.Add('DEMOLOGO.IS2', Is2(61, 40, 20, False));
    LBuilder.Add('MFBG0.IS2', Is2(62, 6, 10, True));
    LBuilder.Add('XPR020.IS2', Is2(63, 14, 14, False));
    LBuilder.Add('XPR02A.IS2', Is2(64, 9, 11, False));
    LBuilder.Add('GND001AA.IS2', Is2(65, 10, 6, False));
    LBuilder.Add('SMOK01AA.IS2', Is2(66, 8, 8, False));
    LBuilder.Add('GND101AA.IS2', Is2(67, 5, 5, False));
    LBuilder.Add('TEST.PIX', RandomBytes(71, 320 * 40, 255));
    LBuilder.Add('LOGO.PIX', RandomBytes(72, 320 * 25, 255));
    LBuilder.Add('LOGO.PAL', RandomBytes(73, 768, 63));
    LBuilder.Add('MOUNT0.PIX', RandomBytes(74, 320 * 30, 255));
    LBuilder.Add('MENUS.S3M', RandomBytes(81, 300, 255));
    LBuilder.Add('HASTE1.S3M', RandomBytes(82, 200, 255));
    LBuilder.Add('FIN.S3M', RandomBytes(83, 100, 255));
    LBuilder.Add('GO.RAW', RandomBytes(91, 500, 255));
    LBuilder.Add('CRASH.RAW', RandomBytes(92, 300, 255));
    LBuilder.Add('MOTOR0.RAW', RandomBytes(93, 400, 255));
    LBuilder.Add('XPR061.I3D', RandomBytes(94, 123, 255));
    LBuilder.Add('CAR0N0A.I3D', RandomBytes(95, 77, 255));
    // a lot of other files that the translator does not look at
    for LIndex := 0 to 5 do
      LBuilder.Add('OTHER' + IntToStr(LIndex) + '.BIN', RandomBytes(100 + LIndex, 10, 255));
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

end.
