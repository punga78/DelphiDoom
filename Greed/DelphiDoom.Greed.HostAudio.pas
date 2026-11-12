{******************************************************************************}
{                                                                              }
{  DelphiDoom: Greed32 - the mixer of the game on the sound output of the host  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.HostAudio;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Audio.Intf, DelphiDoom.Greed.PcmMixer;

type
  /// <summary>
  ///   Gives the samples of the mixer of the game to the PCM output of Libs\GameHost (waveOut): the output asks
  ///   from its thread, the mixer answers. The output does not keep its source alive: this object is the source and
  ///   lives until Close has returned. Without a device (Open false) the game goes on and the mixer is never asked
  /// </summary>
  TGreedHostAudio = class(TInterfacedObject, IGameHostPcmSource)
  strict private
    FOutput: IGameHostPcmOutput;
    FMixer: IGreedPcmRenderer;
  public
    constructor Create(const AOutput: IGameHostPcmOutput; const AMixer: IGreedPcmRenderer);
    destructor Destroy; override;
    /// <summary>Opens the device at the rate of the mixer; false when there is none</summary>
    function Open: Boolean;
    procedure Close;
    /// <summary>The buffers that the device has played: the proof that the sound goes out</summary>
    function CompletedBuffers: Integer;
    procedure Render(ABuffer: PByte; AByteCount: Integer);
  end;

implementation

{ TGreedHostAudio }

constructor TGreedHostAudio.Create(const AOutput: IGameHostPcmOutput; const AMixer: IGreedPcmRenderer);
begin
  inherited Create;
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  if not Assigned(AMixer) then
    raise EArgumentNilException.Create('AMixer');
  FOutput := AOutput;
  FMixer := AMixer;
end;

destructor TGreedHostAudio.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TGreedHostAudio.Open: Boolean;
begin
  if FOutput.IsOpen then
    Exit(True);
  Result := FOutput.Open(FMixer.Rate, Self);
end;

procedure TGreedHostAudio.Close;
begin
  if Assigned(FOutput) then
    FOutput.Close;
end;

function TGreedHostAudio.CompletedBuffers: Integer;
begin
  Result := FOutput.CompletedBuffers;
end;

procedure TGreedHostAudio.Render(ABuffer: PByte; AByteCount: Integer);
begin
  FMixer.Render(ABuffer, AByteCount);
end;

end.
