{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III program - the command line, the text of  }
{  the console and the calendar                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Quake3.CommandLine;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Quake3')]
  TTestQ3CommandLine = class
  public
    [Test]
    procedure UnaRigaDiComandiDovrebbeDarePiuComandiConLeLoroParole;
    [Test]
    procedure IComandiDovrebberoStareNellOrdineDato;
    [Test]
    procedure LeScorciatoieDovrebberoDiventareComandiSet;
    [Test]
    procedure UnPercorsoConSpaziDovrebbeAndareTraVirgolette;
    [Test]
    procedure FramesENoClientDovrebberoEssereOpzioniEnonComandi;
    [Test]
    procedure UnNumeroNegativoDopoUnComandoDovrebbeEssereUnArgomento;
    [Test]
    procedure SenzaFramesDovrebbeGirareFinoAQuit;
    [TestCase('framesSenzaNumero', '-frames,')]
    [TestCase('framesNegativo', '-frames,-3')]
    [TestCase('framesTesto', '-frames,abc')]
    [TestCase('parolaSenzaPiu', 'oa_dm1,')]
    [TestCase('scorciatoiaSenzaValore', '-fs_basepath,')]
    procedure UnaRigaSbagliataDovrebbeDareFalsoConLaRagione(const AFirst: string; const ASecond: string);
    [Test]
    procedure SoloLeRigheDellaFamigliaSetDovrebberoEssereRigheSet;
    [Test]
    procedure LUsoDovrebbeNominareLeOpzioni;
  end;

  [TestFixture]
  [Category('Quake3')]
  TTestQ3ConsoleOutput = class
  public
    [Test]
    procedure IColoriDovrebberoSparire;
    [Test]
    procedure UnaCirconflessoSeguitoDaUnaCirconflessoNonDovrebbeEssereUnColore;
    [Test]
    procedure UnaCirconflessoInFondoDovrebbeRestare;
    [Test]
    procedure IlTestoDelLogDellaConsoleDovrebbeArrivareAlloScrittore;
    [Test]
    procedure IlDevPrintNonDovrebbeScrivereNiente;
  end;

  [TestFixture]
  [Category('Quake3')]
  TTestQ3SystemCalendar = class
  public
    [Test]
    procedure UnGiornoNotoDovrebbeDareLaStruttDelC;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Quake3.Types, DelphiDoom.Quake3.CommandLine, DelphiDoom.Quake3.ConsoleOutput,
  DelphiDoom.Quake3.Calendar, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Console.Q3.Intf, DelphiDoom.Q3Host.Intf;

{ TTestQ3CommandLine }

procedure TTestQ3CommandLine.UnaRigaDiComandiDovrebbeDarePiuComandiConLeLoroParole;
var
  LOptions: TQ3ProgramOptions;
  LError: string;
begin
  Assert.IsTrue(TQ3CommandLine.Parse(['+set', 'fs_game', 'baseoa', '+map', 'oa_dm1', '+addbot', 'Sarge', '3'],
    LOptions, LError), LError);
  Assert.AreEqual<Integer>(3, Length(LOptions.Commands));
  Assert.AreEqual('set fs_game baseoa', string(LOptions.Commands[0]));
  Assert.AreEqual('map oa_dm1', string(LOptions.Commands[1]));
  Assert.AreEqual('addbot Sarge 3', string(LOptions.Commands[2]));
end;

procedure TTestQ3CommandLine.IComandiDovrebberoStareNellOrdineDato;
var
  LOptions: TQ3ProgramOptions;
  LError: string;
begin
  Assert.IsTrue(TQ3CommandLine.Parse(['+quit', '+map', 'x', '+echo'], LOptions, LError), LError);
  Assert.AreEqual('quit', string(LOptions.Commands[0]));
  Assert.AreEqual('map x', string(LOptions.Commands[1]));
  Assert.AreEqual('echo', string(LOptions.Commands[2]));
end;

procedure TTestQ3CommandLine.LeScorciatoieDovrebberoDiventareComandiSet;
var
  LOptions: TQ3ProgramOptions;
  LError: string;
begin
  Assert.IsTrue(TQ3CommandLine.Parse(['-fs_basepath', 'C:\giochi', '-fs_game', 'missionpack', '-fs_homepath', 'D:\h'],
    LOptions, LError), LError);
  Assert.AreEqual<Integer>(3, Length(LOptions.Commands));
  Assert.AreEqual('set fs_basepath C:\giochi', string(LOptions.Commands[0]));
  Assert.AreEqual('set fs_game missionpack', string(LOptions.Commands[1]));
  Assert.AreEqual('set fs_homepath D:\h', string(LOptions.Commands[2]));
end;

procedure TTestQ3CommandLine.UnPercorsoConSpaziDovrebbeAndareTraVirgolette;
var
  LOptions: TQ3ProgramOptions;
  LError: string;
begin
  Assert.IsTrue(TQ3CommandLine.Parse(['-fs_basepath', 'C:\Open Arena'], LOptions, LError), LError);
  Assert.AreEqual('set fs_basepath "C:\Open Arena"', string(LOptions.Commands[0]));
  Assert.IsTrue(TQ3CommandLine.Parse(['+set', 'sv_hostname', 'a b'], LOptions, LError), LError);
  Assert.AreEqual('set sv_hostname "a b"', string(LOptions.Commands[0]));
end;

procedure TTestQ3CommandLine.FramesENoClientDovrebberoEssereOpzioniEnonComandi;
var
  LOptions: TQ3ProgramOptions;
  LError: string;
begin
  Assert.IsTrue(TQ3CommandLine.Parse(['+map', 'oa_dm1', '-frames', '300', '-noclient'], LOptions, LError), LError);
  Assert.AreEqual(300, LOptions.Frames);
  Assert.IsTrue(LOptions.NoClient);
  Assert.AreEqual<Integer>(1, Length(LOptions.Commands));
  Assert.AreEqual('map oa_dm1', string(LOptions.Commands[0]));
end;

procedure TTestQ3CommandLine.UnNumeroNegativoDopoUnComandoDovrebbeEssereUnArgomento;
var
  LOptions: TQ3ProgramOptions;
  LError: string;
begin
  Assert.IsTrue(TQ3CommandLine.Parse(['+set', 'x', '-1'], LOptions, LError), LError);
  Assert.AreEqual('set x -1', string(LOptions.Commands[0]));
end;

procedure TTestQ3CommandLine.SenzaFramesDovrebbeGirareFinoAQuit;
var
  LOptions: TQ3ProgramOptions;
  LError: string;
begin
  Assert.IsTrue(TQ3CommandLine.Parse(['+quit'], LOptions, LError), LError);
  Assert.AreEqual(Q3_FRAMES_UNLIMITED, LOptions.Frames);
  Assert.IsFalse(LOptions.NoClient);
  Assert.IsFalse(LOptions.Help);
end;

procedure TTestQ3CommandLine.UnaRigaSbagliataDovrebbeDareFalsoConLaRagione(const AFirst: string;
  const ASecond: string);
var
  LOptions: TQ3ProgramOptions;
  LError: string;
begin
  if ASecond = '' then
    Assert.IsFalse(TQ3CommandLine.Parse([AFirst], LOptions, LError))
  else
    Assert.IsFalse(TQ3CommandLine.Parse([AFirst, ASecond], LOptions, LError));
  Assert.IsTrue(LError <> '', 'la ragione');
end;

procedure TTestQ3CommandLine.SoloLeRigheDellaFamigliaSetDovrebberoEssereRigheSet;
begin
  Assert.IsTrue(TQ3CommandLine.IsSetCommand('set a b'));
  Assert.IsTrue(TQ3CommandLine.IsSetCommand('SETA a b'));
  Assert.IsTrue(TQ3CommandLine.IsSetCommand('sets a b'));
  Assert.IsTrue(TQ3CommandLine.IsSetCommand('setu a b'));
  Assert.IsTrue(TQ3CommandLine.IsSetCommand('set'));
  Assert.IsFalse(TQ3CommandLine.IsSetCommand('setstuff a'));
  Assert.IsFalse(TQ3CommandLine.IsSetCommand('map oa_dm1'));
end;

procedure TTestQ3CommandLine.LUsoDovrebbeNominareLeOpzioni;
var
  LText, LLine: string;
begin
  LText := '';
  for LLine in TQ3CommandLine.Usage do
    LText := LText + LLine + #10;
  Assert.IsTrue(LText.Contains('-frames'));
  Assert.IsTrue(LText.Contains('-fs_basepath'));
  Assert.IsTrue(LText.Contains('+addbot'));
end;

{ TTestQ3ConsoleOutput }

procedure TTestQ3ConsoleOutput.IColoriDovrebberoSparire;
begin
  Assert.AreEqual('Sarge entered the game', TQ3ConsoleOutput.CleanText('^1Sarge^7 entered the game'));
end;

procedure TTestQ3ConsoleOutput.UnaCirconflessoSeguitoDaUnaCirconflessoNonDovrebbeEssereUnColore;
begin
  // Q_CleanStr: il primo ^ resta, il secondo apre il colore "^b" e va via; in fondo resta tutto
  Assert.AreEqual('a^', TQ3ConsoleOutput.CleanText('a^^b'));
  Assert.AreEqual('a^^', TQ3ConsoleOutput.CleanText('a^^'));
end;

procedure TTestQ3ConsoleOutput.UnaCirconflessoInFondoDovrebbeRestare;
begin
  Assert.AreEqual('end^', TQ3ConsoleOutput.CleanText('end^'));
end;

procedure TTestQ3ConsoleOutput.IlTestoDelLogDellaConsoleDovrebbeArrivareAlloScrittore;
var
  LWritten: string;
  LHost: IQ3HostConsole;
  LLog: IQ3ConsoleLog;
begin
  LWritten := '';
  LHost := TQ3ConsoleOutput.Create(
    procedure(AText: string)
    begin
      LWritten := LWritten + AText;
    end);
  LHost.Print('^2uno'#10);
  LLog := LHost as IQ3ConsoleLog;
  LLog.Print('due'#10);
  Assert.AreEqual('uno'#10'due'#10, LWritten);
end;

procedure TTestQ3ConsoleOutput.IlDevPrintNonDovrebbeScrivereNiente;
var
  LWritten: string;
  LLog: IQ3ConsoleLog;
begin
  LWritten := '';
  LLog := TQ3ConsoleOutput.Create(
    procedure(AText: string)
    begin
      LWritten := LWritten + AText;
    end);
  LLog.DevPrint('niente');
  Assert.AreEqual('', LWritten);
end;

{ TTestQ3SystemCalendar }

procedure TTestQ3SystemCalendar.UnGiornoNotoDovrebbeDareLaStruttDelC;
var
  LTime: TQ3HostRealTime;
  LSeconds: Integer;
begin
  // giovedi' 19 novembre 2026, 13:45:30
  LSeconds := TQ3SystemCalendar.Decode(EncodeDate(2026, 11, 19) + EncodeTime(13, 45, 30, 0), LTime);
  Assert.AreEqual(30, LTime.Second);
  Assert.AreEqual(45, LTime.Minute);
  Assert.AreEqual(13, LTime.Hour);
  Assert.AreEqual(19, LTime.DayOfMonth);
  // i mesi partono da 0 e gli anni dal 1900
  Assert.AreEqual(10, LTime.Month);
  Assert.AreEqual(126, LTime.Year);
  Assert.AreEqual(4, LTime.DayOfWeek);
  Assert.AreEqual(322, LTime.DayOfYear);
  Assert.AreEqual(0, LTime.IsDst);
  // time( NULL ) e' in UTC: un'ora piu' tardi sono 3600 secondi in piu' qualunque sia il fuso
  Assert.AreEqual(LSeconds + 3600, TQ3SystemCalendar.Decode(EncodeDate(2026, 11, 19) + EncodeTime(14, 45, 30, 0), LTime));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3CommandLine);
  TDUnitX.RegisterTestFixture(TTestQ3ConsoleOutput);
  TDUnitX.RegisterTestFixture(TTestQ3SystemCalendar);

end.
