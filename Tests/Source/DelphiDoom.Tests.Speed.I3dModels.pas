{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the speed library - the I3D models of SPEEDH.JCL        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.I3dModels;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   Every I3D model of SPEEDH.JCL (the shareware of Speed Haste, 50 models) read through the container and
  ///   the reader of Libs\Models gives the lines that the old TI3DModelLoader gave (golden file i3d.shareware.golden.txt:
  ///   header, fingerprints of faces and textures, tires and three drawings, before and after some corrections).
  ///   The test is skipped if SPEEDH.JCL is not there.
  /// </summary>
  [TestFixture]
  [Category('speed')]
  TTestSpeedI3dModels = class(TObject)
  strict private
    function FindShareware: string;
    function ReadGolden: TArray<string>;
  public
    [Test]
    procedure DovrebbeDareLeStesseRigheDelVecchioCodiceSuiModelliDelloShareware;
    [Test]
    procedure DovrebbeTrovareNelContenitoreTuttiIModelliDelGolden;
  end;

implementation

uses
  System.Classes, System.IOUtils, DelphiDoom.Speed.Intf, DelphiDoom.Speed.Factory,
  DelphiDoom.Models.I3d.Intf, DelphiDoom.Models.I3d.Factory, DelphiDoom.Tests.Models.I3dDump;

const
  /// <summary>The lines written for every model: 8 of the model and 8 of the model with the corrections</summary>
  LINES_PER_MODEL = 16;

{ TTestSpeedI3dModels }

function TTestSpeedI3dModels.FindShareware: string;
var
  LRoot: string;
  LCandidates: TArray<string>;
  LCandidate: string;
begin
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..'));
  LCandidates := [TPath.Combine(LRoot, 'bin\Speed\SPEEDH.JCL'), TPath.Combine(LRoot, 'Reference\_dati\speed\SPEEDH.JCL'),
    // the worktrees of the repository are under .claude\worktrees\<name>
    TPath.GetFullPath(TPath.Combine(LRoot, '..\..\..\Reference\_dati\speed\SPEEDH.JCL'))];
  for LCandidate in LCandidates do
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  Result := '';
end;

function TTestSpeedI3dModels.ReadGolden: TArray<string>;
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
      '..\..\Tests\Data\Speed\i3d.shareware.golden.txt')));
    Result := LLines.ToStringArray;
  finally
    LLines.Free;
  end;
end;

procedure TTestSpeedI3dModels.DovrebbeDareLeStesseRigheDelVecchioCodiceSuiModelliDelloShareware;
var
  LPath: string;
  LContainer: ISpeedContainer;
  LParser: II3dParser;
  LGolden, LActual: TArray<string>;
  LBytes: TBytes;
  LModel: II3dModel;
  LPosition, LIndex, LModels: Integer;
  LName: string;
begin
  LPath := FindShareware;
  if LPath = '' then
    Assert.Pass('SPEEDH.JCL is not there');
  LContainer := TSpeedFactory.OpenContainer(LPath);
  LParser := TI3dFactory.CreateParser;
  LGolden := ReadGolden;
  LPosition := 0;
  LModels := 0;
  while LPosition < Length(LGolden) do
  begin
    LName := Copy(LGolden[LPosition], Length('model ') + 1, MaxInt);
    LName := Copy(LName, 1, Pos(' bytes ', LName) - 1);
    Assert.IsTrue(LContainer.TryRead(LName, LBytes), 'the model is in the container: ' + LName);
    LModel := LParser.Parse(LBytes);
    LActual := TI3dDump.Lines(LName, Length(LBytes), LModel);
    LModel.ApplyCorrections(TI3dDump.SampleCorrections(LModel.FaceCount));
    LActual := LActual + TI3dDump.Lines('corrected ' + LName, Length(LBytes), LModel);
    Assert.AreEqual<Integer>(LINES_PER_MODEL, Length(LActual));
    for LIndex := 0 to High(LActual) do
      Assert.AreEqual(LGolden[LPosition + LIndex], LActual[LIndex], LName + ' line ' + IntToStr(LIndex));
    Inc(LPosition, LINES_PER_MODEL);
    Inc(LModels);
  end;
  Assert.AreEqual(50, LModels, 'models in the golden file');
end;

procedure TTestSpeedI3dModels.DovrebbeTrovareNelContenitoreTuttiIModelliDelGolden;
var
  LPath: string;
  LContainer: ISpeedContainer;
  LIndex, LCount: Integer;
begin
  LPath := FindShareware;
  if LPath = '' then
    Assert.Pass('SPEEDH.JCL is not there');
  LContainer := TSpeedFactory.OpenContainer(LPath);
  LCount := 0;
  for LIndex := 0 to LContainer.Count - 1 do
    if SameText(ExtractFileExt(LContainer.Entries[LIndex].Name), '.I3D') then
      Inc(LCount);
  Assert.AreEqual(50, LCount);
end;

end.
