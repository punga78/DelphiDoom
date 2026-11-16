{******************************************************************************}
{                                                                              }
{  DelphiDoom: game host library - one event for several listeners              }
{  A window has one sink: this one gives each event to every sink it was given  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameHost.EventFanOut;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf;

type
  /// <summary>
  ///   IGameHostEventSink that posts each event to its sinks, in the order they were given (the keys that are
  ///   down and the buttons of the mouse of the same window, for instance)
  /// </summary>
  TGameHostEventFanOut = class(TInterfacedObject, IGameHostEventSink)
  strict private
    FSinks: TArray<IGameHostEventSink>;
  public
    /// <summary>EArgumentNilException if one of the sinks is nil</summary>
    constructor Create(const ASinks: array of IGameHostEventSink);
    procedure Post(const AEvent: TGameHostEvent);
  end;

implementation

constructor TGameHostEventFanOut.Create(const ASinks: array of IGameHostEventSink);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FSinks, Length(ASinks));
  for LIndex := 0 to High(ASinks) do
  begin
    if not Assigned(ASinks[LIndex]) then
      raise EArgumentNilException.Create('ASinks');
    FSinks[LIndex] := ASinks[LIndex];
  end;
end;

procedure TGameHostEventFanOut.Post(const AEvent: TGameHostEvent);
var
  LSink: IGameHostEventSink;
begin
  for LSink in FSinks do
    LSink.Post(AEvent);
end;

end.
