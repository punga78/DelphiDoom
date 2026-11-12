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
  TGameHostKeyState = class(TInterfacedObject, IGameHostEventSink, IGameHostKeyState)
  strict private
    FKeys: array[0..255] of Boolean;
  public
    procedure Post(const AEvent: TGameHostEvent);
    function IsDown(AVirtualKey: Integer): Boolean;
  end;

implementation

procedure TGameHostKeyState.Post(const AEvent: TGameHostEvent);
begin
  case AEvent.Kind of
    hekKeyDown, hekKeyUp:
      if (AEvent.VirtualKey >= Low(FKeys)) and (AEvent.VirtualKey <= High(FKeys)) then
        FKeys[AEvent.VirtualKey] := AEvent.Kind = hekKeyDown;
    hekActive:
      if not AEvent.Focused then
        FillChar(FKeys, SizeOf(FKeys), 0);
  end;
end;

function TGameHostKeyState.IsDown(AVirtualKey: Integer): Boolean;
begin
  Result := (AVirtualKey >= Low(FKeys)) and (AVirtualKey <= High(FKeys)) and FKeys[AVirtualKey];
end;

end.
