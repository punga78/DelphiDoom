{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the names that the table exports write                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.TableExport.Names;

interface

uses
  DelphiDoom.TableExport.Types,
  DelphiDoom.TableExport.Intf;

type
  /// <summary>
  ///   The lists of flags of the patches, the enumerations of the game and the names that
  ///   the engine has for things, sounds and tokens
  /// </summary>
  TEngineExportNames = class(TInterfacedObject, IExportFlagNames, IExportEnumNames, IExportLookups)
  public
    function Names(ASet: TExportFlagSet): TArray<string>;
    function Count(AKind: TExportEnum): Integer;
    function Name(AKind: TExportEnum; AOrdinal: Integer): string;
    function ThingName(AIndex: Integer): string;
    function SoundName(ASound: Integer): string;
    function BloodName(AColor: Integer): string;
    function GroupName(AGroup: TExportGroup; AValue: Integer): string;
    function RenderStyleToken(AValue: Integer): string;
    function GenderToken(AValue: Integer): string;
    function AmmoToken(AIndex: Integer): string;
    function WeaponToken(AIndex: Integer): string;
    function PlayerClassToken(AIndex: Integer): string;
  end;

implementation

uses
  TypInfo,
  d_delphi,
  deh_main,
  doomdef,
  {$IFDEF DOOM_OR_STRIFE}
  d_items,
  {$ENDIF}
  info_h,
  info,
  info_common,
  p_gender,
  DelphiDoom.Obituary.Types,
  DelphiDoom.Obituary.Genders,
  r_renderstyle,
  r_translations,
  sounddata,
  sounds;

function ListToArray(const AList: TDTextList): TArray<string>;
var
  LIndex: Integer;
begin
  if AList = nil then
    Exit(nil);
  SetLength(Result, AList.Count);
  for LIndex := 0 to AList.Count - 1 do
    Result[LIndex] := AList.Strings[LIndex];
end;

{ TEngineExportNames }

function TEngineExportNames.Names(ASet: TExportFlagSet): TArray<string>;
begin
  case ASet of
    fsMobjFlags: Result := ListToArray(mobj_flags);
    {$IFDEF HERETIC_OR_HEXEN}
    fsMobjFlags2: Result := ListToArray(mobj_flags2);
    {$ENDIF}
    fsMobjFlagsEx: Result := ListToArray(mobj_flags_ex);
    fsMobjFlags2Ex: Result := ListToArray(mobj_flags2_ex);
    fsMobjFlags3Ex: Result := ListToArray(mobj_flags3_ex);
    fsMobjFlags4Ex: Result := ListToArray(mobj_flags4_ex);
    fsMobjFlags5Ex: Result := ListToArray(mobj_flags5_ex);
    fsMobjFlags6Ex: Result := ListToArray(mobj_flags6_ex);
    fsStateFlagsEx: Result := ListToArray(state_flags_ex);
    fsStateFlagsMbf21: Result := ListToArray(state_flags_mbf21);
    fsWeaponFlagsMbf21: Result := ListToArray(weapon_flags_mbf21);
  else
    Result := nil;
  end;
end;

function TEngineExportNames.Count(AKind: TExportEnum): Integer;
begin
  case AKind of
    eeState: Result := Ord(DO_NUMSTATES);
    eeSprite: Result := Ord(DO_NUMSPRITES);
    eeSound: Result := Ord(DO_NUMSFX);
    eeMobj: Result := Ord(DO_NUMMOBJTYPES);
    eeGender: Result := Ord(NUMGENDERS);
    eeRenderStyle: Result := Ord(NUMMOBJRENDERSTYLES);
    eeWeapon: Result := Ord(NUMWEAPONS);
    eePlayerClass:
      {$IFDEF HEXEN}
      Result := Ord(NUMCLASSES) + 1;
      {$ELSE}
      Result := 0;
      {$ENDIF}
    eeAmmo:
      {$IFDEF HEXEN}
      Result := Ord(MANA_NONE) + 1;
      {$ELSE}
      Result := Ord(NUMAMMO) + 2;
      {$ENDIF}
  else
    Result := 0;
  end;
end;

function TEngineExportNames.Name(AKind: TExportEnum; AOrdinal: Integer): string;
begin
  case AKind of
    eeState: Result := GetENumName(TypeInfo(statenum_t), AOrdinal);
    eeSprite: Result := GetENumName(TypeInfo(spritenum_t), AOrdinal);
    eeSound: Result := GetENumName(TypeInfo(sfxenum_t), AOrdinal);
    eeMobj: Result := GetENumName(TypeInfo(mobjtype_t), AOrdinal);
    eeGender: Result := GetENumName(TypeInfo(gender_t), AOrdinal);
    eeRenderStyle: Result := GetENumName(TypeInfo(mobjrenderstyle_t), AOrdinal);
    eeWeapon: Result := GetENumName(TypeInfo(weapontype_t), AOrdinal);
    eePlayerClass:
      {$IFDEF HEXEN}
      Result := GetENumName(TypeInfo(pclass_t), AOrdinal);
      {$ELSE}
      Result := '';
      {$ENDIF}
    eeAmmo:
      {$IFDEF HEXEN}
      Result := GetENumName(TypeInfo(manatype_t), AOrdinal);
      {$ELSE}
      Result := GetENumName(TypeInfo(ammotype_t), AOrdinal);
      {$ENDIF}
  else
    Result := '';
  end;
end;

function TEngineExportNames.ThingName(AIndex: Integer): string;
begin
  Result := Info_GetMobjName(AIndex);
end;

function TEngineExportNames.SoundName(ASound: Integer): string;
begin
  Result := S_GetSoundNameForNum(ASound);
end;

function TEngineExportNames.BloodName(AColor: Integer): string;
begin
  Result := R_GetBloodName(AColor);
end;

function TEngineExportNames.GroupName(AGroup: TExportGroup; AValue: Integer): string;
begin
  case AGroup of
    egInfighting: Result := Info_InfightingGroupToString(AValue);
    egProjectile: Result := Info_ProjectileGroupToString(AValue);
  else
    Result := Info_SplashGroupToString(AValue);
  end;
end;

function TEngineExportNames.RenderStyleToken(AValue: Integer): string;
begin
  Result := renderstyle_tokens[AValue];
end;

function TEngineExportNames.GenderToken(AValue: Integer): string;
begin
  Result := TObituaryGenders.NameOf(TObituaryGender(AValue));
end;

function TEngineExportNames.AmmoToken(AIndex: Integer): string;
begin
  Result := ammotype_tokens.Strings[AIndex];
end;

function TEngineExportNames.WeaponToken(AIndex: Integer): string;
begin
  Result := weapontype_tokens.Strings[AIndex];
end;

function TEngineExportNames.PlayerClassToken(AIndex: Integer): string;
begin
  {$IFDEF HEXEN}
  Result := playerclass_tokens.Strings[AIndex];
  {$ELSE}
  Result := '';
  {$ENDIF}
end;

end.
