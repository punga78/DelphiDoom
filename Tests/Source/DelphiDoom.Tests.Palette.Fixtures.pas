{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the palette library - the input data                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Palette.Fixtures;

{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   Palettes and colormaps made by a fixed generator: the harness that wrote the golden files
  ///   (it ran the old code) and the tests use this same unit, so the inputs are the same.
  ///   And the reader of a lump of a real WAD, for the tests that need bin\Game\*.WAD
  /// </summary>
  TPaletteFixtures = class
  public
    class var
      /// <summary>The folder with bin\ in it; empty: two levels over the folder of the executable (bin\Tests)</summary>
      RootPath: string;
    /// <summary>Count bytes of a linear congruential generator, each and-ed with AMask</summary>
    class function RandomBytes(ASeed: Cardinal; ACount: Integer; AMask: Byte): TBytes; static;
    /// <summary>768 bytes any value</summary>
    class function Palette8(ASeed: Cardinal): TBytes; static;
    /// <summary>768 bytes under 64 (a palette of 6 bits per channel)</summary>
    class function Palette6(ASeed: Cardinal): TBytes; static;
    /// <summary>
    ///   A palette with the black at 0 and the white at 255, a gray ramp in 1..16 and the rest
    ///   at random: it has exact matches
    /// </summary>
    class function PaletteWithRamp(ASeed: Cardinal): TBytes; static;
    /// <summary>ARows rows of 256 bytes, about one in 16 is 0</summary>
    class function Colormap(ASeed: Cardinal; ARows: Integer): TBytes; static;
    /// <summary>The packed colors of a palette ($00RRGGBB)</summary>
    class function PackedColors(const APalette: TBytes): TArray<Cardinal>; static;
    /// <summary>Colors ($00RRGGBB) to look for with the approximate search</summary>
    class function ProbeColors: TArray<Cardinal>; static;
    /// <summary>The names tried on the translation tables and on the blood colors</summary>
    class function ProbeNames: TArray<string>; static;
    class function WadPath(const AGameFolder, AWadFile: string): string; static;
    /// <summary>The last lump with that name of a WAD; false if the WAD or the lump is missing</summary>
    class function ReadLump(const AWadPath, ALumpName: string; out ABytes: TBytes): Boolean; static;
  end;

implementation

uses
  System.IOUtils;

{ TPaletteFixtures }

class function TPaletteFixtures.RandomBytes(ASeed: Cardinal; ACount: Integer; AMask: Byte): TBytes;
var
  LIndex: Integer;
  LState: Cardinal;
begin
  SetLength(Result, ACount);
  LState := ASeed;
  for LIndex := 0 to ACount - 1 do
  begin
    LState := (LState * 1103515245 + 12345) and $7FFFFFFF;
    Result[LIndex] := Byte((LState shr 16) and AMask);
  end;
end;

class function TPaletteFixtures.Palette8(ASeed: Cardinal): TBytes;
begin
  Result := RandomBytes(ASeed, 768, $FF);
end;

class function TPaletteFixtures.Palette6(ASeed: Cardinal): TBytes;
begin
  Result := RandomBytes(ASeed, 768, $3F);
end;

class function TPaletteFixtures.PaletteWithRamp(ASeed: Cardinal): TBytes;
var
  LIndex: Integer;
begin
  Result := RandomBytes(ASeed, 768, $FF);
  Result[0] := 0;
  Result[1] := 0;
  Result[2] := 0;
  for LIndex := 1 to 16 do
  begin
    Result[LIndex * 3] := Byte(LIndex * 16 - 1);
    Result[LIndex * 3 + 1] := Byte(LIndex * 16 - 1);
    Result[LIndex * 3 + 2] := Byte(LIndex * 16 - 1);
  end;
  Result[765] := 255;
  Result[766] := 255;
  Result[767] := 255;
end;

class function TPaletteFixtures.Colormap(ASeed: Cardinal; ARows: Integer): TBytes;
var
  LIndex: Integer;
begin
  Result := RandomBytes(ASeed, ARows * 256, $FF);
  for LIndex := 0 to High(Result) do
    if (Result[LIndex] and $0F) = 0 then
      Result[LIndex] := 0;
end;

class function TPaletteFixtures.PackedColors(const APalette: TBytes): TArray<Cardinal>;
var
  LIndex: Integer;
begin
  SetLength(Result, 256);
  for LIndex := 0 to 255 do
    Result[LIndex] := (Cardinal(APalette[LIndex * 3]) shl 16) or
      (Cardinal(APalette[LIndex * 3 + 1]) shl 8) or Cardinal(APalette[LIndex * 3 + 2]);
end;

class function TPaletteFixtures.ProbeColors: TArray<Cardinal>;
begin
  Result := [$000000, $FF0000, $00FF00, $0000FF, $FFFFFF, $808080, $123456, $FEDCBA];
end;

class function TPaletteFixtures.ProbeNames: TArray<string>;
begin
  Result := ['BRICK', 'brick', 'CR_BRICK', 'CRBRICK', 'purple', 'PURPLE', 'CR_PURPLE', 'cr_red',
    'TRANS5', 'CRTRANS9', 'FOO', 'CR_FOO', 'CRFOO', 'foo', 'CR_CRX', 'CRAB', 'CR', 'CR_', '',
    '0', '7', '8', '9', '12', '00005', '99999999999', 'CR_GRAY', 'cr_blue2', 'Green', 'x',
    'CRCR', 'cr_', 'Cr_White', 'orange', 'CRORANGE', 'BLACK', 'TRANS10'];
end;

class function TPaletteFixtures.WadPath(const AGameFolder, AWadFile: string): string;
var
  LRoot: string;
begin
  LRoot := RootPath;
  if LRoot = '' then
    LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..'));
  Result := TPath.Combine(TPath.Combine(TPath.Combine(LRoot, 'bin'), AGameFolder), AWadFile);
end;

class function TPaletteFixtures.ReadLump(const AWadPath, ALumpName: string;
  out ABytes: TBytes): Boolean;
var
  LStream: TFileStream;
  LHeader: array[0..11] of Byte;
  LEntry: array[0..15] of Byte;
  LCount: Integer;
  LDirectory: Integer;
  LIndex: Integer;
  LOffset: Integer;
  LSize: Integer;
  LRaw: AnsiString;
  LName: string;
  LWanted: string;
  LFoundOffset: Integer;
  LFoundSize: Integer;
begin
  Result := False;
  ABytes := nil;
  if not TFile.Exists(AWadPath) then
    Exit;
  LWanted := UpperCase(ALumpName);
  LFoundOffset := -1;
  LFoundSize := 0;
  LStream := TFileStream.Create(AWadPath, fmOpenRead or fmShareDenyNone);
  try
    LStream.ReadBuffer(LHeader, SizeOf(LHeader));
    LCount := PInteger(@LHeader[4])^;
    LDirectory := PInteger(@LHeader[8])^;
    LStream.Position := LDirectory;
    for LIndex := 0 to LCount - 1 do
    begin
      LStream.ReadBuffer(LEntry, SizeOf(LEntry));
      LOffset := PInteger(@LEntry[0])^;
      LSize := PInteger(@LEntry[4])^;
      SetString(LRaw, PAnsiChar(@LEntry[8]), 8);
      LName := UpperCase(string(PAnsiChar(LRaw)));
      if LName = LWanted then
      begin
        LFoundOffset := LOffset;
        LFoundSize := LSize;
      end;
    end;
    if LFoundOffset < 0 then
      Exit;
    SetLength(ABytes, LFoundSize);
    LStream.Position := LFoundOffset;
    if LFoundSize > 0 then
      LStream.ReadBuffer(ABytes[0], LFoundSize);
    Result := True;
  finally
    LStream.Free;
  end;
end;

end.
