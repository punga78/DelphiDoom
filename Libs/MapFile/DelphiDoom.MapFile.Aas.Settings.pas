{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the settings of an .aas file                 }
{                                                                              }
{  Model of idAASSettings (AASFile.h, AASFile.cpp), Doom 3 GPL Source Code.    }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Aas.Settings;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds, DelphiDoom.MapFile.Aas.Types;

type
  /// <summary>
  ///   What the AAS was built for: the bounding boxes of the actors, the physics that decide
  ///   where they can go and the fixed travel times. A new object has the defaults of the
  ///   constructor of idAASSettings (one box of 32 x 32 x 72, gravity 0 0 -1066)
  /// </summary>
  TAasSettings = class
  strict private
    FBoundingBoxes: array[0..MAX_AAS_BOUNDING_BOXES - 1] of TGeoBounds;
    FNumBoundingBoxes: Integer;
    FUsePatches: Boolean;
    FWriteBrushMap: Boolean;
    FPlayerFlood: Boolean;
    FNoOptimize: Boolean;
    FAllowSwimReachabilities: Boolean;
    FAllowFlyReachabilities: Boolean;
    FFileExtension: AnsiString;
    FGravity: TGeoVec3;
    FGravityDir: TGeoVec3;
    FGravityValue: Single;
    FInvGravityDir: TGeoVec3;
    FMaxStepHeight: Single;
    FMaxBarrierHeight: Single;
    FMaxWaterJumpHeight: Single;
    FMaxFallHeight: Single;
    FMinFloorCos: Single;
    FBarrierJumpTime: Integer;
    FStartCrouchingTime: Integer;
    FWaterJumpTime: Integer;
    FStartWalkOffLedgeTime: Integer;
    function GetBoundingBox(const AIndex: Integer): TGeoBounds;
    procedure SetGravity(const AValue: TGeoVec3);
  public
    constructor Create;
    property NumBoundingBoxes: Integer read FNumBoundingBoxes;
    /// <summary>One of the first NumBoundingBoxes boxes</summary>
    property BoundingBoxes[const AIndex: Integer]: TGeoBounds read GetBoundingBox;
    /// <summary>Forgets the boxes (idAASSettings::ParseBBoxes starts so)</summary>
    procedure ClearBoundingBoxes;
    /// <summary>Adds a box; there is room for MAX_AAS_BOUNDING_BOXES (the original writes past the array)</summary>
    procedure AddBoundingBox(const ABounds: TGeoBounds);
    property UsePatches: Boolean read FUsePatches write FUsePatches;
    property WriteBrushMap: Boolean read FWriteBrushMap write FWriteBrushMap;
    property PlayerFlood: Boolean read FPlayerFlood write FPlayerFlood;
    property NoOptimize: Boolean read FNoOptimize write FNoOptimize;
    property AllowSwimReachabilities: Boolean read FAllowSwimReachabilities write FAllowSwimReachabilities;
    property AllowFlyReachabilities: Boolean read FAllowFlyReachabilities write FAllowFlyReachabilities;
    property FileExtension: AnsiString read FFileExtension write FFileExtension;
    /// <summary>Setting it also sets GravityDir (normalised), GravityValue (the length) and InvGravityDir</summary>
    property Gravity: TGeoVec3 read FGravity write SetGravity;
    property GravityDir: TGeoVec3 read FGravityDir;
    property GravityValue: Single read FGravityValue;
    property InvGravityDir: TGeoVec3 read FInvGravityDir;
    property MaxStepHeight: Single read FMaxStepHeight write FMaxStepHeight;
    property MaxBarrierHeight: Single read FMaxBarrierHeight write FMaxBarrierHeight;
    property MaxWaterJumpHeight: Single read FMaxWaterJumpHeight write FMaxWaterJumpHeight;
    property MaxFallHeight: Single read FMaxFallHeight write FMaxFallHeight;
    property MinFloorCos: Single read FMinFloorCos write FMinFloorCos;
    /// <summary>tt_barrierJump</summary>
    property BarrierJumpTime: Integer read FBarrierJumpTime write FBarrierJumpTime;
    /// <summary>tt_startCrouching</summary>
    property StartCrouchingTime: Integer read FStartCrouchingTime write FStartCrouchingTime;
    /// <summary>tt_waterJump</summary>
    property WaterJumpTime: Integer read FWaterJumpTime write FWaterJumpTime;
    /// <summary>tt_startWalkOffLedge</summary>
    property StartWalkOffLedgeTime: Integer read FStartWalkOffLedgeTime write FStartWalkOffLedgeTime;
    /// <summary>
    ///   Whether the bounds are inside the first box (idAASSettings::ValidForBounds)
    /// </summary>
    function ValidForBounds(const ABounds: TGeoBounds): Boolean;
  end;

implementation

uses
  System.SysUtils;

resourcestring
  STooManyBoundingBoxes = 'more than %d bounding boxes';

{ TAasSettings }

constructor TAasSettings.Create;
begin
  inherited Create;
  FNumBoundingBoxes := 1;
  FBoundingBoxes[0] := TGeoBounds.Make(TGeoVec3.Make(-16, -16, 0), TGeoVec3.Make(16, 16, 72));
  FFileExtension := 'aas48';
  SetGravity(TGeoVec3.Make(0, 0, -1066));
  FMaxStepHeight := 14.0;
  FMaxBarrierHeight := 32.0;
  FMaxWaterJumpHeight := 20.0;
  FMaxFallHeight := 64.0;
  FMinFloorCos := 0.7;
  FBarrierJumpTime := 100;
  FStartCrouchingTime := 100;
  FWaterJumpTime := 100;
  FStartWalkOffLedgeTime := 100;
end;

function TAasSettings.GetBoundingBox(const AIndex: Integer): TGeoBounds;
begin
  Result := FBoundingBoxes[AIndex];
end;

procedure TAasSettings.ClearBoundingBoxes;
begin
  FNumBoundingBoxes := 0;
end;

procedure TAasSettings.AddBoundingBox(const ABounds: TGeoBounds);
begin
  if FNumBoundingBoxes >= MAX_AAS_BOUNDING_BOXES then
    raise EAasFileException.Create(Format(STooManyBoundingBoxes, [MAX_AAS_BOUNDING_BOXES]));
  FBoundingBoxes[FNumBoundingBoxes] := ABounds;
  Inc(FNumBoundingBoxes);
end;

procedure TAasSettings.SetGravity(const AValue: TGeoVec3);
begin
  FGravity := AValue;
  FGravityDir := AValue;
  FGravityValue := FGravityDir.NormalizeSelf;
  FInvGravityDir := -FGravityDir;
end;

function TAasSettings.ValidForBounds(const ABounds: TGeoBounds): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
  begin
    if ABounds.Mins[LIndex] < FBoundingBoxes[0].Mins[LIndex] then
      Exit(False);
    if ABounds.Maxs[LIndex] > FBoundingBoxes[0].Maxs[LIndex] then
      Exit(False);
  end;
  Result := True;
end;

end.
