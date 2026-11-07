{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the obituary library - the formatter                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Obituary.Formatter;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework,
  DelphiDoom.Obituary.Types, DelphiDoom.Obituary.Intf;

type
  /// <summary>
  ///   The lines F of Tests\Data\Obituary\obituary.golden.txt were written by the old
  ///   P_Obituary (a StringReplace for each placeholder) for every placeholder and gender,
  ///   in upper case, with unknown placeholders and with texts without any. The lines R are
  ///   the names that contain a placeholder: the old code replaced them again, the library
  ///   does not (a wanted difference, covered by the tests at the end)
  /// </summary>
  [TestFixture]
  [Category('obituary')]
  TTestObituaryFormatter = class(TObject)
  private
    FFormatter: IObituaryFormatter;
    FGolden: TStringList;
    function Compose(const AModel, AVictim, AKiller: string;
      AVictimGender: TObituaryGender = ogDefault;
      AKillerGender: TObituaryGender = ogDefault): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLoStessoTestoDelVecchioCodice;
    [Test]
    procedure DovrebbeUsareIlGenereDellaVittimaPerGELaltroPerIlResto;
    [Test]
    procedure DovrebbeSostituireIPlaceholderInOgniMaiuscola;
    [Test]
    procedure DovrebbeLasciareIlTestoSenzaPlaceholder;
    [Test]
    procedure DovrebbeLasciareIPlaceholderSconosciuti;
    [Test]
    procedure DovrebbeLasciareUnPercentualeFinale;
    [Test]
    procedure DovrebbeDareUnTestoVuotoPerUnModelloVuoto;
    [Test]
    procedure DovrebbeSostituireIPlaceholderRipetuti;
    [Test]
    procedure NonDovrebbeSostituireDiNuovoUnPlaceholderDentroUnNome;
    [Test]
    procedure NonDovrebbeUnireUnPercentualeDelNomeALettereDelModello;
    [Test]
    procedure DovrebbeRifiutareUnGenereSconosciuto;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaNil;
  end;

implementation

uses
  DelphiDoom.Obituary.Factory;

{ TTestObituaryFormatter }

procedure TTestObituaryFormatter.Setup;
begin
  FFormatter := TObituaryFactory.CreateFormatter(TObituaryFactory.CreateGenders);
  FGolden := TStringList.Create;
  FGolden.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Obituary\obituary.golden.txt')), TEncoding.UTF8);
end;

procedure TTestObituaryFormatter.TearDown;
begin
  FGolden.Free;
  FFormatter := nil;
end;

function TTestObituaryFormatter.Compose(const AModel, AVictim, AKiller: string;
  AVictimGender, AKillerGender: TObituaryGender): string;
begin
  Result := FFormatter.Compose(AModel, AVictim, AKiller, AVictimGender, AKillerGender);
end;

procedure TTestObituaryFormatter.DovrebbeDareLoStessoTestoDelVecchioCodice;
var
  LLine: string;
  LParts: TArray<string>;
  LCount: Integer;
begin
  LCount := 0;
  for LLine in FGolden do
    if Copy(LLine, 1, 2) = 'F'#9 then
    begin
      LParts := LLine.Split([#9]);
      Assert.AreEqual(LParts[6],
        Compose(LParts[1], LParts[2], LParts[3], TObituaryGender(StrToInt(LParts[4])),
          TObituaryGender(StrToInt(LParts[5]))),
        'model "' + LParts[1] + '" victim ' + LParts[4] + ' killer ' + LParts[5]);
      Inc(LCount);
    end;
  Assert.IsTrue(LCount >= 150, 'the golden file has the cases');
end;

procedure TTestObituaryFormatter.DovrebbeUsareIlGenereDellaVittimaPerGELaltroPerIlResto;
begin
  Assert.AreEqual('he her her hers she''s',
    Compose('%g %h %p %s %r', 'A', 'B', ogMale, ogFemale));
  Assert.AreEqual('she it its its it''s',
    Compose('%g %h %p %s %r', 'A', 'B', ogFemale, ogNeutral));
end;

procedure TTestObituaryFormatter.DovrebbeSostituireIPlaceholderInOgniMaiuscola;
begin
  Assert.AreEqual('Player 1 Imp they them their theirs they''re',
    Compose('%O %K %G %H %P %S %R', 'Player 1', 'Imp', ogTeam, ogPlural));
  Assert.AreEqual('Player 1 Imp',
    Compose('%o %K', 'Player 1', 'Imp'));
end;

procedure TTestObituaryFormatter.DovrebbeLasciareIlTestoSenzaPlaceholder;
begin
  Assert.AreEqual('nothing to do', Compose('nothing to do', 'A', 'B'));
end;

procedure TTestObituaryFormatter.DovrebbeLasciareIPlaceholderSconosciuti;
begin
  Assert.AreEqual('%x %y %1 %%', Compose('%x %y %1 %%', 'A', 'B'));
  Assert.AreEqual('%A', Compose('%%o', 'A', 'B'));
end;

procedure TTestObituaryFormatter.DovrebbeLasciareUnPercentualeFinale;
begin
  Assert.AreEqual('100%', Compose('100%', 'A', 'B'));
  Assert.AreEqual('%', Compose('%', 'A', 'B'));
end;

procedure TTestObituaryFormatter.DovrebbeDareUnTestoVuotoPerUnModelloVuoto;
begin
  Assert.AreEqual('', Compose('', 'A', 'B'));
end;

procedure TTestObituaryFormatter.DovrebbeSostituireIPlaceholderRipetuti;
begin
  Assert.AreEqual('AABB', Compose('%o%o%k%k', 'A', 'B'));
end;

procedure TTestObituaryFormatter.NonDovrebbeSostituireDiNuovoUnPlaceholderDentroUnNome;
begin
  // the old code gave "x died to x": %o became "%k", that became the name of the killer
  Assert.AreEqual('%k died to x', Compose('%o died to %k', '%k', 'x'));
  Assert.AreEqual('Player %g died to Imp %p',
    Compose('%o died to %k', 'Player %g', 'Imp %p', ogMale, ogFemale));
  Assert.AreEqual('%o and %o', Compose('%k and %o', '%o', '%o'));
  Assert.AreEqual('Mr %K by Dr %O', Compose('%o by %k', 'Mr %K', 'Dr %O', ogTeam, ogTeam));
end;

procedure TTestObituaryFormatter.NonDovrebbeUnireUnPercentualeDelNomeALettereDelModello;
begin
  // the name ends with % and the model goes on with k: the old code read "%k" and replaced it
  Assert.AreEqual('100%k', Compose('%ok', '100%', 'Imp'));
  // a % of the model followed by a placeholder: the old code turned "%%o" into "%Player 1" and
  // then read "%P" of the name as the possessive ("herlayer 1")
  Assert.AreEqual('%Player 1', Compose('%%o', 'Player 1', 'Imp', ogDefault, ogFemale));
  Assert.AreEqual('%%Player 1', Compose('%%%o','Player 1', 'Imp', ogDefault, ogFemale));
end;

procedure TTestObituaryFormatter.DovrebbeRifiutareUnGenereSconosciuto;
begin
  Assert.WillRaise(
    procedure
    begin
      Compose('%g', 'A', 'B', TObituaryGender(OBITUARY_GENDER_COUNT), ogDefault);
    end,
    EObituaryException);
end;

procedure TTestObituaryFormatter.DovrebbeRifiutareUnaTabellaNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TObituaryFactory.CreateFormatter(nil);
    end,
    EArgumentNilException);
end;

end.
