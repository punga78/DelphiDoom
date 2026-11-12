{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the weapons in the hands of the player           }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): GetTargetAngle, fireweapon  }
{  and chargeweapons of raven.pas, the weapon parts of UpdateView and PlayLoop  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.PlayerWeapons;

// the positions are 16.16 fixed point numbers: the arithmetic wraps as in the original
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Game.Intf, DelphiDoom.Greed.Game.State,
  DelphiDoom.Greed.PlayerControl.Intf;

type
  /// <summary>
  ///   The weapons of the player, line by line from raven.pas: chargeweapons, GetTargetAngle, fireweapon, the loop
  ///   of PlayLoop that advances the frames of the weapon (and shoots the weapons 4 and 18 when their animation
  ///   ends) and the part of UpdateView that lowers a weapon and raises the next one. The globals are the fields of
  ///   TGreedGameState; the ones that are not there are properties of this class: WeaponBobView, WeaponX, WeaponY
  ///   (weapbob1, wx, wy of UpdateView) and the size of the picture that is shown (wpic).
  ///   Not ported: the net game (NetSoundEffect, NetSendSpawn).
  ///   Kept defects of the original: GetTargetAngle never finds a target. After a probe hits a sprite it walks the
  ///   whole list of the sprites and then reads the hit points of the placeholder that ends the list, which are
  ///   always 0: the five probes (960 steps each, at the angle of the shot, 16 to each side and 8 to each side) only
  ///   move the probe and leave SpriteHit, SpriteLoc, PlayerHit, HitX and HitY of the last step, and the answer is
  ///   always the angle of the look of the player. The weapons 0, 5 and 6 use the ammunition and shoot nothing; the
  ///   weapon 18 shoots 12 times around the map, not where the player looks.
  ///   Differences: a tile outside the map reads 0 (the original read the memory near the arrays); a probe that is
  ///   stopped by a wall is not moved again for the steps that are left (in the original every one of them gives
  ///   the same answer and changes nothing); a slot without a weapon (-1) does not shoot (the original read before
  ///   the table of the weapons)
  /// </summary>
  TGreedPlayerWeapons = class(TInterfacedObject, IGreedPlayerWeapons)
  strict private
    FState: TGreedGameState;
    FSpawner: IGreedSpawner;
    FSound: IGreedGameSound;
    FView: IGreedWeaponView;
    FWeaponBobView: Integer;
    FWeaponX: Integer;
    FWeaponY: Integer;
    FPictureWidth: Integer;
    FPictureHeight: Integer;
    function ProbeTryMove(ACenterX, ACenterY: TGreedFixed): Integer;
    function ProbeThrust: Integer;
    procedure ProbeLine(AAngle: Integer);
    function LookAngle: Integer;
    procedure Shoot(AValue: Integer; AX, AY, AHeight: TGreedFixed; AAngle, AAngle2: Integer);
    procedure ShootOne(AValue, AHeightUnits, ASound: Integer);
    procedure ShootTwo(AValue: Integer);
    procedure SelectPicture;
  public
    /// <summary>
    ///   AState has the player, the table of the weapons and the probe; ASpawner is SpawnSprite, ASound is
    ///   SoundEffect, AView has the pictures of the weapon. EArgumentNilException if one is nil
    /// </summary>
    constructor Create(AState: TGreedGameState; const ASpawner: IGreedSpawner; const ASound: IGreedGameSound;
      const AView: IGreedWeaponView);
    /// <summary>The lines of InitData of raven.pas that prepare the probe (speed, size, owner)</summary>
    procedure InitProbe;
    procedure ChargeWeapons;
    function GetTargetAngle(AOffset: Integer; AHeight: TGreedFixed): Integer;
    procedure FireWeapon;
    procedure AdvanceWeaponMode;
    procedure UpdateWeaponView(AUpdate: Boolean; AWindowWidth, AWindowHeight: Integer; out AWeaponX,
      AWeaponY: Integer);
    /// <summary>weapbob1 of UpdateView: the weapon bob of the last new image</summary>
    property WeaponBobView: Integer read FWeaponBobView write FWeaponBobView;
    /// <summary>wx and wy of UpdateView: where the weapon was drawn in the last new image</summary>
    property WeaponX: Integer read FWeaponX write FWeaponX;
    property WeaponY: Integer read FWeaponY write FWeaponY;
    /// <summary>wpic.width and wpic.height: the size of the picture of the weapon that is shown</summary>
    property PictureWidth: Integer read FPictureWidth;
    property PictureHeight: Integer read FPictureHeight;
  end;

implementation

uses
  DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.Game.Constants,
  DelphiDoom.Greed.Game.Tables, DelphiDoom.Greed.FixedMath, DelphiDoom.Greed.TrigTables,
  DelphiDoom.Greed.PlayerMovement;

const
  /// F_NOBULLETCLIP of r_refdef.pas: a wall that does not stop the shots
  F_NOBULLETCLIP = 1 shl 6;
  /// the value of mapsprites of an instawall
  SPRITE_INSTAWALL = 64;
  /// accuracy of GetTargetAngle
  TARGET_ACCURACY = 16;
  WEAPON_DELAY = 8;
  WEAPON_SPREAD = 4;
  WEAPON_GREEN = 18;

{ TGreedPlayerWeapons }

constructor TGreedPlayerWeapons.Create(AState: TGreedGameState; const ASpawner: IGreedSpawner;
  const ASound: IGreedGameSound; const AView: IGreedWeaponView);
begin
  inherited Create;
  if not Assigned(AState) then
    raise EArgumentNilException.Create('AState');
  if not Assigned(ASpawner) then
    raise EArgumentNilException.Create('ASpawner');
  if not Assigned(ASound) then
    raise EArgumentNilException.Create('ASound');
  if not Assigned(AView) then
    raise EArgumentNilException.Create('AView');
  FState := AState;
  FSpawner := ASpawner;
  FSound := ASound;
  FView := AView;
end;

procedure TGreedPlayerWeapons.InitProbe;
begin
  FState.Probe.MoveSpeed := GREED_MAXPROBE;
  // half a tile
  FState.Probe.MoveSize := 16 * GREED_FRACUNIT;
  FState.Probe.SpawnId := FState.PlayerNum;
end;

procedure TGreedPlayerWeapons.ChargeWeapons;
var
  LIndex, LWeapon, LTime: Integer;
begin
  LTime := FState.TimeCount;
  for LIndex := 0 to 4 do
  begin
    LWeapon := FState.Player.Weapons[LIndex];
    while (LWeapon <> -1) and (FState.Weapons[LWeapon].Charge < 100) and
      (LTime >= FState.Weapons[LWeapon].ChargeTime) do
    begin
      if FState.Weapons[LWeapon].Charge = 0 then
        FState.Weapons[LWeapon].ChargeTime := FState.TimeCount;
      FState.Weapons[LWeapon].Charge := FState.Weapons[LWeapon].Charge + 20;
      FState.Weapons[LWeapon].ChargeTime := FState.Weapons[LWeapon].ChargeTime +
        FState.Weapons[LWeapon].ChargeRate;
    end;
  end;
end;

// SP_TryMove of sprites.pas when msprite is the probe: 0 free, 1 a sprite or the player, 2 a wall
function TGreedPlayerWeapons.ProbeTryMove(ACenterX, ACenterY: TGreedFixed): Integer;
var
  LXLow, LYLow, LXHigh, LYHigh, LX, LY, LSpot: Integer;
  LWorld: IGreedWorld;
  LSprite: Byte;
begin
  LWorld := FState.World;
  LXLow := (ACenterX - FState.Probe.MoveSize) div GREED_FRACTILEUNIT;
  LYLow := (ACenterY - FState.Probe.MoveSize) div GREED_FRACTILEUNIT;
  LXHigh := (ACenterX + FState.Probe.MoveSize) div GREED_FRACTILEUNIT;
  LYHigh := (ACenterY + FState.Probe.MoveSize) div GREED_FRACTILEUNIT;
  for LY := LYLow to LYHigh do
    for LX := LXLow to LXHigh do
    begin
      LSpot := GREED_MAP_SIZE * LY + LX;
      if ((LY > LYLow) and (LWorld.GetValue(gpNorthWall, LSpot) <> 0) and
        (LWorld.GetValue(gpNorthFlags, LSpot) and GREED_F_NOCLIP = 0) and
        (LWorld.GetValue(gpNorthFlags, LSpot) and F_NOBULLETCLIP = 0)) or
        ((LX > LXLow) and (LWorld.GetValue(gpWestWall, LSpot) <> 0) and
        (LWorld.GetValue(gpWestFlags, LSpot) and GREED_F_NOCLIP = 0) and
        (LWorld.GetValue(gpWestFlags, LSpot) and F_NOBULLETCLIP = 0)) then
        Exit(2);
      LSprite := LWorld.GetValue(gpMapSprites, LSpot);
      if LSprite = SPRITE_INSTAWALL then
        Exit(2);
      if (LSprite > 0) and (LSprite < 128) and (LSpot <> FState.Probe.StartSpot) then
      begin
        FState.SpriteHit := True;
        FState.SpriteLoc := LSpot;
        Exit(1);
      end;
      // can't shoot yourself
      if (LSpot = FState.Player.MapSpot) and (LSpot <> FState.Probe.StartSpot) and
        (FState.Probe.SpawnId <> FState.PlayerNum) then
      begin
        FState.PlayerHit := True;
        Exit(1);
      end;
    end;
  Result := 0;
end;

// SP_Thrust and SP_ClipMove of sprites.pas when msprite is the probe (SP_TryDoor lets the probe through)
function TGreedPlayerWeapons.ProbeThrust: Integer;
var
  LMoveX, LMoveY, LMoveZ, LNewX, LNewY: TGreedFixed;
begin
  FState.Probe.Angle := FState.Probe.Angle and GREED_ANGLES;
  FState.Probe.Angle2 := FState.Probe.Angle2 and GREED_ANGLES;
  LMoveX := TGreedTrigTables.Cosine(FState.Probe.Angle);
  LMoveY := -TGreedTrigTables.Sine(FState.Probe.Angle);
  LMoveZ := TGreedTrigTables.Sine(FState.Probe.Angle2);
  LNewX := FState.Probe.X + LMoveX;
  LNewY := FState.Probe.Y + LMoveY;
  FState.SpriteHit := False;
  Result := ProbeTryMove(LNewX, LNewY);
  if Result <> 0 then
  begin
    FState.HitX := LNewX;
    FState.HitY := LNewY;
  end;
  if Result <> 2 then
  begin
    FState.Probe.X := FState.Probe.X + LMoveX;
    FState.Probe.Y := FState.Probe.Y + LMoveY;
    FState.Probe.Z := FState.Probe.Z + LMoveZ;
  end;
end;

// One of the five loops of GetTargetAngle: the probe starts from the player and takes MAXPROBE steps. The test
// of the original on the sprite that was hit reads the placeholder at the end of the list (hit points 0) and is
// never true, so a loop never ends early and never turns the player
procedure TGreedPlayerWeapons.ProbeLine(AAngle: Integer);
var
  LCounter: Integer;
begin
  FState.MSprite := GREED_SPRITE_PROBE;
  FState.Probe.X := FState.Player.X;
  FState.Probe.Y := FState.Player.Y;
  FState.Probe.Z := FState.Player.Z;
  FState.Probe.Angle := AAngle;
  FState.Probe.ZAdjust := FState.Player.Height;
  FState.Probe.StartSpot := (FState.Player.Y div GREED_FRACTILEUNIT) * GREED_MAP_SIZE +
    (FState.Player.X div GREED_FRACTILEUNIT);
  LCounter := 0;
  while LCounter < GREED_MAXPROBE do
  begin
    // against a wall the probe does not move: the steps that are left would give the same answer
    if ProbeThrust = 2 then
      Break;
    Inc(LCounter);
  end;
end;

function TGreedPlayerWeapons.LookAngle: Integer;
begin
  Result := (-FState.Player.ScrollMin) and GREED_ANGLES;
end;

function TGreedPlayerWeapons.GetTargetAngle(AOffset: Integer; AHeight: TGreedFixed): Integer;
begin
  if not FState.AutoTarget then
    Exit(LookAngle);
  ProbeLine(FState.Player.Angle + AOffset);
  ProbeLine(FState.Player.Angle + AOffset + TARGET_ACCURACY);
  ProbeLine(FState.Player.Angle + AOffset - TARGET_ACCURACY);
  ProbeLine(FState.Player.Angle + AOffset + TARGET_ACCURACY div 2);
  ProbeLine(FState.Player.Angle + AOffset - TARGET_ACCURACY div 2);
  Result := LookAngle;
end;

procedure TGreedPlayerWeapons.Shoot(AValue: Integer; AX, AY, AHeight: TGreedFixed; AAngle, AAngle2: Integer);
begin
  FSpawner.SpawnSprite(AValue, AX, AY, FState.Player.Z, AHeight, AAngle, AAngle2, True, FState.PlayerNum);
end;

// One shot from where the player is, at the angle of the player, and its sound (0 = none)
procedure TGreedPlayerWeapons.ShootOne(AValue, AHeightUnits, ASound: Integer);
var
  LHeight: TGreedFixed;
  LAngle2: Integer;
begin
  LHeight := FState.Player.Height - (AHeightUnits * GREED_FRACUNIT);
  LAngle2 := GetTargetAngle(0, LHeight);
  Shoot(AValue, FState.Player.X, FState.Player.Y, LHeight, FState.Player.Angle, LAngle2);
  FSound.SoundEffect(ASound, 0, FState.Player.X, FState.Player.Y);
end;

// Two shots, one from 4 units to each side of the player
procedure TGreedPlayerWeapons.ShootTwo(AValue: Integer);
var
  LAngle, LAngle2: Integer;
  LMoveX, LMoveY, LHeight: TGreedFixed;
begin
  LAngle := (FState.Player.Angle - GREED_NORTH) and GREED_ANGLES;
  LMoveX := TGreedFixedMath.Mul(GREED_FRACUNIT * 4, TGreedTrigTables.Cosine(LAngle));
  LMoveY := -TGreedFixedMath.Mul(GREED_FRACUNIT * 4, TGreedTrigTables.Sine(LAngle));
  LHeight := FState.Player.Height - (50 * GREED_FRACUNIT);
  LAngle2 := GetTargetAngle(0, LHeight);
  Shoot(AValue, FState.Player.X + LMoveX, FState.Player.Y + LMoveY, LHeight, FState.Player.Angle, LAngle2);
  LAngle := (FState.Player.Angle + GREED_NORTH) and GREED_ANGLES;
  LMoveX := TGreedFixedMath.Mul(GREED_FRACUNIT * 4, TGreedTrigTables.Cosine(LAngle));
  LMoveY := -TGreedFixedMath.Mul(GREED_FRACUNIT * 4, TGreedTrigTables.Sine(LAngle));
  LHeight := FState.Player.Height - (50 * GREED_FRACUNIT);
  LAngle2 := GetTargetAngle(0, LHeight);
  Shoot(AValue, FState.Player.X + LMoveX, FState.Player.Y + LMoveY, LHeight, FState.Player.Angle, LAngle2);
  FSound.SoundEffect(GREED_SN_BULLET12, 0, FState.Player.X, FState.Player.Y);
end;

procedure TGreedPlayerWeapons.FireWeapon;
var
  LIndex, LWeapon, LAmmo, LAngle, LAngle2, LOldAngle, LOldAngle64: Integer;
  LHeight: TGreedFixed;
begin
  FState.Player.Status := 2;
  LWeapon := FState.Player.Weapons[FState.Player.CurrentWeapon];
  if LWeapon < 0 then
    Exit;
  LAmmo := FState.Weapons[LWeapon].AmmoRate;
  if FState.Player.Ammo[FState.Weapons[LWeapon].AmmoType] < LAmmo then
    Exit;
  LOldAngle := FState.Player.Angle;
  LOldAngle64 := FState.PlayerAngle64;
  FState.Weapons[LWeapon].Charge := 0;
  FState.Player.Ammo[FState.Weapons[LWeapon].AmmoType] :=
    FState.Player.Ammo[FState.Weapons[LWeapon].AmmoType] - LAmmo;
  if (LWeapon <> WEAPON_SPREAD) and (LWeapon <> WEAPON_GREEN) and (FState.WeapMode <> 1) then
    FState.WeapMode := 1;
  case LWeapon of
    // mooman #1
    13:
      ShootOne(GREED_S_HANDBULLET, 50, GREED_SN_BULLET13);
    // lizard #1, specimen #1, trix #1
    8, 14, 15:
      ShootOne(GREED_S_HANDBULLET, 50, GREED_SN_BULLET8);
    // psyborg #2
    1:
      ShootOne(GREED_S_BULLET1, 52, GREED_SN_BULLET1);
    2:
      ShootOne(GREED_S_BULLET2, 50, GREED_SN_BULLET5);
    3:
      ShootOne(GREED_S_BULLET3, 50, GREED_SN_BULLET3);
    WEAPON_SPREAD:
      begin
        // the horizontal angles are 24 apart, the probes of the target 16 apart and in another order: as the original
        LHeight := FState.Player.Height - (50 * GREED_FRACUNIT);
        LAngle2 := GetTargetAngle(-16, LHeight);
        Shoot(GREED_S_BULLET4, FState.Player.X, FState.Player.Y, LHeight, FState.Player.Angle - 48, LAngle2);
        LAngle2 := GetTargetAngle(-32, LHeight);
        Shoot(GREED_S_BULLET4, FState.Player.X, FState.Player.Y, LHeight, FState.Player.Angle - 24, LAngle2);
        LAngle2 := GetTargetAngle(0, LHeight);
        Shoot(GREED_S_BULLET4, FState.Player.X, FState.Player.Y, LHeight, FState.Player.Angle, LAngle2);
        LAngle2 := GetTargetAngle(16, LHeight);
        Shoot(GREED_S_BULLET4, FState.Player.X, FState.Player.Y, LHeight, FState.Player.Angle + 24, LAngle2);
        LAngle2 := GetTargetAngle(32, LHeight);
        Shoot(GREED_S_BULLET4, FState.Player.X, FState.Player.Y, LHeight, FState.Player.Angle + 48, LAngle2);
      end;
    // psyborg #1
    7:
      ShootOne(GREED_S_BULLET7, 52, GREED_SN_BULLET13);
    // lizard #2
    9:
      ShootOne(GREED_S_BULLET9, 52, GREED_SN_BULLET9);
    // specimen #2
    10:
      ShootOne(GREED_S_BULLET10, 52, GREED_SN_BULLET10);
    // mooman #2
    11:
      ShootOne(GREED_S_BULLET11, 52, GREED_SN_BULLET1);
    // dominatrix #2
    12:
      ShootTwo(GREED_S_BULLET12);
    // red gun
    16:
      ShootTwo(GREED_S_BULLET16);
    // blue gun
    17:
      ShootOne(GREED_S_BULLET17, 64, GREED_SN_BULLET17);
    // green gun
    WEAPON_GREEN:
      begin
        LAngle := 0;
        for LIndex := 0 to 11 do
        begin
          LHeight := FState.Player.Height - (52 * GREED_FRACUNIT);
          LAngle2 := GetTargetAngle(0, LHeight);
          Shoot(GREED_S_BULLET18, FState.Player.X, FState.Player.Y, LHeight, LAngle, LAngle2);
          LAngle := LAngle + GREED_ANGLES div 12;
        end;
      end;
  end;
  FState.Player.Angle := LOldAngle;
  FState.PlayerAngle64 := LOldAngle64;
end;

procedure TGreedPlayerWeapons.AdvanceWeaponMode;
var
  LWeapon: Integer;
begin
  while (FState.WeapMode <> 0) and (FState.TimeCount >= FState.WeapDelay) do
  begin
    LWeapon := FState.Player.Weapons[FState.Player.CurrentWeapon];
    if LWeapon < 0 then
    begin
      // no weapon in the slot: the original read before the table of the frames
      FState.WeapMode := 0;
      Break;
    end;
    if (LWeapon = WEAPON_SPREAD) or (LWeapon = WEAPON_GREEN) then
    begin
      if FState.WeapMode = 1 then
      begin
        if LWeapon = WEAPON_SPREAD then
          FSound.SoundEffect(GREED_SN_BULLET4, 0, FState.Player.X, FState.Player.Y);
        if LWeapon = WEAPON_GREEN then
          FSound.SoundEffect(GREED_SN_BULLET18, 0, FState.Player.X, FState.Player.Y);
      end;
      FState.WeapMode := TGreedGameTables.WeaponState[LWeapon][FState.WeapMode];
      if FState.WeapMode = 0 then
        FireWeapon;
    end
    else
      FState.WeapMode := TGreedGameTables.WeaponState[LWeapon][FState.WeapMode];
    FState.WeapDelay := FState.TimeCount + WEAPON_DELAY;
  end;
end;

procedure TGreedPlayerWeapons.SelectPicture;
begin
  FPictureWidth := FView.PictureWidth(FState.WeapMode);
  FPictureHeight := FView.PictureHeight(FState.WeapMode);
end;

procedure TGreedPlayerWeapons.UpdateWeaponView(AUpdate: Boolean; AWindowWidth, AWindowHeight: Integer;
  out AWeaponX, AWeaponY: Integer);
var
  LBobX, LBobY: Integer;
begin
  if AUpdate then
    FWeaponBobView := FState.WeapBob;
  if FState.WeapBobOn then
  begin
    LBobX := TGreedGameTables.WeaponMove[FWeaponBobView] div 2000;
    LBobY := TGreedGameTables.WeaponMove[FWeaponBobView div 2] div 8000;
  end
  else
  begin
    LBobX := 0;
    LBobY := 0;
  end;
  AWeaponX := FWeaponX;
  AWeaponY := FWeaponY;
  // only if alive
  if FState.Player.Angst = 0 then
    Exit;
  if AUpdate then
    SelectPicture;
  AWeaponX := ((AWindowWidth - FPictureWidth) div 2) + LBobX;
  AWeaponY := AWindowHeight - FPictureHeight + LBobY;
  if FState.ChangingWeapons and FState.WeaponLowering then
  begin
    FState.WeaponYChange := FState.WeaponYChange + 15;
    AWeaponY := AWeaponY + FState.WeaponYChange;
    if AWeaponY >= AWindowHeight - 20 then
    begin
      FState.WeaponLowering := False;
      FState.Player.CurrentWeapon := FState.NewWeapon;
      FView.LoadWeapon(FState.Player.Weapons[FState.NewWeapon]);
      FState.WeapMode := 0;
      SelectPicture;
      FState.WeaponYChange := FView.PictureHeight(FState.WeapMode) - 20;
      AWeaponY := AWindowHeight - 21;
      AWeaponX := ((AWindowWidth - FPictureWidth) div 2) + LBobX;
    end;
  end
  else if FState.ChangingWeapons then
  begin
    FState.WeaponYChange := FState.WeaponYChange - 10;
    if FState.WeaponYChange <= 0 then
      FState.ChangingWeapons := False
    else
      AWeaponY := AWeaponY + FState.WeaponYChange;
  end;
  if AUpdate then
  begin
    FWeaponX := AWeaponX;
    FWeaponY := AWeaponY;
  end
  else
  begin
    AWeaponX := FWeaponX;
    AWeaponY := FWeaponY;
  end;
end;

end.
