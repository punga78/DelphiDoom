{******************************************************************************}
{                                                                              }
{  DelphiDoom: racing library - the state of the race                          }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The fields of the old race_t that the cars read, and the clocks             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Racing.RaceState;

interface

uses
  DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  /// <summary>
  ///   The state of the race as a plain object: the game writes it (the start of the race, the
  ///   clocks at every tic) and the cars read it through IRacingRaceState
  /// </summary>
  TRacingRaceState = class(TInterfacedObject, IRacingRaceState, IRacingRaceSettings)
  strict private
    FStatus: TRacingStatus;
    FCarType: TRacingCarType;
    FGameType: TRacingGameType;
    FTransmissionType: Integer;
    FNumLaps: Integer;
    FRaceTime: Integer;
    FLevelTime: Integer;
    FSkill: TRacingSkill;
    FEpisode: Integer;
    FMap: Integer;
  public
    constructor Create;
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

implementation

{ TRacingRaceState }

constructor TRacingRaceState.Create;
begin
  inherited Create;
  FStatus := TRacingStatus.Waiting;
  FCarType := TRacingCarType.Formula;
  FGameType := TRacingGameType.Championship;
  FTransmissionType := RACING_TRANSMISSION_AUTOMATIC;
  FNumLaps := RACING_MIN_LAPS;
  FSkill := TRacingSkill.Medium;
end;

function TRacingRaceState.GetStatus: TRacingStatus;
begin
  Result := FStatus;
end;

function TRacingRaceState.GetCarType: TRacingCarType;
begin
  Result := FCarType;
end;

function TRacingRaceState.GetGameType: TRacingGameType;
begin
  Result := FGameType;
end;

function TRacingRaceState.GetTransmissionType: Integer;
begin
  Result := FTransmissionType;
end;

function TRacingRaceState.GetNumLaps: Integer;
begin
  Result := FNumLaps;
end;

function TRacingRaceState.GetRaceTime: Integer;
begin
  Result := FRaceTime;
end;

function TRacingRaceState.GetLevelTime: Integer;
begin
  Result := FLevelTime;
end;

function TRacingRaceState.GetSkill: TRacingSkill;
begin
  Result := FSkill;
end;

function TRacingRaceState.GetEpisode: Integer;
begin
  Result := FEpisode;
end;

function TRacingRaceState.GetMap: Integer;
begin
  Result := FMap;
end;

procedure TRacingRaceState.SetStatus(AValue: TRacingStatus);
begin
  FStatus := AValue;
end;

procedure TRacingRaceState.SetCarType(AValue: TRacingCarType);
begin
  FCarType := AValue;
end;

procedure TRacingRaceState.SetGameType(AValue: TRacingGameType);
begin
  FGameType := AValue;
end;

procedure TRacingRaceState.SetTransmissionType(AValue: Integer);
begin
  FTransmissionType := AValue;
end;

procedure TRacingRaceState.SetNumLaps(AValue: Integer);
begin
  FNumLaps := AValue;
end;

procedure TRacingRaceState.SetRaceTime(AValue: Integer);
begin
  FRaceTime := AValue;
end;

procedure TRacingRaceState.SetLevelTime(AValue: Integer);
begin
  FLevelTime := AValue;
end;

procedure TRacingRaceState.SetSkill(AValue: TRacingSkill);
begin
  FSkill := AValue;
end;

procedure TRacingRaceState.SetEpisode(AValue: Integer);
begin
  FEpisode := AValue;
end;

procedure TRacingRaceState.SetMap(AValue: Integer);
begin
  FMap := AValue;
end;

end.
