{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - FLIC animations: where the classes are made }
{  (issue #199)                                                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.Factory;

interface

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Flic.Intf;

type
  /// <summary>The composition root of the FLIC part of the library</summary>
  TFlicFactory = class
  public
    /// <summary>
    ///   A decoder on the bytes of a FLI/FLC file; it checks the file at once and raises
    ///   EFlicInvalidDataException if it cannot be played
    /// </summary>
    class function CreateDecoder(const ABytes: TBytes;
      AIncludeRingFrame: Boolean = False): IFlicDecoder; static;
    class function CreatePlayer(const ADecoder: IFlicDecoder; ALooping: Boolean): IFlicPlayer; static;
  end;

implementation

uses
  DelphiDoom.Cinematic.Flic.Decoder,
  DelphiDoom.Cinematic.Flic.Player;

{ TFlicFactory }

class function TFlicFactory.CreateDecoder(const ABytes: TBytes;
  AIncludeRingFrame: Boolean): IFlicDecoder;
begin
  Result := TFlicDecoder.Create(ABytes, AIncludeRingFrame);
end;

class function TFlicFactory.CreatePlayer(const ADecoder: IFlicDecoder;
  ALooping: Boolean): IFlicPlayer;
begin
  Result := TFlicPlayer.Create(ADecoder, ALooping);
end;

end.
