{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - where the input events go                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Input.Sink;

interface

uses
  DelphiDoom.Input.Types, DelphiDoom.Input.Intf;

type
  /// <summary>The events of the library become event_t of the game and go to D_PostEvent</summary>
  TEngineInputSink = class(TInterfacedObject, IInputEventSink)
  public
    procedure Post(const AEvent: TInputEvent);
  end;

implementation

uses
  d_event,
  d_main;

{ TEngineInputSink }

procedure TEngineInputSink.Post(const AEvent: TInputEvent);
const
  LEventTypes: array[TInputEventKind] of evtype_t = (ev_keydown, ev_keyup, ev_mouse, ev_joystick);
var
  LEvent: event_t;
begin
  LEvent._type := LEventTypes[AEvent.Kind];
  LEvent.data1 := AEvent.Data1;
  LEvent.data2 := AEvent.Data2;
  LEvent.data3 := AEvent.Data3;
  D_PostEvent(@LEvent);
end;

end.
