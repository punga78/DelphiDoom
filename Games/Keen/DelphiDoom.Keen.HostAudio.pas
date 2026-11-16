{******************************************************************************}
{                                                                              }
{  DelphiDoom: Keen32 - the sound of the game on the output of the game host    }
{  library                                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.HostAudio;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf, DelphiDoom.GameHost.Audio.Intf, DelphiDoom.Clock.Intf;

type
  /// <summary>
  ///   Gives the samples of the mixer of the game to the sound output of the machine. When there is no output
  ///   (no device, or the game was started without sound) the time of the sound must go on all the same, because
  ///   the game waits for the end of some sounds: Pump renders the samples of the time that went by and throws
  ///   them away
  /// </summary>
  TKeenHostAudio = class(TInterfacedObject, IGameHostPcmSource)
  strict private
    const
      BYTES_PER_FRAME = 4;
    var
      FMixer: IKeenAudioMixer;
      FOutput: IGameHostPcmOutput;
      FClock: IClock;
      FScratch: TBytes;
      FFramesPumped: Integer;
      FPumpStarted: Boolean;
  public
    /// <param name="AOutput">The device; nil for a game without a sound device</param>
    /// <param name="AClock">The time for the sound when there is no device; nil if the program gives the time itself (it renders the mixer)</param>
    constructor Create(const AMixer: IKeenAudioMixer; const AOutput: IGameHostPcmOutput; const AClock: IClock);
    destructor Destroy; override;
    /// <summary>Opens the device at the rate of the mixer; false when there is none (the sound then goes on with Pump)</summary>
    function Open: Boolean;
    procedure Close;
    function IsOpen: Boolean;
    /// <summary>The buffers the device has played</summary>
    function CompletedBuffers: Integer;
    procedure Render(ABuffer: PByte; AByteCount: Integer);
    /// <summary>Called by the loops of the game: without a device it lets the time of the sound go on</summary>
    procedure Pump;
  end;

implementation

{ TKeenHostAudio }

constructor TKeenHostAudio.Create(const AMixer: IKeenAudioMixer; const AOutput: IGameHostPcmOutput;
  const AClock: IClock);
begin
  inherited Create;
  if not Assigned(AMixer) then
    raise EArgumentNilException.Create('AMixer');
  FMixer := AMixer;
  FOutput := AOutput;
  FClock := AClock;
end;

destructor TKeenHostAudio.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TKeenHostAudio.Open: Boolean;
begin
  Result := Assigned(FOutput) and FOutput.Open(FMixer.Rate, Self);
end;

procedure TKeenHostAudio.Close;
begin
  if Assigned(FOutput) and FOutput.IsOpen then
    FOutput.Close;
end;

function TKeenHostAudio.IsOpen: Boolean;
begin
  Result := Assigned(FOutput) and FOutput.IsOpen;
end;

function TKeenHostAudio.CompletedBuffers: Integer;
begin
  if Assigned(FOutput) then
    Result := FOutput.CompletedBuffers
  else
    Result := 0;
end;

procedure TKeenHostAudio.Render(ABuffer: PByte; AByteCount: Integer);
begin
  FMixer.Render(ABuffer, AByteCount);
end;

procedure TKeenHostAudio.Pump;
var
  LNow: Integer;
  LFrames: Integer;
begin
  if IsOpen or not Assigned(FClock) then
    Exit;
  LNow := FClock.Steps(FMixer.Rate);
  if not FPumpStarted then
  begin
    FPumpStarted := True;
    FFramesPumped := LNow;
    Exit;
  end;
  LFrames := LNow - FFramesPumped;
  if LFrames <= 0 then
    Exit;
  // a long stop of the program is not played back: at most a second
  if LFrames > FMixer.Rate then
    LFrames := FMixer.Rate;
  FFramesPumped := LNow;
  if Length(FScratch) < LFrames * BYTES_PER_FRAME then
    SetLength(FScratch, LFrames * BYTES_PER_FRAME);
  FMixer.Render(@FScratch[0], LFrames * BYTES_PER_FRAME);
end;

end.
