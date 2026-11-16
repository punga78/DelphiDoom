{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the states of the actors                          }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  DoActor, StateMachine and NewState of kd_play.c                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.StateMachine;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.StateTypes,
  DelphiDoom.Keen.Intf, DelphiDoom.Keen.ActorMover;

type
  /// <summary>
  ///   Moves an actor through its states for the tics of a frame: the state says how long it lasts, how it
  ///   moves the actor in that time and which function it calls. A state that ends passes the tics that are left
  ///   to the next, so an actor does not lose time when the frame is long
  /// </summary>
  TKeenStateMachine = class
  strict private
    FObjects: IKeenObjectList;
    FStates: IKeenStateTable;
    FActions: IKeenActions;
    FMover: TKeenActorMover;
    FRefresh: IKeenRefresh;
    procedure RunThink(AObject: PKeenObject; const AState: TKeenStateDef);
    procedure AddMove(AObject: PKeenObject; const AState: TKeenStateDef; ATics: Integer);
    procedure ChooseShape(AObject: PKeenObject; const AState: TKeenStateDef);
  public
    constructor Create(const AObjects: IKeenObjectList; const AStates: IKeenStateTable; const AActions: IKeenActions;
      AMover: TKeenActorMover; const ARefresh: IKeenRefresh);
    /// <summary>
    ///   DoActor: the actor goes through ATics of its state. It gives back the tics that went past the end of
    ///   the state (0 if the state goes on or the actor was removed)
    /// </summary>
    function DoActor(AObject: PKeenObject; ATics: Integer): Integer;
    /// <summary>StateMachine: the actor goes through the tics of the frame, changes state if it has to, and is clipped to the walls if it moved or changed shape</summary>
    procedure Run(AObject: PKeenObject);
    /// <summary>NewState: the state of the actor changes at once (and its hit rectangle is calculated)</summary>
    procedure NewState(AObject: PKeenObject; AState: Integer);
  end;

implementation

uses
  DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.Arithmetic;

{ TKeenStateMachine }

constructor TKeenStateMachine.Create(const AObjects: IKeenObjectList; const AStates: IKeenStateTable;
  const AActions: IKeenActions; AMover: TKeenActorMover; const ARefresh: IKeenRefresh);
begin
  inherited Create;
  if not Assigned(AObjects) then
    raise EArgumentNilException.Create('AObjects');
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(AActions) then
    raise EArgumentNilException.Create('AActions');
  if not Assigned(AMover) then
    raise EArgumentNilException.Create('AMover');
  if not Assigned(ARefresh) then
    raise EArgumentNilException.Create('ARefresh');
  FObjects := AObjects;
  FStates := AStates;
  FActions := AActions;
  FMover := AMover;
  FRefresh := ARefresh;
end;

procedure TKeenStateMachine.RunThink(AObject: PKeenObject; const AState: TKeenStateDef);
begin
  if AState.Think = KEEN_ACTION_NONE then
    Exit;
  // an actor can be told not to think for some frames
  if AObject^.NoThink <> 0 then
    Dec(AObject^.NoThink)
  else
    FActions.Think(AState.Think, AObject);
end;

procedure TKeenStateMachine.AddMove(AObject: PKeenObject; const AState: TKeenStateDef; ATics: Integer);
begin
  // the actor moves toward where it looks: xdir 1 is right, -1 is left
  if AObject^.XDir <> 0 then
    if AObject^.XDir = 1 then
      AObject^.XMove := TKeenArithmetic.ToInt16(AObject^.XMove + ATics * AState.XMove)
    else
      AObject^.XMove := TKeenArithmetic.ToInt16(AObject^.XMove - ATics * AState.XMove);
  if AObject^.YDir <> 0 then
    if AObject^.YDir = 1 then
      AObject^.YMove := TKeenArithmetic.ToInt16(AObject^.YMove + ATics * AState.YMove)
    else
      AObject^.YMove := TKeenArithmetic.ToInt16(AObject^.YMove - ATics * AState.YMove);
end;

function TKeenStateMachine.DoActor(AObject: PKeenObject; ATics: Integer): Integer;
var
  LStateIndex: Integer;
  LState: TKeenStateDef;
  LNewTics: Integer;
  LMoveTics: Integer;
begin
  LStateIndex := AObject^.State;
  LState := FStates[LStateIndex];
  if LState.Progress = kpThink then
  begin
    RunThink(AObject, LState);
    Exit(0);
  end;
  LNewTics := AObject^.TicCount + ATics;
  if (LNewTics < LState.TicTime) or (LState.TicTime = 0) then
  begin
    AObject^.TicCount := TKeenArithmetic.ToInt16(LNewTics);
    if LState.Progress in [kpSlide, kpSlideThink] then
      AddMove(AObject, LState, ATics);
    if LState.Progress in [kpSlideThink, kpStepThink] then
      RunThink(AObject, LState);
    Exit(0);
  end;
  LMoveTics := LState.TicTime - AObject^.TicCount;
  Result := LNewTics - LState.TicTime;
  AObject^.TicCount := 0;
  if LState.Progress in [kpSlide, kpSlideThink] then
    AddMove(AObject, LState, LMoveTics)
  else
    // a state that steps moves the actor once, by its xmove and ymove
    AddMove(AObject, LState, 1);
  RunThink(AObject, LState);
  if AObject^.State = LStateIndex then
    AObject^.State := LState.NextState // go to the next state
  else if AObject^.State < 0 then
    Result := 0; // the actor removed itself
end;

procedure TKeenStateMachine.ChooseShape(AObject: PKeenObject; const AState: TKeenStateDef);
begin
  // a state with no shape (0) leaves it to its think function
  if AState.RightShape <> 0 then
  begin
    if AObject^.XDir > 0 then
      AObject^.ShapeNum := Word(AState.RightShape)
    else
      AObject^.ShapeNum := Word(AState.LeftShape);
  end;
end;

procedure TKeenStateMachine.Run(AObject: PKeenObject);
var
  LExcessTics: Integer;
  LOldShape: Word;
  LStateIndex: Integer;
  LState: TKeenStateDef;
begin
  AObject^.XMove := 0;
  AObject^.YMove := 0;
  LOldShape := AObject^.ShapeNum;
  LStateIndex := AObject^.State;
  LExcessTics := DoActor(AObject, FRefresh.Tics);
  if AObject^.State <> LStateIndex then
  begin
    // the new state starts at 0 and the tics that are left are used in it
    AObject^.TicCount := 0;
    LStateIndex := AObject^.State;
  end;
  // a state that ends with no next state removes the actor: the C went on reading the state that is not there
  // when tics were left, here the actor is removed
  while (LExcessTics <> 0) and (LStateIndex >= 0) do
  begin
    // passed through to the next state
    LState := FStates[LStateIndex];
    if (not LState.Skippable) and (LExcessTics >= LState.TicTime) then
      LExcessTics := DoActor(AObject, LState.TicTime - 1)
    else
      LExcessTics := DoActor(AObject, LExcessTics);
    if AObject^.State <> LStateIndex then
    begin
      AObject^.TicCount := 0;
      LStateIndex := AObject^.State;
    end;
  end;
  if LStateIndex < 0 then
  begin
    // the actor removed itself
    FObjects.RemoveObj(AObject);
    Exit;
  end;
  LState := FStates[LStateIndex];
  ChooseShape(AObject, LState);
  if AObject^.ShapeNum = Word(-1) then
    AObject^.ShapeNum := 0; // invisible this time
  // the actor moved or changed shape: it is clipped to the walls, to a tile of movement at most
  if (AObject^.XMove <> 0) or (AObject^.YMove <> 0) or (AObject^.ShapeNum <> LOldShape) then
    FMover.ClipToWalls(AObject);
end;

procedure TKeenStateMachine.NewState(AObject: PKeenObject; AState: Integer);
var
  LNeedToClip: Boolean;
begin
  AObject^.State := AState;
  ChooseShape(AObject, FStates[AState]);
  LNeedToClip := AObject^.NeedToClip;
  AObject^.NeedToClip := False;
  FMover.ClipToWalls(AObject); // only to calculate the values
  AObject^.NeedToClip := LNeedToClip;
  if AObject^.NeedToClip then
    FMover.ClipToWalls(AObject);
end;

end.
