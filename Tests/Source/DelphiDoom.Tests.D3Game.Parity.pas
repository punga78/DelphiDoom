{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 game library - parity with the real C++     }
{  (idClass and idTypeInfo of Class.cpp, the entity table of Game_local.cpp,   }
{  the activity of Entity.cpp)                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.D3Game.Parity;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.D3Game.Rig;

type
  /// <summary>
  ///   Every scenario of Tests\Data\D3Game\scenarios runs on the Delphi classes and must write the golden file that
  ///   the real C++ wrote (Tools\Verifica\255\Build-Harness-Game.ps1: the real Class.h, Event.h and the real bodies of
  ///   Class.cpp, Event.cpp, Game_local.cpp and Entity.cpp, cut out of the source, against traced fakes)
  /// </summary>
  [TestFixture]
  [Category('D3Game')]
  TTestD3GameParity = class
  strict private
    FRig: TD3GameRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    [TestCase('TipiGerarchiaENumerazione', 'types')]
    [TestCase('EventiETabelleDegliEventi', 'events')]
    [TestCase('OggettiCreateInstanceECallSpawn', 'objects')]
    [TestCase('GenerazioneDaEntityDefEDaClasse', 'spawn')]
    [TestCase('TabellaDelleEntitaENomi', 'table')]
    [TestCase('EntitaDellaMappaEMapPopulate', 'map')]
    [TestCase('CicloDiThinkEAttivita', 'frame')]
    procedure LoScenarioDovrebbeDareLeRigheDelC(const AScenario: string);
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.D3Game.ClassBase, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.D3Game.Scenario;

procedure TTestD3GameParity.Setup;
begin
  FRig := TD3GameRig.Create;
end;

procedure TTestD3GameParity.TearDown;
begin
  FRig.Free;
end;

procedure TTestD3GameParity.LoScenarioDovrebbeDareLeRigheDelC(const AScenario: string);
var
  LScenario: TStringList;
  LGolden: TStringList;
  LRunner: TD3GameScenarioRunner;
  LTraceFolder: string;
begin
  LScenario := TTestFiles.Lines(TTestFiles.DataFile('D3Game', 'scenarios\' + AScenario + '.scn'));
  LGolden := TTestFiles.Lines(TTestFiles.DataFile('D3Game', 'golden\' + AScenario + '.golden.txt'));
  LRunner := TD3GameScenarioRunner.Create(FRig);
  try
    LRunner.Run(LScenario);
    // DD_D3GAME_TRACE=<folder>: keeps the whole trace of the run, to compare it with the golden by hand
    LTraceFolder := GetEnvironmentVariable('DD_D3GAME_TRACE');
    if LTraceFolder <> '' then
      FRig.World.Trace.SaveToFile(IncludeTrailingPathDelimiter(LTraceFolder) + AScenario + '.trace.txt');
    TTestGolden.AssertSameLines(LGolden, FRig.World.Trace);
  finally
    LRunner.Free;
    LGolden.Free;
    LScenario.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestD3GameParity);

end.
