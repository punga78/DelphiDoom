{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the loading of a level of Speed Haste                  }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Level.SpeedRules;

interface

uses
  doomdata,
  p_udmf,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Racing.Types,
  DelphiDoom.Engine.Wad.Lumps.Intf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   What the loading of a level does only in Speed Haste. A circuit is a level of Doom (the
  ///   rules of Doom do everything else: they are given, not inherited) with two more lumps after
  ///   BLOCKMAP, PATH and MAPDATA: the things of the path (type 512) are not objects of the map,
  ///   and after the level the points of the track are read (SH_LoadPath of the old fork). The
  ///   cars and the race (SH_InitRace, SH_InitLevelCars) are not made yet
  /// </summary>
  TSpeedLevelRules = class(TInterfacedObject, ILevelGameRules, ILevelGeometryRules, ILevelThingRules)
  strict private
    FGame: ILevelGameRules;
    FGeometry: ILevelGeometryRules;
    FThings: ILevelThingRules;
    FLumps: IEngineLumps;
    FLog: ILog;
    FMapLump: Integer;
    FPath: TArray<TRacingPathThing>;
    FStartPositions: Integer;
    function ReadLevelLump(const AName: string): TArray<Byte>;
    procedure ReadTrack;
  public
    /// <summary>
    ///   AGame, AGeometry and AThings are the rules of Doom; ALumps gives the lumps of the level and
    ///   ALog gets what was read of the track. EArgumentNilException when one is nil
    /// </summary>
    constructor Create(const AGame: ILevelGameRules; const AGeometry: ILevelGeometryRules;
      const AThings: ILevelThingRules; const ALumps: IEngineLumps; const ALog: ILog);
    /// <summary>The points of the path of the level that was loaded last, in the order of the track</summary>
    property Path: TArray<TRacingPathThing> read FPath;
    /// <summary>How many places of the starting grid (things of type 241) the level has</summary>
    property StartPositions: Integer read FStartPositions;
    // ILevelGameRules
    procedure InitializeData;
    procedure ShutDownData;
    function TracesSteps: Boolean;
    function MapName(AEpisode, AMap: Integer): string;
    procedure PrintLoading(const ALumpName: string; AEpisode, AMap: Integer);
    procedure ResetStatistics;
    procedure ClearLevelData;
    procedure AfterBlockmap;
    procedure AfterNodes(AMapLump: Integer);
    procedure BeforeThings;
    procedure AfterThings;
    procedure BeforeDeathmatchSpawn;
    procedure SpawnDeathmatchPlayer(APlayer: Integer);
    procedure AfterDeathmatchSpawn;
    procedure AfterSpecials;
    procedure AfterLevel;
    // ILevelGeometryRules
    property Geometry: ILevelGeometryRules read FGeometry implements ILevelGeometryRules;
    // ILevelThingRules
    procedure SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
    procedure AfterMapThingsSpawned;
    procedure AfterThingsLoaded;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Racing.PathReader;

const
  // the lumps of a circuit that Doom does not have, and how far after the name of the map they
  // can be (ML_PATH and ML_MAPDATA of the old fork come after ML_BLOCKMAP)
  THINGS_LUMP = 'THINGS';
  PATH_LUMP = 'PATH';
  LEVEL_LUMP_SPAN = 13;
  // the place of a car on the starting grid (the old _SHTH_STARPOSITION)
  START_POSITION_THING_TYPE = 241;

{ TSpeedLevelRules }

constructor TSpeedLevelRules.Create(const AGame: ILevelGameRules;
  const AGeometry: ILevelGeometryRules; const AThings: ILevelThingRules;
  const ALumps: IEngineLumps; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AGame) then
    raise EArgumentNilException.Create('AGame');
  if not Assigned(AGeometry) then
    raise EArgumentNilException.Create('AGeometry');
  if not Assigned(AThings) then
    raise EArgumentNilException.Create('AThings');
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FGame := AGame;
  FGeometry := AGeometry;
  FThings := AThings;
  FLumps := ALumps;
  FLog := ALog;
  FMapLump := -1;
end;

function TSpeedLevelRules.ReadLevelLump(const AName: string): TArray<Byte>;
var
  LLump: Integer;
begin
  Result := nil;
  if FMapLump < 0 then
    Exit;
  for LLump := FMapLump + 1 to FMapLump + LEVEL_LUMP_SPAN - 1 do
  begin
    if LLump >= FLumps.Count then
      Break;
    if SameText(FLumps.NameOf(LLump), AName) then
    begin
      SetLength(Result, FLumps.LengthOf(LLump));
      if Length(Result) > 0 then
        FLumps.Read(LLump, @Result[0]);
      Exit;
    end;
  end;
end;

procedure TSpeedLevelRules.ReadTrack;
var
  LThings: TArray<Byte>;
  LThing: Pmapthing_t;
  LIndex: Integer;
begin
  LThings := ReadLevelLump(THINGS_LUMP);
  FPath := TRacingPathReader.FromLumps(LThings, ReadLevelLump(PATH_LUMP));
  FStartPositions := 0;
  if Length(LThings) >= SizeOf(mapthing_t) then
  begin
    LThing := @LThings[0];
    for LIndex := 0 to Length(LThings) div SizeOf(mapthing_t) - 1 do
    begin
      if LThing._type = START_POSITION_THING_TYPE then
        Inc(FStartPositions);
      Inc(LThing);
    end;
  end;
  if Length(FPath) = 0 then
    FLog.Warning('TSpeedLevelRules: the level has no path of the race (lump PATH)'#13#10)
  else
    FLog.Info(Format('Speed Haste track: %d points of the path, %d starting positions'#13#10,
      [Length(FPath), FStartPositions]));
end;

procedure TSpeedLevelRules.InitializeData;
begin
  FGame.InitializeData;
end;

procedure TSpeedLevelRules.ShutDownData;
begin
  FGame.ShutDownData;
end;

function TSpeedLevelRules.TracesSteps: Boolean;
begin
  Result := FGame.TracesSteps;
end;

function TSpeedLevelRules.MapName(AEpisode, AMap: Integer): string;
begin
  Result := FGame.MapName(AEpisode, AMap);
end;

procedure TSpeedLevelRules.PrintLoading(const ALumpName: string; AEpisode, AMap: Integer);
begin
  FGame.PrintLoading(ALumpName, AEpisode, AMap);
end;

procedure TSpeedLevelRules.ResetStatistics;
begin
  FGame.ResetStatistics;
end;

procedure TSpeedLevelRules.ClearLevelData;
begin
  FPath := nil;
  FStartPositions := 0;
  FMapLump := -1;
  FGame.ClearLevelData;
end;

procedure TSpeedLevelRules.AfterBlockmap;
begin
  FGame.AfterBlockmap;
end;

procedure TSpeedLevelRules.AfterNodes(AMapLump: Integer);
begin
  FMapLump := AMapLump;
  FGame.AfterNodes(AMapLump);
end;

procedure TSpeedLevelRules.BeforeThings;
begin
  FGame.BeforeThings;
end;

procedure TSpeedLevelRules.AfterThings;
begin
  FGame.AfterThings;
end;

procedure TSpeedLevelRules.BeforeDeathmatchSpawn;
begin
  FGame.BeforeDeathmatchSpawn;
end;

procedure TSpeedLevelRules.SpawnDeathmatchPlayer(APlayer: Integer);
begin
  FGame.SpawnDeathmatchPlayer(APlayer);
end;

procedure TSpeedLevelRules.AfterDeathmatchSpawn;
begin
  FGame.AfterDeathmatchSpawn;
end;

procedure TSpeedLevelRules.AfterSpecials;
begin
  FGame.AfterSpecials;
end;

procedure TSpeedLevelRules.AfterLevel;
begin
  FGame.AfterLevel;
  ReadTrack;
end;

procedure TSpeedLevelRules.SpawnMapThing(AThing: Pmapthing_t; AExtra: Pextrathing_t);
begin
  // a point of the path is not an object of the map: the track reads it from the lumps
  if AThing._type <> RACING_PATH_THING_TYPE then
    FThings.SpawnMapThing(AThing, AExtra);
end;

procedure TSpeedLevelRules.AfterMapThingsSpawned;
begin
  FThings.AfterMapThingsSpawned;
end;

procedure TSpeedLevelRules.AfterThingsLoaded;
begin
  FThings.AfterThingsLoaded;
end;

end.
