{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the loop of the frames of a level                 }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  PlayLoop, ScrollScreen, CalcInactivate, GivePoints of kd_play.c and          }
{  CalcSingleGravity of kd_keen.c                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.PlayLoop;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.Intf, DelphiDoom.Keen.StateMachine, DelphiDoom.Keen.ActorMover;

type
  PKeenGameState = ^TKeenGameState;

  /// <summary>
  ///   A level in play. A frame reads the control of the player, makes every actor go through its state (the
  ///   asleep ones wake up when their tiles come into view, the ones far from the view go to sleep), calls the
  ///   contact function of two actors that touch, scrolls the view after Keen, lets the actors react (they post
  ///   their sprite) and refreshes the screen. The frame is the same as the one of the original: the order of
  ///   the actors in the list decides who acts first
  /// </summary>
  TKeenPlayLoop = class
  strict private
    FObjects: IKeenObjectList;
    FMachine: TKeenStateMachine;
    FMover: TKeenActorMover;
    FStates: IKeenStateTable;
    FActions: IKeenActions;
    FRefresh: IKeenRefresh;
    FInput: IKeenInput;
    FRandom: IKeenRandom;
    FEvents: IKeenGameEvents;
    FGameState: TKeenGameState;
    FPlayState: TKeenExit;
    FControl: TKeenControlInfo;
    FButton0Held: Boolean;
    FButton1Held: Boolean;
    FPlummet: Boolean;
    FSingleGravity: Integer;
    FOriginXTileMax: Integer;
    FOriginYTileMax: Integer;
    FInactivateLeft: Integer;
    FInactivateRight: Integer;
    FInactivateTop: Integer;
    FInactivateBottom: Integer;
    function GetGameState: PKeenGameState;
    procedure ThinkAndWake;
    procedure CheckContacts;
    procedure ReactAll;
  public
    constructor Create(const AObjects: IKeenObjectList; AMachine: TKeenStateMachine; AMover: TKeenActorMover;
      const AStates: IKeenStateTable; const AActions: IKeenActions; const ARefresh: IKeenRefresh;
      const AInput: IKeenInput; const ARandom: IKeenRandom; const AEvents: IKeenGameEvents);
    /// <summary>CalcInactivate: the limits, in tiles, outside of which an actor goes to sleep</summary>
    procedure CalcInactivate;
    /// <summary>ScrollScreen: the level ends if Keen leaves the map, Keen dies if he falls off it, and the view follows him</summary>
    procedure ScrollScreen;
    /// <summary>GivePoints: an extra life at 20000, 40000, 80000...</summary>
    procedure GivePoints(APoints: Integer);
    /// <summary>
    ///   CalcSingleGravity: how far a falling actor goes in the tics of the frame; gravity only adds on the odd
    ///   tics because of the little precision of the numbers
    /// </summary>
    procedure CalcSingleGravity;
    /// <summary>One turn of the do loop of PlayLoop, up to the refresh and CheckKeys</summary>
    procedure RunFrame;
    /// <summary>PlayLoop: frames until the level ends (PlayState) or a game is loaded</summary>
    procedure Run;
    /// <summary>The state of the game that a saved game keeps</summary>
    property GameState: PKeenGameState read GetGameState;
    property PlayState: TKeenExit read FPlayState write FPlayState;
    /// <summary>c: the control of the first player, as read at the start of the frame</summary>
    property Control: TKeenControlInfo read FControl;
    property Button0Held: Boolean read FButton0Held write FButton0Held;
    property Button1Held: Boolean read FButton1Held write FButton1Held;
    /// <summary>True when Keen has already been killed for falling off the world</summary>
    property Plummet: Boolean read FPlummet write FPlummet;
    property SingleGravity: Integer read FSingleGravity;
    property OriginXTileMax: Integer read FOriginXTileMax;
    property OriginYTileMax: Integer read FOriginYTileMax;
    property InactivateLeft: Integer read FInactivateLeft;
    property InactivateRight: Integer read FInactivateRight;
    property InactivateTop: Integer read FInactivateTop;
    property InactivateBottom: Integer read FInactivateBottom;
  end;

implementation

uses
  DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.AudioIds, DelphiDoom.Keen.Arithmetic;

{ TKeenPlayLoop }

constructor TKeenPlayLoop.Create(const AObjects: IKeenObjectList; AMachine: TKeenStateMachine; AMover: TKeenActorMover;
  const AStates: IKeenStateTable; const AActions: IKeenActions; const ARefresh: IKeenRefresh;
  const AInput: IKeenInput; const ARandom: IKeenRandom; const AEvents: IKeenGameEvents);
begin
  inherited Create;
  if not Assigned(AObjects) then
    raise EArgumentNilException.Create('AObjects');
  if not Assigned(AMachine) then
    raise EArgumentNilException.Create('AMachine');
  if not Assigned(AMover) then
    raise EArgumentNilException.Create('AMover');
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  if not Assigned(AActions) then
    raise EArgumentNilException.Create('AActions');
  if not Assigned(ARefresh) then
    raise EArgumentNilException.Create('ARefresh');
  if not Assigned(AInput) then
    raise EArgumentNilException.Create('AInput');
  if not Assigned(ARandom) then
    raise EArgumentNilException.Create('ARandom');
  if not Assigned(AEvents) then
    raise EArgumentNilException.Create('AEvents');
  FObjects := AObjects;
  FMachine := AMachine;
  FMover := AMover;
  FStates := AStates;
  FActions := AActions;
  FRefresh := ARefresh;
  FInput := AInput;
  FRandom := ARandom;
  FEvents := AEvents;
  FPlayState := keNotDone;
end;

function TKeenPlayLoop.GetGameState: PKeenGameState;
begin
  Result := @FGameState;
end;

procedure TKeenPlayLoop.CalcInactivate;
begin
  FOriginXTileMax := FRefresh.OriginXTile + KEEN_PORTTILESWIDE - 1;
  FOriginYTileMax := FRefresh.OriginYTile + KEEN_PORTTILESHIGH - 1;
  FInactivateLeft := FRefresh.OriginXTile - KEEN_INACTIVATEDIST;
  if FInactivateLeft < 0 then
    FInactivateLeft := 0;
  FInactivateRight := FOriginXTileMax + KEEN_INACTIVATEDIST;
  FInactivateTop := FRefresh.OriginYTile - KEEN_INACTIVATEDIST;
  if FInactivateTop < 0 then
    FInactivateTop := 0;
  FInactivateBottom := FOriginYTileMax + KEEN_INACTIVATEDIST;
end;

procedure TKeenPlayLoop.ScrollScreen;
var
  LPlayer: PKeenObject;
  LXScroll: Integer;
  LYScroll: Integer;
begin
  LPlayer := FObjects.Player;
  // walked off the edge of the map?
  if (LPlayer^.Left < FRefresh.OriginXMin) or
    (LPlayer^.Right > TKeenArithmetic.ToWord(FRefresh.OriginXMax + 20 * KEEN_TILEGLOBAL)) then
  begin
    FPlayState := keLevelComplete;
    Exit;
  end;
  // fallen off the bottom of the world?
  if (not FPlummet) and (LPlayer^.Bottom > TKeenArithmetic.ToWord(FRefresh.OriginYMax + 13 * KEEN_TILEGLOBAL)) then
  begin
    FEvents.ClearGodMode;
    FPlummet := True;
    FEvents.KillKeen;
    Exit;
  end;
  // the positions are unsigned: the differences wrap at 16 bits and are read as an int
  if LPlayer^.X < TKeenArithmetic.ToWord(FRefresh.OriginXGlobal + KEEN_SCROLLWEST) then
    LXScroll := TKeenArithmetic.ToInt16(LPlayer^.X - (FRefresh.OriginXGlobal + KEEN_SCROLLWEST))
  else if LPlayer^.X > TKeenArithmetic.ToWord(FRefresh.OriginXGlobal + KEEN_SCROLLEAST) then
    LXScroll := TKeenArithmetic.ToInt16(LPlayer^.X - (FRefresh.OriginXGlobal + KEEN_SCROLLEAST))
  else
    LXScroll := 0;
  if LPlayer^.Y < TKeenArithmetic.ToWord(FRefresh.OriginYGlobal + KEEN_SCROLLNORTH) then
    LYScroll := TKeenArithmetic.ToInt16(LPlayer^.Y - (FRefresh.OriginYGlobal + KEEN_SCROLLNORTH))
  else if LPlayer^.Y > TKeenArithmetic.ToWord(FRefresh.OriginYGlobal + KEEN_SCROLLSOUTH) then
    LYScroll := TKeenArithmetic.ToInt16(LPlayer^.Y - (FRefresh.OriginYGlobal + KEEN_SCROLLSOUTH))
  else
    LYScroll := 0;
  if (LXScroll <> 0) or (LYScroll <> 0) then
  begin
    FRefresh.Scroll(LXScroll, LYScroll);
    CalcInactivate;
    FObjects.ScoreObj^.NeedToReact := True;
  end;
end;

procedure TKeenPlayLoop.GivePoints(APoints: Integer);
begin
  FGameState.Score := FGameState.Score + APoints;
  if FGameState.Score >= FGameState.NextExtra then
  begin
    FEvents.PlaySound(KEEN_SND_EXTRAKEENSND);
    Inc(FGameState.Lives);
    FGameState.NextExtra := FGameState.NextExtra * 2;
  end;
end;

procedure TKeenPlayLoop.CalcSingleGravity;
var
  LSpeed: Integer;
  LTime: Integer;
begin
  LSpeed := 0;
  FSingleGravity := 0;
  LTime := FRefresh.LastTimeCount - FRefresh.Tics;
  while LTime < FRefresh.LastTimeCount do
  begin
    if (LTime and 1) <> 0 then
    begin
      Inc(LSpeed, KEEN_ACCGRAVITY);
      if LSpeed > KEEN_SPDMAXY then
        LSpeed := KEEN_SPDMAXY;
    end;
    Inc(FSingleGravity, LSpeed);
    Inc(LTime);
  end;
  FSingleGravity := FSingleGravity div 2;
end;

procedure TKeenPlayLoop.ThinkAndWake;
var
  LObject: PKeenObject;
begin
  LObject := FObjects.First;
  while Assigned(LObject) do
  begin
    // an actor that is asleep wakes up when any of its tiles is in the view
    if (LObject^.Active = kaNo) and (Integer(LObject^.TileRight) >= FRefresh.OriginXTile) and
      (Integer(LObject^.TileLeft) <= FOriginXTileMax) and (Integer(LObject^.TileTop) <= FOriginYTileMax) and
      (Integer(LObject^.TileBottom) >= FRefresh.OriginYTile) then
    begin
      LObject^.NeedToReact := True;
      LObject^.Active := kaYes;
    end;
    if LObject^.Active <> kaNo then
      FMachine.Run(LObject);
    // an actor far from the view goes to sleep (a removable one, a shot, goes away)
    if (LObject^.Active in [kaYes, kaRemovable]) and
      ((Integer(LObject^.TileRight) < FInactivateLeft) or (Integer(LObject^.TileLeft) > FInactivateRight) or
       (Integer(LObject^.TileTop) > FInactivateBottom) or (Integer(LObject^.TileBottom) < FInactivateTop)) then
    begin
      if LObject^.Active = kaRemovable then
        FObjects.RemoveObj(LObject) // a temporary thing: a shot
      else if FRandom.RndT < FRefresh.Tics then
      begin
        // not all at once: they go to sleep at a random distance
        FRefresh.RemoveSprite(LObject^.Sprite);
        LObject^.Active := kaNo;
      end;
    end;
    LObject := FObjects.NextOf(LObject);
  end;
end;

procedure TKeenPlayLoop.CheckContacts;
var
  LObject: PKeenObject;
  LCheck: PKeenObject;
begin
  LObject := FObjects.First;
  while Assigned(LObject) do
  begin
    if LObject^.Active <> kaNo then
    begin
      LCheck := FObjects.NextOf(LObject);
      while Assigned(LCheck) do
      begin
        if (LCheck^.Active <> kaNo) and (LObject^.Right > LCheck^.Left) and (LObject^.Left < LCheck^.Right) and
          (LObject^.Top < LCheck^.Bottom) and (LObject^.Bottom > LCheck^.Top) then
        begin
          if (LObject^.State >= 0) and (FStates[LObject^.State].Contact <> KEEN_ACTION_NONE) then
            FActions.Contact(FStates[LObject^.State].Contact, LObject, LCheck);
          if (LCheck^.State >= 0) and (FStates[LCheck^.State].Contact <> KEEN_ACTION_NONE) then
            FActions.Contact(FStates[LCheck^.State].Contact, LCheck, LObject);
          if LObject^.ObClass = kcNothing then
            Break; // the contact removed the actor
        end;
        LCheck := FObjects.NextOf(LCheck);
      end;
    end;
    LObject := FObjects.NextOf(LObject);
  end;
end;

procedure TKeenPlayLoop.ReactAll;
var
  LObject: PKeenObject;
begin
  LObject := FObjects.First;
  while Assigned(LObject) do
  begin
    if LObject^.NeedToReact and (LObject^.State >= 0) and (FStates[LObject^.State].React <> KEEN_ACTION_NONE) then
    begin
      LObject^.NeedToReact := False;
      FActions.React(FStates[LObject^.State].React, LObject);
    end;
    LObject := FObjects.NextOf(LObject);
  end;
end;

procedure TKeenPlayLoop.RunFrame;
begin
  CalcSingleGravity;
  // the input of the player
  FControl := FInput.ReadControl(0);
  if not FControl.Button0 then
    FButton0Held := False;
  if not FControl.Button1 then
    FButton1Held := False;
  // go through the states and propose the movements
  ThinkAndWake;
  // the contacts between the actors
  CheckContacts;
  ScrollScreen;
  // react to what happened and post the sprites to the refresh manager
  ReactAll;
  // show the screen and take the number of tics that all this lasted (for the next frame)
  FRefresh.Refresh;
  FEvents.CheckKeys;
end;

procedure TKeenPlayLoop.Run;
begin
  FButton0Held := False;
  FButton1Held := False;
  FPlayState := keNotDone;
  FPlummet := False;
  FEvents.BeginPlay;
  repeat
    RunFrame;
  until FEvents.IsGameLoaded or (FPlayState <> keNotDone);
end;

end.
