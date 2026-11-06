{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the dynamic lights library - behaviours of the classes}
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DynLights.Behavior;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.DynLights.Types,
  DelphiDoom.DynLights.Intf, DelphiDoom.Tests.DynLights.Fakes;

type
  [TestFixture]
  [Category('dynlights')]
  TTestDynLightsBehavior = class(TObject)
  private
    FRegistry: IDynLightRegistry;
    FStates: TFakeStateTable;
    FStatesIntf: IDynLightStateTable;
    FLog: TFakeLog;
    FLogIntf: ILog;
    FNames: TFakeNames;
    FNamesIntf: IInterface;
    function NewParser(ADeveloperMode: Boolean; ACoefficient: Double): IDynLightParser;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    [TestCase('exact', '65536,65536,65536')]
    [TestCase('half', '1,2,32768')]
    [TestCase('negative', '-1,2,-32768')]
    [TestCase('truncated toward zero', '-1,3,-21845')]
    [TestCase('too big', '1073741824,1,2147483647')]
    [TestCase('too big and negative', '-1073741824,1,-2147483648')]
    [TestCase('by zero', '5,0,2147483647')]
    [TestCase('by zero and negative', '-5,0,-2147483648')]
    procedure TestFixedDivision(AA, AB, AExpected: Integer);
    [Test]
    procedure TestTokensKnowTheAliases;
    [Test]
    procedure TestRegistryPutsTheNameInUpperCaseAndCutsIt;
    [Test]
    procedure TestRegistryFindsTheLastLightOfAName;
    [Test]
    procedure TestRegistryDoesNotFindALongNameThatWasCut;
    [Test]
    procedure TestParserDividesSizeAndOffsetByTheCoefficient;
    [Test]
    procedure TestParserNeedsItsServices;
    [Test]
    procedure TestParserKeepsTheLightThatEndsTheText;
    [Test]
    procedure TestParserLosesTheLightThatEndsTheText;
    [Test]
    procedure TestParserListsTheTextInDeveloperMode;
    [Test]
    procedure TestParserDoesNotListTheTextOtherwise;
    [Test]
    procedure TestRandomSeedUsesTheFirstNumberAsTheHighByte;
    [Test]
    procedure TestBinderFallsBackToAllStates;
    [Test]
    procedure TestBinderReplacesTheLightsOfAnObjectOnceForEachText;
    [Test]
    procedure TestLoaderReadsEachTextOnItsOwn;
    [Test]
    procedure TestLoaderSaysIfThereWasAnyLump;
    [Test]
    procedure TestAnimatorKeepsPointLightsStill;
    [Test]
    procedure TestAnimatorNeedsItsCollaborators;
    [Test]
    procedure TestAnimatorResetStartsFromScratch;
  end;

implementation

uses
  DelphiDoom.DynLights.FixedMath, DelphiDoom.DynLights.Tokens, DelphiDoom.DynLights.Factory;

{ TTestDynLightsBehavior }

procedure TTestDynLightsBehavior.Setup;
begin
  FRegistry := TDynLightFactory.CreateRegistry;
  FStates := TFakeStateTable.Create;
  FStatesIntf := FStates;
  FLog := TFakeLog.Create;
  FLogIntf := FLog;
  FNames := TFakeNames.Create;
  FNamesIntf := FNames;
end;

procedure TTestDynLightsBehavior.TearDown;
begin
  FNamesIntf := nil;
  FLogIntf := nil;
  FStatesIntf := nil;
  FRegistry := nil;
end;

function TTestDynLightsBehavior.NewParser(ADeveloperMode: Boolean;
  ACoefficient: Double): IDynLightParser;
var
  LServices: TDynLightParserServices;
begin
  LServices.Registry := FRegistry;
  LServices.Random := TFakeRandom.Create;
  LServices.Objects := FNames;
  LServices.Sprites := FNames;
  LServices.Binder := TDynLightFactory.CreateBinder(FStatesIntf);
  LServices.Context := TFakeContext.Create(ADeveloperMode);
  Result := TDynLightFactory.CreateParser(LServices, FLogIntf, ACoefficient);
end;

procedure TTestDynLightsBehavior.TestFixedDivision(AA, AB, AExpected: Integer);
begin
  Assert.AreEqual(AExpected, TDynLightFixedMath.Divide(AA, AB));
end;

procedure TTestDynLightsBehavior.TestTokensKnowTheAliases;
begin
  Assert.AreEqual(Ord(TDynLightToken.FlickerLight), Ord(TDynLightTokens.Classify('FLICKERLIGHT2')));
  Assert.AreEqual(Ord(TDynLightToken.Color), Ord(TDynLightTokens.Classify('PRIMARYCOLOR')));
  Assert.AreEqual(Ord(TDynLightToken.SecondaryOffset), Ord(TDynLightTokens.Classify('SECONDARYOFFSET')));
  Assert.AreEqual(Ord(TDynLightToken.Unknown), Ord(TDynLightTokens.Classify('FLICKERLIGHT3')));
  Assert.AreEqual(Ord(TDynLightToken.Unknown), Ord(TDynLightTokens.Classify('color')),
    'the word has to be in upper case');
end;

procedure TTestDynLightsBehavior.TestRegistryPutsTheNameInUpperCaseAndCutsIt;
var
  LLight: TDynLightDefinition;
begin
  LLight := Default(TDynLightDefinition);
  LLight.Name := 'abcdefghijklmnopqrstuvwxyz0123456789';
  Assert.AreEqual(0, FRegistry.Add(LLight));
  Assert.AreEqual('ABCDEFGHIJKLMNOPQRSTUVWXYZ012345', FRegistry.Get(0).Name);
end;

procedure TTestDynLightsBehavior.TestRegistryFindsTheLastLightOfAName;
var
  LLight: TDynLightDefinition;
begin
  LLight := Default(TDynLightDefinition);
  LLight.Name := 'one';
  FRegistry.Add(LLight);
  FRegistry.Add(LLight);
  Assert.AreEqual(1, FRegistry.Find('ONE'));
  Assert.AreEqual(1, FRegistry.Find('one'));
  Assert.AreEqual(-1, FRegistry.Find('two'));
  FRegistry.Clear;
  Assert.AreEqual(0, FRegistry.Count);
end;

procedure TTestDynLightsBehavior.TestRegistryDoesNotFindALongNameThatWasCut;
var
  LLight: TDynLightDefinition;
  LLong: string;
begin
  LLong := StringOfChar('A', 40);
  LLight := Default(TDynLightDefinition);
  LLight.Name := LLong;
  FRegistry.Add(LLight);
  Assert.AreEqual(-1, FRegistry.Find(LLong), 'a defect of the old code, kept');
  Assert.AreEqual(0, FRegistry.Find(StringOfChar('A', 32)));
end;

procedure TTestDynLightsBehavior.TestParserDividesSizeAndOffsetByTheCoefficient;
begin
  NewParser(False, 128).Parse('pointlight L size 64 offset 128 256 -128 object IMP');
  Assert.IsTrue(FRegistry.Get(0).Size1 = 0.5, 'size');
  Assert.IsTrue(FRegistry.Get(0).OffsetX1 = 1, 'offset x');
  Assert.IsTrue(FRegistry.Get(0).OffsetY2 = 2, 'offset y, secondary');
  Assert.IsTrue(FRegistry.Get(0).OffsetZ1 = -1, 'offset z');
end;

procedure TTestDynLightsBehavior.TestParserNeedsItsServices;
var
  LServices: TDynLightParserServices;
begin
  LServices := Default(TDynLightParserServices);
  Assert.WillRaise(
    procedure
    begin
      TDynLightFactory.CreateParser(LServices, nil, 1);
    end, EArgumentNilException);
end;

procedure TTestDynLightsBehavior.TestParserKeepsTheLightThatEndsTheText;
begin
  NewParser(False, 1).Parse('pointlight A color 1 0 0 object IMP');
  Assert.AreEqual(1, FRegistry.Count);
end;

procedure TTestDynLightsBehavior.TestParserLosesTheLightThatEndsTheText;
begin
  NewParser(False, 1).Parse('pointlight A color 1 0 0 pointlight B color 0 1 0');
  Assert.AreEqual(1, FRegistry.Count, 'the last light is added only when a word follows it: a defect, kept');
  Assert.AreEqual('A', FRegistry.Get(0).Name);
end;

procedure TTestDynLightsBehavior.TestParserListsTheTextInDeveloperMode;
begin
  NewParser(True, 1).Parse('a'#13#10'b');
  Assert.AreEqual('--------'#13#10'SC_ParceDynamicLight(): Parsing light definitions'#13#10 +
    '000001: a'#13#10'000002: b'#13#10'--------'#13#10, FLog.Output);
end;

procedure TTestDynLightsBehavior.TestParserDoesNotListTheTextOtherwise;
begin
  NewParser(False, 1).Parse('a'#13#10'b');
  Assert.AreEqual('', FLog.Output);
end;

procedure TTestDynLightsBehavior.TestRandomSeedUsesTheFirstNumberAsTheHighByte;
begin
  NewParser(False, 1).Parse('pointlight A object IMP');
  // the fake gives 11 and then 48
  Assert.AreEqual(11 * 256 + 48, FRegistry.Get(0).RandomSeed);
end;

procedure TTestDynLightsBehavior.TestBinderFallsBackToAllStates;
var
  LBinder: IDynLightBinder;
  LText: string;
begin
  LBinder := TDynLightFactory.CreateBinder(FStatesIntf);
  LBinder.BeginScript;
  // MISL belongs to none of the states of the zombie (object 1): all the states are looked at
  Assert.IsTrue(LBinder.Bind(1, 4, 0, True, 7));
  Assert.IsTrue(FStates.Describe(10, LText));
  Assert.AreEqual(' (1,7)', LText);
  Assert.IsFalse(LBinder.Bind(1, 4, 5, True, 7), 'no such frame');
end;

procedure TTestDynLightsBehavior.TestBinderReplacesTheLightsOfAnObjectOnceForEachText;
var
  LBinder: IDynLightBinder;
  LText: string;
begin
  LBinder := TDynLightFactory.CreateBinder(FStatesIntf);
  LBinder.BeginScript;
  LBinder.Bind(2, 0, 0, True, 1);
  LBinder.Bind(2, 0, 0, True, 2);
  FStates.Describe(3, LText);
  Assert.AreEqual(' (2,1) (2,2)', LText, 'two lights from the same text stay');
  LBinder.BeginScript;
  LBinder.Bind(2, 0, 0, True, 3);
  FStates.Describe(3, LText);
  Assert.AreEqual(' (2,3)', LText,'a new text replaces the lights of the object');
end;

procedure TTestDynLightsBehavior.TestLoaderReadsEachTextOnItsOwn;
var
  LSource: TFakeTextSource;
  LSourceIntf: IDynLightTextSource;
  LFilter: TFakeFilter;
  LFilterIntf: IDynLightTextFilter;
begin
  LSource := TFakeTextSource.Create;
  LSourceIntf := LSource;
  LFilter := TFakeFilter.Create;
  LFilterIntf := LFilter;
  LSource.AddLump('LIGHTDEF', 'pointlight A object IMP');
  LSource.AddLump('LIGHTDEF', 'pointlight B object IMP');
  LSource.AddLump('GLDEFS', 'pointlight C object IMP');
  LSource.AddPak('GLDEFS.txt', 'pointlight D object IMP');
  Assert.IsTrue(TDynLightFactory.CreateLoader(LSourceIntf, LFilterIntf, NewParser(False, 1)).Load(True));
  Assert.AreEqual(4, FRegistry.Count);
  Assert.AreEqual(4, LFilter.Calls, 'one call for each text');
  Assert.AreEqual('A', FRegistry.Get(0).Name);
  Assert.AreEqual('D', FRegistry.Get(3).Name);
end;

procedure TTestDynLightsBehavior.TestLoaderSaysIfThereWasAnyLump;
var
  LSource: TFakeTextSource;
  LSourceIntf: IDynLightTextSource;
  LLoader: IDynLightLoader;
begin
  LSource := TFakeTextSource.Create;
  LSourceIntf := LSource;
  LLoader := TDynLightFactory.CreateLoader(LSourceIntf, nil, NewParser(False, 1));
  Assert.IsFalse(LLoader.Load(True), 'nothing');
  LSource.AddLump('GLDEFS', '');
  Assert.IsFalse(LLoader.Load(False), 'GLDEFS is not read');
  Assert.IsTrue(LLoader.Load(True), 'an empty lump counts');
end;

procedure TTestDynLightsBehavior.TestAnimatorKeepsPointLightsStill;
var
  LAnimator: IDynLightAnimator;
  LFirst: TDynLightRender;
  LSecond: TDynLightRender;
begin
  NewParser(False, 1).Parse('pointlight A color 1 0.5 0 size 10 offset 1 2 3 object IMP');
  LAnimator := TDynLightFactory.CreateAnimator(FRegistry, TFakeRandom.Create);
  LFirst := LAnimator.GetRender(0, 0);
  LSecond := LAnimator.GetRender(0, 500);
  Assert.IsTrue(LFirst.R = 1, 'red');
  Assert.IsTrue(LFirst.Radius = 10, 'radius');
  Assert.IsTrue(LFirst.Z = 3, 'offset z');
  Assert.IsFalse(LFirst.Shadow);
  Assert.IsTrue(LFirst.Radius = LSecond.Radius, 'the radius does not change');
  Assert.IsTrue(LFirst.Y = LSecond.Y, 'the offset does not change');
end;

procedure TTestDynLightsBehavior.TestAnimatorNeedsItsCollaborators;
begin
  Assert.WillRaise(
    procedure
    begin
      TDynLightFactory.CreateAnimator(nil, nil);
    end, EArgumentNilException);
end;

procedure TTestDynLightsBehavior.TestAnimatorResetStartsFromScratch;
var
  LAnimator: IDynLightAnimator;
  LRender: TDynLightRender;
begin
  NewParser(False, 1).Parse('pointlight A color 1 0 0 size 10 object IMP');
  LAnimator := TDynLightFactory.CreateAnimator(FRegistry, TFakeRandom.Create);
  LAnimator.GetRender(0, 0);
  FRegistry.Clear;
  NewParser(False, 1).Parse('pointlight B color 0 0 1 size 20 object IMP');
  LAnimator.Reset;
  LRender := LAnimator.GetRender(0, 1);
  Assert.IsTrue(LRender.B = 1, 'the color of the new light');
  Assert.IsTrue(LRender.Radius = 20, 'the radius of the new light');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDynLightsBehavior);

end.
