{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedSettings and TGreedSettingsStore                  }
{                                                                              }
{  The oracle is M_LoadDefaults and M_SaveDefaults of m_defs.pas of xGreed as   }
{  they were (the table typed again from the original, the pointers to the      }
{  globals replaced by arrays)                                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Settings;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Greed.Save.Intf, DelphiDoom.Greed.Settings.Intf;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedSettings = class(TObject)
  private
    FSut: IGreedSettings;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeAvereLe42ImpostazioniNellOrdineOriginale;
    [Test]
    procedure DovrebbeAvereIValoriDiDefault;
    [Test]
    procedure DovrebbeLeggereGliInteriIBooleaniELeStringhe;
    [Test]
    procedure DovrebbeIgnorareUnNomeSconosciuto;
    [Test]
    procedure DovrebbeLasciareUnInteroVuotoComE;
    [Test]
    procedure DovrebbeLeggereIBooleaniComeLOriginale;
    [Test]
    procedure DovrebbeSollevareConUnNomeSconosciutoOUnTipoSbagliato;
    [Test]
    procedure DovrebbeTagliareUnaStringaA255Caratteri;
    [Test]
    procedure DovrebbeDareIlGiocoDellEpisodio;
    [Test]
    procedure DovrebbeApplicareIlGiocoDellaRigaDiComando;
    [Test]
    procedure DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
    [Test]
    procedure DovrebbeLeggereInteriInTuttiIFormati;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedSettingsStore = class(TObject)
  public
    [Test]
    procedure DovrebbeUsareIDefaultSeIlFileNonCe;
    [Test]
    procedure DovrebbeSalvareERileggere;
    [Test]
    procedure DovrebbeApplicareLaRigaDiComandoDopoLEpisodioDelFile;
    [Test]
    procedure DovrebbeRimettereIDefaultPrimaDiLeggere;
    [Test]
    procedure DovrebbeSollevareSenzaFile;
  end;

implementation

uses
  System.Classes, DelphiDoom.Greed.Types, DelphiDoom.Tests.Greed.SaveGames, DelphiDoom.Greed.Settings, DelphiDoom.Greed.SettingsStore;

type
  TOldKind = (tString, tBoolean, tInteger);

  TOldDefault = record
    name: string;
    _type: TOldKind;
    defaultivalue: Integer;
  end;

const
  // the defaults table of m_defs.pas, with the values of the SC_* of d_ints_h.pas
  OLD_DEFAULTS: array[0..41] of TOldDefault = (
    (name: 'ambientlight'; _type: tInteger; defaultivalue: 2048),
    (name: 'violence'; _type: tBoolean; defaultivalue: 1),
    (name: 'animation'; _type: tBoolean; defaultivalue: 1),
    (name: 'musicvol'; _type: tInteger; defaultivalue: 100),
    (name: 'sfxvol'; _type: tInteger; defaultivalue: 128),
    (name: 'bt_north'; _type: tInteger; defaultivalue: $48),
    (name: 'bt_east'; _type: tInteger; defaultivalue: $4D),
    (name: 'bt_south'; _type: tInteger; defaultivalue: $50),
    (name: 'bt_west'; _type: tInteger; defaultivalue: $4B),
    (name: 'bt_fire'; _type: tInteger; defaultivalue: $1D),
    (name: 'bt_straf'; _type: tInteger; defaultivalue: $38),
    (name: 'bt_use'; _type: tInteger; defaultivalue: $39),
    (name: 'bt_run'; _type: tInteger; defaultivalue: $2A),
    (name: 'bt_jump'; _type: tInteger; defaultivalue: $2C),
    (name: 'bt_useitem'; _type: tInteger; defaultivalue: $2D),
    (name: 'bt_asscam'; _type: tInteger; defaultivalue: $1E),
    (name: 'bt_lookup'; _type: tInteger; defaultivalue: $49),
    (name: 'bt_lookdown'; _type: tInteger; defaultivalue: $51),
    (name: 'bt_centerview'; _type: tInteger; defaultivalue: $47),
    (name: 'bt_slideleft'; _type: tInteger; defaultivalue: $33),
    (name: 'bt_slideright'; _type: tInteger; defaultivalue: $34),
    (name: 'bt_invleft'; _type: tInteger; defaultivalue: $52),
    (name: 'bt_invright'; _type: tInteger; defaultivalue: $53),
    (name: 'bt_motionmode'; _type: tInteger; defaultivalue: $1F),
    (name: 'gameepisode'; _type: tInteger; defaultivalue: 1),
    (name: 'screensize'; _type: tInteger; defaultivalue: 4),
    (name: 'camdelay'; _type: tInteger; defaultivalue: 35),
    (name: 'headbobon'; _type: tBoolean; defaultivalue: 1),
    (name: 'weapbobon'; _type: tBoolean; defaultivalue: 1),
    (name: 'vid_pillarbox_pct'; _type: tInteger; defaultivalue: 17),
    (name: 'slopeprecise'; _type: tBoolean; defaultivalue: 1),
    (name: 'interpolate'; _type: tBoolean; defaultivalue: 1),
    (name: 'doubleblit'; _type: tBoolean; defaultivalue: 1),
    (name: 'lowresolution'; _type: tBoolean; defaultivalue: 0),
    (name: 'mouse'; _type: tBoolean; defaultivalue: 1),
    (name: 'menumouse'; _type: tBoolean; defaultivalue: 1),
    (name: 'mousesensitivity'; _type: tInteger; defaultivalue: 10),
    (name: 'mousesensitivityx'; _type: tInteger; defaultivalue: 10),
    (name: 'mousesensitivityy'; _type: tInteger; defaultivalue: 5),
    (name: 'invertmouseturn'; _type: tBoolean; defaultivalue: 0),
    (name: 'invertmouselook'; _type: tBoolean; defaultivalue: 0),
    (name: 'maindatafile'; _type: tString; defaultivalue: 0));

var
  OldInt: array[0..41] of Integer;
  OldBool: array[0..41] of Boolean;
  OldStr: array[0..41] of string[255];

// atoi of g_delphi.pas, as it was
function OldAtoi(const s: string): integer;
var
  code: integer;
  ret2: integer;
begin
  val(s, result, code);
  if code <> 0 then
  begin
    ret2 := 0;
    if Pos('0x', s) = 1 then
      val('$' + Copy(s, 3, Length(s) - 2), ret2, code)
    else if Pos('-0x', s) = 1 then
    begin
      val('$' + Copy(s, 4, Length(s) - 3), ret2, code);
      ret2 := -ret2;
    end
    else if Pos('#', s) = 1 then
      val(Copy(s, 2, Length(s) - 1), ret2, code);
    if code = 0 then
      result := ret2
    else
      result := 0;
  end;
end;

// M_LoadDefaults, without the command line and the flags of the game
function OldLoad(const AText: string): Boolean;
var
  i, j, idx: integer;
  s: TStringList;
  n, v: string;
begin
  for i := 0 to 41 do
    if OLD_DEFAULTS[i]._type = tInteger then
      OldInt[i] := OLD_DEFAULTS[i].defaultivalue
    else if OLD_DEFAULTS[i]._type = tBoolean then
      OldBool[i] := OLD_DEFAULTS[i].defaultivalue <> 0
    else
      OldStr[i] := '';
  s := TStringList.Create;
  try
    s.Text := AText;
    for i := 0 to s.Count - 1 do
    begin
      idx := -1;
      n := s.Names[i];
      for j := 0 to 41 do
        if OLD_DEFAULTS[j].name = n then
        begin
          idx := j;
          Break;
        end;
      if idx > -1 then
      begin
        v := s.Values[n];
        if OLD_DEFAULTS[idx]._type = tInteger then
        begin
          if v <> '' then
            OldInt[idx] := OldAtoi(v)
        end
        else if OLD_DEFAULTS[idx]._type = tBoolean then
          OldBool[idx] := (v <> '0') and (v <> '')
        else
          OldStr[idx] := v;
      end;
    end;
    Result := s.Count > 0;
  finally
    s.Free;
  end;
end;

// M_SaveDefaults
function OldSave: string;
var
  i: integer;
  s: TStringList;
begin
  s := TStringList.Create;
  try
    for i := 0 to 41 do
      if OLD_DEFAULTS[i]._type = tInteger then
        s.Add(OLD_DEFAULTS[i].name + '=' + IntToStr(OldInt[i]))
      else if OLD_DEFAULTS[i]._type = tBoolean then
      begin
        if OldBool[i] then
          s.Add(OLD_DEFAULTS[i].name + '=1')
        else
          s.Add(OLD_DEFAULTS[i].name + '=0');
      end
      else
        s.Add(OLD_DEFAULTS[i].name + '=' + string(OldStr[i]));
    Result := s.Text;
  finally
    s.Free;
  end;
end;

{ TTestGreedSettings }

procedure TTestGreedSettings.Setup;
begin
  FSut := TGreedSettings.Create;
end;

procedure TTestGreedSettings.DovrebbeAvereLe42ImpostazioniNellOrdineOriginale;
var
  LIndex: Integer;
begin
  Assert.AreEqual(42, FSut.Count);
  for LIndex := 0 to 41 do
    Assert.AreEqual(OLD_DEFAULTS[LIndex].name, FSut.NameOf(LIndex));
end;

procedure TTestGreedSettings.DovrebbeAvereIValoriDiDefault;
begin
  Assert.AreEqual(2048, FSut.GetInteger('ambientlight'));
  Assert.IsTrue(FSut.GetBoolean('violence'));
  Assert.IsFalse(FSut.GetBoolean('lowresolution'));
  Assert.AreEqual($48, FSut.GetInteger('bt_north'));
  Assert.AreEqual('', FSut.GetString('maindatafile'));
  Assert.AreEqual(1, FSut.Episode);
end;

procedure TTestGreedSettings.DovrebbeLeggereGliInteriIBooleaniELeStringhe;
begin
  Assert.IsTrue(FSut.LoadFromText('musicvol=55'#13#10'violence=0'#13#10'maindatafile=C:\X\GREED.BLO'#13#10));
  Assert.AreEqual(55, FSut.GetInteger('musicvol'));
  Assert.IsFalse(FSut.GetBoolean('violence'));
  Assert.AreEqual('C:\X\GREED.BLO', FSut.GetString('maindatafile'));
end;

procedure TTestGreedSettings.DovrebbeIgnorareUnNomeSconosciuto;
begin
  Assert.IsTrue(FSut.LoadFromText('nonesiste=7'#13#10'garbage'#13#10));
  Assert.AreEqual(100, FSut.GetInteger('musicvol'));
end;

procedure TTestGreedSettings.DovrebbeLasciareUnInteroVuotoComE;
begin
  FSut.LoadFromText('musicvol='#13#10);
  Assert.AreEqual(100, FSut.GetInteger('musicvol'));
end;

procedure TTestGreedSettings.DovrebbeLeggereIBooleaniComeLOriginale;
begin
  FSut.LoadFromText('violence=abc'#13#10'animation='#13#10'mouse=2'#13#10'menumouse=0');
  Assert.IsTrue(FSut.GetBoolean('violence'));
  Assert.IsFalse(FSut.GetBoolean('animation'));
  Assert.IsTrue(FSut.GetBoolean('mouse'));
  Assert.IsFalse(FSut.GetBoolean('menumouse'));
end;

procedure TTestGreedSettings.DovrebbeSollevareConUnNomeSconosciutoOUnTipoSbagliato;
begin
  Assert.WillRaise(
    procedure
    begin
      FSut.GetInteger('nonesiste');
    end, EGreedNotFoundException);
  Assert.WillRaise(
    procedure
    begin
      FSut.GetBoolean('musicvol');
    end, EGreedNotFoundException);
  Assert.WillRaise(
    procedure
    begin
      FSut.KindOf('nonesiste');
    end, EGreedNotFoundException);
  Assert.WillRaise(
    procedure
    begin
      FSut.NameOf(42);
    end, EGreedException);
  Assert.AreEqual(Ord(gskBoolean), Ord(FSut.KindOf('violence')));
end;

procedure TTestGreedSettings.DovrebbeTagliareUnaStringaA255Caratteri;
begin
  FSut.SetString('maindatafile', StringOfChar('a', 300));
  Assert.AreEqual(255, Length(FSut.GetString('maindatafile')));
end;

procedure TTestGreedSettings.DovrebbeDareIlGiocoDellEpisodio;
begin
  Assert.AreEqual(Ord(ggvGame1), Ord(FSut.GetGameVariant));
  FSut.Episode := 2;
  Assert.AreEqual(Ord(ggvGame2), Ord(FSut.GetGameVariant));
  FSut.Episode := 3;
  Assert.AreEqual(Ord(ggvGame3), Ord(FSut.GetGameVariant));
  FSut.Episode := 9;
  Assert.AreEqual(Ord(ggvGame1), Ord(FSut.GetGameVariant));
end;

procedure TTestGreedSettings.DovrebbeApplicareIlGiocoDellaRigaDiComando;
begin
  FSut.ApplyCommandLineGame(0);
  Assert.AreEqual(1, FSut.Episode);
  FSut.ApplyCommandLineGame(3);
  Assert.AreEqual(3, FSut.Episode);
  FSut.ApplyCommandLineGame(0);
  Assert.AreEqual(3, FSut.Episode);
  FSut.ApplyCommandLineGame(7);
  Assert.AreEqual(3, FSut.Episode);
end;

procedure TTestGreedSettings.DovrebbeDareGliStessiRisultatiDelCodiceOriginale;
const
  VALUES: array[0..15] of string = ('', '0', '1', '-5', '0x1F', '-0x10', '#12', 'abc', '$FF', ' 7', '7 ',
    '2147483647', '99999999999', '12.5', 'C:\GAME\GREED.BLO', '2');
var
  LSeed: Cardinal;
  LCase, LLines, LLine, LIndex: Integer;
  LText, LName: string;
  LOldLoaded, LNewLoaded: Boolean;
begin
  LSeed := 987654321;
  for LCase := 1 to 3000 do
  begin
    LText := '';
    LLines := (LSeed shr 7) mod 12;
    for LLine := 1 to LLines do
    begin
      LSeed := LSeed * 1664525 + 1013904223;
      LIndex := (LSeed shr 8) mod 46;
      if LIndex < 42 then
        LName := OLD_DEFAULTS[LIndex].name
      else
        LName := 'zz' + IntToStr(LIndex);
      LSeed := LSeed * 1664525 + 1013904223;
      // sometimes the same name in another case, or without the value
      case (LSeed shr 12) mod 6 of
        0: LName := UpperCase(LName);
        1: LName := LName + ' ';
      end;
      LSeed := LSeed * 1664525 + 1013904223;
      if (LSeed shr 9) mod 9 = 0 then
        LText := LText + LName + #13#10
      else
        LText := LText + LName + '=' + VALUES[(LSeed shr 10) mod 16] + #13#10;
    end;
    LOldLoaded := OldLoad(LText);
    FSut := TGreedSettings.Create;
    LNewLoaded := FSut.LoadFromText(LText);
    Assert.AreEqual(LOldLoaded, LNewLoaded, 'loaded ' + IntToStr(LCase));
    Assert.AreEqual(OldSave, FSut.SaveToText, 'text ' + IntToStr(LCase) + ':' + LText);
  end;
end;

procedure TTestGreedSettings.DovrebbeLeggereInteriInTuttiIFormati;
begin
  Assert.AreEqual(12, TGreedSettings.ParseInteger('12'));
  Assert.AreEqual(-3, TGreedSettings.ParseInteger('-3'));
  Assert.AreEqual($1F, TGreedSettings.ParseInteger('$1F'));
  Assert.AreEqual($1F, TGreedSettings.ParseInteger('0x1F'));
  Assert.AreEqual(-$10, TGreedSettings.ParseInteger('-0x10'));
  Assert.AreEqual(12, TGreedSettings.ParseInteger('#12'));
  Assert.AreEqual(0, TGreedSettings.ParseInteger('abc'));
  Assert.AreEqual(0, TGreedSettings.ParseInteger(''));
end;

{ TTestGreedSettingsStore }

procedure TTestGreedSettingsStore.DovrebbeUsareIDefaultSeIlFileNonCe;
var
  LSettings: IGreedSettings;
  LStore: IGreedSettingsStore;
begin
  LSettings := TGreedSettings.Create;
  LStore := TGreedSettingsStore.Create(TFakeSaveFiles.Create, GREED_SETTINGS_FILE);
  Assert.IsFalse(LStore.Load(LSettings, 0));
  Assert.AreEqual(100, LSettings.GetInteger('musicvol'));
end;

procedure TTestGreedSettingsStore.DovrebbeSalvareERileggere;
var
  LFiles: IGreedSaveFiles;
  LSettings, LOther: IGreedSettings;
  LStore: IGreedSettingsStore;
begin
  LFiles := TFakeSaveFiles.Create;
  LStore := TGreedSettingsStore.Create(LFiles, GREED_SETTINGS_FILE);
  LSettings := TGreedSettings.Create;
  LSettings.SetInteger('sfxvol', 77);
  LSettings.SetBoolean('lowresolution', True);
  LSettings.SetString('maindatafile', 'D:\GREED\GREED.BLO');
  LStore.Save(LSettings);
  Assert.IsTrue(LFiles.Exists('xGreed.ini'));
  LOther := TGreedSettings.Create;
  Assert.IsTrue(LStore.Load(LOther, 0));
  Assert.AreEqual(77, LOther.GetInteger('sfxvol'));
  Assert.IsTrue(LOther.GetBoolean('lowresolution'));
  Assert.AreEqual('D:\GREED\GREED.BLO', LOther.GetString('maindatafile'));
end;

procedure TTestGreedSettingsStore.DovrebbeApplicareLaRigaDiComandoDopoLEpisodioDelFile;
var
  LFiles: IGreedSaveFiles;
  LSettings: IGreedSettings;
  LStore: IGreedSettingsStore;
begin
  LFiles := TFakeSaveFiles.Create;
  LFiles.WriteAll('xGreed.ini', TEncoding.Default.GetBytes('gameepisode=2'#13#10));
  LStore := TGreedSettingsStore.Create(LFiles, GREED_SETTINGS_FILE);
  LSettings := TGreedSettings.Create;
  LStore.Load(LSettings, 0);
  Assert.AreEqual(2, LSettings.Episode);
  LStore.Load(LSettings, 3);
  Assert.AreEqual(3, LSettings.Episode);
end;

procedure TTestGreedSettingsStore.DovrebbeRimettereIDefaultPrimaDiLeggere;
var
  LFiles: IGreedSaveFiles;
  LSettings: IGreedSettings;
  LStore: IGreedSettingsStore;
begin
  LFiles := TFakeSaveFiles.Create;
  LStore := TGreedSettingsStore.Create(LFiles, GREED_SETTINGS_FILE);
  LSettings := TGreedSettings.Create;
  LSettings.SetInteger('musicvol', 3);
  LStore.Load(LSettings, 0);
  Assert.AreEqual(100, LSettings.GetInteger('musicvol'));
end;

procedure TTestGreedSettingsStore.DovrebbeSollevareSenzaFile;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedSettingsStore.Create(nil, GREED_SETTINGS_FILE);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedSettings);
  TDUnitX.RegisterTestFixture(TTestGreedSettingsStore);

end.
