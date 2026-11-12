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
    class function FontFile(const ANames: array of TName; const ATable: AnsiString = 'name'; ABase: Integer = 0): TBytes; static;
    /// <summary>A collection of two fonts, as a .ttc: "ttcf", the version, the count and the offsets of the fonts</summary>
    class function Collection(const AFirst, ASecond: array of TName): TBytes; static;
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
    [Test]
    procedure UnaRaccoltaDovrebbeDareLaFamigliaDelFontCheSiChiede;
    [Test]
    procedure SenzaIndiceUnaRaccoltaDovrebbeDareLaPrimaFamiglia;
    [Test]
    procedure UnIndiceCheLaRaccoltaNonHaDovrebbeDareFalso;
    [Test]
    procedure UnFontSingoloDovrebbeAvereSoloLIndiceZero;
    [Test]
    procedure DovrebbeContareIFontDelFile;
    [Test]
    procedure UnaRaccoltaTroncataDovrebbeDareFalso;
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
  const ATable: AnsiString; ABase: Integer): TBytes;
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
    Result[ABase + AOffset] := Byte(AValue shr 8);
    Result[ABase + AOffset + 1] := Byte(AValue and $FF);
  end;

begin
  LStrings := nil;
  SetLength(Result, ABase + TABLE_OFFSET + 6 + Length(ANames) * 12);
  FillChar(Result[0], Length(Result), 0);
  // the offset table: version 1.0 and one table
  PutWord(0, 1);
  PutWord(4, 1);
  Move(ATable[1], Result[ABase + 12], 4);
  PutWord(22, ABase + TABLE_OFFSET);
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

class function TTestXcomSurfaceTtfFamilyName.Collection(const AFirst, ASecond: array of TName): TBytes;
const
  HEADER = 20;
var
  LFirst: TBytes;

  procedure PutLong(AOffset: Integer; AValue: Integer);
  begin
    Result[AOffset] := Byte(AValue shr 24);
    Result[AOffset + 1] := Byte(AValue shr 16);
    Result[AOffset + 2] := Byte(AValue shr 8);
    Result[AOffset + 3] := Byte(AValue and $FF);
  end;

begin
  // the offset tables follow the header; the tables of each font are addressed from the start of the file
  LFirst := FontFile(AFirst, 'name', HEADER);
  Result := FontFile(ASecond, 'name', Length(LFirst));
  Move(LFirst[HEADER], Result[HEADER], Length(LFirst) - HEADER);
  Result[0] := Ord('t');
  Result[1] := Ord('t');
  Result[2] := Ord('c');
  Result[3] := Ord('f');
  PutLong(4, $10000);
  PutLong(8, 2);
  PutLong(12, HEADER);
  PutLong(16, Length(LFirst));
end;

procedure TTestXcomSurfaceTtfFamilyName.UnaRaccoltaDovrebbeDareLaFamigliaDelFontCheSiChiede;
var
  LName: string;
  LFile: TBytes;
begin
  LFile := Collection([Name(3, $409, 1, 'Primo')], [Name(3, $409, 1, 'Secondo')]);
  Assert.IsTrue(TXcomTtfFamilyName.TryRead(LFile, 0, LName));
  Assert.AreEqual('Primo', LName);
  Assert.IsTrue(TXcomTtfFamilyName.TryRead(LFile, 1, LName));
  Assert.AreEqual('Secondo', LName);
end;

procedure TTestXcomSurfaceTtfFamilyName.SenzaIndiceUnaRaccoltaDovrebbeDareLaPrimaFamiglia;
var
  LName: string;
begin
  Assert.IsTrue(TXcomTtfFamilyName.TryRead(Collection([Name(3, $409, 1, 'Primo')], [Name(3, $409, 1, 'Secondo')]),
    LName));
  Assert.AreEqual('Primo', LName);
end;

procedure TTestXcomSurfaceTtfFamilyName.UnIndiceCheLaRaccoltaNonHaDovrebbeDareFalso;
var
  LName: string;
  LFile: TBytes;
begin
  LFile := Collection([Name(3, $409, 1, 'Primo')], [Name(3, $409, 1, 'Secondo')]);
  Assert.IsFalse(TXcomTtfFamilyName.TryRead(LFile, 2, LName));
  Assert.IsFalse(TXcomTtfFamilyName.TryRead(LFile, -1, LName));
  Assert.AreEqual('', LName);
end;

procedure TTestXcomSurfaceTtfFamilyName.UnFontSingoloDovrebbeAvereSoloLIndiceZero;
var
  LName: string;
  LFile: TBytes;
begin
  LFile := FontFile([Name(3, $409, 1, 'My Font')]);
  Assert.IsTrue(TXcomTtfFamilyName.TryRead(LFile, 0, LName));
  Assert.IsFalse(TXcomTtfFamilyName.TryRead(LFile, 1, LName));
end;

procedure TTestXcomSurfaceTtfFamilyName.DovrebbeContareIFontDelFile;
var
  LCollection: TBytes;
begin
  LCollection := Collection([Name(3, $409, 1, 'Primo')], [Name(3, $409, 1, 'Secondo')]);
  Assert.AreEqual(2, TXcomTtfFamilyName.FaceCount(LCollection));
  Assert.IsTrue(TXcomTtfFamilyName.IsCollection(LCollection));
  Assert.AreEqual(1, TXcomTtfFamilyName.FaceCount(FontFile([Name(3, $409, 1, 'My Font')])));
  Assert.IsFalse(TXcomTtfFamilyName.IsCollection(FontFile([Name(3, $409, 1, 'My Font')])));
  Assert.AreEqual(1, TXcomTtfFamilyName.FaceCount(nil));
end;

procedure TTestXcomSurfaceTtfFamilyName.UnaRaccoltaTroncataDovrebbeDareFalso;
var
  LName: string;
  LFile: TBytes;
begin
  LFile := Collection([Name(3, $409, 1, 'Primo')], [Name(3, $409, 1, 'Secondo')]);
  // the offsets are there but the second font is not
  SetLength(LFile, 40);
  Assert.IsFalse(TXcomTtfFamilyName.TryRead(LFile, 1, LName));
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
