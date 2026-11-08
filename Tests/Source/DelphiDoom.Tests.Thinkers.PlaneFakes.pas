{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the thinkers library - the fake host of the planes     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.PlaneFakes;

// the series of numbers wraps on purpose
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Thinkers.Plane.Intf, DelphiDoom.Tests.Thinkers.OldPlanes;

type
  /// <summary>
  ///   What the game does when a plane moves, for the tests: a sector is blocked when the gap
  ///   between its ceiling and its floor is smaller than the height of a thing (or always, when
  ///   BlockAll is set). Every call is written in a log, so two runs can be compared
  /// </summary>
  TFakePlaneHost = class(TInterfacedObject, IPlaneSectorHost)
  strict private
    FThingHeight: Integer;
    FLog: string;
    FChangeCount: Integer;
    FMovedCount: Integer;
    FLastSector: Pointer;
  public
    /// <summary>When True every change of a sector is blocked</summary>
    BlockAll: Boolean;
    constructor Create(AThingHeight: Integer);
    function ChangeSector(ASector: Pointer; ACrush: Boolean): Boolean;
    procedure PlaneMoved(ASector: Pointer);
    /// <summary>Forgets the log and the counters</summary>
    procedure Clear;
    /// <summary>The calls so far, as text</summary>
    property Log: string read FLog;
    /// <summary>How many times ChangeSector was called</summary>
    property ChangeCount: Integer read FChangeCount;
    /// <summary>How many times PlaneMoved was called</summary>
    property MovedCount: Integer read FMovedCount;
    /// <summary>The sector of the last call</summary>
    property LastSector: Pointer read FLastSector;
  end;

/// <summary>The next number of a small generator that gives the same series everywhere</summary>
function NextTestNumber(var AState: Cardinal): Cardinal;

/// <summary>A number from AMin to AMax (both included)</summary>
function TestNumberIn(var AState: Cardinal; AMin, AMax: Integer): Integer;

implementation

{ TFakePlaneHost }

constructor TFakePlaneHost.Create(AThingHeight: Integer);
begin
  inherited Create;
  FThingHeight := AThingHeight;
end;

function TFakePlaneHost.ChangeSector(ASector: Pointer; ACrush: Boolean): Boolean;
var
  LSector: Psector_t;
begin
  LSector := Psector_t(ASector);
  FLastSector := ASector;
  Inc(FChangeCount);
  Result := BlockAll or (LSector.ceilingheight - LSector.floorheight < FThingHeight);
  FLog := FLog + Format('C%d/%d/%d>%d;', [LSector.floorheight, LSector.ceilingheight,
    Ord(ACrush), Ord(Result)]);
end;

procedure TFakePlaneHost.PlaneMoved(ASector: Pointer);
begin
  FLastSector := ASector;
  Inc(FMovedCount);
  FLog := FLog + 'M;';
end;

procedure TFakePlaneHost.Clear;
begin
  FLog := '';
  FChangeCount := 0;
  FMovedCount := 0;
  FLastSector := nil;
end;

function NextTestNumber(var AState: Cardinal): Cardinal;
begin
  // wraps on purpose (a linear congruential generator)
  AState := Cardinal(AState * Cardinal(1664525) + Cardinal(1013904223));
  Result := AState shr 8;
end;

function TestNumberIn(var AState: Cardinal; AMin, AMax: Integer): Integer;
begin
  Result := AMin + Integer(NextTestNumber(AState) mod Cardinal(AMax - AMin + 1));
end;

end.
