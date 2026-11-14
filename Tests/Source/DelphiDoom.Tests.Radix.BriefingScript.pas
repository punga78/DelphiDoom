{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the radix library - the script of a mission briefing   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.BriefingScript;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Radix.Briefing.Types,
  DelphiDoom.Radix.Briefing.Script;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixBriefingScript = class(TObject)
  strict private
    function Parse(const AText: string): TArray<TRadixBriefingCommand>;
    function Raises(const AText: string): Boolean;
  public
    [Test]
    procedure UnTestoVuotoNonDovrebbeAvereComandi;
    [Test]
    procedure DovrebbeSaltareCommentiRigheVuoteERigheSconosciute;
    [Test]
    procedure INomiNonDovrebberoDipendereDalleMaiuscoleNeDaiDuePunti;
    [Test]
    procedure DovrebbeLeggereIlRitardo;
    [Test]
    procedure DovrebbeLeggereUnAnimazioneConITreNumeri;
    [Test]
    procedure DovrebbeLeggereUnImmagineConIDueNumeri;
    [Test]
    procedure DovrebbeLeggereIlPuntoDellaMappaConICinqueNumeri;
    [Test]
    procedure DovrebbeLeggereLaScrittaDellaMappaConIlRestoDellaRiga;
    [Test]
    procedure DovrebbeLeggereLoScorrimento;
    [Test]
    procedure LeStampeDiSeguitoDovrebberoDiventareUnSoloComando;
    [Test]
    procedure UnaStampaDovrebbeFinirePrimaDelComandoCheLaSegue;
    [Test]
    procedure UnaStampaSenzaTestoDovrebbeEssereUnaRigaVuota;
    [Test]
    procedure IlDollaroDovrebbeDiventareUnoSpazioELApostrofoUnAccento;
    [Test]
    procedure IlNomeDelPilotaDovrebbeEntrareNelTesto;
    [Test]
    procedure LeVirgoletteDelTestoDovrebberoRestare;
    [Test]
    [TestCase('ritardo senza numero', 'delay')]
    [TestCase('ritardo non numero', 'delay: soon')]
    [TestCase('punto con quattro numeri', 'pointMap: 1 2 3 4')]
    [TestCase('animazione senza nome', 'displayAnimation:')]
    [TestCase('animazione con due numeri', 'displayAnimation: plane1 8 50')]
    [TestCase('scritta senza punto', 'mapPrint: 5')]
    procedure UnNumeroMancanteOSbagliatoDovrebbeDareEccezione(const AText: string);
    [Test]
    procedure OltreIlMassimoICComandiDovrebberoEssereLasciati;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Radix.Types;

function TTestRadixBriefingScript.Parse(const AText: string): TArray<TRadixBriefingCommand>;
begin
  Result := TRadixBriefingScript.Parse(AText, 'ACE');
end;

function TTestRadixBriefingScript.Raises(const AText: string): Boolean;
begin
  Result := False;
  try
    Parse(AText);
  except
    on ERadixException do
      Result := True;
  end;
end;

procedure TTestRadixBriefingScript.UnTestoVuotoNonDovrebbeAvereComandi;
begin
  Assert.AreEqual(0, Integer(Length(Parse(''))));
  Assert.AreEqual(0, Integer(Length(Parse(#13#10#13#10))));
end;

procedure TTestRadixBriefingScript.DovrebbeSaltareCommentiRigheVuoteERigheSconosciute;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('; a comment'#13#10'// another'#13#10#13#10'  showScreen  '#13#10'dance: 5'#13#10'nextPoint');
  Assert.AreEqual(2, Integer(Length(LCommands)));
  Assert.IsTrue(LCommands[0].Kind = bckShowScreen);
  Assert.IsTrue(LCommands[1].Kind = bckNextPoint);
end;

procedure TTestRadixBriefingScript.INomiNonDovrebberoDipendereDalleMaiuscoleNeDaiDuePunti;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('CLEARTEXTWINDOW'#10'clearAnimWindow:'#10'WaitAction'#10'delay 7');
  Assert.AreEqual(4, Integer(Length(LCommands)));
  Assert.IsTrue(LCommands[0].Kind = bckClearTextWindow);
  Assert.IsTrue(LCommands[1].Kind = bckClearAnimWindow);
  Assert.IsTrue(LCommands[2].Kind = bckWaitAction);
  Assert.IsTrue(LCommands[3].Kind = bckDelay);
  Assert.AreEqual(7, LCommands[3].Numbers[0]);
end;

procedure TTestRadixBriefingScript.DovrebbeLeggereIlRitardo;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('delay: 35');
  Assert.IsTrue(LCommands[0].Kind = bckDelay);
  Assert.AreEqual(35, LCommands[0].Numbers[0]);
end;

procedure TTestRadixBriefingScript.DovrebbeLeggereUnAnimazioneConITreNumeri;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('displayAnimation: netradixplane1 8 50 -1');
  Assert.IsTrue(LCommands[0].Kind = bckDisplayAnimation);
  Assert.AreEqual('netradixplane1', LCommands[0].Text);
  Assert.AreEqual(8, LCommands[0].Numbers[0]);
  Assert.AreEqual(50, LCommands[0].Numbers[1]);
  Assert.AreEqual(-1, LCommands[0].Numbers[2]);
end;

procedure TTestRadixBriefingScript.DovrebbeLeggereUnImmagineConIDueNumeri;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('displayImage: alien 3 4');
  Assert.IsTrue(LCommands[0].Kind = bckDisplayImage);
  Assert.AreEqual('alien', LCommands[0].Text);
  Assert.AreEqual(3, LCommands[0].Numbers[0]);
  Assert.AreEqual(4, LCommands[0].Numbers[1]);
end;

procedure TTestRadixBriefingScript.DovrebbeLeggereIlPuntoDellaMappaConICinqueNumeri;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('pointMap: 24192 1408 63 62 0');
  Assert.IsTrue(LCommands[0].Kind = bckPointMap);
  Assert.AreEqual(24192, LCommands[0].Numbers[0]);
  Assert.AreEqual(1408, LCommands[0].Numbers[1]);
  Assert.AreEqual(63, LCommands[0].Numbers[2]);
  Assert.AreEqual(62, LCommands[0].Numbers[3]);
  Assert.AreEqual(0, LCommands[0].Numbers[4]);
end;

procedure TTestRadixBriefingScript.DovrebbeLeggereLaScrittaDellaMappaConIlRestoDellaRiga;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('mapPrint: 16192 128 Start Position');
  Assert.IsTrue(LCommands[0].Kind = bckMapPrint);
  Assert.AreEqual(16192, LCommands[0].Numbers[0]);
  Assert.AreEqual(128, LCommands[0].Numbers[1]);
  Assert.AreEqual('Start Position', LCommands[0].Text);
end;

procedure TTestRadixBriefingScript.DovrebbeLeggereLoScorrimento;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('scrollMapX: 16192');
  Assert.IsTrue(LCommands[0].Kind = bckScrollMapX);
  Assert.AreEqual(16192, LCommands[0].Numbers[0]);
end;

procedure TTestRadixBriefingScript.LeStampeDiSeguitoDovrebberoDiventareUnSoloComando;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('println: first line'#10'print: second'#10'println:  and more');
  Assert.AreEqual(1, Integer(Length(LCommands)));
  Assert.IsTrue(LCommands[0].Kind = bckPrint);
  Assert.AreEqual('first line'#13#10'secondand more'#13#10, LCommands[0].Text);
end;

procedure TTestRadixBriefingScript.UnaStampaDovrebbeFinirePrimaDelComandoCheLaSegue;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('println: one'#10'waitAction'#10'println: two');
  Assert.AreEqual(3, Integer(Length(LCommands)));
  Assert.AreEqual('one'#13#10, LCommands[0].Text);
  Assert.IsTrue(LCommands[1].Kind = bckWaitAction);
  Assert.AreEqual('two'#13#10, LCommands[2].Text);
end;

procedure TTestRadixBriefingScript.UnaStampaSenzaTestoDovrebbeEssereUnaRigaVuota;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('println: one'#10'println:'#10'println'#10'println: "$"'#10'println: two');
  Assert.AreEqual(1, Integer(Length(LCommands)));
  Assert.AreEqual('one'#13#10#13#10#13#10#13#10'two'#13#10, LCommands[0].Text);
  // a print that writes nothing at all is no command
  Assert.AreEqual(0, Integer(Length(Parse('print:'))));
end;

procedure TTestRadixBriefingScript.IlDollaroDovrebbeDiventareUnoSpazioELApostrofoUnAccento;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('print: it''s$here');
  Assert.AreEqual('it`s here', LCommands[0].Text);
end;

procedure TTestRadixBriefingScript.IlNomeDelPilotaDovrebbeEntrareNelTesto;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('print: Welcome $'#10'printName'#10'println: !');
  Assert.AreEqual(1, Integer(Length(LCommands)));
  Assert.AreEqual('Welcome  ACE!'#13#10, LCommands[0].Text);
end;

procedure TTestRadixBriefingScript.LeVirgoletteDelTestoDovrebberoRestare;
var
  LCommands: TArray<TRadixBriefingCommand>;
begin
  LCommands := Parse('println: "Defiance" to the base');
  Assert.AreEqual('"Defiance" to the base'#13#10, LCommands[0].Text);
end;

procedure TTestRadixBriefingScript.UnNumeroMancanteOSbagliatoDovrebbeDareEccezione(const AText: string);
begin
  Assert.IsTrue(Raises(AText));
end;

procedure TTestRadixBriefingScript.OltreIlMassimoICComandiDovrebberoEssereLasciati;
var
  LText: TStringBuilder;
  LIndex: Integer;
begin
  LText := TStringBuilder.Create;
  try
    for LIndex := 1 to TRadixBriefingScript.MAX_COMMANDS + 20 do
      LText.Append('nextPoint'#10);
    Assert.AreEqual(TRadixBriefingScript.MAX_COMMANDS, Integer(Length(Parse(LText.ToString))));
  finally
    LText.Free;
  end;
end;

end.
