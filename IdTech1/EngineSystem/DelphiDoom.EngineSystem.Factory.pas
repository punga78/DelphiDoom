{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the factory: the composition root       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.Factory;

interface

uses
  System.SysUtils, DelphiDoom.CommandLine.Intf, DelphiDoom.Logging.Intf,
  DelphiDoom.EngineSystem.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the library</summary>
  TEngineSystemFactory = class
  public
    /// <summary>The options of the network game, from the command line</summary>
    class function CreateNetCommandLineReader(const ACommandLine: ICommandLine;
      const ALog: ILog): INetCommandLineReader; static;
    /// <summary>The legacy MIDI player, on the MCI sequencer and a hidden window of Windows</summary>
    class function CreateLegacyMidiPlayer(const ALog: ILog): ILegacyMidiPlayer; overload; static;
    /// <summary>The legacy MIDI player on a sequencer and a window that the caller chooses (the tests)</summary>
    class function CreateLegacyMidiPlayer(const ASequencer: IMciSequencer;
      const AWindows: IMidiNotifyWindow; const ALog: ILog): ILegacyMidiPlayer; overload; static;
    /// <summary>The tracker music, on the MikMod client that TMikModProvider keeps</summary>
    class function CreateModuleMusicPlayer(const ALog: ILog;
      const AWindow: TFunc<NativeUInt>): IModuleMusicPlayer; static;
    /// <summary>The shutdown that runs the steps of the plan and then calls ATerminate</summary>
    class function CreateShutdownSequence(const APlan: IShutdownPlan; const ALog: ILog;
      const ATerminate: TProc<Integer>): IShutdownSequence; static;
    /// <summary>The handler of the fatal errors, on the steps that the engine gives</summary>
    class function CreateFatalErrorHandler(
      const ASteps: IFatalErrorSteps): IFatalErrorHandler; static;
  end;

implementation

uses
  DelphiDoom.EngineSystem.NetCommandLineReader, DelphiDoom.EngineSystem.LegacyMidiPlayer,
  DelphiDoom.EngineSystem.WindowsMciSequencer, DelphiDoom.EngineSystem.WindowsMidiNotifyWindow,
  DelphiDoom.EngineSystem.ModuleMusicPlayer, DelphiDoom.EngineSystem.MikModProviderSource,
  DelphiDoom.EngineSystem.ShutdownSequence, DelphiDoom.EngineSystem.FatalErrorHandler;

{ TEngineSystemFactory }

class function TEngineSystemFactory.CreateNetCommandLineReader(const ACommandLine: ICommandLine;
  const ALog: ILog): INetCommandLineReader;
begin
  Result := TNetCommandLineReader.Create(ACommandLine, ALog);
end;

class function TEngineSystemFactory.CreateLegacyMidiPlayer(const ALog: ILog): ILegacyMidiPlayer;
begin
  Result := TLegacyMidiPlayer.Create(TWindowsMciSequencer.Create, TWindowsMidiNotifyWindow.Create,
    ALog);
end;

class function TEngineSystemFactory.CreateLegacyMidiPlayer(const ASequencer: IMciSequencer;
  const AWindows: IMidiNotifyWindow; const ALog: ILog): ILegacyMidiPlayer;
begin
  Result := TLegacyMidiPlayer.Create(ASequencer, AWindows, ALog);
end;

class function TEngineSystemFactory.CreateModuleMusicPlayer(const ALog: ILog;
  const AWindow: TFunc<NativeUInt>): IModuleMusicPlayer;
begin
  Result := TModuleMusicPlayer.Create(TMikModProviderSource.Create, ALog, AWindow);
end;

class function TEngineSystemFactory.CreateShutdownSequence(const APlan: IShutdownPlan;
  const ALog: ILog; const ATerminate: TProc<Integer>): IShutdownSequence;
begin
  Result := TShutdownSequence.Create(APlan, ALog, ATerminate);
end;

class function TEngineSystemFactory.CreateFatalErrorHandler(
  const ASteps: IFatalErrorSteps): IFatalErrorHandler;
begin
  Result := TFatalErrorHandler.Create(ASteps);
end;

end.
