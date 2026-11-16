{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the sound manager that two threads can call       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.LockedSoundManager;

interface

uses
  System.SysUtils, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   A sound manager behind a lock: the game calls it from its thread while the sound output calls Service from
  ///   its own (in the original the timer interrupt, with the interrupts turned off around each change).
  ///   WaitSoundDone does not call Service: it waits for the output to end the sound, doing AIdle between two looks
  /// </summary>
  TKeenLockedSoundManager = class(TInterfacedObject, IKeenSoundManager)
  strict private
    FInner: IKeenSoundManager;
    FLock: IKeenAudioLock;
    FIdle: TProc;
  public
    /// <param name="AIdle">What a wait does between two looks (it must let the time of the sound go on)</param>
    constructor Create(const AInner: IKeenSoundManager; const ALock: IKeenAudioLock; const AIdle: TProc);
    function GetMode: TKeenSoundMode;
    procedure SetMode(AMode: TKeenSoundMode);
    procedure PlaySound(ASound: Integer);
    procedure StopSound;
    function SoundPlaying: Integer;
    procedure Service;
    procedure WaitSoundDone;
    function AdLibPresent: Boolean;
    function TrySetMode(AMode: TKeenSoundMode): Boolean;
    procedure SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
  end;

implementation

{ TKeenLockedSoundManager }

constructor TKeenLockedSoundManager.Create(const AInner: IKeenSoundManager; const ALock: IKeenAudioLock;
  const AIdle: TProc);
begin
  inherited Create;
  if not Assigned(AInner) then
    raise EArgumentNilException.Create('AInner');
  if not Assigned(ALock) then
    raise EArgumentNilException.Create('ALock');
  if not Assigned(AIdle) then
    raise EArgumentNilException.Create('AIdle');
  FInner := AInner;
  FLock := ALock;
  FIdle := AIdle;
end;

function TKeenLockedSoundManager.GetMode: TKeenSoundMode;
begin
  FLock.Enter;
  try
    Result := FInner.Mode;
  finally
    FLock.Leave;
  end;
end;

procedure TKeenLockedSoundManager.SetMode(AMode: TKeenSoundMode);
begin
  FLock.Enter;
  try
    FInner.Mode := AMode;
  finally
    FLock.Leave;
  end;
end;

procedure TKeenLockedSoundManager.PlaySound(ASound: Integer);
begin
  FLock.Enter;
  try
    FInner.PlaySound(ASound);
  finally
    FLock.Leave;
  end;
end;

procedure TKeenLockedSoundManager.StopSound;
begin
  FLock.Enter;
  try
    FInner.StopSound;
  finally
    FLock.Leave;
  end;
end;

function TKeenLockedSoundManager.SoundPlaying: Integer;
begin
  FLock.Enter;
  try
    Result := FInner.SoundPlaying;
  finally
    FLock.Leave;
  end;
end;

procedure TKeenLockedSoundManager.Service;
begin
  FLock.Enter;
  try
    FInner.Service;
  finally
    FLock.Leave;
  end;
end;

procedure TKeenLockedSoundManager.WaitSoundDone;
begin
  while SoundPlaying <> 0 do
    FIdle();
end;

function TKeenLockedSoundManager.AdLibPresent: Boolean;
begin
  Result := FInner.AdLibPresent;
end;

function TKeenLockedSoundManager.TrySetMode(AMode: TKeenSoundMode): Boolean;
begin
  FLock.Enter;
  try
    Result := FInner.TrySetMode(AMode);
  finally
    FLock.Leave;
  end;
end;

procedure TKeenLockedSoundManager.SetDefault(AGotIt: Boolean; AMode: TKeenSoundMode);
begin
  FLock.Enter;
  try
    FInner.SetDefault(AGotIt, AMode);
  finally
    FLock.Leave;
  end;
end;

end.
