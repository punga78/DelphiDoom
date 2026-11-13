{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the texts and file names of deh_base (DUnitX)          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Dehacked.BaseText;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('dehacked')]
  TTestDehackedBaseText = class
  public
    [Test]
    procedure DovrebbeDareGliStessiTestiDelVecchioDEHCStringToString;
    [Test]
    procedure DovrebbeDareGliStessiValoriDelVecchioDEHStringValue;
    [Test]
    procedure DovrebbeAggiungereIlPrefissoInCodaComeIlVecchioCodice;
    [Test]
    procedure DovrebbeLasciareUnNomeCheHaGiaIlPrefisso;
    [Test]
    procedure DovrebbeDareLeStesseRispostePerMunizioniArmiEClassiDelVecchioCodice;
    [Test]
    procedure DovrebbeProvareIlNomeConEstensioniELaCartellaDeiSalvataggi;
    [Test]
    procedure DovrebbeProvareIlNomeConPuntoSoloComeDato;
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  DelphiDoom.Dehacked.FileNames,
  DelphiDoom.Dehacked.Text,
  DelphiDoom.Dehacked.TokenName,
  DelphiDoom.Tests.InfoTables.LegacyDeh;

const
  Alphabet: array[0..11] of string = ('\', 'N', 'R', #10, #13, 'a', 'z', '1', '_', ' ', 'n', 'Q');

function RandomText: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Random(10) do
    Result := Result + Alphabet[Random(Length(Alphabet))];
end;

// what DEH_AmmoType, DEH_WeaponType and DEH_PlayerClass of the facade do with the library
function NewLookup(const AText: string; const ATokens: TDStringList; const APrefix: string): Integer;
begin
  if StrIsInteger(AText) then
    Result := atoi(AText, -1)
  else
    Result := ATokens.IndexOf(TDehackedTokenName.Canonical(AText, APrefix));
end;

procedure TTestDehackedBaseText.DovrebbeDareGliStessiTestiDelVecchioDEHCStringToString;
var
  LRound: Integer;
  LText: string;
begin
  RandSeed := 191;
  for LRound := 1 to 3000 do
  begin
    LText := RandomText;
    Assert.AreEqual(Legacy_DEH_CStringToString(LText), TDehackedText.CStringToString(LText), LText);
  end;
end;

procedure TTestDehackedBaseText.DovrebbeDareGliStessiValoriDelVecchioDEHStringValue;
var
  LRound: Integer;
  LText: string;
begin
  RandSeed := 192;
  for LRound := 1 to 3000 do
  begin
    LText := RandomText;
    Assert.AreEqual(Legacy_DEH_StringValue(LText), TDehackedText.StringValue(LText), LText);
  end;
end;

procedure TTestDehackedBaseText.DovrebbeAggiungereIlPrefissoInCodaComeIlVecchioCodice;
begin
  // a defect of the old code, kept: "clip" is looked for as "CLIPAM_"
  Assert.AreEqual('CLIPAM_', TDehackedTokenName.Canonical('clip', 'AM_'));
end;

procedure TTestDehackedBaseText.DovrebbeLasciareUnNomeCheHaGiaIlPrefisso;
begin
  Assert.AreEqual('AM_CLIP', TDehackedTokenName.Canonical('am_clip', 'AM_'));
end;

procedure TTestDehackedBaseText.DovrebbeDareLeStesseRispostePerMunizioniArmiEClassiDelVecchioCodice;
const
  Names: array[0..8] of string = ('clip', 'AM_CLIP', 'am_shell', 'wp_pistol', 'WP_FIST', 'PCLASS_FIGHTER', '3', '-1', 'xyz');
var
  LList: TDStringList;
  LName: string;
begin
  LList := TDStringList.Create;
  try
    LList.Add('AM_CLIP');
    LList.Add('AM_SHELL');
    LList.Add('WP_PISTOL');
    LList.Add('PCLASS_FIGHTER');
    LList.Add('CLIPAM_');
    for LName in Names do
    begin
      Assert.AreEqual(Legacy_DEH_AmmoType(LName, LList), NewLookup(LName, LList, 'AM_'), LName);
      Assert.AreEqual(Legacy_DEH_WeaponType(LName, LList), NewLookup(LName, LList, 'WP_'), LName);
      Assert.AreEqual(Legacy_DEH_PlayerClass(LName, LList), NewLookup(LName, LList, 'PCLASS_'), LName);
    end;
  finally
    LList.Free;
  end;
end;

procedure TTestDehackedBaseText.DovrebbeProvareIlNomeConEstensioniELaCartellaDeiSalvataggi;
var
  LNames: TArray<string>;
begin
  LNames := TDehackedFileNames.Candidates('patch',
    function(AName: string): string
    begin
      Result := 'save\' + AName;
    end);
  Assert.AreEqual(4, Length(LNames));
  Assert.AreEqual('patch.deh', LNames[0]);
  Assert.AreEqual('patch.bex', LNames[1]);
  // the folder names come from the last name to the first
  Assert.AreEqual('save\patch.bex', LNames[2]);
  Assert.AreEqual('save\patch.deh', LNames[3]);
end;

procedure TTestDehackedBaseText.DovrebbeProvareIlNomeConPuntoSoloComeDato;
var
  LNames: TArray<string>;
begin
  LNames := TDehackedFileNames.Candidates('my.deh',
    function(AName: string): string
    begin
      Result := AName;
    end);
  Assert.AreEqual(1, Length(LNames));
  Assert.AreEqual('my.deh', LNames[0]);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDehackedBaseText);

end.
