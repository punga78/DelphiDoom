{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Dehacked library - the tables of names of the games}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Dehacked.TokenTables;

// the 32-bit wraparound of the FNV-1a product is wanted
{$Q-}{$R-}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DUnitX.TestFramework, DelphiDoom.Dehacked.Games, DelphiDoom.Dehacked.GameData;

type
  /// <summary>
  ///   Tests\Data\Dehacked\tokens.golden.txt has the fingerprints (FNV-1a over the UTF-8 bytes of each name
  ///   followed by a zero byte) of the lists that the old DEH_Init of each deh_main.pas filled one name at a
  ///   time. Since issue #185 (wave 11b) DEH_Init fills them from TDehackedGames.DataOf: the library data are
  ///   the one source and have to give exactly the old lists, in the same order (the order is the index of a field)
  /// </summary>
  [TestFixture]
  [Category('dehacked')]
  TTestDehackedTokenTables = class(TObject)
  strict private
    function DataPath(const AFileName: string): string;
    function Fingerprint(const AItems: TArray<string>): Cardinal;
    function ListOf(const AData: TDehackedGameData; const AName: string): TArray<string>;
  public
    [Test]
    procedure DovrebbeDareLeStesseListeDelVecchioDehMainNeiQuattroGiochi;

    [Test]
    procedure DovrebbeAvereTuttiIQuattroGiochiNelGolden;

    [Test]
    procedure DovrebbeDareListeDiversePerGiochiDiversi;
  end;

implementation

function TTestDehackedTokenTables.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Dehacked\' + AFileName));
end;

function TTestDehackedTokenTables.Fingerprint(const AItems: TArray<string>): Cardinal;
var
  LItem: string;
  LByte: Byte;
  LBytes: TBytes;
begin
  // FNV-1a over 32 bits: the wraparound of the product is the point
  Result := 2166136261;
  for LItem in AItems do
  begin
    LBytes := TEncoding.UTF8.GetBytes(LItem);
    for LByte in LBytes do
      Result := (Result xor LByte) * 16777619;
    Result := (Result xor 0) * 16777619;
  end;
end;

function TTestDehackedTokenTables.ListOf(const AData: TDehackedGameData; const AName: string): TArray<string>;
begin
  if AName = 'ThingFields' then Result := AData.ThingFields
  else if AName = 'FrameFields' then Result := AData.FrameFields
  else if AName = 'AmmoFields' then Result := AData.AmmoFields
  else if AName = 'WeaponFields' then Result := AData.WeaponFields
  else if AName = 'SoundFields' then Result := AData.SoundFields
  else if AName = 'MiscFields' then Result := AData.MiscFields
  else if AName = 'MobjFlags' then Result := AData.MobjFlags
  else if AName = 'MobjFlags2' then Result := AData.MobjFlags2
  else if AName = 'MobjFlagsEx' then Result := AData.MobjFlagsEx
  else if AName = 'MobjFlags2Ex' then Result := AData.MobjFlags2Ex
  else if AName = 'MobjFlags3Ex' then Result := AData.MobjFlags3Ex
  else if AName = 'MobjFlags4Ex' then Result := AData.MobjFlags4Ex
  else if AName = 'MobjFlags5Ex' then Result := AData.MobjFlags5Ex
  else if AName = 'MobjFlags6Ex' then Result := AData.MobjFlags6Ex
  else if AName = 'MobjFlagsMbf21' then Result := AData.MobjFlagsMbf21
  else if AName = 'StateFlagsEx' then Result := AData.StateFlagsEx
  else if AName = 'StateFlagsMbf21' then Result := AData.StateFlagsMbf21
  else if AName = 'WeaponFlagsMbf21' then Result := AData.WeaponFlagsMbf21
  else
    Assert.Fail('unknown list ' + AName);
end;

procedure TTestDehackedTokenTables.DovrebbeDareLeStesseListeDelVecchioDehMainNeiQuattroGiochi;
var
  LLines: TArray<string>;
  LLine: string;
  LParts: TArray<string>;
  LGame: TDehackedGame;
  LItems: TArray<string>;
  LChecked: Integer;
begin
  LLines := TFile.ReadAllLines(DataPath('tokens.golden.txt'));
  LChecked := 0;
  for LLine in LLines do
  begin
    if (LLine = '') or (LLine[1] = '#') then
      Continue;
    LParts := LLine.Split([' ']);
    Assert.IsTrue(TDehackedGames.TryFromName(LParts[0], LGame), 'game ' + LParts[0]);
    LItems := ListOf(TDehackedGames.DataOf(LGame), LParts[1]);
    Assert.AreEqual<Integer>(StrToInt(LParts[2]), Length(LItems), LParts[0] + ' ' + LParts[1] + ': count');
    Assert.AreEqual(LParts[3], IntToHex(Fingerprint(LItems), 8), LParts[0] + ' ' + LParts[1] + ': fingerprint');
    Inc(LChecked);
  end;
  Assert.AreEqual(72, LChecked);
end;

procedure TTestDehackedTokenTables.DovrebbeAvereTuttiIQuattroGiochiNelGolden;
var
  LText: string;
begin
  LText := TFile.ReadAllText(DataPath('tokens.golden.txt'));
  Assert.IsTrue(LText.Contains('Doom ThingFields 81 '), 'Doom');
  Assert.IsTrue(LText.Contains('Heretic ThingFields 81 '), 'Heretic');
  Assert.IsTrue(LText.Contains('Hexen ThingFields 81 '), 'Hexen');
  Assert.IsTrue(LText.Contains('Strife ThingFields 82 '), 'Strife');
end;

procedure TTestDehackedTokenTables.DovrebbeDareListeDiversePerGiochiDiversi;
begin
  // the games differ in the lists: Strife has one more field of the things, Hexen has no ammunition
  Assert.AreEqual<Integer>(81, Length(TDehackedGames.DataOf(dgDoom).ThingFields));
  Assert.AreEqual<Integer>(82, Length(TDehackedGames.DataOf(dgStrife).ThingFields));
  Assert.AreEqual<Integer>(0, Length(TDehackedGames.DataOf(dgHexen).AmmoFields));
  Assert.AreEqual<Integer>(21, Length(TDehackedGames.DataOf(dgHeretic).MobjFlags2));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDehackedTokenTables);

end.
