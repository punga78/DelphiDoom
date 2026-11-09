{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the states of the actors             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.StateMachine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.StateTypes,
  DelphiDoom.Tests.Keen.GameWorld;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenStateMachine = class(TObject)
  strict private
    FWorld: TKeenTestWorld;
    procedure SetTics(ATics: Integer);
    function Actor(AState: Integer; AShape: Integer = 0): PKeenObject;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeChiamareLaFunzioneDiUnoStatoThink;
    [Test]
    procedure DovrebbeSaltareLaFunzioneConNoThink;
    [Test]
    procedure DovrebbeContareITicDiUnoStatoStep;
    [Test]
    procedure DovrebbeMuovereUnaVoltaAllaFineDiUnoStatoStep;
    [Test]
    procedure DovrebbeMuovereVersoSinistraConXdirMenoUno;
    [Test]
    procedure DovrebbeNonMuovereSenzaDirezione;
    [Test]
    procedure DovrebbeMuovereAOgniTicUnoStatoSlide;
    [Test]
    procedure DovrebbeMuovereSoloPerITicRimastiAllaFineDiUnoSlide;
    [Test]
    procedure DovrebbeChiamareLaFunzioneAOgniFrameInStepThinkESlideThink;
    [Test]
    procedure DovrebbeDareITicInPiuAlloStatoDopo;
    [Test]
    procedure DovrebbeNonSaltareUnoStatoCheNonESaltabile;
    [Test]
    procedure DovrebbeSaltareLoStatoSaltabile;
    [Test]
    procedure DovrebbeLasciareCheLaFunzioneCambiStato;
    [Test]
    procedure DovrebbeFermarsiSeLaFunzioneTogliLAttore;
    [Test]
    procedure DovrebbeTogliereLAttoreCheFinisceNellUltimoStato;
    [Test]
    procedure DovrebbeTogliereLAttoreAncheSeAvanzanoTic;
    [Test]
    procedure DovrebbeSceglierelaFormaDalLato;
    [Test]
    procedure DovrebbeLasciareLaFormaALaFunzioneSeLoStatoNonLaDa;
    [Test]
    procedure DovrebbeRendereInvisibileLaFormaMenoUno;
    [Test]
    procedure DovrebbeMuovereEClipparePerFrameChePortanoAMuoversi;
    [Test]
    procedure DovrebbeNonClipparsiSeNonSiMuoveENonCambiaForma;
    [Test]
    procedure DovrebbeClipparsiSeCambiaForma;
    [Test]
    procedure DovrebbeAzzerareIlMovimentoDelFrame;
    [Test]
    procedure DovrebbeCambiareStatoSubitoConNewState;
    [Test]
    procedure DovrebbeCalcolareIlRettangoloConNewState;
    [Test]
    procedure DovrebbeClipparsiConNewStateSeVaClippato;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

implementation

uses
  DelphiDoom.Keen.StateMachine, DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.Intf;

const
  S_WALK = 0;
  S_SECOND = 1;
  S_THINK = 2;
  S_STEPTHINK = 3;
  S_SLIDE = 4;
  S_SLIDETHINK = 5;
  S_REMOVER = 6;
  S_NONSKIP = 7;
  S_AFTER = 8;
  S_INVISIBLE = 9;
  S_NOSHAPE = 10;
  S_DIRECTIONAL = 11;
  S_SKIPPABLE = 12;
  S_LAST = 13;
  ACTION_THINK = 7;

  SHAPE_A = KEEN_STARTSPRITES + 1;
  SHAPE_B = KEEN_STARTSPRITES + 2;

function St(const AName: string; ALeft, ARight: Integer; AProgress: TKeenProgress; ATicTime, AXMove: Integer;
  AThink: Word; ANext: Integer; ASkippable: Boolean = False): TKeenStateDef;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Name := AName;
  Result.LeftShape := ALeft;
  Result.RightShape := ARight;
  Result.Progress := AProgress;
  Result.TicTime := ATicTime;
  Result.XMove := AXMove;
  Result.Think := AThink;
  Result.NextState := ANext;
  Result.Skippable := ASkippable;
end;

{ TTestKeenStateMachine }

procedure TTestKeenStateMachine.Setup;
begin
  FWorld := TKeenTestWorld.Create(40, 30, [
    St('walk', SHAPE_A, SHAPE_A, kpStep, 3, 5, KEEN_ACTION_NONE, S_SECOND),
    St('second', SHAPE_A, SHAPE_A, kpStep, 2, 0, KEEN_ACTION_NONE, S_WALK),
    St('think', SHAPE_A, SHAPE_A, kpThink, 0, 0, ACTION_THINK, S_THINK),
    St('stepthink', SHAPE_A, SHAPE_A, kpStepThink, 4, 0, ACTION_THINK, S_STEPTHINK),
    St('slide', SHAPE_A, SHAPE_A, kpSlide, 4, 3, KEEN_ACTION_NONE, S_SLIDE),
    St('slidethink', SHAPE_A, SHAPE_A, kpSlideThink, 5, 2, ACTION_THINK, S_SLIDETHINK),
    St('remover', SHAPE_A, SHAPE_A, kpStep, 1, 0, KEEN_ACTION_NONE, -1),
    St('nonskip', SHAPE_A, SHAPE_A, kpStep, 4, 0, KEEN_ACTION_NONE, S_AFTER),
    St('after', SHAPE_A, SHAPE_A, kpStep, 4, 0, KEEN_ACTION_NONE, S_AFTER),
    St('invisible', -1, -1, kpStep, 4, 0, KEEN_ACTION_NONE, S_INVISIBLE),
    St('noshape', 0, 0, kpStep, 4, 0, KEEN_ACTION_NONE, S_NOSHAPE),
    St('directional', SHAPE_A, SHAPE_B, kpStep, 4, 0, KEEN_ACTION_NONE, S_DIRECTIONAL),
    St('skippable', SHAPE_A, SHAPE_A, kpStep, 4, 0, KEEN_ACTION_NONE, S_AFTER, True),
    St('last', SHAPE_A, SHAPE_A, kpStep, 2, 0, KEEN_ACTION_NONE, S_LAST)
  ]);
  FWorld.ShowAt(2, 2);
  FWorld.Refresh.Refresh;
end;

procedure TTestKeenStateMachine.TearDown;
begin
  FWorld.Free;
end;

procedure TTestKeenStateMachine.SetTics(ATics: Integer);
begin
  // a refresh after the clock went forward: the tics of the next frame
  FWorld.Clock.TimeCount := FWorld.Clock.TimeCount + ATics;
  FWorld.Refresh.Refresh;
  Assert.AreEqual(ATics, FWorld.Refresh.Tics);
end;

function TTestKeenStateMachine.Actor(AState: Integer; AShape: Integer): PKeenObject;
begin
  Result := FWorld.AddActor(AShape, AState, 0, 0);
  Result^.X := 600;
  Result^.Y := 900;
  Result^.XDir := 1;
  Result^.State := SmallInt(AState);
end;

procedure TTestKeenStateMachine.DovrebbeChiamareLaFunzioneDiUnoStatoThink;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_THINK);
  Assert.AreEqual(0, FWorld.Machine.DoActor(LObject, 3));
  Assert.AreEqual(1, FWorld.ActionsFake.Calls.Count);
  Assert.AreEqual(Format('think %d %d', [ACTION_THINK, LObject^.Slot]), FWorld.ActionsFake.Calls[0]);
  // a state that thinks does not end by itself
  Assert.AreEqual(S_THINK, Integer(LObject^.State));
end;

procedure TTestKeenStateMachine.DovrebbeSaltareLaFunzioneConNoThink;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_THINK);
  LObject^.NoThink := 2;
  FWorld.Machine.DoActor(LObject, 1);
  FWorld.Machine.DoActor(LObject, 1);
  Assert.AreEqual(0, FWorld.ActionsFake.Calls.Count);
  Assert.AreEqual(0, Integer(LObject^.NoThink));
  FWorld.Machine.DoActor(LObject, 1);
  Assert.AreEqual(1, FWorld.ActionsFake.Calls.Count);
end;

procedure TTestKeenStateMachine.DovrebbeContareITicDiUnoStatoStep;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_WALK);
  Assert.AreEqual(0, FWorld.Machine.DoActor(LObject, 1));
  Assert.AreEqual(1, Integer(LObject^.TicCount));
  Assert.AreEqual(0, FWorld.Machine.DoActor(LObject, 1));
  Assert.AreEqual(2, Integer(LObject^.TicCount));
  Assert.AreEqual(S_WALK, Integer(LObject^.State));
  Assert.AreEqual(0, Integer(LObject^.XMove));
end;

procedure TTestKeenStateMachine.DovrebbeMuovereUnaVoltaAllaFineDiUnoStatoStep;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_WALK);
  LObject^.TicCount := 2;
  // one tic more than the state needs: it moves by its xmove once, goes to the next state, and gives 0 back
  Assert.AreEqual(0, FWorld.Machine.DoActor(LObject, 1));
  Assert.AreEqual(5, Integer(LObject^.XMove));
  Assert.AreEqual(S_SECOND, Integer(LObject^.State));
  Assert.AreEqual(0, Integer(LObject^.TicCount));
  // and three tics give two back
  LObject^.State := S_WALK;
  LObject^.TicCount := 2;
  Assert.AreEqual(2, FWorld.Machine.DoActor(LObject, 3));
end;

procedure TTestKeenStateMachine.DovrebbeMuovereVersoSinistraConXdirMenoUno;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_WALK);
  LObject^.XDir := -1;
  FWorld.Machine.DoActor(LObject, 3);
  Assert.AreEqual(-5, Integer(LObject^.XMove));
end;

procedure TTestKeenStateMachine.DovrebbeNonMuovereSenzaDirezione;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_WALK);
  LObject^.XDir := 0;
  FWorld.Machine.DoActor(LObject, 3);
  Assert.AreEqual(0, Integer(LObject^.XMove));
  Assert.AreEqual(S_SECOND, Integer(LObject^.State));
end;

procedure TTestKeenStateMachine.DovrebbeMuovereAOgniTicUnoStatoSlide;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_SLIDE);
  FWorld.Machine.DoActor(LObject, 2);
  Assert.AreEqual(6, Integer(LObject^.XMove));
  FWorld.Machine.DoActor(LObject, 1);
  Assert.AreEqual(9, Integer(LObject^.XMove));
end;

procedure TTestKeenStateMachine.DovrebbeMuovereSoloPerITicRimastiAllaFineDiUnoSlide;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_SLIDE);
  LObject^.TicCount := 3;
  // 1 tic is left in the state of 4: it slides for that one, the other 2 are the excess
  Assert.AreEqual(2, FWorld.Machine.DoActor(LObject, 3));
  Assert.AreEqual(3, Integer(LObject^.XMove));
end;

procedure TTestKeenStateMachine.DovrebbeChiamareLaFunzioneAOgniFrameInStepThinkESlideThink;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_STEPTHINK);
  FWorld.Machine.DoActor(LObject, 1);
  FWorld.Machine.DoActor(LObject, 1);
  Assert.AreEqual(2, FWorld.ActionsFake.Calls.Count);
  FWorld.ActionsFake.Calls.Clear;
  LObject := Actor(S_SLIDETHINK);
  FWorld.Machine.DoActor(LObject, 2);
  Assert.AreEqual(1, FWorld.ActionsFake.Calls.Count);
  Assert.AreEqual(4, Integer(LObject^.XMove));
  // when the state ends the function is called too
  FWorld.ActionsFake.Calls.Clear;
  LObject^.TicCount := 4;
  FWorld.Machine.DoActor(LObject, 2);
  Assert.AreEqual(1, FWorld.ActionsFake.Calls.Count);
end;

procedure TTestKeenStateMachine.DovrebbeDareITicInPiuAlloStatoDopo;
var
  LObject: PKeenObject;
begin
  SetTics(5);
  LObject := Actor(S_WALK);
  FWorld.Machine.Run(LObject);
  // walk lasts 3 tics: 2 are left for the state that follows (2 tics: not skippable, so it uses tictime - 1)
  Assert.AreEqual(S_SECOND, Integer(LObject^.State));
  Assert.AreEqual(1, Integer(LObject^.TicCount));
  Assert.AreEqual(5, Integer(LObject^.XMove));
end;

procedure TTestKeenStateMachine.DovrebbeNonSaltareUnoStatoCheNonESaltabile;
var
  LObject: PKeenObject;
begin
  SetTics(6);
  LObject := Actor(S_NONSKIP);
  FWorld.Machine.Run(LObject);
  // 6 tics: 4 end the first state, 2 are in the next, that is not ended
  Assert.AreEqual(S_AFTER, Integer(LObject^.State));
  Assert.AreEqual(2, Integer(LObject^.TicCount));
end;

procedure TTestKeenStateMachine.DovrebbeSaltareLoStatoSaltabile;
var
  LObject: PKeenObject;
begin
  SetTics(6);
  LObject := Actor(S_SKIPPABLE);
  FWorld.Machine.Run(LObject);
  Assert.AreEqual(S_AFTER, Integer(LObject^.State));
  Assert.AreEqual(2, Integer(LObject^.TicCount));
  // a state that is not skippable and has a time of 2 that gets 2 tics goes 1 and waits: 'last' loops on itself
  LObject := Actor(S_LAST);
  FWorld.Machine.Run(LObject);
  Assert.AreEqual(S_LAST, Integer(LObject^.State));
end;

procedure TTestKeenStateMachine.DovrebbeLasciareCheLaFunzioneCambiStato;
var
  LObject: PKeenObject;
begin
  FWorld.ActionsFake.OnThink.Add(ACTION_THINK,
    procedure(AObject: PKeenObject)
    begin
      AObject^.State := S_SECOND;
    end);
  LObject := Actor(S_STEPTHINK);
  LObject^.TicCount := 3;
  // the state ends, its function changes the state: the actor does not go to the next of the state it had
  FWorld.Machine.DoActor(LObject, 1);
  Assert.AreEqual(S_SECOND, Integer(LObject^.State));
end;

procedure TTestKeenStateMachine.DovrebbeFermarsiSeLaFunzioneTogliLAttore;
var
  LObject: PKeenObject;
begin
  FWorld.ActionsFake.OnThink.Add(ACTION_THINK,
    procedure(AObject: PKeenObject)
    begin
      AObject^.State := -1;
    end);
  LObject := Actor(S_STEPTHINK);
  LObject^.TicCount := 3;
  Assert.AreEqual(0, FWorld.Machine.DoActor(LObject, 5));
  Assert.AreEqual(-1, Integer(LObject^.State));
end;

procedure TTestKeenStateMachine.DovrebbeTogliereLAttoreCheFinisceNellUltimoStato;
var
  LObject: PKeenObject;
  LSlot: Integer;
begin
  SetTics(2);
  LObject := Actor(S_REMOVER);
  LSlot := LObject^.Slot;
  FWorld.Machine.Run(LObject);
  // the actor is out of the list and its place is free again
  Assert.AreEqual(2, FWorld.Objects.Count);
  Assert.AreEqual(LSlot, Integer(FWorld.Objects.GetNewObj(False)^.Slot));
end;

procedure TTestKeenStateMachine.DovrebbeTogliereLAttoreAncheSeAvanzanoTic;
var
  LObject: PKeenObject;
begin
  // a state of 1 tic with no next state that gets 5 tics: the C goes on with a state that is not there
  SetTics(5);
  LObject := Actor(S_REMOVER);
  FWorld.Machine.Run(LObject);
  Assert.AreEqual(2, FWorld.Objects.Count);
end;

procedure TTestKeenStateMachine.DovrebbeSceglierelaFormaDalLato;
var
  LObject: PKeenObject;
begin
  SetTics(2);
  LObject := Actor(S_DIRECTIONAL);
  LObject^.XDir := 1;
  FWorld.Machine.Run(LObject);
  Assert.AreEqual(SHAPE_B, Integer(LObject^.ShapeNum));
  LObject^.XDir := -1;
  FWorld.Machine.Run(LObject);
  Assert.AreEqual(SHAPE_A, Integer(LObject^.ShapeNum));
  // standing still (xdir 0) is the left shape
  LObject^.XDir := 0;
  FWorld.Machine.Run(LObject);
  Assert.AreEqual(SHAPE_A, Integer(LObject^.ShapeNum));
end;

procedure TTestKeenStateMachine.DovrebbeLasciareLaFormaALaFunzioneSeLoStatoNonLaDa;
var
  LObject: PKeenObject;
begin
  SetTics(2);
  LObject := Actor(S_NOSHAPE, SHAPE_B);
  FWorld.Machine.Run(LObject);
  Assert.AreEqual(SHAPE_B, Integer(LObject^.ShapeNum));
end;

procedure TTestKeenStateMachine.DovrebbeRendereInvisibileLaFormaMenoUno;
var
  LObject: PKeenObject;
begin
  SetTics(2);
  LObject := Actor(S_INVISIBLE, SHAPE_A);
  FWorld.Machine.Run(LObject);
  Assert.AreEqual(0, Integer(LObject^.ShapeNum));
end;

procedure TTestKeenStateMachine.DovrebbeMuovereEClipparePerFrameChePortanoAMuoversi;
var
  LObject: PKeenObject;
begin
  SetTics(3);
  LObject := Actor(S_WALK, SHAPE_A);
  LObject^.NeedToReact := False;
  FWorld.Machine.Run(LObject);
  // the move was clipped to the walls (there is none): the position changed and the actor will react
  Assert.AreEqual(605, Integer(LObject^.X));
  Assert.IsTrue(LObject^.NeedToReact);
end;

procedure TTestKeenStateMachine.DovrebbeNonClipparsiSeNonSiMuoveENonCambiaForma;
var
  LObject: PKeenObject;
begin
  SetTics(2);
  LObject := Actor(S_SECOND, SHAPE_A);
  LObject^.NeedToReact := False;
  FWorld.Machine.Run(LObject);
  Assert.IsFalse(LObject^.NeedToReact);
end;

procedure TTestKeenStateMachine.DovrebbeClipparsiSeCambiaForma;
var
  LObject: PKeenObject;
begin
  SetTics(2);
  LObject := Actor(S_DIRECTIONAL, SHAPE_A);
  LObject^.XDir := 1;
  LObject^.ShapeNum := SHAPE_A;
  LObject^.NeedToReact := False;
  FWorld.Machine.Run(LObject);
  // the shape went from A to B with no move: ClipToWalls ran
  Assert.IsTrue(LObject^.NeedToReact);
end;

procedure TTestKeenStateMachine.DovrebbeAzzerareIlMovimentoDelFrame;
var
  LObject: PKeenObject;
begin
  SetTics(2);
  LObject := Actor(S_SECOND, SHAPE_A);
  LObject^.XMove := 99;
  LObject^.YMove := -99;
  FWorld.Machine.Run(LObject);
  Assert.AreEqual(0, Integer(LObject^.XMove));
  Assert.AreEqual(0, Integer(LObject^.YMove));
end;

procedure TTestKeenStateMachine.DovrebbeCambiareStatoSubitoConNewState;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_WALK);
  LObject^.XDir := 1;
  FWorld.Machine.NewState(LObject, S_DIRECTIONAL);
  Assert.AreEqual(S_DIRECTIONAL, Integer(LObject^.State));
  Assert.AreEqual(SHAPE_B, Integer(LObject^.ShapeNum));
  FWorld.Machine.NewState(LObject, S_NOSHAPE);
  // a state with no shape leaves the one that the actor had
  Assert.AreEqual(SHAPE_B, Integer(LObject^.ShapeNum));
end;

procedure TTestKeenStateMachine.DovrebbeCalcolareIlRettangoloConNewState;
var
  LObject: PKeenObject;
begin
  LObject := Actor(S_WALK);
  LObject^.XDir := -1;
  FWorld.Machine.NewState(LObject, S_DIRECTIONAL);
  Assert.AreEqual(SHAPE_A, Integer(LObject^.ShapeNum));
  Assert.AreEqual(600, Integer(LObject^.Left));
  Assert.AreEqual(855, Integer(LObject^.Right));
  Assert.AreEqual(900, Integer(LObject^.Top));
end;

procedure TTestKeenStateMachine.DovrebbeClipparsiConNewStateSeVaClippato;
var
  LObject: PKeenObject;
begin
  // ClipToWalls adds the move each time that it runs: with the clipping on, NewState runs it twice
  LObject := Actor(S_WALK);
  LObject^.NeedToClip := True;
  LObject^.XMove := 3;
  FWorld.Machine.NewState(LObject, S_DIRECTIONAL);
  Assert.AreEqual(606, Integer(LObject^.X));
  LObject^.NeedToClip := False;
  LObject^.XMove := 3;
  FWorld.Machine.NewState(LObject, S_DIRECTIONAL);
  Assert.AreEqual(609, Integer(LObject^.X));
end;

procedure TTestKeenStateMachine.DovrebbeRifiutareIParametriNulli;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenStateMachine.Create(nil, FWorld.States, FWorld.Actions, FWorld.Mover, FWorld.Refresh);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TKeenStateMachine.Create(FWorld.Objects, FWorld.States, FWorld.Actions, nil, FWorld.Refresh);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenStateMachine);

end.
