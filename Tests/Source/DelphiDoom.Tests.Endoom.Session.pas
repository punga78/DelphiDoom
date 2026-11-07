{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ENDOOM library - the time of the end screen         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Endoom.Session;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Endoom.Intf;

type
  [TestFixture]
  [Category('endoom')]
  TTestEndoomSession = class(TObject)
  private
    FSession: IEndoomSession;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeNonContarePrimaDellAvvio;
    [Test]
    procedure DovrebbeChiedereIlDisegnoAllInizioEDopoLAvvio;
    [Test]
    procedure DovrebbeAccettareUnTastoDopoMezzoSecondo;
    [Test]
    procedure DovrebbeChiudereDopoDieciSecondi;
    [Test]
    procedure DovrebbeLampeggiareOgniMezzoSecondo;
    [Test]
    procedure DovrebbeRifiutareUnaFrequenzaTroppoBassa;
    /// <summary>
    ///   Parity: E_Ticker and E_Responder of the old e_endoom.pas, copied here as they were
    ///   (the globals are fields of the oracle), and the session give the same answers on
    ///   random series of starts, tics and keys
    /// </summary>
    [Test]
    procedure DovrebbeFareComeIlVecchioE_Ticker;
  end;

implementation

uses
  DelphiDoom.Endoom.Factory;

const
  TICRATE = 35;

type
  /// <summary>The old code, with I_Quit counted instead of closing the program</summary>
  TOldEndoomTimer = record
    e_tick: integer;
    e_ticks: integer;
    e_blink: boolean;
    e_needsupdate: boolean;
    quits: integer;
    procedure Reset;
    procedure E_Init;
    procedure E_Ticker;
    function E_Responder: boolean;
    procedure E_Drawer;
  end;

procedure TOldEndoomTimer.Reset;
begin
  e_tick := 0;
  e_ticks := 0;
  e_blink := true;
  e_needsupdate := true;
  quits := 0;
end;

procedure TOldEndoomTimer.E_Init;
begin
  e_ticks := 1;
  e_needsupdate := true;
end;

procedure TOldEndoomTimer.E_Ticker;
var
  blink: boolean;
begin
  if e_ticks > 0 then
  begin
    inc(e_ticks);
    if e_ticks > 10 * TICRATE then
      inc(quits);
    inc(e_tick);
    if e_tick >= TICRATE then
      e_tick := 0;
    blink := e_tick > TICRATE div 2;
    if blink <> e_blink then
    begin
      e_blink := not e_blink;
      e_needsupdate := true;
    end;
  end;
end;

function TOldEndoomTimer.E_Responder: boolean;
begin
  result := e_ticks > TICRATE div 2;
  if result then
    inc(quits);
end;

procedure TOldEndoomTimer.E_Drawer;
begin
  if e_needsupdate then
    e_needsupdate := false;
end;

{ TTestEndoomSession }

procedure TTestEndoomSession.Setup;
begin
  FSession := TEndoomFactory.CreateSession(TICRATE);
end;

procedure TTestEndoomSession.TearDown;
begin
  FSession := nil;
end;

procedure TTestEndoomSession.DovrebbeNonContarePrimaDellAvvio;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 1000 do
    Assert.IsFalse(FSession.Tick);
  Assert.IsFalse(FSession.AcceptsKey);
  Assert.IsTrue(FSession.IsBlinkVisible);
end;

procedure TTestEndoomSession.DovrebbeChiedereIlDisegnoAllInizioEDopoLAvvio;
begin
  Assert.IsTrue(FSession.NeedsRedraw);
  FSession.Drawn;
  Assert.IsFalse(FSession.NeedsRedraw);
  FSession.Start;
  Assert.IsTrue(FSession.NeedsRedraw);
end;

procedure TTestEndoomSession.DovrebbeAccettareUnTastoDopoMezzoSecondo;
var
  LIndex: Integer;
begin
  FSession.Start;
  // the count starts at 1: after 16 tics it is 17, half a second (35 div 2) is not over yet
  for LIndex := 1 to 16 do
    FSession.Tick;
  Assert.IsFalse(FSession.AcceptsKey);
  FSession.Tick;
  Assert.IsTrue(FSession.AcceptsKey);
end;

procedure TTestEndoomSession.DovrebbeChiudereDopoDieciSecondi;
var
  LIndex: Integer;
begin
  FSession.Start;
  for LIndex := 1 to 10 * TICRATE - 1 do
    Assert.IsFalse(FSession.Tick);
  Assert.IsTrue(FSession.Tick);
  Assert.IsTrue(FSession.Tick);
end;

procedure TTestEndoomSession.DovrebbeLampeggiareOgniMezzoSecondo;
var
  LIndex: Integer;
begin
  FSession.Start;
  FSession.Drawn;
  FSession.Tick;
  // the first tic hides the blinking cells
  Assert.IsFalse(FSession.IsBlinkVisible);
  Assert.IsTrue(FSession.NeedsRedraw);
  FSession.Drawn;
  for LIndex := 2 to 17 do
    FSession.Tick;
  Assert.IsFalse(FSession.IsBlinkVisible);
  Assert.IsFalse(FSession.NeedsRedraw);
  FSession.Tick;
  Assert.IsTrue(FSession.IsBlinkVisible);
  Assert.IsTrue(FSession.NeedsRedraw);
end;

procedure TTestEndoomSession.DovrebbeRifiutareUnaFrequenzaTroppoBassa;
begin
  Assert.WillRaise(
    procedure
    begin
      TEndoomFactory.CreateSession(1);
    end,
    EArgumentOutOfRangeException);
end;

procedure TTestEndoomSession.DovrebbeFareComeIlVecchioE_Ticker;
var
  LOld: TOldEndoomTimer;
  LSeed: UInt32;
  LStep: Integer;
  LSeries: Integer;
  LAction: Integer;
  LQuits: Integer;
begin
  LSeed := 2463534242;
  for LSeries := 1 to 20 do
  begin
    LOld.Reset;
    FSession := TEndoomFactory.CreateSession(TICRATE);
    LQuits := 0;
    for LStep := 1 to 1500 do
    begin
      LSeed := LSeed xor (LSeed shl 13);
      LSeed := LSeed xor (LSeed shr 17);
      LSeed := LSeed xor (LSeed shl 5);
      LAction := LSeed mod 100;
      if LAction < 2 then
      begin
        LOld.E_Init;
        FSession.Start;
      end
      else if LAction < 6 then
      begin
        if LOld.E_Responder then
          Assert.IsTrue(FSession.AcceptsKey)
        else
          Assert.IsFalse(FSession.AcceptsKey);
        if FSession.AcceptsKey then
          Inc(LQuits);
      end
      else if LAction < 20 then
      begin
        Assert.AreEqual(LOld.e_needsupdate, FSession.NeedsRedraw);
        LOld.E_Drawer;
        FSession.Drawn;
      end
      else
      begin
        LOld.E_Ticker;
        if FSession.Tick then
          Inc(LQuits);
      end;
      Assert.AreEqual(LOld.e_blink, FSession.IsBlinkVisible);
      Assert.AreEqual(LOld.e_needsupdate, FSession.NeedsRedraw);
      Assert.AreEqual(LOld.quits, LQuits);
    end;
  end;
end;

end.
