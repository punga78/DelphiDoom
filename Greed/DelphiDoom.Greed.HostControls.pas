{******************************************************************************}
{                                                                              }
{  DelphiDoom: Greed32 - the keys of the window as the commands of the game     }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): the default keys of         }
{  d_ints.pas (scanbuttons) and the keys that ControlMovement reads             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.HostControls;

interface

uses
  Winapi.Windows, System.SysUtils, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState,
  DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   IGreedCommandSource on the key state of the window of Libs\GameHost, with the default keys of the
  ///   original: arrows to walk and turn, Ctrl fires, Alt strafes, Space uses (and starts again when dead), Shift
  ///   runs, Z jumps, X uses the item of the inventory, Insert and Delete choose it, A the rear view, Page Up,
  ///   Page Down and Home look, comma and period step aside, S the motion mode, M the map, H the heat mode, Tab
  ///   the goal item, 1..5 the weapons, P pauses, Escape the menu, F1 help, F4 quick exit, F5 briefing, F7 another
  ///   song, F9 and F10 the size of the view, Caps Lock the auto run, Num Lock the auto target, minus and plus the
  ///   zoom of the map. The letters and the digits that go down between two readings are the characters typed
  ///   (the secret codes). The mouse is not read: the key state of the window has no mouse
  /// </summary>
  TGreedHostControls = class(TInterfacedObject, IGreedCommandSource)
  strict private
    const
      FIRST_TYPED = Ord('0');
      LAST_TYPED = Ord('Z');
    var
      FKeys: IGameHostKeyState;
      FWasDown: array[FIRST_TYPED..LAST_TYPED] of Boolean;
      FTyped: string;
    class function KeyOf(ACommand: TGreedCommand): Integer; static;
  public
    /// <summary>EArgumentNilException if AKeys is nil</summary>
    constructor Create(const AKeys: IGameHostKeyState);
    procedure BeginReading;
    function IsPressed(ACommand: TGreedCommand): Boolean;
    function TakeTyped(out ACharacter: Char): Boolean;
    function IsMousePressed(AButton: TGreedMouseButton): Boolean;
    procedure TakeMouseMove(out ADeltaX, ADeltaY: Integer);
  end;

implementation

{ TGreedHostControls }

constructor TGreedHostControls.Create(const AKeys: IGameHostKeyState);
begin
  inherited Create;
  if not Assigned(AKeys) then
    raise EArgumentNilException.Create('AKeys');
  FKeys := AKeys;
end;

class function TGreedHostControls.KeyOf(ACommand: TGreedCommand): Integer;
begin
  case ACommand of
    gcNorth: Result := VK_UP;
    gcEast: Result := VK_RIGHT;
    gcSouth: Result := VK_DOWN;
    gcWest: Result := VK_LEFT;
    gcFire: Result := VK_CONTROL;
    gcStrafe, gcAlt: Result := VK_MENU;
    gcUse, gcRestart: Result := VK_SPACE;
    gcRun, gcShift: Result := VK_SHIFT;
    gcJump: Result := Ord('Z');
    gcUseItem: Result := Ord('X');
    gcRearView: Result := Ord('A');
    gcLookUp: Result := VK_PRIOR;
    gcLookDown: Result := VK_NEXT;
    gcCenterView: Result := VK_HOME;
    gcSlideLeft: Result := VK_OEM_COMMA;
    gcSlideRight: Result := VK_OEM_PERIOD;
    gcInventoryLeft: Result := VK_INSERT;
    gcInventoryRight: Result := VK_DELETE;
    gcMotionMode: Result := Ord('S');
    gcMenu: Result := VK_ESCAPE;
    gcHelp: Result := VK_F1;
    gcVrAngleUp: Result := VK_F2;
    gcVrDistanceNear: Result := VK_F3;
    gcQuickExit: Result := VK_F4;
    gcBriefing: Result := VK_F5;
    gcNetMessage: Result := VK_F6;
    gcNewSong: Result := VK_F7;
    gcViewBigger: Result := VK_F9;
    gcViewSmaller: Result := VK_F10;
    gcQuit: Result := Ord('Q');
    gcPause: Result := Ord('P');
    gcMapZoomOut: Result := VK_OEM_MINUS;
    gcMapZoomIn: Result := VK_OEM_PLUS;
    gcMapMode: Result := Ord('M');
    gcHeatMode: Result := Ord('H');
    gcGoalItem: Result := VK_TAB;
    gcAutoRun: Result := VK_CAPITAL;
    gcAutoTarget: Result := VK_NUMLOCK;
    gcWeapon1: Result := Ord('1');
    gcWeapon2: Result := Ord('2');
    gcWeapon3: Result := Ord('3');
    gcWeapon4: Result := Ord('4');
    gcWeapon5: Result := Ord('5');
  else
    Result := 0;
  end;
end;

procedure TGreedHostControls.BeginReading;
var
  LKey: Integer;
  LDown: Boolean;
begin
  for LKey := FIRST_TYPED to LAST_TYPED do
    if CharInSet(Char(LKey), ['0'..'9', 'A'..'Z']) then
    begin
      LDown := FKeys.IsDown(LKey);
      if LDown and not FWasDown[LKey] then
        FTyped := FTyped + Char(LKey);
      FWasDown[LKey] := LDown;
    end;
end;

function TGreedHostControls.IsPressed(ACommand: TGreedCommand): Boolean;
var
  LKey: Integer;
begin
  LKey := KeyOf(ACommand);
  Result := (LKey <> 0) and FKeys.IsDown(LKey);
end;

function TGreedHostControls.TakeTyped(out ACharacter: Char): Boolean;
begin
  Result := FTyped <> '';
  if Result then
  begin
    ACharacter := FTyped[1];
    Delete(FTyped, 1, 1);
  end
  else
    ACharacter := #0;
end;

function TGreedHostControls.IsMousePressed(AButton: TGreedMouseButton): Boolean;
begin
  Result := False;
end;

procedure TGreedHostControls.TakeMouseMove(out ADeltaX, ADeltaY: Integer);
begin
  ADeltaX := 0;
  ADeltaY := 0;
end;

end.
