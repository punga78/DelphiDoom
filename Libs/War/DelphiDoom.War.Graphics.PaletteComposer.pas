{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - two palettes made one                             }
{                                                                              }
{  Port of war1 (acoto87/war1), wres_getPalette of war_resources.c,            }
{  (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-      }
{  war1.txt). This is an altered version, not the original.                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Graphics.PaletteComposer;

interface

uses
  System.SysUtils, DelphiDoom.War.Graphics.Types;

type
  /// <summary>
  ///   A record may name two palettes. The first is the base; in the second the magenta (252, 0, 252) marks
  ///   the colors that are not used: the magenta colors of the first half of the base come from the second
  ///   palette, and the second half of the base is overwritten by every color of the second palette that is not
  ///   magenta
  /// </summary>
  TWarPaletteComposer = class
  public
    /// <param name="APalette1">768 bytes, or nil when the record names no first palette</param>
    /// <param name="APalette2">768 bytes, or nil when the record names no second palette</param>
    /// <returns>768 bytes; zeros when there is no first palette</returns>
    class function Compose(const APalette1, APalette2: TBytes): TBytes; static;
  end;

implementation

{ TWarPaletteComposer }

class function TWarPaletteComposer.Compose(const APalette1, APalette2: TBytes): TBytes;
var
  LColor: Integer;
  LByte: Integer;
  function IsMagenta(const APalette: TBytes; AColor: Integer): Boolean;
  begin
    Result := (APalette[AColor * 3] = 252) and (APalette[AColor * 3 + 1] = 0) and (APalette[AColor * 3 + 2] = 252);
  end;
begin
  if (Assigned(APalette1) and (Length(APalette1) <> WAR_PALETTE_LENGTH)) or
    (Assigned(APalette2) and (Length(APalette2) <> WAR_PALETTE_LENGTH)) then
    raise EArgumentException.CreateFmt(SWarGraphicsPaletteLength, [WAR_PALETTE_LENGTH, WAR_PALETTE_LENGTH]);

  SetLength(Result, WAR_PALETTE_LENGTH);
  if Assigned(APalette1) then
    Move(APalette1[0], Result[0], WAR_PALETTE_LENGTH);
  if not Assigned(APalette2) then
    Exit;

  // probably only the palettes 191, 194, 197 need this (comment of the original): it is done for any record
  // that names a second palette
  for LColor := 0 to 127 do
    if IsMagenta(Result, LColor) then
      for LByte := 0 to 2 do
        Result[LColor * 3 + LByte] := APalette2[LColor * 3 + LByte];
  for LColor := 128 to 255 do
    if not IsMagenta(APalette2, LColor) then
      for LByte := 0 to 2 do
        Result[LColor * 3 + LByte] := APalette2[LColor * 3 + LByte];
end;

end.
