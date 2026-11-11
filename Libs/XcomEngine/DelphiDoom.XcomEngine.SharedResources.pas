{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the sizes of the sets that the mods share  }
{  (what Mod::loadVanillaResources sets with setMaxSharedFrames)                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.SharedResources;

interface

uses
  System.SysUtils, DelphiDoom.XcomMod.ModOffsets;

type
  /// <summary>
  ///   The shared sizes of the vanilla sets of TFTD (the same values of the golden of the real Mod: the frames of the
  ///   original files and the fixed ones of the code). A set that is not listed has no limit
  /// </summary>
  TXcomVanillaSharedResources = class(TInterfacedObject, IXcomSharedResources)
  public
    function MaxSharedSounds(const ASet: string): Integer;
    function MaxSharedFrames(const ASet: string): Integer;
  end;

implementation

function TXcomVanillaSharedResources.MaxSharedSounds(const ASet: string): Integer;
begin
  if (ASet = 'BATTLE.CAT') or (ASet = 'BATTLE2.CAT') then
    Result := 68
  else if ASet = 'GEO.CAT' then
    Result := 16
  else
    Result := MaxInt;
end;

function TXcomVanillaSharedResources.MaxSharedFrames(const ASet: string): Integer;
begin
  if ASet = 'BASEBITS.PCK' then
    Result := 54
  else if ASet = 'BIGOBS.PCK' then
    Result := 66
  else if ASet = 'FLOOROB.PCK' then
    Result := 82
  else if ASet = 'GlobeMarkers' then
    Result := 9
  else if ASet = 'HANDOB.PCK' then
    Result := 440
  else if ASet = 'HIT.PCK' then
    Result := 4
  else if ASet = 'INTICON.PCK' then
    Result := 16
  else if (ASet = 'Projectiles') or (ASet = 'UnderwaterProjectiles') then
    Result := 385
  else if (ASet = 'SMOKE.PCK') or (ASet = 'X1.PCK') then
    Result := 68
  else
    Result := MaxInt;
end;

end.
