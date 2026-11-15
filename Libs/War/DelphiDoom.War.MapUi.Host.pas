{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - what the model asks of the game around it         }
{                                                                              }
{  Port of war1 (acoto87/war1), war_entities.c (the messages of the status      }
{  bar), (c) 2019 Alejandro Coto Gutierrez, zlib License (see                   }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.MapUi.Host;

{$R-}
{$Q-}

interface

uses
  System.SysUtils, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.Selection,
  DelphiDoom.War.Model.Gather.Intf, DelphiDoom.War.Model.Construction.Intf, DelphiDoom.War.Map.Intf,
  DelphiDoom.War.Map.Fog, DelphiDoom.War.Ui.Intf, DelphiDoom.War.MapUi.Intf, DelphiDoom.War.MapUi.Sprites,
  DelphiDoom.War.Model.Combat.Intf;

type
  /// <summary>The message that the status bar flashes for a while: the text and the real time it ends</summary>
  TWarFlashStatus = record
    Enabled: Boolean;
    EndRealTime: Double;
    Text: AnsiString;
  end;

  /// <summary>What the scene of the map asks of its host besides what the model asks (the scene holds only this interface)</summary>
  IWarMapHost = interface
    ['{6A94E1D3-2B07-4C58-9F3A-D1E80B7C5A24}']
    /// <summary>The parts that exist only once the map is built (not owned: they belong to the scene)</summary>
    procedure Attach(const ASelection: TWarSelection; const AFog: TWarFogOfWar; const ASprites: TWarMapSprites);
    procedure Detach;
    procedure SetRealTime(AValue: Double);
    function GetFlash: TWarFlashStatus;
    procedure SetFlash(const AValue: TWarFlashStatus);
    /// <summary>Where the sounds that the model asks for go (not owned by the host: nil is silence)</summary>
    procedure AttachAudio(const AAudio: IWarMapAudio);
  end;

  /// <summary>
  ///   The ears of the model in the game of the map: it tells the game when to flash a message (wmui_setFlashStatus), when
  ///   an entity leaves the selection, and it answers what the states of building and training ask (how many frames an image
  ///   has, whether a tile is known). The sounds are not played here: the audio is the part of the game that is not ported
  ///   (it stays behind IWarSceneAudio, with the tracks of the music), so a sound asked for is nothing. Not counted by
  ///   reference users: the scene owns it
  /// </summary>
  TWarMapHost = class(TInterfacedObject, IWarMapHost, IWarModelEvents, IWarGatherEvents, IWarConstructionHost,
    IWarCombatEvents, IWarSpellEvents)
  strict private
    FSelection: TWarSelection;
    FFog: TWarFogOfWar;
    FSprites: TWarMapSprites;
    FUnits: IWarUnitCatalog;
    FFlash: TWarFlashStatus;
    FRealTime: Double;
    FAudio: IWarMapAudio;
    procedure Flash(const AText: AnsiString);
  public
    /// <summary>Nothing is owned; the selection, the fog and the sprites belong to the scene, which must outlive this object</summary>
    constructor Create(const AUnits: IWarUnitCatalog);
    /// <summary>The parts that exist only once the map is built</summary>
    procedure Attach(const ASelection: TWarSelection; const AFog: TWarFogOfWar; const ASprites: TWarMapSprites);
    procedure Detach;
    procedure FlashStatus(AMessage: TWarStatusMessage);
    procedure EntityLeftSelection(AEntityId: Word);
    procedure UnitDied(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
    procedure BuildingCollapsing(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
    procedure BuildingDamaged(AEntityId: Word; AHpPercent: Integer);
    procedure TreeChopped(const APosition: TWarVec2);
    procedure AttackSound(const APosition: TWarVec2; ASoundStep: Integer);
    procedure ArrowHit(const APosition: TWarVec2);
    procedure Explosion(const APosition: TWarVec2; ARainOfFire: Boolean);
    procedure SpellCast(const APosition: TWarVec2);
    procedure SummonExpired(const APosition: TWarVec2; AUnitType: Integer);
    function UnitFrames(AUnitType: Integer): Integer;
    function ConstructionFrames(AUnitType: Integer): Integer;
    procedure PlaySound(AAudioId: Integer);
    procedure PlayRandomSound(AFromId, AToId: Integer);
    procedure Acknowledge(APlayer: Integer);
    function IsTileKnown(ATileX, ATileY: Integer): Boolean;
    /// <summary>The real time of this tic, which the flash of the status counts from</summary>
    procedure SetRealTime(AValue: Double);
    function GetFlash: TWarFlashStatus;
    procedure SetFlash(const AValue: TWarFlashStatus);
    procedure AttachAudio(const AAudio: IWarMapAudio);
  end;

implementation

uses
  DelphiDoom.War.Map.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.BuildingResources.Data,
  DelphiDoom.War.Model.UnitClassifier, DelphiDoom.War.Sound.Ids;

{ TWarMapHost }

constructor TWarMapHost.Create(const AUnits: IWarUnitCatalog);
begin
  inherited Create;
  FUnits := AUnits;
end;

procedure TWarMapHost.Attach(const ASelection: TWarSelection; const AFog: TWarFogOfWar; const ASprites: TWarMapSprites);
begin
  FSelection := ASelection;
  FFog := AFog;
  FSprites := ASprites;
end;

procedure TWarMapHost.Detach;
begin
  FAudio := nil;
  FSelection := nil;
  FFog := nil;
  FSprites := nil;
end;

procedure TWarMapHost.SetRealTime(AValue: Double);
begin
  FRealTime := AValue;
end;

function TWarMapHost.GetFlash: TWarFlashStatus;
begin
  Result := FFlash;
end;

procedure TWarMapHost.SetFlash(const AValue: TWarFlashStatus);
begin
  FFlash := AValue;
end;

procedure TWarMapHost.Flash(const AText: AnsiString);
begin
  // wmui_setFlashStatus(context, 1.5f, text)
  FFlash.Enabled := True;
  FFlash.EndRealTime := FRealTime + Single(1.5);
  FFlash.Text := AText;
end;

procedure TWarMapHost.FlashStatus(AMessage: TWarStatusMessage);
begin
  case AMessage of
    wsmNotEnoughGold:
      Flash('NOT ENOUGH GOLD... MINE MORE GOLD');
    wsmNotEnoughLumber:
      Flash('NOT ENOUGH LUMBER... CHOP MORE TREES');
    wsmNotEnoughMana:
      Flash('NOT ENOUGH MANA');
    wsmNotEnoughFood:
      Flash('NOT ENOUGH FOOD... BUILD MORE FARMS');
    wsmCantBuildThere:
      Flash('CAN''T BUILD THERE');
  end;
end;

procedure TWarMapHost.EntityLeftSelection(AEntityId: Word);
begin
  if Assigned(FSelection) then
    FSelection.Remove(AEntityId);
end;

procedure TWarMapHost.UnitDied(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
begin
  // we_takeDamage: the sound of a death: a spider or a scorpion, a catapult (one of the sounds of a collapse, drawn), or a
  // dying man of the humans or of the orcs (a unit of no race is an orc)
  if (AUnitType = WAR_UNIT_SCORPION) or (AUnitType = WAR_UNIT_SPIDER) then
    PlaySound(WAR_SND_DEAD_SPIDER_SCORPION)
  else if (AUnitType = WAR_UNIT_CATAPULT_HUMANS) or (AUnitType = WAR_UNIT_CATAPULT_ORCS) then
    PlayRandomSound(WAR_SND_BUILDING_COLLAPSE_FIRST, WAR_SND_BUILDING_COLLAPSE_LAST)
  else if TWarUnitClassifier.RaceOf(AUnitType) = wraHumans then
    PlaySound(WAR_SND_HUMAN_DEAD)
  else
    PlaySound(WAR_SND_ORC_DEAD);
end;

procedure TWarMapHost.BuildingCollapsing(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
begin
  PlayRandomSound(WAR_SND_BUILDING_COLLAPSE_FIRST, WAR_SND_BUILDING_COLLAPSE_LAST);
end;

procedure TWarMapHost.BuildingDamaged(AEntityId: Word; AHpPercent: Integer);
begin
end;

procedure TWarMapHost.TreeChopped(const APosition: TWarVec2);
begin
  PlayRandomSound(WAR_SND_TREE_CHOPPING_FIRST, WAR_SND_TREE_CHOPPING_LAST);
end;

procedure TWarMapHost.AttackSound(const APosition: TWarVec2; ASoundStep: Integer);
begin
  // wa_playAttackSound: the sword is one of three (drawn); the fist, the fireball, the catapult and the arrow are one; any other
  // step (the lightning) has no sound and makes no entity
  case ASoundStep of
    WAR_ACTION_STEP_SOUND_SWORD:
      PlayRandomSound(WAR_SND_SWORD_ATTACK_FIRST, WAR_SND_SWORD_ATTACK_LAST);
    WAR_ACTION_STEP_SOUND_FIST:
      PlaySound(WAR_SND_FIST_ATTACK);
    WAR_ACTION_STEP_SOUND_FIREBALL:
      PlaySound(WAR_SND_FIREBALL);
    WAR_ACTION_STEP_SOUND_CATAPULT:
      PlaySound(WAR_SND_CATAPULT_ROCK_FIRED);
    WAR_ACTION_STEP_SOUND_ARROW:
      PlaySound(WAR_SND_ARROW_SPEAR);
  end;
end;

procedure TWarMapHost.ArrowHit(const APosition: TWarVec2);
begin
  PlaySound(WAR_SND_ARROW_SPEAR_HIT);
end;

procedure TWarMapHost.Explosion(const APosition: TWarVec2; ARainOfFire: Boolean);
begin
  PlaySound(WAR_SND_CATAPULT_FIRE_EXPLOSION);
end;

procedure TWarMapHost.SpellCast(const APosition: TWarVec2);
begin
  PlaySound(WAR_SND_NORMAL_SPELL);
end;

procedure TWarMapHost.SummonExpired(const APosition: TWarVec2; AUnitType: Integer);
begin
  PlaySound(WAR_SND_DEAD_SPIDER_SCORPION);
end;

function TWarMapHost.UnitFrames(AUnitType: Integer): Integer;
var
  LData: TWarUnitData;
begin
  // the frames of the sprite that the unit has when it is made (the record of its image)
  if (not Assigned(FSprites)) or (not FUnits.TryGetData(AUnitType, LData)) then
    Exit(0);
  Result := FSprites.Get(LData.ResourceIndex).FrameCount;
end;

function TWarMapHost.ConstructionFrames(AUnitType: Integer): Integer;
var
  LIndex: Integer;
begin
  LIndex := AUnitType - WAR_BUILDING_FIRST_TYPE;
  if (not Assigned(FSprites)) or (LIndex < 0) or (LIndex > High(WAR_BUILDING_CONSTRUCTION_RESOURCES)) then
    Exit(0);
  Result := FSprites.Get(WAR_BUILDING_CONSTRUCTION_RESOURCES[LIndex]).FrameCount;
end;

procedure TWarMapHost.AttachAudio(const AAudio: IWarMapAudio);
begin
  FAudio := AAudio;
end;

procedure TWarMapHost.PlaySound(AAudioId: Integer);
begin
  if Assigned(FAudio) then
    FAudio.PlaySound(AAudioId);
end;

procedure TWarMapHost.PlayRandomSound(AFromId, AToId: Integer);
begin
  if Assigned(FAudio) then
    FAudio.PlayRandomSound(AFromId, AToId);
end;

procedure TWarMapHost.Acknowledge(APlayer: Integer);
begin
  if Assigned(FAudio) then
    FAudio.Acknowledge(APlayer);
end;

function TWarMapHost.IsTileKnown(ATileX, ATileY: Integer): Boolean;
begin
  Result := (not Assigned(FFog)) or (not FFog.IsTileUnknown(ATileX, ATileY));
end;

end.
