{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the id Tech library - the engine and its factory       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.IdTech.Engine;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.IdTech.Types, DelphiDoom.IdTech.Intf;

type
  [TestFixture]
  [Category('idtech')]
  TTestIdTechEngine = class(TObject)
  public
    [Test]
    procedure TestEngineAnswersWhatItWasGiven;
    [Test]
    procedure TestDisplayName;
    [Test]
    procedure TestSourcePortIsTrimmedAndMustNotBeEmpty;
    [Test]
    procedure TestFactoryMakesDelphiDoomAnIdTech1Engine;
    [Test]
    procedure TestFactoryRefusesBadVersionNumbers;
    [Test]
    procedure TestACodeThatReceivesTheEngineDoesNotKnowTheClass;
    [Test]
    procedure TestAFakeEngineCanReplaceIt;
  end;

implementation

uses
  DelphiDoom.IdTech.Factory;

type
  /// <summary>A consumer: builds the first line of a configuration file from what it is given</summary>
  TConfigHeader = class
  private
    FEngine: IIdTechEngine;
  public
    constructor Create(const AEngine: IIdTechEngine);
    function Line: string;
  end;

  /// <summary>A fake engine for the tests of the consumers</summary>
  TFakeEngine = class(TInterfacedObject, IIdTechEngine)
  public
    function GetGeneration: TIdTechGeneration;
    function GetSourcePort: string;
    function GetVersion: TIdTechVersion;
    function GetName: string;
    function GetDisplayName: string;
  end;

{ TConfigHeader }

constructor TConfigHeader.Create(const AEngine: IIdTechEngine);
begin
  inherited Create;
  FEngine := AEngine;
end;

function TConfigHeader.Line: string;
begin
  Result := '[' + FEngine.SourcePort + ' ver ' + FEngine.Version.ToString + ']';
end;

{ TFakeEngine }

function TFakeEngine.GetGeneration: TIdTechGeneration;
begin
  Result := TIdTechGeneration.IdTech3;
end;

function TFakeEngine.GetSourcePort: string;
begin
  Result := 'Fake';
end;

function TFakeEngine.GetVersion: TIdTechVersion;
begin
  Result := TIdTechVersion.Create(9, 5);
end;

function TFakeEngine.GetName: string;
begin
  Result := 'fake name';
end;

function TFakeEngine.GetDisplayName: string;
begin
  Result := 'fake display';
end;

{ TTestIdTechEngine }

procedure TTestIdTechEngine.TestEngineAnswersWhatItWasGiven;
var
  LEngine: IIdTechEngine;
begin
  LEngine := TIdTechFactory.CreateEngine(TIdTechGeneration.IdTech2, 'Quake2',
    TIdTechVersion.Create(3, 20));
  Assert.AreEqual(Ord(TIdTechGeneration.IdTech2), Ord(LEngine.Generation));
  Assert.AreEqual('Quake2', LEngine.SourcePort);
  Assert.AreEqual('3.20', LEngine.Version.ToString);
  Assert.AreEqual('id Tech 2', LEngine.Name);
end;

procedure TTestIdTechEngine.TestDisplayName;
begin
  Assert.AreEqual('DelphiDoom 2.07 (id Tech 1)', TIdTechFactory.CreateDelphiDoom(207).DisplayName);
  Assert.AreEqual('Port 1.10 (id Tech 3)',
    TIdTechFactory.CreateEngine(TIdTechGeneration.IdTech3, 'Port', TIdTechVersion.FromNumber(110)).DisplayName);
end;

procedure TTestIdTechEngine.TestSourcePortIsTrimmedAndMustNotBeEmpty;
begin
  Assert.AreEqual('Port', TIdTechFactory.CreateEngine(TIdTechGeneration.IdTech1, '  Port ',
    TIdTechVersion.FromNumber(1)).SourcePort);
  Assert.WillRaise(procedure begin
    TIdTechFactory.CreateEngine(TIdTechGeneration.IdTech1, '', TIdTechVersion.FromNumber(1)); end,
    EIdTechException);
  Assert.WillRaise(procedure begin
    TIdTechFactory.CreateEngine(TIdTechGeneration.IdTech1, '   ', TIdTechVersion.FromNumber(1)); end,
    EIdTechException);
end;

procedure TTestIdTechEngine.TestFactoryMakesDelphiDoomAnIdTech1Engine;
var
  LEngine: IIdTechEngine;
begin
  LEngine := TIdTechFactory.CreateDelphiDoom(207);
  Assert.AreEqual(Ord(TIdTechGeneration.IdTech1), Ord(LEngine.Generation));
  Assert.AreEqual('DelphiDoom', LEngine.SourcePort);
  Assert.AreEqual(207, LEngine.Version.Number);
end;

procedure TTestIdTechEngine.TestFactoryRefusesBadVersionNumbers;
begin
  Assert.WillRaise(procedure begin TIdTechFactory.CreateDelphiDoom(-207); end, EIdTechException);
end;

procedure TTestIdTechEngine.TestACodeThatReceivesTheEngineDoesNotKnowTheClass;
var
  LHeader: TConfigHeader;
begin
  LHeader := TConfigHeader.Create(TIdTechFactory.CreateDelphiDoom(207));
  try
    Assert.AreEqual('[DelphiDoom ver 2.07]', LHeader.Line);
  finally
    LHeader.Free;
  end;
end;

procedure TTestIdTechEngine.TestAFakeEngineCanReplaceIt;
var
  LHeader: TConfigHeader;
begin
  LHeader := TConfigHeader.Create(TFakeEngine.Create);
  try
    Assert.AreEqual('[Fake ver 9.05]', LHeader.Line);
  finally
    LHeader.Free;
  end;
end;

end.
