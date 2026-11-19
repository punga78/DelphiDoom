{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idClip                                    }
{                                                                              }
{  Port of Doom 3 (id Software): game\physics\Clip.h, Clip.cpp (idClip: the    }
{  tree of sectors, the clip models touching bounds, Translation, Rotation,    }
{  Motion, Contents and the queries against one model). Not ported: Contacts   }
{  and GetModelContactFeature (the rigid body and the player need them), render }
{  model traces, the statistics and the drawing.                               }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.Clip;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.TraceModel, DelphiDoom.MathCore.Float.Rotation,
  DelphiDoom.Collision.Types, DelphiDoom.Collision.Intf, DelphiDoom.D3Game.Intf, DelphiDoom.D3Game.ClipModel;

const
  /// <summary>MAX_SECTOR_DEPTH</summary>
  D3_CLIP_MAX_SECTOR_DEPTH = 12;

type
  /// <summary>
  ///   What the clip asks of the game about the entities its clip models belong to: the number (the world has the
  ///   number <c>D3_ENTITYNUM_WORLD</c>), the name (for a message) and the owner of the entity's first clip model, the
  ///   entity a pass entity must not collide with (<c>GetPhysics()->GetClipModel()->GetOwner()</c>; nil if the
  ///   entity's physics has no clip model)
  /// </summary>
  ID3ClipEntities = interface
    ['{4A7E19C3-6B20-4D85-9E13-F0A25C8B7D61}']
    function GetEntityNumber(const AEntity: TObject): Integer;
    function GetEntityName(const AEntity: TObject): AnsiString;
    function GetPassOwner(const AEntity: TObject): TObject;
  end;

  /// <summary>
  ///   idClip: handles collision detection with the world and between physics objects. The world is the collision
  ///   model <c>worldMap</c> of the manager; the clip models are linked into a uniformly subdivided tree of sectors
  ///   built on the bounds of the world. The order of the links in a sector, the walk of the tree and the strict
  ///   <c>fraction &lt;</c> comparison decide which clip model wins a tie: they are the original's.
  /// </summary>
  TD3Clip = class
  strict private
    FManager: ICollisionModelManager;
    FEntities: ID3ClipEntities;
    FPrinter: ID3GamePrinter;
    FSectors: TObjectList<TD3ClipSector>;
    FWorldBounds: TGeoBounds;
    FTemporaryClipModel: TD3ClipModel;
    FDefaultClipModel: TD3ClipModel;
    FTouchCount: Integer;
    function CreateClipSectors(const ADepth: Integer; const ABounds: TGeoBounds;
      var AMaxSector: TGeoVec3): TD3ClipSector;
    procedure ClipModelsTouchingBoundsRecursive(const ANode: TD3ClipSector; const ABounds: TGeoBounds;
      const AContentMask: Integer; const AList: TList<TD3ClipModel>; const AMaxCount: Integer);
    function TestHugeTranslation(var AResults: TCollisionTrace; const AModel: TD3ClipModel;
      const AStart, AEnd: TGeoVec3; const ATrmAxis: TGeoMat3): Boolean;
    function EntityNumber(const AEntity: TObject): Integer;
    function IsWorldPass(const APassEntity: TObject): Boolean;
    function GetRoot: TD3ClipSector;
    function GetDefaultClipModel: TD3ClipModel;
    function TraceModelFor(const AModel: TD3ClipModel): TTraceModel;
  public
    constructor Create(const AManager: ICollisionModelManager; const AEntities: ID3ClipEntities;
      const APrinter: ID3GamePrinter);
    destructor Destroy; override;
    /// <summary>
    ///   idClip::Init: builds the sectors on the bounds of the model <c>worldMap</c>, prints the two lines of the
    ///   original and makes the default clip model (a box of 16 around the origin)
    /// </summary>
    procedure Init;
    /// <summary>idClip::Shutdown</summary>
    procedure Shutdown;
    /// <summary>idClipModel::Link( clp )</summary>
    procedure Link(const AModel: TD3ClipModel); overload;
    /// <summary>idClipModel::Link( clp, ent, id, origin, axis )</summary>
    procedure Link(const AModel: TD3ClipModel; const AEntity: TObject; const AId: Integer; const AOrigin: TGeoVec3;
      const AAxis: TGeoMat3); overload;
    /// <summary>idClip::Translation: true if something was hit</summary>
    function Translation(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3; const AModel: TD3ClipModel;
      const ATrmAxis: TGeoMat3; const AContentMask: Integer; const APassEntity: TObject): Boolean;
    /// <summary>idClip::Rotation</summary>
    function Rotation(var AResults: TCollisionTrace; const AStart: TGeoVec3; const ARotation: TIdRotation;
      const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3; const AContentMask: Integer;
      const APassEntity: TObject): Boolean;
    /// <summary>idClip::Motion</summary>
    function Motion(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3; const ARotation: TIdRotation;
      const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3; const AContentMask: Integer;
      const APassEntity: TObject): Boolean;
    /// <summary>idClip::Contents</summary>
    function Contents(const AStart: TGeoVec3; const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3;
      const AContentMask: Integer; const APassEntity: TObject): Integer;
    /// <summary>idClip::TracePoint</summary>
    function TracePoint(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3; const AContentMask: Integer;
      const APassEntity: TObject): Boolean;
    /// <summary>idClip::TraceBounds</summary>
    function TraceBounds(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3; const ABounds: TGeoBounds;
      const AContentMask: Integer; const APassEntity: TObject): Boolean;
    /// <summary>idClip::TranslationModel</summary>
    procedure TranslationModel(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3;
      const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3; const AContentMask: Integer; const AHandle: Integer;
      const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3);
    /// <summary>idClip::RotationModel</summary>
    procedure RotationModel(var AResults: TCollisionTrace; const AStart: TGeoVec3; const ARotation: TIdRotation;
      const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3; const AContentMask: Integer; const AHandle: Integer;
      const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3);
    /// <summary>idClip::ContentsModel</summary>
    function ContentsModel(const AStart: TGeoVec3; const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3;
      const AContentMask: Integer; const AHandle: Integer; const AModelOrigin: TGeoVec3;
      const AModelAxis: TGeoMat3): Integer;
    /// <summary>idClip::TranslationEntities: against the clip models only, not the world</summary>
    procedure TranslationEntities(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3;
      const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3; const AContentMask: Integer;
      const APassEntity: TObject);
    /// <summary>
    ///   idClip::ClipModelsTouchingBounds: the enabled clip models with some of the contents whose absolute bounds
    ///   overlap the bounds (grown by the box epsilon), each once, in the order of the walk of the tree
    /// </summary>
    function ClipModelsTouchingBounds(const ABounds: TGeoBounds; const AContentMask: Integer;
      const AList: TList<TD3ClipModel>; const AMaxCount: Integer): Integer;
    /// <summary>idClip::EntitiesTouchingBounds: the entities of those clip models, each once</summary>
    function EntitiesTouchingBounds(const ABounds: TGeoBounds; const AContentMask: Integer;
      const AList: TList<TObject>; const AMaxCount: Integer): Integer;
    /// <summary>idClip::GetTraceClipModels: the list with the pass entity, its owner and their missiles left out (nil)</summary>
    function GetTraceClipModels(const ABounds: TGeoBounds; const AContentMask: Integer;
      const APassEntity: TObject; const AList: TList<TD3ClipModel>): Integer;
    /// <summary>
    ///   The game's view of its entities. It can be set after the construction (the game needs the clip and the clip
    ///   needs the game); the clip does not work without it
    /// </summary>
    property Entities: ID3ClipEntities read FEntities write FEntities;
    /// <summary>The collision model manager the clip models of the game are made on (collisionModelManager)</summary>
    property Manager: ICollisionModelManager read FManager;
    property WorldBounds: TGeoBounds read FWorldBounds;
    property DefaultClipModel: TD3ClipModel read GetDefaultClipModel;
    /// <summary>The root of the tree of sectors</summary>
    property Root: TD3ClipSector read GetRoot;
  end;

implementation

uses
  DelphiDoom.MathCore.Float.BoundsRotation, DelphiDoom.D3Game.Types,
  DelphiDoom.D3Game.Errors, DelphiDoom.D3Game.ClipConvert;

const
  SNoWorldMap = 'idClip::Init: the collision model worldMap is not loaded';
  SMaxCount = 'idClip::ClipModelsTouchingBounds_r: max count' + #10;
  SMaxEntities = 'idClip::EntitiesTouchingBounds: max count' + #10;
  SMapBounds = 'map bounds are (%1.1f, %1.1f, %1.1f)' + #10;
  SMaxSector = 'max clip sector is (%1.1f, %1.1f, %1.1f)' + #10;
  SHugeEntity = 'huge translation for clip model %d on entity %d ''%s''' + #10;
  SHugeModel = 'huge translation for clip model %d' + #10;
  SNotTraceModel = 'TraceModelForClipModel: clip model %d is not a trace model' + #10;

constructor TD3Clip.Create(const AManager: ICollisionModelManager; const AEntities: ID3ClipEntities;
  const APrinter: ID3GamePrinter);
begin
  inherited Create;
  FManager := AManager;
  FEntities := AEntities;
  FPrinter := APrinter;
  FSectors := TObjectList<TD3ClipSector>.Create(True);
  FTemporaryClipModel := TD3ClipModel.Create(AManager);
  FDefaultClipModel := TD3ClipModel.Create(AManager);
  FTouchCount := -1;
end;

destructor TD3Clip.Destroy;
begin
  Shutdown;
  FDefaultClipModel.Free;
  FTemporaryClipModel.Free;
  FSectors.Free;
  inherited Destroy;
end;

function TD3Clip.GetRoot: TD3ClipSector;
begin
  if FSectors.Count > 0 then
    Result := FSectors[0]
  else
    Result := nil;
end;

function TD3Clip.GetDefaultClipModel: TD3ClipModel;
begin
  Result := FDefaultClipModel;
end;

function TD3Clip.CreateClipSectors(const ADepth: Integer; const ABounds: TGeoBounds;
  var AMaxSector: TGeoVec3): TD3ClipSector;
var
  LIndex: Integer;
  LSize: TGeoVec3;
  LFront: TGeoBounds;
  LBack: TGeoBounds;
begin
  Result := TD3ClipSector.Create;
  FSectors.Add(Result);

  if ADepth = D3_CLIP_MAX_SECTOR_DEPTH then
  begin
    Result.Axis := -1;
    Result.Children[0] := nil;
    Result.Children[1] := nil;
    for LIndex := 0 to 2 do
      if ABounds.Maxs[LIndex] - ABounds.Mins[LIndex] > AMaxSector[LIndex] then
        AMaxSector[LIndex] := ABounds.Maxs[LIndex] - ABounds.Mins[LIndex];
    Exit;
  end;

  LSize := ABounds.Maxs - ABounds.Mins;
  if (LSize[0] >= LSize[1]) and (LSize[0] >= LSize[2]) then
    Result.Axis := 0
  else if (LSize[1] >= LSize[0]) and (LSize[1] >= LSize[2]) then
    Result.Axis := 1
  else
    Result.Axis := 2;

  Result.Dist := 0.5 * (ABounds.Maxs[Result.Axis] + ABounds.Mins[Result.Axis]);

  LFront := ABounds;
  LBack := ABounds;
  LFront.Mins[Result.Axis] := Result.Dist;
  LBack.Maxs[Result.Axis] := Result.Dist;

  Result.Children[0] := CreateClipSectors(ADepth + 1, LFront, AMaxSector);
  Result.Children[1] := CreateClipSectors(ADepth + 1, LBack, AMaxSector);
end;

procedure TD3Clip.Init;
var
  LHandle: Integer;
  LSize: TGeoVec3;
  LMaxSector: TGeoVec3;
  LBounds: TGeoBounds;
  LTrm: TTraceModel;
begin
  LMaxSector := TGeoVec3.Origin;
  FSectors.Clear;
  FTouchCount := -1;
  // get world map bounds
  LHandle := FManager.FindModel('worldMap');
  if (LHandle < 0) or not FManager.GetModelBounds(LHandle, FWorldBounds) then
    TD3GameErrors.RaiseError(FPrinter, AnsiString(SNoWorldMap));
  // create world sectors
  CreateClipSectors(0, FWorldBounds, LMaxSector);

  LSize := FWorldBounds.Maxs - FWorldBounds.Mins;
  if Assigned(FPrinter) then
  begin
    FPrinter.Printf(AnsiString(Format(SMapBounds, [LSize.X, LSize.Y, LSize.Z], TFormatSettings.Invariant)));
    FPrinter.Printf(AnsiString(Format(SMaxSector, [LMaxSector.X, LMaxSector.Y, LMaxSector.Z],
      TFormatSettings.Invariant)));
  end;

  // initialize a default clip model
  LBounds := TGeoBounds.Make(TGeoVec3.Origin, TGeoVec3.Origin).Expand(8);
  LTrm := TTraceModel.CreateBox(LBounds);
  try
    FDefaultClipModel.LoadModel(LTrm);
  finally
    LTrm.Free;
  end;
end;

procedure TD3Clip.Shutdown;
begin
  FSectors.Clear;
end;

procedure TD3Clip.Link(const AModel: TD3ClipModel);
begin
  AModel.Link(GetRoot);
end;

procedure TD3Clip.Link(const AModel: TD3ClipModel; const AEntity: TObject; const AId: Integer;
  const AOrigin: TGeoVec3; const AAxis: TGeoMat3);
begin
  AModel.Link(GetRoot, AEntity, AId, AOrigin, AAxis);
end;

function TD3Clip.EntityNumber(const AEntity: TObject): Integer;
begin
  Result := FEntities.GetEntityNumber(AEntity);
end;

function TD3Clip.IsWorldPass(const APassEntity: TObject): Boolean;
begin
  Result := Assigned(APassEntity) and (EntityNumber(APassEntity) = D3_ENTITYNUM_WORLD);
end;

procedure TD3Clip.ClipModelsTouchingBoundsRecursive(const ANode: TD3ClipSector; const ABounds: TGeoBounds;
  const AContentMask: Integer; const AList: TList<TD3ClipModel>; const AMaxCount: Integer);
var
  LNode: TD3ClipSector;
  LLink: TD3ClipLink;
  LCheck: TD3ClipModel;
begin
  LNode := ANode;
  while LNode.Axis <> -1 do
  begin
    if ABounds.Mins[LNode.Axis] > LNode.Dist then
      LNode := LNode.Children[0]
    else if ABounds.Maxs[LNode.Axis] < LNode.Dist then
      LNode := LNode.Children[1]
    else
    begin
      ClipModelsTouchingBoundsRecursive(LNode.Children[0], ABounds, AContentMask, AList, AMaxCount);
      LNode := LNode.Children[1];
    end;
  end;

  LLink := LNode.Links;
  while Assigned(LLink) do
  begin
    LCheck := LLink.ClipModel;
    LLink := LLink.NextInSector;

    // if the clip model is enabled
    if not LCheck.IsEnabled then
      Continue;

    // avoid duplicates in the list
    if LCheck.TouchCount = FTouchCount then
      Continue;

    // if the clip model does not have any contents we are looking for
    if (LCheck.Contents and AContentMask) = 0 then
      Continue;

    // if the bounds really do overlap
    if (LCheck.AbsBounds.Mins[0] > ABounds.Maxs[0]) or (LCheck.AbsBounds.Maxs[0] < ABounds.Mins[0]) or
      (LCheck.AbsBounds.Mins[1] > ABounds.Maxs[1]) or (LCheck.AbsBounds.Maxs[1] < ABounds.Mins[1]) or
      (LCheck.AbsBounds.Mins[2] > ABounds.Maxs[2]) or (LCheck.AbsBounds.Maxs[2] < ABounds.Mins[2]) then
      Continue;

    if AList.Count >= AMaxCount then
    begin
      if Assigned(FPrinter) then
        FPrinter.Warning(AnsiString(SMaxCount));
      Exit;
    end;

    LCheck.TouchCount := FTouchCount;
    AList.Add(LCheck);
  end;
end;

function TD3Clip.ClipModelsTouchingBounds(const ABounds: TGeoBounds; const AContentMask: Integer;
  const AList: TList<TD3ClipModel>; const AMaxCount: Integer): Integer;
var
  LParms: TGeoBounds;
  LEpsilon: TGeoVec3;
begin
  AList.Clear;
  if (ABounds.Mins[0] > ABounds.Maxs[0]) or (ABounds.Mins[1] > ABounds.Maxs[1]) or
    (ABounds.Mins[2] > ABounds.Maxs[2]) then
  begin
    // we should not go through the tree for degenerate or backwards bounds
    Result := 0;
    Exit;
  end;

  LEpsilon := TGeoVec3.Make(CM_BOX_EPSILON, CM_BOX_EPSILON, CM_BOX_EPSILON);
  LParms.Mins := ABounds.Mins - LEpsilon;
  LParms.Maxs := ABounds.Maxs + LEpsilon;

  Inc(FTouchCount);
  ClipModelsTouchingBoundsRecursive(GetRoot, LParms, AContentMask, AList, AMaxCount);
  Result := AList.Count;
end;

function TD3Clip.EntitiesTouchingBounds(const ABounds: TGeoBounds; const AContentMask: Integer;
  const AList: TList<TObject>; const AMaxCount: Integer): Integer;
var
  LModels: TList<TD3ClipModel>;
  LIndex: Integer;
begin
  AList.Clear;
  LModels := TList<TD3ClipModel>.Create;
  try
    ClipModelsTouchingBounds(ABounds, AContentMask, LModels, D3_MAX_GENTITIES);
    for LIndex := 0 to LModels.Count - 1 do
      // entity could already be in the list because an entity can use multiple clip models
      if AList.IndexOf(LModels[LIndex].Entity) < 0 then
      begin
        if AList.Count >= AMaxCount then
        begin
          if Assigned(FPrinter) then
            FPrinter.Warning(AnsiString(SMaxEntities));
          Break;
        end;
        AList.Add(LModels[LIndex].Entity);
      end;
  finally
    LModels.Free;
  end;
  Result := AList.Count;
end;

function TD3Clip.GetTraceClipModels(const ABounds: TGeoBounds; const AContentMask: Integer;
  const APassEntity: TObject; const AList: TList<TD3ClipModel>): Integer;
var
  LIndex: Integer;
  LPassOwner: TObject;
  LModel: TD3ClipModel;
begin
  Result := ClipModelsTouchingBounds(ABounds, AContentMask, AList, D3_MAX_GENTITIES);
  if not Assigned(APassEntity) then
    Exit;

  LPassOwner := FEntities.GetPassOwner(APassEntity);
  for LIndex := 0 to Result - 1 do
  begin
    LModel := AList[LIndex];
    // check if we should ignore this entity
    if LModel.Entity = APassEntity then
      AList[LIndex] := nil // don't clip against the pass entity
    else if Assigned(LPassOwner) and (LModel.Entity = LPassOwner) then
      AList[LIndex] := nil // missiles don't clip with their owner
    else if Assigned(LModel.Owner) then
    begin
      if LModel.Owner = APassEntity then
        AList[LIndex] := nil // don't clip against own missiles
      else if LModel.Owner = LPassOwner then
        AList[LIndex] := nil; // don't clip against other missiles from same owner
    end;
  end;
end;

function TD3Clip.TraceModelFor(const AModel: TD3ClipModel): TTraceModel;
begin
  if not Assigned(AModel) then
    Result := nil
  else
  begin
    if not AModel.IsTraceModel then
      TD3GameErrors.RaiseError(FPrinter, AnsiString(Format(SNotTraceModel, [AModel.Id])));
    Result := AModel.GetTraceModel;
  end;
end;

function TD3Clip.TestHugeTranslation(var AResults: TCollisionTrace; const AModel: TD3ClipModel;
  const AStart, AEnd: TGeoVec3; const ATrmAxis: TGeoMat3): Boolean;
var
  LDelta: TGeoVec3;
begin
  Result := False;
  if not Assigned(AModel) then
    Exit;
  LDelta := AEnd - AStart;
  if LDelta.LengthSqr > CM_MAX_TRACE_DIST * CM_MAX_TRACE_DIST then
  begin
    AResults.Fraction := 0.0;
    AResults.EndPos := AStart;
    AResults.EndAxis := ATrmAxis;
    AResults.C := Default(TContactInfo);
    AResults.C.Point := AStart;
    AResults.C.EntityNum := D3_ENTITYNUM_WORLD;
    if Assigned(FPrinter) then
    begin
      if Assigned(AModel.Entity) then
        FPrinter.Printf(AnsiString(Format(SHugeEntity, [AModel.Id, EntityNumber(AModel.Entity),
          string(FEntities.GetEntityName(AModel.Entity))])))
      else
        FPrinter.Printf(AnsiString(Format(SHugeModel, [AModel.Id])));
    end;
    Result := True;
  end;
end;

procedure TD3Clip.TranslationEntities(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3;
  const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3; const AContentMask: Integer;
  const APassEntity: TObject);
var
  LIndex: Integer;
  LTouch: TD3ClipModel;
  LList: TList<TD3ClipModel>;
  LTraceBounds: TGeoBounds;
  LTrace: TCollisionTrace;
  LTrm: TTraceModel;
begin
  if TestHugeTranslation(AResults, AModel, AStart, AEnd, ATrmAxis) then
    Exit;

  LTrm := TraceModelFor(AModel);

  AResults.Fraction := 1.0;
  AResults.EndPos := AEnd;
  AResults.EndAxis := ATrmAxis;

  if not Assigned(LTrm) then
    LTraceBounds.FromPointTranslation(AStart, AEnd - AStart)
  else
    LTraceBounds.FromBoundsTranslation(LTrm.Bounds, AStart, ATrmAxis, AEnd - AStart);

  LList := TList<TD3ClipModel>.Create;
  try
    GetTraceClipModels(LTraceBounds, AContentMask, APassEntity, LList);
    for LIndex := 0 to LList.Count - 1 do
    begin
      LTouch := LList[LIndex];
      if not Assigned(LTouch) then
        Continue;

      FManager.Translation(LTrace, AStart, AEnd, LTrm, ATrmAxis, AContentMask, LTouch.Handle, LTouch.Origin,
        LTouch.Axis);

      if LTrace.Fraction < AResults.Fraction then
      begin
        AResults := LTrace;
        AResults.C.EntityNum := EntityNumber(LTouch.Entity);
        AResults.C.Id := LTouch.Id;
        if AResults.Fraction = 0.0 then
          Break;
      end;
    end;
  finally
    LList.Free;
  end;
end;

function TD3Clip.Translation(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3;
  const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3; const AContentMask: Integer;
  const APassEntity: TObject): Boolean;
var
  LIndex: Integer;
  LTouch: TD3ClipModel;
  LList: TList<TD3ClipModel>;
  LTraceBounds: TGeoBounds;
  LTrace: TCollisionTrace;
  LTrm: TTraceModel;
begin
  if TestHugeTranslation(AResults, AModel, AStart, AEnd, ATrmAxis) then
  begin
    Result := True;
    Exit;
  end;

  LTrm := TraceModelFor(AModel);

  if not IsWorldPass(APassEntity) then
  begin
    // test world
    FManager.Translation(AResults, AStart, AEnd, LTrm, ATrmAxis, AContentMask, 0, TGeoVec3.Origin,
      TGeoMat3.Identity);
    if AResults.Fraction <> 1.0 then
      AResults.C.EntityNum := D3_ENTITYNUM_WORLD
    else
      AResults.C.EntityNum := D3_ENTITYNUM_NONE;
    if AResults.Fraction = 0.0 then
    begin
      Result := True; // blocked immediately by the world
      Exit;
    end;
  end
  else
  begin
    AResults := Default(TCollisionTrace);
    AResults.Fraction := 1.0;
    AResults.EndPos := AEnd;
    AResults.EndAxis := ATrmAxis;
  end;

  if not Assigned(LTrm) then
    LTraceBounds.FromPointTranslation(AStart, AResults.EndPos - AStart)
  else
    LTraceBounds.FromBoundsTranslation(LTrm.Bounds, AStart, ATrmAxis, AResults.EndPos - AStart);

  LList := TList<TD3ClipModel>.Create;
  try
    GetTraceClipModels(LTraceBounds, AContentMask, APassEntity, LList);
    for LIndex := 0 to LList.Count - 1 do
    begin
      LTouch := LList[LIndex];
      if not Assigned(LTouch) then
        Continue;

      FManager.Translation(LTrace, AStart, AEnd, LTrm, ATrmAxis, AContentMask, LTouch.Handle, LTouch.Origin,
        LTouch.Axis);

      if LTrace.Fraction < AResults.Fraction then
      begin
        AResults := LTrace;
        AResults.C.EntityNum := EntityNumber(LTouch.Entity);
        AResults.C.Id := LTouch.Id;
        if AResults.Fraction = 0.0 then
          Break;
      end;
    end;
  finally
    LList.Free;
  end;

  Result := AResults.Fraction < 1.0;
end;

function TD3Clip.Rotation(var AResults: TCollisionTrace; const AStart: TGeoVec3; const ARotation: TIdRotation;
  const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3; const AContentMask: Integer;
  const APassEntity: TObject): Boolean;
var
  LIndex: Integer;
  LTouch: TD3ClipModel;
  LList: TList<TD3ClipModel>;
  LTraceBounds: TGeoBounds;
  LTrace: TCollisionTrace;
  LTrm: TTraceModel;
  LRotation: TIdRotation;
begin
  LRotation := ARotation;
  LTrm := TraceModelFor(AModel);

  if not IsWorldPass(APassEntity) then
  begin
    // test world
    FManager.Rotation(AResults, AStart, LRotation, LTrm, ATrmAxis, AContentMask, 0, TGeoVec3.Origin,
      TGeoMat3.Identity);
    if AResults.Fraction <> 1.0 then
      AResults.C.EntityNum := D3_ENTITYNUM_WORLD
    else
      AResults.C.EntityNum := D3_ENTITYNUM_NONE;
    if AResults.Fraction = 0.0 then
    begin
      Result := True; // blocked immediately by the world
      Exit;
    end;
  end
  else
  begin
    AResults := Default(TCollisionTrace);
    AResults.Fraction := 1.0;
    AResults.EndPos := AStart;
    AResults.EndAxis := ATrmAxis * TD3ClipConvert.ToGeo(LRotation.ToMat3);
  end;

  if not Assigned(LTrm) then
    LTraceBounds := TIdBoundsRotation.FromPointRotation(AStart, LRotation)
  else
    LTraceBounds := TIdBoundsRotation.FromBoundsRotation(LTrm.Bounds, AStart, ATrmAxis, LRotation);

  LList := TList<TD3ClipModel>.Create;
  try
    GetTraceClipModels(LTraceBounds, AContentMask, APassEntity, LList);
    for LIndex := 0 to LList.Count - 1 do
    begin
      LTouch := LList[LIndex];
      if not Assigned(LTouch) then
        Continue;

      FManager.Rotation(LTrace, AStart, LRotation, LTrm, ATrmAxis, AContentMask, LTouch.Handle, LTouch.Origin,
        LTouch.Axis);

      if LTrace.Fraction < AResults.Fraction then
      begin
        AResults := LTrace;
        AResults.C.EntityNum := EntityNumber(LTouch.Entity);
        AResults.C.Id := LTouch.Id;
        if AResults.Fraction = 0.0 then
          Break;
      end;
    end;
  finally
    LList.Free;
  end;

  Result := AResults.Fraction < 1.0;
end;

function TD3Clip.Motion(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3; const ARotation: TIdRotation;
  const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3; const AContentMask: Integer;
  const APassEntity: TObject): Boolean;
var
  LIndex: Integer;
  LNum: Integer;
  LTouch: TD3ClipModel;
  LList: TList<TD3ClipModel>;
  LDir: TGeoVec3;
  LEndPosition: TGeoVec3;
  LTraceBounds: TGeoBounds;
  LTranslational: TCollisionTrace;
  LRotational: TCollisionTrace;
  LTrace: TCollisionTrace;
  LRotation: TIdRotation;
  LEndRotation: TIdRotation;
  LTrm: TTraceModel;
  LVector: TGeoVec3;
begin
  LRotation := ARotation;
  if TestHugeTranslation(AResults, AModel, AStart, AEnd, ATrmAxis) then
  begin
    Result := True;
    Exit;
  end;

  LVector := TGeoVec3.Make(LRotation.Vector.X, LRotation.Vector.Y, LRotation.Vector.Z);
  if Assigned(AModel) and (LRotation.Angle <> 0.0) and not LVector.Compare(TGeoVec3.Origin) then
  begin
    // if no translation
    if AStart.Compare(AEnd) then
    begin
      // pure rotation
      Result := Rotation(AResults, AStart, LRotation, AModel, ATrmAxis, AContentMask, APassEntity);
      Exit;
    end;
  end
  else if not AStart.Compare(AEnd) then
  begin
    // pure translation
    Result := Translation(AResults, AStart, AEnd, AModel, ATrmAxis, AContentMask, APassEntity);
    Exit;
  end
  else
  begin
    // no motion
    AResults.Fraction := 1.0;
    AResults.EndPos := AStart;
    AResults.EndAxis := ATrmAxis;
    Result := False;
    Exit;
  end;

  LTrm := TraceModelFor(AModel);

  if not IsWorldPass(APassEntity) then
  begin
    // translational collision with world
    FManager.Translation(LTranslational, AStart, AEnd, LTrm, ATrmAxis, AContentMask, 0, TGeoVec3.Origin,
      TGeoMat3.Identity);
    if LTranslational.Fraction <> 1.0 then
      LTranslational.C.EntityNum := D3_ENTITYNUM_WORLD
    else
      LTranslational.C.EntityNum := D3_ENTITYNUM_NONE;
  end
  else
  begin
    LTranslational := Default(TCollisionTrace);
    LTranslational.Fraction := 1.0;
    LTranslational.EndPos := AEnd;
    LTranslational.EndAxis := ATrmAxis;
  end;

  LList := TList<TD3ClipModel>.Create;
  try
    if LTranslational.Fraction <> 0.0 then
    begin
      LTraceBounds := TIdBoundsRotation.FromBoundsRotation(LTrm.Bounds, AStart, ATrmAxis, LRotation);
      LDir := LTranslational.EndPos - AStart;
      for LIndex := 0 to 2 do
        if LDir[LIndex] < 0.0 then
          LTraceBounds.Mins[LIndex] := LTraceBounds.Mins[LIndex] + LDir[LIndex]
        else
          LTraceBounds.Maxs[LIndex] := LTraceBounds.Maxs[LIndex] + LDir[LIndex];

      LNum := GetTraceClipModels(LTraceBounds, AContentMask, APassEntity, LList);

      for LIndex := 0 to LList.Count - 1 do
      begin
        LTouch := LList[LIndex];
        if not Assigned(LTouch) then
          Continue;

        FManager.Translation(LTrace, AStart, AEnd, LTrm, ATrmAxis, AContentMask, LTouch.Handle, LTouch.Origin,
          LTouch.Axis);

        if LTrace.Fraction < LTranslational.Fraction then
        begin
          LTranslational := LTrace;
          LTranslational.C.EntityNum := EntityNumber(LTouch.Entity);
          LTranslational.C.Id := LTouch.Id;
          if LTranslational.Fraction = 0.0 then
            Break;
        end;
      end;
    end
    else
      LNum := -1;

    LEndPosition := LTranslational.EndPos;
    LEndRotation := LRotation;
    LEndRotation.SetOrigin(TD3ClipConvert.ToId(LEndPosition));

    if not IsWorldPass(APassEntity) then
    begin
      // rotational collision with world
      FManager.Rotation(LRotational, LEndPosition, LEndRotation, LTrm, ATrmAxis, AContentMask, 0,
        TGeoVec3.Origin, TGeoMat3.Identity);
      if LRotational.Fraction <> 1.0 then
        LRotational.C.EntityNum := D3_ENTITYNUM_WORLD
      else
        LRotational.C.EntityNum := D3_ENTITYNUM_NONE;
    end
    else
    begin
      LRotational := Default(TCollisionTrace);
      LRotational.Fraction := 1.0;
      LRotational.EndPos := LEndPosition;
      LRotational.EndAxis := ATrmAxis * TD3ClipConvert.ToGeo(LRotation.ToMat3);
    end;

    if LRotational.Fraction <> 0.0 then
    begin
      if LNum = -1 then
      begin
        LTraceBounds := TIdBoundsRotation.FromBoundsRotation(LTrm.Bounds, LEndPosition, ATrmAxis, LEndRotation);
        GetTraceClipModels(LTraceBounds, AContentMask, APassEntity, LList);
      end;

      for LIndex := 0 to LList.Count - 1 do
      begin
        LTouch := LList[LIndex];
        if not Assigned(LTouch) then
          Continue;

        FManager.Rotation(LTrace, LEndPosition, LEndRotation, LTrm, ATrmAxis, AContentMask, LTouch.Handle,
          LTouch.Origin, LTouch.Axis);

        if LTrace.Fraction < LRotational.Fraction then
        begin
          LRotational := LTrace;
          LRotational.C.EntityNum := EntityNumber(LTouch.Entity);
          LRotational.C.Id := LTouch.Id;
          if LRotational.Fraction = 0.0 then
            Break;
        end;
      end;
    end;
  finally
    LList.Free;
  end;

  if LRotational.Fraction < 1.0 then
    AResults := LRotational
  else
  begin
    AResults := LTranslational;
    AResults.EndAxis := LRotational.EndAxis;
  end;

  if LTranslational.Fraction > LRotational.Fraction then
    AResults.Fraction := LTranslational.Fraction
  else
    AResults.Fraction := LRotational.Fraction;

  Result := (LTranslational.Fraction < 1.0) or (LRotational.Fraction < 1.0);
end;

function TD3Clip.Contents(const AStart: TGeoVec3; const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3;
  const AContentMask: Integer; const APassEntity: TObject): Integer;
var
  LIndex: Integer;
  LTouch: TD3ClipModel;
  LList: TList<TD3ClipModel>;
  LTraceBounds: TGeoBounds;
  LTrm: TTraceModel;
begin
  LTrm := TraceModelFor(AModel);

  if not IsWorldPass(APassEntity) then
    // test world
    Result := FManager.Contents(AStart, LTrm, ATrmAxis, AContentMask, 0, TGeoVec3.Origin, TGeoMat3.Identity)
  else
    Result := 0;

  if not Assigned(LTrm) then
  begin
    LTraceBounds.Mins := AStart;
    LTraceBounds.Maxs := AStart;
  end
  else if ATrmAxis.IsRotated then
    LTraceBounds.FromTransformedBounds(LTrm.Bounds, AStart, ATrmAxis)
  else
  begin
    LTraceBounds.Mins := LTrm.Bounds.Mins + AStart;
    LTraceBounds.Maxs := LTrm.Bounds.Maxs + AStart;
  end;

  LList := TList<TD3ClipModel>.Create;
  try
    GetTraceClipModels(LTraceBounds, -1, APassEntity, LList);
    for LIndex := 0 to LList.Count - 1 do
    begin
      LTouch := LList[LIndex];
      if not Assigned(LTouch) then
        Continue;

      // if the entity does not have any contents we are looking for
      if (LTouch.Contents and AContentMask) = 0 then
        Continue;

      // if the entity has no new contents flags
      if (LTouch.Contents and Result) = LTouch.Contents then
        Continue;

      if FManager.Contents(AStart, LTrm, ATrmAxis, AContentMask, LTouch.Handle, LTouch.Origin, LTouch.Axis) <> 0 then
        Result := Result or (LTouch.Contents and AContentMask);
    end;
  finally
    LList.Free;
  end;
end;

function TD3Clip.TracePoint(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3;
  const AContentMask: Integer; const APassEntity: TObject): Boolean;
begin
  Translation(AResults, AStart, AEnd, nil, TGeoMat3.Identity, AContentMask, APassEntity);
  Result := AResults.Fraction < 1.0;
end;

function TD3Clip.TraceBounds(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3;
  const ABounds: TGeoBounds; const AContentMask: Integer; const APassEntity: TObject): Boolean;
var
  LTrm: TTraceModel;
begin
  LTrm := TTraceModel.CreateBox(ABounds);
  try
    FTemporaryClipModel.LoadModel(LTrm);
  finally
    LTrm.Free;
  end;
  Translation(AResults, AStart, AEnd, FTemporaryClipModel, TGeoMat3.Identity, AContentMask, APassEntity);
  Result := AResults.Fraction < 1.0;
end;

procedure TD3Clip.TranslationModel(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3;
  const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3; const AContentMask: Integer; const AHandle: Integer;
  const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3);
begin
  FManager.Translation(AResults, AStart, AEnd, TraceModelFor(AModel), ATrmAxis, AContentMask, AHandle,
    AModelOrigin, AModelAxis);
end;

procedure TD3Clip.RotationModel(var AResults: TCollisionTrace; const AStart: TGeoVec3;
  const ARotation: TIdRotation; const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3; const AContentMask: Integer;
  const AHandle: Integer; const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3);
begin
  FManager.Rotation(AResults, AStart, ARotation, TraceModelFor(AModel), ATrmAxis, AContentMask, AHandle,
    AModelOrigin, AModelAxis);
end;

function TD3Clip.ContentsModel(const AStart: TGeoVec3; const AModel: TD3ClipModel; const ATrmAxis: TGeoMat3;
  const AContentMask: Integer; const AHandle: Integer; const AModelOrigin: TGeoVec3;
  const AModelAxis: TGeoMat3): Integer;
begin
  Result := FManager.Contents(AStart, TraceModelFor(AModel), ATrmAxis, AContentMask, AHandle, AModelOrigin,
    AModelAxis);
end;

end.
