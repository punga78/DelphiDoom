{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the game data library - the images of the golden       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The same unit is compiled by the harness that ran the patch builders of     }
{  the forks (outside the repository) and by the tests: both make the same     }
{  images, so the golden lines can be compared                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GameData.Scenarios;

interface

uses
  System.SysUtils;

type
  /// <summary>One image and the way it is turned into a patch</summary>
  TGameDataScenario = record
    Name: string;
    Width: Integer;
    Height: Integer;
    /// <summary>Width * Height palette indices</summary>
    Image: TBytes;
    /// <summary>768 bytes of 0..80 (some above the 63 of VGA, to test the clamp)</summary>
    Palette: TBytes;
    /// <summary>256 colors $00RRGGBB</summary>
    DefaultPalette: TArray<Cardinal>;
  end;

  TGameDataScenarios = class
  public
    class function All: TArray<TGameDataScenario>; static;
    /// <summary>FNV-1a of the bytes, as 8 hexadecimal digits</summary>
    class function Digest(const ABytes: TBytes): string; static;
  end;

implementation

type
  TLcg = record
    State: Cardinal;
    function Next: Cardinal;
  end;

function TLcg.Next: Cardinal;
begin
  {$Q-}{$R-}
  State := State * 1664525 + 1013904223;
  Result := State shr 8;
end;

const
  SIZES: array[0..9, 0..1] of Integer = (
    (1, 1), (2, 3), (8, 8), (16, 16), (5, 16), (64, 10), (3, 200), (40, 128), (33, 1), (1, 64));
  SPECIAL: array[0..3] of Byte = (0, 254, 255, 77);
  PATTERN_COUNT = 5;

class function TGameDataScenarios.All: TArray<TGameDataScenario>;
var
  LSize: Integer;
  LPattern: Integer;
  LIndex: Integer;
  LScenario: TGameDataScenario;
  LLcg: TLcg;
  LList: TArray<TGameDataScenario>;
begin
  SetLength(LList, 0);
  LLcg.State := 12345;
  for LSize := 0 to High(SIZES) do
    for LPattern := 0 to PATTERN_COUNT - 1 do
    begin
      LScenario.Width := SIZES[LSize, 0];
      LScenario.Height := SIZES[LSize, 1];
      LScenario.Name := Format('%dx%d_p%d', [LScenario.Width, LScenario.Height, LPattern]);
      SetLength(LScenario.Image, LScenario.Width * LScenario.Height);
      for LIndex := 0 to High(LScenario.Image) do
        case LPattern of
          0: LScenario.Image[LIndex] := Byte(LLcg.Next);
          1: if LLcg.Next mod 100 < 60 then
               LScenario.Image[LIndex] := SPECIAL[LLcg.Next mod 4]
             else
               LScenario.Image[LIndex] := Byte(LLcg.Next);
          2: LScenario.Image[LIndex] := 255;
          3: LScenario.Image[LIndex] := 0;
          else LScenario.Image[LIndex] := 254;
        end;
      SetLength(LScenario.Palette, 768);
      for LIndex := 0 to 767 do
        LScenario.Palette[LIndex] := Byte(LLcg.Next mod 81);
      SetLength(LScenario.DefaultPalette, 256);
      for LIndex := 0 to 255 do
        LScenario.DefaultPalette[LIndex] := (Cardinal(LLcg.Next) and $FF) shl 16 +
          (Cardinal(LLcg.Next) and $FF) shl 8 + (Cardinal(LLcg.Next) and $FF);
      SetLength(LList, Length(LList) + 1);
      LList[High(LList)] := LScenario;
    end;
  Result := LList;
end;

class function TGameDataScenarios.Digest(const ABytes: TBytes): string;
var
  LHash: Cardinal;
  LIndex: Integer;
begin
  {$Q-}{$R-}
  LHash := $811C9DC5;
  for LIndex := 0 to High(ABytes) do
    LHash := (LHash xor ABytes[LIndex]) * $01000193;
  Result := IntToHex(LHash, 8);
end;

end.
