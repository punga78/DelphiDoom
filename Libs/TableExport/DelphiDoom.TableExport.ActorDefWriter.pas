{******************************************************************************}
{                                                                              }
{  DelphiDoom: TableExport library - the things as ACTOR definitions           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TableExport.ActorDefWriter;

interface

uses
  DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf, DelphiDoom.TableExport.StateChain,
  DelphiDoom.TableExport.IndentedText;

type
  /// <summary>
  ///   Writes a thing as an ACTOR of ACTORDEF/DECORATE: the properties that are not the
  ///   default one, the flags and the states. The text is the one that the parser of the
  ///   library reads back
  /// </summary>
  TExportActorDefWriter = class(TInterfacedObject, IExportActorDefWriter)
  strict private
    FThings: IExportThingSource;
    FEnums: IExportEnumNames;
    FFlags: IExportFlagNames;
    FLookups: IExportLookups;
    FChain: TExportStateChain;
    procedure AddProperties(const AText: TExportIndentedText; const AThing: TExportThing);
    procedure AddFlags(const AText: TExportIndentedText; const AThing: TExportThing);
    procedure AddStates(const AText: TExportIndentedText; const AThing: TExportThing);
  public
    /// <exception cref="EArgumentNilException">A source is nil</exception>
    constructor Create(const AThings: IExportThingSource; const AStates: IExportStateSource;
      const AEnums: IExportEnumNames; const AFlags: IExportFlagNames; const ALookups: IExportLookups);
    destructor Destroy; override;
    function WriteAll: string;
    function Write(AIndex: Integer): string;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.TableExport.Text;

type
  /// <summary>When a property is written and how</summary>
  TPropertyKind = (
    /// <summary>The number, if it is above zero</summary>
    pkPositive,
    /// <summary>The number, if it is not zero</summary>
    pkNotZero,
    /// <summary>The number, if it is not the default one</summary>
    pkNotDefault,
    /// <summary>Fixed point "1.0000", if it is not zero</summary>
    pkFixedNotZero,
    /// <summary>Fixed point, if it is not the default one</summary>
    pkFixedNotDefault,
    /// <summary>The name of a sound, if there is one</summary>
    pkSound,
    /// <summary>The name of a thing in quotes, if the number is above zero</summary>
    pkThing,
    /// <summary>The name of the thing that it inherits from, if the number is zero or more</summary>
    pkInherits,
    /// <summary>The text in quotes, if it is not empty</summary>
    pkQuoted,
    /// <summary>The width and the height: always, in map units</summary>
    pkUnits,
    /// <summary>The name of a group, if it is not the default (zero)</summary>
    pkGroup,
    /// <summary>The render style if it is not the normal one, and then its alpha if there is one</summary>
    pkRenderStyle,
    pkGender,
    pkBloodColor);

  TPropertyDef = record
    Name: string;
    Field: Integer;
    Kind: TPropertyKind;
    Default: Integer;
    Group: TExportGroup;
  end;

function Prop(const AName: string; AField: TExportThingField; AKind: TPropertyKind;
  ADefault: Integer = 0): TPropertyDef;
begin
  Result := Default(TPropertyDef);
  Result.Name := AName;
  Result.Field := Ord(AField);
  Result.Kind := AKind;
  Result.Default := ADefault;
end;

function TextProp(const AName: string; AText: TExportThingText): TPropertyDef;
begin
  Result := Default(TPropertyDef);
  Result.Name := AName;
  Result.Field := Ord(AText);
  Result.Kind := pkQuoted;
end;

function GroupProp(const AName: string; AField: TExportThingField; AGroup: TExportGroup): TPropertyDef;
begin
  Result := Prop(AName, AField, pkGroup);
  Result.Group := AGroup;
end;

/// <summary>The properties in the order that the old code wrote them</summary>
function PropertyDefs: TArray<TPropertyDef>;
begin
  Result := [
    Prop('Health', tfSpawnHealth, pkPositive),
    Prop('Inherits', tfInheritsFrom, pkInherits),
    Prop('Width', tfRadius, pkUnits),
    Prop('Height', tfHeight, pkUnits),
    Prop('Vspeed', tfVSpeed, pkFixedNotZero),
    Prop('MinMissileChance', tfMinMissileChance, pkNotZero),
    Prop('Pushfactor', tfPushFactor, pkNotDefault, EXPORT_DEFAULT_PUSHFACTOR),
    Prop('Friction', tfFriction, pkNotDefault, EXPORT_ORIGINAL_FRICTION),
    Prop('Scale', tfScale, pkFixedNotDefault, EXPORT_FRACUNIT),
    Prop('Gravity', tfGravity, pkFixedNotDefault, EXPORT_FRACUNIT),
    Prop('Speed', tfSpeed, pkNotZero),
    Prop('Damage', tfDamage, pkNotZero),
    Prop('Painchance', tfPainChance, pkNotZero),
    Prop('Mass', tfMass, pkNotZero),
    Prop('Reactiontime', tfReactionTime, pkNotZero),
    Prop('Dropitem', tfDropItem, pkThing),
    Prop('Missiletype', tfMissileType, pkThing),
    Prop('Explosiondamage', tfExplosionDamage, pkPositive),
    Prop('Explosionradius', tfExplosionRadius, pkPositive),
    Prop('Meleedamage', tfMeleeDamage, pkPositive),
    Prop('Seesound', tfSeeSound, pkSound),
    Prop('Attacksound', tfAttackSound, pkSound),
    Prop('Painsound', tfPainSound, pkSound),
    Prop('Deathsound', tfDeathSound, pkSound),
    Prop('Activesound', tfActiveSound, pkSound),
    Prop('Customsound1', tfCustomSound1, pkSound),
    Prop('Customsound2', tfCustomSound2, pkSound),
    Prop('Customsound3', tfCustomSound3, pkSound),
    Prop('Meleesound', tfMeleeSound, pkSound),
    Prop('Ripsound', tfRipSound, pkSound),
    Prop('Floatspeed', tfFloatSpeed, pkPositive),
    Prop('Normalspeed', tfNormalSpeed, pkPositive),
    Prop('Fastspeed', tfFastSpeed, pkPositive),
    TextProp('Obituary', ttObituary),
    TextProp('HitObituary', ttHitObituary),
    Prop('MissileHeight', tfMissileHeight, pkPositive),
    Prop('MeleeThreshold', tfMeleeThreshold, pkPositive),
    Prop('Renderstyle', tfRenderStyle, pkRenderStyle),
    Prop('Gender', tfGender, pkGender),
    Prop('MeleeRange', tfMeleeRange, pkNotZero),
    Prop('MaxStepHeight', tfMaxStepHeight, pkFixedNotZero),
    Prop('MaxDropOffHeight', tfMaxDropoffHeight, pkFixedNotZero),
    Prop('GibHealth', tfGibHealth, pkNotZero),
    Prop('MaxTargetRange', tfMaxTargetRange, pkNotZero),
    Prop('WeaveIndexXY', tfWeaveIndexXY, pkNotZero),
    Prop('WeaveIndexZ', tfWeaveIndexZ, pkNotZero),
    Prop('spriteDX', tfSpriteDX, pkNotZero),
    Prop('spriteDY', tfSpriteDY, pkNotZero),
    GroupProp('InfightingGroup', tfInfightingGroup, egInfighting),
    GroupProp('ProjectileGroup', tfProjectileGroup, egProjectile),
    GroupProp('SplashGroup', tfSplashGroup, egSplash),
    Prop('Bloodcolor', tfBloodColor, pkBloodColor),
    TextProp('Translation', ttTranslation)
  ];
end;

const
  FLAG_SETS: array[0..6] of TExportFlagSet = (
    fsMobjFlags, fsMobjFlagsEx, fsMobjFlags2Ex, fsMobjFlags3Ex, fsMobjFlags4Ex, fsMobjFlags5Ex,
    fsMobjFlags6Ex);
  FLAG_FIELDS: array[0..6] of TExportThingField = (
    tfFlags, tfFlagsEx, tfFlags2Ex, tfFlags3Ex, tfFlags4Ex, tfFlags5Ex, tfFlags6Ex);

{ TExportActorDefWriter }

constructor TExportActorDefWriter.Create(const AThings: IExportThingSource;
  const AStates: IExportStateSource; const AEnums: IExportEnumNames; const AFlags: IExportFlagNames;
  const ALookups: IExportLookups);
begin
  inherited Create;
  if not Assigned(AThings) then
    raise EArgumentNilException.Create('AThings');
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(AEnums) then
    raise EArgumentNilException.Create('AEnums');
  if not Assigned(AFlags) then
    raise EArgumentNilException.Create('AFlags');
  if not Assigned(ALookups) then
    raise EArgumentNilException.Create('ALookups');
  FThings := AThings;
  FEnums := AEnums;
  FFlags := AFlags;
  FLookups := ALookups;
  FChain := TExportStateChain.Create(AStates);
end;

destructor TExportActorDefWriter.Destroy;
begin
  FChain.Free;
  inherited Destroy;
end;

procedure TExportActorDefWriter.AddProperties(const AText: TExportIndentedText;
  const AThing: TExportThing);
var
  LDef: TPropertyDef;
  LNumber: Integer;
  LText: string;
begin
  for LDef in PropertyDefs do
  begin
    if LDef.Kind = pkQuoted then
    begin
      LText := AThing.Texts[TExportThingText(LDef.Field)];
      if LText <> '' then
        AText.AddLine(LDef.Name + ' "' + LText + '"');
      Continue;
    end;
    LNumber := AThing.Numbers[TExportThingField(LDef.Field)];
    case LDef.Kind of
      pkPositive:
        if LNumber > 0 then
          AText.AddLine(LDef.Name + ' ' + IntToStr(LNumber));
      pkNotZero:
        if LNumber <> 0 then
          AText.AddLine(LDef.Name + ' ' + IntToStr(LNumber));
      pkNotDefault:
        if LNumber <> LDef.Default then
          AText.AddLine(LDef.Name + ' ' + IntToStr(LNumber));
      pkFixedNotZero:
        if LNumber <> 0 then
          AText.AddLine(LDef.Name + ' ' + TExportText.FixedText(LNumber));
      pkFixedNotDefault:
        if LNumber <> LDef.Default then
          AText.AddLine(LDef.Name + ' ' + TExportText.FixedText(LNumber));
      pkSound:
        if LNumber > 0 then
          AText.AddLine(LDef.Name + ' ' + FLookups.SoundName(LNumber));
      pkThing:
        if LNumber > 0 then
          AText.AddLine(LDef.Name + ' "' + FLookups.ThingName(LNumber) + '"');
      pkInherits:
        if LNumber >= 0 then
          AText.AddLine(LDef.Name + ' "' + FLookups.ThingName(LNumber) + '"');
      pkUnits:
        AText.AddLine(LDef.Name + ' ' + IntToStr(LNumber div EXPORT_FRACUNIT));
      pkGroup:
        if LNumber <> 0 then
          AText.AddLine(LDef.Name + ' ' + FLookups.GroupName(LDef.Group, LNumber));
      pkRenderStyle:
        if LNumber <> 0 then
        begin
          AText.AddLine(LDef.Name + ' ' + FLookups.RenderStyleToken(LNumber));
          if AThing.Numbers[tfAlpha] > 0 then
            AText.AddLine('Alpha ' + TExportText.FixedText(AThing.Numbers[tfAlpha]));
        end;
      pkGender:
        if LNumber <> 0 then
          AText.AddLine(LDef.Name + ' ' + FLookups.GenderToken(LNumber));
      pkBloodColor:
        if FLookups.BloodName(LNumber) <> '' then
          AText.AddLine(LDef.Name + ' ' + FLookups.BloodName(LNumber));
    end;
  end;
end;

procedure TExportActorDefWriter.AddFlags(const AText: TExportIndentedText; const AThing: TExportThing);
var
  LSet: Integer;
  LNames: TArray<string>;
  LBit: Integer;
  LValue: Cardinal;
begin
  for LSet := 0 to High(FLAG_SETS) do
  begin
    LNames := FFlags.Names(FLAG_SETS[LSet]);
    LValue := Cardinal(AThing.Numbers[FLAG_FIELDS[LSet]]);
    for LBit := 0 to High(LNames) do
      if (LBit < 32) and ((LValue and (Cardinal(1) shl LBit)) <> 0) then
        AText.AddLine('+' + LNames[LBit]);
  end;
end;

procedure TExportActorDefWriter.AddStates(const AText: TExportIndentedText; const AThing: TExportThing);
var
  LLabels: TArray<TExportStateLabel>;
  LEntry: TExportStateLabel;

  function Entry(const AName: string; AField: TExportThingField): TExportStateLabel;
  begin
    Result.Name := AName;
    Result.State := AThing.Numbers[AField];
  end;

begin
  // The labels that a Goto can name, in the order that the old code compared them
  LLabels := [
    Entry('Spawn', tfSpawnState), Entry('See', tfSeeState), Entry('Melee', tfMeleeState),
    Entry('Missile', tfMissileState), Entry('Pain', tfPainState), Entry('Death', tfDeathState),
    Entry('Xdeath', tfXDeathState), Entry('Raise', tfRaiseState), Entry('Heal', tfHealState),
    Entry('Crash', tfCrashState), Entry('Crush', tfCrushState), Entry('Interact', tfInteractState)
  ];
  AText.AddLine('States');
  AText.AddLine('{');
  for LEntry in LLabels do
    FChain.Write(AText, LEntry.Name, LEntry.State, LLabels);
  AText.AddLine('}');
end;

function TExportActorDefWriter.Write(AIndex: Integer): string;
var
  LText: TExportIndentedText;
  LThing: TExportThing;
  LLine: string;
begin
  LThing := FThings.Get(AIndex);
  LText := TExportIndentedText.Create;
  try
    if (AIndex >= 0) and (AIndex < FEnums.Count(eeMobj)) then
      LText.AddLine('// ' + UpperCase(FEnums.Name(eeMobj, AIndex)));
    LLine := 'ACTOR "' + FLookups.ThingName(AIndex) + '"';
    if LThing.Numbers[tfDoomedNum] > 0 then
      LLine := LLine + ' ' + IntToStr(LThing.Numbers[tfDoomedNum]);
    LText.AddLine(LLine);
    LText.AddLine('{');
    AddProperties(LText, LThing);
    AddFlags(LText, LThing);
    AddStates(LText, LThing);
    LText.AddLine('}');
    LText.AddLine('');
    Result := LText.Text;
  finally
    LText.Free;
  end;
end;

function TExportActorDefWriter.WriteAll: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FThings.Count - 1 do
    Result := Result + Write(LIndex);
end;

end.
