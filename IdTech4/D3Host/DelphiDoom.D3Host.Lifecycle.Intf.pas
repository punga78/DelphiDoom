{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 host library - contracts of the life cycle               }
{                                                                              }
{  Port of Doom 3 (id Software): what framework\Common.cpp (Init, Shutdown,    }
{  InitGame, ShutdownGame, Frame, GUIFrame, SingleAsyncTic, Async) calls on    }
{  the systems of the engine.                                                  }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Host.Lifecycle.Intf;

interface

uses
  DelphiDoom.D3Host.Types, DelphiDoom.D3Host.Intf;

type
  /// <summary>A system that is started and stopped by the life cycle (the cmd system, the cvar system, the declarations...)</summary>
  ID3Subsystem = interface
    ['{4E1D7A93-B260-4C58-9F0A-D83E51C2B764}']
    procedure Init;
    procedure Shutdown;
  end;

  /// <summary>The console as the life cycle uses it (the graphics are loaded by the renderer, not here)</summary>
  ID3ConsoleControl = interface
    ['{A83C5F20-9D14-4E67-B1A9-0C72E4D6F385}']
    procedure Init;
    procedure Shutdown;
    procedure ClearNotifyLines;
  end;

  /// <summary>The part of the session that the life cycle calls (UpdateScreen is ID3ScreenUpdater)</summary>
  ID3SessionLifecycle = interface
    ['{17B96E4D-C3A0-4852-8F1E-5D20A7B3C949}']
    procedure Init;
    procedure Shutdown;
    procedure Frame;
    procedure GuiFrameEvents;
    procedure StartMenu(const APlayIntro: Boolean);
    procedure WriteCDKey;
  end;

  /// <summary>The sound system as the life cycle uses it</summary>
  ID3SoundSystem = interface
    ['{D0482B7E-61F5-4A93-A8C6-3E9B17F0D254}']
    procedure Init;
    procedure Shutdown;
    procedure ClearBuffer;
    /// <summary>soundSystem->GetPlayingSoundWorld() is not NULL</summary>
    function HasPlayingSoundWorld: Boolean;
    /// <summary>The StopAllSounds of the playing sound world</summary>
    procedure StopAllSounds;
    procedure AsyncUpdate(const ATime: Integer);
    procedure AsyncUpdateWrite(const ATime: Integer);
  end;

  /// <summary>idAsyncNetwork as the life cycle uses it</summary>
  ID3AsyncNetwork = interface
    ['{6C9E0D35-F2B8-4A71-93D4-B58A06E1C7F2}']
    procedure Init;
    procedure Shutdown;
    procedure RunFrame;
    function IsActive: Boolean;
    /// <summary>net_serverDedicated.GetInteger: 0 no, 1 dedicated</summary>
    function ServerDedicated: Integer;
    procedure KillServer;
    procedure ShutdownClient;
    procedure InitServerPort;
  end;

  /// <summary>The file system as the life cycle uses it (reading and writing are ID3CommonFileSystem)</summary>
  ID3FileSystemSetup = interface
    ['{83A5F1C7-2E09-4D46-B7B8-9C14D6E0A532}']
    procedure Init;
    procedure Shutdown(const AReloading: Boolean);
    /// <summary>OpenExplicitFileRead; nil if there is no such file</summary>
    function OpenExplicitFileRead(const AOSPath: AnsiString): ID3CommonFile;
    function RelativePathToOSPath(const ARelativePath, ABasePath: AnsiString): AnsiString;
  end;

  /// <summary>The event loop as the life cycle uses it</summary>
  ID3EventLoopControl = interface
    ['{F5B2C84A-0D71-4E39-A6C8-17E93B50D2A4}']
    procedure Init;
    procedure Shutdown;
    function RunEventLoop(const ACommandExecution: Boolean): Integer;
  end;

  /// <summary>The Sys_* calls of the life cycle, and the leak test of the memory</summary>
  ID3SystemLifecycle = interface
    ['{2A60D9E3-B4C1-4F85-8D17-E3F90A5B6C48}']
    procedure Init;
    procedure InitNetworking;
    function AlreadyRunning: Boolean;
    procedure Shutdown;
    procedure DoPreferences;
    procedure GenerateEvents;
    procedure EnterCriticalSection;
    procedure LeaveCriticalSection;
    function FPUStackIsEmpty: Boolean;
    function FPUState: AnsiString;
    procedure EnableLeakTest(const AName: AnsiString);
  end;

  /// <summary>The command line of idCommonLocal (TD3CommandLine implements it)</summary>
  ID3CommandLineControl = interface
    ['{93E7B1D6-4A02-4C58-A9F3-60D5C28E1B47}']
    procedure ParseCommandLine(const AArguments: TArray<AnsiString>);
    procedure ClearCommandLine;
    function SafeMode: Boolean;
    procedure CheckToolMode;
    procedure StartupVariable(const AMatch: AnsiString; const AOnce: Boolean);
    procedure StartupAllVariables(const AOnce: Boolean);
    function AddStartupCommands: Boolean;
  end;

  /// <summary>The warnings of idCommonLocal: the ones that the life cycle prints or clears</summary>
  ID3WarningControl = interface
    ['{0B8F6A42-D175-4E93-B2C0-84A7E91D3F65}']
    procedure ClearWarnings(const AReason: AnsiString);
    procedure PrintWarnings;
    /// <summary>warningCaption.Clear() and errorList.Clear(), as Shutdown does</summary>
    procedure ClearCaptionAndErrors;
  end;

  /// <summary>CloseLogFile of idCommonLocal</summary>
  ID3LogFileControl = interface
    ['{C41A8D07-6E93-4B52-AF18-72D0B5E3C964}']
    procedure CloseLogFile;
  end;

  /// <summary>
  ///   What idCommonLocal::Init and InitGame do that is not ported: the SIMD, the registration of the commands, the
  ///   language dictionary, the renderer start, the game module, the machine spec and the loading messages
  /// </summary>
  ID3StartupSteps = interface
    ['{5D2E93B8-A0C7-4F14-8B61-E9C3F7A04D25}']
    procedure InitSIMD;
    /// <summary>idCVar::RegisterStaticVars: the cvars that the classes of the engine declare</summary>
    procedure RegisterStaticVars;
    procedure InitCommands;
    procedure InitLanguageDict;
    procedure InitRenderSystem;
    procedure LoadGameDLL;
    procedure UnloadGameDLL;
    procedure SetMachineSpec;
    /// <summary>Com_ExecMachineSpec_f</summary>
    procedure ExecMachineSpec;
    /// <summary>PrintLoadingMessage: the text is already looked up in the language dictionary</summary>
    procedure PrintLoadingMessage(const AText: AnsiString);
  end;

  /// <summary>What idCommonLocal::Frame does that is not ported: the writing of the configuration and the SIMD switch</summary>
  ID3FrameSteps = interface
    ['{E8C03F57-1B96-4A24-9D7E-C5A1062B8F39}']
    procedure WriteConfiguration;
    /// <summary>com_forceGenericSIMD.IsModified</summary>
    function IsSIMDModified: Boolean;
    procedure InitSIMD;
  end;

implementation

end.
