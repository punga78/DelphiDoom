{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - the sound calls on the sound system     }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): cl_cgame.c and   }
{  cl_ui.c (the S_* calls), snd_dma.c. Copyright (C) 1999-2005 Id Software,     }
{  Inc. This unit is derived from the Quake III Arena source code and is        }
{  therefore available under the GNU General Public License, version 2 or (at   }
{  your option) any later version.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.ClientSoundAdapter;

interface

uses
  DelphiDoom.Audio.Q3.SoundSystem, DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.Client.Intf;

type
  /// <summary>
  ///   IQ3HostSound on TQ3SoundSystem of Framework\Audio (the port of snd_dma.c). The background track of the C
  ///   (S_StartBackgroundTrack reads a file of music from the disk) is not part of that sound system: here it
  ///   does nothing. The sound system is not owned
  /// </summary>
  TQ3SoundSystemAdapter = class(TInterfacedObject, IQ3HostSound)
  strict private
    FSystem: TQ3SoundSystem;
  public
    constructor Create(ASystem: TQ3SoundSystem);
    function RegisterSound(const AName: AnsiString; ACompressed: Boolean): Integer;
    procedure StartSound(AOrigin: PQ3HostVec3; AEntityNumber, AEntityChannel, ASfx: Integer);
    procedure StartLocalSound(ASfx, AChannelNumber: Integer);
    procedure ClearLoopingSounds(AKillAll: Boolean);
    procedure AddLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3HostVec3; ASfx: Integer);
    procedure AddRealLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3HostVec3; ASfx: Integer);
    procedure StopLoopingSound(AEntityNumber: Integer);
    procedure UpdateEntityPosition(AEntityNumber: Integer; const AOrigin: TQ3HostVec3);
    procedure Respatialize(AEntityNumber: Integer; const AHead: TQ3HostVec3; const AAxis: TQ3HostAxis;
      AInWater: Integer);
    procedure StartBackgroundTrack(const AIntro, ALoop: AnsiString);
    procedure StopBackgroundTrack;
  end;

implementation

uses
  DelphiDoom.Audio.Q3.Types;

constructor TQ3SoundSystemAdapter.Create(ASystem: TQ3SoundSystem);
begin
  inherited Create;
  FSystem := ASystem;
end;

function TQ3SoundSystemAdapter.RegisterSound(const AName: AnsiString; ACompressed: Boolean): Integer;
begin
  // the sound is never compressed (S_RegisterSound of the sound system)
  Result := FSystem.RegisterSound(string(AName));
end;

procedure TQ3SoundSystemAdapter.StartSound(AOrigin: PQ3HostVec3; AEntityNumber, AEntityChannel, ASfx: Integer);
begin
  FSystem.StartSound(PQ3Vec3(AOrigin), AEntityNumber, AEntityChannel, ASfx);
end;

procedure TQ3SoundSystemAdapter.StartLocalSound(ASfx, AChannelNumber: Integer);
begin
  FSystem.StartLocalSound(ASfx, AChannelNumber);
end;

procedure TQ3SoundSystemAdapter.ClearLoopingSounds(AKillAll: Boolean);
begin
  FSystem.ClearLoopingSounds(AKillAll);
end;

procedure TQ3SoundSystemAdapter.AddLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3HostVec3;
  ASfx: Integer);
begin
  FSystem.AddLoopingSound(AEntityNumber, TQ3Vec3(AOrigin), TQ3Vec3(AVelocity), ASfx);
end;

procedure TQ3SoundSystemAdapter.AddRealLoopingSound(AEntityNumber: Integer; const AOrigin, AVelocity: TQ3HostVec3;
  ASfx: Integer);
begin
  FSystem.AddRealLoopingSound(AEntityNumber, TQ3Vec3(AOrigin), TQ3Vec3(AVelocity), ASfx);
end;

procedure TQ3SoundSystemAdapter.StopLoopingSound(AEntityNumber: Integer);
begin
  FSystem.StopLoopingSound(AEntityNumber);
end;

procedure TQ3SoundSystemAdapter.UpdateEntityPosition(AEntityNumber: Integer; const AOrigin: TQ3HostVec3);
begin
  FSystem.UpdateEntityPosition(AEntityNumber, TQ3Vec3(AOrigin));
end;

procedure TQ3SoundSystemAdapter.Respatialize(AEntityNumber: Integer; const AHead: TQ3HostVec3;
  const AAxis: TQ3HostAxis; AInWater: Integer);
begin
  FSystem.Respatialize(AEntityNumber, TQ3Vec3(AHead), TQ3Axis(AAxis), AInWater);
end;

procedure TQ3SoundSystemAdapter.StartBackgroundTrack(const AIntro, ALoop: AnsiString);
begin
  // not part of the sound system: the music of the level is not played
end;

procedure TQ3SoundSystemAdapter.StopBackgroundTrack;
begin
end;

end.
