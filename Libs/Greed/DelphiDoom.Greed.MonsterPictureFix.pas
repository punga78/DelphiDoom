{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the colour 255 of the pictures of the monsters   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the loop of                 }
{  DemandLoadMonster of spawn.pas                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.MonsterPictureFix;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   What DemandLoadMonster does to each lump it loads: in every column of the sprite (scalepic_t: leftoffset,
  ///   width, one offset for each column; a column is the bottom row, the top row and bottom - top + 1 pixels) the
  ///   pixels of colour 255 become 0, which is not drawn. Only the first run of each column is looked at, as in the
  ///   original. Difference: what would fall outside the lump is not touched (the original wrote in the memory
  ///   after it)
  /// </summary>
  TGreedMonsterPictureFix = class
  public
    /// <summary>Changes ALump in place; gives how many pixels were cleared</summary>
    class function Apply(var ALump: TBytes): Integer; static;
  end;

implementation

const
  HEADER_BYTES = 4;
  CLEARED_COLOUR = 255;

{ TGreedMonsterPictureFix }

class function TGreedMonsterPictureFix.Apply(var ALump: TBytes): Integer;
var
  LWidth, LColumn, LOffset, LTop, LBottom, LCount, LPixel, LPosition: Integer;
begin
  Result := 0;
  if Length(ALump) < HEADER_BYTES then
    Exit;
  LWidth := SmallInt(ALump[2] or (ALump[3] shl 8));
  for LColumn := 0 to LWidth - 1 do
  begin
    if HEADER_BYTES + LColumn * 2 + 1 >= Length(ALump) then
      Break;
    LOffset := SmallInt(ALump[HEADER_BYTES + LColumn * 2] or (ALump[HEADER_BYTES + LColumn * 2 + 1] shl 8));
    if (LOffset = 0) or (LOffset < 0) or (LOffset + 1 >= Length(ALump)) then
      Continue;
    LBottom := ALump[LOffset];
    LTop := ALump[LOffset + 1];
    LCount := LBottom - LTop + 1;
    for LPixel := 0 to LCount - 1 do
    begin
      LPosition := LOffset + 2 + LPixel;
      if LPosition >= Length(ALump) then
        Break;
      if ALump[LPosition] = CLEARED_COLOUR then
      begin
        ALump[LPosition] := 0;
        Inc(Result);
      end;
    end;
  end;
end;

end.
