{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - a definition as the text of a patch          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.DehWriter;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.ActorDef.Types, DelphiDoom.ActorDef.Intf,
  DelphiDoom.ActorDef.GotoResolver;

type
  /// <summary>
  ///   Writes an actor or a weapon as the text of a patch (DEH) that the engine already reads
  ///   (NewThing ..., WEAPON ..., Frame NewFrame ...): this is how a definition reaches the tables
  ///   of the engine. While it writes it gives the states their names (the state catalog), gives
  ///   the actor that replaces another one the name of the other as an alias, and resolves the
  ///   gotos that name a state of the engine or of another actor
  /// </summary>
  TActorDefDehWriter = class
  private
    FProfile: TActorDefProfile;
    FActors: IActorDefActorCatalog;
    FStates: IActorDefStateCatalog;
    FSounds: IActorDefSoundResolver;
    FResolver: TActorDefGotoResolver;
    FText: string;
    procedure AddLine(const ALine: string);
    procedure AddStateLine(AState: Integer; const APrefix: string);
    procedure AddNextFrame(const AState: TActorDefState; AIndex: Integer; AIsWeapon: Boolean;
      const AActor: TActorDefActor; const AWeapon: TActorDefWeapon);
    procedure AddStates(const AStates: TActorDefStates; const ANamePrefix, AOwnerName: string;
      AIsWeapon: Boolean; const AActor: TActorDefActor; const AWeapon: TActorDefWeapon);
  public
    constructor Create(const AProfile: TActorDefProfile; const AActors: IActorDefActorCatalog;
      const AStates: IActorDefStateCatalog; const ASounds: IActorDefSoundResolver;
      const ALog: ILog);
    destructor Destroy; override;
    function ActorText(const AActor: TActorDefActor): string;
    function WeaponText(const AWeapon: TActorDefWeapon): string;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

{ TActorDefDehWriter }

constructor TActorDefDehWriter.Create(const AProfile: TActorDefProfile;
  const AActors: IActorDefActorCatalog; const AStates: IActorDefStateCatalog;
  const ASounds: IActorDefSoundResolver; const ALog: ILog);
begin
  inherited Create;
  FProfile := AProfile;
  FActors := AActors;
  FStates := AStates;
  FSounds := ASounds;
  FResolver := TActorDefGotoResolver.Create(AActors, AStates, ALog);
end;

destructor TActorDefDehWriter.Destroy;
begin
  FResolver.Free;
  inherited Destroy;
end;

procedure TActorDefDehWriter.AddLine(const ALine: string);
begin
  FText := FText + ALine + #13#10;
end;

procedure TActorDefDehWriter.AddStateLine(AState: Integer; const APrefix: string);
begin
  if AState = -1 then
    AddLine(APrefix + ' Frame = OriginalFrame 0')
  else if AState >= ACTORDEF_ORIGINAL_STATE_MARKER then
    AddLine(APrefix + ' Frame = OriginalFrame ' + IntToStr(AState - ACTORDEF_ORIGINAL_STATE_MARKER))
  else
    AddLine(APrefix + ' Frame = NewFrame ' + IntToStr(AState));
end;

procedure TActorDefDehWriter.AddNextFrame(const AState: TActorDefState; AIndex: Integer;
  AIsWeapon: Boolean; const AActor: TActorDefActor; const AWeapon: TActorDefWeapon);
begin
  if AState.GotoNeedsCalc then
  begin
    if AIsWeapon then
      AddLine('Next Frame = ' + FResolver.ResolveForWeapon(AState.GotoText, AWeapon))
    else
      AddLine('Next Frame = ' + FResolver.ResolveForActor(AState.GotoText, AActor));
  end
  else if AState.NextState >= ACTORDEF_ORIGINAL_STATE_MARKER then
    AddLine('Next Frame = OriginalFrame ' + IntToStr(AState.NextState - ACTORDEF_ORIGINAL_STATE_MARKER))
  else if AState.NextState >= 0 then
    AddLine('Next Frame = NewFrame ' + IntToStr(AState.NextState))
  else
    AddLine('Next Frame = OriginalFrame 0');
end;

procedure TActorDefDehWriter.AddStates(const AStates: TActorDefStates; const ANamePrefix,
  AOwnerName: string; AIsWeapon: Boolean; const AActor: TActorDefActor;
  const AWeapon: TActorDefWeapon);
var
  LIndex: Integer;
  LState: TActorDefState;
begin
  if Length(AStates) = 0 then
    Exit;
  for LIndex := 0 to High(AStates) do
  begin
    LState := AStates[LIndex];
    if LState.Alias <> '' then
      FStates.Add(ANamePrefix + IntToStr(LIndex) + ', ' + LState.Alias + ', ' + AOwnerName + '::' +
        LState.Alias)
    else
      FStates.Add(ANamePrefix + IntToStr(LIndex));
    AddLine('Frame NewFrame ' + IntToStr(LIndex));
    AddLine('Sprite Number = ' + LState.Sprite);
    if LState.Bright then
      AddLine('Sprite Subnumber = Bright ' + IntToStr(LState.Frame))
    else
      AddLine('Sprite Subnumber = ' + IntToStr(LState.Frame));
    AddLine('Duration = ' + IntToStr(LState.Tics));
    AddLine('Duration 2 = ' + IntToStr(LState.Tics2));
    AddNextFrame(LState, LIndex, AIsWeapon, AActor, AWeapon);
    AddLine('Codep Frame = ' + LState.Action);
    AddLine('Unknown 1 = 0');
    AddLine('Unknown 2 = 0');
    if (not AIsWeapon) or FProfile.WeaponStatesWriteFlagsEx then
      AddLine('Flags_ex = ' + IntToStr(LState.FlagsEx));
    if not AIsWeapon then
      AddLine('Owner = ' + AActor.Name);

    // MBF21
    if LState.Fast then
      AddLine('MBF21 BITS = STATEF_SKILL5FAST');

    AddLine('');
  end;
  AddLine('');
  AddLine('');
  AddLine('SubmitNewFrames');
end;

function TActorDefDehWriter.ActorText(const AActor: TActorDefActor): string;
var
  LActor: TActorDefActor;
  LWeapon: TActorDefWeapon;
begin
  // the speed of a missile is changed here: the actor of the caller stays as it is
  LActor := AActor;
  LWeapon := Default(TActorDefWeapon);
  FText := '';

  if LActor.ReplacesId >= 0 then
  begin
    AddLine('Thing ' + IntToStr(LActor.ReplacesId + 1)); // the patches count the things from 1
    FActors.AddAlias(LActor.Name, FActors.NameOf(LActor.ReplacesId));
  end
  else
    AddLine('NewThing "' + LActor.Name + '"');
  if LActor.InheritsFrom <> '' then
    AddLine('Inheritsfrom = "' + LActor.InheritsFrom + '"')
  else
    AddLine('Inheritsfrom = -1');
  if FProfile.HasStrifeName then
    if LActor.Name2 <> '' then
      AddLine('name = ' + LActor.Name2);
  AddLine('Id # = ' + IntToStr(LActor.DoomedNum));
  AddStateLine(LActor.SpawnState, 'Initial');
  AddLine('Hit Points = ' + IntToStr(LActor.SpawnHealth));
  AddStateLine(LActor.SeeState, 'First Moving');
  AddLine('Alert Sound = ' + FSounds.Resolve(LActor.SeeSound));
  AddLine('Reaction Time = ' + IntToStr(LActor.ReactionTime));
  AddLine('Attack Sound = ' + FSounds.Resolve(LActor.AttackSound));
  AddStateLine(LActor.PainState, 'Injury');
  AddLine('Pain Chance = ' + IntToStr(LActor.PainChance));
  AddLine('Pain Sound = ' + FSounds.Resolve(LActor.PainSound));
  AddStateLine(LActor.MeleeState, 'Close Attack');
  AddStateLine(LActor.MissileState, 'Far Attack');
  AddStateLine(LActor.DeathState, 'Death');
  AddStateLine(LActor.XDeathState, 'Exploding');
  AddStateLine(LActor.HealState, 'Heal');
  AddStateLine(LActor.CrashState, 'Crash');
  AddStateLine(LActor.CrushState, 'Crush');
  AddStateLine(LActor.InteractState, 'Interact');
  AddLine('Death Sound = ' + FSounds.Resolve(LActor.DeathSound));
  if Pos('MF_MISSILE', LActor.Flags) > 0 then
    if LActor.Speed < 2048 then // the speed of a missile is in fixed point
      LActor.Speed := LActor.Speed * ACTORDEF_FRACUNIT;
  AddLine('Speed = ' + IntToStr(LActor.Speed));
  AddLine('VSpeed = ' + IntToStr(Round(LActor.VSpeed * ACTORDEF_FRACUNIT)));
  AddLine('MinMissileChance = ' + IntToStr(LActor.MinMissileChance));
  AddLine('Pushfactor = ' + IntToStr(Round(LActor.PushFactor * ACTORDEF_FRACUNIT)));
  AddLine('Friction = ' + IntToStr(Round(LActor.Friction * ACTORDEF_FRACUNIT)));
  AddLine('Width = ' + IntToStr(LActor.Radius * ACTORDEF_FRACUNIT));
  AddLine('Height = ' + IntToStr(LActor.Height * ACTORDEF_FRACUNIT));
  AddLine('Mass = ' + IntToStr(LActor.Mass));
  AddLine('Missile Damage = ' + IntToStr(LActor.Damage));
  AddLine('Action Sound = ' + FSounds.Resolve(LActor.ActiveSound));
  AddStateLine(LActor.RaiseState, 'Respawn');
  AddLine('Bits = ' + LActor.Flags);
  AddLine('flags_ex = ' + LActor.FlagsEx);
  AddLine('Custom Sound 1 = ' + FSounds.Resolve(LActor.CustomSound1));
  AddLine('Custom Sound 2 = ' + FSounds.Resolve(LActor.CustomSound2));
  AddLine('Custom Sound 3 = ' + FSounds.Resolve(LActor.CustomSound3));
  AddLine('Melee Damage = ' + IntToStr(LActor.MeleeDamage));
  AddLine('Melee Sound = ' + FSounds.Resolve(LActor.MeleeSound));
  AddLine('Explosion Damage = ' + IntToStr(LActor.ExplosionDamage));
  AddLine('Explosion Radius = ' + IntToStr(LActor.ExplosionRadius));
  AddLine('Dropitem = ' + LActor.DropItem);
  AddLine('Missiletype = ' + LActor.MissileType);
  if LActor.RenderStyle <> '' then
    AddLine('Renderstyle = ' + LActor.RenderStyle)
  else
    AddLine('Renderstyle = NORMAL');
  AddLine('Alpha = ' + IntToStr(LActor.Alpha));
  AddLine('flags2_ex = ' + LActor.Flags2Ex);
  AddLine('flags3_ex = ' + LActor.Flags3Ex);
  AddLine('flags4_ex = ' + LActor.Flags4Ex);
  AddLine('missileheight = ' + IntToStr(LActor.MissileHeight));
  AddLine('melee threshold = ' + IntToStr(LActor.MeleeThreshold));
  AddLine('Scale = ' + IntToStr(Round(LActor.Scale * ACTORDEF_FRACUNIT)));
  AddLine('Gravity = ' + IntToStr(Round(LActor.Gravity * ACTORDEF_FRACUNIT)));
  AddLine('Float Speed = ' + IntToStr(LActor.FloatSpeed));
  AddLine('Normal Speed = ' + IntToStr(LActor.NormalSpeed));
  AddLine('Fast Speed = ' + IntToStr(LActor.FastSpeed));
  AddLine('Obituary = "' + LActor.Obituary + '"');
  AddLine('Hit Obituary = "' + LActor.HitObituary + '"');
  if LActor.Gender <> '' then
    AddLine('Gender = ' + LActor.Gender)
  else
    AddLine('Gender = DEFAULT');
  AddLine('Melee Range = ' + IntToStr(LActor.MeleeRange));
  AddLine('Max Step Height = ' + IntToStr(LActor.MaxStepHeight));
  AddLine('Max DropOff Height = ' + IntToStr(LActor.MaxDropoffHeight));
  AddLine('Gib Health = ' + IntToStr(LActor.GibHealth));
  AddLine('Max Target Range = ' + IntToStr(LActor.MaxTargetRange));
  AddLine('Weave Index XY = ' + IntToStr(LActor.WeaveIndexXY));
  AddLine('Weave Index Z = ' + IntToStr(LActor.WeaveIndexZ));
  AddLine('Sprite DX = ' + IntToStr(Round(LActor.SpriteDX * ACTORDEF_FRACUNIT)));
  AddLine('Sprite DY = ' + IntToStr(Round(LActor.SpriteDY * ACTORDEF_FRACUNIT)));
  AddLine('flags5_ex = ' + LActor.Flags5Ex);
  AddLine('flags6_ex = ' + LActor.Flags6Ex);
  AddLine('Rip Sound = ' + FSounds.Resolve(LActor.RipSound));
  AddLine('Blood Color = ' + LActor.BloodColor);
  AddLine('Translation = ' + LActor.Translation);

  AddLine('');

  AddStates(LActor.States, 'S_' + TScannerStrings.UpperAscii(LActor.Name), LActor.Name, False,
    LActor, LWeapon);

  AddLine('');
  AddLine('');
  Result := FText;
end;

function TActorDefDehWriter.WeaponText(const AWeapon: TActorDefWeapon): string;
var
  LActor: TActorDefActor;
  LHeader: string;
begin
  LActor := Default(TActorDefActor);
  FText := '';

  LHeader := 'WEAPON ' + IntToStr(AWeapon.WeaponNo);
  if FProfile.WeaponHasPlayerClass then
    LHeader := LHeader + ' ' + IntToStr(AWeapon.PlayerClass);
  AddLine(LHeader);
  if FProfile.WeaponHasLevel then
    AddLine('Level ' + IntToStr(AWeapon.Level));
  AddLine('Ammo Type = ' + IntToStr(AWeapon.Ammo));
  AddStateLine(AWeapon.UpState, 'DESELECT');
  AddStateLine(AWeapon.DownState, 'SELECT');
  AddStateLine(AWeapon.ReadyState, 'BOBBING');
  AddStateLine(AWeapon.AttackState, 'SHOOTING');
  AddStateLine(AWeapon.HoldAttackState, 'HOLD SHOOTING');
  AddStateLine(AWeapon.FlashState, 'FIRING');
  AddLine('MBF21 BITS = ' + AWeapon.Flags);
  AddLine('AMMO PER SHOT = ' + IntToStr(AWeapon.AmmoPerShot));

  AddLine('');

  AddStates(AWeapon.States, 'S_WEAPON' + IntToStr(AWeapon.WeaponNo) + '_',
    'WEAPON' + IntToStr(AWeapon.WeaponNo), True, LActor, AWeapon);

  AddLine('');
  AddLine('');
  Result := FText;
end;

end.
