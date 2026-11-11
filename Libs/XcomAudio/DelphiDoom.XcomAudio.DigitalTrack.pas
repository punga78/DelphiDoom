{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - a music made of a digital file of the mod   }
{  (Music::load of a FLAC, OGG, MP3 or WAV file of the SOUND folder)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.DigitalTrack;

interface

uses
  System.SysUtils, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>
  ///   A digital music. The file stays compressed until the track is going to play (Prepare, called by the player
  ///   before the mixer gets the track) and the samples go away when it stops: a mod with many long tracks does not
  ///   keep them all decoded. Mix_PlayMusic(loop): -1 plays forever, 0 or 1 once, more that many times
  /// </summary>
  TXcomDigitalTrack = class(TInterfacedObject, IXcomMusicTrack, IXcomMusicPreparation)
  strict private
    FDecoder: IXcomSampleDecoder;
    FData: TBytes;
    FRate: Integer;
    FFormat: string;
    FSamples: TArray<SmallInt>;
    FPrepared: Boolean;
    FPosition: Integer;
    FRemaining: Integer;
    FActive: Boolean;
  public
    /// <param name="ADecoder">Reads the file; EArgumentNilException when nil</param>
    /// <param name="AData">The bytes of the file</param>
    /// <param name="ARate">The rate of the mixer</param>
    /// <param name="AFormat">The name the audio options show (Flac, Ogg, Mp3, Wav)</param>
    constructor Create(const ADecoder: IXcomSampleDecoder; const AData: TBytes; ARate: Integer;
      const AFormat: string);
    function Format: string;
    /// <summary>Decodes the file; a file that cannot be decoded is a silent track</summary>
    procedure Prepare;
    procedure Start(ALoop: Integer);
    procedure Stop;
    function IsPlaying: Boolean;
    procedure Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
  end;

implementation

uses
  DelphiDoom.XcomAudio.Types;

constructor TXcomDigitalTrack.Create(const ADecoder: IXcomSampleDecoder; const AData: TBytes; ARate: Integer;
  const AFormat: string);
begin
  inherited Create;
  if not Assigned(ADecoder) then
    raise EArgumentNilException.Create('ADecoder');
  FDecoder := ADecoder;
  FData := AData;
  FRate := ARate;
  FFormat := AFormat;
end;

function TXcomDigitalTrack.Format: string;
begin
  Result := FFormat;
end;

procedure TXcomDigitalTrack.Prepare;
begin
  if FPrepared then
    Exit;
  FPrepared := True;
  if not FDecoder.TryDecode(FData, FRate, FSamples) then
    FSamples := nil;
end;

procedure TXcomDigitalTrack.Start(ALoop: Integer);
begin
  Prepare;
  FPosition := 0;
  if ALoop < 0 then
    FRemaining := -1
  else if ALoop <= 1 then
    FRemaining := 1
  else
    FRemaining := ALoop;
  FActive := Length(FSamples) > 0;
end;

procedure TXcomDigitalTrack.Stop;
begin
  FActive := False;
  FSamples := nil;
  FPrepared := False;
end;

function TXcomDigitalTrack.IsPlaying: Boolean;
begin
  Result := FActive;
end;

procedure TXcomDigitalTrack.Render(ABuffer: PSmallInt; ABytes: Integer; AVolume: Single);
var
  LCount: Integer;
  LSum: Integer;
begin
  if (ABytes <= 0) or ((ABytes and 3) <> 0) then
    raise EXcomAudioException.Create(SXcomBufferNotWhole);
  LCount := ABytes div 2;
  while FActive and (LCount > 0) do
  begin
    if FPosition >= Length(FSamples) then
    begin
      if FRemaining > 0 then
        Dec(FRemaining);
      if FRemaining = 0 then
      begin
        FActive := False;
        Break;
      end;
      FPosition := 0;
    end;
    LSum := Integer(ABuffer^) + Trunc(FSamples[FPosition] * AVolume);
    if LSum > 32767 then
      LSum := 32767
    else if LSum < -32768 then
      LSum := -32768;
    ABuffer^ := SmallInt(LSum);
    Inc(ABuffer);
    Inc(FPosition);
    Dec(LCount);
  end;
end;

end.
