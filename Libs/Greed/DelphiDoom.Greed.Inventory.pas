{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the inventory of the player                      }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): inventoryright,             }
{  inventoryleft and useinventory of display.pas (the logic, not the drawing)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Inventory;

// the positions are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.GameView.Intf;

const
  /// <summary>inventorycursor when no item is chosen</summary>
  GREED_INVENTORY_NONE = -1;

type
  /// <summary>
  ///   The item of the inventory that is chosen (inventorycursor) and what using it does: the medtube and the
  ///   shield charge, the grenade (thrown by the loop of the game: FireGrenade), the reverso pill and the
  ///   invisibility (special effects with a time), the mines, the decoy, the instawall and the clone (sprites next
  ///   to the player), the holosuit (the player looks like the nearest corpse), the warp jammer (done by the loop:
  ///   WarpJammer of the state) and the soul stealer (16 shots around).
  ///   The status bar of the original chooses the first item when none is chosen, or when the chosen one is
  ///   finished, while it draws (displayinventory): here that is EnsureSelection, which the game calls where the
  ///   status bar is drawn. The net game is not ported.
  ///   Kept defect: the scale of the holo picture is the one of the nearest corpse found, and is not initialized
  ///   by the original when none is (here 0)
  /// </summary>
  TGreedInventory = class
  strict private
    FState: TGreedGameState;
    FSpawner: IGreedSpawner;
    FSound: IGreedGameSound;
    FMessages: IGreedMessages;
    FHealth: IGreedPlayerHealth;
    FView: IGreedGameView;
    FCursor: Integer;
    FFireGrenade: Boolean;
    procedure UseOne(const AMessage: string);
    procedure Drop(AKind, ASpawnId: Integer; const AMessage: string);
    procedure StartEffect(AEffect, ATics: Integer; const AMessage: string);
    procedure HoloSuit;
    procedure SoulStealer;
  public
    /// <summary>EArgumentNilException if one of the arguments is nil</summary>
    constructor Create(AState: TGreedGameState; const ASpawner: IGreedSpawner; const ASound: IGreedGameSound;
      const AMessages: IGreedMessages; const AHealth: IGreedPlayerHealth; const AView: IGreedGameView);
    /// <summary>inventoryright: the next item that the player has, around the end; none if it has nothing</summary>
    procedure Right;
    /// <summary>inventoryleft: the item before</summary>
    procedure Left;
    /// <summary>useinventory</summary>
    procedure Use;
    /// <summary>oldinventory := -2; inventoryleft; inventoryright: after the inventory changed</summary>
    procedure Refresh;
    /// <summary>The start of displayinventory: an item is chosen if none is, or if the chosen one is finished</summary>
    procedure EnsureSelection;
    /// <summary>inventorycursor: 0..12, or GREED_INVENTORY_NONE</summary>
    property Cursor: Integer read FCursor write FCursor;
    /// <summary>firegrenade: the loop of the game throws the grenade and clears it</summary>
    property FireGrenade: Boolean read FFireGrenade write FFireGrenade;
  end;

implementation

uses
  DelphiDoom.Greed.Player.Intf;

const
  TIC_RATE = 70;
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
  SOUL_BULLETS = 16;

{ TGreedInventory }

constructor TGreedInventory.Create(AState: TGreedGameState; const ASpawner: IGreedSpawner;
  const ASound: IGreedGameSound; const AMessages: IGreedMessages; const AHealth: IGreedPlayerHealth;
  const AView: IGreedGameView);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ASpawner) then
    raise EArgumentNilException.Create('ASpawner');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(AMessages) then
    raise EArgumentNilException.Create('AMessages');
  if not Assigned(AHealth) then
    raise EArgumentNilException.Create('AHealth');
  if not Assigned(AView) then
    raise EArgumentNilException.Create('AView');
  FState := AState;
  FSpawner := ASpawner;
  FSound := ASound;
  FMessages := AMessages;
  FHealth := AHealth;
  FView := AView;
  FCursor := GREED_INVENTORY_NONE;
end;

procedure TGreedInventory.Right;
begin
  if FCursor = GREED_INVENTORY_NONE then
    FCursor := 0
  else
    Inc(FCursor);
  while (FCursor < GREED_MAXINVENTORY) and (FState.Player.Inventory[FCursor] = 0) do
    Inc(FCursor);
  if FCursor >= GREED_MAXINVENTORY then
  begin
    FCursor := 0;
    while (FCursor < GREED_MAXINVENTORY) and (FState.Player.Inventory[FCursor] = 0) do
      Inc(FCursor);
    // nothing found
    if FCursor = GREED_MAXINVENTORY then
      FCursor := GREED_INVENTORY_NONE;
  end;
end;

procedure TGreedInventory.Left;
begin
  Dec(FCursor);
  while (FCursor >= 0) and (FState.Player.Inventory[FCursor] = 0) do
    Dec(FCursor);
  if FCursor <= -1 then
  begin
    FCursor := GREED_MAXINVENTORY - 1;
    while (FCursor >= 0) and (FState.Player.Inventory[FCursor] = 0) do
      Dec(FCursor);
  end;
end;

procedure TGreedInventory.Refresh;
begin
  FView.RefreshInventory;
  Left;
  Right;
end;

procedure TGreedInventory.EnsureSelection;
begin
  if (FCursor = GREED_INVENTORY_NONE) or (FState.Player.Inventory[FCursor] = 0) then
    Right;
end;

procedure TGreedInventory.UseOne(const AMessage: string);
begin
  Dec(FState.Player.Inventory[FCursor]);
  FMessages.WriteMessage(AMessage);
end;

procedure TGreedInventory.Drop(AKind, ASpawnId: Integer; const AMessage: string);
begin
  FSpawner.SpawnSprite(AKind, FState.Player.X, FState.Player.Y, 0, 0, 0, 0, False, ASpawnId);
  UseOne(AMessage);
end;

procedure TGreedInventory.StartEffect(AEffect, ATics: Integer; const AMessage: string);
begin
  if FState.SpecialEffect = AEffect then
    Exit;
  FState.SpecialEffect := AEffect;
  FState.SpecialEffectTime := FState.TimeCount + ATics;
  FView.SetTotalEffectTime(ATics);
  UseOne(AMessage);
end;

procedure TGreedInventory.HoloSuit;
var
  LIndex, LMinDistance, LDistance, LX, LY, LPicture, LScale: Integer;
  LSprite: PGreedSprite;
begin
  LMinDistance := MaxInt;
  LPicture := 0;
  LScale := 0;
  LIndex := FState.Sprites.First;
  while LIndex <> GREED_POOL_NIL do
  begin
    LSprite := PGreedSprite(FState.Sprites.Item(LIndex));
    if (not LSprite^.Active) and (LSprite^.HitPoints = 0) then
    begin
      LX := (FState.Player.X - LSprite^.X) div GREED_FRACTILEUNIT;
      LY := (FState.Player.Y - LSprite^.Y) div GREED_FRACTILEUNIT;
      LDistance := LX * LX + LY * LY;
      if LDistance < LMinDistance then
      begin
        LPicture := LSprite^.BasePic;
        LScale := LSprite^.Scale;
        LMinDistance := LDistance;
      end;
    end;
    LIndex := FState.Sprites.Next(LIndex);
  end;
  if LMinDistance <> MaxInt then
  begin
    Dec(FState.Player.Inventory[FCursor]);
    FState.Player.HoloPic := LPicture;
    FState.Player.HoloScale := LScale;
    FMessages.WriteMessage('HoloSuit Active');
  end
  else
    FMessages.WriteMessage('Unsuccessful Holo');
end;

procedure TGreedInventory.SoulStealer;
var
  LIndex, LAngle: Integer;
begin
  LAngle := 0;
  for LIndex := 0 to SOUL_BULLETS - 1 do
  begin
    FSpawner.SpawnSprite(GREED_S_SOULBULLET, FState.Player.X, FState.Player.Y, FState.Player.Z,
      FState.Player.Height - (52 * GREED_FRACUNIT), LAngle, 0, True, FState.PlayerNum);
    LAngle := LAngle + GREED_ANGLES div SOUL_BULLETS;
  end;
  FSound.SoundEffect(GREED_SN_SOULSTEALER, 0, FState.Player.X, FState.Player.Y);
  FSound.SoundEffect(GREED_SN_SOULSTEALER, 0, FState.Player.X, FState.Player.Y);
  UseOne('Used Soul Stealer');
end;

procedure TGreedInventory.Use;
begin
  if (FCursor = GREED_INVENTORY_NONE) or (FState.Player.Inventory[FCursor] = 0) then
    Exit;
  case FCursor of
    ITEM_MEDTUBE:
      if FState.Player.Angst < FState.Player.MaxAngst then
      begin
        FHealth.MedPaks(50);
        UseOne('Used Medtube');
      end;
    ITEM_SHIELD:
      if FState.Player.Shield < FState.Player.MaxShield then
      begin
        FHealth.Heal(50);
        UseOne('Used Shield Charge');
      end;
    ITEM_GRENADE:
      FFireGrenade := True;
    ITEM_REVERSO_PILL:
      StartEffect(GREED_SE_REVERSO_PILL, TIC_RATE * 15, 'Used Reverso Pill');
    ITEM_PROXIMITY_MINE:
      Drop(GREED_S_PROXMINE, FState.PlayerNum, 'Dropped Proximity Mine');
    ITEM_TIME_BOMB:
      Drop(GREED_S_TIMEMINE, FState.PlayerNum, 'Dropped Time Bomb');
    ITEM_DECOY:
      Drop(GREED_S_DECOY, FState.Player.CharType, 'Activated Decoy');
    ITEM_INSTAWALL:
      Drop(GREED_S_INSTAWALL, FState.PlayerNum, 'Activated InstaWall');
    ITEM_CLONE:
      Drop(GREED_S_CLONE, FState.Player.CharType, 'Clone Activated');
    ITEM_HOLOSUIT:
      HoloSuit;
    ITEM_INVISIBILITY:
      StartEffect(GREED_SE_INVISIBILITY, TIC_RATE * 30, 'Activated Invisibility Shield');
    ITEM_WARP_JAMMER:
      FState.WarpJammer := True;
    ITEM_SOUL_STEALER:
      SoulStealer;
  end;
  Refresh;
end;

end.
