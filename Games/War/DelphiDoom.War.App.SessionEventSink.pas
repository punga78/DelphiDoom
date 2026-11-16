{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - where the events of the window go                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.SessionEventSink;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Events.Intf, DelphiDoom.War.App.Session;

type
  /// <summary>
  ///   The sink of the window of Warcraft32: the window is AScale times the picture of the game (320 x 200) and gives
  ///   the position of the mouse in its own pixels, the game wants it in the pixels of its picture, so the position is
  ///   divided by the scale (a whole division, as the picture is stretched by whole numbers). The events then go to the
  ///   session, which records them and gives them to the game
  /// </summary>
  TWarSessionEventSink = class(TInterfacedObject, IGameHostEventSink)
  strict private
    FSession: TWarSession;
    FScale: Integer;
  public
    /// <summary>The session is not owned and must outlive the window that posts to this sink</summary>
    constructor Create(const ASession: TWarSession; AScale: Integer);
    procedure Post(const AEvent: TGameHostEvent);
  end;

implementation

{ TWarSessionEventSink }

constructor TWarSessionEventSink.Create(const ASession: TWarSession; AScale: Integer);
begin
  inherited Create;
  if not Assigned(ASession) then
    raise EArgumentNilException.Create('ASession');
  if AScale < 1 then
    raise EArgumentOutOfRangeException.Create('AScale');
  FSession := ASession;
  FScale := AScale;
end;

procedure TWarSessionEventSink.Post(const AEvent: TGameHostEvent);
var
  LEvent: TGameHostEvent;
begin
  LEvent := AEvent;
  if AEvent.Kind in [hekMouseMotion, hekMouseDown, hekMouseUp] then
  begin
    LEvent.X := AEvent.X div FScale;
    LEvent.Y := AEvent.Y div FScale;
  end;
  FSession.Post(LEvent);
end;

end.
