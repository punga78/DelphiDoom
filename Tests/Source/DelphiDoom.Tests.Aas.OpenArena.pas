{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the AAS library - the 99 .aas files of OpenArena       }
{  0.8.8 (GPL v2), read where they are; ignored if they are not there          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.OpenArena;

{$Q-}
{$R-}

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   Reads every .aas of pak6-misc.pk3, pak6-patch085.pk3 and pak6-patch088.pk3 (DELPHIDOOM_OPENARENA = the
  ///   baseoa folder or a pk3 in it, or Reference\openarena\openarena-0.8.8\baseoa). The checksum of the BSP is
  ///   the one the file carries (the BSP is not needed). Nothing of OpenArena is copied into the repository.
  /// </summary>
  [TestFixture]
  [Category('Aas')]
  [Category('OpenArena')]
  TTestAasOpenArena = class
  strict private
    function BaseFolder: string;
  public
    [Test]
    procedure DovrebbeLeggereTuttiIFileSenzaErroriENessunMessaggio;
    [Test]
    procedure IlCentroDiOgniAreaDovrebbeStareNellArea;
    [Test]
    procedure UnaLineaTraIcentriDiDueAreeDovrebbePartireDallaPrima;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Zip, DUnitX.Exceptions, DelphiDoom.MathCore.Types,
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Factory,
  DelphiDoom.Aas.HeaderCipher, DelphiDoom.Tests.Aas.Support;

const
  PAKS: array[0..2] of string = ('pak6-misc.pk3', 'pak6-patch085.pk3', 'pak6-patch088.pk3');

type
  TVisit = reference to procedure(const AName: string; const AFile: IAasFile; const AImport: TFakeImport);

function TTestAasOpenArena.BaseFolder: string;
var
  LRelative: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (Result <> '') and TFile.Exists(Result) then
    Result := TPath.GetDirectoryName(Result);
  if (Result <> '') and TDirectory.Exists(Result) then
    Exit;
  LRelative := '..\..\Reference\openarena\openarena-0.8.8\baseoa';
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), LRelative));
  if not TDirectory.Exists(Result) then
    raise ETestIgnored.Create('OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena): prova ignorata');
end;

procedure VisitAll(const AFolder: string; const AVisit: TVisit);
var
  LPak, LName: string;
  LZip: TZipFile;
  LBytes: TBytes;
  LHeader: TAasFileHeader;
  LImport: TFakeImport;
  LKeeper: IBotImport;
  LFile: IAasFile;
begin
  for LPak in PAKS do
  begin
    if not TFile.Exists(TPath.Combine(AFolder, LPak)) then
      Continue;
    LZip := TZipFile.Create;
    try
      LZip.Open(TPath.Combine(AFolder, LPak), zmRead);
      for LName in LZip.FileNames do
      begin
        if not LName.EndsWith('.aas') then
          Continue;
        LZip.Read(LName, LBytes);
        Move(LBytes[0], LHeader, SizeOf(LHeader));
        if LHeader.Version = AAS_VERSION then
          TAasHeaderCipher.Apply(LHeader);
        LImport := TFakeImport.Create;
        LKeeper := LImport;
        LFile := TAasFactory.CreateReader(LKeeper, nil, nil).ParseBytes(LBytes, AnsiString(LName), LHeader.BspChecksum);
        AVisit(LPak + '/' + LName, LFile, LImport);
      end;
    finally
      LZip.Free;
    end;
  end;
end;

procedure TTestAasOpenArena.DovrebbeLeggereTuttiIFileSenzaErroriENessunMessaggio;
var
  LCount: Integer;
begin
  LCount := 0;
  VisitAll(BaseFolder,
    procedure(const AName: string; const AFile: IAasFile; const AImport: TFakeImport)
    begin
      Inc(LCount);
      Assert.AreEqual<Integer>(AAS_VERSION, AFile.Version, AName);
      Assert.IsTrue(Length(AFile.Areas) > 1, AName);
      Assert.AreEqual<Integer>(Length(AFile.Areas), Length(AFile.AreaSettings), AName);
      Assert.IsTrue(Length(AFile.Nodes) > 1, AName);
      Assert.AreEqual<Integer>(0, AImport.Count, AName);
    end);
  Assert.IsTrue(LCount > 0);
  // the three paks of 0.8.8 have 49 + 12 + 38 files
  if LCount < 99 then
    Assert.Pass('only ' + IntToStr(LCount) + ' files found');
end;

procedure TTestAasOpenArena.IlCentroDiOgniAreaDovrebbeStareNellArea;
var
  LTotal, LInside: Integer;
begin
  LTotal := 0;
  LInside := 0;
  VisitAll(BaseFolder,
    procedure(const AName: string; const AFile: IAasFile; const AImport: TFakeImport)
    var
      LSampler: IAasSampler;
      LIndex: Integer;
    begin
      LSampler := TAasFactory.CreateSampler(AFile, AImport);
      for LIndex := 1 to High(AFile.Areas) do
      begin
        Inc(LTotal);
        if LSampler.PointAreaNum(AFile.Areas[LIndex].Center) = LIndex then
          Inc(LInside);
      end;
      Assert.AreEqual<Integer>(0, AImport.Count, AName);
    end);
  Assert.IsTrue(LTotal > 0);
  // the centre of a convex area is inside it; a few areas are so thin that it falls on the plane of a face
  Assert.IsTrue(LInside * 100 >= LTotal * 95, Format('%d of %d centres', [LInside, LTotal]));
end;

procedure TTestAasOpenArena.UnaLineaTraIcentriDiDueAreeDovrebbePartireDallaPrima;
var
  LTotal, LGood: Integer;
begin
  LTotal := 0;
  LGood := 0;
  VisitAll(BaseFolder,
    procedure(const AName: string; const AFile: IAasFile; const AImport: TFakeImport)
    var
      LTracer: IAasTracer;
      LSampler: IAasSampler;
      LAreas: TArray<Integer>;
      LPoints: TArray<TVec3>;
      LSeed: Cardinal;
      LFrom, LTo, LIndex: Integer;
    begin
      LTracer := TAasFactory.CreateTracer(AFile, AImport);
      LSampler := TAasFactory.CreateSampler(AFile, AImport);
      LSeed := 2463534242;
      for LIndex := 1 to 20 do
      begin
        LSeed := LSeed xor (LSeed shl 13);
        LSeed := LSeed xor (LSeed shr 17);
        LSeed := LSeed xor (LSeed shl 5);
        LFrom := 1 + Integer(LSeed mod Cardinal(High(AFile.Areas)));
        LSeed := LSeed xor (LSeed shl 13);
        LSeed := LSeed xor (LSeed shr 17);
        LSeed := LSeed xor (LSeed shl 5);
        LTo := 1 + Integer(LSeed mod Cardinal(High(AFile.Areas)));
        if LSampler.PointAreaNum(AFile.Areas[LFrom].Center) <> LFrom then
          Continue;
        Inc(LTotal);
        if (LTracer.TraceAreas(AFile.Areas[LFrom].Center, AFile.Areas[LTo].Center, 64, LAreas, LPoints) > 0) and
           (LAreas[0] = LFrom) then
          Inc(LGood);
      end;
      Assert.AreEqual<Integer>(0, AImport.Count, AName);
    end);
  Assert.IsTrue(LTotal > 0);
  Assert.IsTrue(LGood = LTotal, Format('%d of %d traces start in the first area', [LGood, LTotal]));
end;

end.
