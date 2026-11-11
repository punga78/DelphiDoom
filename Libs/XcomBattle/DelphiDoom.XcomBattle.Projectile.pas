{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape library - the path of a bullet, a missile or a  }
{  thrown item (Projectile), without the drawing                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattle.Projectile;

interface

uses
  System.SysUtils, System.Math, System.Generics.Collections, DelphiDoom.XcomMod.MapBlock,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomMod.MapData, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Model,
  DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattle.Services.Intf,
  DelphiDoom.XcomBattle.Host.Intf, DelphiDoom.XcomBattle.Trajectory;

type
  /// <summary>The options that Projectile reads (Options::battleFireSpeed and the others)</summary>
  TXcomProjectileOptions = record
    /// <summary>battleFireSpeed: the steps a projectile makes in a tick</summary>
    FireSpeed: Integer;
    /// <summary>battleUFOExtenderAccuracy</summary>
    UfoExtenderAccuracy: Boolean;
    /// <summary>forceFire</summary>
    ForceFire: Boolean;
    /// <summary>Whether the control key is held (SDL_GetModState)</summary>
    ControlHeld: Boolean;
    /// <summary>The options of a new OpenXcom: speed 6, no extender accuracy, forced fire, no key</summary>
    class function Default: TXcomProjectileOptions; static;
  end;

  /// <summary>Receives the vapor that a projectile leaves under water (the drawing adds particles to the tile)</summary>
  IXcomProjectileVapor = interface
    ['{6E2B9A47-1D83-4C05-B7F6-90A3D5C18E42}']
    procedure AddVaporCloud(const AVoxel: TXcomPosition; ADensity, AColor: Integer);
  end;

  /// <summary>
  ///   Calculates the trajectory of a shot (a straight line with the deviation of the accuracy), of a throw or an
  ///   arcing missile, and walks along it (Projectile). It does not draw: the bullet sprite number and the
  ///   floor sprite of a thrown item are there for the map
  /// </summary>
  TXcomProjectile = class
  strict private
    FSave: TXcomSavedBattleGame;
    FEngine: IXcomProjectileEngine;
    FHost: IXcomBattleHost;
    FVapor: IXcomProjectileVapor;
    FOptions: TXcomProjectileOptions;
    FAction: TXcomBattleAction;
    FOrigin: TXcomPosition;
    FTargetVoxel: TXcomPosition;
    FPosition: Integer;
    FBulletSprite: Integer;
    FReversed: Boolean;
    FSpeed: Integer;
    FVaporColor: Integer;
    FVaporDensity: Integer;
    FVaporProbability: Integer;
    FTrajectory: TList<TXcomPosition>;
    function GetItem: TXcomBattleItem;
    function GetItemFloorSprite: Integer;
    procedure AddVaporCloud;
  public
    /// <param name="AAction">The action: copied, the weapon and the actor stay the caller's</param>
    /// <param name="AOrigin">The tile the projectile starts from</param>
    /// <param name="ATargetVoxel">The voxel it is aimed at</param>
    /// <param name="AAmmo">The ammo that produced the projectile, or nil</param>
    /// <param name="AVapor">Where the vapor trail goes, or nil</param>
    constructor Create(const ASave: TXcomSavedBattleGame; const AEngine: IXcomProjectileEngine;
      const AHost: IXcomBattleHost; const AOptions: TXcomProjectileOptions; const AAction: TXcomBattleAction;
      const AOrigin, ATargetVoxel: TXcomPosition; const AAmmo: TXcomBattleItem;
      const AVapor: IXcomProjectileVapor = nil);
    destructor Destroy; override;
    /// <summary>
    ///   calculateTrajectory: the path of a straight shot with the deviation of the accuracy; the result is the
    ///   voxel type at the end (V_*: object 0..3, unit 4, out of the map 5) or -1 (no line of fire)
    /// </summary>
    function CalculateTrajectory(AAccuracy: Double): Integer; overload;
    function CalculateTrajectory(AAccuracy: Double; const AOriginVoxel: TXcomPosition; AExcludeUnit: Boolean = True)
      : Integer; overload;
    /// <summary>calculateThrow: the path of an arc (a throw or an arcing missile); V_OUTOFBOUNDS when there is none</summary>
    function CalculateThrow(AAccuracy: Double): Integer;
    /// <summary>
    ///   applyAccuracy: moves the target voxel by the deviation of the accuracy (and the range of the weapon) and
    ///   extends the line to the maximum distance when asked
    /// </summary>
    procedure ApplyAccuracy(const AOrigin: TXcomPosition; var ATarget: TXcomPosition; AAccuracy: Double;
      AKeepRange, AExtendLine: Boolean);
    /// <summary>move: goes on in the trajectory; false when it is finished</summary>
    function Move: Boolean;
    /// <summary>The voxel at an offset from the current position of the projectile</summary>
    function GetPosition(AOffset: Integer = 0): TXcomPosition;
    /// <summary>getParticle: the sprite of the bullet for a frame, or -1</summary>
    function GetParticle(AIndex: Integer): Integer;
    /// <summary>skipTrajectory</summary>
    procedure SkipTrajectory;
    /// <summary>getOrigin: the tile of the first voxel of the trajectory (a workaround for large units)</summary>
    function GetOrigin: TXcomPosition;
    /// <summary>getTarget: the tile that was aimed at</summary>
    function GetTarget: TXcomPosition;
    /// <summary>The item that is thrown, or nil</summary>
    property Item: TXcomBattleItem read GetItem;
    /// <summary>The floor sprite of the thrown item (FLOOROB.PCK), or -1 when nothing is thrown</summary>
    property ItemFloorSprite: Integer read GetItemFloorSprite;
    property IsReversed: Boolean read FReversed;
    property Speed: Integer read FSpeed;
    property TargetVoxel: TXcomPosition read FTargetVoxel;
    property Trajectory: TList<TXcomPosition> read FTrajectory;
  end;

implementation

const
  PI_VALUE: Double = 3.14159265358979323846;
  SNoWeapon = 'The action of the projectile has no weapon';

class function TXcomProjectileOptions.Default: TXcomProjectileOptions;
begin
  Result.FireSpeed := 6;
  Result.UfoExtenderAccuracy := False;
  Result.ForceFire := True;
  Result.ControlHeld := False;
end;

{ TXcomProjectile }

constructor TXcomProjectile.Create(const ASave: TXcomSavedBattleGame; const AEngine: IXcomProjectileEngine;
  const AHost: IXcomBattleHost; const AOptions: TXcomProjectileOptions; const AAction: TXcomBattleAction;
  const AOrigin, ATargetVoxel: TXcomPosition; const AAmmo: TXcomBattleItem; const AVapor: IXcomProjectileVapor);
begin
  inherited Create;
  FSave := ASave;
  FEngine := AEngine;
  FHost := AHost;
  FVapor := AVapor;
  FOptions := AOptions;
  FAction := TXcomBattleAction.Create;
  FAction.Assign(AAction);
  FOrigin := AOrigin;
  FTargetVoxel := ATargetVoxel;
  FTrajectory := TList<TXcomPosition>.Create;
  FPosition := 0;
  FBulletSprite := -1;
  FReversed := False;
  FVaporColor := -1;
  FVaporDensity := -1;
  FVaporProbability := 5;
  // this is the number of pixels the sprite will move between frames
  FSpeed := FOptions.FireSpeed;
  if Assigned(FAction.Weapon) then
  begin
    if FAction.ActionType <> BA_THROW then
    begin
      // try to get all the required info from the ammo, if present
      if Assigned(AAmmo) then
      begin
        FBulletSprite := AAmmo.Rules.BulletSprite;
        FVaporColor := AAmmo.Rules.VaporColor;
        FVaporDensity := AAmmo.Rules.VaporDensity;
        FVaporProbability := AAmmo.Rules.VaporProbability;
        FSpeed := Max(1, FSpeed + AAmmo.Rules.BulletSpeed);
      end;
      // no ammo, or the ammo did not contain the info we wanted: see what the weapon has on offer
      if FBulletSprite = -1 then
        FBulletSprite := FAction.Weapon.Rules.BulletSprite;
      if FVaporColor = -1 then
        FVaporColor := FAction.Weapon.Rules.VaporColor;
      if FVaporDensity = -1 then
        FVaporDensity := FAction.Weapon.Rules.VaporDensity;
      if FVaporProbability = 5 then
        FVaporProbability := FAction.Weapon.Rules.VaporProbability;
      if (not Assigned(AAmmo)) or (AAmmo <> FAction.Weapon) or (AAmmo.Rules.BulletSpeed = 0) then
        FSpeed := Max(1, FSpeed + FAction.Weapon.Rules.BulletSpeed);
    end;
  end;
  if (ATargetVoxel.X - AOrigin.X) + (ATargetVoxel.Y - AOrigin.Y) >= 0 then
    FReversed := True;
end;

destructor TXcomProjectile.Destroy;
begin
  FTrajectory.Free;
  FAction.Free;
  inherited Destroy;
end;

function TXcomProjectile.GetItem: TXcomBattleItem;
begin
  if FAction.ActionType = BA_THROW then
    Result := FAction.Weapon
  else
    Result := nil;
end;

function TXcomProjectile.GetItemFloorSprite: Integer;
begin
  if FAction.ActionType = BA_THROW then
    Result := FAction.Weapon.Rules.FloorSprite
  else
    Result := -1;
end;

function TXcomProjectile.CalculateTrajectory(AAccuracy: Double): Integer;
var
  LOriginVoxel: TXcomPosition;
begin
  LOriginVoxel := FEngine.GetOriginVoxel(FAction, FSave.TileAt(FOrigin));
  Result := CalculateTrajectory(AAccuracy, LOriginVoxel);
end;

function TXcomProjectile.CalculateTrajectory(AAccuracy: Double; const AOriginVoxel: TXcomPosition;
  AExcludeUnit: Boolean): Integer;
var
  LTargetTile: TXcomTile;
  LActor: TXcomBattleUnit;
  LTest: Integer;
  LHitPosition: TXcomPosition;
  LHitUnit: TXcomBattleUnit;
  LTargetUnit: TXcomBattleUnit;
  LExtendLine: Boolean;
  LTarget: TXcomPosition;
begin
  LTargetTile := FSave.TileAt(FAction.Target);
  LActor := FAction.Actor;
  if AExcludeUnit then
    LTest := FEngine.CalculateLine(AOriginVoxel, FTargetVoxel, False, FTrajectory, LActor)
  else
    LTest := FEngine.CalculateLine(AOriginVoxel, FTargetVoxel, False, FTrajectory, nil);
  if (LTest <> V_EMPTY) and (FTrajectory.Count > 0) and (LActor.Faction = FACTION_PLAYER) and
    (FAction.AutoShotCounter = 1) and ((not FOptions.ControlHeld) or (not FOptions.ForceFire)) and
    FHost.PanicHandled and (FAction.ActionType <> BA_LAUNCH) then
  begin
    LHitPosition := TXcomPosition.Make(FTrajectory[0].X div 16, FTrajectory[0].Y div 16, FTrajectory[0].Z div 24);
    // no unit? must be lower
    if (LTest = V_UNIT) and Assigned(FSave.TileAt(LHitPosition)) and
      (FSave.TileAt(LHitPosition).CurrentUnit = nil) then
      LHitPosition := TXcomPosition.Make(LHitPosition.X, LHitPosition.Y, LHitPosition.Z - 1);
    if (LHitPosition <> FAction.Target) and (FAction.ResultText = '') then
    begin
      if LTest = V_NORTHWALL then
      begin
        if LHitPosition.Y - 1 <> FAction.Target.Y then
        begin
          FTrajectory.Clear;
          Exit(V_EMPTY);
        end;
      end
      else if LTest = V_WESTWALL then
      begin
        if LHitPosition.X - 1 <> FAction.Target.X then
        begin
          FTrajectory.Clear;
          Exit(V_EMPTY);
        end;
      end
      else if LTest = V_UNIT then
      begin
        LHitUnit := FSave.TileAt(LHitPosition).CurrentUnit;
        LTargetUnit := LTargetTile.CurrentUnit;
        if LHitUnit <> LTargetUnit then
        begin
          FTrajectory.Clear;
          Exit(V_EMPTY);
        end;
      end
      else
      begin
        FTrajectory.Clear;
        Exit(V_EMPTY);
      end;
    end;
  end;
  FTrajectory.Clear;
  LExtendLine := True;
  // even guided missiles drift, but how much is based on the faction of the shooter, rather than accuracy
  if FAction.ActionType = BA_LAUNCH then
  begin
    if LActor.Faction = FACTION_PLAYER then
      AAccuracy := 0.60
    else
      AAccuracy := 0.55;
    LExtendLine := FAction.Waypoints.Count <= 1;
  end;
  // some accuracy modifiers: this results in a new target voxel
  LTarget := FTargetVoxel;
  ApplyAccuracy(AOriginVoxel, LTarget, AAccuracy, False, LExtendLine);
  FTargetVoxel := LTarget;
  // finally a line calculation, storing this trajectory
  Result := FEngine.CalculateLine(AOriginVoxel, FTargetVoxel, True, FTrajectory, LActor);
end;

function TXcomProjectile.CalculateThrow(AAccuracy: Double): Integer;
var
  LTargetTile: TXcomTile;
  LOriginVoxel: TXcomPosition;
  LTargetVoxel: TXcomPosition;
  LTargets: TList<TXcomPosition>;
  LCurvature: Double;
  LForced: Boolean;
  LUnit: TXcomBattleUnit;
  LTest: Integer;
  LCandidate: TXcomPosition;
  LDeltas: TXcomPosition;
  LEndPoint: TXcomPosition;
  LEndTile: TXcomTile;
  LObject: TXcomMapData;
  LUnit16: TXcomPosition;
begin
  LTargetTile := FSave.TileAt(FAction.Target);
  LOriginVoxel := FEngine.GetOriginVoxel(FAction, nil);
  LUnit16 := TXcomPosition.Make(16, 16, 24);
  LTargetVoxel := FAction.Target * LUnit16 + TXcomPosition.Make(8, 8, 1 + -LTargetTile.GetTerrainLevel);
  LCurvature := 0;
  LForced := False;
  LTargets := TList<TXcomPosition>.Create;
  try
    if FAction.ActionType = BA_THROW then
      LTargets.Add(LTargetVoxel)
    else
    begin
      LUnit := LTargetTile.CurrentUnit;
      if (not Assigned(LUnit)) and (FAction.Target.Z > 0) and LTargetTile.HasNoFloor(nil) then
        LUnit := FSave.TileAt(FAction.Target - TXcomPosition.Make(0, 0, 1)).CurrentUnit;
      if FOptions.ForceFire and FOptions.ControlHeld and (FSave.Side = FACTION_PLAYER) then
      begin
        LTargets.Add(FAction.Target * LUnit16 + TXcomPosition.Make(0, 0, 12));
        LForced := True;
      end
      else if Assigned(LUnit) and ((FAction.Actor.Faction <> FACTION_PLAYER) or LUnit.Visible) then
      begin
        Inc(LTargetVoxel.Z, LUnit.FloatHeight); // ground level is the base
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, LUnit.GetHeight div 2 + 1));
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 2));
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, LUnit.GetHeight - 1));
      end
      else if Assigned(LTargetTile.MapData[XCOM_PART_OBJECT]) then
      begin
        LTargetVoxel := FAction.Target * LUnit16 + TXcomPosition.Make(8, 8, 0);
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 13));
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 8));
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 23));
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 2));
      end
      else if Assigned(LTargetTile.MapData[XCOM_PART_NORTHWALL]) then
      begin
        LTargetVoxel := FAction.Target * LUnit16 + TXcomPosition.Make(8, 0, 0);
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 13));
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 8));
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 20));
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 3));
      end
      else if Assigned(LTargetTile.MapData[XCOM_PART_WESTWALL]) then
      begin
        LTargetVoxel := FAction.Target * LUnit16 + TXcomPosition.Make(0, 8, 0);
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 13));
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 8));
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 20));
        LTargets.Add(LTargetVoxel + TXcomPosition.Make(0, 0, 2));
      end
      else if Assigned(LTargetTile.MapData[XCOM_PART_FLOOR]) then
        LTargets.Add(LTargetVoxel);
    end;
    LTest := V_OUTOFBOUNDS;
    for LCandidate in LTargets do
    begin
      LTargetVoxel := LCandidate;
      if FEngine.ValidateThrow(FAction, LOriginVoxel, LTargetVoxel, LCurvature, LTest, LForced) then
        Break;
    end;
  finally
    LTargets.Free;
  end;
  if (not LForced) and (LTest = V_OUTOFBOUNDS) then
    Exit(LTest); // no line of fire
  LTest := V_OUTOFBOUNDS;
  // finally a line calculation, storing this trajectory: make sure it is valid
  while LTest = V_OUTOFBOUNDS do
  begin
    LDeltas := LTargetVoxel;
    FTrajectory.Clear;
    if FAction.ActionType = BA_THROW then
    begin
      ApplyAccuracy(LOriginVoxel, LDeltas, AAccuracy, True, False); // calling for best flavor
      LDeltas := LDeltas - LTargetVoxel;
    end
    else
    begin
      ApplyAccuracy(LOriginVoxel, LTargetVoxel, AAccuracy, True, False); // arcing shot deviation
      LDeltas := TXcomPosition.Make(0, 0, 0);
    end;
    LTest := FEngine.CalculateParabola(LOriginVoxel, LTargetVoxel, True, FTrajectory, FAction.Actor, LCurvature,
      LDeltas);
    if LForced then
      Exit(XCOM_PART_OBJECT); // fake hit
    LEndPoint := TXcomTrajectory.PositionFromEnd(FTrajectory, ITEM_DROP_VOXEL_OFFSET) div LUnit16;
    LEndTile := FSave.TileAt(LEndPoint);
    // check if the item would land on a tile with a blocking object
    if (FAction.ActionType = BA_THROW) and Assigned(LEndTile) and Assigned(LEndTile.MapData[XCOM_PART_OBJECT]) then
    begin
      LObject := LEndTile.MapData[XCOM_PART_OBJECT];
      if (LObject.GetTuCost(MT_WALK) = 255) and
        not (LEndTile.IsBigWall and ((LObject.BigWall < 1) or (LObject.BigWall > 3))) then
        LTest := V_OUTOFBOUNDS;
    end;
  end;
  Result := LTest;
end;

procedure TXcomProjectile.ApplyAccuracy(const AOrigin: TXcomPosition; var ATarget: TXcomPosition; AAccuracy: Double;
  AKeepRange, AExtendLine: Boolean);
var
  LDeltaX: Integer;
  LDeltaY: Integer;
  LRealDistance: Double;
  LMaxRange: Double;
  LWeapon: TXcomRuleItem;
  LModifier: Double;
  LUpperLimit: Integer;
  LLowerLimit: Integer;
  LRange: Double;
  LDistanceX: Integer;
  LDistanceY: Integer;
  LDistanceZ: Integer;
  LShiftXy: Integer;
  LShiftZ: Integer;
  LDeviation: Integer;
  LDeviationValue: Double;
  LScaled: Double;
  LRotation: Double;
  LTilt: Double;
  LCosFi: Double;
  LSinFi: Double;
  LCosTe: Double;
  LSinTe: Double;
  LProduct: Double;
  LHorizontal: Double;
  LAngleX: Double;
  LAngleY: Double;
  LAngleZ: Double;
  LTemp: Double;
begin
  if not Assigned(FAction.Weapon) then
    raise EXcomBattleException.Create(SNoWeapon);
  LDeltaX := AOrigin.X - ATarget.X;
  LDeltaY := AOrigin.Y - ATarget.Y;
  LRealDistance := Sqrt(Double(LDeltaX * LDeltaX) + Double(LDeltaY * LDeltaY));
  // maxRange is the maximum range a projectile shall ever travel in voxel space
  if AKeepRange then
    LMaxRange := LRealDistance
  else
    LMaxRange := 16 * 1000; // 1000 tiles
  if FAction.ActionType = BA_HIT then
    LMaxRange := 46; // up to 2 tiles diagonally (as in the case of reaper v reaper)
  LWeapon := FAction.Weapon.Rules;
  if (FAction.ActionType <> BA_THROW) and (FAction.ActionType <> BA_HIT) then
  begin
    LModifier := 0.0;
    LUpperLimit := LWeapon.AimRange;
    LLowerLimit := LWeapon.MinRange;
    if FOptions.UfoExtenderAccuracy then
    begin
      if FAction.ActionType = BA_AUTOSHOT then
        LUpperLimit := LWeapon.AutoRange
      else if FAction.ActionType = BA_SNAPSHOT then
        LUpperLimit := LWeapon.SnapRange;
    end;
    LRange := LRealDistance / 16;
    if LRange < LLowerLimit then
    begin
      LTemp := LWeapon.Dropoff * (LLowerLimit - LRange);
      LModifier := LTemp / 100;
    end
    else if LUpperLimit < LRange then
    begin
      LTemp := LWeapon.Dropoff * (LRange - LUpperLimit);
      LModifier := LTemp / 100;
    end;
    LTemp := AAccuracy - LModifier;
    AAccuracy := Max(0.0, LTemp);
  end;
  LDistanceX := Abs(AOrigin.X - ATarget.X);
  LDistanceY := Abs(AOrigin.Y - ATarget.Y);
  LDistanceZ := Abs(AOrigin.Z - ATarget.Z);
  if LDistanceX div 2 <= LDistanceY then
    LShiftXy := LDistanceX div 4 + LDistanceY // we need to add some x/y non-uniformity
  else
    LShiftXy := (LDistanceX + LDistanceY) div 2; // that is the uniform part of spreading
  if LShiftXy <= LDistanceZ then
    LShiftZ := LShiftXy div 2 + LDistanceZ // slight z deviation
  else
    LShiftZ := LShiftXy + LDistanceZ div 2;
  // the product is a double in the C++ (SSE): the x87 would keep the error of 0.78 * 100 and Trunc would give 8 for 9
  LScaled := AAccuracy * 100;
  LDeviationValue := FSave.Random.Generate(0, 100) - LScaled;
  LDeviation := Trunc(LDeviationValue);
  if LDeviation >= 0 then
    Inc(LDeviation, 50) // add extra spread to the "miss" cloud
  else
    Inc(LDeviation, 10); // an accuracy of 109 or greater will become 1 (tightest spread)
  LDeviation := Max(1, LShiftZ * LDeviation div 200); // range ratio
  Inc(ATarget.X, FSave.Random.Generate(0, LDeviation) - LDeviation div 2);
  Inc(ATarget.Y, FSave.Random.Generate(0, LDeviation) - LDeviation div 2);
  Inc(ATarget.Z, FSave.Random.Generate(0, LDeviation div 2) div 2 - LDeviation div 8);
  if AExtendLine then
  begin
    LAngleY := ATarget.Y - AOrigin.Y;
    LAngleX := ATarget.X - AOrigin.X;
    LAngleZ := ATarget.Z - AOrigin.Z;
    LRotation := ArcTan2(LAngleY, LAngleX) * 180 / PI_VALUE;
    LHorizontal := Sqrt(LAngleX * LAngleX + LAngleY * LAngleY);
    LTilt := ArcTan2(LAngleZ, LHorizontal) * 180 / PI_VALUE;
    // the new target can be very far out of the map, but we do not care about that right now
    LTemp := LTilt * PI_VALUE / 180.0;
    LCosFi := Cos(LTemp);
    LSinFi := Sin(LTemp);
    LTemp := LRotation * PI_VALUE / 180.0;
    LCosTe := Cos(LTemp);
    LSinTe := Sin(LTemp);
    LProduct := LMaxRange * LCosTe;
    LProduct := LProduct * LCosFi;
    LTemp := AOrigin.X + LProduct;
    ATarget.X := Trunc(LTemp);
    LProduct := LMaxRange * LSinTe;
    LProduct := LProduct * LCosFi;
    LTemp := AOrigin.Y + LProduct;
    ATarget.Y := Trunc(LTemp);
    LProduct := LMaxRange * LSinFi;
    LTemp := AOrigin.Z + LProduct;
    ATarget.Z := Trunc(LTemp);
  end;
end;

procedure TXcomProjectile.AddVaporCloud;
begin
  if Assigned(FVapor) then
    FVapor.AddVaporCloud(FTrajectory[FPosition], FVaporDensity, FVaporColor);
end;

function TXcomProjectile.Move: Boolean;
var
  LStep: Integer;
begin
  for LStep := 0 to FSpeed - 1 do
  begin
    Inc(FPosition);
    if FPosition = FTrajectory.Count then
    begin
      Dec(FPosition);
      Exit(False);
    end;
    if (FSave.Depth > 0) and (FVaporColor <> -1) and (FAction.ActionType <> BA_THROW) and
      TXcomBattleRandom.Percent(FSave.Random, FVaporProbability) then
      AddVaporCloud;
  end;
  Result := True;
end;

function TXcomProjectile.GetPosition(AOffset: Integer): TXcomPosition;
begin
  Result := TXcomTrajectory.PositionFromStart(FTrajectory, FPosition + AOffset);
end;

function TXcomProjectile.GetParticle(AIndex: Integer): Integer;
begin
  if FBulletSprite <> -1 then
    Result := FBulletSprite + AIndex
  else
    Result := -1;
end;

procedure TXcomProjectile.SkipTrajectory;
begin
  while Move do
    ;
end;

function TXcomProjectile.GetOrigin: TXcomPosition;
begin
  // instead of using the position of the actor, the voxel origin translated to a tile position: a workaround
  // for large units
  Result := FTrajectory.First div TXcomPosition.Make(16, 16, 24);
end;

function TXcomProjectile.GetTarget: TXcomPosition;
begin
  Result := FAction.Target;
end;

end.
