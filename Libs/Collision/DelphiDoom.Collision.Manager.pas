{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the model manager                           }
{                                                                              }
{  Port of the registry part of idCollisionModelManagerLocal (CollisionModel_  }
{  local.h, CollisionModel_load.cpp, CollisionModel_contacts.cpp), Doom 3 GPL  }
{  Source Code. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media       }
{  company. Doom 3 Source Code: GNU General Public License version 3 with      }
{  additional terms. This unit is a derived work (GPL v3).                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Manager;

interface

uses
  System.Classes, System.Generics.Collections, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Mat3,
  DelphiDoom.Geometry.Bounds, DelphiDoom.Geometry.Winding, DelphiDoom.Geometry.TraceModel,
  DelphiDoom.Logging.Intf, DelphiDoom.Collision.Types, DelphiDoom.Collision.Intf,
  DelphiDoom.Collision.Model, DelphiDoom.Collision.CheckCounter, DelphiDoom.Collision.Translator,
  DelphiDoom.Collision.ContentsTester, DelphiDoom.Collision.Tracer, DelphiDoom.Collision.ContentsRunner,
  DelphiDoom.Collision.TranslationRunner, DelphiDoom.Collision.TrmModel;

type
  /// <summary>
  ///   The registry of collision models and the queries on them. It owns the models and
  ///   the shared counter, and assembles the translator, the tester and the tracer (it is the
  ///   composition point of the library, TCollisionFactory creates it). The state that the C++
  ///   manager keeps in fields and in function statics (checkCount, the static trace work,
  ///   the contacts) is held here or per call: two managers do not disturb each other.
  ///   Not thread safe: one query at a time per manager (the C++ code has the same limit).
  /// </summary>
  TCollisionModelManager = class(TInterfacedObject, ICollisionModelManager)
  private
    FLog: ILog;
    FCatalog: ICollisionMaterialCatalog;
    FModels: TObjectList<TCollisionModel>;
    FCounter: TCollisionCheckCounter;
    FTranslator: TCollisionTranslator;
    FContentsTester: TCollisionContentsTester;
    FTracer: TCollisionTracer;
    FContentsRunner: TCollisionContentsRunner;
    FTranslationRunner: TCollisionTranslationRunner;
    FTrmSlot: TCollisionTrmModelSlot;
    function ModelOf(AHandle: Integer; const AFunction: string): TCollisionModel;
    procedure Say(const AText: string);
  public
    /// <summary>
    ///   ACatalog gives the "_tracemodel" material for the trace model slot and the materials
    ///   of the files; ALog may be nil
    /// </summary>
    constructor Create(const ACatalog: ICollisionMaterialCatalog; const ALog: ILog);
    destructor Destroy; override;

    procedure FreeMap;
    function AddModel(AModel: TCollisionModel): Integer;
    function FindModel(const AName: string): Integer;
    function LoadModelFile(AStream: TStream; AMapFileCrc: Cardinal = 0): Integer;
    function SetupTrmModel(ATrm: TTraceModel; AMaterial: TCollisionMaterial): Integer;
    function TrmFromModel(AHandle: Integer; ATrm: TTraceModel): Boolean;
    function GetModelName(AHandle: Integer): string;
    function GetModelBounds(AHandle: Integer; out ABounds: TGeoBounds): Boolean;
    function GetModelContents(AHandle: Integer; out AContents: Integer): Boolean;
    function GetModelVertex(AHandle, AVertexNum: Integer; out AVertex: TGeoVec3): Boolean;
    function GetModelEdge(AHandle, AEdgeNum: Integer; out AStart, AEnd: TGeoVec3): Boolean;
    function GetModelPolygon(AHandle, APolygonNum: Integer): TGeoWinding;
    procedure Translation(var AResults: TCollisionTrace; const AStart, AEnd: TGeoVec3; ATrm: TTraceModel;
      const ATrmAxis: TGeoMat3; AContentMask: Integer; AModel: Integer; const AModelOrigin: TGeoVec3;
      const AModelAxis: TGeoMat3);
    function Contents(const AStart: TGeoVec3; ATrm: TTraceModel; const ATrmAxis: TGeoMat3;
      AContentMask: Integer; AModel: Integer; const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3): Integer;
    function Contacts(AContacts: TList<TContactInfo>; AMaxContacts: Integer; const AStart, ADir: TGeoVec3;
      ADepth: Single; ATrm: TTraceModel; const ATrmAxis: TGeoMat3; AContentMask: Integer; AModel: Integer;
      const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3): Integer;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Collision.Model.Types, DelphiDoom.Collision.Model.Polygon,
  DelphiDoom.Collision.CmFile.Reader, DelphiDoom.Collision.TrmExtractor;

resourcestring
  SInvalidHandle = 'TCollisionModelManager.%s: invalid model handle';
  SInvalidVertex = 'TCollisionModelManager.GetModelVertex: invalid vertex number';
  SInvalidEdge = 'TCollisionModelManager.GetModelEdge: invalid edge number';
  STraceModelMaterial = '_tracemodel';

{ TCollisionModelManager }

constructor TCollisionModelManager.Create(const ACatalog: ICollisionMaterialCatalog; const ALog: ILog);
begin
  inherited Create;
  FCatalog := ACatalog;
  FLog := ALog;
  FModels := TObjectList<TCollisionModel>.Create(True);
  FCounter := TCollisionCheckCounter.Create;
  FTranslator := TCollisionTranslator.Create(FCounter);
  FContentsTester := TCollisionContentsTester.Create(FCounter);
  FTracer := TCollisionTracer.Create(FTranslator, FContentsTester);
  FContentsRunner := TCollisionContentsRunner.Create(FCounter, FTracer);
  FTranslationRunner := TCollisionTranslationRunner.Create(FLog, FCounter, FTracer, FContentsRunner);
  FTrmSlot := TCollisionTrmModelSlot.Create(FCatalog.FindMaterial(STraceModelMaterial));
end;

destructor TCollisionModelManager.Destroy;
begin
  FTrmSlot.Free;
  FTranslationRunner.Free;
  FContentsRunner.Free;
  FTracer.Free;
  FContentsTester.Free;
  FTranslator.Free;
  FCounter.Free;
  FModels.Free;
  inherited Destroy;
end;

procedure TCollisionModelManager.Say(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Info(AText + #10);
end;

function TCollisionModelManager.ModelOf(AHandle: Integer; const AFunction: string): TCollisionModel;
begin
  Result := nil;
  if AHandle = TRACE_MODEL_HANDLE then
    Result := FTrmSlot.Model
  else if (AHandle >= 0) and (AHandle < FModels.Count) then
    Result := FModels[AHandle];
  if not Assigned(Result) then
    Say(Format(SInvalidHandle, [AFunction]));
end;

procedure TCollisionModelManager.FreeMap;
begin
  FModels.Clear;
end;

function TCollisionModelManager.AddModel(AModel: TCollisionModel): Integer;
begin
  // the counter of this manager may already have reached the values left on the model
  AModel.ResetCheckCounts;
  Result := FModels.Add(AModel);
end;

function TCollisionModelManager.FindModel(const AName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FModels.Count - 1 do
    if SameText(FModels[LIndex].Name, AName) then
      Exit(LIndex);
  Result := -1;
end;

function TCollisionModelManager.LoadModelFile(AStream: TStream; AMapFileCrc: Cardinal): Integer;
var
  LReader: TCollisionFileReader;
  LList: TObjectList<TCollisionModel>;
  LIndex: Integer;
begin
  Result := 0;
  LReader := TCollisionFileReader.Create(FCatalog, FLog);
  try
    LList := LReader.LoadFromStream(AStream, AMapFileCrc);
  finally
    LReader.Free;
  end;
  if not Assigned(LList) then
    Exit;
  try
    LList.OwnsObjects := False;
    for LIndex := 0 to LList.Count - 1 do
    begin
      AddModel(LList[LIndex]);
      Inc(Result);
    end;
  finally
    LList.Free;
  end;
end;

function TCollisionModelManager.SetupTrmModel(ATrm: TTraceModel; AMaterial: TCollisionMaterial): Integer;
begin
  FTrmSlot.Setup(ATrm, AMaterial);
  Result := TRACE_MODEL_HANDLE;
end;

function TCollisionModelManager.TrmFromModel(AHandle: Integer; ATrm: TTraceModel): Boolean;
var
  LModel: TCollisionModel;
begin
  LModel := ModelOf(AHandle, 'TrmFromModel');
  Result := Assigned(LModel) and TCollisionTrmExtractor.Extract(LModel, ATrm, FLog);
end;

function TCollisionModelManager.GetModelName(AHandle: Integer): string;
var
  LModel: TCollisionModel;
begin
  LModel := ModelOf(AHandle, 'GetModelName');
  if Assigned(LModel) then
    Result := LModel.Name
  else
    Result := '';
end;

function TCollisionModelManager.GetModelBounds(AHandle: Integer; out ABounds: TGeoBounds): Boolean;
var
  LModel: TCollisionModel;
begin
  LModel := ModelOf(AHandle, 'GetModelBounds');
  Result := Assigned(LModel);
  if Result then
    ABounds := LModel.Bounds;
end;

function TCollisionModelManager.GetModelContents(AHandle: Integer; out AContents: Integer): Boolean;
var
  LModel: TCollisionModel;
begin
  LModel := ModelOf(AHandle, 'GetModelContents');
  Result := Assigned(LModel);
  if Result then
    AContents := LModel.Contents;
end;

function TCollisionModelManager.GetModelVertex(AHandle, AVertexNum: Integer; out AVertex: TGeoVec3): Boolean;
var
  LModel: TCollisionModel;
begin
  Result := False;
  LModel := ModelOf(AHandle, 'GetModelVertex');
  if not Assigned(LModel) then
    Exit;
  if (AVertexNum < 0) or (AVertexNum >= LModel.NumVertices) then
  begin
    Say(SInvalidVertex);
    Exit;
  end;
  AVertex := LModel.Vertices[AVertexNum].P;
  Result := True;
end;

function TCollisionModelManager.GetModelEdge(AHandle, AEdgeNum: Integer; out AStart, AEnd: TGeoVec3): Boolean;
var
  LModel: TCollisionModel;
begin
  Result := False;
  LModel := ModelOf(AHandle, 'GetModelEdge');
  if not Assigned(LModel) then
    Exit;
  AEdgeNum := Abs(AEdgeNum);
  if AEdgeNum >= LModel.NumEdges then
  begin
    Say(SInvalidEdge);
    Exit;
  end;
  AStart := LModel.Vertices[LModel.Edges[AEdgeNum].VertexNum[0]].P;
  AEnd := LModel.Vertices[LModel.Edges[AEdgeNum].VertexNum[1]].P;
  Result := True;
end;

function TCollisionModelManager.GetModelPolygon(AHandle, APolygonNum: Integer): TGeoWinding;
var
  LModel: TCollisionModel;
  LPolygon: TCmPolygon;
  LIndex: Integer;
  LEdgeNum: Integer;
  LVertex: Integer;
begin
  Result := nil;
  LModel := ModelOf(AHandle, 'GetModelPolygon');
  if not Assigned(LModel) then
    Exit;
  LPolygon := LModel.PolygonById(APolygonNum);
  if not Assigned(LPolygon) then
    Exit;
  Result := TGeoWinding.Create;
  for LIndex := 0 to LPolygon.NumEdges - 1 do
  begin
    LEdgeNum := LPolygon.Edges[LIndex];
    if LEdgeNum < 0 then
      LVertex := 1
    else
      LVertex := 0;
    Result.AddPoint(LModel.Vertices[LModel.Edges[Abs(LEdgeNum)].VertexNum[LVertex]].P);
  end;
end;

procedure TCollisionModelManager.Translation(var AResults: TCollisionTrace; const AStart,
  AEnd: TGeoVec3; ATrm: TTraceModel; const ATrmAxis: TGeoMat3; AContentMask: Integer; AModel: Integer;
  const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3);
var
  LModel: TCollisionModel;
begin
  AResults := Default(TCollisionTrace);
  LModel := ModelOf(AModel, 'Translation');
  if not Assigned(LModel) then
    Exit;
  FTranslationRunner.Translate(AResults, AStart, AEnd, ATrm, ATrmAxis, AContentMask, LModel, AModelOrigin,
    AModelAxis);
end;

function TCollisionModelManager.Contents(const AStart: TGeoVec3; ATrm: TTraceModel; const ATrmAxis: TGeoMat3;
  AContentMask: Integer; AModel: Integer; const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3): Integer;
var
  LModel: TCollisionModel;
  LResults: TCollisionTrace;
begin
  Result := 0;
  LModel := ModelOf(AModel, 'Contents');
  if not Assigned(LModel) then
    Exit;
  LResults := Default(TCollisionTrace);
  Result := FContentsRunner.ContentsTrm(LResults, AStart, ATrm, ATrmAxis, AContentMask, LModel,
    AModelOrigin, AModelAxis);
end;

function TCollisionModelManager.Contacts(AContacts: TList<TContactInfo>; AMaxContacts: Integer;
  const AStart, ADir: TGeoVec3; ADepth: Single; ATrm: TTraceModel; const ATrmAxis: TGeoMat3;
  AContentMask: Integer; AModel: Integer; const AModelOrigin: TGeoVec3; const AModelAxis: TGeoMat3): Integer;
var
  LModel: TCollisionModel;
  LResults: TCollisionTrace;
  LEnd: TGeoVec3;
begin
  AContacts.Clear;
  Result := 0;
  LModel := ModelOf(AModel, 'Translation');
  if not Assigned(LModel) then
    Exit;
  // same as Translation but instead of storing the first collision we store all collisions as contacts
  LEnd := AStart + ADir * ADepth;
  FTranslationRunner.Translate(LResults, AStart, LEnd, ATrm, ATrmAxis, AContentMask, LModel, AModelOrigin,
    AModelAxis, AContacts, AMaxContacts);
  Result := AContacts.Count;
end;

end.
