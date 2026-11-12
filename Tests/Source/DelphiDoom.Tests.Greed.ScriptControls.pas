unit DelphiDoom.Tests.Greed.ScriptControls;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.Types,
  DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.ScriptControls;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedScriptControls = class(TObject)
  strict private
    FLines: TStringList;
    FControls: TGreedScriptControls;
    FIntf: IInterface;
    procedure Make;
    procedure Read(ATimes: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePremereIlComandoAlTicDelloScript;
    [Test]
    procedure DovrebbeRilasciareIlComandoConUp;
    [Test]
    procedure DovrebbeServireLeRigheNellOrdineDeiTicAncheSeScritteAlContrario;
    [Test]
    procedure DovrebbeDareDueComandiAiTastiDoppi;
    [Test]
    procedure DovrebbeBattereUnCarattereAdOgniLettura;
    [Test]
    procedure DovrebbeSaltareCommentiERigheVuote;
    [Test]
    procedure DovrebbeSollevareConUnaRigaNonCapita;
    [Test]
    procedure DovrebbeSollevareConUnComandoSconosciuto;
    [Test]
    procedure DovrebbeSollevareSenzaScript;
  end;

implementation

uses
  DelphiDoom.Greed.CommandState;

procedure TTestGreedScriptControls.Setup;
begin
  FLines := TStringList.Create;
end;

procedure TTestGreedScriptControls.TearDown;
begin
  FIntf := nil;
  FControls := nil;
  FLines.Free;
end;

procedure TTestGreedScriptControls.Make;
begin
  FControls := TGreedScriptControls.Create(FLines, nil);
  FIntf := FControls;
end;

// the n-th reading is the tic 2n - 1 (the game reads on the odd tics)
procedure TTestGreedScriptControls.Read(ATimes: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ATimes do
    FControls.BeginReading;
end;

procedure TTestGreedScriptControls.DovrebbePremereIlComandoAlTicDelloScript;
begin
  FLines.Add('5 north down');
  Make;
  Read(2);
  Assert.IsFalse(FControls.IsPressed(gcNorth), 'the tic 3');
  Read(1);
  Assert.IsTrue(FControls.IsPressed(gcNorth), 'the tic 5');
  Assert.AreEqual(5, FControls.Tic);
  Assert.IsFalse(FControls.IsPressed(gcFire));
end;

procedure TTestGreedScriptControls.DovrebbeRilasciareIlComandoConUp;
begin
  FLines.Add('1 fire down');
  FLines.Add('7 fire up');
  Make;
  Read(3);
  Assert.IsTrue(FControls.IsPressed(gcFire));
  Read(1);
  Assert.IsFalse(FControls.IsPressed(gcFire), 'the tic 7');
end;

procedure TTestGreedScriptControls.DovrebbeServireLeRigheNellOrdineDeiTicAncheSeScritteAlContrario;
begin
  // the up is written before the down that comes first: the original order of the tics wins
  FLines.Add('9 west up');
  FLines.Add('3 west down');
  Make;
  Read(2);
  Assert.IsTrue(FControls.IsPressed(gcWest), 'down at the tic 3');
  Read(3);
  Assert.IsFalse(FControls.IsPressed(gcWest), 'up at the tic 9');
end;

procedure TTestGreedScriptControls.DovrebbeDareDueComandiAiTastiDoppi;
begin
  FLines.Add('1 space down');
  FLines.Add('1 shift down');
  FLines.Add('1 alt down');
  Make;
  Read(1);
  Assert.IsTrue(FControls.IsPressed(gcUse) and FControls.IsPressed(gcRestart), 'space');
  Assert.IsTrue(FControls.IsPressed(gcRun) and FControls.IsPressed(gcShift), 'shift');
  Assert.IsTrue(FControls.IsPressed(gcStrafe) and FControls.IsPressed(gcAlt), 'alt');
end;

procedure TTestGreedScriptControls.DovrebbeBattereUnCarattereAdOgniLettura;
var
  LCharacter: Char;
begin
  FLines.Add('1 type GOD');
  Make;
  Read(1);
  Assert.IsTrue(FControls.TakeTyped(LCharacter));
  Assert.AreEqual('G', LCharacter);
  Assert.IsFalse(FControls.TakeTyped(LCharacter), 'one a reading');
  Read(1);
  Assert.IsTrue(FControls.TakeTyped(LCharacter));
  Assert.AreEqual('O', LCharacter);
  Read(1);
  Assert.IsTrue(FControls.TakeTyped(LCharacter));
  Assert.AreEqual('D', LCharacter);
  Read(1);
  Assert.IsFalse(FControls.TakeTyped(LCharacter));
end;

procedure TTestGreedScriptControls.DovrebbeSaltareCommentiERigheVuote;
begin
  FLines.Add('# a comment');
  FLines.Add('');
  FLines.Add('   ');
  FLines.Add('1 east down');
  Make;
  Read(1);
  Assert.IsTrue(FControls.IsPressed(gcEast));
end;

procedure TTestGreedScriptControls.DovrebbeSollevareConUnaRigaNonCapita;
var
  LMessage: string;
begin
  FLines.Add('1 north down');
  FLines.Add('a north down');
  LMessage := '';
  try
    Make;
  except
    on E: EGreedException do
      LMessage := E.Message;
  end;
  Assert.IsTrue(LMessage.Contains('line 2'), LMessage);
end;

procedure TTestGreedScriptControls.DovrebbeSollevareConUnComandoSconosciuto;
var
  LRaised: Boolean;
begin
  FLines.Add('1 dance down');
  LRaised := False;
  try
    Make;
  except
    on EGreedException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

procedure TTestGreedScriptControls.DovrebbeSollevareSenzaScript;
var
  LRaised: Boolean;
begin
  LRaised := False;
  try
    TGreedScriptControls.Create(nil, nil).Free;
  except
    on EArgumentNilException do
      LRaised := True;
  end;
  Assert.IsTrue(LRaised);
end;

end.
