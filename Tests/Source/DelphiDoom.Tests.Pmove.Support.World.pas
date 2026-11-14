{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the pmove library - a made up world: convex brushes    }
{  swept by a box (the algorithm of CM_TraceThroughBrush), the same as the one }
{  of Tools\Verifica\127\pmgen.c that made the golden                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Pmove.Support.World;

// one float operation per statement, as the C code rounds them
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Collision.Q3.Types, DelphiDoom.Pmove.Intf;

type
  /// <summary>A convex brush: the points behind every plane (normal . p less than or equal to the distance) are inside</summary>
  TFakeBrush = record
    Contents: Integer;
    SurfaceFlags: Integer;
    /// <summary>The entity of the brush; 0 is the world</summary>
    Entity: Integer;
    Normals: TArray<TQ3Vec3>;
    Distances: TArray<Single>;
  end;

  /// <summary>The world of the tests: brushes in a list, the first that is hit first wins a tie</summary>
  TFakeWorld = class(TInterfacedObject, IPmoveTrace)
  strict private
    FBrushes: TList<TFakeBrush>;
    /// <summary>Calls made, for the tests that want to know what the movement asked</summary>
    FTraceCount: Integer;
    FPointContentsCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddBrush(const ABrush: TFakeBrush);
    /// <summary>An axial box, the six sides in the order -x +x -y +y -z +z</summary>
    procedure AddBox(const AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Single; const AContents: Integer;
      const ASurfaceFlags: Integer = 0; const AEntity: Integer = 0);
    function Trace(const AStart, AMins, AMaxs, AEnd: TQ3Vec3; const AEntityToSkip, AContentMask: Integer): TQ3Trace;
    function PointContents(const APoint: TQ3Vec3; const AEntityToSkip: Integer): Integer;
    property TraceCount: Integer read FTraceCount;
    property PointContentsCount: Integer read FPointContentsCount;
  end;

implementation

uses
  DelphiDoom.Collision.Q3.Math, DelphiDoom.Pmove.Types;

const
  // SURFACE_CLIP_EPSILON as a float
  TRACE_EPSILON: Single = 0.125;

constructor TFakeWorld.Create;
begin
  inherited Create;
  FBrushes := TList<TFakeBrush>.Create;
end;

destructor TFakeWorld.Destroy;
begin
  FBrushes.Free;
  inherited Destroy;
end;

procedure TFakeWorld.AddBrush(const ABrush: TFakeBrush);
begin
  FBrushes.Add(ABrush);
end;

procedure TFakeWorld.AddBox(const AMinX, AMinY, AMinZ, AMaxX, AMaxY, AMaxZ: Single; const AContents: Integer;
  const ASurfaceFlags, AEntity: Integer);
var
  LBrush: TFakeBrush;

  procedure Plane(const ANormalX, ANormalY, ANormalZ, ADistance: Single);
  var
    LNormal: TQ3Vec3;
  begin
    LNormal[0] := ANormalX;
    LNormal[1] := ANormalY;
    LNormal[2] := ANormalZ;
    LBrush.Normals := LBrush.Normals + [LNormal];
    LBrush.Distances := LBrush.Distances + [ADistance];
  end;

begin
  LBrush.Contents := AContents;
  LBrush.SurfaceFlags := ASurfaceFlags;
  LBrush.Entity := AEntity;
  LBrush.Normals := nil;
  LBrush.Distances := nil;
  Plane(-1, 0, 0, -AMinX);
  Plane(1, 0, 0, AMaxX);
  Plane(0, -1, 0, -AMinY);
  Plane(0, 1, 0, AMaxY);
  Plane(0, 0, -1, -AMinZ);
  Plane(0, 0, 1, AMaxZ);
  FBrushes.Add(LBrush);
end;

function TFakeWorld.Trace(const AStart, AMins, AMaxs, AEnd: TQ3Vec3; const AEntityToSkip,
  AContentMask: Integer): TQ3Trace;
var
  LBrush: TFakeBrush;
  LPlane, LAxis, LClip: Integer;
  LEnter, LLeave, LDistance, LStartDistance, LEndDistance, LFraction, LNumerator, LDenominator: Single;
  LOffset: TQ3Vec3;
  LStartOut, LGetOut, LMiss: Boolean;
begin
  Inc(FTraceCount);
  Result := Default(TQ3Trace);
  Result.Fraction := 1.0;
  for LBrush in FBrushes do
  begin
    if (LBrush.Contents and AContentMask) = 0 then
      Continue;
    LEnter := -1.0;
    LLeave := 1.0;
    LStartOut := False;
    LGetOut := False;
    LClip := -1;
    LMiss := False;
    for LPlane := 0 to High(LBrush.Normals) do
    begin
      for LAxis := 0 to 2 do
        if LBrush.Normals[LPlane][LAxis] < 0 then
          LOffset[LAxis] := AMaxs[LAxis]
        else
          LOffset[LAxis] := AMins[LAxis];
      LDistance := TQ3Math.Dot(LOffset, LBrush.Normals[LPlane]);
      LDistance := LBrush.Distances[LPlane] - LDistance;
      LStartDistance := TQ3Math.Dot(AStart, LBrush.Normals[LPlane]);
      LStartDistance := LStartDistance - LDistance;
      LEndDistance := TQ3Math.Dot(AEnd, LBrush.Normals[LPlane]);
      LEndDistance := LEndDistance - LDistance;
      if LEndDistance > 0 then
        LGetOut := True;
      if LStartDistance > 0 then
        LStartOut := True;
      if (LStartDistance > 0) and (LEndDistance >= LStartDistance) then
      begin
        LMiss := True;
        Break;
      end;
      if (LStartDistance <= 0) and (LEndDistance <= 0) then
        Continue;
      LDenominator := LStartDistance - LEndDistance;
      if LStartDistance > LEndDistance then
      begin
        LNumerator := LStartDistance - TRACE_EPSILON;
        LFraction := LNumerator / LDenominator;
        if LFraction < 0 then
          LFraction := 0;
        if LFraction > LEnter then
        begin
          LEnter := LFraction;
          LClip := LPlane;
        end;
      end
      else
      begin
        LNumerator := LStartDistance + TRACE_EPSILON;
        LFraction := LNumerator / LDenominator;
        if LFraction > 1 then
          LFraction := 1;
        if LFraction < LLeave then
          LLeave := LFraction;
      end;
    end;
    if LMiss then
      Continue;
    if not LStartOut then
    begin
      Result.StartSolid := True;
      if not LGetOut then
      begin
        Result.AllSolid := True;
        Result.Fraction := 0;
        Result.Contents := LBrush.Contents;
      end;
      Continue;
    end;
    if (LEnter < LLeave) and (LEnter > -1) and (LEnter < Result.Fraction) then
    begin
      if LEnter < 0 then
        LEnter := 0;
      Result.Fraction := LEnter;
      Result.Plane.Normal := LBrush.Normals[LClip];
      Result.SurfaceFlags := LBrush.SurfaceFlags;
      Result.Contents := LBrush.Contents;
      if LBrush.Entity <> 0 then
        Result.EntityNum := LBrush.Entity
      else
        Result.EntityNum := Q3_ENTITYNUM_WORLD;
    end;
  end;
  if Result.Fraction = 1.0 then
  begin
    Result.EndPos := AEnd;
    Result.EntityNum := Q3_ENTITYNUM_NONE;
  end
  else
  begin
    for LAxis := 0 to 2 do
    begin
      LDistance := AEnd[LAxis] - AStart[LAxis];
      LDistance := Result.Fraction * LDistance;
      Result.EndPos[LAxis] := AStart[LAxis] + LDistance;
    end;
    if Result.AllSolid then
      Result.EntityNum := Q3_ENTITYNUM_WORLD;
  end;
end;

function TFakeWorld.PointContents(const APoint: TQ3Vec3; const AEntityToSkip: Integer): Integer;
var
  LBrush: TFakeBrush;
  LPlane: Integer;
  LInside: Boolean;
  LDistance: Single;
begin
  Inc(FPointContentsCount);
  Result := 0;
  for LBrush in FBrushes do
  begin
    LInside := True;
    for LPlane := 0 to High(LBrush.Normals) do
    begin
      LDistance := TQ3Math.Dot(APoint, LBrush.Normals[LPlane]);
      LDistance := LDistance - LBrush.Distances[LPlane];
      if LDistance > 0 then
      begin
        LInside := False;
        Break;
      end;
    end;
    if LInside then
      Result := Result or LBrush.Contents;
  end;
end;

end.
