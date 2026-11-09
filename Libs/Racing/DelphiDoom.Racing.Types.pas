{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the types and constants                        }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the data types of speed_cars, speed_race, speed_path and            }
{  speed_score of the GLSpeed fork of DelphiDoom                               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.Types;

// The speeds, the angles and the distances are 16.16 fixed point and wrap as in the old code
{$Q-}
{$R-}
{$SCOPEDENUMS ON}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types;

const
  /// <summary>A speed of 1 km/h in fixed point units (the old KMH_TO_FIXED)</summary>
  RACING_KMH_TO_FIXED = 4370;
  /// <summary>The highest rpm of an engine (the old MAX_RPM)</summary>
  RACING_MAX_RPM = 13000;
  /// <summary>How much the rpm fall in one tic when the engine does not push (about a second from the top to zero)</summary>
  RACING_RPM_FADE = 370;
  /// <summary>The most cars of a race, the player included (the old MAX_RACE_CARS)</summary>
  RACING_MAX_CARS = 20;
  RACING_FORMULA_CAR_COUNT = 20;
  RACING_STOCK_CAR_COUNT = 20;
  /// <summary>The cars of the game (the old NUMCARINFO)</summary>
  RACING_CAR_COUNT = RACING_FORMULA_CAR_COUNT + RACING_STOCK_CAR_COUNT;
  RACING_MIN_LAPS = 2;
  RACING_MAX_LAPS = 10;
  /// <summary>The forward gears (the old NUM_CAR_GEARS); gear -1 is the reverse and 0 is neutral</summary>
  RACING_GEAR_COUNT = 6;
  /// <summary>The speed of a car is cut in so many steps to look up the push of a gear</summary>
  RACING_GEAR_FACTOR_COUNT = 16;
  RACING_GEAR_FACTOR_MULTIPLIER = 1024;
  RACING_TICKS_PER_SECOND = 35;
  RACING_AUTO_GEAR_CHANGE_TICS = RACING_TICKS_PER_SECOND div 8;
  RACING_AUTO_NEXT_GEAR_CHANGE_TICS = RACING_TICKS_PER_SECOND div 8;
  RACING_MANUAL_GEAR_CHANGE_TICS = RACING_TICKS_PER_SECOND div 16;
  RACING_MANUAL_NEXT_GEAR_CHANGE_TICS = RACING_TICKS_PER_SECOND div 16;
  RACING_MAX_SLIP_FACTOR = 255;
  RACING_PILOT_NAME_SIZE = 16;
  /// <summary>The lines of the ground map and its columns</summary>
  RACING_GROUND_SIZE = 4096;
  /// <summary>The size in bytes of a valid ground map</summary>
  RACING_GROUND_BYTES = RACING_GROUND_SIZE * RACING_GROUND_SIZE;
  /// <summary>The scale between map units and the ground map (the old SPEED_LEVEL_SCALE)</summary>
  RACING_LEVEL_SCALE = 2;
  RACING_TRANSMISSION_AUTOMATIC = 0;
  RACING_TRANSMISSION_MANUAL = 1;
  /// <summary>The bits of buttons2 of the player command (the old BT2_GEARUP and BT2_GEARDOWN)</summary>
  RACING_BUTTON_GEAR_UP = 1;
  RACING_BUTTON_GEAR_DOWN = 2;
  /// <summary>The records of the table of the best times of a track, for every car type</summary>
  RACING_SCORES_PER_TABLE = 10;
  RACING_MAX_EPISODES = 4;
  RACING_MAX_MAPS = 9;

type
  /// <summary>Raised when the racing code gets data that cannot work (too many cars, a path that does not exist)</summary>
  ERacingException = class(Exception);

  /// <summary>The families of cars (the old cartype_t)</summary>
  TRacingCarType = (Formula, Stock, Any);

  /// <summary>The ground under a wheel (the old groundtype_t)</summary>
  TRacingGroundType = (Asphalt, Grass, Dirt, Sand, Unknown);

  /// <summary>What the race is doing (the old racestatus_t)</summary>
  TRacingStatus = (Waiting, Racing, PlayerFinished);

  /// <summary>The kinds of race (the old gametype_t)</summary>
  TRacingGameType = (Championship, SingleRace, Practice);

  /// <summary>The five levels of difficulty (the old skill_t)</summary>
  TRacingSkill = (Baby, Easy, Medium, Hard, Nightmare);

  /// <summary>The kinds of particle that a car leaves behind it</summary>
  TRacingParticleKind = (Spark, Smoke, GrassDirt, Dirt, SandDirt);

  /// <summary>One car of the game (the old carinfo_t)</summary>
  TRacingCarInfo = record
    /// <summary>The textures of the model that the replacement textures take the place of</summary>
    OriginalTexture1: string;
    Texture1: string;
    OriginalTexture2: string;
    Texture2: string;
    /// <summary>The number that is seen on the car</summary>
    Number: Integer;
    MaxSpeed: TFixed;
    /// <summary>A negative speed</summary>
    MaxReverseSpeed: TFixed;
    /// <summary>The speed gained in one tic with the gear that pushes most</summary>
    BaseAcceleration: TFixed;
    /// <summary>The speed lost in one tic by the brakes</summary>
    BaseDeceleration: TFixed;
    /// <summary>The angle of the steering in one tic</summary>
    TurnSpeed: TAngle;
    Model3d: string;
    CarType: TRacingCarType;
    /// <summary>The widest drift, in degrees</summary>
    MaxDrift: Integer;
    Name: string;
  end;

  /// <summary>What a driver asks of a car in a tic (the old drivingcmd_t)</summary>
  TRacingDrivingCommand = record
    Turn: TFixed;
    Accelerate: TFixed;
    Decelerate: TFixed;
    Brake: TFixed;
  end;

  /// <summary>
  ///   Everything the racing code knows about a car: the fields of the old mobj_t that are only
  ///   for the cars, plus the position and the angle. The game copies the fields from the object
  ///   of the car, runs the code and copies them back; the distances travelled by the tires are
  ///   Double, as in the old object
  /// </summary>
  TRacingCarState = record
    X, Y, Z: TFixed;
    /// <summary>Where the car was in the last tic: the speed is the distance from here</summary>
    OldX, OldY: TFixed;
    Angle: TAngle;
    MomentumX, MomentumY: TFixed;
    EngineSpeed: TFixed;
    CarInfo: Integer;
    CarId: Integer;
    DestinationAngle: TAngle;
    DestinationSpeed: TFixed;
    CurrentPath: Integer;
    PreviousPath: Integer;
    LapsCompleted: Integer;
    RacePosition: Integer;
    /// <summary>The first tic that can leave a particle</summary>
    NextParticle: Integer;
    /// <summary>The distance each tire has travelled, in map units (two wheels of a formula car do not follow the engine)</summary>
    TireDistance: array[0..3] of Double;
    TireAngle: Integer;
    SoundCountdown: Integer;
    CarTurn: TFixed;
    CarAccelerate: TFixed;
    CarDecelerate: TFixed;
    CarBrake: TFixed;
    BrakeSoundCountdown: Integer;
    /// <summary>Where the sound of the brakes comes from</summary>
    BrakeSoundX, BrakeSoundY, BrakeSoundZ: TFixed;
    Rpm: Integer;
    Gear: Integer;
    DestinationGear: Integer;
    GearTics: Integer;
    NextGearTics: Integer;
    DriftAngle: Integer;
    /// <summary>The unique key of the object: it decides between two cars at the same place in the race</summary>
    Key: Cardinal;
    /// <summary>True when a person drives the car (the engine sound of the other cars comes from the car)</summary>
    IsPlayer: Boolean;
  end;

  /// <summary>What a person asks (the fields of the player command that the cars read)</summary>
  TRacingPlayerInput = record
    /// <summary>The steering of the tic, in the units of the player command</summary>
    AngleTurn: Integer;
    /// <summary>Only the sign counts: forward, back or none</summary>
    ForwardMove: Integer;
    /// <summary>The gear buttons (RACING_BUTTON_GEAR_UP and RACING_BUTTON_GEAR_DOWN)</summary>
    Buttons: Integer;
  end;

  /// <summary>What a player keeps about the laps (the old laprecordchecked of the player)</summary>
  TRacingPlayerState = record
    LapRecordChecked: array[0..RACING_MAX_LAPS - 1] of Boolean;
  end;

  /// <summary>The laps of a car, in tics (the old timelaps_t)</summary>
  TRacingLapTimes = array[0..RACING_MAX_LAPS - 1] of Integer;

  /// <summary>The result of a race of a player (the old playerscore_t)</summary>
  TRacingScore = record
    Episode: Integer;
    Map: Integer;
    NumLaps: Integer;
    CarInfo: Integer;
    RacePosition: Integer;
    LapTimes: TRacingLapTimes;
    TotalTime: Integer;
  end;

  /// <summary>When a car entered and left a point of the path in a lap (the old rtlcarpathinfoitem_t)</summary>
  TRacingPathVisit = record
    EnterTime: Integer;
    ExitTime: Integer;
    VisitLap: Integer;
  end;

  /// <summary>The visits of a car to a point of the path, one for each lap (the old rtlcarpathinfo_t)</summary>
  TRacingPathVisits = array[0..RACING_MAX_LAPS] of TRacingPathVisit;

  /// <summary>A point of the track as the map gives it: where it is, where the cars have to look and how fast they go</summary>
  TRacingPathPoint = record
    X, Y: TFixed;
    Angle: TAngle;
    /// <summary>The speed in km/h</summary>
    Speed: Integer;
  end;

  /// <summary>A point of the track as the map file gives it, before the game makes an object of it</summary>
  TRacingPathThing = record
    /// <summary>The position, in map units</summary>
    X, Y: Integer;
    /// <summary>The angle, in degrees</summary>
    Angle: Integer;
    /// <summary>The speed in km/h</summary>
    Speed: Integer;
  end;

  /// <summary>A point of the path that the cars of the computer follow (the old rtlpath_t)</summary>
  TRacingPath = record
    X, Y: TFixed;
    Angle: TAngle;
    Id: Integer;
    Speed: TFixed;
    Previous: Integer;
    Next: Integer;
    DistanceToNext: TFixed;
    DistanceToHere: Int64;
    Visits: array[0..RACING_CAR_COUNT - 1] of TRacingPathVisits;
  end;

  PRacingPath = ^TRacingPath;

  /// <summary>What the race needs to know of a car to put it in order (the cars that have a car info)</summary>
  TRacingPositionInput = record
    Key: Cardinal;
    CarInfo: Integer;
    LapsCompleted: Integer;
    CurrentPath: Integer;
    X, Y: TFixed;
  end;

  /// <summary>One car in the order of the race (the old racepositionitem_t)</summary>
  TRacingPositionItem = record
    /// <summary>Which car of the input this is</summary>
    Index: Integer;
    Key: Cardinal;
    TotalDistance: Int64;
    LapsCompleted: Integer;
    FinishTime: Integer;
  end;

  /// <summary>The settings of the championship that a race keeps (the old championship_t)</summary>
  TRacingChampionship = record
    NumLaps: Integer;
    RaceCarType: TRacingCarType;
    GameType: TRacingGameType;
    TransmissionType: Integer;
    DefaultFormulaCar: Integer;
    DefaultStockCar: Integer;
    DefaultAnyCar: Integer;
    PilotName: string;
  end;

  /// <summary>A line of a table of times (the old speedtimetableitem_t); the layout is the one of the file of the records</summary>
  TRacingScoreItem = record
    DriverName: string[RACING_PILOT_NAME_SIZE];
    Time: Integer;
    CarId: Integer;
    /// <summary>The skill, as a number of TRacingSkill</summary>
    Skill: Byte;
  end;

  /// <summary>The ten best times of a track for a family of cars</summary>
  TRacingScoreItems = array[0..RACING_SCORES_PER_TABLE - 1] of TRacingScoreItem;

  PRacingScoreItems = ^TRacingScoreItems;

  /// <summary>The tables of times of every track and family (the old speedtimetable_t)</summary>
  TRacingScoreTable = array[1..RACING_MAX_EPISODES] of array[1..RACING_MAX_MAPS] of
    array[TRacingCarType.Formula..TRacingCarType.Stock] of TRacingScoreItems;

  /// <summary>
  ///   All the records: the best laps and the best races for every number of laps (the old
  ///   speedrecordtable_t); it is the file of the records as it is
  /// </summary>
  TRacingRecordTable = record
    LapRecords: TRacingScoreTable;
    CourseRecords: array[RACING_MIN_LAPS..RACING_MAX_LAPS] of TRacingScoreTable;
  end;

  PRacingRecordTable = ^TRacingRecordTable;

implementation

end.
