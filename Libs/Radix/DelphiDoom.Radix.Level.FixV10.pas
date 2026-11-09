{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelFixV10                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of fix_radix_level_v10 and fix_doom_level_v10 of radix_level.pas       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.FixV10;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Level.Data, DelphiDoom.Radix.Level.DoomMap, DelphiDoom.Radix.Level.Intf;

type
  /// <summary>The corrections of the levels of Radix 1.0 (shareware)</summary>
  TRadixLevelFixV10 = class(TInterfacedObject, IRadixLevelFix)
  public
    procedure FixRadix(const ALevel: TRadixLevelData);
    procedure FixDoom(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData);
  end;

implementation

{ TRadixLevelFixV10 }

procedure TRadixLevelFixV10.FixRadix(const ALevel: TRadixLevelData);
begin
  // nothing to correct in the level of Radix itself
end;

procedure TRadixLevelFixV10.FixDoom(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData);
begin
  if ALevel.Name = 'E2M4' then
  begin
    // final arena sky
    AMap.Sectors[48].CeilingHeight := 1312;
    AMap.Sectors[49].CeilingHeight := 1312;
  end
  else if ALevel.Name = 'E3M6' then
    AMap.Sectors[62].CeilingHeight := 1408;
end;

end.
