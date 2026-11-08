{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the fake services of the doors  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.DoorFakes;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DelphiDoom.Thinkers.Door.Types, DelphiDoom.Thinkers.Door.Intf;

type
  /// <summary>
  ///   The services of the doors for the tests. It writes down every call in a list of lines (the
  ///   movement of the ceiling, the sounds), answers the movement with a script of results, and
  ///   has the same four faces as the engine's host. The old code of the tests calls the Old*
  ///   methods, which write the same lines: so two hosts with the same script can be compared
  /// </summary>
  TFakeDoorHost = class(TInterfacedObject, IDoorPlaneMover, IDoorSounds, IDoorSectorQueries,
    IDoorOptions)
  strict private
    FEvents: TStrings;
    FResults: TList<TDoorPlaneResult>;
    FNextResult: Integer;
  public
    /// <summary>The compatibility option that the doors read</summary>
    Compatibility: Boolean;
    LowestCeiling: Integer;
    LowestFloor: Integer;
    HighestFloor: Integer;
    /// <param name="AEvents">The list where the calls are written; it belongs to the caller</param>
    constructor Create(AEvents: TStrings);
    destructor Destroy; override;
    /// <summary>The results of the next movements, in order; after the last one the answer is Ok</summary>
    procedure SetResults(const AResults: array of TDoorPlaneResult);
    function OldMove(ASpeed, ADestination: Integer; ACrush: Boolean; AFloorOrCeiling,
      ADirection: Integer): TDoorPlaneResult;
    procedure OldSound(const AName: string);
    procedure OldStop;
    function MovePlane(ASector: Pointer; ASpeed, ADestination: Integer; ACrush: Boolean;
      AFloorOrCeiling, ADirection: Integer): TDoorPlaneResult;
    procedure Play(ASector: Pointer; ASound: TDoorSound; const AState: TDoorState);
    procedure Stop(ASector: Pointer);
    function LowestCeilingSurrounding(ASector: Pointer): Integer;
    function LowestFloorSurrounding(ASector: Pointer): Integer;
    function HighestFloorSurrounding(ASector: Pointer): Integer;
    function GetCompatibilityMode: Boolean;
  end;

/// <summary>The state as a line of text, to compare two of them</summary>
function DoorStateToText(const AState: TDoorState): string;

/// <summary>The outcome as a line of text</summary>
function DoorOutcomeToText(const AOutcome: TDoorTickOutcome): string;

/// <summary>A state with the values that the tests give to a door</summary>
function MakeDoorState(AKind: TDoorKind; ADirection, ATopHeight, ASpeed, ATopWait,
  ATopCountdown: Integer): TDoorState;

/// <summary>The numbers of a series that does not repeat soon: the same seed gives the same numbers</summary>
function NextTestNumber(var ASeed: Cardinal): Cardinal;

implementation

const
  SOUND_NAMES: array[TDoorSound] of string = ('None', 'Open', 'Close', 'BlazeOpen', 'BlazeClose');

function BoolText(AValue: Boolean): string;
begin
  if AValue then
    Result := '1'
  else
    Result := '0';
end;

function DoorStateToText(const AState: TDoorState): string;
begin
  Result := Format('kind=%d dir=%d top=%d speed=%d wait=%d count=%d open=%d close=%d',
    [Ord(AState.Kind), AState.Direction, AState.TopHeight, AState.Speed, AState.TopWait,
    AState.TopCountdown, AState.OpenSound, AState.CloseSound]);
end;

function DoorOutcomeToText(const AOutcome: TDoorTickOutcome): string;
begin
  Result := Format('removed=%s lightsoff=%s lightson=%s', [BoolText(AOutcome.Removed),
    BoolText(AOutcome.TurnLightsOff), BoolText(AOutcome.TurnLightsOn)]);
end;

function MakeDoorState(AKind: TDoorKind; ADirection, ATopHeight, ASpeed, ATopWait,
  ATopCountdown: Integer): TDoorState;
begin
  Result := Default(TDoorState);
  Result.Kind := AKind;
  Result.Direction := ADirection;
  Result.TopHeight := ATopHeight;
  Result.Speed := ASpeed;
  Result.TopWait := ATopWait;
  Result.TopCountdown := ATopCountdown;
end;

function NextTestNumber(var ASeed: Cardinal): Cardinal;
begin
  // a linear congruential series, the wrap of the multiplication is wanted
  ASeed := Cardinal(UInt64(ASeed) * 1103515245 + 12345);
  Result := (ASeed shr 8) and $FFFFFF;
end;

{ TFakeDoorHost }

constructor TFakeDoorHost.Create(AEvents: TStrings);
begin
  inherited Create;
  FEvents := AEvents;
  FResults := TList<TDoorPlaneResult>.Create;
end;

destructor TFakeDoorHost.Destroy;
begin
  FResults.Free;
  inherited Destroy;
end;

procedure TFakeDoorHost.SetResults(const AResults: array of TDoorPlaneResult);
var
  LIndex: Integer;
begin
  FResults.Clear;
  for LIndex := 0 to High(AResults) do
    FResults.Add(AResults[LIndex]);
  FNextResult := 0;
end;

function TFakeDoorHost.OldMove(ASpeed, ADestination: Integer; ACrush: Boolean; AFloorOrCeiling,
  ADirection: Integer): TDoorPlaneResult;
begin
  FEvents.Add(Format('move speed=%d dest=%d crush=%s fc=%d dir=%d', [ASpeed, ADestination,
    BoolText(ACrush), AFloorOrCeiling, ADirection]));
  if FNextResult < FResults.Count then
  begin
    Result := FResults[FNextResult];
    Inc(FNextResult);
  end
  else
    Result := TDoorPlaneResult.Ok;
end;

procedure TFakeDoorHost.OldSound(const AName: string);
begin
  FEvents.Add('play ' + AName);
end;

procedure TFakeDoorHost.OldStop;
begin
  FEvents.Add('stop');
end;

function TFakeDoorHost.MovePlane(ASector: Pointer; ASpeed, ADestination: Integer;
  ACrush: Boolean; AFloorOrCeiling, ADirection: Integer): TDoorPlaneResult;
begin
  Result := OldMove(ASpeed, ADestination, ACrush, AFloorOrCeiling, ADirection);
end;

procedure TFakeDoorHost.Play(ASector: Pointer; ASound: TDoorSound; const AState: TDoorState);
begin
  OldSound(SOUND_NAMES[ASound]);
end;

procedure TFakeDoorHost.Stop(ASector: Pointer);
begin
  OldStop;
end;

function TFakeDoorHost.LowestCeilingSurrounding(ASector: Pointer): Integer;
begin
  Result := LowestCeiling;
end;

function TFakeDoorHost.LowestFloorSurrounding(ASector: Pointer): Integer;
begin
  Result := LowestFloor;
end;

function TFakeDoorHost.HighestFloorSurrounding(ASector: Pointer): Integer;
begin
  Result := HighestFloor;
end;

function TFakeDoorHost.GetCompatibilityMode: Boolean;
begin
  Result := Compatibility;
end;

end.
