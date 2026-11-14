{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the parameters of the command line   }
{  of the original, and the commands of the script for the mouse and the        }
{  joystick                                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.Parameters;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Keen.Parameters, DelphiDoom.Keen.Script,
  DelphiDoom.Keen.ScriptedHost, DelphiDoom.Keen.ScriptedDevices, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Skip;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenParameters = class(TObject)
  public
    [Test]
    procedure DovrebbeIgnorareIlMaiuscolo;
    [Test]
    procedure DovrebbeSaltareLaPunteggiatura;
    [Test]
    procedure DovrebbeAccettareUnParametroPiuLungoDellaStringa;
    [Test]
    procedure NonDovrebbeAccettareUnParametroPiuCorto;
    [Test]
    procedure DovrebbeDareLIndiceDellaPrimaStringaCheCombacia;
    [Test]
    procedure DovrebbeFermarsiAllaStringaVuota;
    [Test]
    procedure UnParametroSenzaLettereDovrebbeDareMenoUno;
    [Test]
    procedure UnParametroVuotoDovrebbeDareMenoUno;
    [Test]
    procedure DovrebbeRiconoscereIParametriDelGioco;
    [Test]
    procedure DovrebbeLeggereNoMouseENoJoys;
    [Test]
    procedure DovrebbeLeggereCompENoAl;
    [Test]
    procedure DovrebbeLeggereLaSoundSource;
    [Test]
    procedure DovrebbeLeggereIlLivelloDelTed;
    [Test]
    procedure UnLivelloDelTedNegativoDovrebbeFermareLaRicerca;
    [Test]
    procedure UnTedSenzaNumeroNonDovrebbeDareUnLivello;
    [Test]
    procedure UnTedConUnTestoDovrebbeDareZero;
    [Test]
    procedure SenzaParametriDovrebbeDareIValoriDiPartenza;
    [Test]
    procedure DovrebbeDireCheUnParametroPrendeUnValore;
  end;

  /// <summary>The answers of the US_CheckParm of the original (ToolsVerificauparm), 290 cases</summary>
  [TestFixture]
  [Category('keen')]
  TTestKeenParametersParity = class(TObject)
  strict private
    class function PrintedBy(const ASourceLines: TStringList; const AKey: string): string; static;
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelC;
    [Test]
    procedure IlTestoDiVerEDelPuntoInterrogativoDovrebbeEssereQuelloDelSorgente;
    [Test]
    procedure DovrebbeRispondereSoloAlPrimoArgomento;
    [Test]
    procedure DovrebbeIgnorareIlMaiuscoloInVer;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenScriptDevices = class(TObject)
  public
    [Test]
    procedure DovrebbeLeggereIlMovimentoDelMouse;
    [Test]
    procedure DovrebbeLeggereIPulsantiDelMouse;
    [Test]
    procedure DovrebbeLeggereLaPosizioneDelJoystick;
    [Test]
    procedure DovrebbeLeggereIPulsantiDelJoystick;
    [Test]
    procedure DovrebbeRifiutareUnMovimentoSenzaDueNumeri;
    [Test]
    procedure DovrebbeRifiutareUnPulsanteNonNumerico;
    [Test]
    procedure DovrebbeRifiutareUnaPosizioneFuoriDalPorto;
    [Test]
    procedure IlHostDovrebbeMuovereIDispositiviAlTicGiusto;
    [Test]
    procedure IlHostSenzaDispositiviDovrebbeIgnorareIComandi;
  end;

implementation

{ TTestKeenParameters }

procedure TTestKeenParameters.DovrebbeIgnorareIlMaiuscolo;
begin
  Assert.AreEqual(1, TKeenParameters.Check('NoMouse', ['nojoys', 'nomouse']));
  Assert.AreEqual(1, TKeenParameters.Check('nomouse', ['NOJOYS', 'NOMOUSE']));
end;

procedure TTestKeenParameters.DovrebbeSaltareLaPunteggiatura;
begin
  Assert.AreEqual(0, TKeenParameters.Check('-comp', ['comp']));
  Assert.AreEqual(0, TKeenParameters.Check('/comp', ['comp']));
  Assert.AreEqual(0, TKeenParameters.Check('--9comp', ['comp']));
end;

procedure TTestKeenParameters.DovrebbeAccettareUnParametroPiuLungoDellaStringa;
begin
  // as the C: the string only has to be the beginning of the parameter
  Assert.AreEqual(1, TKeenParameters.Check('nomouse2', ['nojoys', 'nomouse']));
  Assert.AreEqual(0, TKeenParameters.Check('compatible', ['comp']));
end;

procedure TTestKeenParameters.NonDovrebbeAccettareUnParametroPiuCorto;
begin
  Assert.AreEqual(-1, TKeenParameters.Check('nomou', ['nomouse']));
  Assert.AreEqual(-1, TKeenParameters.Check('co', ['comp']));
end;

procedure TTestKeenParameters.DovrebbeDareLIndiceDellaPrimaStringaCheCombacia;
begin
  Assert.AreEqual(0, TKeenParameters.Check('ss1', ['ss', 'ss1']));
  Assert.AreEqual(1, TKeenParameters.Check('ss1', ['noal', 'ss1', 'ss']));
end;

procedure TTestKeenParameters.DovrebbeFermarsiAllaStringaVuota;
begin
  Assert.AreEqual(-1, TKeenParameters.Check('comp', ['', 'comp']));
  Assert.AreEqual(0, TKeenParameters.Check('comp', ['comp', '']));
end;

procedure TTestKeenParameters.UnParametroSenzaLettereDovrebbeDareMenoUno;
begin
  // the C runs past the end of the string; here there is nothing to match
  Assert.AreEqual(-1, TKeenParameters.Check('-123', ['comp']));
  Assert.AreEqual(-1, TKeenParameters.Check('---', ['comp']));
end;

procedure TTestKeenParameters.UnParametroVuotoDovrebbeDareMenoUno;
begin
  Assert.AreEqual(-1, TKeenParameters.Check('', ['comp']));
end;

procedure TTestKeenParameters.DovrebbeRiconoscereIParametriDelGioco;
begin
  Assert.IsTrue(TKeenParameters.IsOriginal('-nojoys'));
  Assert.IsTrue(TKeenParameters.IsOriginal('NOMOUSE'));
  Assert.IsTrue(TKeenParameters.IsOriginal('/comp'));
  Assert.IsTrue(TKeenParameters.IsOriginal('noal'));
  Assert.IsTrue(TKeenParameters.IsOriginal('ss3'));
  Assert.IsTrue(TKeenParameters.IsOriginal('tedlevel'));
  Assert.IsTrue(TKeenParameters.IsOriginal('HIDDENCARD'));
  Assert.IsFalse(TKeenParameters.IsOriginal('-scale'));
  Assert.IsFalse(TKeenParameters.IsOriginal('-warp'));
end;

procedure TTestKeenParameters.DovrebbeLeggereNoMouseENoJoys;
var
  LParameters: TKeenOriginalParameters;
begin
  LParameters := TKeenParameters.Parse(['-nomouse']);
  Assert.IsTrue(LParameters.NoMouse);
  Assert.IsFalse(LParameters.NoJoysticks);
  LParameters := TKeenParameters.Parse(['nojoys', 'NOMOUSE']);
  Assert.IsTrue(LParameters.NoMouse);
  Assert.IsTrue(LParameters.NoJoysticks);
end;

procedure TTestKeenParameters.DovrebbeLeggereCompENoAl;
var
  LParameters: TKeenOriginalParameters;
begin
  LParameters := TKeenParameters.Parse(['comp', '/noal', 'nosb', 'nodr', 'noss', 'sst', 'hiddencard']);
  Assert.IsTrue(LParameters.Compatibility);
  Assert.IsTrue(LParameters.NoAdLibDetection);
  Assert.IsTrue(LParameters.NoSoundBlasterDetection);
  Assert.IsTrue(LParameters.LeaveDriveOn);
  Assert.IsTrue(LParameters.NoSoundSourceDetection);
  Assert.IsTrue(LParameters.SoundSourceTandy);
  Assert.IsTrue(LParameters.HiddenCard);
end;

procedure TTestKeenParameters.DovrebbeLeggereLaSoundSource;
begin
  Assert.AreEqual(1, TKeenParameters.Parse(['ss1']).SoundSourcePort);
  Assert.AreEqual(2, TKeenParameters.Parse(['ss2']).SoundSourcePort);
  Assert.AreEqual(3, TKeenParameters.Parse(['ss3']).SoundSourcePort);
  // the last one wins, as the C overwrites ssPort
  Assert.AreEqual(3, TKeenParameters.Parse(['ss1', 'ss3']).SoundSourcePort);
end;

procedure TTestKeenParameters.DovrebbeLeggereIlLivelloDelTed;
begin
  Assert.AreEqual(5, TKeenParameters.Parse(['TEDLEVEL', '5']).TedLevel);
  Assert.AreEqual(0, TKeenParameters.Parse(['-tedlevel', '0']).TedLevel);
end;

procedure TTestKeenParameters.UnLivelloDelTedNegativoDovrebbeFermareLaRicerca;
begin
  Assert.AreEqual(-1, TKeenParameters.Parse(['tedlevel', '-3', 'tedlevel', '4']).TedLevel);
end;

procedure TTestKeenParameters.UnTedSenzaNumeroNonDovrebbeDareUnLivello;
begin
  // the C reads argv[argc], that is nil, and fails; here there is no level
  Assert.AreEqual(-1, TKeenParameters.Parse(['tedlevel']).TedLevel);
end;

procedure TTestKeenParameters.UnTedConUnTestoDovrebbeDareZero;
begin
  Assert.AreEqual(0, TKeenParameters.Parse(['tedlevel', 'abc']).TedLevel);
  Assert.AreEqual(12, TKeenParameters.Parse(['tedlevel', ' 12x']).TedLevel);
  Assert.AreEqual(7, TKeenParameters.Parse(['tedlevel', '+7']).TedLevel);
end;

procedure TTestKeenParameters.SenzaParametriDovrebbeDareIValoriDiPartenza;
var
  LParameters: TKeenOriginalParameters;
begin
  LParameters := TKeenParameters.Parse([]);
  Assert.IsFalse(LParameters.NoMouse);
  Assert.IsFalse(LParameters.NoJoysticks);
  Assert.IsFalse(LParameters.Compatibility);
  Assert.AreEqual(-1, LParameters.TedLevel);
  Assert.AreEqual(0, LParameters.SoundSourcePort);
end;

procedure TTestKeenParameters.DovrebbeDireCheUnParametroPrendeUnValore;
begin
  Assert.IsTrue(TKeenParameters.TakesValue('TEDLEVEL'));
  Assert.IsFalse(TKeenParameters.TakesValue('nomouse'));
end;

{ TTestKeenParametersParity }

class function TTestKeenParametersParity.PrintedBy(const ASourceLines: TStringList; const AKey: string): string;
var
  LIndex: Integer;
  LLine: string;
  LStart: Integer;
  LEnd: Integer;
  LText: string;
begin
  Result := '';
  LIndex := 0;
  while (LIndex < ASourceLines.Count) and (Pos(AKey, ASourceLines[LIndex]) = 0) do
    Inc(LIndex);
  Assert.IsTrue(LIndex < ASourceLines.Count, 'the key ' + AKey + ' is in main');
  Inc(LIndex);
  while (LIndex < ASourceLines.Count) and (Pos('exit(0)', ASourceLines[LIndex]) = 0) do
  begin
    LLine := Trim(ASourceLines[LIndex]);
    LStart := Pos('printf("', LLine);
    if LStart > 0 then
    begin
      LStart := LStart + Length('printf("');
      LEnd := LastDelimiter('"', LLine);
      LText := Copy(LLine, LStart, LEnd - LStart);
      LText := StringReplace(LText, '\n', #10, [rfReplaceAll]);
      LText := StringReplace(LText, '%%', '%', [rfReplaceAll]);
      Result := Result + LText;
    end;
    Inc(LIndex);
  end;
end;

procedure TTestKeenParametersParity.IlTestoDiVerEDelPuntoInterrogativoDovrebbeEssereQuelloDelSorgente;
var
  LPath: string;
  LLines: TStringList;
  LText: string;
begin
  LPath := TTestFiles.FindFileUp('Reference\keen\kd_main.c');
  if LPath = '' then
    TTestSkip.Ignore('i sorgenti di Keen Dreams non sono su questa macchina');
  LLines := TTestFiles.Lines(LPath);
  try
    Assert.IsTrue(TKeenParameters.TryInformation('/VER', LText));
    Assert.AreEqual(PrintedBy(LLines, '"/VER"'), LText);
    Assert.IsTrue(TKeenParameters.TryInformation('/?', LText));
    Assert.AreEqual(PrintedBy(LLines, '"/?"'), LText);
  finally
    LLines.Free;
  end;
end;

procedure TTestKeenParametersParity.DovrebbeRispondereSoloAlPrimoArgomento;
var
  LText: string;
begin
  Assert.IsFalse(TKeenParameters.TryInformation('-ver', LText));
  Assert.IsFalse(TKeenParameters.TryInformation('VER', LText));
  Assert.IsFalse(TKeenParameters.TryInformation('/VERSION', LText));
  Assert.IsFalse(TKeenParameters.TryInformation('', LText));
  Assert.AreEqual('', LText);
end;

procedure TTestKeenParametersParity.DovrebbeIgnorareIlMaiuscoloInVer;
var
  LText: string;
begin
  Assert.IsTrue(TKeenParameters.TryInformation('/ver', LText));
  Assert.IsTrue(StartsText(#10'Keen Dreams version 1.93  (Rev 1)', LText));
  Assert.IsTrue(TKeenParameters.TryInformation('/VeR', LText));
end;

procedure TTestKeenParametersParity.DovrebbeDareLeStesseRisposteDelC;
var
  LLines: TStringList;
  LFields: TArray<string>;
  LLine: string;
  LCases: Integer;
begin
  LLines := TTestFiles.Lines(TTestFiles.DataFile('Keen', 'parm.golden.txt'));
  try
    LCases := 0;
    for LLine in LLines do
    begin
      LFields := LLine.Split([#9]);
      if Length(LFields) <> 3 then
        Continue;
      if LFields[1] = 'input' then
        Assert.AreEqual(StrToInt(LFields[2]), TKeenParameters.Check(LFields[0], ['nojoys', 'nomouse']), LLine)
      else if LFields[1] = 'refresh' then
        Assert.AreEqual(StrToInt(LFields[2]), TKeenParameters.Check(LFields[0], ['comp', '']), LLine)
      else if LFields[1] = 'sound' then
        Assert.AreEqual(StrToInt(LFields[2]), TKeenParameters.Check(LFields[0], ['noal', 'nosb', 'nodr', 'noss', 'sst', 'ss1', 'ss2', 'ss3']), LLine)
      else if LFields[1] = 'user' then
        Assert.AreEqual(StrToInt(LFields[2]), TKeenParameters.Check(LFields[0], ['TEDLEVEL', '']), LLine)
      else if LFields[1] = 'video' then
        Assert.AreEqual(StrToInt(LFields[2]), TKeenParameters.Check(LFields[0], ['HIDDENCARD', '']), LLine)
      else
        Assert.Fail('table ' + LFields[1]);
      Inc(LCases);
    end;
    Assert.AreEqual(290, LCases);
  finally
    LLines.Free;
  end;
end;

{ TTestKeenScriptDevices }

procedure TTestKeenScriptDevices.DovrebbeLeggereIlMovimentoDelMouse;
var
  LEvents: TArray<TKeenScriptEvent>;
begin
  LEvents := TKeenScript.Parse('mouse 4 -2');
  Assert.AreEqual<Integer>(1, Length(LEvents));
  Assert.AreEqual(Ord(kseMouseMove), Ord(LEvents[0].Kind));
  Assert.AreEqual(4, LEvents[0].X);
  Assert.AreEqual(-2, LEvents[0].Y);
end;

procedure TTestKeenScriptDevices.DovrebbeLeggereIPulsantiDelMouse;
var
  LEvents: TArray<TKeenScriptEvent>;
begin
  LEvents := TKeenScript.Parse('mousebuttons 3');
  Assert.AreEqual(Ord(kseMouseButtons), Ord(LEvents[0].Kind));
  Assert.AreEqual(3, LEvents[0].X);
end;

procedure TTestKeenScriptDevices.DovrebbeLeggereLaPosizioneDelJoystick;
var
  LEvents: TArray<TKeenScriptEvent>;
begin
  LEvents := TKeenScript.Parse('joy 1900 100');
  Assert.AreEqual(Ord(kseJoystickPosition), Ord(LEvents[0].Kind));
  Assert.AreEqual(1900, LEvents[0].X);
  Assert.AreEqual(100, LEvents[0].Y);
end;

procedure TTestKeenScriptDevices.DovrebbeLeggereIPulsantiDelJoystick;
var
  LEvents: TArray<TKeenScriptEvent>;
begin
  LEvents := TKeenScript.Parse('joybuttons 1');
  Assert.AreEqual(Ord(kseJoystickButtons), Ord(LEvents[0].Kind));
  Assert.AreEqual(1, LEvents[0].X);
end;

procedure TTestKeenScriptDevices.DovrebbeRifiutareUnMovimentoSenzaDueNumeri;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenScript.Parse('mouse 4');
    end, EKeenException);
  Assert.WillRaise(
    procedure
    begin
      TKeenScript.Parse('mouse a b');
    end, EKeenException);
end;

procedure TTestKeenScriptDevices.DovrebbeRifiutareUnPulsanteNonNumerico;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenScript.Parse('mousebuttons left');
    end, EKeenException);
end;

procedure TTestKeenScriptDevices.DovrebbeRifiutareUnaPosizioneFuoriDalPorto;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenScript.Parse('joy 70000 0');
    end, EKeenException);
  Assert.WillRaise(
    procedure
    begin
      TKeenScript.Parse('joy -1 0');
    end, EKeenException);
end;

procedure TTestKeenScriptDevices.IlHostDovrebbeMuovereIDispositiviAlTicGiusto;
var
  LHost: TKeenScriptedHost;
  LKeeper: IKeenClock;
  LDevices: TKeenScriptedDevices;
  LDevicesKeeper: IInterface;
  LDeltaX: Integer;
  LDeltaY: Integer;
  LX: Word;
  LY: Word;
begin
  LHost := TKeenScriptedHost.Create(TKeenScript.Parse('wait 2' + sLineBreak + 'mouse 6 1' + sLineBreak +
    'mousebuttons 1' + sLineBreak + 'joy 1500 500' + sLineBreak + 'joybuttons 2'));
  LKeeper := LHost;
  LDevices := TKeenScriptedDevices.Create(True, True);
  LDevicesKeeper := LDevices;
  LHost.Devices := LDevices;
  LHost.Step;
  LDevices.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(0, LDeltaX);
  Assert.AreEqual(0, Integer(LDevices.GetButtons));
  LHost.Step;
  LHost.Step;
  LHost.Step;
  LHost.Step;
  LHost.Step;
  LDevices.GetDelta(LDeltaX, LDeltaY);
  Assert.AreEqual(6, LDeltaX);
  Assert.AreEqual(1, LDeltaY);
  Assert.AreEqual(1, Integer(LDevices.GetButtons));
  LDevices.GetAbs(0, LX, LY);
  Assert.AreEqual(1500, Integer(LX));
  Assert.AreEqual(500, Integer(LY));
  Assert.AreEqual(2, Integer(LDevices.GetButtons(0)));
end;

procedure TTestKeenScriptDevices.IlHostSenzaDispositiviDovrebbeIgnorareIComandi;
var
  LHost: TKeenScriptedHost;
  LKeeper: IKeenClock;
  LStep: Integer;
begin
  LHost := TKeenScriptedHost.Create(TKeenScript.Parse('mouse 6 1' + sLineBreak + 'joy 1 1'));
  LKeeper := LHost;
  for LStep := 1 to 5 do
    LHost.Step;
  Assert.AreEqual(5, LHost.Steps);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenParameters);
  TDUnitX.RegisterTestFixture(TTestKeenParametersParity);
  TDUnitX.RegisterTestFixture(TTestKeenScriptDevices);

end.
