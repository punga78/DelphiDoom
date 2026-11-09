{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the contracts                                  }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.Intf;

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.Racing.Types;

type
  /// <summary>The state of the race that the cars read (the old race and the clocks of the game)</summary>
  IRacingRaceState = interface
    ['{4C1E7A52-91B3-4D68-8F20-5A6B3D9E1C07}']
    function GetStatus: TRacingStatus;
    function GetCarType: TRacingCarType;
    function GetGameType: TRacingGameType;
    function GetTransmissionType: Integer;
    function GetNumLaps: Integer;
    function GetRaceTime: Integer;
    function GetLevelTime: Integer;
    function GetSkill: TRacingSkill;
    function GetEpisode: Integer;
    function GetMap: Integer;
    /// <summary>Waiting at the start, racing, or the player has finished</summary>
    property Status: TRacingStatus read GetStatus;
    /// <summary>The family of cars of the race</summary>
    property CarType: TRacingCarType read GetCarType;
    property GameType: TRacingGameType read GetGameType;
    /// <summary>RACING_TRANSMISSION_AUTOMATIC or RACING_TRANSMISSION_MANUAL</summary>
    property TransmissionType: Integer read GetTransmissionType;
    property NumLaps: Integer read GetNumLaps;
    /// <summary>The tics since the start of the race</summary>
    property RaceTime: Integer read GetRaceTime;
    /// <summary>The tics since the start of the level</summary>
    property LevelTime: Integer read GetLevelTime;
    property Skill: TRacingSkill read GetSkill;
    property Episode: Integer read GetEpisode;
    property Map: Integer read GetMap;
  end;

  /// <summary>The state of the race with the writing side: what the game does when a race starts and at every tic</summary>
  IRacingRaceSettings = interface(IRacingRaceState)
    ['{91D40B7E-3C58-4F12-A6E9-D07B5C2A8E31}']
    procedure SetStatus(AValue: TRacingStatus);
    procedure SetCarType(AValue: TRacingCarType);
    procedure SetGameType(AValue: TRacingGameType);
    procedure SetTransmissionType(AValue: Integer);
    procedure SetNumLaps(AValue: Integer);
    procedure SetRaceTime(AValue: Integer);
    procedure SetLevelTime(AValue: Integer);
    procedure SetSkill(AValue: TRacingSkill);
    procedure SetEpisode(AValue: Integer);
    procedure SetMap(AValue: Integer);
  end;

  /// <summary>The geometry of the world, which the game answers (angles from the view, and the distance from the view)</summary>
  IRacingGeometry = interface
    ['{7D3A9F14-2E85-4B60-A1C7-93F0B52E6D48}']
    /// <summary>The angle of the direction from (AX1, AY1) to (AX2, AY2) (the old R_PointToAngle2)</summary>
    function PointToAngle(AX1, AY1, AX2, AY2: TFixed): TAngle;
    /// <summary>The approximate distance of a point from the view (the old P_AproxDistance of the difference)</summary>
    function ApproximateDistanceFromView(AX, AY: TFixed): TFixed;
  end;

  /// <summary>What a car makes appear and hear in the world: the game creates the objects and plays the sounds</summary>
  IRacingEffects = interface
    ['{E5B28C71-0A4D-47F3-9B16-2C8D7E3F1A95}']
    /// <summary>A particle that leaves a wheel; the game decides which of the two objects of the kind it creates</summary>
    procedure SpawnParticle(AKind: TRacingParticleKind; AX, AY, AZ, AMomentumX, AMomentumY: TFixed);
    /// <summary>The sound of the engine for a fraction (0..9) of the rpm; gives how many tics the sound lasts</summary>
    function PlayEngineSound(AFormula: Boolean; AFraction: Integer): Integer;
    /// <summary>The sound of the brakes from a point; gives how many tics it lasts</summary>
    function PlayBrakeSound(AX, AY, AZ: TFixed): Integer;
  end;

  /// <summary>What happens in the game when the laps of a player change</summary>
  IRacingPlayerEvents = interface
    ['{19F6D3A8-5C27-4E90-B8A4-6D1E0F7B3C52}']
    /// <summary>A lap was completed: the game stores the result and asks if it is a record</summary>
    procedure LapCompleted(const AScore: TRacingScore);
    /// <summary>The result of the player after a lap or at the end of the race</summary>
    procedure ScoreChanged(const AScore: TRacingScore);
  end;

  /// <summary>The ground of the track, from the map of the ground (the old SH_GroundTypeAtXY and SH_SlipperFactorAtXY)</summary>
  IRacingGround = interface
    ['{A3C84E19-7B52-4D06-9E3F-58D1A2C6B704}']
    /// <summary>The map of the ground: 4096 x 4096 bytes. The memory belongs to the caller (the lump cache). A map of another size is the same as no map: always asphalt</summary>
    procedure SetMap(AMap: PByte; ASize: Integer);
    function GroundTypeAt(AX, AY: TFixed): TRacingGroundType;
    /// <summary>How well the tires hold the ground at a point, 0..255 (a random number of the range of the ground)</summary>
    function SlipperFactorAt(AX, AY: TFixed): Byte;
  end;

  /// <summary>The path that the cars of the computer follow, and the laps (the old speed_path)</summary>
  IRacingTrack = interface
    ['{5E91B7D3-C406-4A28-8F5D-0B3A7C2E9164}']
    /// <summary>Takes the points of the track in the order of the map and orders them as a lap. False if there are none</summary>
    function Load(const APoints: array of TRacingPathPoint): Boolean;
    function PathCount: Integer;
    /// <summary>A point of the path (the record belongs to the track and stays valid until the next Load)</summary>
    function GetPath(AIndex: Integer): PRacingPath;
    /// <summary>The index of the point of the path that a car at (AX, AY) has to go to (the old SH_GetNextPath)</summary>
    function GetNextPath(AX, AY: TFixed): Integer;
    /// <summary>Counts the laps and the times of a car (the old SH_NotifyPath)</summary>
    procedure Notify(var ACar: TRacingCarState);
    /// <summary>The times of the laps of a car (the old SH_GetTimeLaps)</summary>
    procedure GetLapTimes(const ACar: TRacingCarState; out ATimes: TRacingLapTimes);
    /// <summary>
    ///   Puts the cars in order and gives the position (from 1) of each (the old
    ///   SH_CalculatePositions); the items are in the order of the race
    /// </summary>
    function CalculatePositions(const ACars: array of TRacingPositionInput): TArray<TRacingPositionItem>;
  end;

  /// <summary>What a driver does in a tic (the old SH_BuildDrivingCmd*)</summary>
  IRacingDriver = interface
    ['{C8D2F061-3A97-4E5B-B142-7F09E6A3D815}']
    /// <summary>The command of the computer for a car</summary>
    procedure BuildCommand(var ACar: TRacingCarState; out ACommand: TRacingDrivingCommand);
  end;

  /// <summary>The driver that a person controls</summary>
  IRacingPlayerDriver = interface
    ['{3F6A8B24-D170-4C95-A7E3-1B58C9D02E46}']
    procedure BuildCommand(var ACar: TRacingCarState; var APlayer: TRacingPlayerState;
      const AInput: TRacingPlayerInput; out ACommand: TRacingDrivingCommand);
  end;

  /// <summary>The motion of a car (the old SH_ExecuteDrivingCmd)</summary>
  IRacingPhysics = interface
    ['{B07E1D95-6C43-4A82-9F18-E4D3A5C72B60}']
    /// <summary>Moves the car for a tic: gears, engine, steering, drift and the momentum that the game uses to move it</summary>
    procedure Execute(var ACar: TRacingCarState; const ACommand: TRacingDrivingCommand);
  end;

  /// <summary>The sounds of the engine and of the brakes of a car</summary>
  IRacingCarSounds = interface
    ['{62A4C9F7-1D83-4B50-8E26-F9B0D7A31C48}']
    /// <summary>The sound of the engine; the countdown belongs to the object that plays it (the car, or the sound object of the player)</summary>
    procedure EngineSound(const ACar: TRacingCarState; var ASoundCountdown: Integer);
    procedure BrakeSound(var ACar: TRacingCarState);
  end;

  /// <summary>The particles that a car leaves (the old SH_SpawnParticleCheck)</summary>
  IRacingParticles = interface
    ['{D91B35E8-4F60-4A72-B3C9-0A8E6D21F574}']
    procedure Check(var ACar: TRacingCarState; AActualSpeed, AEngineSpeed: TFixed);
  end;

  /// <summary>The choice of the car of each starting position of the grid (the old SH_InitLevelCars)</summary>
  IRacingGridAssigner = interface
    ['{08C5A7D2-E391-4F64-A0B8-72D6F1E9C353}']
    /// <summary>
    ///   The car of each of the starting positions: a random car of the family of the race that
    ///   no player has. With too many starting positions it raises ERacingException
    /// </summary>
    function Assign(AStartCount: Integer; ARaceCarType: TRacingCarType;
      const APlayerCarIds: array of Integer): TArray<Integer>;
  end;

  /// <summary>The tables of the best times (the old speed_score)</summary>
  IRacingScoreTable = interface
    ['{F4A71E36-8B05-4D92-96C1-3E5B0D8A7F29}']
    function GetRecords: PRacingRecordTable;
    procedure Clear;
    /// <summary>Puts the result of a race in the tables: the laps and the whole race (the old SH_UpdateScoreTable)</summary>
    procedure Update(const AScore: TRacingScore; const ADriverName: string; ASkill: TRacingSkill);
    /// <summary>True if a lap time would enter the table of the best laps (the old SH_CheckLapRecord)</summary>
    function CheckLapRecord(AEpisode, AMap: Integer; ACarType: TRacingCarType; ATime: Integer): Boolean;
    /// <summary>Reads the file of the records; False (and the tables are empty, as the old code left them) if its size is not the one of the table</summary>
    function LoadFromBytes(const ABytes: TBytes): Boolean;
    /// <summary>The file of the records</summary>
    function SaveToBytes: TBytes;
    /// <summary>The tables themselves (they belong to the object)</summary>
    property Records: PRacingRecordTable read GetRecords;
  end;

implementation

end.
