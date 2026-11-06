{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the music player                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.MusicPlayer;

interface

uses
  System.Generics.Collections, DelphiDoom.Audio.Types, DelphiDoom.Audio.Intf;

type
  /// <summary>
  ///   Chooses the backend of every song (the first one that recognizes it, in the order they
  ///   were given), remembers the one that plays now and sends it pause, resume, volume and the
  ///   tic. A song that no backend recognizes gets a handle and is silent
  /// </summary>
  TMusicPlayer = class(TInterfacedObject, IMusicPlayer)
  private
    type
      TMusicSong = record
        Backend: IMusicBackend;
        Context: NativeInt;
      end;
    var
      FBackends: TArray<IMusicBackend>;
      FSongs: TDictionary<Integer, TMusicSong>;
      FActive: IMusicBackend;
      FNextHandle: Integer;
  public
    constructor Create(const ABackends: TArray<IMusicBackend>);
    destructor Destroy; override;
    procedure Initialize;
    procedure Shutdown;
    function Register(AData: Pointer; ASize: Integer): Integer;
    procedure Play(AHandle: Integer; ALooping: Boolean);
    procedure Pause(AHandle: Integer);
    procedure Resume(AHandle: Integer);
    procedure Unregister(AHandle: Integer);
    procedure SetVolume(AVolume: Integer);
    procedure Process;
  end;

implementation

uses
  System.SysUtils;

{ TMusicPlayer }

constructor TMusicPlayer.Create(const ABackends: TArray<IMusicBackend>);
begin
  inherited Create;
  FBackends := Copy(ABackends);
  FSongs := TDictionary<Integer, TMusicSong>.Create;
  FNextHandle := 1;
end;

destructor TMusicPlayer.Destroy;
begin
  FSongs.Free;
  inherited Destroy;
end;

procedure TMusicPlayer.Initialize;
var
  LBackend: IMusicBackend;
begin
  for LBackend in FBackends do
    LBackend.Initialize;
end;

procedure TMusicPlayer.Shutdown;
var
  LBackend: IMusicBackend;
begin
  for LBackend in FBackends do
    LBackend.Shutdown;
  FActive := nil;
end;

function TMusicPlayer.Register(AData: Pointer; ASize: Integer): Integer;
var
  LBackend: IMusicBackend;
  LSong: TMusicSong;
begin
  if Assigned(FActive) then
    FActive.PrepareForNewSong;

  LSong.Backend := nil;
  LSong.Context := 0;
  for LBackend in FBackends do
    case LBackend.Register(AData, ASize, LSong.Context) of
      TMusicRegisterResult.Failed:
        begin
          FActive := nil;
          Result := 0;
          Exit;
        end;
      TMusicRegisterResult.Registered:
        begin
          LSong.Backend := LBackend;
          FActive := LBackend;
          Break;
        end;
    end;

  Result := FNextHandle;
  Inc(FNextHandle);
  FSongs.Add(Result, LSong);
end;

procedure TMusicPlayer.Play(AHandle: Integer; ALooping: Boolean);
var
  LSong: TMusicSong;
begin
  if FSongs.TryGetValue(AHandle, LSong) and Assigned(LSong.Backend) then
    LSong.Backend.Play(LSong.Context, ALooping);
end;

procedure TMusicPlayer.Pause(AHandle: Integer);
var
  LSong: TMusicSong;
begin
  if not Assigned(FActive) then
    Exit;
  if not FSongs.TryGetValue(AHandle, LSong) then
    LSong.Context := 0;
  FActive.Pause(LSong.Context);
end;

procedure TMusicPlayer.Resume(AHandle: Integer);
var
  LSong: TMusicSong;
begin
  if not Assigned(FActive) then
    Exit;
  if not FSongs.TryGetValue(AHandle, LSong) then
    LSong.Context := 0;
  FActive.Resume(LSong.Context);
end;

procedure TMusicPlayer.Unregister(AHandle: Integer);
var
  LSong: TMusicSong;
begin
  if not FSongs.TryGetValue(AHandle, LSong) then
    Exit;

  FSongs.Remove(AHandle);
  if Assigned(LSong.Backend) then
  begin
    LSong.Backend.Stop(LSong.Context);
    LSong.Backend.Unregister(LSong.Context);
  end;
end;

procedure TMusicPlayer.SetVolume(AVolume: Integer);
begin
  if Assigned(FActive) then
    FActive.SetVolume(AVolume);
end;

procedure TMusicPlayer.Process;
begin
  if Assigned(FActive) then
    FActive.Process;
end;

end.
