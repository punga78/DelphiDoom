{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - how each field of a block is read            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.FieldKinds;

interface

uses
  DelphiDoom.Dehacked.Types;

type
  /// <summary>
  ///   What a field is, by its name: the same name is read in the same way in every game. The
  ///   position of a name in the table of a game is what changes
  /// </summary>
  TDehackedFieldKinds = class
  public
    /// <param name="ANames">The fields of the things of a game, in order</param>
    /// <param name="AHasFlags2">The game has BITS2 (Heretic and Hexen); Doom and Strife warn about it</param>
    class function ThingDefs(const ANames: TArray<string>; AHasFlags2: Boolean): TArray<TDehackedFieldDef>; static;
    class function FrameDefs(const ANames: TArray<string>): TArray<TDehackedFieldDef>; static;
    class function WeaponDefs(const ANames: TArray<string>): TArray<TDehackedFieldDef>; static;
    /// <summary>Numbers, zero if the text is not one (ammunition, sounds)</summary>
    class function CountDefs(const ANames: TArray<string>): TArray<TDehackedFieldDef>; static;
  end;

implementation

uses
  System.StrUtils;

function NewDef(const AName: string; AKind: TDehackedFieldKind; ADefault: Integer = -1): TDehackedFieldDef;
begin
  Result := Default(TDehackedFieldDef);
  Result.Name := AName;
  Result.Canonical := -1;
  Result.Kind := AKind;
  Result.Default := ADefault;
end;

function FlagsDef(const AName, AFlagSet: string): TDehackedFieldDef;
begin
  Result := NewDef(AName, dfkFlags);
  Result.FlagSet := AFlagSet;
end;

procedure ResolveAliases(var ADefs: TArray<TDehackedFieldDef>; const ANames: TArray<string>;
  const AAliases, ATargets: array of string);
var
  LIndex, LTarget: Integer;
begin
  for LIndex := 0 to High(ADefs) do
  begin
    LTarget := IndexStr(ADefs[LIndex].Name, AAliases);
    if LTarget >= 0 then
      ADefs[LIndex].Canonical := IndexStr(ATargets[LTarget], ANames);
  end;
end;

{ TDehackedFieldKinds }

class function TDehackedFieldKinds.ThingDefs(const ANames: TArray<string>;
  AHasFlags2: Boolean): TArray<TDehackedFieldDef>;
var
  LIndex: Integer;
  LName: string;
  LDef: TDehackedFieldDef;
begin
  SetLength(Result, Length(ANames));
  for LIndex := 0 to High(ANames) do
  begin
    LName := ANames[LIndex];
    if IndexStr(LName, ['INITIAL FRAME', 'FIRST MOVING FRAME', 'INJURY FRAME', 'PAIN FRAME',
      'CLOSE ATTACK FRAME', 'FAR ATTACK FRAME', 'DEATH FRAME', 'EXPLODING FRAME',
      'RESPAWN FRAME', 'HEAL FRAME', 'CRASH FRAME', 'INTERACT FRAME', 'CRUSH FRAME']) >= 0 then
      LDef := NewDef(LName, dfkState)
    else if IndexStr(LName, ['ALERT SOUND', 'ATTACK SOUND', 'PAIN SOUND', 'DEATH SOUND',
      'ACTION SOUND', 'ACTIVE SOUND', 'CUSTOM SOUND 1', 'CUSTOM SOUND 2', 'CUSTOM SOUND 3',
      'MELEE SOUND', 'RIP SOUND', 'INHERITSFROM', 'NAME', 'NAME2', 'RENDERSTYLE', 'DROPITEM',
      'DROPPED ITEM', 'MISSILETYPE', 'OBITUARY', 'HIT OBITUARY', 'GENDER', 'INFIGHTING GROUP',
      'PROJECTILE GROUP', 'SPLASH GROUP', 'BLOOD COLOR', 'TRANSLATION']) >= 0 then
      LDef := NewDef(LName, dfkName)
    else if IndexStr(LName, ['PUSHFACTOR', 'SCALE', 'GRAVITY', 'FRICTION', 'MAX STEP HEIGHT',
      'MAX DROPOFF HEIGHT']) >= 0 then
    begin
      LDef := NewDef(LName, dfkFixed);
      LDef.Tolerance := 64;
    end
    else if IndexStr(LName, ['SPRITE DX', 'SPRITE DY']) >= 0 then
    begin
      LDef := NewDef(LName, dfkFixed);
      LDef.Tolerance := 256;
    end
    else if LName = 'BITS' then
      LDef := FlagsDef(LName, 'MF')
    else if LName = 'BITS2' then
    begin
      if AHasFlags2 then
        LDef := FlagsDef(LName, 'MF2')
      else
        LDef := NewDef(LName, dfkUnsupported);
    end
    else if LName = 'FLAGS_EX' then
      LDef := FlagsDef(LName, 'MF_EX')
    else if LName = 'FLAGS2_EX' then
      LDef := FlagsDef(LName, 'MF2_EX')
    else if LName = 'FLAGS3_EX' then
      LDef := FlagsDef(LName, 'MF3_EX')
    else if LName = 'FLAGS4_EX' then
      LDef := FlagsDef(LName, 'MF4_EX')
    else if LName = 'FLAGS5_EX' then
      LDef := FlagsDef(LName, 'MF5_EX')
    else if LName = 'FLAGS6_EX' then
      LDef := FlagsDef(LName, 'MF6_EX')
    else if LName = 'MBF21 BITS' then
    begin
      LDef := FlagsDef(LName, 'MBF21');
      LDef.SetsMbf21 := True;
    end
    else
      LDef := NewDef(LName, dfkInteger);
    Result[LIndex] := LDef;
  end;
  ResolveAliases(Result, ANames,
    ['ACTIVE SOUND', 'RADIUS', 'DROPPED ITEM', 'PAIN FRAME'],
    ['ACTION SOUND', 'WIDTH', 'DROPITEM', 'INJURY FRAME']);
end;

class function TDehackedFieldKinds.FrameDefs(const ANames: TArray<string>): TArray<TDehackedFieldDef>;
var
  LIndex: Integer;
  LName: string;
begin
  SetLength(Result, Length(ANames));
  for LIndex := 0 to High(ANames) do
  begin
    LName := ANames[LIndex];
    if (LName = 'SPRITE NUMBER') or (LName = 'OWNER') then
      Result[LIndex] := NewDef(LName, dfkName)
    else if LName = 'SPRITE SUBNUMBER' then
      Result[LIndex] := NewDef(LName, dfkFrameNumber)
    else if LName = 'NEXT FRAME' then
      Result[LIndex] := NewDef(LName, dfkNextState)
    else if LName = 'CODEP FRAME' then
      Result[LIndex] := NewDef(LName, dfkAction)
    else if LName = 'FLAGS_EX' then
      Result[LIndex] := FlagsDef(LName, 'STATE_EX')
    else if LName = 'MBF21 BITS' then
      Result[LIndex] := FlagsDef(LName, 'STATE_MBF21')
    else
      Result[LIndex] := NewDef(LName, dfkInteger);
  end;
end;

class function TDehackedFieldKinds.WeaponDefs(const ANames: TArray<string>): TArray<TDehackedFieldDef>;
var
  LIndex: Integer;
  LName: string;
begin
  SetLength(Result, Length(ANames));
  for LIndex := 0 to High(ANames) do
  begin
    LName := ANames[LIndex];
    if (LName = 'AMMO TYPE') or (LName = 'MANA TYPE') then
      Result[LIndex] := NewDef(LName, dfkName)
    else if IndexStr(LName, ['DESELECT FRAME', 'SELECT FRAME', 'BOBBING FRAME', 'SHOOTING FRAME',
      'FIRING FRAME', 'HOLD SHOOTING FRAME']) >= 0 then
      Result[LIndex] := NewDef(LName, dfkState)
    else if LName = 'AMMO PER SHOT' then
      Result[LIndex] := NewDef(LName, dfkPositive)
    else if LName = 'LEVEL' then
    begin
      Result[LIndex] := NewDef(LName, dfkLevel);
      Result[LIndex].Tolerance := 2;
    end
    else if LName = 'MBF21 BITS' then
      Result[LIndex] := FlagsDef(LName, 'WEAPON_MBF21')
    else
      Result[LIndex] := NewDef(LName, dfkInteger);
  end;
end;

class function TDehackedFieldKinds.CountDefs(const ANames: TArray<string>): TArray<TDehackedFieldDef>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(ANames));
  for LIndex := 0 to High(ANames) do
    if ANames[LIndex] = 'NAME' then
      Result[LIndex] := NewDef(ANames[LIndex], dfkName, 0)
    else
      Result[LIndex] := NewDef(ANames[LIndex], dfkInteger, 0);
end;

end.
