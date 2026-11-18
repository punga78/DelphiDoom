{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R0) - the host   }
{  adapter that cgame and ui call (IQ3HostRenderer) over the recording         }
{  renderer of Q3Host                                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.Adapter;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Render')]
  TTestQ3HostRendererAdapter = class
  public
    [Test]
    procedure DovrebbeDareGliStessiNumeriDelRendererInterno;
    [Test]
    procedure DovrebbeCaricareLeShaderEIModelliRegistrati;
    [Test]
    procedure DovrebbeScrivereLeBoundsVereDiUnModelloCaricato;
    [Test]
    procedure DovrebbeLasciareLeRisposteNeutreSenzaDati;
    [Test]
    procedure DovrebbeScrivereUnTagVeroERitornareUno;
    [Test]
    procedure DovrebbeUsareIlMondoCaricatoPerInPvs;
    [Test]
    procedure DovrebbeSopravvivereAUnMondoMancanteODanneggiato;
    [Test]
    procedure DovrebbeInoltrareTutteLeAltreChiamate;
  end;

implementation

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.Qvm.Intf,
  DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Client.Intf, DelphiDoom.Q3Host.ClientRecordingRenderer,
  DelphiDoom.Q3Render.Types,
  DelphiDoom.Q3Render.Intf, DelphiDoom.Q3Render.Host.Adapter, DelphiDoom.Tests.Q3Render.Support,
  DelphiDoom.Tests.MapFile.BspSample;

type
  TRig = record
    Files: TMemoryFiles;
    Keep: IQ3RenderFiles;
    System: IQ3RenderSystem;
    Recorder: TQ3RecordingRenderer;
    Inner: IQ3HostRenderer;
    Log: TCountingLog;
    LogIntf: ILog;
    Adapter: IQ3HostRenderer;
  end;

function MakeRig: TRig;
var
  LBuilder: TBspSampleBuilder;
begin
  Result.Files := TMemoryFiles.Create;
  Result.Keep := Result.Files;
  Result.Files.Add('models/w.md3', TTestSupport.Md3Bytes('models/w/skin'));
  LBuilder := TBspSampleBuilder.Create;
  try
    Result.Files.Add('maps/room.bsp', LBuilder.Build(0));
  finally
    LBuilder.Free;
  end;
  Result.Files.Add('maps/bad.bsp', TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8));
  Result.System := TTestSupport.BuildSystem(Result.Keep, []);
  Result.Recorder := TQ3RecordingRenderer.Create;
  Result.Inner := Result.Recorder;
  Result.Log := TCountingLog.Create;
  Result.LogIntf := Result.Log;
  Result.Adapter := TQ3HostRendererAdapter.Create(Result.Inner, Result.System.Shaders, Result.System.Models,
    Result.System.WorldLoader, Result.LogIntf);
end;

procedure TTestQ3HostRendererAdapter.DovrebbeDareGliStessiNumeriDelRendererInterno;
var
  LRig: TRig;
  LPlain: IQ3HostRenderer;
  LName: string;
begin
  LRig := MakeRig;
  LPlain := TQ3RecordingRenderer.Create;
  for LName in ['gfx/a', 'gfx/b', 'GFX/A', 'gfx/c'] do
  begin
    Assert.AreEqual(LPlain.RegisterShader(AnsiString(LName)), LRig.Adapter.RegisterShader(AnsiString(LName)));
    Assert.AreEqual(LPlain.RegisterShaderNoMip(AnsiString(LName)), LRig.Adapter.RegisterShaderNoMip(AnsiString(LName)));
  end;
  // a model that does not load keeps the number of the recorder: nothing the module sees changes
  Assert.AreEqual(LPlain.RegisterModel('models/none.md3'), LRig.Adapter.RegisterModel('models/none.md3'));
  Assert.AreEqual(LPlain.RegisterModel('models/w.md3'), LRig.Adapter.RegisterModel('models/w.md3'));
  Assert.AreEqual(LPlain.RegisterSkin('x'), LRig.Adapter.RegisterSkin('x'));
  Assert.AreEqual(3, Length(LRig.Recorder.RegisteredNames(TQ3RecordingRenderer.KIND_SHADER)), 'gfx/a twice');
  Assert.AreEqual(8, LRig.Recorder.CallCount('RegisterShader') + LRig.Recorder.CallCount('RegisterShaderNoMip'));
end;

procedure TTestQ3HostRendererAdapter.DovrebbeCaricareLeShaderEIModelliRegistrati;
var
  LRig: TRig;
begin
  LRig := MakeRig;
  LRig.Adapter.RegisterShader('gfx/x');
  LRig.Adapter.RegisterShaderNoMip('gfx/y');
  Assert.AreEqual(2, Length(LRig.System.Shaders.DefectiveNames), 'both were asked of the shader table (no image: defective)');
  LRig.Adapter.RegisterModel('models/w.md3');
  Assert.AreEqual(1, LRig.System.Models.LoadedCount);
end;

procedure TTestQ3HostRendererAdapter.DovrebbeScrivereLeBoundsVereDiUnModelloCaricato;
var
  LRig: TRig;
  LMemory: TFlatMemory;
  LMemoryIntf: IQvmMemory;
  LModel: Integer;
begin
  LRig := MakeRig;
  LMemory := TFlatMemory.Create;
  LMemoryIntf := LMemory;
  LModel := LRig.Adapter.RegisterModel('models/w.md3');
  LRig.Adapter.ModelBounds(LMemoryIntf, LModel, 100, 200);
  Assert.AreEqual(Single(-10), LMemory.ReadSingle(100));
  Assert.AreEqual(Single(-2), LMemory.ReadSingle(108));
  Assert.AreEqual(Single(10), LMemory.ReadSingle(200));
  Assert.AreEqual(1, LRig.Recorder.CallCount('ModelBounds'), 'the call is counted by the recorder as before');
end;

procedure TTestQ3HostRendererAdapter.DovrebbeLasciareLeRisposteNeutreSenzaDati;
var
  LRig: TRig;
  LMemory: TFlatMemory;
  LMemoryIntf: IQvmMemory;
  LModel: Integer;
  LPoint: TQ3HostVec3;
begin
  LRig := MakeRig;
  LMemory := TFlatMemory.Create;
  LMemoryIntf := LMemory;
  LModel := LRig.Adapter.RegisterModel('models/none.md3');
  LRig.Adapter.ModelBounds(LMemoryIntf, LModel, 100, 200);
  Assert.AreEqual(Single(-8), LMemory.ReadSingle(100));
  Assert.AreEqual(Single(8), LMemory.ReadSingle(200));
  Assert.AreEqual(0, LRig.Adapter.LerpTag(LMemoryIntf, 300, LModel, 0, 1, 0.5, 'tag_weapon'));
  LPoint[0] := 0;
  LPoint[1] := 0;
  LPoint[2] := 0;
  Assert.AreEqual(1, LRig.Adapter.InPVS(LPoint, LPoint), 'no world: every point is in the PVS');
  Assert.AreEqual(0, LRig.Adapter.LightForPoint(LMemoryIntf, LPoint, 400, 500, 600));
end;

procedure TTestQ3HostRendererAdapter.DovrebbeScrivereUnTagVeroERitornareUno;
var
  LRig: TRig;
  LMemory: TFlatMemory;
  LMemoryIntf: IQvmMemory;
  LModel: Integer;
begin
  LRig := MakeRig;
  LMemory := TFlatMemory.Create;
  LMemoryIntf := LMemory;
  LModel := LRig.Adapter.RegisterModel('models/w.md3');
  Assert.AreEqual(1, LRig.Adapter.LerpTag(LMemoryIntf, 300, LModel, 0, 1, 0.5, 'tag_weapon'));
  Assert.AreEqual(Single(5), LMemory.ReadSingle(300), 'origin.x between 0 and 10');
  Assert.AreEqual(Single(1), LMemory.ReadSingle(304 + 8), 'axis[0][0]');
  Assert.AreEqual(Single(1), LMemory.ReadSingle(300 + 12 + 12 + 4), 'axis[1][1]');
  Assert.AreEqual(Single(1), LMemory.ReadSingle(300 + 12 + 24 + 8), 'axis[2][2]');
  // a tag the model does not have: the recorder answers, 0 and the identity
  Assert.AreEqual(0, LRig.Adapter.LerpTag(LMemoryIntf, 400, LModel, 0, 1, 0.5, 'tag_head'));
  Assert.AreEqual(2, LRig.Recorder.CallCount('LerpTag'));
end;

procedure TTestQ3HostRendererAdapter.DovrebbeUsareIlMondoCaricatoPerInPvs;
var
  LRig: TRig;
  LPoint: TQ3HostVec3;
  LSame: TQ3RenderVec3;
begin
  LRig := MakeRig;
  LRig.Adapter.LoadWorld('maps/room.bsp');
  Assert.IsNotNull(TQ3HostRendererAdapter(LRig.Adapter as TObject).World);
  Assert.AreEqual(1, LRig.Recorder.CallCount('LoadWorld'));
  LPoint[0] := 0;
  LPoint[1] := 0;
  LPoint[2] := 64;
  // the answer is the one of the world (the sample has rows of its own), not the recorder's neutral 1
  LSame[0] := 0;
  LSame[1] := 0;
  LSame[2] := 64;
  Assert.AreEqual<Integer>(Ord(TQ3HostRendererAdapter(LRig.Adapter as TObject).World.InPvs(LSame, LSame)),
    LRig.Adapter.InPVS(LPoint, LPoint));
  // "*0" is now the first brush model of the world
  Assert.AreEqual(1, LRig.System.Models.Register('*0'));
end;

procedure TTestQ3HostRendererAdapter.DovrebbeSopravvivereAUnMondoMancanteODanneggiato;
var
  LRig: TRig;
begin
  LRig := MakeRig;
  LRig.Adapter.LoadWorld('maps/none.bsp');
  Assert.AreEqual(0, LRig.Log.Warnings.Count);
  LRig.Adapter.LoadWorld('maps/bad.bsp');
  Assert.AreEqual(1, LRig.Log.Warnings.Count);
  Assert.AreEqual(2, LRig.Recorder.CallCount('LoadWorld'));
end;

procedure TTestQ3HostRendererAdapter.DovrebbeInoltrareTutteLeAltreChiamate;
var
  LRig: TRig;
  LMemory: TFlatMemory;
  LMemoryIntf: IQvmMemory;
  LOrigin: TQ3HostVec3;
begin
  LRig := MakeRig;
  LMemory := TFlatMemory.Create;
  LMemoryIntf := LMemory;
  LOrigin[0] := 0;
  LOrigin[1] := 0;
  LOrigin[2] := 0;
  LRig.Adapter.ClearScene;
  LRig.Adapter.AddRefEntityToScene(LMemoryIntf, 100);
  LRig.Adapter.AddPolyToScene(LMemoryIntf, 1, 3, 100, 1);
  LRig.Adapter.AddLightToScene(LOrigin, 1, 1, 1, 1, False);
  LRig.Adapter.RenderScene(LMemoryIntf, 100);
  LRig.Adapter.SetColor(LMemoryIntf, 0);
  LRig.Adapter.DrawStretchPic(0, 0, 1, 1, 0, 0, 1, 1, 1);
  LRig.Adapter.RegisterFont(LMemoryIntf, 'f', 16, 1000);
  LRig.Adapter.RemapShader('a', 'b', '');
  Assert.AreEqual(0, LRig.Adapter.MarkFragments(LMemoryIntf, 0, 0, 0, 0, 0, 0, 0));
  Assert.AreEqual(11332, Length(LRig.Adapter.GlConfig));
  Assert.AreEqual(1, LRig.Recorder.CallCount('RenderScene'));
  Assert.AreEqual(1, LRig.Recorder.CallCount('DrawStretchPic'));
  Assert.AreEqual(1, LRig.Recorder.CallCount('AddPolyToScene'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3HostRendererAdapter);

end.
