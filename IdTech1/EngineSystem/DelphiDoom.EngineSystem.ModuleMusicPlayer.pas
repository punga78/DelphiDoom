{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the tracker music player                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.ModuleMusicPlayer;

// Port of i_mikplay.pas (issue #185): MOD, S3M, XM and IT music with the tracker written in
// Pascal. A failure of the sound library is a warning in the log, never an error of the game.

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Mikmod.Intf,
  DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf;

type
  /// <summary>
  ///   Plays a module that is in memory. Nothing works until Initialize succeeds: a machine
  ///   without a sound card plays no module music, and the game goes on
  /// </summary>
  TModuleMusicPlayer = class(TInterfacedObject, IModuleMusicPlayer)
  strict private
    FClients: IMikModClientSource;
    FLog: ILog;
    FWindow: TFunc<NativeUInt>;
    FIsInitialized: Boolean;
  public
    /// <summary>
    ///   AClients gives the MikMod client; AWindow gives the window that DirectSound needs when the
    ///   player starts; EArgumentNilException if one of the three is nil
    /// </summary>
    constructor Create(const AClients: IMikModClientSource; const ALog: ILog;
      const AWindow: TFunc<NativeUInt>);
    procedure Initialize;
    procedure ShutDown;
    procedure Play(AData: Pointer; ASize: Integer);
    procedure Pause;
    procedure Resume;
    procedure Stop;
    procedure SetVolume(ALevel: Integer);
    procedure Process;
    property IsInitialized: Boolean read FIsInitialized;
  end;

const
  /// <summary>The mixing frequency that the tracker opens the device with</summary>
  MODULE_MUSIC_FREQUENCY = 44100;

  /// <summary>The volume of the tracker (0..127) for each level of the menu (0..15)</summary>
  MODULE_MUSIC_VOLUME: array[0..15] of Word = (
      0,     9,     17,    26,
     34,    43,     51,    60,
     68,    77,     85,    94,
    102,   111,    119,   127
  );

implementation

{ TModuleMusicPlayer }

constructor TModuleMusicPlayer.Create(const AClients: IMikModClientSource; const ALog: ILog;
  const AWindow: TFunc<NativeUInt>);
begin
  inherited Create;
  if not Assigned(AClients) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['AClients']);
  if not Assigned(ALog) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ALog']);
  if not Assigned(AWindow) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['AWindow']);
  FClients := AClients;
  FLog := ALog;
  FWindow := AWindow;
end;

procedure TModuleMusicPlayer.Initialize;
begin
  try
    FClients.Client.Initialize(MODULE_MUSIC_FREQUENCY, True, True, True, FWindow(), 0);
    FIsInitialized := True;
  except
    on E: EMikModException do
    begin
      FIsInitialized := False;
      FLog.Warning(Format(SMikModInitWarning, [E.Message]));
    end;
  end;
end;

procedure TModuleMusicPlayer.ShutDown;
begin
  FIsInitialized := False;
  FClients.Release;
end;

procedure TModuleMusicPlayer.Play(AData: Pointer; ASize: Integer);
begin
  if not FIsInitialized then
    Exit;

  // The tracker reads the module from memory: no temporary file
  try
    FClients.Client.LoadFromMemory(AData, ASize);
    FClients.Client.Play(True);
  except
    on E: EMikModException do
      FLog.Warning(Format(SMikModPlayWarning, [E.Message]));
  end;
end;

procedure TModuleMusicPlayer.Pause;
begin
  if not FIsInitialized then
    Exit;

  try
    if not FClients.Client.IsPaused then
      FClients.Client.Pause;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to pause
  end;
end;

procedure TModuleMusicPlayer.Resume;
begin
  if not FIsInitialized then
    Exit;

  try
    if FClients.Client.IsPaused then
      FClients.Client.Resume;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to resume
  end;
end;

procedure TModuleMusicPlayer.Stop;
begin
  if not FIsInitialized then
    Exit;

  try
    FClients.Client.Stop;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to stop
  end;
end;

procedure TModuleMusicPlayer.SetVolume(ALevel: Integer);
var
  LLevel: Integer;
begin
  if not FIsInitialized then
    Exit;

  LLevel := ALevel;
  if LLevel < 1 then
    LLevel := 1
  else if LLevel > 15 then
    LLevel := 15;
  try
    FClients.Client.SetVolume(MODULE_MUSIC_VOLUME[LLevel]);
  except
    on EMikModException do
      ; // Nothing is loaded yet: the volume is set when the music starts
  end;
end;

procedure TModuleMusicPlayer.Process;
begin
  if not FIsInitialized then
    Exit;

  try
    FClients.Client.Update;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to mix
  end;
end;

end.
