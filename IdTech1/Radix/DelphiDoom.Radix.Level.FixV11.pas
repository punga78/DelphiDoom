{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelFixV11                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of fix_radix_level_v11 and fix_doom_level_v11 of radix_level.pas       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.FixV11;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Level.Data, DelphiDoom.Radix.Level.DoomMap, DelphiDoom.Radix.Level.Intf;

type
  /// <summary>The corrections of the levels of Radix 1.1</summary>
  TRadixLevelFixV11 = class(TInterfacedObject, IRadixLevelFix)
  public
    procedure FixRadix(const ALevel: TRadixLevelData);
    procedure FixDoom(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData);
  end;

implementation

uses
  DelphiDoom.Radix.Level.FixOps;

{ TRadixLevelFixV11 }

procedure TRadixLevelFixV11.FixRadix(const ALevel: TRadixLevelData);
begin
  // nothing to correct in the level of Radix itself
end;

procedure TRadixLevelFixV11.FixDoom(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData);
begin
  if ALevel.Name = 'E1M1' then
  begin
    TRadixLevelFixOps.ReplaceSideSector(AMap, 206, 0);
    TRadixLevelFixOps.ReplaceSideSector(AMap, 211, 212);
  end;
end;

end.
