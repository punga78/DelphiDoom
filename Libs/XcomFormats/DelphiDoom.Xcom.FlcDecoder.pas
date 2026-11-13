{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom formats library - the FLI and FLC animations (the decoder   }
{  of FlcPlayer of OpenXcom, without screen, clock and audio device)            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.FlcDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.Flic.FrameDecoder;

const
  XCOM_FLC_HEADER_BYTES = FLIC_FILE_HEADER_BYTES;
  XCOM_FLC_TYPE_FLI = FLIC_FILE_TYPE_FLI;
  XCOM_FLC_TYPE_FLC = FLIC_FILE_TYPE_FLC;

type
  /// <summary>A file that is not a FLI/FLC animation, or a chunk that reads or writes outside its buffers</summary>
  EXcomFlcException = class(EXcomDataException);

  /// <summary>The colors first .. first + count - 1 of the palette of the decoder have changed</summary>
  TXcomFlcPaletteHandler = reference to procedure(AFirst, ACount: Integer);

  /// <summary>
  ///   FlcPlayer without the screen. Since the issue #229 this is a thin adapter over TFlicFrameDecoder of
  ///   Libs\Flic (the decoder, with its oddities of the C++ kept, lives there and is shared with
  ///   Libs\Cinematic): it keeps the API of before, the palette as TXcomColor and the errors as
  ///   EXcomFlcException
  /// </summary>
  TXcomFlcDecoder = class
  strict private
    FCore: TFlicFrameDecoder;
    FOnPalette: TXcomFlcPaletteHandler;
    procedure ForwardPalette(AFirst, ACount: Integer);
    function GetHeaderType: Word;
    function GetFrames: Word;
    function GetWidth: Word;
    function GetHeight: Word;
    function GetDepth: Word;
    function GetSpeed: Word;
    function GetFrameCount: Integer;
    function GetFinished: Boolean;
    function GetHasAudio: Boolean;
    function GetSampleRate: Integer;
    function GetVideoDelay: Integer;
  public
    /// <summary>FlcPlayer::init: keeps the bytes and reads the header; EXcomFlcException when it is not FLI or FLC</summary>
    constructor Create(const ABytes: TBytes);
    destructor Destroy; override;
    /// <summary>
    ///   The first part of FlcPlayer::decodeVideo: skips the audio and prefix chunks up to the next frame and
    ///   reads its header. False (and Finished) when what is there is not a frame
    /// </summary>
    function FindFrame: Boolean;
    /// <summary>
    ///   The delay before the frame found by FindFrame, in milliseconds: a FLI uses its own delay or the speed
    ///   of the header in 1/70 s; a FLC that plays its own audio (the videos of TFTD) the length of an audio
    ///   chunk; any other FLC the speed of the header
    /// </summary>
    function FrameDelay(AInternalAudio: Boolean): Cardinal;
    /// <summary>
    ///   The second part of FlcPlayer::decodeVideo: draws the frame found by FindFrame in ATarget (APitch bytes
    ///   per row, the picture starts at AOffset). The last frame of the file sets Finished and, with
    ///   ASkipLastFrame, is not drawn
    /// </summary>
    procedure DecodeFrame(const ATarget: TBytes; APitch, AOffset: Integer; ASkipLastFrame: Boolean);
    /// <summary>
    ///   FlcPlayer::decodeAudio(1): the next audio chunk of the file, as the unsigned 8 bit samples it holds.
    ///   False when the file has no more audio chunks (Finished when what is there is not a frame)
    /// </summary>
    function NextAudioChunk(out ASamples: TBytes): Boolean;
    /// <summary>FlcPlayer::playAudioFrame: 16 bit samples, (sample - 128) * 240 * volume as a float truncated</summary>
    class function ToSigned16(const ASamples: TBytes; AVolume: Double): TArray<SmallInt>; static;
    /// <summary>FlcPlayer::setHeaderSpeed</summary>
    procedure SetHeaderSpeed(ASpeed: Integer);
    /// <summary>FlcPlayer::stop</summary>
    procedure Stop;
    /// <summary>The color of the palette of the animation</summary>
    function Color(AIndex: Integer): TXcomColor;
    property OnPalette: TXcomFlcPaletteHandler read FOnPalette write FOnPalette;
    function IsFli: Boolean;
    property HeaderType: Word read GetHeaderType;
    property Frames: Word read GetFrames;
    property Width: Word read GetWidth;
    property Height: Word read GetHeight;
    property Depth: Word read GetDepth;
    property Speed: Word read GetSpeed;
    /// <summary>FlcPlayer::getFrameCount: the frames found so far (also the last one when it is not drawn)</summary>
    property FrameCount: Integer read GetFrameCount;
    property Finished: Boolean read GetFinished;
    /// <summary>The file has audio chunks and one was read (the rate of the first one)</summary>
    property HasAudio: Boolean read GetHasAudio;
    property SampleRate: Integer read GetSampleRate;
    /// <summary>1000 / (sample rate / samples of the first audio chunk), with the integer divisions of the C++</summary>
    property VideoDelay: Integer read GetVideoDelay;
  end;

implementation

uses
  DelphiDoom.Flic.Types;

{ TXcomFlcDecoder }

constructor TXcomFlcDecoder.Create(const ABytes: TBytes);
begin
  inherited Create;
  try
    FCore := TFlicFrameDecoder.Create(ABytes);
  except
    on E: EFlicFormatException do
      raise EXcomFlcException.Create(E.Message);
  end;
  FCore.OnPalette := ForwardPalette;
end;

destructor TXcomFlcDecoder.Destroy;
begin
  FCore.Free;
  inherited Destroy;
end;

procedure TXcomFlcDecoder.ForwardPalette(AFirst, ACount: Integer);
begin
  if Assigned(FOnPalette) then
    FOnPalette(AFirst, ACount);
end;

function TXcomFlcDecoder.FindFrame: Boolean;
begin
  try
    Result := FCore.FindFrame;
  except
    on E: EFlicFormatException do
      raise EXcomFlcException.Create(E.Message);
  end;
end;

function TXcomFlcDecoder.FrameDelay(AInternalAudio: Boolean): Cardinal;
begin
  Result := FCore.FrameDelay(AInternalAudio);
end;

procedure TXcomFlcDecoder.DecodeFrame(const ATarget: TBytes; APitch, AOffset: Integer; ASkipLastFrame: Boolean);
begin
  try
    FCore.DecodeFrame(ATarget, APitch, AOffset, ASkipLastFrame);
  except
    on E: EFlicFormatException do
      raise EXcomFlcException.Create(E.Message);
  end;
end;

function TXcomFlcDecoder.NextAudioChunk(out ASamples: TBytes): Boolean;
begin
  try
    Result := FCore.NextAudioChunk(ASamples);
  except
    on E: EFlicFormatException do
      raise EXcomFlcException.Create(E.Message);
  end;
end;

class function TXcomFlcDecoder.ToSigned16(const ASamples: TBytes; AVolume: Double): TArray<SmallInt>;
begin
  Result := TFlicFrameDecoder.ToSigned16(ASamples, AVolume);
end;

procedure TXcomFlcDecoder.SetHeaderSpeed(ASpeed: Integer);
begin
  FCore.SetHeaderSpeed(ASpeed);
end;

procedure TXcomFlcDecoder.Stop;
begin
  FCore.Stop;
end;

function TXcomFlcDecoder.Color(AIndex: Integer): TXcomColor;
var
  LColor: TFlicColor;
begin
  LColor := FCore.Color(AIndex);
  Result.Red := LColor.Red;
  Result.Green := LColor.Green;
  Result.Blue := LColor.Blue;
  Result.Alpha := LColor.Alpha;
end;

function TXcomFlcDecoder.IsFli: Boolean;
begin
  Result := FCore.IsFli;
end;

function TXcomFlcDecoder.GetHeaderType: Word;
begin
  Result := FCore.HeaderType;
end;

function TXcomFlcDecoder.GetFrames: Word;
begin
  Result := FCore.Frames;
end;

function TXcomFlcDecoder.GetWidth: Word;
begin
  Result := FCore.Width;
end;

function TXcomFlcDecoder.GetHeight: Word;
begin
  Result := FCore.Height;
end;

function TXcomFlcDecoder.GetDepth: Word;
begin
  Result := FCore.Depth;
end;

function TXcomFlcDecoder.GetSpeed: Word;
begin
  Result := FCore.Speed;
end;

function TXcomFlcDecoder.GetFrameCount: Integer;
begin
  Result := FCore.FrameCount;
end;

function TXcomFlcDecoder.GetFinished: Boolean;
begin
  Result := FCore.Finished;
end;

function TXcomFlcDecoder.GetHasAudio: Boolean;
begin
  Result := FCore.HasAudio;
end;

function TXcomFlcDecoder.GetSampleRate: Integer;
begin
  Result := FCore.SampleRate;
end;

function TXcomFlcDecoder.GetVideoDelay: Integer;
begin
  Result := FCore.VideoDelay;
end;

end.
