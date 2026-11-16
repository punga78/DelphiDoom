{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the header of a saved game                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$Q-}
{$R-}
unit DelphiDoom.Tests.Serializer.SaveGameHeader;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Serializer.SaveGameHeader;

type
  [TestFixture]
  [Category('serializer')]
  TTestSerializerSaveGameHeader = class
  strict private
    // the text of the old G_DoSaveGameInFile, copied as it was
    procedure OldWriteDescription(const ADestination: PByte; const ASize: Integer;
      const ADescription: string; const APadWithSpaces: Boolean);
    function OldVersionField(const AVersion: Integer; const ASize: Integer): AnsiString;
  public
    [Test]
    procedure DovrebbeScrivereLaDescrizioneComeIlVecchioCodiceConIlPaddingDiZeri;
    [Test]
    procedure DovrebbeScrivereLaDescrizioneComeIlVecchioCodiceConIlPaddingDiSpazi;
    [Test]
    procedure DovrebbeTagliareLaDescrizioneLunga;
    [Test]
    procedure DovrebbeScrivereLaVersioneComeIlVecchioCodice;
    [Test]
    procedure DovrebbeFareIlGiroDelTempoDelLivello;
    [Test]
    procedure DovrebbeScrivereITreByteDelTempoPiuSignificativoPrima;
  end;

implementation

{ TTestSerializerSaveGameHeader }

procedure TTestSerializerSaveGameHeader.OldWriteDescription(const ADestination: PByte;
  const ASize: Integer; const ADescription: string; const APadWithSpaces: Boolean);
var
  LDescription: string;
  LText: AnsiString;
begin
  LDescription := ADescription;
  if APadWithSpaces then
    while Length(LDescription) < ASize do
      LDescription := LDescription + ' ';
  FillChar(ADestination^, ASize, 0);
  LText := AnsiString(LDescription);
  if Length(LText) > ASize then
    SetLength(LText, ASize);
  if Length(LText) > 0 then
    Move(LText[1], ADestination^, Length(LText));
end;

function TTestSerializerSaveGameHeader.OldVersionField(const AVersion: Integer;
  const ASize: Integer): AnsiString;
var
  LName: string;
begin
  LName := 'version ' + IntToStr(AVersion);
  while Length(LName) < ASize do
    LName := LName + ' ';
  Result := AnsiString(LName);
end;

procedure TTestSerializerSaveGameHeader.DovrebbeScrivereLaDescrizioneComeIlVecchioCodiceConIlPaddingDiZeri;
const
  TEXTS: array[0..4] of string = ('', 'a', 'Level one', 'exactly 24 characters ok', 'caffè e latte');
var
  LIndex: Integer;
  LOld: array[0..23] of Byte;
  LNew: array[0..23] of Byte;
begin
  for LIndex := 0 to High(TEXTS) do
  begin
    FillChar(LNew, SizeOf(LNew), $55);
    OldWriteDescription(@LOld[0], 24, TEXTS[LIndex], False);
    TSaveGameHeader.WriteDescription(@LNew[0], 24, TEXTS[LIndex], 0);
    Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], 24), TEXTS[LIndex]);
  end;
end;

procedure TTestSerializerSaveGameHeader.DovrebbeScrivereLaDescrizioneComeIlVecchioCodiceConIlPaddingDiSpazi;
const
  TEXTS: array[0..3] of string = ('', 'Strife slot', 'exactly 24 characters ok', 'a text that is longer than the field');
var
  LIndex: Integer;
  LOld: array[0..23] of Byte;
  LNew: array[0..23] of Byte;
begin
  for LIndex := 0 to High(TEXTS) do
  begin
    FillChar(LNew, SizeOf(LNew), $55);
    // Strife pads the text with spaces before cutting it
    OldWriteDescription(@LOld[0], 24, TEXTS[LIndex], True);
    TSaveGameHeader.WriteDescription(@LNew[0], 24, TEXTS[LIndex], Ord(' '));
    Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], 24), TEXTS[LIndex]);
  end;
end;

procedure TTestSerializerSaveGameHeader.DovrebbeTagliareLaDescrizioneLunga;
var
  LBuffer: array[0..29] of Byte;
begin
  FillChar(LBuffer, SizeOf(LBuffer), $55);
  TSaveGameHeader.WriteDescription(@LBuffer[0], 24, StringOfChar('x', 40), 0);
  Assert.AreEqual<Integer>(Ord('x'), LBuffer[23]);
  // nothing is written after the field
  Assert.AreEqual<Integer>($55, LBuffer[24]);
end;

procedure TTestSerializerSaveGameHeader.DovrebbeScrivereLaVersioneComeIlVecchioCodice;
var
  LVersion: Integer;
  LSize: Integer;
  LField: array[0..15] of Byte;
  LOld: AnsiString;
begin
  for LVersion in [113, 206, 1, 99999] do
    for LSize in [11, 16] do
    begin
      TSaveGameHeader.WriteVersion(@LField[0], LVersion, LSize);
      LOld := OldVersionField(LVersion, LSize);
      Assert.IsTrue(CompareMem(@LField[0], @LOld[1], LSize));
      Assert.AreEqual(LOld, TSaveGameHeader.VersionText(LVersion, LSize));
    end;
end;

procedure TTestSerializerSaveGameHeader.DovrebbeFareIlGiroDelTempoDelLivello;
var
  LTime: Integer;
  LBytes: array[0..2] of Byte;
begin
  for LTime in [0, 1, 255, 256, 70000, 1234567, $FFFFFF] do
  begin
    TSaveGameHeader.WriteLevelTime(@LBytes[0], LTime);
    Assert.AreEqual(LTime, TSaveGameHeader.ReadLevelTime(@LBytes[0]));
  end;
end;

procedure TTestSerializerSaveGameHeader.DovrebbeScrivereITreByteDelTempoPiuSignificativoPrima;
var
  LBytes: array[0..2] of Byte;
begin
  TSaveGameHeader.WriteLevelTime(@LBytes[0], $010203);
  Assert.AreEqual<Integer>(1, LBytes[0]);
  Assert.AreEqual<Integer>(2, LBytes[1]);
  Assert.AreEqual<Integer>(3, LBytes[2]);
  // more than 24 bits wrap, as the old code did
  TSaveGameHeader.WriteLevelTime(@LBytes[0], $1010203);
  Assert.AreEqual($010203, TSaveGameHeader.ReadLevelTime(@LBytes[0]));
end;

end.
