{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the buttons of the mouse that are down       }
{  For a game that asks which buttons are held instead of reading events        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.MouseState;

interface

uses
  DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   IGameHostEventSink that remembers which buttons of the mouse are down and whether the window has the focus.
  ///   A window that loses the focus does not see the buttons go up: they are all taken as released when the
  ///   focus changes, in either direction
  /// </summary>
  TGameHostMouseState = class(TInterfacedObject, IGameHostEventSink, IGameHostMouseState)
  strict private
    FButtons: array[TGameHostMouseButton] of Boolean;
    FUnfocused: Boolean;
  public
    procedure Post(const AEvent: TGameHostEvent);
    function IsDown(AButton: TGameHostMouseButton): Boolean;
    function IsFocused: Boolean;
  end;

implementation

procedure TGameHostMouseState.Post(const AEvent: TGameHostEvent);
begin
  case AEvent.Kind of
    hekMouseDown, hekMouseUp:
      if AEvent.Button <> hmbNone then
        FButtons[AEvent.Button] := AEvent.Kind = hekMouseDown;
    hekActive:
      begin
        FUnfocused := not AEvent.Focused;
        FillChar(FButtons, SizeOf(FButtons), 0);
      end;
  end;
end;

function TGameHostMouseState.IsDown(AButton: TGameHostMouseButton): Boolean;
begin
  Result := (AButton <> hmbNone) and FButtons[AButton];
end;

function TGameHostMouseState.IsFocused: Boolean;
begin
  Result := not FUnfocused;
end;

end.
