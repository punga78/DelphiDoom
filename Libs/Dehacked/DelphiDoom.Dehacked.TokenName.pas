{******************************************************************************}
{                                                                              }
{  DelphiDoom: DEHACKED library - the name of a type as the token lists read it}
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.TokenName;

interface

type
  /// <summary>
  ///   The names of the ammunition, the weapons and the player classes ("AM_CLIP", "WP_PISTOL",
  ///   "PCLASS_FIGHTER") are looked up in token lists that hold the full names; a patch or a
  ///   script may leave the prefix out (the old DEH_AmmoType, DEH_WeaponType, DEH_PlayerClass)
  /// </summary>
  TDehackedTokenName = class sealed
  public
    /// <summary>
    ///   The name in upper case; if it does not start with the prefix the prefix is added AFTER
    ///   it ("CLIP" becomes "CLIPAM_"): a defect of the old code, kept, so that such a name is
    ///   not found, as it was not
    /// </summary>
    class function Canonical(const AText, APrefix: string): string; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Scanner.Strings;

{ TDehackedTokenName }

class function TDehackedTokenName.Canonical(const AText, APrefix: string): string;
begin
  Result := TScannerStrings.UpperAscii(AText);
  if not Result.StartsWith(APrefix) then
    Result := Result + APrefix;
end;

end.
