{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the reject builder of the glbsp port                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Reject.Builder;

interface

uses
  System.Classes,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Glbsp.Level.Data,
  DelphiDoom.Glbsp.Level.Types,
  DelphiDoom.Glbsp.Reject.Builder,
  DelphiDoom.Glbsp.Wad.Document,
  DelphiDoom.Glbsp.Wad.Lump,
  DelphiDoom.Glbsp.Wad.Types;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspRejectBuilder = class(TObject)
  private
    FData: TGlbspLevelData;
    FWad: TGlbspWad;
    FInput: TBytesStream;
    procedure CreateWad;
    procedure AddSectors(const ACount: Integer);
    procedure Connect(const ASectorA, ASectorB: Integer; const ATwoSidedFlag: Boolean);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestUnSettoreIsolatoDaGliAltri;
    [Test]
    procedure TestTuttiConnessiNessunBitAcceso;
    [Test]
    procedure TestLineaSenzaFlagDueLatiNonUnisce;
    [Test]
    procedure TestGruppiUnitiPerCatena;
    [Test]
    procedure TestScriveIlLumpReject;
  end;

implementation

{ TTestGlbspRejectBuilder }

procedure TTestGlbspRejectBuilder.Setup;
begin
  FData := TGlbspLevelData.Create;
  FWad := TGlbspWad.Create;
  CreateWad;
end;

procedure TTestGlbspRejectBuilder.TearDown;
begin
  FWad.Free;
  FInput.Free;
  FData.Free;
end;

procedure TTestGlbspRejectBuilder.CreateWad;
const
  NAMES: array[0..4] of AnsiString = ('MAP01', 'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES');
var
  LHeader: TRawWadHeader;
  LEntry: TRawWadEntry;
  LIndex, LCharIndex: Integer;
begin
  FInput := TBytesStream.Create;
  LHeader.MagicType := 'PWAD';
  LHeader.NumEntries := Length(NAMES);
  LHeader.DirStart := WAD_HEADER_SIZE;
  FInput.WriteBuffer(LHeader, SizeOf(LHeader));
  for LIndex := 0 to High(NAMES) do
  begin
    FillChar(LEntry, SizeOf(LEntry), 0);
    LEntry.Start := WAD_HEADER_SIZE;
    for LCharIndex := 1 to Length(NAMES[LIndex]) do
      LEntry.Name[LCharIndex - 1] := NAMES[LIndex][LCharIndex];
    FInput.WriteBuffer(LEntry, SizeOf(LEntry));
  end;
  FInput.Position := 0;
  FWad.ReadFromStream(FInput, True, False);
  FWad.FindNextLevel;
end;

procedure TTestGlbspRejectBuilder.AddSectors(const ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACount do
    FData.NewSector.Index := FData.Sectors.Count - 1;
end;

procedure TTestGlbspRejectBuilder.Connect(const ASectorA, ASectorB: Integer;
  const ATwoSidedFlag: Boolean);
var
  LLine: TGlbspLinedef;
begin
  LLine := FData.NewLinedef;
  LLine.Right := FData.NewSidedef;
  LLine.Right.Sector := FData.Sectors[ASectorA];
  LLine.Left := FData.NewSidedef;
  LLine.Left.Sector := FData.Sectors[ASectorB];
  LLine.TwoSided := ATwoSidedFlag;
end;

procedure TTestGlbspRejectBuilder.TestUnSettoreIsolatoDaGliAltri;
var
  LBuilder: TGlbspRejectBuilder;
  LMatrix: TBytes;
begin
  // Sectors 0 and 1 are connected, sector 2 is an island
  AddSectors(3);
  Connect(0, 1, True);
  LBuilder := TGlbspRejectBuilder.Create(FData, FWad);
  try
    LMatrix := LBuilder.BuildMatrix;
  finally
    LBuilder.Free;
  end;

  // 9 bits: the pairs (2,0) and (2,1), set in both directions: bits 6, 2, 7, 5
  Assert.AreEqual(2, Length(LMatrix));
  Assert.AreEqual(Integer($E4), Integer(LMatrix[0]));
  Assert.AreEqual(0, Integer(LMatrix[1]));
end;

procedure TTestGlbspRejectBuilder.TestTuttiConnessiNessunBitAcceso;
var
  LBuilder: TGlbspRejectBuilder;
  LMatrix: TBytes;
  LByte: Byte;
begin
  AddSectors(3);
  Connect(0, 1, True);
  Connect(1, 2, True);
  LBuilder := TGlbspRejectBuilder.Create(FData, FWad);
  try
    LMatrix := LBuilder.BuildMatrix;
  finally
    LBuilder.Free;
  end;

  for LByte in LMatrix do
    Assert.AreEqual(0, Integer(LByte));
end;

procedure TTestGlbspRejectBuilder.TestLineaSenzaFlagDueLatiNonUnisce;
var
  LBuilder: TGlbspRejectBuilder;
  LMatrix: TBytes;
begin
  AddSectors(2);
  // Without the two sided flag the engine does not allow sight through it
  Connect(0, 1, False);
  LBuilder := TGlbspRejectBuilder.Create(FData, FWad);
  try
    LMatrix := LBuilder.BuildMatrix;
  finally
    LBuilder.Free;
  end;

  // 4 bits: the pair (1,0) in both directions: bits 2 and 1
  Assert.AreEqual(1, Length(LMatrix));
  Assert.AreEqual(6, Integer(LMatrix[0]));
end;

procedure TTestGlbspRejectBuilder.TestGruppiUnitiPerCatena;
var
  LBuilder: TGlbspRejectBuilder;
begin
  AddSectors(5);
  Connect(3, 4, True);
  Connect(1, 2, True);
  // Joins the two groups: 1-2 and 3-4 become one, through 2-3
  Connect(2, 3, True);
  LBuilder := TGlbspRejectBuilder.Create(FData, FWad);
  try
    LBuilder.BuildMatrix;
  finally
    LBuilder.Free;
  end;

  Assert.AreEqual(FData.Sectors[1].RejGroup, FData.Sectors[2].RejGroup);
  Assert.AreEqual(FData.Sectors[1].RejGroup, FData.Sectors[3].RejGroup);
  Assert.AreEqual(FData.Sectors[1].RejGroup, FData.Sectors[4].RejGroup);
  Assert.AreNotEqual(FData.Sectors[0].RejGroup, FData.Sectors[1].RejGroup);
end;

procedure TTestGlbspRejectBuilder.TestScriveIlLumpReject;
var
  LBuilder: TGlbspRejectBuilder;
  LLump: TGlbspLump;
begin
  AddSectors(3);
  Connect(0, 1, True);
  LBuilder := TGlbspRejectBuilder.Create(FData, FWad);
  try
    LBuilder.PutReject;
  finally
    LBuilder.Free;
  end;

  LLump := FWad.FindLevelLump('REJECT');
  Assert.IsNotNull(LLump);
  Assert.AreEqual(2, LLump.Length);
  Assert.AreEqual(Integer($E4), Integer(LLump.Data[0]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspRejectBuilder);

end.
