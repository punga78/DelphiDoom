{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the functions of the states, bound after the      }
{  parts that call them are made                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.LateActions;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The state machine calls the functions of the states, and the functions call the state machine back (a
  ///   think function gives an actor a new state): one of the two has to be made before the other exists. This
  ///   stands for the functions until they are made; Bind gives it the real ones. A call before that is an
  ///   EKeenException. The link is weak: the real functions are owned by who composed the game
  /// </summary>
  TKeenLateActions = class(TInterfacedObject, IKeenActions)
  strict private
    [weak] FTarget: IKeenActions;
    function Target: IKeenActions;
  public
    procedure Bind(const ATarget: IKeenActions);
    procedure Think(AAction: Word; AObject: PKeenObject);
    procedure Contact(AAction: Word; AObject, AOther: PKeenObject);
    procedure React(AAction: Word; AObject: PKeenObject);
  end;

implementation

const
  SLateNotBound = 'Keen: the functions of the states were called before they were bound';

{ TKeenLateActions }

procedure TKeenLateActions.Bind(const ATarget: IKeenActions);
begin
  FTarget := ATarget;
end;

function TKeenLateActions.Target: IKeenActions;
begin
  Result := FTarget;
  if not Assigned(Result) then
    raise EKeenException.Create(SLateNotBound);
end;

procedure TKeenLateActions.Think(AAction: Word; AObject: PKeenObject);
begin
  Target.Think(AAction, AObject);
end;

procedure TKeenLateActions.Contact(AAction: Word; AObject, AOther: PKeenObject);
begin
  Target.Contact(AAction, AObject, AOther);
end;

procedure TKeenLateActions.React(AAction: Word; AObject: PKeenObject);
begin
  Target.React(AAction, AObject);
end;

end.
