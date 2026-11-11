{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom save library - CraftWeaponProjectile of OpenXcom (a        }
{  missile or a beam in a dogfight)                                             }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.CraftWeaponProjectile;

interface

type
  /// <summary>CraftWeaponProjectileType (from the rules of the weapon; laser and plasma are beams)</summary>
  TXcomProjectileType = (ptStingrayMissile, ptAvalancheMissile, ptCannonRound, ptFusionBall, ptLaserBeam, ptPlasmaBeam);

  /// <summary>CraftWeaponProjectileGlobalType</summary>
  TXcomProjectileKind = (pkMissile, pkBeam);

  /// <summary>
  ///   A projectile of a dogfight: a missile or a cannon round moves along the radar (one unit of position
  ///   is an eighth of a pixel), a beam only fades. Nothing here is saved
  /// </summary>
  TXcomCraftWeaponProjectile = class
  public
    const
      /// <summary>Directions: fired by the interceptor (up the radar), by the UFO (down), none</summary>
      DIRECTION_NONE = 0;
      DIRECTION_UP = 1;
      DIRECTION_DOWN = 2;
      /// <summary>HP_LEFT, HP_CENTER, HP_RIGHT: where on the radar</summary>
      HORIZONTAL_LEFT = -1;
      HORIZONTAL_CENTER = 0;
      HORIZONTAL_RIGHT = 1;
  strict private
    FType: TXcomProjectileType;
    FKind: TXcomProjectileKind;
    FSpeed: Integer;
    FDirection: Integer;
    FPosition: Integer;
    FHorizontalPosition: Integer;
    FState: Integer;
    FAccuracy: Integer;
    FDamage: Integer;
    FRange: Integer;
    FToBeRemoved: Boolean;
    FMissed: Boolean;
    FDistanceCovered: Integer;
  public
    constructor Create;
    /// <summary>setType: a beam has the state 8 that halves each step until it is gone</summary>
    procedure SetType(AType: TXcomProjectileType);
    /// <summary>setDirection: a projectile fired up starts at 0</summary>
    procedure SetDirection(ADirection: Integer);
    /// <summary>
    ///   move: a missile moves by its speed (the last step stops at the maximum range, the next marks it as
    ///   missed), a beam fades and is removed when its state gets to 1
    /// </summary>
    procedure Move;
    procedure Remove;
    property ProjectileType: TXcomProjectileType read FType;
    property Kind: TXcomProjectileKind read FKind;
    property Direction: Integer read FDirection;
    property Position: Integer read FPosition write FPosition;
    property HorizontalPosition: Integer read FHorizontalPosition write FHorizontalPosition;
    property State: Integer read FState;
    property ToBeRemoved: Boolean read FToBeRemoved;
    property Damage: Integer read FDamage write FDamage;
    property Accuracy: Integer read FAccuracy write FAccuracy;
    property Missed: Boolean read FMissed write FMissed;
    property Range: Integer read FRange write FRange;
    property Speed: Integer read FSpeed write FSpeed;
  end;

implementation

{ TXcomCraftWeaponProjectile }

constructor TXcomCraftWeaponProjectile.Create;
begin
  inherited Create;
  FType := ptCannonRound;
  FKind := pkMissile;
end;

procedure TXcomCraftWeaponProjectile.SetType(AType: TXcomProjectileType);
begin
  FType := AType;
  if AType >= ptLaserBeam then
  begin
    FKind := pkBeam;
    FState := 8;
  end;
end;

procedure TXcomCraftWeaponProjectile.SetDirection(ADirection: Integer);
begin
  FDirection := ADirection;
  if FDirection = DIRECTION_UP then
    FPosition := 0;
end;

procedure TXcomCraftWeaponProjectile.Move;
var
  LChange: Integer;
begin
  if FKind = pkMissile then
  begin
    LChange := FSpeed;
    // the projectile would reach its maximum range this tick
    if ((FDistanceCovered div 8) < FRange) and (((FDistanceCovered + FSpeed) div 8) >= FRange) then
      LChange := FRange * 8 - FDistanceCovered;
    // the projectile passed its maximum range on the previous tick
    if (FDistanceCovered div 8) >= FRange then
      FMissed := True;
    if FDirection = DIRECTION_UP then
      Inc(FPosition, LChange)
    else if FDirection = DIRECTION_DOWN then
      Dec(FPosition, LChange);
    Inc(FDistanceCovered, LChange);
  end
  else
  begin
    FState := FState div 2;
    if FState = 1 then
      FToBeRemoved := True;
  end;
end;

procedure TXcomCraftWeaponProjectile.Remove;
begin
  FToBeRemoved := True;
end;

end.
