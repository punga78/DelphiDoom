{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the player picks up and the warps           }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): FindWarpDestination,        }
{  CheckItems and CheckWarps of raven.pas                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.ItemRules;

// the positions are 16.16 fixed point numbers and the clock is added to the random numbers as an unsigned
// 32 bit number: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Random, DelphiDoom.Greed.Game.Constants,
  DelphiDoom.Greed.Game.Tables, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.Level.Intf;

const
  /// <summary>MAXAMMO of raven.pas</summary>
  GREED_MAX_AMMO = 300;

type
  /// <summary>
  ///   CheckItems, CheckWarps and FindWarpDestination of raven.pas, line by line. CheckWarps is called at every
  ///   frame with the place of the player: on a warp (128..130 in the plane of the sprites) it looks for the other
  ///   warp with the same number and starts the warp (Warping, WarpX, WarpY: WarpAnim of TGreedLevelRules does the
  ///   rest); on a tile with an item it calls CheckItems; on a tile with a trigger of the script (triggers of
  ///   event.pas, here TGreedGameState.Triggers) it runs its event. CheckItems is what the value of the tile says:
  ///   med tubes and shield charges (used or stored), ammunition, the three boxes, the items of the inventory, the
  ///   bonus item, the primary and secondary goals, the switches of the elevators, the exit and the weapons
  ///   (more ammunition, exchange with the one of the same kind that is dropped nearby, or a new one).
  ///   The globals of the original are the fields of TGreedGameState; the one that is not there is the property
  ///   WarpActive (warpActive of raven.pas). Triggers is the array triggers[x][y] as it lies in memory: the index
  ///   is x * 64 + y. The net game is not ported: the NetItemPickup and NetSoundEffect calls and the branches
  ///   "if netmode" are not here (AUseIt = False, the pickup done by another player, is kept).
  ///   Kept defects: the utility chest gives only the items 6 and 10 of the table (the loop of the original ends
  ///   on "6 or 10 or 12" instead of going on); the ammo box looks at weapons[currentweapon] (the number of the
  ///   slot, not of the weapon) to know if the weapon uses no ammunition; a switch tile is cleared, and its sounds
  ///   are played, once for each elevator of the list (never if the list is empty); the sound of a trigger is at
  ///   (cx * FRACTILEUNIT, cy * FRACTILEUNIT) with cx already in fixed point (it wraps); a weapon whose sprite is
  ///   not on the tile changes the weapon in the hand without giving it.
  ///   Differences: a tile outside the map reads 0 and is not written, a weapon number outside the table is a
  ///   weapon of zeros, and a bonus item without its sprite does not remove it (the original used the memory near
  ///   the arrays and a nil pointer); a weapon whose ammunition kind has no slot (the weapon 6 of the table, the
  ///   grenade launcher, has the kind 3) is left where it is: the original read player.ammo[0] as the slot 5 and
  ///   gave the ammunition to player.bodycount
  /// </summary>
  TGreedItemRules = class
  strict private
    FState: TGreedGameState;
    FSpawner: IGreedSpawner;
    FSound: IGreedGameSound;
    FEvents: IGreedEventRunner;
    FMessages: IGreedMessages;
    FHealth: IGreedPlayerHealth;
    FRandom: IGreedRandom;
    FClock: IGreedSystemClock;
    FHost: IGreedItemHost;
    FWarpActive: Byte;
    function MapSprite(ASpot: Integer): Integer;
    function FloorPic(ASpot: Integer): Integer;
    procedure ClearMapSprite(ASpot: Integer);
    function WeaponInfo(AWeapon: Integer): TGreedWeaponInfo;
    function FindSprite(ATileX, ATileY, AKind: Integer): Integer;
    procedure AddAmmo(AKind, AAmount: Integer);
    procedure PickupSound(ASound, ATileX, ATileY: Integer);
    procedure ReplaceWithGenerator(ASprite: Integer);
    procedure RemoveBox(ASprite: Integer);
    procedure PickupMedPak(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer);
    procedure PickupShield(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer);
    procedure PickupAmmo(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer);
    procedure PickupAmmoBox(ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer);
    procedure PickupMedBox(ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer);
    procedure PickupGoodieBox(ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer);
    procedure PickupInventoryItem(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer);
    procedure PickupBonusItem(ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer);
    procedure PickupGoal(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer;
      APrimary: Boolean);
    procedure ElevatorSwitch(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean);
    procedure PickupWeapon(AValue, ATileX, ATileY, AMapSpot: Integer; ACharType: Integer);
  public
    /// <summary>
    ///   AState has the world, the pools and the globals; ASpawner is SpawnSprite, ASound SoundEffect, AEvents
    ///   RunEvent, AMessages writemsg, AHealth heal, medpaks and addscore, ARandom MS_RndT, AClock clock, AHost
    ///   the status bar, the weapon in the hand and the mouse. EArgumentNilException if one is nil
    /// </summary>
    constructor Create(AState: TGreedGameState; const ASpawner: IGreedSpawner; const ASound: IGreedGameSound;
      const AEvents: IGreedEventRunner; const AMessages: IGreedMessages; const AHealth: IGreedPlayerHealth;
      const ARandom: IGreedRandom; const AClock: IGreedSystemClock; const AHost: IGreedItemHost);
    /// <summary>
    ///   FindWarpDestination(x, y, warpValue): the first other tile with the same warp value; True and the tile
    ///   in AX and AY if no warp is active (the player then stands still: the rates are zeroed)
    /// </summary>
    function FindWarpDestination(var AX, AY: Integer; AWarpValue: Byte): Boolean;
    /// <summary>CheckItems(cx, cy, useit, chartype): the tile (cx, cy); AUseIt False only takes the item away</summary>
    procedure CheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType: Integer);
    /// <summary>CheckWarps(cx, cy): the place of the player in fixed point</summary>
    procedure CheckWarps(ACenterX, ACenterY: TGreedFixed);
    /// <summary>warpActive of raven.pas: the value of the warp the player came out of, 0 when it has left it</summary>
    property WarpActive: Byte read FWarpActive write FWarpActive;
  end;

implementation

const
  TILE = GREED_FRACTILEUNIT;
  SStoredMedTube = 'Stored MedTube!';
  SUsedMedTube = 'Used MedTube!';
  SStoredShield = 'Stored Shield Charge!';
  SUsedShield = 'Used Shield Charge!';
  SBonusItem = 'Bonus Item!';
  SPrimaryGoal = 'Primary goal item!';
  SSecondaryGoal = 'Secondary goal item!';
  SMoreAmmo = 'Found more ammo.';
  SExchangedWeapons = 'Exchanged weapons!';
  SNewWeapon = 'Acquired new weapon!';

{ TGreedItemRules }

constructor TGreedItemRules.Create(AState: TGreedGameState; const ASpawner: IGreedSpawner;
  const ASound: IGreedGameSound; const AEvents: IGreedEventRunner; const AMessages: IGreedMessages;
  const AHealth: IGreedPlayerHealth; const ARandom: IGreedRandom; const AClock: IGreedSystemClock;
  const AHost: IGreedItemHost);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ASpawner) then
    raise EArgumentNilException.Create('ASpawner');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  if not Assigned(AMessages) then
    raise EArgumentNilException.Create('AMessages');
  if not Assigned(AHealth) then
    raise EArgumentNilException.Create('AHealth');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  FState := AState;
  FSpawner := ASpawner;
  FSound := ASound;
  FEvents := AEvents;
  FMessages := AMessages;
  FHealth := AHealth;
  FRandom := ARandom;
  FClock := AClock;
  FHost := AHost;
end;

function TGreedItemRules.MapSprite(ASpot: Integer): Integer;
begin
  if (ASpot < 0) or (ASpot >= GREED_MAP_TILES) then
    Result := 0
  else
    Result := FState.World.GetValue(gpMapSprites, ASpot);
end;

function TGreedItemRules.FloorPic(ASpot: Integer): Integer;
begin
  if (ASpot < 0) or (ASpot >= GREED_MAP_TILES) then
    Result := 0
  else
    Result := FState.World.GetValue(gpFloorPic, ASpot);
end;

procedure TGreedItemRules.ClearMapSprite(ASpot: Integer);
begin
  if (ASpot >= 0) and (ASpot < GREED_MAP_TILES) then
    FState.World.SetValue(gpMapSprites, ASpot, 0);
end;

function TGreedItemRules.WeaponInfo(AWeapon: Integer): TGreedWeaponInfo;
begin
  if (AWeapon < Low(FState.Weapons)) or (AWeapon > High(FState.Weapons)) then
    Result := Default(TGreedWeaponInfo)
  else
    Result := FState.Weapons[AWeapon];
end;

function TGreedItemRules.FindSprite(ATileX, ATileY, AKind: Integer): Integer;
var
  LSprite: PGreedSprite;
begin
  Result := FState.Sprites.First;
  while Result <> GREED_POOL_NIL do
  begin
    LSprite := PGreedSprite(FState.Sprites.Item(Result));
    if (LSprite^.X div TILE = ATileX) and (LSprite^.Y div TILE = ATileY) then
      if LSprite^.Kind = AKind then
        Exit;
    Result := FState.Sprites.Next(Result);
  end;
end;

procedure TGreedItemRules.AddAmmo(AKind, AAmount: Integer);
begin
  if (AKind < Low(FState.Player.Ammo)) or (AKind > High(FState.Player.Ammo)) then
    Exit;
  FState.Player.Ammo[AKind] := FState.Player.Ammo[AKind] + AAmount;
  if FState.Player.Ammo[AKind] > GREED_MAX_AMMO then
    FState.Player.Ammo[AKind] := GREED_MAX_AMMO;
end;

procedure TGreedItemRules.PickupSound(ASound, ATileX, ATileY: Integer);
begin
  FSound.SoundEffect(ASound, 0, ATileX * TILE, ATileY * TILE);
end;

procedure TGreedItemRules.ReplaceWithGenerator(ASprite: Integer);
var
  LSprite: PGreedSprite;
begin
  LSprite := PGreedSprite(FState.Sprites.Item(ASprite));
  FSpawner.SpawnSprite(GREED_S_GENERATOR, LSprite^.X, LSprite^.Y, 0, 0, 0, 0, False, 0);
  FState.Sprites.Remove(ASprite);
end;

procedure TGreedItemRules.RemoveBox(ASprite: Integer);
var
  LEvent: Integer;
begin
  LEvent := PGreedSprite(FState.Sprites.Item(ASprite))^.DeathEvent;
  if LEvent <> 0 then
    FEvents.RunEvent(LEvent, False);
  FState.Sprites.Remove(ASprite);
end;

function TGreedItemRules.FindWarpDestination(var AX, AY: Integer; AWarpValue: Byte): Boolean;
var
  LSearch, LNoSearch: Integer;
begin
  LNoSearch := AY * GREED_MAP_SIZE + AX;
  if FWarpActive = 0 then
  begin
    for LSearch := 0 to GREED_MAP_TILES - 1 do
      if (FState.World.GetValue(gpMapSprites, LSearch) = AWarpValue) and (LSearch <> LNoSearch) then
      begin
        AX := LSearch and (GREED_MAP_SIZE - 1);
        AY := LSearch div GREED_MAP_SIZE;
        FState.TurnRate := 0;
        FState.MoveRate := 0;
        FState.FallRate := 0;
        FState.StrafRate := 0;
        FHost.ResetMouse;
        FWarpActive := AWarpValue;
        Exit(True);
      end;
  end;
  Result := False;
end;

procedure TGreedItemRules.PickupMedPak(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean;
  ACharType: Integer);
var
  LSprite: Integer;
begin
  LSprite := FindSprite(ATileX, ATileY, AValue - GREED_SM_MEDPAK1 + GREED_S_MEDPAK1);
  if LSprite = GREED_POOL_NIL then
    Exit;
  ClearMapSprite(AMapSpot);
  PickupSound(GREED_SN_PICKUP0 + ACharType, ATileX, ATileY);
  if AUseIt then
  begin
    if FState.Player.Angst = FState.Player.MaxAngst then
    begin
      FState.Player.Inventory[0] := FState.Player.Inventory[0] + 5 - (AValue - GREED_SM_MEDPAK1);
      if FState.Player.Inventory[0] > 20 then
        FState.Player.Inventory[0] := 20;
      FHost.RefreshInventory;
      FMessages.WriteMessage(SStoredMedTube);
    end
    else
    begin
      FHealth.MedPaks((5 - (AValue - GREED_SM_MEDPAK1)) * 50);
      FMessages.WriteMessage(SUsedMedTube);
    end;
  end;
  ReplaceWithGenerator(LSprite);
end;

procedure TGreedItemRules.PickupShield(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean;
  ACharType: Integer);
var
  LSprite: Integer;
begin
  LSprite := FindSprite(ATileX, ATileY, AValue - GREED_SM_MEDPAK1 + GREED_S_MEDPAK1);
  if LSprite = GREED_POOL_NIL then
    Exit;
  ClearMapSprite(AMapSpot);
  PickupSound(GREED_SN_PICKUP0 + ACharType, ATileX, ATileY);
  if AUseIt then
  begin
    if FState.Player.Shield = FState.Player.MaxShield then
    begin
      FState.Player.Inventory[1] := FState.Player.Inventory[1] + 1 + (AValue - GREED_SM_SHIELD1);
      if FState.Player.Inventory[1] > 20 then
        FState.Player.Inventory[1] := 20;
      FHost.RefreshInventory;
      FMessages.WriteMessage(SStoredShield);
    end
    else
    begin
      FHealth.Heal((1 + (AValue - GREED_SM_SHIELD1)) * 50);
      FMessages.WriteMessage(SUsedShield);
    end;
  end;
  ReplaceWithGenerator(LSprite);
end;

procedure TGreedItemRules.PickupAmmo(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean;
  ACharType: Integer);
var
  LSprite: Integer;
begin
  LSprite := FindSprite(ATileX, ATileY, AValue - GREED_SM_ENERGY + GREED_S_ENERGY);
  if LSprite = GREED_POOL_NIL then
    Exit;
  ClearMapSprite(AMapSpot);
  PickupSound(GREED_SN_PICKUP0 + ACharType, ATileX, ATileY);
  if AUseIt then
  begin
    FState.HurtBorder := True;
    AddAmmo(AValue - GREED_SM_ENERGY, 75);
    FHost.RefreshAmmo;
    FMessages.WriteMessage(TGreedGameTables.PickupAmmoMessages[AValue - GREED_SM_ENERGY]);
  end;
  ReplaceWithGenerator(LSprite);
end;

procedure TGreedItemRules.PickupAmmoBox(ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer);
var
  LSprite, LAmmoKind, LSlot: Integer;
  LNoAmmoWeapon, LFull: Boolean;
begin
  LSlot := FState.Player.CurrentWeapon;
  if (LSlot >= Low(FState.Player.Weapons)) and (LSlot <= High(FState.Player.Weapons)) then
    LAmmoKind := WeaponInfo(FState.Player.Weapons[LSlot]).AmmoType
  else
    LAmmoKind := 0;
  // the original asks the table with the number of the slot, not of the weapon
  LNoAmmoWeapon := WeaponInfo(LSlot).AmmoRate = 0;
  if (LAmmoKind >= Low(FState.Player.Ammo)) and (LAmmoKind <= High(FState.Player.Ammo)) then
    LFull := FState.Player.Ammo[LAmmoKind] >= GREED_MAX_AMMO
  else
    LFull := False;
  if AUseIt and (LFull or (LNoAmmoWeapon and (FState.Player.Ammo[0] >= GREED_MAX_AMMO) and
    (FState.Player.Ammo[1] >= GREED_MAX_AMMO) and (FState.Player.Ammo[2] >= GREED_MAX_AMMO))) then
    Exit;
  LSprite := FindSprite(ATileX, ATileY, GREED_S_AMMOBOX);
  if LSprite = GREED_POOL_NIL then
    Exit;
  ClearMapSprite(AMapSpot);
  PickupSound(GREED_SN_PICKUP0 + ACharType, ATileX, ATileY);
  if AUseIt then
  begin
    FState.HurtBorder := True;
    if LNoAmmoWeapon then
    begin
      AddAmmo(0, 45);
      AddAmmo(1, 45);
      AddAmmo(2, 45);
    end
    else
      AddAmmo(LAmmoKind, 125);
    FHost.RefreshAmmo;
    FMessages.WriteMessage(TGreedGameTables.PickupMessages[11]);
  end;
  RemoveBox(LSprite);
end;

procedure TGreedItemRules.PickupMedBox(ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer);
var
  LSprite: Integer;
begin
  if AUseIt and (FState.Player.Angst = FState.Player.MaxAngst) and
    (FState.Player.Shield = FState.Player.MaxShield) then
    Exit;
  LSprite := FindSprite(ATileX, ATileY, GREED_S_MEDBOX);
  if LSprite = GREED_POOL_NIL then
    Exit;
  ClearMapSprite(AMapSpot);
  PickupSound(GREED_SN_PICKUP0 + ACharType, ATileX, ATileY);
  if AUseIt then
  begin
    FHealth.Heal(250);
    FHealth.MedPaks(250);
    FState.HurtBorder := True;
    FMessages.WriteMessage(TGreedGameTables.PickupMessages[12]);
  end;
  RemoveBox(LSprite);
end;

procedure TGreedItemRules.PickupGoodieBox(ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean;
  ACharType: Integer);
var
  LSprite, LCount, LItem: Integer;
begin
  LSprite := FindSprite(ATileX, ATileY, GREED_S_GOODIEBOX);
  if LSprite = GREED_POOL_NIL then
    Exit;
  ClearMapSprite(AMapSpot);
  PickupSound(GREED_SN_PICKUP0 + ACharType, ATileX, ATileY);
  if AUseIt then
  begin
    for LCount := 0 to 1 do
    begin
      // as the original: the loop stops on the items 6 and 10 (12 never comes out of a mod 11)
      repeat
        LItem := Integer(Cardinal(FClock.Clock + FRandom.Next) mod 11);
      until (LItem = 6) or (LItem = 10) or (LItem = 12);
      FState.Player.Inventory[LItem + 2] := FState.Player.Inventory[LItem + 2] +
        TGreedGameTables.PickupAmounts[LItem];
      if LItem = 2 then
      begin
        if FState.Player.Inventory[2] > 15 then
          FState.Player.Inventory[2] := 15;
      end
      else if FState.Player.Inventory[LItem + 2] > 10 then
        FState.Player.Inventory[LItem + 2] := 10;
    end;
    FHost.RefreshInventory;
    FState.HurtBorder := True;
    FMessages.WriteMessage(TGreedGameTables.PickupMessages[13]);
  end;
  RemoveBox(LSprite);
end;

procedure TGreedItemRules.PickupInventoryItem(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean;
  ACharType: Integer);
var
  LSprite, LItem: Integer;
begin
  LItem := AValue - GREED_SM_IGRENADE;
  LSprite := FindSprite(ATileX, ATileY, LItem + GREED_S_IGRENADE);
  if LSprite = GREED_POOL_NIL then
    Exit;
  ClearMapSprite(AMapSpot);
  PickupSound(GREED_SN_PICKUP0 + ACharType, ATileX, ATileY);
  if AUseIt then
  begin
    FState.HurtBorder := True;
    FState.Player.Inventory[LItem + 2] := FState.Player.Inventory[LItem + 2] + TGreedGameTables.PickupAmounts[LItem];
    if AValue = GREED_SM_IGRENADE then
    begin
      if FState.Player.Inventory[2] > 15 then
        FState.Player.Inventory[2] := 15;
    end
    else if FState.Player.Inventory[LItem + 2] > 10 then
      FState.Player.Inventory[LItem + 2] := 10;
    FMessages.WriteMessage(TGreedGameTables.PickupMessages[LItem]);
    FHost.RefreshInventory;
  end;
  ReplaceWithGenerator(LSprite);
end;

procedure TGreedItemRules.PickupBonusItem(ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean; ACharType: Integer);
begin
  if AUseIt then
  begin
    FHealth.AddScore(FState.BonusItem.Score);
    FHealth.Heal(150);
    FHealth.MedPaks(150);
    FState.HurtBorder := True;
    FMessages.WriteMessage(SBonusItem);
  end;
  FState.BonusItem.Score := 0;
  FState.BonusItem.MapSpot := -1;
  if FState.BonusItem.Sprite <> GREED_POOL_NIL then
    FState.Sprites.Remove(FState.BonusItem.Sprite);
  ClearMapSprite(AMapSpot);
  PickupSound(GREED_SN_WEAPPICKUP0 + ACharType, ATileX, ATileY);
  FState.BonusItem.Name := '';
end;

procedure TGreedItemRules.PickupGoal(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean;
  ACharType: Integer; APrimary: Boolean);
var
  LSprite, LNumber: Integer;
begin
  if APrimary then
  begin
    LNumber := AValue - GREED_SM_PRIMARY1;
    LSprite := FindSprite(ATileX, ATileY, LNumber + GREED_S_PRIMARY1);
  end
  else
  begin
    LNumber := AValue - GREED_SM_SECONDARY1;
    LSprite := FindSprite(ATileX, ATileY, LNumber + GREED_S_SECONDARY1);
  end;
  if LSprite = GREED_POOL_NIL then
    Exit;
  FState.Sprites.Remove(LSprite);
  ClearMapSprite(AMapSpot);
  PickupSound(GREED_SN_WEAPPICKUP0 + ACharType, ATileX, ATileY);
  if AUseIt then
  begin
    FHealth.Heal(150);
    FHealth.MedPaks(150);
    FState.HurtBorder := True;
    if APrimary then
    begin
      FHealth.AddScore(FState.Primaries[LNumber * 2 + 1]);
      FMessages.WriteMessage(SPrimaryGoal);
      Inc(FState.Player.Primaries[LNumber]);
    end
    else
    begin
      FHealth.AddScore(FState.Secondaries[LNumber * 2 + 1]);
      FMessages.WriteMessage(SSecondaryGoal);
      Inc(FState.Player.Secondaries[LNumber]);
    end;
  end;
end;

procedure TGreedItemRules.ElevatorSwitch(AValue, ATileX, ATileY, AMapSpot: Integer; AUseIt: Boolean);
var
  LIndex: Integer;
  LElevator: TGreedLinkedPool<TGreedElevator>.PItem;
  LSound, LStart: Boolean;
begin
  LSound := False;
  LIndex := FState.Elevators.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LElevator := FState.Elevators.Item(LIndex);
    case AValue of
      GREED_SM_SWITCHDOWN:
        LStart := (LElevator^.Kind = getSwitchDown) and not LElevator^.Down;
      GREED_SM_SWITCHDOWN2:
        LStart := (LElevator^.Kind = getSwitchDown2) and not LElevator^.Down;
    else
      LStart := (LElevator^.Kind = getSwitchUp) and not LElevator^.Up;
    end;
    if LStart then
    begin
      if AValue = GREED_SM_SWITCHUP then
        LElevator^.Up := True
      else
        LElevator^.Down := True;
      LElevator^.Timer := FState.TimeCount;
      LSound := True;
      FSound.SoundEffect(GREED_SN_ELEVATORSTART, 15, (LElevator^.MapSpot and 63) * TILE,
        (LElevator^.MapSpot div 64) * TILE);
    end;
    ClearMapSprite(AMapSpot);
    if AValue = GREED_SM_SWITCHDOWN then
    begin
      // the first kind of switch is heard only by who uses it, and twice
      if AUseIt and LSound then
      begin
        PickupSound(GREED_SN_TRIGGER, ATileX, ATileY);
        PickupSound(GREED_SN_TRIGGER, ATileX, ATileY);
      end;
    end
    else if LSound then
      PickupSound(GREED_SN_TRIGGER, ATileX, ATileY);
    LIndex := FState.Elevators.Next(LIndex);
  end;
end;

procedure TGreedItemRules.PickupWeapon(AValue, ATileX, ATileY, AMapSpot: Integer; ACharType: Integer);
var
  LWeapon, LAmmoKind, LSlot, LRow, LColumn, LSpot, LX, LY, LSprite: Integer;
begin
  LWeapon := AValue - GREED_SM_WEAPON0;
  LAmmoKind := WeaponInfo(LWeapon).AmmoType;
  LSlot := LAmmoKind + 2;
  if (LSlot < Low(FState.Player.Weapons)) or (LSlot > High(FState.Player.Weapons)) then
    Exit;

  if FState.Player.Weapons[LSlot] = LWeapon then
  begin
    AddAmmo(LAmmoKind, 100);
    FMessages.WriteMessage(SMoreAmmo);
  end
  else if FState.Player.Weapons[LSlot] <> -1 then
  begin
    // the weapon that the player had goes on the first free tile around
    LRow := -GREED_MAP_SIZE;
    while LRow <= GREED_MAP_SIZE do
    begin
      for LColumn := -1 to 1 do
      begin
        LSpot := AMapSpot + LRow + LColumn;
        if (LSpot <> AMapSpot) and (FloorPic(LSpot) <> 0) and (MapSprite(LSpot) = 0) then
        begin
          LX := (LSpot and 63) * GREED_MAP_SIZE + 32;
          LY := (LSpot div 64) * GREED_MAP_SIZE + 32;
          FSpawner.SpawnSprite(FState.Player.Weapons[LSlot] + GREED_S_WEAPON0, LX * GREED_FRACUNIT,
            LY * GREED_FRACUNIT, 0, 0, 0, 0, False, 0);
          LRow := GREED_MAP_SIZE * 2;
          Break;
        end;
      end;
      LRow := LRow + GREED_MAP_SIZE;
    end;
    if FState.Player.CurrentWeapon = LSlot then
    begin
      FState.WeaponLowering := False;
      FState.NewWeapon := LSlot;
      FHost.LoadWeapon(LWeapon);
      FState.WeaponYChange := FHost.GetWeaponPictureHeight - 20;
      FState.ChangingWeapons := True;
    end
    else
    begin
      FState.ChangingWeapons := True;
      FState.WeaponLowering := True;
      FState.NewWeapon := LSlot;
    end;
    FMessages.WriteMessage(SExchangedWeapons);
  end
  else
  begin
    FMessages.WriteMessage(SNewWeapon);
    FState.ChangingWeapons := True;
    FState.WeaponLowering := True;
    FState.NewWeapon := LSlot;
  end;

  LSprite := FindSprite(ATileX, ATileY, LWeapon + GREED_S_WEAPON0);
  if LSprite = GREED_POOL_NIL then
    Exit;
  FState.Player.Weapons[LSlot] := LWeapon;
  FState.HurtBorder := True;
  FState.Sprites.Remove(LSprite);
  ClearMapSprite(AMapSpot);
  PickupSound(GREED_SN_WEAPPICKUP0 + ACharType, ATileX, ATileY);
end;

procedure TGreedItemRules.CheckItems(ATileX, ATileY: Integer; AUseIt: Boolean; ACharType: Integer);
var
  LMapSpot, LValue: Integer;
begin
  LMapSpot := ATileY * GREED_MAP_SIZE + ATileX;
  LValue := MapSprite(LMapSpot);
  case LValue of
    GREED_SM_MEDPAK1..GREED_SM_MEDPAK4:
      PickupMedPak(LValue, ATileX, ATileY, LMapSpot, AUseIt, ACharType);
    GREED_SM_SHIELD1..GREED_SM_SHIELD4:
      PickupShield(LValue, ATileX, ATileY, LMapSpot, AUseIt, ACharType);
    GREED_SM_ENERGY, GREED_SM_BALLISTIC, GREED_SM_PLASMA:
      PickupAmmo(LValue, ATileX, ATileY, LMapSpot, AUseIt, ACharType);
    GREED_SM_AMMOBOX:
      PickupAmmoBox(ATileX, ATileY, LMapSpot, AUseIt, ACharType);
    GREED_SM_MEDBOX:
      PickupMedBox(ATileX, ATileY, LMapSpot, AUseIt, ACharType);
    GREED_SM_GOODIEBOX:
      PickupGoodieBox(ATileX, ATileY, LMapSpot, AUseIt, ACharType);
    GREED_SM_IGRENADE..GREED_SM_ISTEALER:
      PickupInventoryItem(LValue, ATileX, ATileY, LMapSpot, AUseIt, ACharType);
    GREED_SM_BONUSITEM:
      PickupBonusItem(ATileX, ATileY, LMapSpot, AUseIt, ACharType);
    GREED_SM_PRIMARY1, GREED_SM_PRIMARY2:
      PickupGoal(LValue, ATileX, ATileY, LMapSpot, AUseIt, ACharType, True);
    GREED_SM_SECONDARY1..GREED_SM_SECONDARY7:
      PickupGoal(LValue, ATileX, ATileY, LMapSpot, AUseIt, ACharType, False);
    GREED_SM_SWITCHDOWN, GREED_SM_SWITCHDOWN2, GREED_SM_SWITCHUP:
      ElevatorSwitch(LValue, ATileX, ATileY, LMapSpot, AUseIt);
    GREED_SM_EXIT:
      FState.ExitLevel := True;
    GREED_SM_WEAPON0..GREED_SM_WEAPON18:
      PickupWeapon(LValue, ATileX, ATileY, LMapSpot, ACharType);
  end;
end;

procedure TGreedItemRules.CheckWarps(ACenterX, ACenterY: TGreedFixed);
var
  LX, LY, LMapSpot, LValue, LTrigger: Integer;
begin
  LX := ACenterX div TILE;
  LY := ACenterY div TILE;
  LMapSpot := LY * GREED_MAP_SIZE + LX;
  LValue := MapSprite(LMapSpot);
  if (LValue >= 128) and (LValue <= 130) then
  begin
    if FState.Warping <> 0 then
      Exit;
    if FindWarpDestination(LX, LY, Byte(LValue)) then
    begin
      FState.WarpX := (LX * GREED_MAP_SIZE + 32) * GREED_FRACUNIT;
      FState.WarpY := (LY * GREED_MAP_SIZE + 32) * GREED_FRACUNIT;
      FState.Warping := 1;
    end;
  end
  else
  begin
    FWarpActive := 0;
    if LValue > 130 then
      CheckItems(LX, LY, True, FState.Player.CharType);
  end;
  // triggers[x][y]: the first index is x; the tile is the one of the warp destination when a warp was found
  LTrigger := 0;
  if (LX >= 0) and (LX < GREED_MAP_SIZE) and (LY >= 0) and (LY < GREED_MAP_SIZE) then
    LTrigger := FState.Triggers[LX * GREED_MAP_SIZE + LY];
  if LTrigger <> 0 then
  begin
    // cx and cy are already fixed point numbers: the place of the sound wraps, as in the original
    FSound.SoundEffect(GREED_SN_TRIGGER, 0, ACenterX * TILE, ACenterY * TILE);
    FSound.SoundEffect(GREED_SN_TRIGGER, 0, ACenterX * TILE, ACenterY * TILE);
    FEvents.RunEvent(LTrigger, True);
  end;
end;

end.
