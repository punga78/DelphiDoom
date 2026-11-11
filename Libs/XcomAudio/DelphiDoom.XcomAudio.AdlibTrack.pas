{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - a song of the Adlib (AdlibMusic of          }
{  OpenXcom as a track of the mixer)                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.AdlibTrack;

interface

uses
  System.SysUtils, DelphiDoom.XcomAdlib.Intf, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>
  ///   AdlibMusic: the bytes of a song, the volume it is normalized to, and the player of the two chips that all the
  ///   Adlib songs share (the C++ keeps the chips in two globals). The tracks of one player never play together: the
  ///   mixer stops the old track before it starts the new one
  /// </summary>
  TXcomAdlibTrack = class(TInterfacedObject, IXcomMusicTrack)
  strict private
    FPlayer: IXcomAdlibPlayer;
    FSettings: IXcomMusicSettings;
    FSong: TBytes;
    FNormalization: Single;
    FActive: Boolean;
    FBuffer: TArray<SmallInt>;
  public
    /// <param name="ASong">The bytes with the name of the CAT entry kept (IXcomAdlibMusicSource.LoadTrackWithName)</param>
    /// <param name="ANormalization">RuleMusic::getNormalization: 0.76 for the tracks of TFTD</param>
    constructor Create(const APlayer: IXcomAdlibPlayer; const ASettings: IXcomMusicSettings; const ASong: TBytes;
      ANormalization: Single);
    function Format: string;
    /// <summary>AdlibMusic::play: the loop is not used (Mix_HookMusic plays until it is stopped)</summary>
    procedure Start(ALoop: Integer);
    procedure Stop;
    function IsPlaying: Boolean;
    /// <summary>AdlibMusic::player: nothing when the music volume is 0; the song starts again when it ends and musicAlwaysLoop is on</summary>
    procedure Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
  end;

implementation

uses
  DelphiDoom.XcomAudio.Types;

{ TXcomAdlibTrack }

constructor TXcomAdlibTrack.Create(const APlayer: IXcomAdlibPlayer; const ASettings: IXcomMusicSettings;
  const ASong: TBytes; ANormalization: Single);
begin
  inherited Create;
  FPlayer := APlayer;
  FSettings := ASettings;
  FSong := ASong;
  FNormalization := ANormalization;
end;

function TXcomAdlibTrack.Format: string;
begin
  Result := 'Adlib';
end;

procedure TXcomAdlibTrack.Start(ALoop: Integer);
begin
  FPlayer.Load(FSong);
  FPlayer.Play(FNormalization);
  FActive := True;
end;

procedure TXcomAdlibTrack.Stop;
begin
  if FActive then
    FPlayer.Stop;
  FActive := False;
end;

function TXcomAdlibTrack.IsPlaying: Boolean;
begin
  Result := FActive and FPlayer.IsPlaying;
end;

procedure TXcomAdlibTrack.Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
var
  LIndex: Integer;
  LSum: Integer;
begin
  if (not FActive) or (AVolume <= 0) then
    Exit;
  if FSettings.AlwaysLoop and not FPlayer.IsPlaying then
  begin
    Start(-1);
    Exit;
  end;
  if (ABytes <= 0) or ((ABytes and 3) <> 0) then
    raise EXcomAudioException.Create(SXcomBufferNotWhole);
  if Length(FBuffer) < ABytes div 2 then
    SetLength(FBuffer, ABytes div 2);
  FPlayer.Render(FBuffer, ABytes, AVolume);
  for LIndex := 0 to ABytes div 2 - 1 do
  begin
    LSum := Integer(ABuffer^) + Integer(FBuffer[LIndex]);
    if LSum > 32767 then
      LSum := 32767
    else if LSum < -32768 then
      LSum := -32768;
    ABuffer^ := SmallInt(LSum);
    Inc(ABuffer);
  end;
end;

end.
