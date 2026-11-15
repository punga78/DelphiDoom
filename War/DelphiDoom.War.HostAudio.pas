{******************************************************************************}
{                                                                              }
{  Warcraft32: the sound of the game on the PCM output of Libs\GameHost        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.HostAudio;

interface

uses
  System.SysUtils, DelphiDoom.GameHost.Audio.Intf;

type
  /// <summary>
  ///   Opens the sound output of the machine on the source that mixes the effects and the song, and closes it. The
  ///   output does not keep the source alive: this object does, until Close has returned. Without a device (Open
  ///   False) the game goes on and the source is never asked
  /// </summary>
  TWarHostAudio = class
  strict private
    FOutput: IGameHostPcmOutput;
    FSource: IGameHostPcmSource;
    FRate: Integer;
  public
    constructor Create(const AOutput: IGameHostPcmOutput; const ASource: IGameHostPcmSource; ARate: Integer);
    destructor Destroy; override;
    /// <summary>Opens the device at the rate; false when there is none</summary>
    function Open: Boolean;
    procedure Close;
    /// <summary>The buffers that the device has played: the proof that the sound goes out</summary>
    function CompletedBuffers: Integer;
  end;

implementation

{ TWarHostAudio }

constructor TWarHostAudio.Create(const AOutput: IGameHostPcmOutput; const ASource: IGameHostPcmSource;
  ARate: Integer);
begin
  inherited Create;
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  FOutput := AOutput;
  FSource := ASource;
  FRate := ARate;
end;

destructor TWarHostAudio.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TWarHostAudio.Open: Boolean;
begin
  if FOutput.IsOpen then
    Exit(True);
  Result := FOutput.Open(FRate, FSource);
end;

procedure TWarHostAudio.Close;
begin
  FOutput.Close;
end;

function TWarHostAudio.CompletedBuffers: Integer;
begin
  Result := FOutput.CompletedBuffers;
end;

end.
