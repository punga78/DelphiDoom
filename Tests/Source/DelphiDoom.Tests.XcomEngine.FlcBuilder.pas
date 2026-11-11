{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom libraries - FLI/FLC and LBM files built   }
{  in memory for the tests of the decoder and of the cutscenes                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.FlcBuilder;

interface

uses
  System.SysUtils;

const
  FLC_COLOR_256 = $04;
  FLC_SS2 = $07;
  FLC_COLOR_64 = $0B;
  FLC_LC = $0C;
  FLC_BLACK = $0D;
  FLC_BRUN = $0F;
  FLC_COPY = $10;

type
  /// <summary>
  ///   Writes a FLI or FLC file a piece at a time: the header, then frames ($F1FA) made of chunks, prefix chunks
  ///   ($F100) and the audio chunks of TFTD ($AAAA)
  /// </summary>
  TFlcBuilder = class
  strict private
    FBytes: TBytes;
    FFrame: TBytes;
    FChunks: Integer;
    FFrameOpen: Boolean;
    FFrameDelay: Integer;
    class procedure Append(var ATarget: TBytes; const ABytes: array of Byte); static;
    class procedure AppendWord(var ATarget: TBytes; AValue: Integer); static;
    class procedure AppendCardinal(var ATarget: TBytes; AValue: Cardinal); static;
  public
    constructor Create(AType: Word; AWidth, AHeight, AFrames, ASpeed: Integer);
    /// <summary>Starts a frame; ADelay is the FRAME_TYPE extension (0: the speed of the header)</summary>
    procedure BeginFrame(ADelay: Integer = 0);
    /// <summary>A chunk of the frame: its type and what follows the six bytes of its header</summary>
    procedure Chunk(AType: Word; const AData: array of Byte);
    procedure EndFrame;
    /// <summary>A whole frame with a FLI_COPY chunk of these pixels</summary>
    procedure CopyFrame(const APixels: array of Byte; ADelay: Integer = 0);
    procedure Prefix(const AData: array of Byte);
    procedure Audio(ASampleRate: Integer; const ASamples: array of Byte);
    function Build: TBytes;
  end;

  /// <summary>A PBM picture (IFF, 8 planes, no compression): the width must be a multiple of 16</summary>
  TLbmBuilder = class
  public
    /// <summary>Every pixel is AFill; the color AFill of the palette is (ARed, AGreen, ABlue), the others black</summary>
    class function Solid(AWidth, AHeight: Integer; AFill, ARed, AGreen, ABlue: Byte): TBytes; static;
  end;

implementation

{ TFlcBuilder }

class procedure TFlcBuilder.Append(var ATarget: TBytes; const ABytes: array of Byte);
var
  LStart: Integer;
begin
  if Length(ABytes) = 0 then
    Exit;
  LStart := Length(ATarget);
  SetLength(ATarget, LStart + Length(ABytes));
  Move(ABytes[0], ATarget[LStart], Length(ABytes));
end;

class procedure TFlcBuilder.AppendWord(var ATarget: TBytes; AValue: Integer);
begin
  Append(ATarget, [Byte(AValue and $FF), Byte((AValue shr 8) and $FF)]);
end;

class procedure TFlcBuilder.AppendCardinal(var ATarget: TBytes; AValue: Cardinal);
begin
  Append(ATarget, [Byte(AValue and $FF), Byte((AValue shr 8) and $FF), Byte((AValue shr 16) and $FF),
    Byte((AValue shr 24) and $FF)]);
end;

constructor TFlcBuilder.Create(AType: Word; AWidth, AHeight, AFrames, ASpeed: Integer);
begin
  inherited Create;
  SetLength(FBytes, 128);
  FillChar(FBytes[0], 128, 0);
  FBytes[4] := AType and $FF;
  FBytes[5] := AType shr 8;
  FBytes[6] := AFrames and $FF;
  FBytes[7] := AFrames shr 8;
  FBytes[8] := AWidth and $FF;
  FBytes[9] := AWidth shr 8;
  FBytes[10] := AHeight and $FF;
  FBytes[11] := AHeight shr 8;
  FBytes[12] := 8;
  FBytes[16] := ASpeed and $FF;
  FBytes[17] := ASpeed shr 8;
end;

procedure TFlcBuilder.BeginFrame(ADelay: Integer);
begin
  FFrame := nil;
  FChunks := 0;
  FFrameDelay := ADelay;
  FFrameOpen := True;
end;

procedure TFlcBuilder.Chunk(AType: Word; const AData: array of Byte);
begin
  AppendCardinal(FFrame, 6 + Length(AData));
  AppendWord(FFrame, AType);
  Append(FFrame, AData);
  Inc(FChunks);
end;

procedure TFlcBuilder.EndFrame;
begin
  AppendCardinal(FBytes, 16 + Length(FFrame));
  AppendWord(FBytes, $F1FA);
  AppendWord(FBytes, FChunks);
  AppendWord(FBytes, FFrameDelay);
  Append(FBytes, [0, 0, 0, 0, 0, 0]);
  Append(FBytes, FFrame);
  FFrameOpen := False;
end;

procedure TFlcBuilder.CopyFrame(const APixels: array of Byte; ADelay: Integer);
begin
  BeginFrame(ADelay);
  Chunk(FLC_COPY, APixels);
  EndFrame;
end;

procedure TFlcBuilder.Prefix(const AData: array of Byte);
begin
  AppendCardinal(FBytes, 6 + Length(AData));
  AppendWord(FBytes, $F100);
  Append(FBytes, AData);
end;

procedure TFlcBuilder.Audio(ASampleRate: Integer; const ASamples: array of Byte);
begin
  // the size of an audio chunk is the count of its samples: the header of 16 bytes is not in it
  AppendCardinal(FBytes, Length(ASamples));
  AppendWord(FBytes, $AAAA);
  AppendWord(FBytes, 0);
  AppendWord(FBytes, ASampleRate);
  Append(FBytes, [0, 0, 0, 0, 0, 0]);
  Append(FBytes, ASamples);
end;

function TFlcBuilder.Build: TBytes;
begin
  Result := Copy(FBytes);
end;

{ TLbmBuilder }

class function TLbmBuilder.Solid(AWidth, AHeight: Integer; AFill, ARed, AGreen, ABlue: Byte): TBytes;

  procedure Put(var AAt: Integer; const ABytes: array of Byte);
  begin
    Move(ABytes[0], Result[AAt], Length(ABytes));
    Inc(AAt, Length(ABytes));
  end;

  procedure PutLong(var AAt: Integer; AValue: Cardinal);
  begin
    Put(AAt, [Byte(AValue shr 24), Byte(AValue shr 16), Byte(AValue shr 8), Byte(AValue)]);
  end;

var
  LAt: Integer;
  LBody: Integer;
begin
  LBody := AWidth * AHeight;
  SetLength(Result, 12 + 8 + 20 + 8 + 768 + 8 + LBody);
  FillChar(Result[0], Length(Result), 0);
  LAt := 0;
  Put(LAt, [Ord('F'), Ord('O'), Ord('R'), Ord('M')]);
  PutLong(LAt, Length(Result) - 8);
  Put(LAt, [Ord('P'), Ord('B'), Ord('M'), Ord(' ')]);
  Put(LAt, [Ord('B'), Ord('M'), Ord('H'), Ord('D')]);
  PutLong(LAt, 20);
  Put(LAt, [Byte(AWidth shr 8), Byte(AWidth), Byte(AHeight shr 8), Byte(AHeight), 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 1, 1,
    Byte(AWidth shr 8), Byte(AWidth), Byte(AHeight shr 8), Byte(AHeight)]);
  Put(LAt, [Ord('C'), Ord('M'), Ord('A'), Ord('P')]);
  PutLong(LAt, 768);
  Result[LAt + AFill * 3] := ARed;
  Result[LAt + AFill * 3 + 1] := AGreen;
  Result[LAt + AFill * 3 + 2] := ABlue;
  Inc(LAt, 768);
  Put(LAt, [Ord('B'), Ord('O'), Ord('D'), Ord('Y')]);
  PutLong(LAt, LBody);
  FillChar(Result[LAt], LBody, AFill);
end;

end.
