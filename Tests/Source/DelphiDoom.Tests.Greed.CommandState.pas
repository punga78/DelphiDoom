unit DelphiDoom.Tests.Greed.CommandState;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState,
  DelphiDoom.Tests.Greed.GameFakes;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedCommandState = class(TObject)
  strict private
    FSource: TFakeCommandSource;
    FSourceIntf: IGreedCommandSource;
    FState: TGreedCommandState;
    FStateIntf: IInterface;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure NonDovrebbeCambiareFinoAllaLettura;
    [Test]
    procedure DovrebbeDareFrescoIlComandoAppenaPremuto;
    [Test]
    procedure DovrebbeTenereMangiatoIlComandoFinoAlRilascio;
    [Test]
    procedure DovrebbeDareUnCarattereUnaVolta;
    [Test]
    procedure DovrebbePerdereIlCarattereNonPreso;
    [Test]
    procedure DovrebbeSollevareSenzaOrigine;
  end;

implementation

procedure TTestGreedCommandState.Setup;
begin
  FSource := TFakeCommandSource.Create;
  FSourceIntf := FSource;
  FState := TGreedCommandState.Create(FSourceIntf);
  FStateIntf := FState;
end;

procedure TTestGreedCommandState.TearDown;
begin
  FStateIntf := nil;
  FSourceIntf := nil;
end;

procedure TTestGreedCommandState.NonDovrebbeCambiareFinoAllaLettura;
begin
  FSource.Pressed := [gcFire];
  Assert.IsFalse(FState.IsDown(gcFire), 'the keys are read on the odd tics only');
  FState.ReadControls;
  Assert.IsTrue(FState.IsDown(gcFire));
  FSource.Pressed := [];
  Assert.IsTrue(FState.IsDown(gcFire), 'still the reading before');
  FState.ReadControls;
  Assert.IsFalse(FState.IsDown(gcFire));
end;

procedure TTestGreedCommandState.DovrebbeDareFrescoIlComandoAppenaPremuto;
begin
  FSource.Pressed := [gcMenu];
  FState.ReadControls;
  Assert.IsTrue(FState.IsFresh(gcMenu));
  FState.ReadControls;
  Assert.IsTrue(FState.IsFresh(gcMenu), 'it stays fresh until it is eaten');
end;

procedure TTestGreedCommandState.DovrebbeTenereMangiatoIlComandoFinoAlRilascio;
begin
  FSource.Pressed := [gcPause];
  FState.ReadControls;
  FState.Eat(gcPause);
  Assert.IsFalse(FState.IsFresh(gcPause));
  Assert.IsTrue(FState.IsDown(gcPause), 'eaten is still down');
  FState.ReadControls;
  Assert.IsFalse(FState.IsFresh(gcPause));
  FSource.Pressed := [];
  FState.ReadControls;
  FSource.Pressed := [gcPause];
  FState.ReadControls;
  Assert.IsTrue(FState.IsFresh(gcPause), 'pressed again');
end;

procedure TTestGreedCommandState.DovrebbeDareUnCarattereUnaVolta;
var
  LCharacter: Char;
begin
  FSource.Typed := 'A';
  FState.ReadControls;
  Assert.IsTrue(FState.TakeCharacter(LCharacter));
  Assert.AreEqual('A', LCharacter);
  Assert.IsFalse(FState.TakeCharacter(LCharacter));
end;

procedure TTestGreedCommandState.DovrebbePerdereIlCarattereNonPreso;
var
  LCharacter: Char;
begin
  // lastascii is cleared at every reading, newascii is not: the character that was not taken is not given again
  FSource.Typed := 'A';
  FState.ReadControls;
  FState.ReadControls;
  Assert.IsTrue(FState.TakeCharacter(LCharacter), 'newascii is still set');
  Assert.AreEqual(#0, LCharacter, 'but lastascii was cleared');
end;

procedure TTestGreedCommandState.DovrebbeSollevareSenzaOrigine;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    TGreedCommandState.Create(nil).Free;
  except
    on EArgumentNilException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

end.
