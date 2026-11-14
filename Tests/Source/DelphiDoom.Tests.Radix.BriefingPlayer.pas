{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the radix library - the run of a mission briefing      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.BriefingPlayer;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Radix.Briefing.Types,
  DelphiDoom.Radix.Briefing.Player;

type
  /// <summary>A map that writes down what the briefing asks of it</summary>
  TFakeBriefingMap = class(TInterfacedObject, IRadixBriefingMap)
  public
    Ready: Boolean;
    Calls: string;
    function IsReady: Boolean;
    procedure MarkPoint(AX, AY, ARed, AGreen, ABlue: Integer);
    procedure Print(AX, AY: Integer; const AText: string);
  end;

  [TestFixture]
  [Category('radix')]
  TTestRadixBriefingPlayer = class(TObject)
  strict private
    FPlayer: TRadixBriefingPlayer;
    FMap: TFakeBriefingMap;
    FMapReference: IRadixBriefingMap;
    procedure Start(const AScript: string);
    procedure Ticks(ACount: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnBriefingSenzaComandiDovrebbeFinireAlPrimoTic;
    [Test]
    procedure IlTestoDovrebbeEssereBattutoUnCarattereATic;
    [Test]
    procedure IlPilotaDovrebbeCompletareIlTestoInUnTic;
    [Test]
    procedure LAttesaDovrebbeFermareIComandiFinoAlPilota;
    [Test]
    procedure UnAzioneDelPilotaDovrebbeValereUnaVoltaSola;
    [Test]
    procedure IlRitardoDovrebbeDurareISuoiTicEIlPilotaLoSalta;
    [Test]
    procedure PulireIlTestoDovrebbeSvuotareLaFinestra;
    [Test]
    procedure LImmagineDovrebbeRestareNellaFinestra;
    [Test]
    procedure LAnimazioneDovrebbeGirareLeSueFigure;
    [Test]
    procedure LAnimazioneDovrebbeContinuareDuranteUnAttesa;
    [Test]
    procedure LaMappaDovrebbeScorrereVersoIlBersaglioEFrenare;
    [Test]
    procedure IComandiDellaMappaDovrebberoAspettareLaMappa;
    [Test]
    procedure SenzaMappaIComandiDellaMappaNonDovrebberoFareNiente;
    [Test]
    procedure DopoLaFineITicNonDovrebberoCambiareNiente;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Radix.Briefing.Script;

{ TFakeBriefingMap }

function TFakeBriefingMap.IsReady: Boolean;
begin
  Result := Ready;
end;

procedure TFakeBriefingMap.MarkPoint(AX, AY, ARed, AGreen, ABlue: Integer);
begin
  Calls := Calls + Format('point %d %d %d %d %d;', [AX, AY, ARed, AGreen, ABlue]);
end;

procedure TFakeBriefingMap.Print(AX, AY: Integer; const AText: string);
begin
  Calls := Calls + Format('print %d %d %s;', [AX, AY, AText]);
end;

{ TTestRadixBriefingPlayer }

procedure TTestRadixBriefingPlayer.Setup;
begin
  FMap := TFakeBriefingMap.Create;
  FMapReference := FMap;
  FPlayer := nil;
end;

procedure TTestRadixBriefingPlayer.TearDown;
begin
  FPlayer.Free;
  FMapReference := nil;
end;

procedure TTestRadixBriefingPlayer.Start(const AScript: string);
begin
  FreeAndNil(FPlayer);
  FPlayer := TRadixBriefingPlayer.Create(TRadixBriefingScript.Parse(AScript, 'ACE'), FMapReference);
end;

procedure TTestRadixBriefingPlayer.Ticks(ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    FPlayer.Tick(False);
end;

procedure TTestRadixBriefingPlayer.UnBriefingSenzaComandiDovrebbeFinireAlPrimoTic;
begin
  Start('');
  Assert.IsFalse(FPlayer.Finished);
  Ticks(1);
  Assert.IsTrue(FPlayer.Finished);
end;

procedure TTestRadixBriefingPlayer.IlTestoDovrebbeEssereBattutoUnCarattereATic;
begin
  Start('print: abc');
  Ticks(1);
  Assert.AreEqual('a', FPlayer.Message);
  Assert.IsFalse(FPlayer.Finished);
  Ticks(2);
  Assert.AreEqual('abc', FPlayer.Message);
  Assert.IsFalse(FPlayer.Finished);
  Ticks(1);
  Assert.AreEqual('abc', FPlayer.Message);
  Assert.IsTrue(FPlayer.Finished);
end;

procedure TTestRadixBriefingPlayer.IlPilotaDovrebbeCompletareIlTestoInUnTic;
begin
  Start('print: a long text');
  Ticks(3);
  Assert.AreEqual('a l', FPlayer.Message);
  FPlayer.Tick(True);
  Assert.AreEqual('a long text', FPlayer.Message);
  Assert.IsTrue(FPlayer.Finished);
end;

procedure TTestRadixBriefingPlayer.LAttesaDovrebbeFermareIComandiFinoAlPilota;
begin
  Start('waitAction'#10'displayImage: alien 0 0');
  Ticks(50);
  Assert.IsFalse(FPlayer.Finished);
  Assert.AreEqual('', FPlayer.Picture);
  FPlayer.Tick(True);
  Assert.AreEqual('alien', FPlayer.Picture);
  Assert.IsTrue(FPlayer.Finished);
end;

procedure TTestRadixBriefingPlayer.UnAzioneDelPilotaDovrebbeValereUnaVoltaSola;
begin
  Start('waitAction'#10'waitAction');
  FPlayer.Tick(True);
  Assert.IsFalse(FPlayer.Finished);
  Ticks(10);
  Assert.IsFalse(FPlayer.Finished);
  FPlayer.Tick(True);
  Assert.IsTrue(FPlayer.Finished);
end;

procedure TTestRadixBriefingPlayer.IlRitardoDovrebbeDurareISuoiTicEIlPilotaLoSalta;
begin
  Start('delay: 5');
  Ticks(4);
  Assert.IsFalse(FPlayer.Finished);
  Ticks(1);
  Assert.IsTrue(FPlayer.Finished);

  Start('delay: 500');
  Ticks(2);
  Assert.IsFalse(FPlayer.Finished);
  FPlayer.Tick(True);
  Assert.IsTrue(FPlayer.Finished);
end;

procedure TTestRadixBriefingPlayer.PulireIlTestoDovrebbeSvuotareLaFinestra;
begin
  Start('print: ab'#10'waitAction'#10'clearTextWindow'#10'print: c');
  Ticks(5);
  Assert.AreEqual('ab', FPlayer.Message);
  FPlayer.Tick(True);
  Assert.AreEqual('c', FPlayer.Message);
end;

procedure TTestRadixBriefingPlayer.LImmagineDovrebbeRestareNellaFinestra;
begin
  Start('displayImage: alien 0 0'#10'delay: 3');
  Ticks(2);
  Assert.AreEqual('alien', FPlayer.Picture);
  Ticks(5);
  Assert.AreEqual('alien', FPlayer.Picture);
  Assert.IsTrue(FPlayer.Finished);
end;

procedure TTestRadixBriefingPlayer.LAnimazioneDovrebbeGirareLeSueFigure;
begin
  // three pictures, each one until the clock (3 for every tic) reaches 6: two tics and the one that turns
  Start('displayAnimation: plane1 3 6 -1'#10'waitAction');
  Ticks(1);
  Assert.AreEqual('plane1', FPlayer.Picture);
  Ticks(2);
  Assert.AreEqual('plane2', FPlayer.Picture);
  Ticks(3);
  Assert.AreEqual('plane3', FPlayer.Picture);
  Ticks(3);
  Assert.AreEqual('plane1', FPlayer.Picture);
end;

procedure TTestRadixBriefingPlayer.LAnimazioneDovrebbeContinuareDuranteUnAttesa;
begin
  Start('displayAnimation: plane1 2 0 -1'#10'waitAction');
  Ticks(1);
  Assert.AreEqual('plane2', FPlayer.Picture);
  Ticks(1);
  Assert.AreEqual('plane1', FPlayer.Picture);
  Assert.IsFalse(FPlayer.Finished);
end;

procedure TTestRadixBriefingPlayer.LaMappaDovrebbeScorrereVersoIlBersaglioEFrenare;
var
  LBefore: Integer;
begin
  Start('scrollMapX: 14000'#10'waitAction');
  Assert.AreEqual(0, FPlayer.MapPosition);
  // the speed is the distance in two seconds: 14000 div 70 = 200 for every tic
  Ticks(1);
  Assert.AreEqual(0, FPlayer.MapPosition);
  Ticks(1);
  Assert.AreEqual(200, FPlayer.MapPosition);
  Ticks(64);
  Assert.AreEqual(13000, FPlayer.MapPosition);
  // nearer than 1024 it slows down
  LBefore := FPlayer.MapPosition;
  Ticks(1);
  Assert.AreEqual(LBefore + 200 * 1000 div 1024, FPlayer.MapPosition);
  Ticks(400);
  Assert.AreEqual(14000, FPlayer.MapPosition);
end;

procedure TTestRadixBriefingPlayer.IComandiDellaMappaDovrebberoAspettareLaMappa;
begin
  Start('pointMap: 10 20 63 0 5'#10'mapPrint: 30 40 Fan'#10'waitAction');
  Ticks(3);
  Assert.AreEqual('', FMap.Calls);
  FMap.Ready := True;
  Ticks(3);
  Assert.AreEqual('point 10 20 63 0 5;print 30 40 Fan;', FMap.Calls);
end;

procedure TTestRadixBriefingPlayer.SenzaMappaIComandiDellaMappaNonDovrebberoFareNiente;
begin
  FreeAndNil(FPlayer);
  FPlayer := TRadixBriefingPlayer.Create(TRadixBriefingScript.Parse('pointMap: 1 2 3 4 5'#10'delay: 2', ''), nil);
  Ticks(2);
  Assert.IsTrue(FPlayer.Finished);
end;

procedure TTestRadixBriefingPlayer.DopoLaFineITicNonDovrebberoCambiareNiente;
begin
  Start('print: ab');
  Ticks(10);
  Assert.IsTrue(FPlayer.Finished);
  FPlayer.Tick(True);
  Assert.AreEqual('ab', FPlayer.Message);
  Assert.IsTrue(FPlayer.Finished);
end;

end.
