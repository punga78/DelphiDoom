{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - markerDef and renderDef              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.MarkerRender;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('GuiWindow')]
  TTestGuiMarkerRender = class
  public
    [Test]
    procedure IlMarkerLeggeLeStatisticheEDisegnaIMarcatori;
    [Test]
    procedure UnClicSuUnMarcatoreChiedeIlSalto;
    [Test]
    procedure UnClicFuoriDaiMarcatoriUsaIlTempoDelCursore;
    [Test]
    procedure IlDestroEIlBarraSpazioDannoIComandi;
    [Test]
    procedure UnFileDiStatisticheConTroppeVociDaUnErrore;
    [Test]
    procedure IlMouseSuiMarcatoriCambiaLAnteprima;
    [Test]
    procedure LaFinestraDiRenderCreaLuceEModelloAlPrimoDisegno;
    [Test]
    procedure LaFinestraDiRenderAggiornaLAnimazioneEIlCampoVisivo;
    [Test]
    procedure LaFinestraDiRenderSenzaModelloAvvisa;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3,
  DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Marker, DelphiDoom.Gui.Window.Render, DelphiDoom.Gui.Window.Hosts,
  DelphiDoom.Gui.Window.Keys, DelphiDoom.Gui.Material.Intf, DelphiDoom.Gui.Window.Types, DelphiDoom.Gui.DrawContext,
  DelphiDoom.Tests.Gui.DrawFakes, DelphiDoom.Tests.Gui.WindowFakes, DelphiDoom.Gui.UserInterface;

type
  TFakeLister = class(TInterfacedObject, IGuiFileLister)
    function ListFiles(const APath, AExtension: AnsiString): TArray<AnsiString>;
  end;

  TFakeScratch = class(TInterfacedObject, IGuiScratchImages)
  public
    Uploads: Integer;
    NonZero: Integer;
    procedure UploadScratch(const AMaterial: IGuiMaterial; const APixels: TArray<Cardinal>; const AWidth, AHeight: Integer);
  end;

  TFakeWorld = class(TInterfacedObject, IGuiRenderWorld)
  public
    Calls: TStringList;
    constructor Create(const ACalls: TStringList);
    procedure InitFromMap;
    function AddLightDef(const ALight: TGuiRenderLight): Integer;
    procedure UpdateLightDef(const AHandle: Integer; const ALight: TGuiRenderLight);
    function AddEntityDef(const AEntity: TGuiRenderEntity): Integer;
    procedure UpdateEntityDef(const AHandle: Integer; const AEntity: TGuiRenderEntity);
    procedure RenderScene(const AView: TGuiRenderView);
  end;

  TFakeRenderHost = class(TInterfacedObject, IGuiRenderHost)
  public
    Calls: TStringList;
    constructor Create(const ACalls: TStringList);
    function AllocRenderWorld: IGuiRenderWorld;
    function ParseModelEntity(const AModelName, AOrigin: AnsiString): TGuiRenderEntity;
    function AnimationLength(const AAnimClass, AAnimName: AnsiString): Integer;
    procedure CreateAnimationFrame(const AAnimClass, AAnimName: AnsiString; const ATime: Integer);
  end;

function TFakeLister.ListFiles(const APath, AExtension: AnsiString): TArray<AnsiString>;
begin
  Result := TArray<AnsiString>.Create('demos/m/120.tga', 'demos/m/600.tga');
end;

procedure TFakeScratch.UploadScratch(const AMaterial: IGuiMaterial; const APixels: TArray<Cardinal>;
  const AWidth, AHeight: Integer);
var
  LPixel: Cardinal;
begin
  Inc(Uploads);
  for LPixel in APixels do
    if LPixel <> 0 then
      Inc(NonZero);
end;

constructor TFakeWorld.Create(const ACalls: TStringList);
begin
  inherited Create;
  Calls := ACalls;
end;

procedure TFakeWorld.InitFromMap;
begin
  Calls.Add('InitFromMap');
end;

function TFakeWorld.AddLightDef(const ALight: TGuiRenderLight): Integer;
begin
  Calls.Add(Format('AddLight %g %g %g', [ALight.Origin.X, ALight.Origin.Y, ALight.Red], TFormatSettings.Invariant));
  Result := 5;
end;

procedure TFakeWorld.UpdateLightDef(const AHandle: Integer; const ALight: TGuiRenderLight);
begin
  Calls.Add(Format('UpdateLight %d', [AHandle]));
end;

function TFakeWorld.AddEntityDef(const AEntity: TGuiRenderEntity): Integer;
begin
  Calls.Add('AddEntity ' + string(AEntity.ModelName));
  Result := 9;
end;

procedure TFakeWorld.UpdateEntityDef(const AHandle: Integer; const AEntity: TGuiRenderEntity);
begin
  Calls.Add(Format('UpdateEntity %d yaw %g', [AHandle, AEntity.Yaw], TFormatSettings.Invariant));
end;

procedure TFakeWorld.RenderScene(const AView: TGuiRenderView);
begin
  Calls.Add(Format('Render %g fov %.3f %.3f t %d', [AView.Width, AView.FovX, AView.FovY, AView.Time], TFormatSettings.Invariant));
end;

constructor TFakeRenderHost.Create(const ACalls: TStringList);
begin
  inherited Create;
  Calls := ACalls;
end;

function TFakeRenderHost.AllocRenderWorld: IGuiRenderWorld;
begin
  Result := TFakeWorld.Create(Calls);
end;

function TFakeRenderHost.ParseModelEntity(const AModelName, AOrigin: AnsiString): TGuiRenderEntity;
begin
  Result := Default(TGuiRenderEntity);
  Result.HasModel := AModelName <> '';
  Result.ModelName := AModelName;
  Result.Origin := AOrigin;
end;

function TFakeRenderHost.AnimationLength(const AAnimClass, AAnimName: AnsiString): Integer;
begin
  Result := 1000;
end;

procedure TFakeRenderHost.CreateAnimationFrame(const AAnimClass, AAnimName: AnsiString; const ATime: Integer);
begin
  Calls.Add(Format('Frame %s %s %d', [string(AAnimClass), string(AAnimName), ATime]));
end;

const
  MARKER_GUI = 'windowDef Desktop { rect 0, 0, 640, 480 ' +
    'markerDef bar { rect 0, 0, 400, 50 markerMat "guis/marker" markerStop "guis/stop" markerColor 1, 1, 1, 1 background "guis/graph" } ' +
    'windowDef markerText { rect 0, 60, 100, 20 } windowDef markerBackground { rect 0, 90, 100, 20 } }';

type
  TMarkerRig = class
  public
    World: TGuiWindowWorld;
    Scratch: TFakeScratch;
    ScratchRef: IInterface;
    Surface: IInterface;
    Materials: TGuiHarnessMaterials;
    MaterialsRef: IInterface;
    Draw: TGuiDrawContext;
    Files: TGuiHarnessFiles;
    FilesRef: IInterface;
    constructor Create(const AStats: Integer);
    destructor Destroy; override;
    function Marker: TGuiMarkerWindow;
  end;

constructor TMarkerRig.Create(const AStats: Integer);
var
  LBytes: TBytes;
  LIndex: Integer;
  LValue: Integer;
  LCount: Integer;
begin
  World := TGuiWindowWorld.Create;
  Scratch := TFakeScratch.Create;
  ScratchRef := Scratch;
  Materials := TGuiHarnessMaterials.Create(World.Lines);
  MaterialsRef := Materials;
  Files := TGuiHarnessFiles.Create;
  FilesRef := Files;
  TGuiHarnessFonts.AddSet(Files, 'fonts/english');
  Draw := TGuiDrawContext.Create(TGuiHarnessSurface.Create(World.Lines), Materials, Files, nil, nil);
  Draw.Initialize;
  SetLength(LBytes, 4 + AStats * 16);
  LCount := AStats;
  Move(LCount, LBytes[0], 4);
  for LIndex := 0 to AStats * 4 - 1 do
  begin
    LValue := (LIndex * 7) mod 50 - 3;
    Move(LValue, LBytes[4 + LIndex * 4], 4);
  end;
  World.Files.Add('demos/m/stats.dat', LBytes);
  World.Load(MARKER_GUI);
  World.UserInterface.Context.Materials := Materials;
  World.UserInterface.Context.DrawContext := Draw;
  World.UserInterface.Context.ScratchImages := Scratch;
  World.UserInterface.Context.FileLister := TFakeLister.Create;
end;

destructor TMarkerRig.Destroy;
begin
  World.Free;
  Draw.Free;
  inherited Destroy;
end;

function TMarkerRig.Marker: TGuiMarkerWindow;
begin
  Result := World.UserInterface.Desktop.Children[0] as TGuiMarkerWindow;
end;

procedure TTestGuiMarkerRender.IlMarkerLeggeLeStatisticheEDisegnaIMarcatori;
var
  LRig: TMarkerRig;
begin
  LRig := TMarkerRig.Create(30);
  try
    LRig.World.UserInterface.SetStateString('statData', 'demos/m/stats.dat');
    LRig.World.UserInterface.SetStateInt('loadLength', 1000);
    LRig.World.UserInterface.Activate(True, 10);
    Assert.AreEqual(30, LRig.Marker.NumStats);
    Assert.AreEqual(2, LRig.Marker.Markers.Count);
    Assert.AreEqual(120, LRig.Marker.Markers[0].Time);
    Assert.AreEqual(1, LRig.Scratch.Uploads);
    Assert.IsTrue(LRig.Scratch.NonZero > 100, 'the lines of the four statistics are in the image');
    LRig.World.UserInterface.Redraw(20);
    Assert.AreEqual(Single(16), LRig.Marker.Markers[0].Rect.W);
    Assert.IsTrue(Pos('guis/marker', LRig.World.Lines.Text) > 0, LRig.World.Lines.Text);
  finally
    LRig.Free;
  end;
end;

procedure TTestGuiMarkerRender.UnClicSuUnMarcatoreChiedeIlSalto;
var
  LRig: TMarkerRig;
  LUpdate: Boolean;
  LCommand: AnsiString;
begin
  LRig := TMarkerRig.Create(30);
  try
    LRig.World.UserInterface.SetStateString('statData', 'demos/m/stats.dat');
    LRig.World.UserInterface.SetStateInt('loadLength', 1000);
    LRig.World.UserInterface.SetStateFloat('loadPct', 0.1);
    LRig.World.UserInterface.Activate(True, 10);
    LRig.World.UserInterface.Redraw(20);
    LUpdate := False;
    LRig.World.UserInterface.Context.CursorX := LRig.Marker.Markers[1].Rect.X + 4;
    LRig.World.UserInterface.Context.CursorY := LRig.Marker.Markers[1].Rect.Y + 4;
    LCommand := LRig.Marker.HandleEvent(TGuiSysEvent.Make(GUI_SE_KEY, GUI_K_MOUSE1, 1), LUpdate);
    Assert.AreEqual('cmdDemoGotoMarker', string(LCommand));
    Assert.AreEqual(1, LRig.Marker.CurrentMarker);
    Assert.AreEqual(600, LRig.Marker.StopTime);
    Assert.AreEqual(600, LRig.World.UserInterface.GetStateInt('currentMarker'));
  finally
    LRig.Free;
  end;
end;

procedure TTestGuiMarkerRender.UnClicFuoriDaiMarcatoriUsaIlTempoDelCursore;
var
  LRig: TMarkerRig;
  LUpdate: Boolean;
begin
  LRig := TMarkerRig.Create(30);
  try
    LRig.World.UserInterface.SetStateString('statData', 'demos/m/stats.dat');
    LRig.World.UserInterface.SetStateInt('loadLength', 1000);
    LRig.World.UserInterface.SetStateFloat('loadPct', 1);
    LRig.World.UserInterface.Activate(True, 10);
    LRig.World.UserInterface.Context.CursorX := 200;
    LRig.World.UserInterface.Context.CursorY := 20;
    LRig.World.UserInterface.Redraw(20);
    Assert.AreEqual(500, LRig.Marker.CurrentTime);
    LUpdate := False;
    Assert.AreEqual('', string(LRig.Marker.HandleEvent(TGuiSysEvent.Make(GUI_SE_KEY, GUI_K_MOUSE1, 1), LUpdate)));
    Assert.AreEqual(-1, LRig.Marker.CurrentMarker);
    Assert.AreEqual(500, LRig.Marker.StopTime);
    LRig.World.UserInterface.Redraw(30);
  finally
    LRig.Free;
  end;
end;

procedure TTestGuiMarkerRender.IlDestroEIlBarraSpazioDannoIComandi;
var
  LRig: TMarkerRig;
  LUpdate: Boolean;
begin
  LRig := TMarkerRig.Create(0);
  try
    LUpdate := False;
    Assert.AreEqual('cmdDemoGotoMarker', string(LRig.Marker.HandleEvent(TGuiSysEvent.Make(GUI_SE_KEY, GUI_K_MOUSE2, 1), LUpdate)));
    Assert.AreEqual('cmdDemoPauseFrame', string(LRig.Marker.HandleEvent(TGuiSysEvent.Make(GUI_SE_KEY, GUI_K_SPACE, 1), LUpdate)));
    Assert.AreEqual('', string(LRig.Marker.HandleEvent(TGuiSysEvent.Make(GUI_SE_KEY, GUI_K_SPACE, 0), LUpdate)));
    Assert.AreEqual('', string(LRig.Marker.HandleEvent(TGuiSysEvent.Make(GUI_SE_CHAR, 65, 0), LUpdate)));
    Assert.AreEqual('', string(LRig.Marker.HandleEvent(TGuiSysEvent.Make(GUI_SE_KEY, 65, 1), LUpdate)));
  finally
    LRig.Free;
  end;
end;

procedure TTestGuiMarkerRender.IlMouseSuiMarcatoriCambiaLAnteprima;
var
  LRig: TMarkerRig;
  LUpdate, LSimple: Boolean;
begin
  LRig := TMarkerRig.Create(30);
  try
    LRig.World.UserInterface.SetStateString('statData', 'demos/m/stats.dat');
    LRig.World.UserInterface.SetStateInt('loadLength', 1000);
    LRig.World.UserInterface.Activate(True, 10);
    LRig.World.UserInterface.Redraw(20);
    LRig.Marker.RouteMouseCoords(0, 0);
    Assert.AreEqual('No Preview', string(LRig.World.UserInterface.Desktop.FindDrawWindow('markerBackground', LSimple).Text.AsText));
    // a click on a marker keeps it as the current one: the preview then shows its picture
    LRig.World.UserInterface.Context.CursorX := LRig.Marker.Markers[0].Rect.X + 4;
    LRig.World.UserInterface.Context.CursorY := LRig.Marker.Markers[0].Rect.Y + 4;
    LUpdate := False;
    LRig.Marker.HandleEvent(TGuiSysEvent.Make(GUI_SE_KEY, GUI_K_MOUSE1, 1), LUpdate);
    LRig.World.UserInterface.Context.CursorX := 390;
    LRig.World.UserInterface.Context.CursorY := 300;
    LRig.Marker.RouteMouseCoords(0, 0);
    Assert.AreEqual('', string(LRig.World.UserInterface.Desktop.FindDrawWindow('markerBackground', LSimple).Text.AsText));
    LRig.World.UserInterface.Redraw(30);
    Assert.IsTrue(LRig.Marker.StopTime = 120);
  finally
    LRig.Free;
  end;
end;

procedure TTestGuiMarkerRender.UnFileDiStatisticheConTroppeVociDaUnErrore;
var
  LRig: TMarkerRig;
  LRaised: Boolean;
  LBytes: TBytes;
  LCount: Integer;
begin
  LRig := TMarkerRig.Create(2);
  try
    SetLength(LBytes, 8);
    LCount := 99999;
    Move(LCount, LBytes[0], 4);
    LRig.World.Files.Add('demos/m/big.dat', LBytes);
    LRig.World.UserInterface.SetStateString('statData', 'demos/m/big.dat');
    LRaised := False;
    try
      LRig.World.UserInterface.Activate(True, 10);
    except
      on E: EGuiWindowException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, 'the original reads past its table of 3600 entries');
  finally
    LRig.Free;
  end;
end;

type
  TRenderRig = class
  public
    World: TGuiWindowWorld;
    Calls: TStringList;
    Host: IGuiRenderHost;
    Materials: TGuiHarnessMaterials;
    MaterialsRef: IInterface;
    Files: TGuiHarnessFiles;
    FilesRef: IInterface;
    Draw: TGuiDrawContext;
    constructor Create(const AText: AnsiString);
    destructor Destroy; override;
  end;

constructor TRenderRig.Create(const AText: AnsiString);
begin
  World := TGuiWindowWorld.Create;
  Calls := TStringList.Create;
  Host := TFakeRenderHost.Create(Calls);
  Materials := TGuiHarnessMaterials.Create(World.Lines);
  MaterialsRef := Materials;
  Files := TGuiHarnessFiles.Create;
  FilesRef := Files;
  TGuiHarnessFonts.AddSet(Files, 'fonts/english');
  Draw := TGuiDrawContext.Create(TGuiHarnessSurface.Create(World.Lines), Materials, Files, nil, nil);
  Draw.Initialize;
  World.Load(AText);
  World.UserInterface.Context.Materials := Materials;
  World.UserInterface.Context.DrawContext := Draw;
  World.UserInterface.Context.RenderHost := Host;
end;

destructor TRenderRig.Destroy;
begin
  World.Free;
  Draw.Free;
  Calls.Free;
  inherited Destroy;
end;

procedure TTestGuiMarkerRender.LaFinestraDiRenderCreaLuceEModelloAlPrimoDisegno;
var
  LRig: TRenderRig;
begin
  LRig := TRenderRig.Create('windowDef Desktop { rect 0, 0, 640, 480 renderDef r { rect 10, 10, 200, 100 model "models/x" ' +
    'lightOrigin -100, 0, 50, 1 lightColor 1, 0.5, 0.25, 1 modelRotate 10, 20, 30, 0 } }');
  try
    LRig.World.UserInterface.Redraw(100);
    Assert.AreEqual('InitFromMap', LRig.Calls[0]);
    Assert.IsTrue(Pos('AddLight', LRig.Calls[1]) = 1, LRig.Calls.Text);
    Assert.AreEqual('AddEntity models/x', LRig.Calls[2]);
    LRig.Calls.Clear;
    LRig.World.UserInterface.Redraw(150);
    Assert.IsTrue(Pos('InitFromMap', LRig.Calls.Text) = 0, 'the world is made once');
    Assert.IsTrue(Pos('UpdateEntity 9 yaw 20', LRig.Calls.Text) > 0, LRig.Calls.Text);
  finally
    LRig.Free;
  end;
end;

procedure TTestGuiMarkerRender.LaFinestraDiRenderAggiornaLAnimazioneEIlCampoVisivo;
var
  LRig: TRenderRig;
begin
  LRig := TRenderRig.Create('windowDef Desktop { rect 0, 0, 640, 480 renderDef r { rect 0, 0, 200, 100 model "m" anim "walk" animClass "zombie" ' +
    '} }');
  try
    LRig.World.UserInterface.Redraw(100);
    Assert.IsTrue(Pos('Frame zombie walk 0', LRig.Calls.Text) > 0, LRig.Calls.Text);
    // 2 * atan(100 / 200) in degrees
    Assert.IsTrue(Pos('fov 90.000 53.130', LRig.Calls.Text) > 0, LRig.Calls.Text);
    LRig.Calls.Clear;
    LRig.World.UserInterface.Redraw(400);
    Assert.IsTrue(Pos('Frame zombie walk 300', LRig.Calls.Text) > 0);
    LRig.Calls.Clear;
    LRig.World.UserInterface.Redraw(1300);
    Assert.IsTrue(Pos('Frame zombie walk 0', LRig.Calls.Text) > 0, 'the animation starts again after its length');
  finally
    LRig.Free;
  end;
end;

procedure TTestGuiMarkerRender.LaFinestraDiRenderSenzaModelloAvvisa;
var
  LRig: TRenderRig;
begin
  LRig := TRenderRig.Create('windowDef Desktop { rect 0, 0, 640, 480 renderDef r { rect 0, 0, 200, 100 } }');
  try
    LRig.World.UserInterface.Redraw(100);
    Assert.IsTrue(Pos('no model set', LRig.World.Lines.Text) > 0);
    Assert.IsTrue(Pos('AddEntity', LRig.Calls.Text) = 0);
  finally
    LRig.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiMarkerRender);

end.
