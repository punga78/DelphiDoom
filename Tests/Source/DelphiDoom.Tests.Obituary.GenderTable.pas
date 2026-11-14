{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the obituary library - the table of the genders        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Obituary.GenderTable;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Obituary.Types, DelphiDoom.Obituary.Intf;

type
  /// <summary>
  ///   The lines P and G of Tests\Data\Obituary\obituary.golden.txt were written by the old
  ///   GENDERINFO and R_GetGenderForName (Base\p_gender.pas)
  /// </summary>
  [TestFixture]
  [Category('obituary')]
  TTestObituaryGenderTable = class(TObject)
  private
    FGenders: IObituaryGenders;
    FGolden: TStringList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAvereSeiGeneri;
    [Test]
    procedure DovrebbeDareLeParoleDelVecchioGenderInfo;
    [Test]
    procedure DovrebbeTrovareIGeneriDelVecchioCodice;
    [TestCase('Numero', '2,2')]
    [TestCase('Esadecimale', '$3,3')]
    [TestCase('Cancelletto', '#4,4')]
    [TestCase('Nome', 'Female,2')]
    [TestCase('NomeMinuscolo', 'plural,3')]
    [TestCase('ConPrefisso', 'gender_team,4')]
    [TestCase('PrefissoMaiuscolo', 'GENDER_NEUTRAL,5')]
    [TestCase('FuoriIntervallo', '6,0')]
    [TestCase('Negativo', '-1,0')]
    [TestCase('Sconosciuto', 'robot,0')]
    [TestCase('Vuoto', ',0')]
    procedure DovrebbeTrovareUnGenerePerNome(const AText: string; AExpected: Integer);
    [Test]
    procedure DovrebbeDareIlNomeDiOgniGenere;
    [Test]
    procedure DovrebbeRifiutareUnGenereSconosciuto;
  end;

implementation

uses
  DelphiDoom.Obituary.Factory;

{ TTestObituaryGenderTable }

procedure TTestObituaryGenderTable.Setup;
begin
  FGenders := TObituaryFactory.CreateGenders;
  FGolden := TStringList.Create;
  FGolden.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Obituary\obituary.golden.txt')), TEncoding.UTF8);
end;

procedure TTestObituaryGenderTable.TearDown;
begin
  FGolden.Free;
  FGenders := nil;
end;

procedure TTestObituaryGenderTable.DovrebbeAvereSeiGeneri;
begin
  Assert.AreEqual(6, OBITUARY_GENDER_COUNT);
  Assert.AreEqual(5, Ord(High(TObituaryGender)));
end;

procedure TTestObituaryGenderTable.DovrebbeDareLeParoleDelVecchioGenderInfo;
var
  LLine: string;
  LParts: TArray<string>;
  LGender: TObituaryGender;
  LPronouns: TObituaryPronouns;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in FGolden do
    if Copy(LLine, 1, 2) = 'P'#9 then
    begin
      LParts := LLine.Split([#9]);
      LGender := TObituaryGender(StrToInt(LParts[1]));
      LPronouns := FGenders.PronounsOf(LGender);
      Assert.AreEqual(LParts[2], FGenders.NameOf(LGender));
      Assert.AreEqual(LParts[3], LPronouns.Subject);
      Assert.AreEqual(LParts[4], LPronouns.ObjectForm);
      Assert.AreEqual(LParts[5], LPronouns.Possessive);
      Assert.AreEqual(LParts[6], LPronouns.Independent);
      Assert.AreEqual(LParts[7], LPronouns.Contraction);
      Inc(LCount);
    end;
  Assert.AreEqual(6, LCount);
end;

procedure TTestObituaryGenderTable.DovrebbeTrovareIGeneriDelVecchioCodice;
var
  LLine: string;
  LParts: TArray<string>;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in FGolden do
    if Copy(LLine, 1, 2) = 'G'#9 then
    begin
      LParts := LLine.Split([#9]);
      Assert.AreEqual(StrToInt(LParts[2]), Integer(FGenders.FindByName(LParts[1])),
        'input "' + LParts[1] + '"');
      Inc(LCount);
    end;
  Assert.IsTrue(LCount >= 25, 'the golden file has the cases');
end;

procedure TTestObituaryGenderTable.DovrebbeTrovareUnGenerePerNome(const AText: string;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, Integer(FGenders.FindByName(AText)));
end;

procedure TTestObituaryGenderTable.DovrebbeDareIlNomeDiOgniGenere;
begin
  Assert.AreEqual('Default', FGenders.NameOf(ogDefault));
  Assert.AreEqual('Male', FGenders.NameOf(ogMale));
  Assert.AreEqual('Female', FGenders.NameOf(ogFemale));
  Assert.AreEqual('Plural', FGenders.NameOf(ogPlural));
  Assert.AreEqual('Team', FGenders.NameOf(ogTeam));
  Assert.AreEqual('Neutral', FGenders.NameOf(ogNeutral));
end;

procedure TTestObituaryGenderTable.DovrebbeRifiutareUnGenereSconosciuto;
begin
  Assert.WillRaise(
    procedure
    begin
      FGenders.PronounsOf(TObituaryGender(OBITUARY_GENDER_COUNT));
    end,
    EObituaryException);
  Assert.WillRaise(
    procedure
    begin
      FGenders.NameOf(TObituaryGender(OBITUARY_GENDER_COUNT));
    end,
    EObituaryException);
end;

end.
