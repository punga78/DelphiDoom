{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - music backend of the tracker modules (MOD, S3M, XM, IT) }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Music.ModuleBackend;

interface

uses
  DelphiDoom.Audio.Types,
  DelphiDoom.Engine.Music.BackendBase;

type
  /// <summary>It plays at once when the song is registered, like the old code</summary>
  TModuleMusicBackend = class(TEngineMusicBackendBase)
  public
    procedure Initialize; override;
    procedure Shutdown; override;
    function Register(AData: Pointer; ASize: Integer;
      out AContext: NativeInt): TMusicRegisterResult; override;
    procedure Stop(AContext: NativeInt); override;
    procedure Pause(AContext: NativeInt); override;
    procedure Resume(AContext: NativeInt); override;
    procedure SetVolume(AVolume: Integer); override;
    procedure Process; override;
  end;

implementation

uses
  DelphiDoom.Audio.ModuleDetector,
  i_mikplay,
  s_sound;

{ TModuleMusicBackend }

procedure TModuleMusicBackend.Initialize;
begin
  I_InitMik;
end;

procedure TModuleMusicBackend.Shutdown;
begin
  I_StopMik;
  I_ShutDownMik;
end;

function TModuleMusicBackend.Register(AData: Pointer; ASize: Integer;
  out AContext: NativeInt): TMusicRegisterResult;
begin
  AContext := 0;
  if not TModuleDetector.IsModule(AData, ASize) then
  begin
    Result := TMusicRegisterResult.NotRecognized;
    Exit;
  end;

  I_PlayMik(AData, ASize);
  I_SetMusicVolumeMik(snd_MusicVolume);
  Result := TMusicRegisterResult.Registered;
end;

procedure TModuleMusicBackend.Stop(AContext: NativeInt);
begin
  I_StopMik;
end;

procedure TModuleMusicBackend.Pause(AContext: NativeInt);
begin
  I_PauseMik;
end;

procedure TModuleMusicBackend.Resume(AContext: NativeInt);
begin
  I_ResumeMik;
end;

procedure TModuleMusicBackend.SetVolume(AVolume: Integer);
begin
  I_SetMusicVolumeMik(AVolume);
end;

procedure TModuleMusicBackend.Process;
begin
  I_ProcessMik;
end;

end.
