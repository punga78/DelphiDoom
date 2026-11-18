{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R0) - the model  }
{  table over an md3 built by the test (two frames, one tag, one surface)      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.Model;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Render')]
  TTestQ3ModelRegistry = class
  public
    [Test]
    procedure DovrebbeLeggereUnMd3ELeSueShader;
    [Test]
    procedure DovrebbeLeggereIlivelliDiDettaglioPerLeLoroShader;
    [Test]
    procedure DovrebbeDareLeBoundsDelPrimoFotogramma;
    [Test]
    procedure DovrebbeInterpolareUnTagTraDueFotogrammi;
    [Test]
    procedure DovrebbeDareFalsoPerUnTagCheNonCe;
    [Test]
    procedure DovrebbeRicordareUnModelloMancanteEUnFileDanneggiato;
    [Test]
    procedure DovrebbeDareIModelliDelMondoPerINomiConLAsterisco;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Models.Static.Md3.Intf, DelphiDoom.Q3Render.Types,
  DelphiDoom.Q3Render.Intf, DelphiDoom.Tests.Q3Render.Support, DelphiDoom.Tests.MapFile.BspSample;

type
  TRig = record
    Files: TMemoryFiles;
    Keep: IQ3RenderFiles;
    System: IQ3RenderSystem;
  end;

function MakeRig: TRig;
begin
  Result.Files := TMemoryFiles.Create;
  Result.Keep := Result.Files;
  Result.Files.Add('models/w.md3', TTestSupport.Md3Bytes('models/w/skin'));
  Result.Files.Add('models/w_1.md3', TTestSupport.Md3Bytes('models/w/lod1'));
  Result.Files.Add('models/bad.md3', TBytes.Create(1, 2, 3, 4));
  Result.System := TTestSupport.BuildSystem(Result.Keep, []);
end;

procedure TTestQ3ModelRegistry.DovrebbeLeggereUnMd3ELeSueShader;
var
  LRig: TRig;
  LModel: IMd3Model;
begin
  LRig := MakeRig;
  Assert.AreEqual(1, LRig.System.Models.Register('models/w.md3'));
  LModel := LRig.System.Models.GetModel(1);
  Assert.AreEqual(2, LModel.NumFrames);
  Assert.AreEqual(1, LModel.NumTags);
  Assert.AreEqual(1, LModel.NumSurfaces);
  Assert.AreEqual(1, LRig.System.Models.LoadedCount);
  Assert.AreEqual(1, LRig.System.Models.Register('models/w.md3'));
  // the shader of the surface is registered (the image is not there: defective, as RE_RegisterShader would see it)
  Assert.IsTrue(Length(LRig.System.Shaders.DefectiveNames) >= 1);
end;

procedure TTestQ3ModelRegistry.DovrebbeLeggereIlivelliDiDettaglioPerLeLoroShader;
var
  LRig: TRig;
  LName: string;
  LFound: Boolean;
begin
  LRig := MakeRig;
  LRig.System.Models.Register('models/w.md3');
  // RE_RegisterModel looks for w_2.md3, w_1.md3 and w.md3
  Assert.AreEqual(0, LRig.Files.Reads.IndexOf('models/w_2.md3'));
  Assert.IsTrue(LRig.Files.Reads.IndexOf('models/w_1.md3') > 0);
  Assert.IsTrue(LRig.Files.Reads.IndexOf('models/w.md3') > LRig.Files.Reads.IndexOf('models/w_1.md3'));
  LFound := False;
  for LName in LRig.System.Shaders.DefectiveNames do
    if SameText(LName, 'models/w/lod1') then
      LFound := True;
  Assert.IsTrue(LFound, 'the shader of the lower level of detail is registered too');
end;

procedure TTestQ3ModelRegistry.DovrebbeDareLeBoundsDelPrimoFotogramma;
var
  LRig: TRig;
  LMins, LMaxs: TQ3RenderVec3;
begin
  LRig := MakeRig;
  LRig.System.Models.Register('models/w.md3');
  Assert.IsTrue(LRig.System.Models.ModelBounds(1, LMins, LMaxs));
  Assert.AreEqual(Single(-10), LMins[0]);
  Assert.AreEqual(Single(-1), LMins[1]);
  Assert.AreEqual(Single(-2), LMins[2]);
  Assert.AreEqual(Single(10), LMaxs[0]);
  Assert.AreEqual(Single(4), LMaxs[2]);
  Assert.IsFalse(LRig.System.Models.ModelBounds(9, LMins, LMaxs));
end;

procedure TTestQ3ModelRegistry.DovrebbeInterpolareUnTagTraDueFotogrammi;
var
  LRig: TRig;
  LOrigin: TQ3RenderVec3;
  LAxis: TQ3RenderAxis;
begin
  LRig := MakeRig;
  LRig.System.Models.Register('models/w.md3');
  // the tag is at x = 0 in the first frame and x = 10 in the second
  Assert.IsTrue(LRig.System.Models.LerpTag(1, 0, 1, 0.5, 'tag_weapon', LOrigin, LAxis));
  Assert.AreEqual(Single(5), LOrigin[0]);
  Assert.AreEqual(Single(1), LAxis[0][0]);
  Assert.AreEqual(Single(1), LAxis[1][1]);
  Assert.AreEqual(Single(1), LAxis[2][2]);
end;

procedure TTestQ3ModelRegistry.DovrebbeDareFalsoPerUnTagCheNonCe;
var
  LRig: TRig;
  LOrigin: TQ3RenderVec3;
  LAxis: TQ3RenderAxis;
begin
  LRig := MakeRig;
  LRig.System.Models.Register('models/w.md3');
  Assert.IsFalse(LRig.System.Models.LerpTag(1, 0, 1, 0.5, 'tag_head', LOrigin, LAxis));
  Assert.IsFalse(LRig.System.Models.LerpTag(7, 0, 1, 0.5, 'tag_weapon', LOrigin, LAxis));
end;

procedure TTestQ3ModelRegistry.DovrebbeRicordareUnModelloMancanteEUnFileDanneggiato;
var
  LRig: TRig;
  LReads: Integer;
begin
  LRig := MakeRig;
  Assert.AreEqual(0, LRig.System.Models.Register('models/none.md3'));
  LReads := LRig.Files.Reads.Count;
  Assert.AreEqual(0, LRig.System.Models.Register('models/none.md3'));
  Assert.AreEqual(LReads, LRig.Files.Reads.Count, 'the disk is not scanned again');
  Assert.AreEqual(0, LRig.System.Models.Register('models/bad.md3'));
  Assert.AreEqual<Integer>(2, Length(LRig.System.Models.MissingNames));
  Assert.AreEqual(0, LRig.System.Models.Register(''));
end;

procedure TTestQ3ModelRegistry.DovrebbeDareIModelliDelMondoPerINomiConLAsterisco;
var
  LRig: TRig;
  LBuilder: TBspSampleBuilder;
  LWorld: IQ3RenderWorld;
  LMins, LMaxs: TQ3RenderVec3;
begin
  LRig := MakeRig;
  // without a world there are no brush models
  Assert.AreEqual(0, LRig.System.Models.Register('*1'));
  LBuilder := TBspSampleBuilder.Create;
  try
    LRig.Files.Add('maps/room.bsp', LBuilder.Build(0));
  finally
    LBuilder.Free;
  end;
  LWorld := LRig.System.WorldLoader.Load('maps/room.bsp');
  Assert.IsNotNull(LWorld);
  LRig.System.Models.SetWorld(LWorld);
  Assert.AreEqual(1, LRig.System.Models.Register('*0'));
  Assert.IsTrue(LRig.System.Models.ModelBounds(1, LMins, LMaxs));
  Assert.AreEqual(0, LRig.System.Models.Register('*99'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3ModelRegistry);

end.
