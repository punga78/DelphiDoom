{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the endoom library - the input data                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.Fixtures;

{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

uses
  System.SysUtils, System.Classes;

type
  /// <summary>
  ///   Screens, fonts, colors and palettes made by a fixed generator: the harness that wrote the
  ///   golden files (it ran the old code) and the tests use this same unit, so the inputs are the
  ///   same. And the reader of a lump of a real WAD, for the tests that need bin\Game\*.WAD
  /// </summary>
  TEndoomFixtures = class
  public
    /// <summary>Count bytes of a linear congruential generator, each and-ed with AMask</summary>
    class function RandomBytes(ASeed: Cardinal; ACount: Integer; AMask: Byte): TBytes; static;
    /// <summary>A screen (4000 bytes): AKind 0 walks every character, 1 every attribute, 2 mixes them</summary>
    class function Screen(AKind: Integer): TBytes; static;
    /// <summary>A font of 128x128 bytes with about half of the pixels at 0</summary>
    class function Font: TBytes; static;
    /// <summary>16 palette indices: AKind 0 and 1 are different and have no repeated value</summary>
    class function ColorIndices(AKind: Integer): TArray<Byte>; static;
    /// <summary>256 colors ($00RRGGBB, some with a stray alpha byte)</summary>
    class function Palette: TArray<Cardinal>; static;
    /// <summary>The path of a file in bin\Game; the folder with bin\ is two levels over the executable</summary>
    class function WadPath(const AGameFolder, AWadFile: string): string; static;
    /// <summary>The last lump with that name of a WAD; false if the WAD or the lump is missing</summary>
    class function ReadLump(const AWadPath, ALumpName: string; out ABytes: TBytes): Boolean; static;
  end;

implementation

uses
  System.IOUtils;

{ TEndoomFixtures }

class function TEndoomFixtures.RandomBytes(ASeed: Cardinal; ACount: Integer; AMask: Byte): TBytes;
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

class function TEndoomFixtures.Screen(AKind: Integer): TBytes;
var
  LCell: Integer;
begin
  SetLength(Result, 4000);
  for LCell := 0 to 1999 do
  begin
    case AKind of
      0:
        begin
          Result[LCell * 2] := Byte(LCell);
          Result[LCell * 2 + 1] := Byte(LCell * 7 + LCell div 256);
        end;
      1:
        begin
          Result[LCell * 2] := Byte(LCell * 13 + 5);
          Result[LCell * 2 + 1] := Byte(LCell div 8);
        end;
    else
      begin
        Result[LCell * 2] := Byte(LCell div 3);
        Result[LCell * 2 + 1] := Byte(LCell);
      end;
    end;
  end;
end;

class function TEndoomFixtures.Font: TBytes;
begin
  Result := RandomBytes(77, 128 * 128, $01);
end;

class function TEndoomFixtures.ColorIndices(AKind: Integer): TArray<Byte>;
var
  LIndex: Integer;
begin
  SetLength(Result, 16);
  for LIndex := 0 to 15 do
    if AKind = 0 then
      Result[LIndex] := Byte(LIndex * 17 + 3)
    else
      Result[LIndex] := Byte(255 - LIndex * 5);
end;

class function TEndoomFixtures.Palette: TArray<Cardinal>;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  LBytes := RandomBytes(99, 256 * 4, $FF);
  SetLength(Result, 256);
  for LIndex := 0 to 255 do
    Result[LIndex] := PCardinal(@LBytes[LIndex * 4])^;
end;

class function TEndoomFixtures.WadPath(const AGameFolder, AWadFile: string): string;
var
  LRoot: string;
begin
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..'));
  Result := TPath.Combine(TPath.Combine(TPath.Combine(LRoot, 'bin'), AGameFolder), AWadFile);
end;

class function TEndoomFixtures.ReadLump(const AWadPath, ALumpName: string;
  out ABytes: TBytes): Boolean;
var
  LStream: TFileStream;
  LHeader: array[0..11] of Byte;
  LEntry: array[0..15] of Byte;
  LCount: Integer;
  LDirectory: Integer;
  LIndex: Integer;
  LRaw: AnsiString;
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
      SetString(LRaw, PAnsiChar(@LEntry[8]), 8);
      if UpperCase(string(PAnsiChar(LRaw))) = LWanted then
      begin
        LFoundOffset := PInteger(@LEntry[0])^;
        LFoundSize := PInteger(@LEntry[4])^;
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
