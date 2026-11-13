{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the model manager (idRenderModelManager)    }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\ModelManager.cpp}
{  (idRenderModelManagerLocal). Copyright (C) 1999-2011 id Software LLC, a     }
{  ZeniMax Media company. This unit is derived from the Doom 3 GPL source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Manager.Manager;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Models.Source.Intf,
  DelphiDoom.Models.Manager.Intf;

type
  /// <summary>
  ///   The list of the models by name: it finds a model (loading it by the loader of its
  ///   extension), keeps the default, beam and sprite models, reloads what changed and purges
  ///   what a level did not use. No renderer: no vertex caches, entity definitions or world.
  ///   Not ported: the console commands (listModels, printModel, touchModel), the precache
  ///   commands and the memory report. Replaces the global <c>renderModelManager</c>: whoever
  ///   needs it receives the interface.
  /// </summary>
  TRenderModelManager = class(TInterfacedObject, IRenderModelManager)
  strict private
    FSource: IModelFileSource;
    FLoaders: IRenderModelLoaderTable;
    FLog: IIdLibLog;
    FModels: TList<IRenderModel>;
    FIndex: TDictionary<string, IRenderModel>;
    FDefaultModel: IRenderModel;
    FBeamModel: IRenderModel;
    FSpriteModel: IRenderModel;
    FInsideLevelLoad: Boolean;
    function GetModel(const AName: AnsiString; const ACreateIfNotFound: Boolean): IRenderModel;
    procedure RebuildIndex;
    class function ExtensionOf(const AName: string): string; static;
  public
    /// <summary>
    ///   The source gives the time stamps for ReloadModels; the loaders know the extensions.
    ///   The log is optional.
    /// </summary>
    constructor Create(const ASource: IModelFileSource; const ALoaders: IRenderModelLoaderTable;
      const ALog: IIdLibLog);
    destructor Destroy; override;
    procedure Init;
    procedure Shutdown;
    function FindModel(const AName: AnsiString): IRenderModel;
    function CheckModel(const AName: AnsiString): IRenderModel;
    function DefaultModel: IRenderModel;
    procedure AddModel(const AModel: IRenderModel);
    procedure RemoveModel(const AModel: IRenderModel);
    procedure FreeModel(const AModel: IRenderModel);
    procedure ReloadModels(const AForceAll: Boolean);
    procedure BeginLevelLoad(const APurgeAll: Boolean);
    function EndLevelLoad: TLevelLoadCounts;
    function NumModels: Integer;
    function GetModelAt(const AIndex: Integer): IRenderModel;
    function InsideLevelLoad: Boolean;
  end;

implementation

uses
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Static.DefaultModel,
  DelphiDoom.Models.Manager.Model;

resourcestring
  SModelManagerFreeDefault = 'idRenderModelManager::FreeModel: can''t free the default model';
  SModelManagerFreeBeam = 'idRenderModelManager::FreeModel: can''t free the beam model';
  SModelManagerFreeSprite = 'idRenderModelManager::FreeModel: can''t free the sprite model';

const
  DEFAULT_MODEL_NAME = '_DEFAULT';
  BEAM_MODEL_NAME = '_BEAM';
  SPRITE_MODEL_NAME = '_SPRITE';

{ TRenderModelManager }

constructor TRenderModelManager.Create(const ASource: IModelFileSource; const ALoaders: IRenderModelLoaderTable;
  const ALog: IIdLibLog);
begin
  inherited Create;
  FSource := ASource;
  FLoaders := ALoaders;
  FLog := ALog;
  FModels := TList<IRenderModel>.Create;
  FIndex := TDictionary<string, IRenderModel>.Create;
end;

destructor TRenderModelManager.Destroy;
begin
  FIndex.Free;
  FModels.Free;
  inherited Destroy;
end;

class function TRenderModelManager.ExtensionOf(const AName: string): string;
var
  LDot: Integer;
begin
  LDot := LastDelimiter('.', AName);
  if LDot = 0 then
    Result := ''
  else
    Result := Copy(AName, LDot + 1, MaxInt);
end;

procedure TRenderModelManager.Init;
begin
  FInsideLevelLoad := False;
  // create a default model
  FDefaultModel := TRenderModel.CreateFixed(DEFAULT_MODEL_NAME, rmkDefault,
    TStaticDefaultModel.Build(DEFAULT_MODEL_NAME), True);
  FDefaultModel.LevelLoadReferenced := True;
  AddModel(FDefaultModel);
  // create the beam model
  FBeamModel := TRenderModel.CreateFixed(BEAM_MODEL_NAME, rmkBeam, TStaticDefaultModel.BuildEmpty(BEAM_MODEL_NAME), False);
  FBeamModel.LevelLoadReferenced := True;
  AddModel(FBeamModel);
  FSpriteModel := TRenderModel.CreateFixed(SPRITE_MODEL_NAME, rmkSprite,
    TStaticDefaultModel.BuildEmpty(SPRITE_MODEL_NAME), False);
  FSpriteModel.LevelLoadReferenced := True;
  AddModel(FSpriteModel);
end;

procedure TRenderModelManager.Shutdown;
begin
  FModels.Clear;
  FIndex.Clear;
  FDefaultModel := nil;
  FBeamModel := nil;
  FSpriteModel := nil;
end;

procedure TRenderModelManager.RebuildIndex;
var
  LModel: IRenderModel;
begin
  FIndex.Clear;
  // the newest model of a name is found first (the hash chain starts with the last one added)
  for LModel in FModels do
    FIndex.AddOrSetValue(LowerCase(string(LModel.Name)), LModel);
end;

function TRenderModelManager.GetModel(const AName: AnsiString; const ACreateIfNotFound: Boolean): IRenderModel;
var
  LCanonical, LExtension: string;
  LLoader: IRenderModelLoader;
begin
  if AName = '' then
    Exit(nil);
  LCanonical := LowerCase(string(AName));
  // see if it is already present
  if FIndex.TryGetValue(LCanonical, Result) then
  begin
    if not Result.IsLoaded then
      // reload it if it was purged
      Result.LoadModel;
    // else if inside a level load and not referenced the original touches the materials: no materials here
    Result.LevelLoadReferenced := True;
    Exit;
  end;

  // see if we can load it: which loader depends on the extension
  LExtension := ExtensionOf(LCanonical);
  LLoader := FLoaders.Find(LExtension);
  if LLoader = nil then
  begin
    if (LExtension <> '') and Assigned(FLog) then
      FLog.Warning(Format('unknown model type ''%s''', [LCanonical]));
    if not ACreateIfNotFound then
      Exit(nil);
    Result := TRenderModel.CreateFixed(AName, rmkStatic, TStaticDefaultModel.Build(string(AName)), True);
  end
  else
    Result := TRenderModel.Create(AName, LLoader);
  Result.LevelLoadReferenced := True;
  if (not ACreateIfNotFound) and Result.IsDefaultModel then
    Exit(nil);
  AddModel(Result);
end;

function TRenderModelManager.FindModel(const AName: AnsiString): IRenderModel;
begin
  Result := GetModel(AName, True);
end;

function TRenderModelManager.CheckModel(const AName: AnsiString): IRenderModel;
begin
  Result := GetModel(AName, False);
end;

function TRenderModelManager.DefaultModel: IRenderModel;
begin
  Result := FDefaultModel;
end;

procedure TRenderModelManager.AddModel(const AModel: IRenderModel);
begin
  FModels.Add(AModel);
  FIndex.AddOrSetValue(LowerCase(string(AModel.Name)), AModel);
end;

procedure TRenderModelManager.RemoveModel(const AModel: IRenderModel);
var
  LIndex: Integer;
begin
  LIndex := FModels.IndexOf(AModel);
  if LIndex < 0 then
    Exit;
  FModels.Delete(LIndex);
  RebuildIndex;
end;

procedure TRenderModelManager.FreeModel(const AModel: IRenderModel);
begin
  if AModel = nil then
    Exit;
  if AModel = FDefaultModel then
    raise EModelsException.Create(SModelManagerFreeDefault);
  if AModel = FBeamModel then
    raise EModelsException.Create(SModelManagerFreeBeam);
  if AModel = FSpriteModel then
    raise EModelsException.Create(SModelManagerFreeSprite);
  RemoveModel(AModel);
end;

procedure TRenderModelManager.ReloadModels(const AForceAll: Boolean);
var
  LIndex: Integer;
  LModel: IRenderModel;
  LData: AnsiString;
  LTimeStamp: Int64;
begin
  // skip the default model at index 0
  for LIndex := 1 to FModels.Count - 1 do
  begin
    LModel := FModels[LIndex];
    if not LModel.IsReloadable then
      Continue;
    if not AForceAll then
    begin
      // check timestamp
      if not FSource.ReadFile(LModel.Name, LData, LTimeStamp) then
        Continue;
      if LTimeStamp <= LModel.TimeStamp then
        Continue;
    end;
    LModel.LoadModel;
  end;
end;

procedure TRenderModelManager.BeginLevelLoad(const APurgeAll: Boolean);
var
  LModel: IRenderModel;
begin
  FInsideLevelLoad := True;
  for LModel in FModels do
  begin
    if APurgeAll and LModel.IsReloadable then
      LModel.PurgeModel;
    LModel.LevelLoadReferenced := False;
  end;
end;

function TRenderModelManager.EndLevelLoad: TLevelLoadCounts;
var
  LModel: IRenderModel;
begin
  FInsideLevelLoad := False;
  Result := Default(TLevelLoadCounts);
  // purge any models not touched
  for LModel in FModels do
    if (not LModel.LevelLoadReferenced) and LModel.IsLoaded and LModel.IsReloadable then
    begin
      Inc(Result.Purged);
      LModel.PurgeModel;
    end
    else
      Inc(Result.Kept);
  // load any new ones
  for LModel in FModels do
    if LModel.LevelLoadReferenced and (not LModel.IsLoaded) and LModel.IsReloadable then
    begin
      Inc(Result.Loaded);
      LModel.LoadModel;
    end;
end;

function TRenderModelManager.NumModels: Integer;
begin
  Result := FModels.Count;
end;

function TRenderModelManager.GetModelAt(const AIndex: Integer): IRenderModel;
begin
  Result := FModels[AIndex];
end;

function TRenderModelManager.InsideLevelLoad: Boolean;
begin
  Result := FInsideLevelLoad;
end;

end.
