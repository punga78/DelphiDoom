{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixEditions                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.Editions;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Editions;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixEditions = class(TObject)
  public
    [Test]
    [TestCase('1.0 shareware', '745CF789,0')]
    [TestCase('1.0 registered', 'F7D737A5,1')]
    [TestCase('1.1 shareware', '681B6BE8,2')]
    [TestCase('1.1 registered', '4947EB68,3')]
    [TestCase('2.0 shareware', '593759BE,4')]
    [TestCase('2.0 registered', '67F5000C,5')]
    procedure DovrebbeRiconoscereLEdizioneDalCrc(const ACrcHex: string; AExpected: Integer);
    [Test]
    procedure DovrebbeDareSconosciutaPerUnCrcCheNonCe;
    [Test]
    procedure DovrebbeDireRegistrataSoloPerLeTreEdizioniComplete;
    [Test]
    procedure DovrebbeDareIlTitoloDelVecchioCodice;
    [Test]
    procedure DovrebbeRidareIlCrcDiOgniEdizione;
  strict private
    function FindVersion2Shareware: string;
  public
    [Test]
    procedure DovrebbeRiconoscereIlFileVeroDellaVersione2Shareware;
  end;

implementation

uses
  System.Classes, System.IOUtils,
  DelphiDoom.MathCore.Crc32, DelphiDoom.Tests.Shared.Skip;

{ TTestRadixEditions }

function TTestRadixEditions.FindVersion2Shareware: string;
const
  DATA_FILE = 'Reference\_dati\radix\v20\game\RADIX.DAT';
var
  LRoot: string;
  LCandidate: string;
begin
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..'));
  // the worktrees of the repository are under .claude\worktrees\<name>
  for LCandidate in TArray<string>.Create(TPath.Combine(LRoot, DATA_FILE),
    TPath.GetFullPath(TPath.Combine(LRoot, '..\..\..\' + DATA_FILE))) do
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  Result := '';
end;

procedure TTestRadixEditions.DovrebbeRiconoscereLEdizioneDalCrc(const ACrcHex: string; AExpected: Integer);
begin
  Assert.AreEqual(AExpected, Integer(Ord(TRadixEditions.FromCrc32(Cardinal(StrToInt64('$' + ACrcHex))))));
end;

procedure TTestRadixEditions.DovrebbeDareSconosciutaPerUnCrcCheNonCe;
begin
  Assert.AreEqual(Ord(reUnknown), Ord(TRadixEditions.FromCrc32(0)));
  Assert.AreEqual(Ord(reUnknown), Ord(TRadixEditions.FromCrc32($593759BF)));
  Assert.IsFalse(TRadixEditions.IsKnown(reUnknown));
  Assert.IsTrue(TRadixEditions.IsKnown(reV10Shareware));
end;

procedure TTestRadixEditions.DovrebbeDireRegistrataSoloPerLeTreEdizioniComplete;
begin
  Assert.IsFalse(TRadixEditions.IsRegistered(reV10Shareware));
  Assert.IsTrue(TRadixEditions.IsRegistered(reV10Registered));
  Assert.IsFalse(TRadixEditions.IsRegistered(reV11Shareware));
  Assert.IsTrue(TRadixEditions.IsRegistered(reV11Registered));
  Assert.IsFalse(TRadixEditions.IsRegistered(reV20Shareware));
  Assert.IsTrue(TRadixEditions.IsRegistered(reV20Registered));
  Assert.IsFalse(TRadixEditions.IsRegistered(reUnknown));
end;

procedure TTestRadixEditions.DovrebbeDareIlTitoloDelVecchioCodice;
begin
  Assert.AreEqual('Radix v1.0 Shareware', TRadixEditions.Title(reV10Shareware));
  Assert.AreEqual('Radix v2.0 Remix Shareware', TRadixEditions.Title(reV20Shareware));
  Assert.AreEqual('Radix v2.0 Remix Registered', TRadixEditions.Title(reV20Registered));
  Assert.AreEqual('Game mode indeterminate', TRadixEditions.Title(reUnknown));
end;

procedure TTestRadixEditions.DovrebbeRidareIlCrcDiOgniEdizione;
var
  LEdition: TRadixEdition;
begin
  for LEdition := reV10Shareware to reV20Registered do
    Assert.AreEqual(Ord(LEdition), Ord(TRadixEditions.FromCrc32(TRadixEditions.Crc32Of(LEdition))));
  Assert.AreEqual(Cardinal(0), TRadixEditions.Crc32Of(reUnknown));
end;

procedure TTestRadixEditions.DovrebbeRiconoscereIlFileVeroDellaVersione2Shareware;
var
  LPath: string;
  LStream: TFileStream;
  LCrc: Cardinal;
begin
  LPath := FindVersion2Shareware;
  if LPath = '' then
  begin
    TTestSkip.Ignore('RADIX.DAT (2.0 shareware) non c''e'': i dati del gioco non stanno nel repository');
    Exit;
  end;
  LStream := TFileStream.Create(LPath, fmOpenRead or fmShareDenyNone);
  try
    LCrc := TCrc32.CalculateStream(LStream);
  finally
    LStream.Free;
  end;
  Assert.AreEqual(Ord(reV20Shareware), Ord(TRadixEditions.FromCrc32(LCrc)));
end;

end.
