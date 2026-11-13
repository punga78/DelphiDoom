{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the model manager: contracts                }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\ModelManager.h  }
{  and ModelManager.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax    }
{  Media company. This unit is derived from the Doom 3 GPL source code and is  }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Manager.Intf;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Static.Intf;

type
  /// <summary>The kind of a model that the manager keeps</summary>
  TRenderModelKind = (
    /// <summary>The default cube (also the model that stands for a missing file of an unknown type)</summary>
    rmkDefault,
    /// <summary>"_BEAM": drawn by the renderer, no data here</summary>
    rmkBeam,
    /// <summary>"_SPRITE": drawn by the renderer, no data here</summary>
    rmkSprite,
    /// <summary>ASE, LWO, MA, MD3: a list of surfaces (idRenderModelStatic)</summary>
    rmkStatic,
    /// <summary>md5mesh: joints, meshes and weights (idRenderModelMD5)</summary>
    rmkMd5);

  /// <summary>What a loader gives for a file</summary>
  TRenderModelData = record
    /// <summary>The surfaces, nil for an md5mesh</summary>
    Static: IStaticModel;
    /// <summary>The md5 model, nil for a static model</summary>
    Md5: IMd5Model;
    /// <summary>The time stamp of the file the data was read from</summary>
    TimeStamp: Int64;
    /// <summary>The file could not be loaded: <c>Static</c> is the default cube (MakeDefaultModel)</summary>
    Defaulted: Boolean;
  end;

  /// <summary>Reads the file of a model: one loader per kind of file, chosen by the extension</summary>
  IRenderModelLoader = interface
    ['{B2D7F450-1E83-4A69-9C14-6A0E58D3B7F1}']
    function GetKind: TRenderModelKind;
    /// <summary>
    ///   Loads the file. A file that is missing or damaged is not an exception: the answer is
    ///   the default cube (<c>Defaulted</c> True) and a warning goes to the log, as the original does.
    /// </summary>
    function Load(const AName: AnsiString): TRenderModelData;
    property Kind: TRenderModelKind read GetKind;
  end;

  /// <summary>The loaders by the extension of the file (the dispatch of GetModel by extension)</summary>
  IRenderModelLoaderTable = interface
    ['{0E5D2B97-6A41-4F83-B9C6-D3187F52A0E4}']
    /// <summary>Registers the loader of an extension without the dot (ignoring case); a second one replaces the first</summary>
    procedure Register(const AExtension: string; const ALoader: IRenderModelLoader);
    /// <summary>The loader of an extension (with or without the dot), nil if none</summary>
    function Find(const AExtension: string): IRenderModelLoader;
  end;

  /// <summary>A model in the manager (idRenderModel as the manager sees it)</summary>
  IRenderModel = interface
    ['{4C9E1A83-7D50-4B26-A3F8-E15B02D96C74}']
    function GetName: AnsiString;
    function GetKind: TRenderModelKind;
    function GetStatic: IStaticModel;
    function GetMd5: IMd5Model;
    function GetIsDefaultModel: Boolean;
    function GetIsLoaded: Boolean;
    function GetIsReloadable: Boolean;
    function GetTimeStamp: Int64;
    function GetLevelLoadReferenced: Boolean;
    procedure SetLevelLoadReferenced(const AValue: Boolean);
    property Name: AnsiString read GetName;
    property Kind: TRenderModelKind read GetKind;
    /// <summary>The surfaces of a static model or of the default cube, nil otherwise or when purged</summary>
    property Static: IStaticModel read GetStatic;
    /// <summary>The md5 model, nil otherwise or when purged</summary>
    property Md5: IMd5Model read GetMd5;
    /// <summary>IsDefaultModel: the file could not be loaded or this is the default model</summary>
    property IsDefaultModel: Boolean read GetIsDefaultModel;
    /// <summary>IsLoaded: not purged</summary>
    property IsLoaded: Boolean read GetIsLoaded;
    /// <summary>The model comes from a file that can be read again</summary>
    property IsReloadable: Boolean read GetIsReloadable;
    property TimeStamp: Int64 read GetTimeStamp;
    /// <summary>IsLevelLoadReferenced: the level that is loading uses the model</summary>
    property LevelLoadReferenced: Boolean read GetLevelLoadReferenced write SetLevelLoadReferenced;
    /// <summary>LoadModel: reads the file again (a purged model comes back)</summary>
    procedure LoadModel;
    /// <summary>PurgeModel: forgets the data, the name stays</summary>
    procedure PurgeModel;
  end;

  /// <summary>What a level load did to the models (EndLevelLoad)</summary>
  TLevelLoadCounts = record
    Purged: Integer;
    Kept: Integer;
    Loaded: Integer;
  end;

  /// <summary>The models of the game by name (idRenderModelManager) without the renderer</summary>
  IRenderModelManager = interface
    ['{8F3A6D12-95C0-4E7B-B2D1-0A47C6E83F59}']
    /// <summary>
    ///   Init: the default, beam and sprite models are the first three of the list and are always
    ///   referenced by the level
    /// </summary>
    procedure Init;
    /// <summary>Shutdown: forgets every model</summary>
    procedure Shutdown;
    /// <summary>
    ///   FindModel: the model of that name, loaded if it was not; a name that cannot be loaded
    ///   gives the model that stands for it (a default cube). An empty name is nil.
    /// </summary>
    function FindModel(const AName: AnsiString): IRenderModel;
    /// <summary>CheckModel: as FindModel but nil if the model would be a default one</summary>
    function CheckModel(const AName: AnsiString): IRenderModel;
    function DefaultModel: IRenderModel;
    /// <summary>AddModel: puts a model of the caller in the list (a second one with the same name is searched after the first)</summary>
    procedure AddModel(const AModel: IRenderModel);
    /// <summary>RemoveModel: takes a model out of the list</summary>
    procedure RemoveModel(const AModel: IRenderModel);
    /// <summary>
    ///   FreeModel: the model goes out of the list; the default, beam and sprite models cannot be
    ///   freed (EModelsException)
    /// </summary>
    procedure FreeModel(const AModel: IRenderModel);
    /// <summary>
    ///   ReloadModels: the reloadable models are read again, all of them or those whose file is
    ///   newer than the data (the default, beam and sprite models stay)
    /// </summary>
    procedure ReloadModels(const AForceAll: Boolean);
    /// <summary>BeginLevelLoad: nothing is referenced by the new level; AAll purges every reloadable model (com_purgeAll)</summary>
    procedure BeginLevelLoad(const APurgeAll: Boolean);
    /// <summary>EndLevelLoad: the models that the level did not touch are purged, the ones it did and are purged are loaded</summary>
    function EndLevelLoad: TLevelLoadCounts;
    function NumModels: Integer;
    function GetModelAt(const AIndex: Integer): IRenderModel;
    function InsideLevelLoad: Boolean;
  end;

implementation

end.
