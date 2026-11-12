{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the events of the game, bound after the parts     }
{  that raise them are made                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.LateEvents;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The actors tell the game what happens (a sound, the death of Keen, the keys at the end of a frame) and the
  ///   game is made of the actors: this stands for the game until it exists. A call before Bind is an
  ///   EKeenException. The link is weak: the game is owned by who composed it
  /// </summary>
  TKeenLateEvents = class(TInterfacedObject, IKeenGameEvents)
  strict private
    [weak] FTarget: IKeenGameEvents;
    function Target: IKeenGameEvents;
  public
    procedure Bind(const ATarget: IKeenGameEvents);
    procedure KillKeen;
    procedure PlaySound(ASound: Integer);
    procedure CheckKeys;
    function IsGameLoaded: Boolean;
    procedure BeginPlay;
    procedure ClearGodMode;
    function IsGodMode: Boolean;
    function IsJumpCheat: Boolean;
    procedure ShowNeedBombs;
  end;

implementation

const
  SLateNotBound = 'Keen: an event of the game was raised before the game was bound';

{ TKeenLateEvents }

procedure TKeenLateEvents.Bind(const ATarget: IKeenGameEvents);
begin
  FTarget := ATarget;
end;

function TKeenLateEvents.Target: IKeenGameEvents;
begin
  Result := FTarget;
  if not Assigned(Result) then
    raise EKeenException.Create(SLateNotBound);
end;

procedure TKeenLateEvents.KillKeen;
begin
  Target.KillKeen;
end;

procedure TKeenLateEvents.PlaySound(ASound: Integer);
begin
  Target.PlaySound(ASound);
end;

procedure TKeenLateEvents.CheckKeys;
begin
  Target.CheckKeys;
end;

function TKeenLateEvents.IsGameLoaded: Boolean;
begin
  Result := Target.IsGameLoaded;
end;

procedure TKeenLateEvents.BeginPlay;
begin
  Target.BeginPlay;
end;

procedure TKeenLateEvents.ClearGodMode;
begin
  Target.ClearGodMode;
end;

function TKeenLateEvents.IsGodMode: Boolean;
begin
  Result := Target.IsGodMode;
end;

function TKeenLateEvents.IsJumpCheat: Boolean;
begin
  Result := Target.IsJumpCheat;
end;

procedure TKeenLateEvents.ShowNeedBombs;
begin
  Target.ShowNeedBombs;
end;

end.
