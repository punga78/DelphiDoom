{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the pauseMode option and of the options saved when     }
{  the game ends (Game::run of OpenXcom)                                       }
{                                                                              }
{  This program is free software; you can redistribute it and/or modify it     }
{  under the terms of the GNU General Public License, version 3 or later.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.GamePause;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.OptionsStore.Intf, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Game,
  DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>A state that counts its turns</summary>
  TThinkingState = class(TXcomState)
  public
    Thinks: Integer;
    procedure Think; override;
  end;

  /// <summary>A store that remembers the size of the display it was asked to save</summary>
  TFakeOptionsStore = class(TInterfacedObject, IXcomOptionsStore)
  public
    Saves: Integer;
    SavedWidth: Integer;
    SavedHeight: Integer;
    procedure Load(AOptions: TXcomOptions);
    procedure Save(AOptions: TXcomOptions);
  end;

  [TestFixture]
  [Category('XcomEngine')]
  TTestXcomGamePause = class
  strict private
    FWorld: TTestWorld;
    FState: TThinkingState;
    procedure Focus(AHasFocus, AMinimized: Boolean);
    function ThinksIn(AMilliseconds: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [TestCase('focus, mode 0', '0,True,False,0')]
    [TestCase('no focus, mode 0', '0,False,False,0')]
    [TestCase('no focus, mode 1', '1,False,False,0')]
    [TestCase('no focus, mode 2', '2,False,False,1')]
    [TestCase('no focus, mode 3', '3,False,False,2')]
    [TestCase('minimized, mode 0', '0,False,True,1')]
    [TestCase('minimized, mode 1', '1,False,True,2')]
    [TestCase('minimized, mode 3', '3,False,True,2')]
    procedure DovrebbeRallentareOFermareSecondoPauseMode(AMode: Integer; AHasFocus, AMinimized: Boolean;
      AExpected: Integer);
    [Test]
    procedure DovrebbeFermareIlPensieroInPausaERiprendereColFuoco;
    [Test]
    procedure DovrebbeAspettareCentoMillisecondiQuandoNonCorre;
    [Test]
    procedure DovrebbeSalvareLeOpzioniConLaMisuraDellaFinestraRidimensionata;
    [Test]
    procedure NonDovrebbeFareNullaSenzaDeposito;
  end;

implementation

{ TThinkingState }

procedure TThinkingState.Think;
begin
  inherited Think;
  Inc(Thinks);
end;

{ TFakeOptionsStore }

procedure TFakeOptionsStore.Load(AOptions: TXcomOptions);
begin
end;

procedure TFakeOptionsStore.Save(AOptions: TXcomOptions);
begin
  Inc(Saves);
  SavedWidth := AOptions.DisplayWidth;
  SavedHeight := AOptions.DisplayHeight;
end;

{ TTestXcomGamePause }

procedure TTestXcomGamePause.Setup;
begin
  FWorld := TTestWorld.Create;
  FState := TThinkingState.Create(FWorld.Game);
  FWorld.Game.PushState(FState);
  FWorld.Wait(50);
end;

procedure TTestXcomGamePause.TearDown;
begin
  FWorld.Game.SetOptionsStore(nil);
  FWorld.Free;
end;

procedure TTestXcomGamePause.Focus(AHasFocus, AMinimized: Boolean);
var
  LEvent: TXcomInputEvent;
begin
  LEvent := TXcomInputEvent.Make(ekActive);
  LEvent.Key := Ord(AHasFocus);
  LEvent.Button := Ord(AMinimized);
  FWorld.Events.Enqueue(LEvent);
  FWorld.Game.RunFrame;
end;

function TTestXcomGamePause.ThinksIn(AMilliseconds: Integer): Integer;
var
  LBefore: Integer;
begin
  LBefore := FState.Thinks;
  FWorld.Wait(AMilliseconds);
  Result := FState.Thinks - LBefore;
end;

procedure TTestXcomGamePause.DovrebbeRallentareOFermareSecondoPauseMode(AMode: Integer; AHasFocus,
  AMinimized: Boolean; AExpected: Integer);
begin
  FWorld.Game.Options.SetValue('pauseMode', AMode);
  Focus(AHasFocus, AMinimized);
  Assert.AreEqual(AExpected, Integer(Ord(FWorld.Game.RunningState)));
end;

procedure TTestXcomGamePause.DovrebbeFermareIlPensieroInPausaERiprendereColFuoco;
begin
  FWorld.Game.Options.SetValue('pauseMode', 3);
  Focus(False, False);
  Assert.AreEqual(0, ThinksIn(100), 'in pausa lo stato non pensa');
  Focus(True, False);
  Assert.IsTrue(ThinksIn(100) > 0, 'col fuoco il gioco riprende');
end;

procedure TTestXcomGamePause.DovrebbeAspettareCentoMillisecondiQuandoNonCorre;
begin
  Assert.AreEqual(1, FWorld.Game.FrameDelay);
  FWorld.Game.Options.SetValue('pauseMode', 2);
  Focus(False, False);
  Assert.AreEqual(100, FWorld.Game.FrameDelay);
end;

procedure TTestXcomGamePause.DovrebbeSalvareLeOpzioniConLaMisuraDellaFinestraRidimensionata;
var
  LStore: TFakeOptionsStore;
  LStoreRef: IXcomOptionsStore;
  LEvent: TXcomInputEvent;
begin
  LStore := TFakeOptionsStore.Create;
  LStoreRef := LStore;
  FWorld.Game.SetOptionsStore(LStoreRef);
  FWorld.Game.Options.AllowResize := True;
  LEvent := TXcomInputEvent.Make(ekResize);
  LEvent.X := 800;
  LEvent.Y := 500;
  FWorld.Events.Enqueue(LEvent);
  FWorld.Game.RunFrame;
  FWorld.Game.SaveOptions;
  Assert.AreEqual(1, LStore.Saves);
  Assert.AreEqual(800, LStore.SavedWidth);
  Assert.AreEqual(500, LStore.SavedHeight);
end;

procedure TTestXcomGamePause.NonDovrebbeFareNullaSenzaDeposito;
begin
  FWorld.Game.SetOptionsStore(nil);
  FWorld.Game.SaveOptions;
  Assert.IsFalse(FWorld.Game.IsQuitting, 'il gioco senza deposito non salva e non si ferma');
end;

end.
