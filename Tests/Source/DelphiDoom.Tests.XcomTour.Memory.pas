{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - the game composed as the program composes it gives      }
{  back the memory it takes (issue #176)                                       }
{                                                                              }
{  This program is free software; you can redistribute it and/or               }
{  modify it under the terms of the GNU General Public License                 }
{  as published by the Free Software Foundation; either version 2              }
{  of the License, or (at your option) any later version.                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomTour.Memory;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   Leaks found playing in Xcom32 (-leaks): a shade object for every shaded blit, the settings of a saved game
  ///   made in the call of a const interface parameter, the cycle of the anonymous methods of the composition
  ///   root. Each test does the same thing twice and compares the blocks that are left (TXcomMemoryCount): the
  ///   first time fills the caches, the second must leave nothing more
  /// </summary>
  [TestFixture]
  [Category('xcomtour')]
  TTestXcomTourMemory = class
  strict private
    function BlocksAfter(const AAction: TProc): Integer;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure UnaCopiaConOmbraNonDovrebbeLasciareMemoria;
    [Test]
    procedure UnaPartitaNuovaChiusaNonDovrebbeLasciareMemoria;
    [Test]
    procedure UnSalvataggioCaricatoESalvatoNonDovrebbeLasciareMemoria;
    [Test]
    procedure UnaMissioneFinoAlGeoscapeNonDovrebbeLasciareMemoria;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Shade, DelphiDoom.XcomSurface.Types,
  DelphiDoom.XcomEngine.Types, DelphiDoom.Xcom.MemoryCount, DelphiDoom.Tests.XcomTour.World;

procedure TTestXcomTourMemory.Setup;
begin
  TXcomMemoryCount.Install;
end;

function TTestXcomTourMemory.BlocksAfter(const AAction: TProc): Integer;
begin
  AAction;
  Result := TXcomMemoryCount.Blocks;
end;

procedure TTestXcomTourMemory.UnaCopiaConOmbraNonDovrebbeLasciareMemoria;
var
  LSource, LTarget: TXcomSurface;
  LBefore: Integer;
  LIndex: Integer;
begin
  LSource := TXcomSurface.Create(32, 40);
  LTarget := TXcomSurface.Create(64, 64);
  try
    // the first blit may make what is made once
    TXcomSurfaceShader.Blit(LSource, LTarget, 0, 0, 3);
    TXcomSurfaceShader.Blit(LSource, LTarget, 0, 0, 3, False, 5);
    LBefore := TXcomMemoryCount.Blocks;
    for LIndex := 1 to 100 do
    begin
      TXcomSurfaceShader.Blit(LSource, LTarget, LIndex mod 8, 0, 3);
      TXcomSurfaceShader.Blit(LSource, LTarget, 0, LIndex mod 8, 3, True, 5);
      TXcomSurfaceShader.Blit(LSource, LTarget, 0, 0, 3, TXcomGraphSubset.Make(0, 16, 0, 16));
    end;
    Assert.AreEqual(LBefore, TXcomMemoryCount.Blocks, 'una copia con ombra non alloca nulla che resti');
  finally
    LTarget.Free;
    LSource.Free;
  end;
end;

procedure TTestXcomTourMemory.UnaPartitaNuovaChiusaNonDovrebbeLasciareMemoria;
var
  LRun: TProc;
  LFirst: Integer;
begin
  LRun :=
    procedure
    var
      LWorld: TXcomTourWorld;
    begin
      LWorld := TXcomTourWorld.Create;
      try
        if LWorld.HasData then
          LWorld.StartNewGame;
      finally
        LWorld.Free;
      end;
    end;
  LFirst := BlocksAfter(LRun);
  Assert.AreEqual(LFirst, BlocksAfter(LRun), 'la seconda partita nuova non lascia blocchi in piu''');
end;

procedure TTestXcomTourMemory.UnSalvataggioCaricatoESalvatoNonDovrebbeLasciareMemoria;
var
  LRun: TProc;
  LFirst: Integer;
begin
  LRun :=
    procedure
    var
      LWorld: TXcomTourWorld;
    begin
      LWorld := TXcomTourWorld.Create;
      try
        if LWorld.HasData and LWorld.LoadVariant('save02_dogfight') then
        begin
          // Options, Save Game, the new saved game, its name
          LWorld.Click(TOUR_GEO_BUTTON_X, TOUR_OPTIONS_Y);
          LWorld.Click(256, 166);
          LWorld.Click(107, 93);
          LWorld.TypeText('m');
          LWorld.Key(XCOM_KEY_RETURN);
          LWorld.Wait(1000);
        end;
      finally
        LWorld.Free;
      end;
    end;
  LFirst := BlocksAfter(LRun);
  Assert.AreEqual(LFirst, BlocksAfter(LRun), 'caricare e salvare una seconda volta non lascia blocchi in piu''');
end;

procedure TTestXcomTourMemory.UnaMissioneFinoAlGeoscapeNonDovrebbeLasciareMemoria;
var
  LRun: TProc;
  LFirst: Integer;
begin
  LRun :=
    procedure
    var
      LWorld: TXcomTourWorld;
    begin
      LWorld := TXcomTourWorld.Create;
      try
        if LWorld.HasData and LWorld.LoadMission('crash') then
        begin
          // Begin Mission? Yes, the briefing, the inventory, the first turn: the map is drawn for a while
          LWorld.Wait(500);
          LWorld.Click(160, 320);
          LWorld.Click(320, 345);
          LWorld.Click(508, 22);
          LWorld.Wait(500);
          LWorld.Key(XCOM_KEY_RETURN);
          LWorld.Wait(1500);
          // the mission is abandoned: the debriefing and the geoscape again
          LWorld.Click(512, 336);
          LWorld.Click(150, 235);
          LWorld.Wait(1500);
          LWorld.Click(72, 372);
          LWorld.Wait(1500);
        end;
      finally
        LWorld.Free;
      end;
    end;
  LFirst := BlocksAfter(LRun);
  Assert.AreEqual(LFirst, BlocksAfter(LRun), 'la seconda missione non lascia blocchi in piu''');
end;

end.
