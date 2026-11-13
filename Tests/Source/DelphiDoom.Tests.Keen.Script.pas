{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the script of a run without a   }
{  player and the clock that follows it; the RLEW compression                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Script;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Keen.Script,
  DelphiDoom.Keen.ScriptedHost;

type
  [TestFixture]
  [Category('keen')]
  [Category('keen-user')]
  TTestKeenScript = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereAttesaPressioneEFoto;
    [Test]
    procedure DovrebbeBattereUnTestoTastoPerTasto;
    [Test]
    procedure DovrebbeSaltareCommentiERigheVuote;
    [Test]
    procedure DovrebbeConoscereINomiDeiTasti;
    [Test]
    procedure DovrebbeRifiutareUnComandoSconosciuto;
    [Test]
    procedure DovrebbeRifiutareUnTastoSconosciuto;
    [Test]
    procedure DovrebbeRifiutareUnAttesaNonValida;
    [Test]
    procedure IlTempoDovrebbeAvanzareDiUnTicAOgniAttesa;
    [Test]
    procedure GliEventiDovrebberoAccadereAlLoroTic;
    [Test]
    procedure IlTempoDelGiocoDovrebbePotereEssereCambiatoSenzaToccareLoScript;
    [Test]
    procedure LaFineDovrebbeEssereUnUscitaDalGioco;
    [Test]
    procedure UnoScriptFinitoDovrebbeFermareUnGiocoCheAspettaPerSempre;
    [Test]
    procedure OgniPassoDovrebbeChiamareIlSuoGancio;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenRlewCompress = class(TObject)
  public
    [Test]
    procedure DovrebbeComprimereSoloLeSerieDiPiuDiTreParole;
    [Test]
    procedure DovrebbeScrivereSempreIlTagComeSerie;
    [Test]
    procedure DovrebbeDareNullaPerNulla;
    [Test]
    procedure LEspansioneDovrebbeRidareLeParole;
  end;

implementation

uses
  DelphiDoom.Keen.Rlew;

{ TTestKeenScript }

procedure TTestKeenScript.DovrebbeLeggereAttesaPressioneEFoto;
var
  LEvents: TArray<TKeenScriptEvent>;
begin
  LEvents := TKeenScript.Parse('wait 10'#13#10'press enter'#13#10'shot a.png'#13#10'down right'#13#10'wait 5'#13#10 +
    'up right'#13#10'quit');
  Assert.AreEqual<Integer>(6, Length(LEvents));
  Assert.AreEqual(10, LEvents[0].Tic);
  Assert.AreEqual(Ord(ksePort), Ord(LEvents[0].Kind));
  Assert.AreEqual($1C, Integer(LEvents[0].Port));
  Assert.AreEqual(10 + KEEN_SCRIPT_PRESS_TICS, LEvents[1].Tic);
  Assert.AreEqual($9C, Integer(LEvents[1].Port), 'the break code');
  Assert.AreEqual(10 + KEEN_SCRIPT_PRESS_TOTAL, LEvents[2].Tic);
  Assert.AreEqual(Ord(kseShot), Ord(LEvents[2].Kind));
  Assert.AreEqual('a.png', LEvents[2].Name);
  Assert.AreEqual($4D, Integer(LEvents[3].Port));
  Assert.AreEqual($CD, Integer(LEvents[4].Port));
  Assert.AreEqual(LEvents[3].Tic + 1 + 5, LEvents[4].Tic);
  Assert.AreEqual(Ord(kseQuit), Ord(LEvents[5].Kind));
end;

procedure TTestKeenScript.DovrebbeBattereUnTestoTastoPerTasto;
var
  LEvents: TArray<TKeenScriptEvent>;
begin
  LEvents := TKeenScript.Parse('type a 1');
  Assert.AreEqual<Integer>(6, Length(LEvents));
  Assert.AreEqual($1E, Integer(LEvents[0].Port));
  Assert.AreEqual($39, Integer(LEvents[2].Port), 'the space');
  Assert.AreEqual($02, Integer(LEvents[4].Port));
  Assert.AreEqual(2 * KEEN_SCRIPT_PRESS_TOTAL, LEvents[4].Tic);
end;

procedure TTestKeenScript.DovrebbeSaltareCommentiERigheVuote;
begin
  Assert.AreEqual<Integer>(0, Length(TKeenScript.Parse('')));
  Assert.AreEqual<Integer>(1, Length(TKeenScript.Parse('# a comment'#10#10'   '#10'  QUIT  ')));
end;

procedure TTestKeenScript.DovrebbeConoscereINomiDeiTasti;
var
  LScan: Byte;
begin
  Assert.IsTrue(TKeenScript.TryScanCode('ESC', LScan));
  Assert.AreEqual($01, Integer(LScan));
  Assert.IsTrue(TKeenScript.TryScanCode('f10', LScan));
  Assert.AreEqual($44, Integer(LScan));
  Assert.IsTrue(TKeenScript.TryScanCode('q', LScan));
  Assert.AreEqual($10, Integer(LScan));
  Assert.IsTrue(TKeenScript.TryScanCode('l', LScan));
  Assert.AreEqual($26, Integer(LScan));
  Assert.IsTrue(TKeenScript.TryScanCode('m', LScan));
  Assert.AreEqual($32, Integer(LScan));
  Assert.IsTrue(TKeenScript.TryScanCode('0', LScan));
  Assert.AreEqual($0B, Integer(LScan));
  Assert.IsTrue(TKeenScript.TryScanCode('ctrl', LScan));
  Assert.AreEqual($1D, Integer(LScan));
  Assert.IsFalse(TKeenScript.TryScanCode('hyper', LScan));
  Assert.IsFalse(TKeenScript.TryScanCode('', LScan));
end;

procedure TTestKeenScript.DovrebbeRifiutareUnComandoSconosciuto;
begin
  Assert.WillRaise(procedure begin TKeenScript.Parse('wait 1'#10'jump'); end, EKeenException);
end;

procedure TTestKeenScript.DovrebbeRifiutareUnTastoSconosciuto;
begin
  Assert.WillRaise(procedure begin TKeenScript.Parse('press hyper'); end, EKeenException);
  Assert.WillRaise(procedure begin TKeenScript.Parse('type a!'); end, EKeenException);
end;

procedure TTestKeenScript.DovrebbeRifiutareUnAttesaNonValida;
begin
  Assert.WillRaise(procedure begin TKeenScript.Parse('wait'); end, EKeenException);
  Assert.WillRaise(procedure begin TKeenScript.Parse('wait -3'); end, EKeenException);
  Assert.WillRaise(procedure begin TKeenScript.Parse('wait soon'); end, EKeenException);
end;

procedure TTestKeenScript.IlTempoDovrebbeAvanzareDiUnTicAOgniAttesa;
var
  LHost: TKeenScriptedHost;
  LClock: IKeenClock;
begin
  LHost := TKeenScriptedHost.Create(nil);
  LClock := LHost;
  Assert.AreEqual(0, LClock.TimeCount);
  LClock.Idle;
  LClock.Idle;
  LHost.Step;
  Assert.AreEqual(3, LClock.TimeCount);
  Assert.AreEqual(3, LHost.Steps);
end;

procedure TTestKeenScript.GliEventiDovrebberoAccadereAlLoroTic;
var
  LHost: TKeenScriptedHost;
  LClock: IKeenClock;
  LLog: string;
  LIndex: Integer;
begin
  LHost := TKeenScriptedHost.Create(TKeenScript.Parse('wait 3'#10'down a'#10'shot one'#10'wait 2'#10'up a'));
  LClock := LHost;
  LLog := '';
  LHost.Keys :=
    procedure(AByte: Byte)
    begin
      LLog := LLog + Format('%d:k%x ', [LHost.Steps, AByte]);
    end;
  LHost.OnShot :=
    procedure(AName: string)
    begin
      LLog := LLog + Format('%d:s%s ', [LHost.Steps, AName]);
    end;
  for LIndex := 1 to 10 do
    LClock.Idle;
  Assert.AreEqual('3:k1E 4:sone 6:k9E ', LLog);
  LHost.Keys := nil;
  LHost.OnShot := nil;
end;

procedure TTestKeenScript.IlTempoDelGiocoDovrebbePotereEssereCambiatoSenzaToccareLoScript;
var
  LHost: TKeenScriptedHost;
  LClock: IKeenClock;
  LKeys: Integer;
begin
  LHost := TKeenScriptedHost.Create(TKeenScript.Parse('wait 4'#10'down a'));
  LClock := LHost;
  LKeys := 0;
  LHost.Keys := procedure(AByte: Byte) begin Inc(LKeys); end;
  LClock.Idle;
  LClock.Idle;
  // the game takes its time back (as RF_Refresh does after a long frame)
  LClock.TimeCount := 0;
  LClock.Idle;
  Assert.AreEqual(1, LClock.TimeCount);
  Assert.AreEqual(0, LKeys);
  LClock.Idle;
  Assert.AreEqual(1, LKeys, 'the fourth step of the script, whatever the time of the game says');
  LHost.Keys := nil;
end;

procedure TTestKeenScript.LaFineDovrebbeEssereUnUscitaDalGioco;
var
  LHost: TKeenScriptedHost;
  LClock: IKeenClock;
begin
  LHost := TKeenScriptedHost.Create(TKeenScript.Parse('wait 2'#10'quit'));
  LClock := LHost;
  LClock.Idle;
  Assert.WillRaise(procedure begin LClock.Idle; end, EKeenQuitException);
end;

procedure TTestKeenScript.UnoScriptFinitoDovrebbeFermareUnGiocoCheAspettaPerSempre;
var
  LHost: TKeenScriptedHost;
  LClock: IKeenClock;
  LIndex: Integer;
begin
  LHost := TKeenScriptedHost.Create(TKeenScript.Parse('wait 5'#10'down a'));
  LClock := LHost;
  for LIndex := 1 to 5 + KEEN_SCRIPT_GRACE_STEPS do
    LClock.Idle;
  Assert.WillRaise(procedure begin LClock.Idle; end, EKeenScriptEndedException);
end;

procedure TTestKeenScript.OgniPassoDovrebbeChiamareIlSuoGancio;
var
  LHost: TKeenScriptedHost;
  LClock: IKeenClock;
  LCount: Integer;
begin
  LHost := TKeenScriptedHost.Create(nil);
  LClock := LHost;
  LCount := 0;
  LHost.OnStep :=
    procedure
    begin
      Inc(LCount);
      // a wait inside a step does not step again
      LHost.Step;
    end;
  LClock.Idle;
  LClock.Idle;
  Assert.AreEqual(2, LCount);
  Assert.AreEqual(2, LHost.Steps);
  LHost.OnStep := nil;
end;

{ TTestKeenRlewCompress }

procedure TTestKeenRlewCompress.DovrebbeComprimereSoloLeSerieDiPiuDiTreParole;
var
  LBytes: TBytes;
begin
  // 5, 5, 5 (three: copied), 7 x 4 (a run), 9
  LBytes := TKeenRlew.Compress(TArray<Word>.Create(5, 5, 5, 7, 7, 7, 7, 9), $ABCD);
  Assert.AreEqual(TBytes.Create(5, 0, 5, 0, 5, 0, $CD, $AB, 4, 0, 7, 0, 9, 0), LBytes);
end;

procedure TTestKeenRlewCompress.DovrebbeScrivereSempreIlTagComeSerie;
var
  LBytes: TBytes;
begin
  // a word that is the tag cannot be copied as it is: it is a run of one
  LBytes := TKeenRlew.Compress(TArray<Word>.Create(1, $ABCD, 2), $ABCD);
  Assert.AreEqual(TBytes.Create(1, 0, $CD, $AB, 1, 0, $CD, $AB, 2, 0), LBytes);
end;

procedure TTestKeenRlewCompress.DovrebbeDareNullaPerNulla;
begin
  Assert.AreEqual<Integer>(0, Length(TKeenRlew.Compress(nil, $ABCD)));
end;

procedure TTestKeenRlewCompress.LEspansioneDovrebbeRidareLeParole;
var
  LWords: TArray<Word>;
  LIndex: Integer;
  LState: Cardinal;
  LCompressed: TBytes;
  LExpanded: TBytes;
  LRlew: IKeenRlew;
begin
  // a plane like the ones of a map: long runs, single words and the tag
  SetLength(LWords, 3000);
  LState := 12345;
  for LIndex := 0 to High(LWords) do
  begin
    LState := LState * 1664525 + 1013904223;
    if (LState shr 28) < 11 then
      LWords[LIndex] := 0
    else if (LState shr 28) = 11 then
      LWords[LIndex] := $ABCD
    else
      LWords[LIndex] := Word(LState shr 12);
  end;
  LCompressed := TKeenRlew.Compress(LWords, $ABCD);
  Assert.IsTrue(Length(LCompressed) < Length(LWords) * 2);
  LRlew := TKeenRlew.Create;
  LExpanded := LRlew.Expand(LCompressed, 0, Length(LWords) * 2, $ABCD);
  for LIndex := 0 to High(LWords) do
    Assert.AreEqual(Integer(LWords[LIndex]), Integer(LExpanded[LIndex * 2]) or (Integer(LExpanded[LIndex * 2 + 1]) shl 8),
      'word ' + IntToStr(LIndex));
end;

end.
