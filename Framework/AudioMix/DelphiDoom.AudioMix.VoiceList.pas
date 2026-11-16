{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio mix library - the voices that play now                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.AudioMix.VoiceList;

interface

uses
  System.SysUtils, System.SyncObjs, System.Generics.Collections, DelphiDoom.AudioMix.Intf;

type
  /// <summary>
  ///   The voices that play, in the order they were added (a sum that saturates depends on the order), behind a lock:
  ///   the game starts and stops voices from its thread while the audio output mixes from its own. MixAll gives each
  ///   voice one block and removes the ones that have ended. The lock can be taken again by the caller (it is a
  ///   critical section) to protect its own state with the same lock, as the mixers of the games did
  /// </summary>
  TPcmVoiceList = class
  strict private
    type
      TEntry = record
        Handle: Integer;
        Voice: IPcmVoice;
      end;
  strict private
    FLock: TCriticalSection;
    FEntries: TList<TEntry>;
    FNextHandle: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds a voice at the end; returns its handle (1, 2, 3...). EArgumentNilException when nil</summary>
    function Add(const AVoice: IPcmVoice): Integer;
    /// <summary>Takes out the voice with the handle (nothing happens if it is not there)</summary>
    procedure Remove(AHandle: Integer);
    procedure Clear;
    function Count: Integer;
    /// <summary>
    ///   Calls Mix of every voice, in order, with the same destination and count (one interface call per voice and
    ///   per block); the voices that answer True are removed. Returns how many were removed
    /// </summary>
    function MixAll(ADestination: Pointer; ACount: Integer): Integer;
    property Lock: TCriticalSection read FLock;
  end;

implementation

{ TPcmVoiceList }

constructor TPcmVoiceList.Create;
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FEntries := TList<TEntry>.Create;
  FNextHandle := 1;
end;

destructor TPcmVoiceList.Destroy;
begin
  FEntries.Free;
  FLock.Free;
  inherited Destroy;
end;

function TPcmVoiceList.Add(const AVoice: IPcmVoice): Integer;
var
  LEntry: TEntry;
begin
  if not Assigned(AVoice) then
    raise EArgumentNilException.Create('AVoice');
  FLock.Enter;
  try
    LEntry.Handle := FNextHandle;
    LEntry.Voice := AVoice;
    Inc(FNextHandle);
    FEntries.Add(LEntry);
    Result := LEntry.Handle;
  finally
    FLock.Leave;
  end;
end;

procedure TPcmVoiceList.Remove(AHandle: Integer);
var
  LIndex: Integer;
begin
  FLock.Enter;
  try
    for LIndex := FEntries.Count - 1 downto 0 do
      if FEntries[LIndex].Handle = AHandle then
        FEntries.Delete(LIndex);
  finally
    FLock.Leave;
  end;
end;

procedure TPcmVoiceList.Clear;
begin
  FLock.Enter;
  try
    FEntries.Clear;
  finally
    FLock.Leave;
  end;
end;

function TPcmVoiceList.Count: Integer;
begin
  FLock.Enter;
  try
    Result := FEntries.Count;
  finally
    FLock.Leave;
  end;
end;

function TPcmVoiceList.MixAll(ADestination: Pointer; ACount: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  FLock.Enter;
  try
    LIndex := 0;
    while LIndex < FEntries.Count do
      if FEntries[LIndex].Voice.Mix(ADestination, ACount) then
      begin
        FEntries.Delete(LIndex);
        Inc(Result);
      end
      else
        Inc(LIndex);
  finally
    FLock.Leave;
  end;
end;

end.
