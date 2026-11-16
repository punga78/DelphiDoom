{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - base of the music backends                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Music.BackendBase;

interface

uses
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf;

type
  /// <summary>
  ///   Every method does nothing, except Register: a backend writes only what its format needs
  /// </summary>
  TEngineMusicBackendBase = class(TInterfacedObject, IMusicBackend)
  public
    procedure Initialize; virtual;
    procedure Shutdown; virtual;
    function Register(AData: Pointer; ASize: Integer;
      out AContext: NativeInt): TMusicRegisterResult; virtual; abstract;
    procedure Play(AContext: NativeInt; ALooping: Boolean); virtual;
    procedure Stop(AContext: NativeInt); virtual;
    procedure Pause(AContext: NativeInt); virtual;
    procedure Resume(AContext: NativeInt); virtual;
    procedure Unregister(AContext: NativeInt); virtual;
    procedure SetVolume(AVolume: Integer); virtual;
    procedure Process; virtual;
    procedure PrepareForNewSong; virtual;
  end;

implementation

{ TEngineMusicBackendBase }

procedure TEngineMusicBackendBase.Initialize;
begin
end;

procedure TEngineMusicBackendBase.Shutdown;
begin
end;

procedure TEngineMusicBackendBase.Play(AContext: NativeInt; ALooping: Boolean);
begin
end;

procedure TEngineMusicBackendBase.Stop(AContext: NativeInt);
begin
end;

procedure TEngineMusicBackendBase.Pause(AContext: NativeInt);
begin
end;

procedure TEngineMusicBackendBase.Resume(AContext: NativeInt);
begin
end;

procedure TEngineMusicBackendBase.Unregister(AContext: NativeInt);
begin
end;

procedure TEngineMusicBackendBase.SetVolume(AVolume: Integer);
begin
end;

procedure TEngineMusicBackendBase.Process;
begin
end;

procedure TEngineMusicBackendBase.PrepareForNewSong;
begin
end;

end.
