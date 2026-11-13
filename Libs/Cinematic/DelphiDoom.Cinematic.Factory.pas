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
  DelphiDoom.Cinematic.Intf;

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
      AAlpha: Byte = ROQ_ALPHA_OPAQUE): IRoqDecoder; static;
    class function CreatePlayer(const ADecoder: IRoqDecoder; ALooping: Boolean): IRoqPlayer; static;
  end;

implementation

uses
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

class function TCinematicFactory.CreatePlayer(const ADecoder: IRoqDecoder;
  ALooping: Boolean): IRoqPlayer;
begin
  Result := TRoqPlayer.Create(ADecoder, ALooping);
end;

end.
