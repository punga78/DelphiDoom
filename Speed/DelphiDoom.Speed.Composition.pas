{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed32 - the composition root                                  }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.Composition;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.GameData.Intf, DelphiDoom.Speed.Types,
  DelphiDoom.Speed.Intf, DelphiDoom.Speed.RaceSimulation;

type
  /// <summary>
  ///   The one place of Speed32 that knows the classes behind the interfaces: the translator of the game
  ///   (Libs\Speed), the racing (Libs\Racing) and the log. It does not touch ComposeEngine nor
  ///   TIdTechGeneration: the engine of Speed (id Tech 1) is the S5 of the issue 168, not this program
  /// </summary>
  TSpeedComposition = class
  public
    /// <summary>A log that writes on the console</summary>
    class function CreateConsoleLog: ILog; static;
    /// <summary>
    ///   The data of the game, as the WAD that the engine would load: SPEEDH.JCL translated in memory.
    ///   APakEntries gets the models (MODELS\x.I3D) that the engine reads from the container
    /// </summary>
    class function TranslateGame(const AJclPath: string; const ALog: ILog;
      out APakEntries: TArray<TSpeedPakEntry>): IGameWadComposer; static;
    /// <summary>A race of the computer on a level of the translated WAD</summary>
    class function CreateRaceSimulation(const AWad: IGameWadComposer): TSpeedRaceSimulation; static;
  end;

implementation

uses
  DelphiDoom.MathCore.Factory, DelphiDoom.Logging.Factory, DelphiDoom.GameData.Factory,
  DelphiDoom.Speed.Factory, DelphiDoom.Speed.Sim.LogSink;

{ TSpeedComposition }

class function TSpeedComposition.CreateConsoleLog: ILog;
begin
  Result := TLogFactory.CreateLog([TSpeedConsoleLogSink.Create], nil);
end;

class function TSpeedComposition.TranslateGame(const AJclPath: string; const ALog: ILog;
  out APakEntries: TArray<TSpeedPakEntry>): IGameWadComposer;
begin
  Result := TGameDataFactory.CreateWadComposer;
  APakEntries := TSpeedFactory.CreateTranslator(ALog).Translate(TSpeedFactory.OpenContainer(AJclPath), Result);
end;

class function TSpeedComposition.CreateRaceSimulation(const AWad: IGameWadComposer): TSpeedRaceSimulation;
begin
  Result := TSpeedRaceSimulation.Create(AWad, TMathCoreFactory.CreateGameRandom);
end;

end.
