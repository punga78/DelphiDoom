{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom surface library - the family name of a font    }
{  file (the bytes are made by the test: no font file is in the repository)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomSurface.TtfFamilyName;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.XcomSurface.TtfFamilyName;

type
  [TestFixture]
  [Category('xcom-surface')]
  TTestXcomSurfaceTtfFamilyName = class(TObject)
  strict private
    type
      TName = record
        PlatformId: Integer;
        LanguageId: Integer;
        NameId: Integer;
        Text: string;
      end;
    class function Name(APlatform, ALanguage, ANameId: Integer; const AText: string): TName; static;
    /// <summary>A font file with one table, "name" (or ATable), and the given records</summary>
    class function FontFile(const ANames: array of TName; const ATable: AnsiString = 'name'): TBytes; static;
  public
    [Test]
    procedure DovrebbeLeggereIlNomeDiWindowsInInglese;
    [Test]
    procedure DovrebbePreferireIlNomeDiWindowsAQuelloDelMacintosh;
    [Test]
    procedure DovrebbeLeggereIlNomeDelMacintoshSeEIlSolo;
    [Test]
    procedure DovrebbeIgnorareINomiCheNonSonoLaFamiglia;
    [Test]
    procedure DovrebbeDareFalsoSenzaLaTabellaDeiNomi;
    [Test]
    procedure DovrebbeDareFalsoSeIBytesNonSonoUnFont;
    [Test]
    procedure DovrebbeDareFalsoSeIlFileETroncato;
  end;

implementation

class function TTestXcomSurfaceTtfFamilyName.Name(APlatform, ALanguage, ANameId: Integer;
  const AText: string): TName;
begin
  Result.PlatformId := APlatform;
  Result.LanguageId := ALanguage;
  Result.NameId := ANameId;
  Result.Text := AText;
end;

class function TTestXcomSurfaceTtfFamilyName.FontFile(const ANames: array of TName;
  const ATable: AnsiString): TBytes;
const
  TABLE_OFFSET = 28;
var
  LStrings: TBytes;
  LText: TBytes;
  LIndex: Integer;
  LRecord: Integer;
  LChar: Char;
  LCount: Integer;

  procedure PutWord(AOffset, AValue: Integer);
  begin
    Result[AOffset] := Byte(AValue shr 8);
    Result[AOffset + 1] := Byte(AValue and $FF);
  end;

begin
  LStrings := nil;
  SetLength(Result, TABLE_OFFSET + 6 + Length(ANames) * 12);
  FillChar(Result[0], Length(Result), 0);
  // the offset table: version 1.0 and one table
  PutWord(0, 1);
  PutWord(4, 1);
  Move(ATable[1], Result[12], 4);
  PutWord(22, TABLE_OFFSET);
  // the name table: format 0, the count and where the strings start
  PutWord(TABLE_OFFSET + 2, Length(ANames));
  PutWord(TABLE_OFFSET + 4, 6 + Length(ANames) * 12);
  for LIndex := 0 to High(ANames) do
  begin
    LText := nil;
    LCount := 0;
    SetLength(LText, Length(ANames[LIndex].Text) * 2);
    for LChar in ANames[LIndex].Text do
      if ANames[LIndex].PlatformId = 1 then
      begin
        LText[LCount] := Byte(Ord(LChar));
        Inc(LCount);
      end
      else
      begin
        LText[LCount] := Byte(Ord(LChar) shr 8);
        LText[LCount + 1] := Byte(Ord(LChar) and $FF);
        Inc(LCount, 2);
      end;
    SetLength(LText, LCount);
    LRecord := TABLE_OFFSET + 6 + LIndex * 12;
    PutWord(LRecord, ANames[LIndex].PlatformId);
    PutWord(LRecord + 4, ANames[LIndex].LanguageId);
    PutWord(LRecord + 6, ANames[LIndex].NameId);
    PutWord(LRecord + 8, Length(LText));
    PutWord(LRecord + 10, Length(LStrings));
    LStrings := LStrings + LText;
  end;
  Result := Result + LStrings;
end;

procedure TTestXcomSurfaceTtfFamilyName.DovrebbeLeggereIlNomeDiWindowsInInglese;
var
  LName: string;
begin
  Assert.IsTrue(TXcomTtfFamilyName.TryRead(FontFile([Name(3, $410, 1, 'Carattere'), Name(3, $409, 1, 'My Font')]),
    LName));
  Assert.AreEqual('My Font', LName);
end;

procedure TTestXcomSurfaceTtfFamilyName.DovrebbePreferireIlNomeDiWindowsAQuelloDelMacintosh;
var
  LName: string;
begin
  Assert.IsTrue(TXcomTtfFamilyName.TryRead(FontFile([Name(3, $410, 1, 'Finestre'), Name(1, 0, 1, 'Mela')]), LName));
  Assert.AreEqual('Finestre', LName);
end;

procedure TTestXcomSurfaceTtfFamilyName.DovrebbeLeggereIlNomeDelMacintoshSeEIlSolo;
var
  LName: string;
begin
  Assert.IsTrue(TXcomTtfFamilyName.TryRead(FontFile([Name(1, 0, 1, 'Mela')]), LName));
  Assert.AreEqual('Mela', LName);
end;

procedure TTestXcomSurfaceTtfFamilyName.DovrebbeIgnorareINomiCheNonSonoLaFamiglia;
var
  LName: string;
begin
  // 2 is the style ("Bold"), 4 the full name
  Assert.IsTrue(TXcomTtfFamilyName.TryRead(FontFile([Name(3, $409, 2, 'Bold'), Name(3, $409, 1, 'Famiglia'),
    Name(3, $409, 4, 'Famiglia Bold')]), LName));
  Assert.AreEqual('Famiglia', LName);
  Assert.IsFalse(TXcomTtfFamilyName.TryRead(FontFile([Name(3, $409, 2, 'Bold')]), LName));
  Assert.AreEqual('', LName);
end;

procedure TTestXcomSurfaceTtfFamilyName.DovrebbeDareFalsoSenzaLaTabellaDeiNomi;
var
  LName: string;
begin
  Assert.IsFalse(TXcomTtfFamilyName.TryRead(FontFile([Name(3, $409, 1, 'My Font')], 'glyf'), LName));
end;

procedure TTestXcomSurfaceTtfFamilyName.DovrebbeDareFalsoSeIBytesNonSonoUnFont;
var
  LName: string;
begin
  Assert.IsFalse(TXcomTtfFamilyName.TryRead(nil, LName));
  Assert.IsFalse(TXcomTtfFamilyName.TryRead(TBytes.Create(1, 2, 3), LName));
  Assert.IsFalse(TXcomTtfFamilyName.TryRead(TBytes.Create(0, 1, 0, 0, 0, 9, 0, 0), LName));
end;

procedure TTestXcomSurfaceTtfFamilyName.DovrebbeDareFalsoSeIlFileETroncato;
var
  LFile: TBytes;
  LName: string;
begin
  LFile := FontFile([Name(3, $409, 1, 'My Font')]);
  // the text of the name is cut
  SetLength(LFile, Length(LFile) - 3);
  Assert.IsFalse(TXcomTtfFamilyName.TryRead(LFile, LName));
  // the records are cut
  SetLength(LFile, 36);
  Assert.IsFalse(TXcomTtfFamilyName.TryRead(LFile, LName));
end;

end.
