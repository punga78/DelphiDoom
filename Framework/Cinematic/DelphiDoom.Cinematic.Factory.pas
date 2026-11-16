{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - where the classes are made                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Factory;

interface

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Types,
  DelphiDoom.Cinematic.Intf,
  DelphiDoom.Cinematic.Jpeg.Intf,
  DelphiDoom.Cinematic.ModeCodebook;

type
  /// <summary>The composition root of the library: the only place that knows the classes</summary>
  TCinematicFactory = class
  public
    /// <summary>A source on a buffer</summary>
    class function CreateMemorySource(const ABytes: TBytes): IRoqSource; static;
    /// <summary>
    ///   A decoder; it reads the header of the file at once and raises if it is not RoQ.
    ///   ASink may be nil
    /// </summary>
    class function CreateDecoder(const ASource: IRoqSource; const ASink: IRoqAudioSink;
      AAlpha: Byte = ROQ_ALPHA_OPAQUE): IRoqDecoder; overload; static;
    /// <summary>
    ///   A decoder that also decodes the JPEG frames of Doom 3 with AJpeg (made by
    ///   <c>TRoqJpegFactory</c>, or a fake); with nil it is the same as the other overload
    /// </summary>
    class function CreateDecoder(const ASource: IRoqSource; const ASink: IRoqAudioSink;
      AAlpha: Byte; const AJpeg: IRoqJpegDecoder): IRoqDecoder; overload; static;
    class function CreatePlayer(const ADecoder: IRoqDecoder; ALooping: Boolean): IRoqPlayer; static;
    /// <summary>
    ///   The codebook of Quake III in one of its modes (the caller owns it). AGray is the table of the
    ///   gray format and may be nil for the other two
    /// </summary>
    class function CreateModeCodebook(const AMode: TRoqCodebookMode; AAlpha: Byte = ROQ_ALPHA_OPAQUE;
      const AGray: TBytes = nil): TRoqModeCodebook; static;
  end;

implementation

uses
  DelphiDoom.Cinematic.YuvConverter,
  DelphiDoom.Cinematic.MemorySource,
  DelphiDoom.Cinematic.Decoder,
  DelphiDoom.Cinematic.Player;

{ TCinematicFactory }

class function TCinematicFactory.CreateMemorySource(const ABytes: TBytes): IRoqSource;
begin
  Result := TRoqMemorySource.Create(ABytes);
end;

class function TCinematicFactory.CreateDecoder(const ASource: IRoqSource;
  const ASink: IRoqAudioSink; AAlpha: Byte): IRoqDecoder;
begin
  Result := TRoqDecoder.Create(ASource, ASink, AAlpha);
end;

class function TCinematicFactory.CreateDecoder(const ASource: IRoqSource;
  const ASink: IRoqAudioSink; AAlpha: Byte; const AJpeg: IRoqJpegDecoder): IRoqDecoder;
begin
  Result := TRoqDecoder.Create(ASource, ASink, AAlpha, AJpeg);
end;

class function TCinematicFactory.CreatePlayer(const ADecoder: IRoqDecoder;
  ALooping: Boolean): IRoqPlayer;
begin
  Result := TRoqPlayer.Create(ADecoder, ALooping);
end;

class function TCinematicFactory.CreateModeCodebook(const AMode: TRoqCodebookMode; AAlpha: Byte;
  const AGray: TBytes): TRoqModeCodebook;
var
  LConverter: TRoqYuvConverter;
begin
  LConverter := TRoqYuvConverter.Create(AAlpha);
  try
    Result := TRoqModeCodebook.Create(LConverter, AMode, AGray, True);
  except
    LConverter.Free;
    raise;
  end;
end;

end.
