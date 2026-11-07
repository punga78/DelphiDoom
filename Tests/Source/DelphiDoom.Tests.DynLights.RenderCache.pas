{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the dynamic lights library - the records of the        }
{  renderers                                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DynLights.RenderCache;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.DynLights.Types,
  DelphiDoom.DynLights.Intf;

type
  /// <summary>Puts ACount lights in the registry and says Found</summary>
  TFakeRenderLoader = class(TInterfacedObject, IDynLightLoader)
  public
    Registry: IDynLightRegistry;
    LightCount: Integer;
    Found: Boolean;
    LastGldefsAsLightDef: Boolean;
    Loads: Integer;
    function Load(AGldefsAsLightDef: Boolean): Boolean;
  end;

  /// <summary>The render of light i at tic t is (i, t, i + t); every call is counted</summary>
  TFakeRenderAnimator = class(TInterfacedObject, IDynLightAnimator)
  public
    Calls: Integer;
    Resets: Integer;
    function GetRender(AIndex, ALevelTime: Integer): TDynLightRender;
    procedure Reset;
  end;

  [TestFixture]
  [Category('dynlights')]
  TTestDynLightsRenderCache = class(TObject)
  private
    FRegistry: IDynLightRegistry;
    FLoader: TFakeRenderLoader;
    FLoaderRef: IDynLightLoader;
    FAnimator: TFakeRenderAnimator;
    FAnimatorRef: IDynLightAnimator;
    FCache: IDynLightRenderCache;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAvereUnRecordPerLuceDopoIlCaricamento;
    [Test]
    procedure DovrebbeDareLaRispostaDelCaricatore;
    [Test]
    procedure DovrebbeRipulireRegistroEAnimatorePrimaDiCaricare;
    [Test]
    procedure DovrebbeCalcolareLaLuceDallAnimatore;
    [Test]
    procedure DovrebbeCalcolareUnaLuceUnaVoltaPerTic;
    [Test]
    procedure DovrebbeRicalcolareAlTicSuccessivo;
    [Test]
    procedure DovrebbeDareSempreLoStessoRecord;
    [Test]
    procedure DovrebbeSpegnereSempreLOmbra;
    [Test]
    procedure DovrebbeRicalcolareDopoUnNuovoCaricamento;
    [Test]
    procedure DovrebbeSvuotareTuttoConClear;
    [Test]
    procedure DovrebbeRifiutareDipendenzeNil;
  end;

implementation

uses
  DelphiDoom.DynLights.Factory;

{ TFakeRenderLoader }

function TFakeRenderLoader.Load(AGldefsAsLightDef: Boolean): Boolean;
var
  LIndex: Integer;
  LDefinition: TDynLightDefinition;
begin
  Inc(Loads);
  LastGldefsAsLightDef := AGldefsAsLightDef;
  for LIndex := 0 to LightCount - 1 do
  begin
    LDefinition := Default(TDynLightDefinition);
    LDefinition.Name := 'LIGHT' + IntToStr(LIndex);
    Registry.Add(LDefinition);
  end;
  Result := Found;
end;

{ TFakeRenderAnimator }

function TFakeRenderAnimator.GetRender(AIndex, ALevelTime: Integer): TDynLightRender;
begin
  Inc(Calls);
  Result := Default(TDynLightRender);
  Result.R := AIndex;
  Result.G := ALevelTime;
  Result.B := AIndex + ALevelTime;
  Result.Radius := 100 + AIndex;
  Result.X := 1;
  Result.Y := 2;
  Result.Z := 3;
  Result.Shadow := True;
end;

procedure TFakeRenderAnimator.Reset;
begin
  Inc(Resets);
end;

{ TTestDynLightsRenderCache }

procedure TTestDynLightsRenderCache.Setup;
begin
  FRegistry := TDynLightFactory.CreateRegistry;
  FLoader := TFakeRenderLoader.Create;
  FLoaderRef := FLoader;
  FLoader.Registry := FRegistry;
  FLoader.LightCount := 3;
  FLoader.Found := True;
  FAnimator := TFakeRenderAnimator.Create;
  FAnimatorRef := FAnimator;
  FCache := TDynLightFactory.CreateRenderCache(FLoaderRef, FRegistry, FAnimatorRef);
end;

procedure TTestDynLightsRenderCache.TearDown;
begin
  FCache := nil;
  FLoader := nil;
  FLoaderRef := nil;
  FAnimator := nil;
  FAnimatorRef := nil;
  FRegistry := nil;
end;

procedure TTestDynLightsRenderCache.DovrebbeAvereUnRecordPerLuceDopoIlCaricamento;
begin
  Assert.AreEqual(0, FCache.Count);
  FCache.Load(False);
  Assert.AreEqual(3, FCache.Count);
end;

procedure TTestDynLightsRenderCache.DovrebbeDareLaRispostaDelCaricatore;
begin
  Assert.IsTrue(FCache.Load(True));
  Assert.IsTrue(FLoader.LastGldefsAsLightDef);
  FLoader.Found := False;
  Assert.IsFalse(FCache.Load(False));
  Assert.IsFalse(FLoader.LastGldefsAsLightDef);
end;

procedure TTestDynLightsRenderCache.DovrebbeRipulireRegistroEAnimatorePrimaDiCaricare;
begin
  FCache.Load(False);
  FCache.Load(False);
  // the second load starts from an empty registry: still three lights, not six
  Assert.AreEqual(3, FRegistry.Count);
  Assert.AreEqual(3, FCache.Count);
  Assert.AreEqual(2, FAnimator.Resets);
end;

procedure TTestDynLightsRenderCache.DovrebbeCalcolareLaLuceDallAnimatore;
var
  LLight: PDynLightRender;
begin
  FCache.Load(False);
  LLight := FCache.GetLight(2, 40);
  Assert.AreEqual(Single(2), LLight.R);
  Assert.AreEqual(Single(40), LLight.G);
  Assert.AreEqual(Single(42), LLight.B);
  Assert.AreEqual(Single(102), LLight.Radius);
  Assert.AreEqual(Single(1), LLight.X);
  Assert.AreEqual(Single(2), LLight.Y);
  Assert.AreEqual(Single(3), LLight.Z);
end;

procedure TTestDynLightsRenderCache.DovrebbeCalcolareUnaLuceUnaVoltaPerTic;
begin
  FCache.Load(False);
  FCache.GetLight(1, 10);
  FCache.GetLight(1, 10);
  FCache.GetLight(1, 10);
  Assert.AreEqual(1, FAnimator.Calls);
  FCache.GetLight(0, 10);
  Assert.AreEqual(2, FAnimator.Calls);
end;

procedure TTestDynLightsRenderCache.DovrebbeRicalcolareAlTicSuccessivo;
var
  LLight: PDynLightRender;
begin
  FCache.Load(False);
  FCache.GetLight(1, 10);
  LLight := FCache.GetLight(1, 11);
  Assert.AreEqual(2, FAnimator.Calls);
  Assert.AreEqual(Single(11), LLight.G);
  // back to a tic that was seen before: calculated again
  FCache.GetLight(1, 10);
  Assert.AreEqual(3, FAnimator.Calls);
end;

procedure TTestDynLightsRenderCache.DovrebbeDareSempreLoStessoRecord;
var
  LFirst: PDynLightRender;
begin
  FCache.Load(False);
  LFirst := FCache.GetLight(0, 1);
  FCache.GetLight(1, 1);
  Assert.IsTrue(LFirst = FCache.GetLight(0, 2));
  Assert.IsFalse(LFirst = FCache.GetLight(1, 2));
end;

procedure TTestDynLightsRenderCache.DovrebbeSpegnereSempreLOmbra;
var
  LLight: PDynLightRender;
begin
  FCache.Load(False);
  LLight := FCache.GetLight(0, 5);
  Assert.IsFalse(LLight.Shadow);
  LLight.Shadow := True;
  // a renderer may turn it on during a frame: the next call puts it off again
  Assert.IsFalse(FCache.GetLight(0, 5).Shadow);
end;

procedure TTestDynLightsRenderCache.DovrebbeRicalcolareDopoUnNuovoCaricamento;
begin
  FCache.Load(False);
  FCache.GetLight(0, 7);
  FCache.Load(False);
  FCache.GetLight(0, 7);
  Assert.AreEqual(2, FAnimator.Calls);
end;

procedure TTestDynLightsRenderCache.DovrebbeSvuotareTuttoConClear;
begin
  FCache.Load(False);
  FCache.Clear;
  Assert.AreEqual(0, FCache.Count);
  Assert.AreEqual(0, FRegistry.Count);
  Assert.AreEqual(2, FAnimator.Resets);
end;

procedure TTestDynLightsRenderCache.DovrebbeRifiutareDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TDynLightFactory.CreateRenderCache(nil, FRegistry, FAnimatorRef);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TDynLightFactory.CreateRenderCache(FLoaderRef, nil, FAnimatorRef);
    end,
    EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TDynLightFactory.CreateRenderCache(FLoaderRef, FRegistry, nil);
    end,
    EArgumentNilException);
end;

end.
