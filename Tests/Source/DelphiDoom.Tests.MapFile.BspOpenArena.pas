{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the map file library - the BSP files of OpenArena      }
{  0.8.8 (GPL v2), read where they are; ignored if they are not there          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapFile.BspOpenArena;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.MapFile.Bsp.Intf;

type
  /// <summary>
  ///   Every .bsp of pak1-maps.pk3, pak6-patch085.pk3 and pak6-patch088.pk3 (DELPHIDOOM_OPENARENA = the
  ///   baseoa folder or a pk3 in it, or Reference\openarena\openarena-0.8.8\baseoa). Nothing of
  ///   OpenArena is copied into the repository
  /// </summary>
  [TestFixture]
  [Category('MapFile')]
  [Category('OpenArena')]
  TTestBspOpenArena = class
  strict private
    function BaseFolder: string;
    procedure Visit(const AVisit: TProc<string, TBytes>);
  public
    [Test]
    procedure DovrebbeRiscrivereOgniMappaERileggerlaUguale;
    [Test]
    procedure DovrebbeCaricareLAlberoELaGrigliaDiLuceDiOgniMappa;
  end;

implementation

uses
  System.Classes, System.IOUtils, System.Zip, DUnitX.Exceptions, DelphiDoom.Geometry.Vec3, DelphiDoom.Geometry.Bounds,
  DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MapFile.Bsp.RenderTypes, DelphiDoom.MapFile.Bsp.Factory,
  DelphiDoom.MapFile.Bsp.GridSizeReader;

const
  PAKS: array[0..2] of string = ('pak1-maps.pk3', 'pak6-patch085.pk3', 'pak6-patch088.pk3');

function TTestBspOpenArena.BaseFolder: string;
var
  LRelative: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (Result <> '') and TFile.Exists(Result) then
    Result := TPath.GetDirectoryName(Result);
  if (Result <> '') and TDirectory.Exists(Result) then
    Exit;
  LRelative := '..\..\..\..\Reference\openarena\openarena-0.8.8\baseoa';
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), LRelative));
  if not TDirectory.Exists(Result) then
    raise ETestIgnored.Create('OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena): prova ignorata');
end;

procedure TTestBspOpenArena.Visit(const AVisit: TProc<string, TBytes>);
var
  LFolder, LPak, LName: string;
  LZip: TZipFile;
  LBytes: TBytes;
  LCount: Integer;
begin
  LFolder := BaseFolder;
  LCount := 0;
  for LPak in PAKS do
  begin
    if not TFile.Exists(TPath.Combine(LFolder, LPak)) then
      Continue;
    LZip := TZipFile.Create;
    try
      LZip.Open(TPath.Combine(LFolder, LPak), zmRead);
      for LName in LZip.FileNames do
        if LName.EndsWith('.bsp', True) then
        begin
          LZip.Read(LName, LBytes);
          AVisit(LName, LBytes);
          Inc(LCount);
        end;
    finally
      LZip.Free;
    end;
  end;
  if LCount = 0 then
    raise ETestIgnored.Create('nessuna mappa nei pk3 di OpenArena: prova ignorata');
end;

procedure TTestBspOpenArena.DovrebbeRiscrivereOgniMappaERileggerlaUguale;
begin
  Visit(
    procedure(AName: string; ABytes: TBytes)
    var
      LFirst, LSecond: IBspFile;
      LWritten, LAgain: TBytes;
      LIndex: Integer;
    begin
      LFirst := TBspFactory.CreateReader.ParseBytes(ABytes, AName);
      LWritten := TBspFactory.CreateWriter.ToBytes(LFirst);
      LSecond := TBspFactory.CreateReader.ParseBytes(LWritten, AName);
      Assert.AreEqual(string(LFirst.EntityText), string(LSecond.EntityText), AName + ': entities');
      for LIndex := 0 to HEADER_LUMPS - 1 do
        if LIndex <> LUMP_ENTITIES then
          Assert.IsTrue((Length(LFirst.LumpData[LIndex]) = Length(LSecond.LumpData[LIndex])) and
            ((Length(LFirst.LumpData[LIndex]) = 0) or CompareMem(@LFirst.LumpData[LIndex][0],
            @LSecond.LumpData[LIndex][0], Length(LFirst.LumpData[LIndex]))), AName + ': lump ' + IntToStr(LIndex));
      // writing what was written does not change a byte
      LAgain := TBspFactory.CreateWriter.ToBytes(LSecond);
      Assert.IsTrue((Length(LWritten) = Length(LAgain)) and CompareMem(@LWritten[0], @LAgain[0], Length(LWritten)),
        AName + ': second write');
    end);
end;

procedure TTestBspOpenArena.DovrebbeCaricareLAlberoELaGrigliaDiLuceDiOgniMappa;
var
  LWithGrid, LMaps: Integer;
begin
  LWithGrid := 0;
  LMaps := 0;
  Visit(
    procedure(AName: string; ABytes: TBytes)
    var
      LFile: IBspFile;
      LTree: TBspRenderTree;
      LGrid: TBspLightGrid;
      LIndex: Integer;
      LModel: TBspModel;
    begin
      LFile := TBspFactory.CreateReader.ParseBytes(ABytes, AName);
      LTree := TBspFactory.CreateTreeLoader.Load(LFile.Nodes, LFile.Leafs, Length(LFile.Planes));
      Assert.AreEqual<Integer>(Length(LFile.Nodes) + Length(LFile.Leafs), Length(LTree.Nodes), AName + ': nodes');
      Assert.AreEqual<Integer>(-1, LTree.Nodes[0].Parent);
      for LIndex := 1 to High(LTree.Nodes) do
        Assert.IsTrue(LTree.Nodes[LIndex].Parent >= 0, AName + ': parent of ' + IntToStr(LIndex));
      LModel := LFile.Models[0];
      LGrid := TBspFactory.CreateLightGridLoader.Load(
        TGeoBounds.Make(TGeoVec3.Make(LModel.Mins[0], LModel.Mins[1], LModel.Mins[2]),
          TGeoVec3.Make(LModel.Maxs[0], LModel.Maxs[1], LModel.Maxs[2])),
        TBspGridSizeReader.Read(LFile.EntityText), LFile.LightGrid, 1);
      Inc(LMaps);
      if Length(LGrid.Data) > 0 then
        Inc(LWithGrid);
      if Length(LGrid.Data) > 0 then
        Assert.AreEqual<Integer>(Length(LFile.LightGrid), Length(LGrid.Data), AName);
    end);
  // most maps are made with a grid that fits
  Assert.IsTrue(LWithGrid * 2 > LMaps, Format('%d maps of %d have a light grid that fits', [LWithGrid, LMaps]));
end;

end.
