// TEMPORARY HARNESS of issue #152 (not for the build of the game): runs the OLD code of the door
// thinkers next to the NEW one, for every tic of every door, on the same state and the same
// results of the real movement of the ceiling. See RUN-152.md.
//
// The old code here is the oracle of the unit tests (Tests\Source\DelphiDoom.Tests.Thinkers.OldDoors:
// the statements of the old procedures, with the calls to the game replaced by a fake host), not a
// compilation of the old text: the real old executable is the one built from master (RUN-152.md,
// timedemo and savegames).
//
// For each call: state of the door (neutral kind) and floor are written down -> the NEW code runs
// on the real door through a recording host (it writes down every movement with its real result,
// every sound and every stop, and delegates to the real host) -> the OLD code runs on the written
// down state with a fake host that answers with the recorded results -> compare the state, the
// lines written, and whether the door was removed. A report is written to door_parity.txt on exit.

{$I Doom32.inc}

unit door_parity;

interface

uses
  p_spec;

type
  TDPDoorProc = procedure(door: Pvldoor_t);

procedure DP_Classic(door: Pvldoor_t; NewProc: TDPDoorProc);
procedure DP_Udmf(door: Pvldoor_t; NewProc: TDPDoorProc);

implementation

uses
  SysUtils,
  Classes,
  m_base,
  r_defs,
{$IFNDEF HEXEN}
  g_game,
{$ENDIF}
  p_tick,
  DelphiDoom.Thinkers.Door.Types,
  DelphiDoom.Thinkers.Door.Intf,
  DelphiDoom.Thinkers.Door.Profiles,
  DelphiDoom.Thinkers.Door.Factory,
  DelphiDoom.Engine.Door.Kinds,
  DelphiDoom.Engine.Door.Host,
  DelphiDoom.Engine.Door.Services,
  DelphiDoom.Tests.Thinkers.DoorFakes,
  DelphiDoom.Tests.Thinkers.OldDoors;

type
  /// The services of the game, written down: the real ones do the work
  TDPHost = class(TInterfacedObject, IDoorPlaneMover, IDoorSounds, IDoorSectorQueries,
    IDoorOptions)
  private
    FPlane: IDoorPlaneMover;
    FSounds: IDoorSounds;
    FQueries: IDoorSectorQueries;
    FOptions: IDoorOptions;
  public
    constructor Create(const AReal: IDoorPlaneMover);
    function MovePlane(ASector: Pointer; ASpeed, ADestination: Integer; ACrush: Boolean;
      AFloorOrCeiling, ADirection: Integer): TDoorPlaneResult;
    procedure Play(ASector: Pointer; ASound: TDoorSound; const AState: TDoorState);
    procedure Stop(ASector: Pointer);
    function LowestCeilingSurrounding(ASector: Pointer): Integer;
    function LowestFloorSurrounding(ASector: Pointer): Integer;
    function HighestFloorSurrounding(ASector: Pointer): Integer;
    function GetCompatibilityMode: Boolean;
  end;

const
  SOUND_NAMES: array[TDoorSound] of string = ('None', 'Open', 'Close', 'BlazeOpen', 'BlazeClose');

var
  dp_installed: boolean = false;
  dp_log: TStringList = nil;
  dp_results: array of TDoorPlaneResult;
  dp_ticks: array[boolean] of integer;
  dp_bad: array[boolean] of integer;
  dp_report: TextFile;
  dp_reportopen: boolean = false;

//==============================================================================
// the recording host
//==============================================================================
constructor TDPHost.Create(const AReal: IDoorPlaneMover);
begin
  inherited Create;
  FPlane := AReal;
  FSounds := AReal as IDoorSounds;
  FQueries := AReal as IDoorSectorQueries;
  FOptions := AReal as IDoorOptions;
end;

function TDPHost.MovePlane(ASector: Pointer; ASpeed, ADestination: Integer; ACrush: Boolean;
  AFloorOrCeiling, ADirection: Integer): TDoorPlaneResult;
var
  crushtext: string;
begin
  result := FPlane.MovePlane(ASector, ASpeed, ADestination, ACrush, AFloorOrCeiling, ADirection);
  if ACrush then
    crushtext := '1'
  else
    crushtext := '0';
  dp_log.Add(Format('move speed=%d dest=%d crush=%s fc=%d dir=%d',
    [ASpeed, ADestination, crushtext, AFloorOrCeiling, ADirection]));
  SetLength(dp_results, Length(dp_results) + 1);
  dp_results[Length(dp_results) - 1] := result;
end;

procedure TDPHost.Play(ASector: Pointer; ASound: TDoorSound; const AState: TDoorState);
begin
  dp_log.Add('play ' + SOUND_NAMES[ASound]);
  FSounds.Play(ASector, ASound, AState);
end;

procedure TDPHost.Stop(ASector: Pointer);
begin
  dp_log.Add('stop');
  FSounds.Stop(ASector);
end;

function TDPHost.LowestCeilingSurrounding(ASector: Pointer): Integer;
begin
  result := FQueries.LowestCeilingSurrounding(ASector);
end;

function TDPHost.LowestFloorSurrounding(ASector: Pointer): Integer;
begin
  result := FQueries.LowestFloorSurrounding(ASector);
end;

function TDPHost.HighestFloorSurrounding(ASector: Pointer): Integer;
begin
  result := FQueries.HighestFloorSurrounding(ASector);
end;

function TDPHost.GetCompatibilityMode: Boolean;
begin
  result := FOptions.CompatibilityMode;
end;

//==============================================================================
// the report
//==============================================================================
procedure DP_Open;
begin
  if not dp_reportopen then
  begin
    AssignFile(dp_report, 'door_parity.txt');
    Rewrite(dp_report);
    dp_reportopen := true;
  end;
end;

procedure DP_Account(AUdmf: boolean; same: boolean; const what: string);
begin
  inc(dp_ticks[AUdmf]);
  if not same then
  begin
    inc(dp_bad[AUdmf]);
    if dp_bad[AUdmf] <= 20 then
    begin
      DP_Open;
      writeln(dp_report, 'MISMATCH udmf=', AUdmf, ' ', what);
    end;
  end;
end;

//==============================================================================
// the installation: the same services as ComposeDoors, with the recording host in the middle
//==============================================================================
procedure DP_Install;
var
  game: TDoorGame;
  realhost: IDoorPlaneMover;
  wrap: IDoorPlaneMover;
  profile: TDoorProfile;
  classicrunner: IDoorRunner;
  classicspawner: IDoorSpawner;
  udmfrunner: IDoorRunner;
  udmfspawner: IDoorSpawner;
begin
  if dp_installed then
    exit;
  dp_installed := true;
  dp_log := TStringList.Create;
  if not TDoorProfiles.TryGameFromName(_GAME, game) then
    exit;

  classicrunner := nil;
  classicspawner := nil;
  if game <> TDoorGame.Hexen then
  begin
    realhost := TEngineDoorHost.Create(TDoorFlavor.Classic);
    wrap := TDPHost.Create(realhost);
    profile := TDoorProfiles.ForGame(game, TDoorFlavor.Classic);
    classicrunner := TDoorFactory.CreateRunner(profile, wrap, wrap as IDoorSounds,
      wrap as IDoorOptions);
    classicspawner := TDoorFactory.CreateSpawner(profile, wrap as IDoorSounds,
      wrap as IDoorSectorQueries);
  end;

  realhost := TEngineDoorHost.Create(TDoorFlavor.Udmf);
  wrap := TDPHost.Create(realhost);
  profile := TDoorProfiles.ForGame(game, TDoorFlavor.Udmf);
  udmfrunner := TDoorFactory.CreateRunner(profile, wrap, wrap as IDoorSounds,
    wrap as IDoorOptions);
  udmfspawner := TDoorFactory.CreateSpawner(profile, wrap as IDoorSounds,
    wrap as IDoorSectorQueries);

  P_ConfigureDoors(classicrunner, classicspawner, udmfrunner, udmfspawner);
end;

//==============================================================================
// the door as the library sees it
//==============================================================================
procedure DP_Load(door: Pvldoor_t; out AState: TDoorState);
begin
  AState := Default(TDoorState);
  AState.Kind := DoorKindToNeutral(door._type);
  AState.Direction := door.direction;
  AState.TopHeight := door.topheight;
  AState.Speed := door.speed;
  AState.TopWait := door.topwait;
  AState.TopCountdown := door.topcountdown;
{$IFDEF STRIFE}
  AState.OpenSound := door.opensound;
  AState.CloseSound := door.closesound;
{$ENDIF}
end;

function DP_SectorData(door: Pvldoor_t; AUdmf: boolean): pointer;
begin
{$IF DEFINED(DOOM) OR DEFINED(STRIFE)}
  if AUdmf then
    result := door.sector.specialdata
  else
    result := door.sector.ceilingdata;
{$ELSE}
  result := door.sector.specialdata;
{$IFEND}
end;

//==============================================================================
// the old code on the written down state
//==============================================================================
procedure DP_Old(var ADoor: TDoorState; AFloor: integer; const AHost: TFakeDoorHost;
  var AOutcome: TOldDoorOutcome; AUdmf: boolean);
begin
  if AUdmf then
    OldUdmfTick(ADoor, AFloor, AHost, AOutcome)
  else
  begin
{$IFDEF DOOM}
    OldDoomTick(ADoor, AFloor, AHost, AOutcome);
{$ENDIF}
{$IFDEF HERETIC}
    OldHereticTick(ADoor, AFloor, AHost, AOutcome);
{$ENDIF}
{$IFDEF STRIFE}
    OldStrifeTick(ADoor, AFloor, AHost, AOutcome);
{$ENDIF}
  end;
end;

procedure DP_Run(door: Pvldoor_t; NewProc: TDPDoorProc; AUdmf: boolean);
var
  before, newstate: TDoorState;
  floorheight: integer;
  wasset, removed: boolean;
  newlog: string;
  oldevents: TStringList;
  oldhost: TFakeDoorHost;
  oldoutcome: TOldDoorOutcome;
  oldstate: TDoorState;
  results: array of TDoorPlaneResult;
  i: integer;
  same: boolean;
begin
  DP_Install;
  DP_Load(door, before);
  floorheight := door.sector.floorheight;
  wasset := DP_SectorData(door, AUdmf) = door;
  dp_log.Clear;
  SetLength(dp_results, 0);

  NewProc(door);

  newlog := dp_log.Text;
  DP_Load(door, newstate);
  removed := wasset and (DP_SectorData(door, AUdmf) <> door);
  SetLength(results, Length(dp_results));
  for i := 0 to High(dp_results) do
    results[i] := dp_results[i];

  oldevents := TStringList.Create;
  oldhost := TFakeDoorHost.Create(oldevents);
  try
    oldhost.SetResults(results);
{$IFNDEF HEXEN}
    oldhost.Compatibility := compatibilitymode;
{$ENDIF}
    oldstate := before;
    oldoutcome := Default(TOldDoorOutcome);
    DP_Old(oldstate, floorheight, oldhost, oldoutcome, AUdmf);

    same := (DoorStateToText(oldstate) = DoorStateToText(newstate)) and
            (oldevents.Text = newlog) and
            (oldoutcome.Removed = removed);
    DP_Account(AUdmf, same, Format('old [%s] removed %d calls [%s], new [%s] removed %d calls [%s]',
      [DoorStateToText(oldstate), Ord(oldoutcome.Removed), StringReplace(oldevents.Text, #13#10, ';', [rfReplaceAll]),
       DoorStateToText(newstate), Ord(removed), StringReplace(newlog, #13#10, ';', [rfReplaceAll])]));
  finally
    oldhost.Free;
    oldevents.Free;
  end;
end;

procedure DP_Classic(door: Pvldoor_t; NewProc: TDPDoorProc);
begin
{$IFDEF HEXEN}
  NewProc(door);
{$ELSE}
  DP_Run(door, NewProc, false);
{$ENDIF}
end;

procedure DP_Udmf(door: Pvldoor_t; NewProc: TDPDoorProc);
begin
  DP_Run(door, NewProc, true);
end;

initialization

finalization
  if dp_installed then
  begin
    DP_Open;
    writeln(dp_report, 'classic ticks=', dp_ticks[false], ' mismatches=', dp_bad[false]);
    writeln(dp_report, 'udmf ticks=', dp_ticks[true], ' mismatches=', dp_bad[true]);
  end;
  if dp_reportopen then
    CloseFile(dp_report);
  dp_log.Free;

end.
