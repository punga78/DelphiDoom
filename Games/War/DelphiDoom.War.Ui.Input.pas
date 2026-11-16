{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the input of the game                             }
{                                                                              }
{  Port of war1 (acoto87/war1), war_game.c (wg_setInputButton, wg_setInputKey, }
{  wg_beginInputFrame and the loss of focus of wg_processGameEvent), (c) 2019  }
{  Alejandro Coto Gutierrez, zlib License (see Games\War\LICENSE-war1.txt).    }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Input;

interface

uses
  System.SysUtils, System.Math, DelphiDoom.War.Ui.Types, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   WarInput: held buttons and keys and the transitions of the frame in course (JustPressed, JustReleased: true
  ///   from the event to BeginFrame). The mouse is at the position of the last event, cut to the integer below
  /// </summary>
  TWarUiInput = class(TInterfacedObject, IWarUiInput)
  strict private
    FButtons: array[TWarMouseButton] of TWarInputState;
    FKeys: array[TWarKey] of TWarInputState;
    FPositionX: Single;
    FPositionY: Single;
  public
    /// <summary>wg_setInputButton</summary>
    procedure SetButton(AButton: TWarMouseButton; APressed: Boolean);
    /// <summary>wg_setInputKey</summary>
    procedure SetKey(AKey: TWarKey; APressed: Boolean);
    /// <summary>The position of an event of the mouse: (f32)floorf of each coordinate</summary>
    procedure SetPosition(AX, AY: Single);
    /// <summary>wg_beginInputFrame: the transitions are for one frame only</summary>
    procedure BeginFrame;
    /// <summary>SDL_EVENT_WINDOW_FOCUS_LOST and the like: nothing is held, nothing just changed</summary>
    procedure ReleaseAll;
    function IsButtonHeld(AButton: TWarMouseButton): Boolean;
    function IsButtonJustPressed(AButton: TWarMouseButton): Boolean;
    function IsButtonJustReleased(AButton: TWarMouseButton): Boolean;
    function IsKeyHeld(AKey: TWarKey): Boolean;
    function IsKeyJustPressed(AKey: TWarKey): Boolean;
    function IsKeyJustReleased(AKey: TWarKey): Boolean;
    function GetPositionX: Single;
    function GetPositionY: Single;
    property PositionX: Single read GetPositionX;
    property PositionY: Single read GetPositionY;
  end;

implementation

{ TWarUiInput }

procedure TWarUiInput.SetButton(AButton: TWarMouseButton; APressed: Boolean);
begin
  if APressed and not FButtons[AButton].Held then
    FButtons[AButton].JustPressed := True
  else if (not APressed) and FButtons[AButton].Held then
    FButtons[AButton].JustReleased := True;
  FButtons[AButton].Held := APressed;
end;

procedure TWarUiInput.SetKey(AKey: TWarKey; APressed: Boolean);
begin
  if APressed and not FKeys[AKey].Held then
    FKeys[AKey].JustPressed := True
  else if (not APressed) and FKeys[AKey].Held then
    FKeys[AKey].JustReleased := True;
  FKeys[AKey].Held := APressed;
end;

procedure TWarUiInput.SetPosition(AX, AY: Single);
begin
  FPositionX := Floor(AX);
  FPositionY := Floor(AY);
end;

procedure TWarUiInput.BeginFrame;
var
  LButton: TWarMouseButton;
  LKey: TWarKey;
begin
  for LButton := Low(TWarMouseButton) to High(TWarMouseButton) do
  begin
    FButtons[LButton].JustPressed := False;
    FButtons[LButton].JustReleased := False;
  end;
  for LKey := Low(TWarKey) to High(TWarKey) do
  begin
    FKeys[LKey].JustPressed := False;
    FKeys[LKey].JustReleased := False;
  end;
end;

procedure TWarUiInput.ReleaseAll;
var
  LButton: TWarMouseButton;
  LKey: TWarKey;
begin
  for LButton := Low(TWarMouseButton) to High(TWarMouseButton) do
    FButtons[LButton] := Default(TWarInputState);
  for LKey := Low(TWarKey) to High(TWarKey) do
    FKeys[LKey] := Default(TWarInputState);
end;

function TWarUiInput.IsButtonHeld(AButton: TWarMouseButton): Boolean;
begin
  Result := FButtons[AButton].Held;
end;

function TWarUiInput.IsButtonJustPressed(AButton: TWarMouseButton): Boolean;
begin
  Result := FButtons[AButton].JustPressed;
end;

function TWarUiInput.IsButtonJustReleased(AButton: TWarMouseButton): Boolean;
begin
  Result := FButtons[AButton].JustReleased;
end;

function TWarUiInput.IsKeyHeld(AKey: TWarKey): Boolean;
begin
  Result := FKeys[AKey].Held;
end;

function TWarUiInput.IsKeyJustPressed(AKey: TWarKey): Boolean;
begin
  Result := FKeys[AKey].JustPressed;
end;

function TWarUiInput.IsKeyJustReleased(AKey: TWarKey): Boolean;
begin
  Result := FKeys[AKey].JustReleased;
end;

function TWarUiInput.GetPositionX: Single;
begin
  Result := FPositionX;
end;

function TWarUiInput.GetPositionY: Single;
begin
  Result := FPositionY;
end;

end.
