{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the projectiles                                   }
{                                                                              }
{  Port of war1 (acoto87/war1), war_projectiles.c, (c) 2019 Alejandro Coto     }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an altered }
{  version, not the original.                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Projectiles;

{$R-}
{$Q-}

interface

uses
  System.Generics.Collections, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context,
  DelphiDoom.War.Model.StateMachine, DelphiDoom.War.Model.Combat, DelphiDoom.War.Model.NearUnits;

type
  /// <summary>The blow that a projectile that arrives gives to its target (we_meleeAttack): given by whoever builds</summary>
  TWarMeleeHandler = procedure(AAttackerSlot, ATargetSlot: Integer) of object;

  /// <summary>
  ///   The projectiles fly in a straight line at their speed to where the target was, one step per tic; on arrival an
  ///   arrow, a fireball or a water elemental's bolt hurts its target, a catapult stone hurts every unit within 2 tiles
  ///   (the ones of its own side too: wu_canAttack does not look at who is the enemy) and a rain of fire everything
  ///   within 1 tile. The explosions make an animation entity that the original never removes. Defects of the original
  ///   kept: the list of the projectiles is walked while a projectile that arrives takes itself out, so the one after it is
  ///   skipped for that tic. A projectile whose target is the wall hurts the piece of the tile where it lands; the splash
  ///   of a catapult and the rain of fire hurt every piece of wall within their radius
  /// </summary>
  TWarProjectiles = class
  strict private
    FContext: TWarModelContext;
    FMachine: TWarStateMachine;
    FCombat: TWarCombat;
    FNear: TWarNearUnits;
    FMelee: TWarMeleeHandler;
    FNearUnits: TList<Integer>;
    FWallMelee: TWarMeleeHandler;
    procedure WallSplash(const ATile: TWarVec2; ARadius, ASourceSlot: Integer);
    function UpdatePosition(AEntity: PWarEntity): Boolean;
    procedure UpdateSprite(AEntity: PWarEntity);
    procedure UpdateRainOfFireSprite(AEntity: PWarEntity);
    procedure TargetDamage(AEntity: PWarEntity);
    procedure SplashDamage(AEntity: PWarEntity; ARadius: Integer);
    procedure RainOfFireDamage(AEntity: PWarEntity; ARadius: Integer);
    procedure MakeExplosion(const APosition: TWarVec2; ARainOfFire: Boolean);
    function IsAlive(ASlot: Integer): Boolean;
  public
    constructor Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine; const ACombat: TWarCombat;
      const ANear: TWarNearUnits; const AMelee: TWarMeleeHandler);
    destructor Destroy; override;
    /// <summary>
    ///   The blow on a piece of wall (we_meleeWallAttack: attacker slot, index of the piece); without one the walls are
    ///   not hurt by the units (the rain of fire hurts them anyway)
    /// </summary>
    property WallMelee: TWarMeleeHandler read FWallMelee write FWallMelee;
    /// <summary>wu_getProjectileType: what a unit that shoots throws (an arrow for a type that does not shoot)</summary>
    class function TypeOfUnit(AUnitType: Integer): Integer; static;
    /// <summary>wproj_createProjectile: the slot of the entity, 0 if the pool is full (the original would crash)</summary>
    function Launch(AProjectileType: Integer; ASourceId, ATargetId: Word; const AOrigin, ATarget: TWarVec2): Integer;
    /// <summary>updateProjectiles: every projectile of the list, in order</summary>
    procedure UpdateAll;
  end;

implementation

uses
  System.Math, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Math, DelphiDoom.War.Model.Intf,
  DelphiDoom.War.Model.Combat.Intf, DelphiDoom.War.Model.Animations, DelphiDoom.War.Model.Construction.Types;

type
  TProjectileData = record
    Speed: Integer;
    FrameCount: Integer;
    FrameStride: Integer;
  end;

const
  // projectilesData of war_projectiles.c: pixels per second, frames of an animation and frames between directions
  PROJECTILE_DATA: array[0..WAR_PROJECTILE_TYPE_COUNT - 1] of TProjectileData = (
    (Speed: 8 * WAR_MODEL_MEGA_TILE; FrameCount: 1; FrameStride: 0),
    (Speed: 4 * WAR_MODEL_MEGA_TILE; FrameCount: 3; FrameStride: 5),
    (Speed: 8 * WAR_MODEL_MEGA_TILE; FrameCount: 5; FrameStride: 5),
    (Speed: 8 * WAR_MODEL_MEGA_TILE; FrameCount: 2; FrameStride: 5),
    (Speed: 8 * WAR_MODEL_MEGA_TILE; FrameCount: 2; FrameStride: 5),
    (Speed: 6 * WAR_MODEL_MEGA_TILE; FrameCount: 3; FrameStride: 1));
  // the angles at which the frame of the sprite changes and the x scale is reversed
  CONTROL_ANGLES: array[0..8] of Single = (0, 45, 90, 135, 180, 225, 270, 315, 360);
  FRAME_INDICES: array[0..8] of Integer = (2, 3, 4, 3, 2, 1, 0, 1, 2);
  FRAME_SCALES: array[0..8] of Integer = (1, 1, 1, -1, -1, -1, 1, 1, 1);
  MOVE_EPSILON: Single = 0.5;
  PI_SINGLE: Single = 3.14159265358979323846;
  HALF_STEP: Single = 22.5;

{ TWarProjectiles }

constructor TWarProjectiles.Create(const AContext: TWarModelContext; const AMachine: TWarStateMachine;
  const ACombat: TWarCombat; const ANear: TWarNearUnits; const AMelee: TWarMeleeHandler);
begin
  inherited Create;
  FContext := AContext;
  FMachine := AMachine;
  FCombat := ACombat;
  FNear := ANear;
  FMelee := AMelee;
  FNearUnits := TList<Integer>.Create;
end;

destructor TWarProjectiles.Destroy;
begin
  FNearUnits.Free;
  inherited;
end;

class function TWarProjectiles.TypeOfUnit(AUnitType: Integer): Integer;
begin
  case AUnitType of
    WAR_UNIT_CATAPULT_HUMANS, WAR_UNIT_CATAPULT_ORCS:
      Result := WAR_PROJECTILE_CATAPULT;
    WAR_UNIT_CONJURER, WAR_UNIT_WARLOCK, WAR_UNIT_CLERIC, WAR_UNIT_NECROLYTE:
      Result := WAR_PROJECTILE_FIREBALL;
    WAR_UNIT_WATER_ELEMENTAL:
      Result := WAR_PROJECTILE_WATER_ELEMENTAL;
  else
    Result := WAR_PROJECTILE_ARROW;
  end;
end;

function TWarProjectiles.Launch(AProjectileType: Integer; ASourceId, ATargetId: Word; const AOrigin,
  ATarget: TWarVec2): Integer;
var
  LEntity: PWarEntity;
begin
  Result := FContext.Pool.CreateEntity(WAR_ENTITY_PROJECTILE, True);
  if Result = 0 then
    Exit;
  LEntity := FContext.Pool.Slots[Result];
  LEntity^.HasTransform := True;
  LEntity^.Position := AOrigin;
  LEntity^.HasProjectile := True;
  LEntity^.Projectile.ProjectileType := AProjectileType;
  LEntity^.Projectile.SourceEntityId := ASourceId;
  LEntity^.Projectile.TargetEntityId := ATargetId;
  LEntity^.Projectile.Origin := AOrigin;
  LEntity^.Projectile.Target := ATarget;
  LEntity^.Projectile.Speed := PROJECTILE_DATA[AProjectileType].Speed;
end;

function TWarProjectiles.IsAlive(ASlot: Integer): Boolean;
begin
  Result := not FMachine.IsDead(ASlot) and not FMachine.IsGoingToDie(ASlot) and not FMachine.IsCollapsing(ASlot) and
    not FMachine.IsGoingToCollapse(ASlot);
end;

// wproj_updateProjectilePosition: True when it has arrived
function TWarProjectiles.UpdatePosition(AEntity: PWarEntity): Boolean;
var
  LDirection: TWarVec2;
  LStep: TWarVec2;
  LNew: TWarVec2;
  LSpeed: Single;
  LDirectionLength: Single;
  LStepLength: Single;
  LDistance: Single;
  LStride: Single;
begin
  LSpeed := AEntity^.Projectile.Speed;
  LDirection := TWarModelMath.Sub(AEntity^.Projectile.Target, AEntity^.Position);
  LDirectionLength := TWarModelMath.Length(LDirection);
  LStride := LSpeed * FContext.Clock^.DeltaTime;
  LStep := TWarModelMath.Scale(TWarModelMath.Normalize(LDirection), LStride);
  LStepLength := TWarModelMath.Length(LStep);
  if LDirectionLength < LStepLength then
    LStep := LDirection;
  LNew := TWarModelMath.Add(AEntity^.Position, LStep);
  LDistance := TWarModelMath.Length(TWarModelMath.Sub(LNew, AEntity^.Projectile.Target));
  AEntity^.Position := LNew;
  Result := LDistance < MOVE_EPSILON;
end;

// wproj_updateProjectileSprite: the frame and the side of an arrow, a stone or a fireball, from its angle and how far it went
procedure TWarProjectiles.UpdateSprite(AEntity: PWarEntity);
var
  LProjectile: PWarProjectileComponent;
  LData: TProjectileData;
  LTotal: Single;
  LDirection: TWarVec2;
  LDirectionLength: Single;
  LTravel: Single;
  LPercent: Single;
  LPercentValid: Boolean;
  LCosine: Single;
  LCross: Single;
  LRadians: Single;
  LAngle: Single;
  LIndex: Integer;
  LFrameIndex: Integer;
  LFlip: Boolean;
  LFrameCount: Integer;
  LReverse: Boolean;
  LQuotient: Integer;
  LStep: Integer;
  LLow: Single;
  LHigh: Single;
  LTwoPi: Single;
begin
  LProjectile := @AEntity^.Projectile;
  LData := PROJECTILE_DATA[LProjectile^.ProjectileType];
  LTotal := TWarModelMath.Length(TWarModelMath.Sub(LProjectile^.Origin, LProjectile^.Target));
  LDirection := TWarModelMath.Sub(LProjectile^.Target, AEntity^.Position);
  LDirectionLength := TWarModelMath.Length(LDirection);
  LTravel := LTotal - LDirectionLength;
  // PERCENTABF: (f32)a / b * 100; with no total distance it is not a number and no comparison with it is true
  LPercentValid := LTotal <> 0;
  LPercent := 0;
  if LPercentValid then
  begin
    LPercent := LTravel / LTotal;
    LPercent := LPercent * 100;
  end;
  // vec2_angleClockwise(VEC2_RIGHT, direction): NaN (no frame found) when the cosine rounds above 1
  LFrameIndex := 0;
  LFlip := False;
  if LDirectionLength = 0 then
    LAngle := 0
  else
  begin
    LCosine := LDirection.X / LDirectionLength;
    LCross := 1 * LDirection.Y;
    LCross := LCross - 0 * LDirection.X;
    if Abs(LCosine) > 1 then
      LAngle := NaN
    else
    begin
      LRadians := ArcCos(Double(LCosine));
      if LCross < 0 then
      begin
        LTwoPi := 2 * PI_SINGLE;
        LRadians := LTwoPi - LRadians;
      end;
      LAngle := LRadians * 180;
      LAngle := LAngle / PI_SINGLE;
    end;
  end;
  if not IsNan(LAngle) then
    for LIndex := 0 to High(CONTROL_ANGLES) do
    begin
      LLow := CONTROL_ANGLES[LIndex] - HALF_STEP;
      LHigh := CONTROL_ANGLES[LIndex] + HALF_STEP;
      if (LAngle >= LLow) and (LAngle < LHigh) then
      begin
        LFrameIndex := FRAME_INDICES[LIndex];
        LFlip := FRAME_SCALES[LIndex] < 0;
        Break;
      end;
    end;
  // some projectiles have sequences like 0 1 0 or 0 1 2 1 0; the fireball has a linear one
  LFrameCount := LData.FrameCount;
  LReverse := False;
  if (LProjectile^.ProjectileType <> WAR_PROJECTILE_FIREBALL) and
    (LProjectile^.ProjectileType <> WAR_PROJECTILE_RAIN_OF_FIRE) then
  begin
    LFrameCount := LFrameCount * 2 - 1;
    LReverse := True;
  end;
  LQuotient := 100 div LFrameCount;
  for LStep := 1 to LFrameCount - 1 do
  begin
    if LPercentValid and (LQuotient * LStep >= LPercent) then
      Break;
    if LReverse and (LStep > LFrameCount div 2) then
      Dec(LFrameIndex, LData.FrameStride)
    else
      Inc(LFrameIndex, LData.FrameStride);
  end;
  LProjectile^.FlipX := LFlip;
  LProjectile^.FrameIndex := LFrameIndex;
end;

// wproj_updateRainOfFireProjectileSprite
procedure TWarProjectiles.UpdateRainOfFireSprite(AEntity: PWarEntity);
var
  LProjectile: PWarProjectileComponent;
  LData: TProjectileData;
  LTotal: Single;
  LDirectionLength: Single;
  LPercent: Single;
  LPercentValid: Boolean;
  LQuotient: Integer;
  LStep: Integer;
  LFrameIndex: Integer;
begin
  LProjectile := @AEntity^.Projectile;
  LData := PROJECTILE_DATA[LProjectile^.ProjectileType];
  LTotal := TWarModelMath.Length(TWarModelMath.Sub(LProjectile^.Origin, LProjectile^.Target));
  LDirectionLength := TWarModelMath.Length(TWarModelMath.Sub(LProjectile^.Target, AEntity^.Position));
  LPercentValid := LTotal <> 0;
  LPercent := 0;
  if LPercentValid then
  begin
    LPercent := (LTotal - LDirectionLength) / LTotal;
    LPercent := LPercent * 100;
  end;
  LFrameIndex := 0;
  LQuotient := 100 div LData.FrameCount;
  for LStep := 1 to LData.FrameCount - 1 do
  begin
    if LPercentValid and (LQuotient * LStep >= LPercent) then
      Break;
    Inc(LFrameIndex, LData.FrameStride);
  end;
  LProjectile^.FrameIndex := LFrameIndex;
end;

// wproj_doProjectileTargetDamage
procedure TWarProjectiles.TargetDamage(AEntity: PWarEntity);
var
  LSource: Integer;
  LTarget: Integer;
  LTile: TWarVec2;
  LPiece: Integer;
begin
  LSource := FContext.Pool.FindSlot(AEntity^.Projectile.SourceEntityId);
  LTarget := FContext.Pool.FindSlot(AEntity^.Projectile.TargetEntityId);
  // the attacker and the victim could have been removed by other units
  if (LSource = 0) or (LTarget = 0) then
    Exit;
  if FContext.Pool.Slots[LTarget]^.EntityType = WAR_ENTITY_WALL then
  begin
    LTile := TWarModelMath.MapToTile(AEntity^.Projectile.Target);
    LPiece := FContext.Walls.IndexAt(Trunc(LTile.X), Trunc(LTile.Y));
    if (LPiece >= 0) and Assigned(FWallMelee) then
      FWallMelee(LSource, LPiece);
  end
  else
    FMelee(LSource, LTarget);
end;

// the pieces of wall within the radius: hit by the source, or by the rain of fire when there is no source
procedure TWarProjectiles.WallSplash(const ATile: TWarVec2; ARadius, ASourceSlot: Integer);
var
  LIndex: Integer;
  LPiece: PWarWallPiece;
  LDistance: Single;
begin
  if FContext.Pool.OfType[WAR_ENTITY_WALL].Count = 0 then
    Exit;
  for LIndex := 0 to FContext.Walls.Count - 1 do
  begin
    LPiece := FContext.Walls[LIndex];
    LDistance := TWarModelMath.DistanceInTiles(ATile, TWarModelMath.Vec(LPiece^.TileX, LPiece^.TileY));
    if LDistance <= ARadius then
    begin
      if ASourceSlot <> 0 then
      begin
        if Assigned(FWallMelee) then
          FWallMelee(ASourceSlot, LIndex);
      end
      else
        FContext.Walls.TakeDamage(LIndex, 0, WAR_MODEL_RAIN_OF_FIRE_DAMAGE);
    end;
  end;
end;

// wproj_doProjectileSplashDamage
procedure TWarProjectiles.SplashDamage(AEntity: PWarEntity; ARadius: Integer);
var
  LTile: TWarVec2;
  LSource: Integer;
  LIndex: Integer;
  LSlot: Integer;
begin
  LTile := TWarModelMath.MapToTile(AEntity^.Projectile.Target);
  LSource := FContext.Pool.FindSlot(AEntity^.Projectile.SourceEntityId);
  if LSource = 0 then
    Exit;
  FNear.Collect(LTile, ARadius, FNearUnits);
  for LIndex := 0 to FNearUnits.Count - 1 do
  begin
    LSlot := FNearUnits[LIndex];
    if FContext.Queries.CanAttack(LSource, LSlot) then
      FMelee(LSource, LSlot);
  end;
  WallSplash(LTile, ARadius, LSource);
end;

// wproj_doRainOfFireProjectileSplashDamage
procedure TWarProjectiles.RainOfFireDamage(AEntity: PWarEntity; ARadius: Integer);
var
  LTile: TWarVec2;
  LIndex: Integer;
  LSlot: Integer;
begin
  LTile := TWarModelMath.MapToTile(AEntity^.Projectile.Target);
  FNear.Collect(LTile, ARadius, FNearUnits);
  for LIndex := 0 to FNearUnits.Count - 1 do
  begin
    LSlot := FNearUnits[LIndex];
    if IsAlive(LSlot) then
      FCombat.TakeDamage(LSlot, 0, WAR_MODEL_RAIN_OF_FIRE_DAMAGE);
  end;
  WallSplash(LTile, ARadius, 0);
end;

procedure TWarProjectiles.MakeExplosion(const APosition: TWarVec2; ARainOfFire: Boolean);
var
  LSlot: Integer;
begin
  // the animation entity: the original never removes it (the animation ends and leaves the entity empty)
  LSlot := FContext.Pool.CreateEntity(WAR_ENTITY_ANIMATION, True);
  if LSlot <> 0 then
  begin
    if ARainOfFire then
      TWarAnimations.CreateRainOfFireExplosion(FContext.Pool.Slots[LSlot], APosition)
    else
      TWarAnimations.CreateExplosion(FContext.Pool.Slots[LSlot], APosition);
  end;
  if Assigned(FContext.CombatEvents) then
    FContext.CombatEvents.Explosion(APosition, ARainOfFire);
end;

procedure TWarProjectiles.UpdateAll;
var
  LList: TList<Integer>;
  LIndex: Integer;
  LEntity: PWarEntity;
  LTarget: TWarVec2;
  LId: Word;
begin
  LList := FContext.Pool.OfType[WAR_ENTITY_PROJECTILE];
  LIndex := 0;
  while LIndex < LList.Count do
  begin
    LEntity := FContext.Pool.Slots[LList[LIndex]];
    Inc(LIndex);
    if not LEntity^.HasProjectile then
      Continue;
    LTarget := LEntity^.Projectile.Target;
    LId := LEntity^.Id;
    if LEntity^.Projectile.ProjectileType = WAR_PROJECTILE_RAIN_OF_FIRE then
    begin
      if not UpdatePosition(LEntity) then
        UpdateRainOfFireSprite(LEntity)
      else
      begin
        RainOfFireDamage(LEntity, WAR_MODEL_NEAR_RAIN_OF_FIRE_RADIUS);
        MakeExplosion(LTarget, True);
        FContext.Entities.RemoveEntityById(LId);
        // the list shrinks under the walk: the next projectile is skipped, as in the original
      end;
    end
    else if not UpdatePosition(LEntity) then
      UpdateSprite(LEntity)
    else
    begin
      if LEntity^.Projectile.ProjectileType = WAR_PROJECTILE_CATAPULT then
      begin
        SplashDamage(LEntity, WAR_MODEL_NEAR_CATAPULT_RADIUS);
        MakeExplosion(LTarget, False);
      end
      else
      begin
        TargetDamage(LEntity);
        if (LEntity^.Projectile.ProjectileType = WAR_PROJECTILE_ARROW) and Assigned(FContext.CombatEvents) then
          FContext.CombatEvents.ArrowHit(LTarget);
      end;
      FContext.Entities.RemoveEntityById(LId);
    end;
  end;
end;

end.
