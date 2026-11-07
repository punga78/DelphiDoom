{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the obituary library - the genders without state       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Obituary.Genders;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Obituary.Types;

type
  /// <summary>
  ///   TObituaryGenders is what deh_main, sc_actordef and the ACTORDEF catalog of the engine
  ///   call in place of R_GetGenderForName and R_GenderName: the lines P and G of
  ///   Tests\Data\Obituary\obituary.golden.txt were written by the old p_gender.pas
  /// </summary>
  [TestFixture]
  [Category('obituary')]
  TTestObituaryGenders = class(TObject)
  private
    FGolden: TStringList;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLeParoleDelVecchioGenderInfo;
    [Test]
    procedure DovrebbeTrovareIGeneriDelVecchioCodice;
    [TestCase('Numero', '1,1')]
    [TestCase('ZeroX', '0x5,5')]
    [TestCase('Cancelletto', '#2,2')]
    [TestCase('CancellettoNonNumerico', '#x,0')]
    [TestCase('Nome', 'Male,1')]
    [TestCase('NomeMisto', 'nEuTrAl,5')]
    [TestCase('ConPrefisso', 'Gender_Female,2')]
    [TestCase('FuoriIntervallo', '99,0')]
    [TestCase('Sconosciuto', 'robot,0')]
    procedure DovrebbeTrovareUnGenerePerNome(const AText: string; AExpected: Integer);
    [Test]
    procedure DovrebbeDareIlNomeCheRitrovaLoStessoGenere;
    [Test]
    procedure DovrebbeRifiutareUnGenereSconosciuto;
  end;

implementation

uses
  DelphiDoom.Obituary.Genders;

{ TTestObituaryGenders }

procedure TTestObituaryGenders.Setup;
begin
  FGolden := TStringList.Create;
  FGolden.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Obituary\obituary.golden.txt')), TEncoding.UTF8);
end;

procedure TTestObituaryGenders.TearDown;
begin
  FGolden.Free;
end;

procedure TTestObituaryGenders.DovrebbeDareLeParoleDelVecchioGenderInfo;
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
      LPronouns := TObituaryGenders.PronounsOf(LGender);
      Assert.AreEqual(LParts[2], TObituaryGenders.NameOf(LGender));
      Assert.AreEqual(LParts[3], LPronouns.Subject);
      Assert.AreEqual(LParts[4], LPronouns.ObjectForm);
      Assert.AreEqual(LParts[5], LPronouns.Possessive);
      Assert.AreEqual(LParts[6], LPronouns.Independent);
      Assert.AreEqual(LParts[7], LPronouns.Contraction);
      Inc(LCount);
    end;
  Assert.AreEqual(6, LCount);
end;

procedure TTestObituaryGenders.DovrebbeTrovareIGeneriDelVecchioCodice;
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
      Assert.AreEqual(StrToInt(LParts[2]), Integer(TObituaryGenders.FindByName(LParts[1])),
        'input "' + LParts[1] + '"');
      Inc(LCount);
    end;
  Assert.IsTrue(LCount >= 25, 'the golden file has the cases');
end;

procedure TTestObituaryGenders.DovrebbeTrovareUnGenerePerNome(const AText: string;
  AExpected: Integer);
begin
  Assert.AreEqual(AExpected, Integer(TObituaryGenders.FindByName(AText)));
end;

procedure TTestObituaryGenders.DovrebbeDareIlNomeCheRitrovaLoStessoGenere;
var
  LGender: TObituaryGender;
begin
  // the engine writes the name of a gender (DEH_CurrentSettings) and reads it back
  for LGender := Low(TObituaryGender) to High(TObituaryGender) do
    Assert.AreEqual(Ord(LGender),
      Ord(TObituaryGenders.FindByName(TObituaryGenders.NameOf(LGender))));
end;

procedure TTestObituaryGenders.DovrebbeRifiutareUnGenereSconosciuto;
begin
  Assert.WillRaise(
    procedure
    begin
      TObituaryGenders.NameOf(TObituaryGender(OBITUARY_GENDER_COUNT));
    end,
    EObituaryException);
  Assert.WillRaise(
    procedure
    begin
      TObituaryGenders.PronounsOf(TObituaryGender(OBITUARY_GENDER_COUNT + 3));
    end,
    EObituaryException);
end;

end.
