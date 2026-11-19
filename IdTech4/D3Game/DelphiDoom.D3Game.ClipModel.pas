{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - idClipModel                               }
{                                                                              }
{  Port of Doom 3 (id Software): game\physics\Clip.h, Clip.cpp (idClipModel    }
{  and the clipSector_t / clipLink_t it links with). Not ported: render model  }
{  clip models (no renderer), the shared trace model cache (every clip model   }
{  owns a copy of its trace model: nothing can tell), the mass properties,     }
{  Save and Restore.                                                           }
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
unit DelphiDoom.D3Game.ClipModel;

interface

uses
  DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3, DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.TraceModel,
  DelphiDoom.Collision.Types, DelphiDoom.Collision.Intf;

type
  TD3ClipModel = class;
  TD3ClipSector = class;

  /// <summary>clipLink_t: the link of a clip model into a sector (doubly linked in the sector)</summary>
  TD3ClipLink = class
  public
    ClipModel: TD3ClipModel;
    Sector: TD3ClipSector;
    PrevInSector: TD3ClipLink;
    NextInSector: TD3ClipLink;
    /// <summary>The next link of the same clip model</summary>
    NextLink: TD3ClipLink;
  end;

  /// <summary>clipSector_t: a node of the tree; Axis -1 is a leaf, which has the links</summary>
  TD3ClipSector = class
  public
    Axis: Integer;
    Dist: Single;
    Children: array[0..1] of TD3ClipSector;
    Links: TD3ClipLink;
  end;

  /// <summary>
  ///   idClipModel: the shape an entity collides with: a collision model by handle or a trace model, an origin and an
  ///   axis, contents, and the owner and entity it belongs to. <c>Entity</c> and <c>Owner</c> are opaque here (the
  ///   clip asks the game for their numbers through <c>ID3ClipEntities</c>). The links into the sectors are owned by
  ///   the clip model and freed by <c>Unlink</c> (and the destructor).
  /// </summary>
  TD3ClipModel = class
  strict private
    FManager: ICollisionModelManager;
    FEnabled: Boolean;
    FEntity: TObject;
    FId: Integer;
    FOwner: TObject;
    FOrigin: TGeoVec3;
    FAxis: TGeoMat3;
    FBounds: TGeoBounds;
    FAbsBounds: TGeoBounds;
    FMaterial: TCollisionMaterial;
    FContents: Integer;
    FHandle: Integer;
    FTraceModel: TTraceModel;
    FLinks: TD3ClipLink;
    FTouchCount: Integer;
    procedure Init;
    procedure LinkSector(const ANode: TD3ClipSector);
  public
    /// <summary>idClipModel( void ): no shape, contents <c>CONTENTS_BODY</c></summary>
    constructor Create(const AManager: ICollisionModelManager); overload;
    /// <summary>idClipModel( const char *name )</summary>
    constructor Create(const AManager: ICollisionModelManager; const AName: string); overload;
    /// <summary>idClipModel( const idTraceModel &amp;trm ): copies the trace model</summary>
    constructor Create(const AManager: ICollisionModelManager; const ATraceModel: TTraceModel); overload;
    /// <summary>idClipModel( const idClipModel *model ): not linked</summary>
    constructor Create(const ASource: TD3ClipModel); overload;
    destructor Destroy; override;
    /// <summary>idClipModel::LoadModel( name ): a name that is not found (or is the world) gives handle 0 and false</summary>
    function LoadModel(const AName: string): Boolean; overload;
    /// <summary>idClipModel::LoadModel( trm )</summary>
    procedure LoadModel(const ATraceModel: TTraceModel); overload;
    /// <summary>
    ///   idClipModel::Link( clp ): the entity and id must have been set. Computes the absolute bounds (expanded by the
    ///   box epsilon) and links into every leaf they touch, starting at the root sector.
    /// </summary>
    procedure Link(const ARoot: TD3ClipSector); overload;
    procedure Link(const ARoot: TD3ClipSector; const AEntity: TObject; const AId: Integer; const AOrigin: TGeoVec3;
      const AAxis: TGeoMat3); overload;
    procedure Unlink;
    /// <summary>idClipModel::SetPosition: unlinks the clip model</summary>
    procedure SetPosition(const AOrigin: TGeoVec3; const AAxis: TGeoMat3);
    procedure Translate(const ATranslation: TGeoVec3);
    procedure Enable;
    procedure Disable;
    /// <summary>idClipModel::Handle: the collision model, or the trace model set up in the manager</summary>
    function Handle: Integer;
    function IsTraceModel: Boolean;
    function IsLinked: Boolean;
    function IsEnabled: Boolean;
    /// <summary>The trace model, nil if there is none (owned by the clip model)</summary>
    function GetTraceModel: TTraceModel;
    property Entity: TObject read FEntity write FEntity;
    property Owner: TObject read FOwner write FOwner;
    property Id: Integer read FId write FId;
    property Origin: TGeoVec3 read FOrigin;
    property Axis: TGeoMat3 read FAxis;
    property Bounds: TGeoBounds read FBounds;
    property AbsBounds: TGeoBounds read FAbsBounds;
    property Material: TCollisionMaterial read FMaterial write FMaterial;
    property Contents: Integer read FContents write FContents;
    /// <summary>The last query that listed this clip model (the duplicate check of <c>ClipModelsTouchingBounds</c>)</summary>
    property TouchCount: Integer read FTouchCount write FTouchCount;
  end;

implementation

uses
  System.SysUtils;

constructor TD3ClipModel.Create(const AManager: ICollisionModelManager);
begin
  inherited Create;
  FManager := AManager;
  Init;
end;

constructor TD3ClipModel.Create(const AManager: ICollisionModelManager; const AName: string);
begin
  Create(AManager);
  LoadModel(AName);
end;

constructor TD3ClipModel.Create(const AManager: ICollisionModelManager; const ATraceModel: TTraceModel);
begin
  Create(AManager);
  LoadModel(ATraceModel);
end;

constructor TD3ClipModel.Create(const ASource: TD3ClipModel);
begin
  inherited Create;
  FManager := ASource.FManager;
  FEnabled := ASource.FEnabled;
  FEntity := ASource.FEntity;
  FId := ASource.FId;
  FOwner := ASource.FOwner;
  FOrigin := ASource.FOrigin;
  FAxis := ASource.FAxis;
  FBounds := ASource.FBounds;
  FAbsBounds := ASource.FAbsBounds;
  FMaterial := ASource.FMaterial;
  FContents := ASource.FContents;
  FHandle := ASource.FHandle;
  FLinks := nil;
  FTouchCount := -1;
  if Assigned(ASource.FTraceModel) then
    LoadModel(ASource.FTraceModel);
end;

destructor TD3ClipModel.Destroy;
begin
  // make sure the clip model is no longer linked
  Unlink;
  FTraceModel.Free;
  inherited Destroy;
end;

procedure TD3ClipModel.Init;
begin
  FEnabled := True;
  FEntity := nil;
  FId := 0;
  FOwner := nil;
  FOrigin := TGeoVec3.Origin;
  FAxis := TGeoMat3.Identity;
  FBounds.Zero;
  FAbsBounds.Zero;
  FMaterial := nil;
  FContents := CONTENTS_BODY;
  FHandle := 0;
  FTraceModel := nil;
  FLinks := nil;
  FTouchCount := -1;
end;

function TD3ClipModel.LoadModel(const AName: string): Boolean;
var
  LHandle: Integer;
begin
  FreeAndNil(FTraceModel);
  LHandle := FManager.FindModel(AName);
  if LHandle < 0 then
    LHandle := 0;
  FHandle := LHandle;
  // handle 0 is the world and also what a model that is not found gives: the original cannot tell them apart
  if FHandle <> 0 then
  begin
    FManager.GetModelBounds(FHandle, FBounds);
    FManager.GetModelContents(FHandle, FContents);
    Result := True;
  end
  else
  begin
    FBounds.Zero;
    Result := False;
  end;
end;

procedure TD3ClipModel.LoadModel(const ATraceModel: TTraceModel);
begin
  FHandle := 0;
  if FTraceModel <> ATraceModel then
  begin
    FTraceModel.Free;
    FTraceModel := TTraceModel.Create;
    FTraceModel.Assign(ATraceModel);
  end;
  FBounds := ATraceModel.Bounds;
end;

procedure TD3ClipModel.Unlink;
var
  LLink: TD3ClipLink;
begin
  LLink := FLinks;
  while Assigned(LLink) do
  begin
    FLinks := LLink.NextLink;
    if Assigned(LLink.PrevInSector) then
      LLink.PrevInSector.NextInSector := LLink.NextInSector
    else
      LLink.Sector.Links := LLink.NextInSector;
    if Assigned(LLink.NextInSector) then
      LLink.NextInSector.PrevInSector := LLink.PrevInSector;
    LLink.Free;
    LLink := FLinks;
  end;
end;

procedure TD3ClipModel.LinkSector(const ANode: TD3ClipSector);
var
  LNode: TD3ClipSector;
  LLink: TD3ClipLink;
begin
  LNode := ANode;
  while LNode.Axis <> -1 do
  begin
    if FAbsBounds.Mins[LNode.Axis] > LNode.Dist then
      LNode := LNode.Children[0]
    else if FAbsBounds.Maxs[LNode.Axis] < LNode.Dist then
      LNode := LNode.Children[1]
    else
    begin
      LinkSector(LNode.Children[0]);
      LNode := LNode.Children[1];
    end;
  end;

  LLink := TD3ClipLink.Create;
  LLink.ClipModel := Self;
  LLink.Sector := LNode;
  LLink.NextInSector := LNode.Links;
  LLink.PrevInSector := nil;
  if Assigned(LNode.Links) then
    LNode.Links.PrevInSector := LLink;
  LNode.Links := LLink;
  LLink.NextLink := FLinks;
  FLinks := LLink;
end;

procedure TD3ClipModel.Link(const ARoot: TD3ClipSector);
var
  LEpsilon: TGeoVec3;
begin
  if not Assigned(FEntity) then
    Exit;

  if Assigned(FLinks) then
    Unlink; // unlink from old position

  if FBounds.IsCleared then
    Exit;

  // set the abs box
  if FAxis.IsRotated then
    // expand for rotation
    FAbsBounds.FromTransformedBounds(FBounds, FOrigin, FAxis)
  else
  begin
    FAbsBounds.Mins := FBounds.Mins + FOrigin;
    FAbsBounds.Maxs := FBounds.Maxs + FOrigin;
  end;

  // because movement is clipped an epsilon away from an actual edge, we must fully check even when bounding boxes
  // don't quite touch
  LEpsilon := TGeoVec3.Make(CM_BOX_EPSILON, CM_BOX_EPSILON, CM_BOX_EPSILON);
  FAbsBounds.Mins := FAbsBounds.Mins - LEpsilon;
  FAbsBounds.Maxs := FAbsBounds.Maxs + LEpsilon;

  LinkSector(ARoot);
end;

procedure TD3ClipModel.Link(const ARoot: TD3ClipSector; const AEntity: TObject; const AId: Integer;
  const AOrigin: TGeoVec3; const AAxis: TGeoMat3);
begin
  FEntity := AEntity;
  FId := AId;
  FOrigin := AOrigin;
  FAxis := AAxis;
  Link(ARoot);
end;

procedure TD3ClipModel.SetPosition(const AOrigin: TGeoVec3; const AAxis: TGeoMat3);
begin
  if Assigned(FLinks) then
    Unlink; // unlink from old position
  FOrigin := AOrigin;
  FAxis := AAxis;
end;

procedure TD3ClipModel.Translate(const ATranslation: TGeoVec3);
begin
  Unlink;
  FOrigin := FOrigin + ATranslation;
end;

procedure TD3ClipModel.Enable;
begin
  FEnabled := True;
end;

procedure TD3ClipModel.Disable;
begin
  FEnabled := False;
end;

function TD3ClipModel.Handle: Integer;
begin
  if FHandle <> 0 then
    Result := FHandle
  else if Assigned(FTraceModel) then
    Result := FManager.SetupTrmModel(FTraceModel, FMaterial)
  else
    // this happens in multiplayer on the combat models
    Result := 0;
end;

function TD3ClipModel.IsTraceModel: Boolean;
begin
  Result := Assigned(FTraceModel);
end;

function TD3ClipModel.IsLinked: Boolean;
begin
  Result := Assigned(FLinks);
end;

function TD3ClipModel.IsEnabled: Boolean;
begin
  Result := FEnabled;
end;

function TD3ClipModel.GetTraceModel: TTraceModel;
begin
  Result := FTraceModel;
end;

end.
