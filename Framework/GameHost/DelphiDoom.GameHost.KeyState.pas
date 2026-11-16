{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - the keys that are down                       }
{  For a game that asks which keys are held instead of reading events           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.KeyState;

interface

uses
  DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   IGameHostEventSink that remembers which virtual keys are down. A window that loses the focus does not see
  ///   the keys go up: they are all taken as released then
  /// </summary>
  TGameHostKeyState = class(TInterfacedObject, IGameHostEventSink, IGameHostKeyState, IGameHostKeyPresses)
  strict private
    FKeys: array[0..255] of Boolean;
    FPresses: array[0..255] of Cardinal;
  public
    procedure Post(const AEvent: TGameHostEvent);
    function IsDown(AVirtualKey: Integer): Boolean;
    function PressCount(AVirtualKey: Integer): Cardinal;
  end;

implementation

procedure TGameHostKeyState.Post(const AEvent: TGameHostEvent);
begin
  case AEvent.Kind of
    hekKeyDown, hekKeyUp:
      if (AEvent.VirtualKey >= Low(FKeys)) and (AEvent.VirtualKey <= High(FKeys)) then
      begin
        // a held key repeats its key down: that is one press
        if (AEvent.Kind = hekKeyDown) and not FKeys[AEvent.VirtualKey] then
          FPresses[AEvent.VirtualKey] := FPresses[AEvent.VirtualKey] + 1;
        FKeys[AEvent.VirtualKey] := AEvent.Kind = hekKeyDown;
      end;
    hekActive:
      if not AEvent.Focused then
        FillChar(FKeys, SizeOf(FKeys), 0);
  end;
end;

function TGameHostKeyState.IsDown(AVirtualKey: Integer): Boolean;
begin
  Result := (AVirtualKey >= Low(FKeys)) and (AVirtualKey <= High(FKeys)) and FKeys[AVirtualKey];
end;

function TGameHostKeyState.PressCount(AVirtualKey: Integer): Cardinal;
begin
  if (AVirtualKey >= Low(FPresses)) and (AVirtualKey <= High(FPresses)) then
    Result := FPresses[AVirtualKey]
  else
    Result := 0;
end;

end.
