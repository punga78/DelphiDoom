{******************************************************************************}
{                                                                              }
{  DelphiDoom: Texture library - tells if a lump is a patch                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Port of T_IsValidPatchImage (t_patch.pas)                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.PatchInspector;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Walks the columns of a lump the way the engine does and checks that every post stays
  ///   inside of the picture and that the lump does not end in the middle of a column; this is what
  ///   tells a patch from other data (a PAK has the lumps without names of their kind)
  /// </summary>
  /// <remarks>
  ///   A byte that the walk reads outside of the lump counts as 0: the old code read the memory
  ///   there and the answer depended on it
  /// </remarks>
  TTexturePatchInspector = class sealed
  public
    /// <param name="ALump">The bytes of the lump</param>
    /// <param name="ASize">How many of them are the patch (the length of the array when it is smaller)</param>
    class function IsValid(const ALump: TBytes; ASize: Integer): Boolean; static;
  end;

implementation

{ TTexturePatchInspector }

class function TTexturePatchInspector.IsValid(const ALump: TBytes; ASize: Integer): Boolean;
var
  LColumn: Integer;
  LWidth, LHeight: Integer;
  LCount: Integer;
  LDestTop: Integer;
  LMaximum: Integer;
  LPosition: Integer;
  LDelta, LPreviousDelta: Integer;
  LTall: Boolean;
  LPosts: Integer;
  LDest: Integer;

  function ByteAt(APosition: Integer): Integer;
  begin
    if (APosition >= 0) and (APosition < Length(ALump)) and (APosition < ASize) then
      Result := ALump[APosition]
    else
      Result := 0;
  end;

  function IntegerAt(APosition: Integer): Integer;
  begin
    Result := ByteAt(APosition) or (ByteAt(APosition + 1) shl 8) or (ByteAt(APosition + 2) shl 16) or
              (ByteAt(APosition + 3) shl 24);
  end;

  function InRange(APosition, AFirst, ALast: Integer): Boolean;
  begin
    Result := (APosition >= AFirst) and (APosition <= ALast);
  end;

begin
  Result := True;
  if ASize > Length(ALump) then
    ASize := Length(ALump);
  // the header is four smallints: the width and the height come first
  LWidth := SmallInt(ByteAt(0) or (ByteAt(1) shl 8));
  LHeight := SmallInt(ByteAt(2) or (ByteAt(3) shl 8));
  if not (InRange(LWidth, 0, 8192) and InRange(LHeight, 0, 1024)) then
    Exit(False);

  LCount := LWidth;
  LColumn := 0;
  LDestTop := 0;
  LMaximum := LWidth * LHeight;
  while (LColumn < LCount) and Result do
  begin
    // the table of the offsets of the columns follows the header
    LPosition := IntegerAt(8 + LColumn * 4);
    if not InRange(LPosition, 0, ASize - 3) then
      if ByteAt(LPosition) <> $FF then
        Exit(False);
    if not InRange(LPosition, 0, ASize) then
      Exit(False);

    LDelta := 0;
    LTall := False;
    LPosts := 0;
    while Result and (ByteAt(LPosition) <> $FF) do
    begin
      LDelta := LDelta + ByteAt(LPosition);
      LDest := LDestTop + (LDelta + ByteAt(LPosition + 1) - 1) * LWidth;
      if LDest >= LMaximum then
        Exit(False);

      if not LTall then
      begin
        LPreviousDelta := ByteAt(LPosition);
        LPosition := LPosition + ByteAt(LPosition + 1) + 4;
        if ByteAt(LPosition) > LPreviousDelta then
          LDelta := 0
        else
          LTall := True;
      end
      else
        LPosition := LPosition + ByteAt(LPosition + 1) + 4;

      if not InRange(LPosition, 0, ASize - 3) then
        if LColumn < LWidth - 1 then
          Exit(False);

      Inc(LPosts);
      if LPosts >= LHeight then
        Exit(False);
    end;
    Inc(LColumn);
    Inc(LDestTop);
  end;
end;

end.
