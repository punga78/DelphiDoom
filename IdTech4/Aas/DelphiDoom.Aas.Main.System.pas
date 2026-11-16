{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the AAS system                                     }
{                                                                              }
{  Port of be_aas_main.c: setup, loading of a map, the frame, the initialization }
{  that goes on over several frames, and the shutdown. Based on the Quake III   }
{  Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software,    }
{  Inc. This unit is derived from the Quake III Arena source code and is        }
{  therefore available under the GNU General Public License, version 2 or (at   }
{  your option) any later version.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Main.System;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf,
  DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Aas.Main.Intf, DelphiDoom.Aas.Main.StringIndexes, DelphiDoom.Aas.Entity.Table, DelphiDoom.Aas.Reach.Intf;

type
  /// <summary>
  ///   The AAS of the bots for one game: the library variables, the entities and the map that is loaded. The
  ///   classes behind the interfaces are given by the composition root. Nothing is owned except the table and the
  ///   map; the import, the reader, the libvars and the models are not
  /// </summary>
  TAasSystem = class(TInterfacedObject, IAasFrameState)
  strict private
    FImport: IBotImport;
    FLibVars: IBotLibVars;
    FReader: IAasReader;
    FModels: IAasBspModels;
    FBuilder: IAasMapBuilder;
    FDeveloper: Boolean;
    FLoaded: Boolean;
    FInitialized: Boolean;
    FTime: Single;
    FNumFrames: Integer;
    FMaxClients: Integer;
    FMaxEntities: Integer;
    FMapName: AnsiString;
    FFileName: AnsiString;
    FEntities: TAasEntityTable;
    FBspEntities: IAasBspEntities;
    FMap: IAasMap;
    FStrings: TAasStringIndexes;
    FBestLinkArea: TAasBestLinkArea;
    FBestReachable: TFunc<IAasBestReachable>;
    function GetLoaded: Boolean;
    function GetInitialized: Boolean;
    function GetTime: Single;
    function GetNumFrames: Integer;
    function LoadFiles(const AMapName: AnsiString): Integer;
    procedure ContinueInit(const ATime: Single);
  public
    /// <summary>
    ///   The reader loads the files named maps/name.aas; the models give the entity text of the map; the builder
    ///   makes the map of the file. ABestLinkArea is AAS_BestReachableLinkArea (it needs the reachabilities)
    /// </summary>
    constructor Create(const AImport: IBotImport; const ALibVars: IBotLibVars; const AReader: IAasReader;
      const AModels: IAasBspModels; const ABuilder: IAasMapBuilder; const ABestLinkArea: TAasBestLinkArea;
      const ABestReachable: TFunc<IAasBestReachable>; const ADeveloper: Boolean);
    destructor Destroy; override;
    /// <summary>
    ///   AAS_Setup: maxclients and maxentities from the library variables; the entities are made and invalid
    /// </summary>
    function Setup: Integer;
    /// <summary>AAS_Shutdown</summary>
    procedure Shutdown;
    /// <summary>
    ///   AAS_LoadMap: loads the entities of the BSP and the AAS file and starts the initialization (which goes on
    ///   in StartFrame). An empty name only updates the indexes of the strings (0). The error code of the load
    /// </summary>
    function LoadMap(const AMapName: AnsiString): Integer;
    /// <summary>AAS_StartFrame: unlinks the entities that were not updated, invalidates them, goes on with the initialization</summary>
    function StartFrame(const ATime: Single): Integer;
    /// <summary>AAS_ProjectPointOntoVector: the point projected on the line from the start to the end</summary>
    class function ProjectPointOntoVector(const APoint, AStart, AEnd: TVec3): TVec3; static;
    /// <summary>AAS_Loaded</summary>
    property Loaded: Boolean read FLoaded;
    /// <summary>AAS_Initialized</summary>
    property Initialized: Boolean read FInitialized;
    /// <summary>AAS_Time</summary>
    property Time: Single read FTime;
    property MaxClients: Integer read FMaxClients;
    property MaxEntities: Integer read FMaxEntities;
    /// <summary>aasworld.filename: the file that was loaded</summary>
    property FileName: AnsiString read FFileName;
    property Entities: TAasEntityTable read FEntities;
    property Map: IAasMap read FMap;
    property BspEntities: IAasBspEntities read FBspEntities;
    property Strings: TAasStringIndexes read FStrings;
    /// <summary>The functions of be_aas_reach.c for the bots (AAS_BestReachableArea ...) on the map that is loaded; nil before one</summary>
    function BestReachable: IAasBestReachable;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.Types, DelphiDoom.Aas.Printer, DelphiDoom.Aas.VectorMath,
  DelphiDoom.Aas.Links, DelphiDoom.Aas.Bsp.Entities, DelphiDoom.Aas.Entity.Types;

resourcestring
  SShutdown = 'AAS shutdown.'#10;
  SInitialized = 'AAS initialized.'#10;
  SLoaded = 'loaded %s'#10;
  SWritten = '%s written succesfully'#10;
  SNotWritten = 'couldn''t write %s'#10;

const
  REACHABILITY_VAR = 'forcewrite';

{ TAasSystem }

constructor TAasSystem.Create(const AImport: IBotImport; const ALibVars: IBotLibVars; const AReader: IAasReader;
  const AModels: IAasBspModels; const ABuilder: IAasMapBuilder; const ABestLinkArea: TAasBestLinkArea;
  const ABestReachable: TFunc<IAasBestReachable>; const ADeveloper: Boolean);
begin
  inherited Create;
  FImport := AImport;
  FLibVars := ALibVars;
  FReader := AReader;
  FModels := AModels;
  FBuilder := ABuilder;
  FBestLinkArea := ABestLinkArea;
  FBestReachable := ABestReachable;
  FDeveloper := ADeveloper;
  FStrings := TAasStringIndexes.Create(AImport);
end;

destructor TAasSystem.Destroy;
begin
  FEntities.Free;
  FStrings.Free;
  inherited Destroy;
end;

function TAasSystem.BestReachable: IAasBestReachable;
begin
  if Assigned(FBestReachable) then
    Result := FBestReachable()
  else
    Result := nil;
end;

function TAasSystem.GetLoaded: Boolean;
begin
  Result := FLoaded;
end;

function TAasSystem.GetInitialized: Boolean;
begin
  Result := FInitialized;
end;

function TAasSystem.GetTime: Single;
begin
  Result := FTime;
end;

function TAasSystem.GetNumFrames: Integer;
begin
  Result := FNumFrames;
end;

function TAasSystem.Setup: Integer;
begin
  FMaxClients := Trunc(FLibVars.GetValueOrCreate('maxclients', '128'));
  FMaxEntities := Trunc(FLibVars.GetValueOrCreate('maxentities', '1024'));
  // saveroutingcache is only created: the route cache file is not written
  FLibVars.GetValueOrCreate('saveroutingcache', '0');
  FEntities.Free;
  FEntities := TAasEntityTable.Create(FImport, Self, FModels, FMaxEntities, FBestLinkArea);
  FNumFrames := 0;
  Result := BLERR_NOERROR;
end;

procedure TAasSystem.Shutdown;
begin
  if Assigned(FMap) then
    FMap.Steps.FreeRouting;
  FMap := nil;
  FBspEntities := nil;
  FEntities.Free;
  FEntities := nil;
  FLoaded := False;
  FInitialized := False;
  FTime := 0;
  FNumFrames := 0;
  FMapName := '';
  FFileName := '';
  TAasPrinter.Print(FImport, PRT_MESSAGE, SShutdown);
end;

function TAasSystem.LoadFiles(const AMapName: AnsiString): Integer;
var
  LFile: IAasFile;
  LName: AnsiString;
begin
  FMapName := AMapName;
  // the entity links are reset before the files are loaded
  if Assigned(FEntities) then
    FEntities.ResetEntityLinks;
  // the entities of the BSP
  FBspEntities := TAasBspEntities.Create(FImport, FModels.EntityData);
  LName := 'maps/' + AMapName + '.aas';
  Result := FReader.Load(LName, LFile);
  if Result <> BLERR_NOERROR then
    Exit;
  FLoaded := True;
  FMap := FBuilder.Build(LFile, Trunc(FLibVars.GetValueOrCreate('max_aaslinks', '6144')), FBspEntities);
  TAasPrinter.Print(FImport, PRT_MESSAGE, Format(SLoaded, [string(LName)]));
  FFileName := LName;
  Result := BLERR_NOERROR;
end;

function TAasSystem.LoadMap(const AMapName: AnsiString): Integer;
begin
  Result := 0;
  // no name: only the string indexes are updated (by the caller)
  if AMapName = '' then
    Exit;
  FInitialized := False;
  // the caches of the old map are freed before the map changes: they need its numbers
  if Assigned(FMap) then
    FMap.Steps.FreeRouting;
  FMap := nil;
  Result := LoadFiles(AMapName);
  if Result <> BLERR_NOERROR then
  begin
    FLoaded := False;
    FMap := nil;
    Exit;
  end;
  FMap.Steps.InitSettings;
  if Assigned(FEntities) then
    FEntities.Links := FMap.Links;
  FMap.Steps.InitReachability;
  FMap.Steps.InitAlternativeRouting;
  Result := 0;
end;

procedure TAasSystem.ContinueInit(const ATime: Single);
begin
  // no AAS file loaded, or already initialized
  if not FLoaded or FInitialized then
    Exit;
  // the reachabilities of some areas per frame: not finished
  if FMap.Steps.ContinueInitReachability(ATime) then
    Exit;
  FMap.Steps.InitClustering;
  // the reachabilities were calculated, or the library variable forces it: write the file
  if FMap.Steps.SaveFile or (Trunc(FLibVars.GetValue(REACHABILITY_VAR)) <> 0) then
  begin
    if Trunc(FLibVars.GetValueOrCreate('aasoptimize', '0')) <> 0 then
      FMap.Steps.Optimize;
    // AAS_WriteAASFile is not ported: the file is never written
    TAasPrinter.Print(FImport, PRT_ERROR, Format(SNotWritten, [string(FFileName)]));
  end;
  FMap.Steps.InitRouting;
  // at this point the AAS is initialized
  FInitialized := True;
  TAasPrinter.Print(FImport, PRT_MESSAGE, SInitialized);
end;

function TAasSystem.StartFrame(const ATime: Single): Integer;
begin
  FTime := ATime;
  if Assigned(FEntities) then
  begin
    // unlink the entities that were not updated last frame, then invalidate them all
    FEntities.UnlinkInvalidEntities;
    FEntities.InvalidateEntities;
  end;
  ContinueInit(ATime);
  Inc(FNumFrames);
  Result := BLERR_NOERROR;
end;

class function TAasSystem.ProjectPointOntoVector(const APoint, AStart, AEnd: TVec3): TVec3;
var
  LPointVector, LVector: TVec3;
  LDot: Single;
  LIndex: Integer;
begin
  for LIndex := 0 to 2 do
  begin
    LPointVector[LIndex] := APoint[LIndex] - AStart[LIndex];
    LVector[LIndex] := AEnd[LIndex] - AStart[LIndex];
  end;
  TAasVectorMath.Normalize(LVector);
  // project onto the directional vector of the segment
  LDot := TAasVectorMath.Dot(LPointVector, LVector);
  for LIndex := 0 to 2 do
    Result[LIndex] := AStart[LIndex] + LVector[LIndex] * LDot;
end;

end.
