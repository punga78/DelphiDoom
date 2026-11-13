{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - contracts                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.Intf;

// Small contracts between the classes of the library and the engine (or Windows). Every class
// receives what it needs as one of these, so that a test can give it a fake.

interface

uses
  DelphiDoom.EngineSystem.Types, DelphiDoom.Mikmod.Client, DelphiDoom.Net.Types;

type
  /// <summary>Reads what the command line says about the network game</summary>
  INetCommandLineReader = interface
    ['{7B2E4F1A-93C6-4D58-A0E7-5C1D8B3F6A92}']
    /// <summary>
    ///   Reads -dup, -extratic, -port, -left, -right, -back and -net; writes the lines that the old
    ///   code printed to the log. APreviousPort is the port when -port is missing
    /// </summary>
    function Read(APreviousPort: Integer): TNetCommandLineOptions;
  end;

  /// <summary>The sequencer of Windows (MCI) that plays a MIDI file, command by command</summary>
  IMciSequencer = interface
    ['{2D8A6E53-1B94-4F70-8C2A-E3F5A7091B46}']
    /// <summary>Opens the file on the sequencer; 0 or an MCI error code. ADeviceId is set only on success</summary>
    function Open(const AFileName: string; out ADeviceId: Cardinal): Cardinal;
    /// <summary>Asks if the output port is the MIDI mapper; 0 or an MCI error code</summary>
    function QueryMapperPort(ADeviceId: Cardinal; out AIsMapper: Boolean): Cardinal;
    /// <summary>Starts to play; ANotifyWindow is told when the song ends</summary>
    function Play(ADeviceId: Cardinal; ANotifyWindow: NativeUInt): Cardinal;
    /// <summary>Goes back to the start of the song; ANotifyWindow is told when it is done</summary>
    function SeekToStart(ADeviceId: Cardinal; ANotifyWindow: NativeUInt): Cardinal;
    procedure Stop(ADeviceId: Cardinal);
    procedure Close(ADeviceId: Cardinal);
    procedure Pause(ADeviceId: Cardinal);
    procedure Resume(ADeviceId: Cardinal);
  end;

  /// <summary>Called when the sequencer says that a song ended (or did not: ASuccessful)</summary>
  TMidiNotifyEvent = procedure(ASuccessful: Boolean) of object;

  /// <summary>The hidden window that receives the notifications of the sequencer</summary>
  IMidiNotifyWindow = interface
    ['{9C4B1E72-6A38-4D05-B2F9-0E7A5C3D8164}']
    /// <summary>Makes the window; 0 if it could not be made. AOnNotify is called for every song that ends</summary>
    function Open(const AOnNotify: TMidiNotifyEvent): NativeUInt;
    /// <summary>Destroys the window: no more notifications</summary>
    procedure Close(AHandle: NativeUInt);
  end;

  /// <summary>The MIDI player of the legacy kind: a play list that the sequencer of Windows goes through</summary>
  ILegacyMidiPlayer = interface
    ['{E1A7C492-5D06-4B83-9F2E-8A0B3D6C7145}']
    procedure Initialize;
    procedure ShutDown;
    procedure AddFile(const AFileName: string);
    procedure ClearPlayList;
    /// <summary>Stops what plays and plays the file at AIndex of the play list</summary>
    procedure Play(AIndex: Integer);
    procedure Stop;
    procedure Pause;
    procedure Resume;
    /// <summary>The volume of the legacy player cannot be changed: nothing happens</summary>
    procedure SetVolume(ALevel: Integer);
    /// <summary>Nothing to do at every tic: the sequencer plays by itself</summary>
    procedure Process;
  end;

  /// <summary>Where the module player gets the MikMod client from, and how it lets it go</summary>
  IMikModClientSource = interface
    ['{4F6D2A81-B7E3-4C95-A108-9D3E5B7F2C60}']
    function Client: TMikModClient;
    procedure Release;
  end;

  /// <summary>The tracker music (MOD, S3M, XM, IT) of the engine</summary>
  IModuleMusicPlayer = interface
    ['{A5E93B17-C264-4D0F-8B71-3F2C6A9D0E58}']
    procedure Initialize;
    procedure ShutDown;
    procedure Play(AData: Pointer; ASize: Integer);
    procedure Pause;
    procedure Resume;
    procedure Stop;
    /// <summary>ALevel is the 0..15 volume of the menu</summary>
    procedure SetVolume(ALevel: Integer);
    /// <summary>Mixes the next block: called at every frame</summary>
    procedure Process;
  end;

  /// <summary>The steps that the engine takes to shut down, in order; the command line can change them</summary>
  IShutdownPlan = interface
    ['{83D1F6A0-4E29-4B7C-95A3-C0E8D2B5741F}']
    /// <summary>The steps from the network to the files, for a program that stops with ACode</summary>
    function Steps(ACode: Integer): TArray<TShutdownStep>;
  end;

  /// <summary>Runs the shutdown of the engine</summary>
  IShutdownSequence = interface
    ['{C7F2845B-0A19-4E63-8D5C-1B6E9A3F07D2}']
    /// <summary>True from the moment the shutdown starts</summary>
    function IsFinished: Boolean;
    /// <summary>Writes what it does to the log, runs the steps of the plan and ends the process</summary>
    procedure Run(ACode: Integer);
  end;

  /// <summary>
  ///   What the handler of the fatal errors asks of the engine, in the order of the old I_Error.
  ///   The state (IsFailing) belongs to the engine: other units read it while the engine shuts down
  /// </summary>
  IFatalErrorSteps = interface
    ['{1E94B7D3-58A0-4C26-9F1D-6D3A0C8E5B72}']
    function IsFailing: Boolean;
    /// <summary>Saves the output that is cached in memory</summary>
    procedure FlashOutput;
    procedure MarkFailing;
    /// <summary>Closes the demo that is being recorded</summary>
    procedure FinishDemo;
    /// <summary>Shows the error: the error file, the message box and the output</summary>
    procedure Report(const AMessage: string);
    /// <summary>The shutdown with the code 1</summary>
    procedure Terminate;
  end;

  /// <summary>The handler of the fatal errors of the engine (I_Error)</summary>
  IFatalErrorHandler = interface
    ['{F2B8A5C0-7D43-4E19-A6E8-0B91D7C34F56}']
    procedure Handle(const AMessage: string);
  end;

  /// <summary>Where the crash report goes: a call that cannot allocate, because the heap may be corrupt</summary>
  ICrashSink = interface
    ['{5C9E0A38-B4D7-4F61-8A25-D1E73F6B9084}']
    procedure Write(AText: PAnsiChar);
  end;

  /// <summary>A crash sink that writes to a file that the crash opens when it comes</summary>
  ICrashFileSink = interface(ICrashSink)
    ['{D08E7A52-39C1-4B64-A5F8-6E21B4C97D30}']
    /// <summary>The handle of the file, open for writing; the owner of the handle closes it</summary>
    procedure SetTarget(AHandle: NativeUInt);
  end;

  /// <summary>What can be read of the memory of the program at the time of the crash</summary>
  ICrashMemory = interface
    ['{B3D61F94-2A7E-4C08-9E53-7F0A8C5D1E26}']
    function IsReadable(AAddress: Cardinal; ASize: Cardinal): Boolean;
    function ReadDWord(AAddress: Cardinal): Cardinal;
  end;

implementation

end.
