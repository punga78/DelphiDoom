{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the weapons for the table exports                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.TableExport.Weapons;

interface

uses
  DelphiDoom.TableExport.Types,
  DelphiDoom.TableExport.Intf;

type
  /// <summary>
  ///   The weapons of the game: one for Doom and Strife, two levels for Heretic, four classes
  ///   for Hexen, level or class first and then the weapon
  /// </summary>
  TEngineExportWeapons = class(TInterfacedObject, IExportWeaponSource)
  public
    function Count: Integer;
    function Get(AIndex: Integer): TExportWeapon;
  end;

implementation

uses
  doomdef,
  {$IFDEF DOOM_OR_STRIFE}
  d_items,
  {$ENDIF}
  {$IFDEF HERETIC}
  p_pspr_h,
  p_pspr,
  {$ENDIF}
  {$IFDEF HEXEN}
  p_pspr_h,
  p_pspr,
  {$ENDIF}
  info_h;

{ TEngineExportWeapons }

function TEngineExportWeapons.Count: Integer;
begin
  {$IFDEF DOOM_OR_STRIFE}
  Result := Ord(NUMWEAPONS);
  {$ENDIF}
  {$IFDEF HERETIC}
  Result := 2 * Ord(NUMWEAPONS);
  {$ENDIF}
  {$IFDEF HEXEN}
  Result := Ord(NUMCLASSES) * Ord(NUMWEAPONS);
  {$ENDIF}
end;

function TEngineExportWeapons.Get(AIndex: Integer): TExportWeapon;
var
  LInfo: Pweaponinfo_t;
begin
  Result := Default(TExportWeapon);
  Result.WeaponNo := AIndex mod Ord(NUMWEAPONS);
  {$IFDEF DOOM_OR_STRIFE}
  LInfo := @weaponinfo[Result.WeaponNo];
  Result.Numbers[wfAmmo] := Ord(LInfo.ammo);
  Result.Numbers[wfAmmoPerShot] := LInfo.ammopershot;
  {$ENDIF}
  {$IFDEF HERETIC}
  Result.Level := 1 + AIndex div Ord(NUMWEAPONS);
  if Result.Level = 1 then
  begin
    LInfo := @wpnlev1info[Result.WeaponNo];
    Result.Numbers[wfAmmoPerShot] := WeaponAmmoUsePL1[Result.WeaponNo];
  end
  else
  begin
    LInfo := @wpnlev2info[Result.WeaponNo];
    Result.Numbers[wfAmmoPerShot] := WeaponAmmoUsePL2[Result.WeaponNo];
  end;
  Result.Numbers[wfAmmo] := Ord(LInfo.ammo);
  {$ENDIF}
  {$IFDEF HEXEN}
  Result.PlayerClass := AIndex div Ord(NUMWEAPONS);
  LInfo := @WeaponInfo[Result.WeaponNo, Result.PlayerClass];
  Result.Numbers[wfAmmo] := Ord(LInfo.mana);
  Result.Numbers[wfAmmoPerShot] := WeaponManaUse[Result.PlayerClass, Result.WeaponNo];
  {$ENDIF}
  Result.Numbers[wfUpState] := LInfo.upstate;
  Result.Numbers[wfDownState] := LInfo.downstate;
  Result.Numbers[wfReadyState] := LInfo.readystate;
  Result.Numbers[wfAttackState] := LInfo.atkstate;
  Result.Numbers[wfHoldAttackState] := LInfo.holdatkstate;
  Result.Numbers[wfFlashState] := LInfo.flashstate;
  Result.Numbers[wfMbf21Bits] := LInfo.mbf21bits;
end;

end.
