{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the state of the play of a level                  }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  c, button0held, button1held, playstate, gamestate and GivePoints of kd_play.c }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.PlayState;

interface

uses
  System.SysUtils, DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   What the loop of the frames and the actions of the actors share: the control of the player of the frame,
  ///   the buttons that are still held from the last frame, how the level ends and what a saved game keeps
  /// </summary>
  TKeenPlayState = class(TInterfacedObject, IKeenPlayState)
  strict private
    FEvents: IKeenGameEvents;
    FGameState: TKeenGameState;
    FPlayState: TKeenExit;
    FControl: TKeenControlInfo;
    FButton0Held: Boolean;
    FButton1Held: Boolean;
    FMapOn: Integer;
  public
    constructor Create(const AEvents: IKeenGameEvents);
    function GetControl: TKeenControlInfo;
    procedure SetControl(const AValue: TKeenControlInfo);
    function GetButton0Held: Boolean;
    procedure SetButton0Held(AValue: Boolean);
    function GetButton1Held: Boolean;
    procedure SetButton1Held(AValue: Boolean);
    function GetPlayState: TKeenExit;
    procedure SetPlayState(AValue: TKeenExit);
    function GetGameState: PKeenGameState;
    function GetMapOn: Integer;
    procedure SetMapOn(AValue: Integer);
    procedure GivePoints(APoints: Integer);
  end;

implementation

uses
  DelphiDoom.Keen.AudioIds;

{ TKeenPlayState }

constructor TKeenPlayState.Create(const AEvents: IKeenGameEvents);
begin
  inherited Create;
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  FEvents := AEvents;
  FPlayState := keNotDone;
end;

function TKeenPlayState.GetControl: TKeenControlInfo;
begin
  Result := FControl;
end;

procedure TKeenPlayState.SetControl(const AValue: TKeenControlInfo);
begin
  FControl := AValue;
end;

function TKeenPlayState.GetButton0Held: Boolean;
begin
  Result := FButton0Held;
end;

procedure TKeenPlayState.SetButton0Held(AValue: Boolean);
begin
  FButton0Held := AValue;
end;

function TKeenPlayState.GetButton1Held: Boolean;
begin
  Result := FButton1Held;
end;

procedure TKeenPlayState.SetButton1Held(AValue: Boolean);
begin
  FButton1Held := AValue;
end;

function TKeenPlayState.GetPlayState: TKeenExit;
begin
  Result := FPlayState;
end;

procedure TKeenPlayState.SetPlayState(AValue: TKeenExit);
begin
  FPlayState := AValue;
end;

function TKeenPlayState.GetGameState: PKeenGameState;
begin
  Result := @FGameState;
end;

function TKeenPlayState.GetMapOn: Integer;
begin
  Result := FMapOn;
end;

procedure TKeenPlayState.SetMapOn(AValue: Integer);
begin
  FMapOn := AValue;
end;

procedure TKeenPlayState.GivePoints(APoints: Integer);
begin
  FGameState.Score := FGameState.Score + APoints;
  if FGameState.Score >= FGameState.NextExtra then
  begin
    FEvents.PlaySound(KEEN_SND_EXTRAKEENSND);
    Inc(FGameState.Lives);
    FGameState.NextExtra := FGameState.NextExtra * 2;
  end;
end;

end.
