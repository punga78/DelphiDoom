{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the commands of the player as the timer of the   }
{  original reads them                                                          }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): INT_ReadControls and        }
{  eat_key of d_ints.pas (keyboard[], in_button[], lastascii, newascii, mouse)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.CommandState;

interface

uses
  System.SysUtils, DelphiDoom.Greed.PlayerControl.Intf;

type
  /// <summary>
  ///   Where the commands come from: the keys of a window, a script, a test. It says what is pressed at the moment
  ///   it is asked; TGreedCommandState asks once for every reading of the controls
  /// </summary>
  IGreedCommandSource = interface
    ['{C81E5A37-294D-4F60-B7A3-5D0E96F1C2B8}']
    /// <summary>A reading of the controls starts: the answers that follow are of the same moment</summary>
    procedure BeginReading;
    function IsPressed(ACommand: TGreedCommand): Boolean;
    /// <summary>The next character typed since the reading before (upper case); False when there are no more</summary>
    function TakeTyped(out ACharacter: Char): Boolean;
    function IsMousePressed(AButton: TGreedMouseButton): Boolean;
    /// <summary>How far the mouse went since the reading before (left and up are positive)</summary>
    procedure TakeMouseMove(out ADeltaX, ADeltaY: Integer);
  end;

  /// <summary>
  ///   keyboard[] of the original, one entry for each command instead of one for each scan code: 0 not pressed,
  ///   1 pressed, 2 pressed and eaten (eat_key). The state changes only when the controls are read (ReadControls:
  ///   INT_ReadControls, which the timer calls on the odd tics), so a command is the same for the whole tic.
  ///   A command that was eaten stays eaten until it is released. The last character typed is given once
  ///   (lastascii and newascii). Difference: in the original two commands on the same key are eaten together
  /// </summary>
  TGreedCommandState = class(TInterfacedObject, IGreedControls, IGreedControlsSampler)
  strict private
    FSource: IGreedCommandSource;
    FKeys: array[TGreedCommand] of Byte;
    FMouse: array[TGreedMouseButton] of Boolean;
    FMouseDeltaX: Integer;
    FMouseDeltaY: Integer;
    FLastCharacter: Char;
    FNewCharacter: Boolean;
  public
    /// <summary>EArgumentNilException if ASource is nil</summary>
    constructor Create(const ASource: IGreedCommandSource);
    procedure ReadControls;
    function IsDown(ACommand: TGreedCommand): Boolean;
    function IsFresh(ACommand: TGreedCommand): Boolean;
    procedure Eat(ACommand: TGreedCommand);
    function TakeCharacter(out ACharacter: Char): Boolean;
    function IsMouseDown(AButton: TGreedMouseButton): Boolean;
    function GetMouseDeltaX: Integer;
    function GetMouseDeltaY: Integer;
  end;

implementation

const
  KEY_UP = 0;
  KEY_DOWN = 1;
  KEY_EATEN = 2;

{ TGreedCommandState }

constructor TGreedCommandState.Create(const ASource: IGreedCommandSource);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FSource := ASource;
end;

procedure TGreedCommandState.ReadControls;
var
  LCommand: TGreedCommand;
  LButton: TGreedMouseButton;
  LCharacter: Char;
begin
  FSource.BeginReading;
  for LCommand := Low(TGreedCommand) to High(TGreedCommand) do
    if FSource.IsPressed(LCommand) then
    begin
      if FKeys[LCommand] = KEY_UP then
        FKeys[LCommand] := KEY_DOWN;
    end
    else
      FKeys[LCommand] := KEY_UP;
  // lastascii := #0 at every reading: a character that was not taken is lost
  FLastCharacter := #0;
  while FSource.TakeTyped(LCharacter) do
  begin
    FLastCharacter := LCharacter;
    FNewCharacter := True;
  end;
  for LButton := Low(TGreedMouseButton) to High(TGreedMouseButton) do
    FMouse[LButton] := FSource.IsMousePressed(LButton);
  FSource.TakeMouseMove(FMouseDeltaX, FMouseDeltaY);
end;

function TGreedCommandState.IsDown(ACommand: TGreedCommand): Boolean;
begin
  Result := FKeys[ACommand] <> KEY_UP;
end;

function TGreedCommandState.IsFresh(ACommand: TGreedCommand): Boolean;
begin
  Result := FKeys[ACommand] = KEY_DOWN;
end;

procedure TGreedCommandState.Eat(ACommand: TGreedCommand);
begin
  if FKeys[ACommand] = KEY_DOWN then
    FKeys[ACommand] := KEY_EATEN;
end;

function TGreedCommandState.TakeCharacter(out ACharacter: Char): Boolean;
begin
  Result := FNewCharacter;
  ACharacter := FLastCharacter;
  FNewCharacter := False;
end;

function TGreedCommandState.IsMouseDown(AButton: TGreedMouseButton): Boolean;
begin
  Result := FMouse[AButton];
end;

function TGreedCommandState.GetMouseDeltaX: Integer;
begin
  Result := FMouseDeltaX;
end;

function TGreedCommandState.GetMouseDeltaY: Integer;
begin
  Result := FMouseDeltaY;
end;

end.
