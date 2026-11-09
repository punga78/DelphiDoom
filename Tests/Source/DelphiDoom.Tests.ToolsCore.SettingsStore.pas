{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSettingsStore                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ToolsCore.SettingsStore;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Tools.Intf, DelphiDoom.Tests.ToolsCore.Fakes;

type
  /// <summary>
  ///   The SETTINGS and LOAD lines of Tests\Data\ToolsCore\old.golden.txt were written by ee_defs of
  ///   ENDEDIT (ee_SaveSettingsToFile and ee_LoadSettingFromFile) on the same values and texts
  /// </summary>
  [TestFixture]
  [Category('toolscore')]
  TTestToolsSettingsStore = class(TObject)
  strict private
    FFileSystem: TFakeToolFileSystem;
    FFileSystemIntf: IToolFileSystem;
    FSettings: ISettingsStore;
    function LoadedLine(const ATitle, AText: string): string;
    function SavedLines: TArray<string>;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareIValoriPredefinitiSeMancano;
    [Test]
    procedure DovrebbeLeggereCiCheHaScritto;
    [Test]
    procedure DovrebbeSostituireUnValoreScrittoDueVolte;
    [Test]
    procedure DovrebbeNonDistinguereLeMaiuscole;
    [Test]
    procedure DovrebbeRisponderePredefinitoSeIlNumeroNonEValido;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileManca;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileNonSiLegge;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileNonSiScrive;
    [Test]
    procedure DovrebbeTrovareUnValoreSenzaSezione;
    [Test]
    procedure DovrebbeLeggereUnFileInAnsi;
    [Test]
    procedure DovrebbeLeggereUnFileUtf8ConBom;
    [Test]
    procedure DovrebbeSalvareERileggereUnPercorsoNonAscii;
    [Test]
    procedure DovrebbeRifiutareUnSistemaDiFileNil;
    [Test]
    procedure DovrebbeScrivereLoStessoFileDelVecchioCodice;
    [Test]
    procedure DovrebbeLeggereGliStessiValoriDelVecchioCodice;
  end;

implementation

uses
  System.Generics.Collections,
  DelphiDoom.Tools.Factory;

const
  SPATH = 'C:\tool\tool.ini';

{ TTestToolsSettingsStore }

procedure TTestToolsSettingsStore.Setup;
begin
  FFileSystem := TFakeToolFileSystem.Create;
  FFileSystemIntf := FFileSystem;
  FSettings := TToolsFactory.CreateSettings(FFileSystemIntf, SPATH);
end;

function TTestToolsSettingsStore.LoadedLine(const ATitle, AText: string): string;
var
  LSettings: ISettingsStore;
begin
  FFileSystem.PutText(SPATH, AText);
  LSettings := TToolsFactory.CreateSettings(FFileSystemIntf, SPATH);
  Result := Format('%s %s', [ATitle, BoolToStr(LSettings.Load, True)]);
  Result := Result + #1 + Format('%s grid=%d zoom=%d method=%d h0=[%s] h1=[%s] h9=[%s]',
    [ATitle, Ord(LSettings.ReadBoolean('Options', 'SHOWGRID', False)),
     LSettings.ReadInteger('Options', 'ZOOM', 0),
     LSettings.ReadInteger('Options', 'TEXTARTMETHOD', 0),
     LSettings.ReadString('File Menu History', 'FILEMENUHISTORY0', ''),
     LSettings.ReadString('File Menu History', 'FILEMENUHISTORY1', ''),
     LSettings.ReadString('File Menu History', 'FILEMENUHISTORY9', '')]);
end;

function TTestToolsSettingsStore.SavedLines: TArray<string>;
var
  LLines: TStringList;
begin
  Assert.IsTrue(FSettings.Save);
  LLines := TStringList.Create;
  try
    LLines.Text := FFileSystem.TextOf(SPATH);
    Result := LLines.ToStringArray;
  finally
    LLines.Free;
  end;
end;

procedure TTestToolsSettingsStore.DovrebbeDareIValoriPredefinitiSeMancano;
begin
  Assert.AreEqual('x', FSettings.ReadString('S', 'N', 'x'));
  Assert.AreEqual(7, FSettings.ReadInteger('S', 'N', 7));
  Assert.IsTrue(FSettings.ReadBoolean('S', 'N', True));
end;

procedure TTestToolsSettingsStore.DovrebbeLeggereCiCheHaScritto;
begin
  FSettings.WriteString('S', 'Testo', 'ciao');
  FSettings.WriteInteger('S', 'Numero', -12);
  FSettings.WriteBoolean('S', 'Vero', True);
  FSettings.WriteBoolean('S', 'Falso', False);
  Assert.AreEqual('ciao', FSettings.ReadString('S', 'Testo', ''));
  Assert.AreEqual(-12, FSettings.ReadInteger('S', 'Numero', 0));
  Assert.IsTrue(FSettings.ReadBoolean('S', 'Vero', False));
  Assert.IsFalse(FSettings.ReadBoolean('S', 'Falso', True));
end;

procedure TTestToolsSettingsStore.DovrebbeSostituireUnValoreScrittoDueVolte;
begin
  FSettings.WriteInteger('S', 'N', 1);
  FSettings.WriteInteger('S', 'N', 2);
  Assert.AreEqual(2, FSettings.ReadInteger('S', 'N', 0));
  Assert.AreEqual(2, Length(SavedLines), 'una sezione e un valore');
end;

procedure TTestToolsSettingsStore.DovrebbeNonDistinguereLeMaiuscole;
begin
  FSettings.WriteString('Opzioni', 'Nome', 'v');
  Assert.AreEqual('v', FSettings.ReadString('OPZIONI', 'NOME', ''));
end;

procedure TTestToolsSettingsStore.DovrebbeRisponderePredefinitoSeIlNumeroNonEValido;
begin
  FSettings.WriteString('S', 'N', 'abc');
  Assert.AreEqual(5, FSettings.ReadInteger('S', 'N', 5));
  Assert.IsTrue(FSettings.ReadBoolean('S', 'N', True));
  Assert.IsFalse(FSettings.ReadBoolean('S', 'N', False));
end;

procedure TTestToolsSettingsStore.DovrebbeDareFalsoSeIlFileManca;
begin
  Assert.IsFalse(FSettings.Load);
end;

procedure TTestToolsSettingsStore.DovrebbeDareFalsoSeIlFileNonSiLegge;
begin
  FFileSystem.PutText(SPATH, 'A=1');
  FFileSystem.FailRead := True;
  Assert.IsFalse(FSettings.Load);
end;

procedure TTestToolsSettingsStore.DovrebbeDareFalsoSeIlFileNonSiScrive;
begin
  FFileSystem.FailWrite := True;
  Assert.IsFalse(FSettings.Save);
end;

procedure TTestToolsSettingsStore.DovrebbeTrovareUnValoreSenzaSezione;
begin
  FFileSystem.PutText(SPATH, 'ZOOM=4'#13#10'[Altro]'#13#10'ZOOM=9');
  Assert.IsTrue(FSettings.Load);
  Assert.AreEqual(4, FSettings.ReadInteger('Options', 'ZOOM', 0));
  Assert.AreEqual(9, FSettings.ReadInteger('Altro', 'ZOOM', 0));
end;

procedure TTestToolsSettingsStore.DovrebbeLeggereUnFileInAnsi;
var
  LBytes: TBytes;
begin
  // the old tools wrote ANSI: a 0xE8 byte is not UTF-8
  LBytes := TEncoding.ANSI.GetBytes('[H]'#13#10'P=C:\caff' + #$E8 + '.bin'#13#10);
  FFileSystem.TryWriteAllBytes(SPATH, LBytes);
  Assert.IsTrue(FSettings.Load);
  Assert.AreEqual('C:\caff' + #$E8 + '.bin', FSettings.ReadString('H', 'P', ''));
end;

procedure TTestToolsSettingsStore.DovrebbeLeggereUnFileUtf8ConBom;
var
  LBytes: TBytes;
begin
  LBytes := TEncoding.UTF8.GetPreamble + TEncoding.UTF8.GetBytes('[H]'#13#10'P=ci' + #$E0 + #13#10);
  FFileSystem.TryWriteAllBytes(SPATH, LBytes);
  Assert.IsTrue(FSettings.Load);
  Assert.AreEqual('ci' + #$E0, FSettings.ReadString('H', 'P', ''));
end;

procedure TTestToolsSettingsStore.DovrebbeSalvareERileggereUnPercorsoNonAscii;
var
  LOther: ISettingsStore;
begin
  FSettings.WriteString('H', 'P', 'D:\citt' + #$E0 + '\caff' + #$E8 + '.bin');
  Assert.IsTrue(FSettings.Save);
  LOther := TToolsFactory.CreateSettings(FFileSystemIntf, SPATH);
  Assert.IsTrue(LOther.Load);
  Assert.AreEqual('D:\citt' + #$E0 + '\caff' + #$E8 + '.bin', LOther.ReadString('H', 'P', ''));
end;

procedure TTestToolsSettingsStore.DovrebbeRifiutareUnSistemaDiFileNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TToolsFactory.CreateSettings(nil, SPATH);
    end, EArgumentNilException);
end;

procedure TTestToolsSettingsStore.DovrebbeScrivereLoStessoFileDelVecchioCodice;
var
  LAll: TArray<string>;
  LExpected: TList<string>;
  LActual: TList<string>;
  LIndex: Integer;

  procedure Fill(const AValues: array of string);
  var
    LStep: Integer;
  begin
    FSettings := TToolsFactory.CreateSettings(FFileSystemIntf, SPATH);
    for LStep := 0 to 9 do
      FSettings.WriteString('File Menu History', 'FILEMENUHISTORY' + IntToStr(LStep), AValues[LStep]);
    FSettings.WriteBoolean('Options', 'SHOWGRID', AValues[10] = '1');
    FSettings.WriteInteger('Options', 'ZOOM', StrToInt(AValues[11]));
    FSettings.WriteInteger('Options', 'TEXTARTMETHOD', StrToInt(AValues[12]));
  end;

  procedure CollectExpected(const ATitle: string);
  var
    LPosition: Integer;
  begin
    LExpected.Clear;
    LPosition := 0;
    while (LPosition < Length(LAll)) and (LAll[LPosition] <> 'SETTINGS ' + ATitle) do
      Inc(LPosition);
    Inc(LPosition);
    while LAll[LPosition] <> 'END' do
    begin
      LExpected.Add(Copy(LAll[LPosition], 3, MaxInt));
      Inc(LPosition);
    end;
  end;

begin
  LAll := TToolsGolden.AllLines('ToolsCore\old.golden.txt');
  LExpected := TList<string>.Create;
  LActual := TList<string>.Create;
  try
    Fill(['', '', '', '', '', '', '', '', '', '', '0', '0', '0']);
    CollectExpected('defaults');
    LActual.AddRange(SavedLines);
    Assert.AreEqual(LExpected.Count, LActual.Count);
    for LIndex := 0 to LExpected.Count - 1 do
      Assert.AreEqual(LExpected[LIndex], LActual[LIndex]);

    Fill(['C:\one.bin', '', '', 'D:\dir with spaces\two.bin', '', '', '', '', '', '', '1', '7', '3']);
    CollectExpected('changed');
    LActual.Clear;
    LActual.AddRange(SavedLines);
    Assert.AreEqual(LExpected.Count, LActual.Count);
    for LIndex := 0 to LExpected.Count - 1 do
      Assert.AreEqual(LExpected[LIndex], LActual[LIndex]);
  finally
    LActual.Free;
    LExpected.Free;
  end;
end;

procedure TTestToolsSettingsStore.DovrebbeLeggereGliStessiValoriDelVecchioCodice;
const
  TITLES: array[0..3] of string = ('plain', 'lowercase', 'noval', 'dup');
var
  LResults: TArray<string>;
  LValues: TArray<string>;
  LTexts: array[0..3] of string;
  LIndex: Integer;
  LPair: TArray<string>;
begin
  LTexts[0] := '[File Menu History]'#13#10'FILEMENUHISTORY0=C:\a.bin'#13#10'FILEMENUHISTORY1=C:\b.bin'#13#10#13#10 +
    '[Options]'#13#10'SHOWGRID=1'#13#10'ZOOM=12'#13#10'TEXTARTMETHOD=2'#13#10;
  LTexts[1] := 'showgrid = 1'#13#10'zoom=  5  '#13#10'textartmethod=4'#13#10'filemenuhistory9 = x:\y';
  LTexts[2] := 'SHOWGRID='#13#10'ZOOM=abc'#13#10'TEXTARTMETHOD=3'#13#10'FILEMENUHISTORY0='#13#10'# comment'#13#10'ZOOM=9=9';
  LTexts[3] := 'ZOOM=3'#13#10'ZOOM=4'#13#10'SHOWGRID=2';
  LResults := TToolsGolden.Lines('ToolsCore\old.golden.txt', 'LOADRES');
  LValues := TToolsGolden.Lines('ToolsCore\old.golden.txt', 'LOAD');
  Assert.AreEqual(4, Length(LResults));
  for LIndex := 0 to 3 do
  begin
    LPair := LoadedLine(TITLES[LIndex], LTexts[LIndex]).Split([#1]);
    Assert.AreEqual(LResults[LIndex], LPair[0]);
    Assert.AreEqual(LValues[LIndex], LPair[1]);
  end;
end;

end.
