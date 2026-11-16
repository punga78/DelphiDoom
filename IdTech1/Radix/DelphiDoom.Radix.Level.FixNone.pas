{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelFixNone                              }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.FixNone;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Level.Data, DelphiDoom.Radix.Level.DoomMap, DelphiDoom.Radix.Level.Intf;

type
  /// <summary>For a level that is not of a known version: no corrections</summary>
  TRadixLevelFixNone = class(TInterfacedObject, IRadixLevelFix)
  public
    procedure FixRadix(const ALevel: TRadixLevelData);
    procedure FixDoom(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData);
  end;

implementation

{ TRadixLevelFixNone }

procedure TRadixLevelFixNone.FixRadix(const ALevel: TRadixLevelData);
begin
end;

procedure TRadixLevelFixNone.FixDoom(const AMap: TRadixDoomMap; const ALevel: TRadixLevelData);
begin
end;

end.
