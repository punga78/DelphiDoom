{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the cost of a frame of the map        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.MapUiBench;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework;

type
  /// <summary>
  ///   The cost of a frame of the map with 400 units and the fog off (the whole map of 64 x 64 tiles is drawn), measured as
  ///   Tools\Verifica\197\war_frame_ref.c measures the C ("fog off", "spawn 400", "time N"): the same units on the same
  ///   tiles. The test always runs a few frames (so that 400 units and the fog off do not crash); the numbers are written
  ///   when the variable DELPHIDOOM_WAR_BENCH_OUT is a file (minimum, median and mean in microseconds, for the whole frame
  ///   and for the drawing only), to compare with the C built with -O1 and -O2
  /// </summary>
  [TestFixture]
  [Category('war')]
  TTestWarMapUiBench = class(TObject)
  public
    [Test]
    procedure DovrebbeDisegnareLaMappaConQuattrocentoUnitaESenzaNebbia;
  end;

implementation

uses
  System.Diagnostics, DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Model.Types,
  DelphiDoom.War.Ui.Game, DelphiDoom.War.Ui.ScriptRunner, DelphiDoom.War.MapUi.Scene, DelphiDoom.Tests.War.RealData,
  DelphiDoom.War.Campaign.Intf, DelphiDoom.War.Campaign.Catalog, DelphiDoom.Tests.War.UiRig;

{ TTestWarMapUiBench }

procedure TTestWarMapUiBench.DovrebbeDisegnareLaMappaConQuattrocentoUnitaESenzaNebbia;
var
  LGame: TWarUiGame;
  LScene: TWarMapScene;
  LIndex: Integer;
  LX: Integer;
  LY: Integer;
  LSlot: Integer;
  LDelta: Single;
  LStopwatch: TStopwatch;
  LTimes: TList<Double>;
  LOutput: TStringList;
  LTarget: string;
  LRender: Boolean;
  LCampaigns: IWarCampaigns;
  LMapType: Integer;

  function Summary(const AName: string; ARenderOnly: Boolean): string;
  var
    LFrame: Integer;
    LSum: Double;
    LSorted: TArray<Double>;
  begin
    LTimes.Clear;
    for LFrame := 1 to 200 do
    begin
      LStopwatch := TStopwatch.StartNew;
      LGame.Manager.BeginFrame(LDelta);
      if not ARenderOnly then
        LGame.Manager.UpdateGame;
      LGame.Manager.RenderGame;
      LGame.Manager.EndFrame;
      LStopwatch.Stop;
      LTimes.Add(LStopwatch.Elapsed.TotalMilliseconds * 1000);
      LGame.Manager.BeginInputFrame;
    end;
    LSorted := LTimes.ToArray;
    TArray.Sort<Double>(LSorted);
    LSum := 0;
    for LFrame := 0 to High(LSorted) do
      LSum := LSum + LSorted[LFrame];
    Result := Format('TIME %s 200 min %.1f median %.1f mean %.1f', [AName, LSorted[0], LSorted[High(LSorted) div 2],
      LSum / Length(LSorted)], TFormatSettings.Invariant);
  end;

begin
  TWarRealData.RequireDataWar;
  LGame := TWarUiRig.CreateRealMapGame;
  LTimes := TList<Double>.Create;
  LOutput := TStringList.Create;
  try
    LDelta := Single(1) / Single(60);
    LGame.Input.SetPosition(190, 100);
    LCampaigns := TWarCampaigns.Create;
    Assert.IsTrue(LCampaigns.TryGetMapType(wraHumans, 1, LMapType), 'La prima missione degli umani');
    LGame.Manager.SetNextCampaignMap(LMapType, 0);
    LGame.Manager.RunFrame(LDelta);
    LGame.Manager.BeginInputFrame;
    LScene := LGame.Manager.Scene as TWarMapScene;
    Assert.IsNotNull(LScene);
    // the same as "fog off" and "spawn 400" of the harness of the C
    LScene.Map.Fog.Enabled := False;
    for LIndex := 0 to 399 do
    begin
      LX := 1 + (LIndex * 3) mod 62;
      LY := 1 + (((LIndex * 3) div 62) * 3) mod 62;
      LSlot := LScene.Binding.World.Entities.CreateUnit(WAR_UNIT_FOOTMAN, LX, LY, 0, wrkNone, 0, True);
      Assert.AreNotEqual(0, LSlot, 'La riserva delle entita'' e'' piena');
      LScene.Binding.World.Entities.SetInitialIdle(LSlot);
    end;
    LTarget := GetEnvironmentVariable('DELPHIDOOM_WAR_BENCH_OUT');
    LRender := LTarget <> '';
    LGame.Manager.RunFrame(LDelta);
    LGame.Manager.BeginInputFrame;
    if LRender then
    begin
      LOutput.Add(Summary('time', False));
      LOutput.Add(Summary('timerender', True));
      LOutput.SaveToFile(LTarget);
    end
    else
      for LIndex := 1 to 3 do
      begin
        LGame.Manager.RunFrame(LDelta);
        LGame.Manager.BeginInputFrame;
      end;
    // the frames ran: the 400 units are in the pool next to the ones of the level
    Assert.IsTrue(LScene.Binding.World.Context.Pool.OfType[WAR_ENTITY_UNIT].Count >= 400, 'Le unita'' ci sono');
  finally
    LOutput.Free;
    LTimes.Free;
    LGame.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarMapUiBench);

end.
