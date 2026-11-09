{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom ruleset library - offsets of the mods and the  }
{  craft weapon (the parity is in DelphiDoom.Tests.XcomMod.Golden)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomMod.ModOffsets;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.ModOffsets;

type
  [TestFixture]
  [Category('xcom-mod')]
  TTestXcomModOffsets = class(TObject)
  private
    FOffsets: TXcomModOffsets;
    function Node(const AText: string): IYamlNode;
    function Load(const AText, ASet: string; AShared: Integer = 20; ADefault: Integer = -1): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeLasciareUnIdPiccoloEMuovereUnIdGrande;
    [Test]
    procedure DovrebbeLeggereUnNumeroSenzaSpostarloSottoIlLimiteComune;
    [Test]
    procedure DovrebbeSommareLOffsetDelModCorrente;
    [Test]
    procedure DovrebbeLeggereUnaMappaConIlNomeDiUnAltroMod;
    [Test]
    procedure DovrebbeUsareIlModMasterEQuelloCorrente;
    [Test]
    procedure DovrebbeLasciareMenoUnoCosiCom;
    [Test]
    procedure DovrebbeRifiutareUnOffsetSottoMenoUno;
    [Test]
    procedure DovrebbeRifiutareUnOffsetOltreLaDimensioneDelMod;
    [Test]
    procedure DovrebbeRifiutareUnModSconosciuto;
    [Test]
    procedure DovrebbeLasciareIlValoreSeIlNodoNonELeggibile;
    [Test]
    procedure DovrebbeLeggereUnaListaDiSuoni;
    [Test]
    procedure DovrebbeLeggereUnSoloSuonoComeLista;
    [Test]
    procedure DovrebbeNonToccareNulaSeIlNodoNonCe;
    [Test]
    procedure DovrebbeContareUnCentesimoPerLeTrasparenze;
    [Test]
    procedure DovrebbeRifiutareUnaListaVuotaODiModVuota;
  end;

implementation

uses
  DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Factory, DelphiDoom.XcomMod.Types;

type
  TFakeShared = class(TInterfacedObject, IXcomSharedResources)
  public
    function MaxSharedSounds(const ASet: string): Integer;
    function MaxSharedFrames(const ASet: string): Integer;
  end;

function TFakeShared.MaxSharedSounds(const ASet: string): Integer;
begin
  Result := 20;
end;

function TFakeShared.MaxSharedFrames(const ASet: string): Integer;
begin
  Result := 30;
end;

{ TTestXcomModOffsets }

procedure TTestXcomModOffsets.Setup;
begin
  FOffsets := TXcomModOffsets.Create([TXcomModData.Make('master', 0, 1000), TXcomModData.Make('xcom1', 1000, 500),
    TXcomModData.Make('mymod', 2000, 300)], 2, TFakeShared.Create);
end;

procedure TTestXcomModOffsets.TearDown;
begin
  FOffsets.Free;
end;

function TTestXcomModOffsets.Node(const AText: string): IYamlNode;
begin
  Result := TYamlFactory.CreateParser.Load(YamlStringToText(AText));
end;

function TTestXcomModOffsets.Load(const AText, ASet: string; AShared, ADefault: Integer): Integer;
begin
  Result := ADefault;
  FOffsets.LoadOffsetNode('STR_X', Result, Node(AText), AShared, ASet);
end;

procedure TTestXcomModOffsets.DovrebbeLasciareUnIdPiccoloEMuovereUnIdGrande;
begin
  Assert.AreEqual(5, FOffsets.GetOffset(5, 5));
  Assert.AreEqual(-3, FOffsets.GetOffset(-3, 5));
  Assert.AreEqual(2006, FOffsets.GetOffset(6, 5));
end;

procedure TTestXcomModOffsets.DovrebbeLeggereUnNumeroSenzaSpostarloSottoIlLimiteComune;
begin
  Assert.AreEqual(19, Load('19', 'GEO.CAT'));
  Assert.AreEqual(20 + 2000, Load('20', 'GEO.CAT'));
end;

procedure TTestXcomModOffsets.DovrebbeSommareLOffsetDelModCorrente;
begin
  Assert.AreEqual(2030, Load('30', 'GEO.CAT'));
end;

procedure TTestXcomModOffsets.DovrebbeLeggereUnaMappaConIlNomeDiUnAltroMod;
begin
  Assert.AreEqual(1100, Load('{index: 100, mod: xcom1}', 'GEO.CAT'));
end;

procedure TTestXcomModOffsets.DovrebbeUsareIlModMasterEQuelloCorrente;
begin
  Assert.AreEqual(100, Load('{index: 100, mod: master}', 'GEO.CAT'));
  Assert.AreEqual(2100, Load('{index: 100, mod: current}', 'GEO.CAT'));
end;

procedure TTestXcomModOffsets.DovrebbeLasciareMenoUnoCosiCom;
begin
  Assert.AreEqual(-1, Load('-1', 'GEO.CAT'));
end;

procedure TTestXcomModOffsets.DovrebbeRifiutareUnOffsetSottoMenoUno;
var
  LMessage: string;
begin
  LMessage := '';
  try
    Load('-2', 'GEO.CAT');
  except
    on E: EXcomModException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('Error for ''STR_X'': offset ''-2'' has incorrect value in set ''GEO.CAT'' at line 0', LMessage);
end;

procedure TTestXcomModOffsets.DovrebbeRifiutareUnOffsetOltreLaDimensioneDelMod;
var
  LMessage: string;
begin
  LMessage := '';
  try
    Load('301', 'GEO.CAT');
  except
    on E: EXcomModException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('Error for ''STR_X'': offset ''301'' exceeds mod size limit 300 in set ''GEO.CAT''', LMessage);
  // the limit is inclusive: 300 is allowed
  Assert.AreEqual(2300, Load('300', 'GEO.CAT'));
end;

procedure TTestXcomModOffsets.DovrebbeRifiutareUnModSconosciuto;
var
  LMessage: string;
begin
  LMessage := '';
  try
    Load('{index: 1, mod: nomod}', 'GEO.CAT');
  except
    on E: EXcomModException do
      LMessage := E.Message;
  end;
  Assert.AreEqual('Error for ''STR_X'': unknown mod ''nomod'' used', LMessage);
end;

procedure TTestXcomModOffsets.DovrebbeLasciareIlValoreSeIlNodoNonELeggibile;
begin
  // a sequence is neither a scalar nor a map: the offset stays what it was (and is still checked)
  Assert.AreEqual(7, Load('[1, 2]', 'GEO.CAT', 20, 7));
  Assert.AreEqual(2027, Load('[1, 2]', 'GEO.CAT', 20, 27));
  Assert.AreEqual(-1, Load('[1, 2]', 'GEO.CAT'));
end;

procedure TTestXcomModOffsets.DovrebbeLeggereUnaListaDiSuoni;
var
  LSounds: TArray<Integer>;
begin
  LSounds := TArray<Integer>.Create(9);
  FOffsets.LoadSoundOffset('STR_X', LSounds, Node('[3, 25, -1, {index: 4, mod: master}]'), 'GEO.CAT');
  Assert.AreEqual(4, Integer(Length(LSounds)));
  Assert.AreEqual(3, LSounds[0]);
  Assert.AreEqual(2025, LSounds[1]);
  Assert.AreEqual(-1, LSounds[2]);
  Assert.AreEqual(4, LSounds[3]);
end;

procedure TTestXcomModOffsets.DovrebbeLeggereUnSoloSuonoComeLista;
var
  LSounds: TArray<Integer>;
begin
  FOffsets.LoadSoundOffset('STR_X', LSounds, Node('30'), 'GEO.CAT');
  Assert.AreEqual(1, Integer(Length(LSounds)));
  Assert.AreEqual(2030, LSounds[0]);
end;

procedure TTestXcomModOffsets.DovrebbeNonToccareNulaSeIlNodoNonCe;
var
  LSound: Integer;
  LSounds: TArray<Integer>;
  LEmpty: IYamlNode;
begin
  LEmpty := Node('a: 1').Find('b');
  LSound := 42;
  FOffsets.LoadSoundOffset('STR_X', LSound, LEmpty, 'GEO.CAT');
  Assert.AreEqual(42, LSound);
  LSounds := TArray<Integer>.Create(1, 2);
  FOffsets.LoadSoundOffset('STR_X', LSounds, LEmpty, 'GEO.CAT');
  Assert.AreEqual(2, Integer(Length(LSounds)));
end;

procedure TTestXcomModOffsets.DovrebbeContareUnCentesimoPerLeTrasparenze;
var
  LIndex: Integer;
begin
  // the size of the mod is divided by 100 (3) and so is its offset (20)
  LIndex := -1;
  FOffsets.LoadTransparencyOffset('STR_X', LIndex, Node('2'));
  Assert.AreEqual(22, LIndex);
  Assert.WillRaise(
    procedure
    var
      LOther: Integer;
    begin
      LOther := -1;
      FOffsets.LoadTransparencyOffset('STR_X', LOther, Node('4'));
    end, EXcomModException);
end;

procedure TTestXcomModOffsets.DovrebbeRifiutareUnaListaVuotaODiModVuota;
begin
  Assert.WillRaise(
    procedure
    begin
      TXcomModOffsets.Create(nil, 0, TFakeShared.Create).Free;
    end, EXcomModException);
  Assert.WillRaise(
    procedure
    begin
      TXcomModOffsets.Create([TXcomModData.Make('a', 0, 1)], 1, TFakeShared.Create).Free;
    end, EXcomModException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomModOffsets);

end.
