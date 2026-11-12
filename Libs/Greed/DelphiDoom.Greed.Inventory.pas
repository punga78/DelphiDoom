{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the inventory of the player                      }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): inventoryleft,              }
{  inventoryright and useinventory of display.pas, and the grenade of PlayLoop  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Inventory;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Elevator.Intf, DelphiDoom.Greed.Game.Constants,
  DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State;

const
  /// <summary>oldinventory after a change: the status bar draws the inventory again</summary>
  GREED_INVENTORY_REDRAW = -2;
  /// <summary>inventorycursor when the player has nothing</summary>
  GREED_INVENTORY_NONE = -1;

  SGreedUsedMedtube = 'Used Medtube';
  SGreedUsedShieldCharge = 'Used Shield Charge';
  SGreedUsedReversoPill = 'Used Reverso Pill';
  SGreedDroppedProximityMine = 'Dropped Proximity Mine';
  SGreedDroppedTimeBomb = 'Dropped Time Bomb';
  SGreedActivatedDecoy = 'Activated Decoy';
  SGreedActivatedInstaWall = 'Activated InstaWall';
  SGreedCloneActivated = 'Clone Activated';
  SGreedHoloSuitActive = 'HoloSuit Active';
  SGreedUnsuccessfulHolo = 'Unsuccessful Holo';
  SGreedActivatedInvisibility = 'Activated Invisibility Shield';
  SGreedUsedSoulStealer = 'Used Soul Stealer';

type
  /// <summary>
  ///   The cursor on the 13 kinds of items of the player and what using one does. The fields are the globals of
  ///   display.pas that are about the inventory, with the names of the original; the status bar (TGreedHud) reads
  ///   Cursor and reads and writes OldInventory.
  ///   Use (useinventory): medtube and shield charge only if they are needed; the grenade only sets FireGrenade
  ///   (the game loop throws it: ThrowGrenade); the reverso pill and the invisibility start a special effect unless
  ///   it is already running; mines, decoy, instawall and clone are sprites made where the player stands; the
  ///   holosuit takes the picture of the nearest sprite that is not active and has no hit points; the warp jammer
  ///   only sets the flag of the game (JamWarps of the level does the rest and takes the item); the soul stealer
  ///   shoots 16 bullets around and plays its sound twice. After any use the cursor goes to the previous kind that
  ///   the player has and then to the next one: it stays where it is if that kind is not finished.
  ///   Not ported: the net game (NetSendSpawn, NetSoundEffect).
  ///   Kept from the original: the scale of the holosuit is the one of the nearest sprite found, and the angle of
  ///   the 16th bullet is not used after the loop
  /// </summary>
  TGreedInventory = class
  strict private
    FState: TGreedGameState;
    FSpawner: IGreedSpawner;
    FSound: IGreedGameSound;
    FHealth: IGreedPlayerHealth;
    FMessages: IGreedMessages;
    procedure StartEffect(AEffect, ATics: Integer; const AMessage: string);
    procedure Drop(AKind, ASpawnId: Integer; const AMessage: string);
    procedure UseHoloSuit;
    procedure UseSoulStealer;
  public
    /// <summary>inventorycursor: the kind of item that is chosen, GREED_INVENTORY_NONE if there is none</summary>
    Cursor: Integer;
    /// <summary>oldinventory: the cursor the status bar drew last, GREED_INVENTORY_REDRAW to draw it again</summary>
    OldInventory: Integer;
    /// <summary>totaleffecttime: how long the special effect that was started last lasts (the original never reads it)</summary>
    TotalEffectTime: Integer;
    /// <summary>firegrenade: a grenade was asked for and the game loop has not thrown it yet</summary>
    FireGrenade: Boolean;
    constructor Create(AState: TGreedGameState; const ASpawner: IGreedSpawner; const ASound: IGreedGameSound;
      const AHealth: IGreedPlayerHealth; const AMessages: IGreedMessages);
    /// <summary>inventoryright: the next kind the player has, going around; none if there is nothing</summary>
    procedure Right;
    /// <summary>inventoryleft: the previous kind the player has, going around; none if there is nothing</summary>
    procedure Left;
    /// <summary>useinventory</summary>
    procedure Use;
    /// <summary>oldinventory := -2; inventoryleft; inventoryright (what picking up an item does)</summary>
    procedure Refresh;
    /// <summary>
    ///   "if firegrenade" of PlayLoop: the grenade is made at the player with his angles, its sound is played and
    ///   one is taken from the inventory. Nothing if no grenade was asked for
    /// </summary>
    procedure ThrowGrenade;
  end;

implementation

const
  // the kinds of items, in the order of player.inventory
  ITEM_MEDTUBE = 0;
  ITEM_SHIELD = 1;
  ITEM_GRENADE = 2;
  ITEM_REVERSO_PILL = 3;
  ITEM_PROXIMITY_MINE = 4;
  ITEM_TIME_BOMB = 5;
  ITEM_DECOY = 6;
  ITEM_INSTAWALL = 7;
  ITEM_CLONE = 8;
  ITEM_HOLOSUIT = 9;
  ITEM_INVISIBILITY = 10;
  ITEM_WARP_JAMMER = 11;
  ITEM_SOUL_STEALER = 12;

{ TGreedInventory }

constructor TGreedInventory.Create(AState: TGreedGameState; const ASpawner: IGreedSpawner;
  const ASound: IGreedGameSound; const AHealth: IGreedPlayerHealth; const AMessages: IGreedMessages);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ASpawner) then
    raise EArgumentNilException.Create('ASpawner');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(AHealth) then
    raise EArgumentNilException.Create('AHealth');
  if not Assigned(AMessages) then
    raise EArgumentNilException.Create('AMessages');
  FState := AState;
  FSpawner := ASpawner;
  FSound := ASound;
  FHealth := AHealth;
  FMessages := AMessages;
  Cursor := GREED_INVENTORY_NONE;
end;

procedure TGreedInventory.Right;
begin
  if Cursor = GREED_INVENTORY_NONE then
    Cursor := 0
  else
    Inc(Cursor);
  while (Cursor < GREED_MAX_INVENTORY) and (FState.Player.Inventory[Cursor] = 0) do
    Inc(Cursor);
  if Cursor >= GREED_MAX_INVENTORY then
  begin
    Cursor := 0;
    while (Cursor < GREED_MAX_INVENTORY) and (FState.Player.Inventory[Cursor] = 0) do
      Inc(Cursor);
    if Cursor = GREED_MAX_INVENTORY then
      Cursor := GREED_INVENTORY_NONE;
  end;
end;

procedure TGreedInventory.Left;
begin
  Dec(Cursor);
  while (Cursor >= 0) and (FState.Player.Inventory[Cursor] = 0) do
    Dec(Cursor);
  if Cursor <= -1 then
  begin
    Cursor := GREED_MAX_INVENTORY - 1;
    while (Cursor >= 0) and (FState.Player.Inventory[Cursor] = 0) do
      Dec(Cursor);
  end;
end;

procedure TGreedInventory.Refresh;
begin
  OldInventory := GREED_INVENTORY_REDRAW;
  Left;
  Right;
end;

procedure TGreedInventory.StartEffect(AEffect, ATics: Integer; const AMessage: string);
begin
  if FState.SpecialEffect <> AEffect then
  begin
    FState.SpecialEffect := AEffect;
    FState.SpecialEffectTime := FState.TimeCount + ATics;
    TotalEffectTime := ATics;
    Dec(FState.Player.Inventory[Cursor]);
    FMessages.WriteMessage(AMessage);
  end;
end;

procedure TGreedInventory.Drop(AKind, ASpawnId: Integer; const AMessage: string);
begin
  FSpawner.SpawnSprite(AKind, FState.Player.X, FState.Player.Y, 0, 0, 0, 0, False, ASpawnId);
  Dec(FState.Player.Inventory[Cursor]);
  FMessages.WriteMessage(AMessage);
end;

procedure TGreedInventory.UseHoloSuit;
var
  LMinimum: Integer;
  LPicture: Integer;
  LScale: Integer;
  LSprite: Integer;
  LItem: PGreedSprite;
  LX, LY: Integer;
  LDistance: Integer;
begin
  LMinimum := MaxInt;
  LPicture := 0;
  LScale := 0;
  LSprite := FState.Sprites.First;
  while LSprite <> GREED_POOL_NIL do
  begin
    LItem := PGreedSprite(FState.Sprites.Item(LSprite));
    if not LItem^.Active and (LItem^.HitPoints = 0) then
    begin
      LX := (FState.Player.X - LItem^.X) div GREED_FRACTILEUNIT;
      LY := (FState.Player.Y - LItem^.Y) div GREED_FRACTILEUNIT;
      LDistance := LX * LX + LY * LY;
      if LDistance < LMinimum then
      begin
        LPicture := LItem^.BasePic;
        LScale := LItem^.Scale;
        LMinimum := LDistance;
      end;
    end;
    LSprite := FState.Sprites.Next(LSprite);
  end;
  if LMinimum <> MaxInt then
  begin
    Dec(FState.Player.Inventory[Cursor]);
    FState.Player.HoloPic := LPicture;
    FState.Player.HoloScale := LScale;
    FMessages.WriteMessage(SGreedHoloSuitActive);
  end
  else
    FMessages.WriteMessage(SGreedUnsuccessfulHolo);
end;

procedure TGreedInventory.UseSoulStealer;
var
  LAngle: Integer;
  LIndex: Integer;
begin
  LAngle := 0;
  for LIndex := 0 to 15 do
  begin
    FSpawner.SpawnSprite(GREED_S_SOULBULLET, FState.Player.X, FState.Player.Y, FState.Player.Z,
      FState.Player.Height - (52 * GREED_FRACUNIT), LAngle, 0, True, FState.PlayerNum);
    LAngle := LAngle + (GREED_ANGLES div 16);
  end;
  FSound.SoundEffect(GREED_SN_SOULSTEALER, 0, FState.Player.X, FState.Player.Y);
  FSound.SoundEffect(GREED_SN_SOULSTEALER, 0, FState.Player.X, FState.Player.Y);
  Dec(FState.Player.Inventory[Cursor]);
  FMessages.WriteMessage(SGreedUsedSoulStealer);
end;

procedure TGreedInventory.Use;
begin
  if (Cursor < 0) or (Cursor >= GREED_MAX_INVENTORY) or (FState.Player.Inventory[Cursor] = 0) then
    Exit;
  case Cursor of
    ITEM_MEDTUBE:
      if FState.Player.Angst < FState.Player.MaxAngst then
      begin
        FHealth.MedPaks(50);
        Dec(FState.Player.Inventory[Cursor]);
        FMessages.WriteMessage(SGreedUsedMedtube);
      end;
    ITEM_SHIELD:
      if FState.Player.Shield < FState.Player.MaxShield then
      begin
        FHealth.Heal(50);
        Dec(FState.Player.Inventory[Cursor]);
        FMessages.WriteMessage(SGreedUsedShieldCharge);
      end;
    ITEM_GRENADE:
      FireGrenade := True;
    ITEM_REVERSO_PILL:
      StartEffect(GREED_SE_REVERSOPILL, GREED_TIC_RATE * 15, SGreedUsedReversoPill);
    ITEM_PROXIMITY_MINE:
      Drop(GREED_S_PROXMINE, FState.PlayerNum, SGreedDroppedProximityMine);
    ITEM_TIME_BOMB:
      Drop(GREED_S_TIMEMINE, FState.PlayerNum, SGreedDroppedTimeBomb);
    ITEM_DECOY:
      Drop(GREED_S_DECOY, FState.Player.CharType, SGreedActivatedDecoy);
    ITEM_INSTAWALL:
      Drop(GREED_S_INSTAWALL, FState.PlayerNum, SGreedActivatedInstaWall);
    ITEM_CLONE:
      Drop(GREED_S_CLONE, FState.Player.CharType, SGreedCloneActivated);
    ITEM_HOLOSUIT:
      UseHoloSuit;
    ITEM_INVISIBILITY:
      StartEffect(GREED_SE_INVISIBILITY, GREED_TIC_RATE * 30, SGreedActivatedInvisibility);
    ITEM_WARP_JAMMER:
      FState.WarpJammer := True;
    ITEM_SOUL_STEALER:
      UseSoulStealer;
  end;
  OldInventory := GREED_INVENTORY_REDRAW;
  Left;
  Right;
end;

procedure TGreedInventory.ThrowGrenade;
begin
  if not FireGrenade then
    Exit;
  FSpawner.SpawnSprite(GREED_S_GRENADE, FState.Player.X, FState.Player.Y, FState.Player.Z,
    FState.Player.Height - (50 * GREED_FRACUNIT), FState.Player.Angle, (-FState.Player.ScrollMin) and GREED_ANGLES,
    True, FState.PlayerNum);
  FSound.SoundEffect(GREED_SN_GRENADE, 0, FState.Player.X, FState.Player.Y);
  Dec(FState.Player.Inventory[ITEM_GRENADE]);
  FireGrenade := False;
end;

end.
