{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the curve of the volume options            }
{  (Game::volumeExponent of OpenXcom)                                           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Volume;

interface

type
  /// <summary>The conversion of the volume of the options (0..128) into what the mixer applies</summary>
  TXcomVolume = class
  public
    const
      /// <summary>SDL_MIX_MAXVOLUME</summary>
      MAX_VOLUME = 128;
      /// <summary>Game::VOLUME_GRADIENT</summary>
      GRADIENT = 10.0;
    /// <summary>Game::volumeExponent: 0 gives 0 and 128 gives 1, with a curve that grows slowly at first</summary>
    class function Exponent(AVolume: Integer): Double; static;
    /// <summary>
    ///   Game::setVolume: the exponent times SDL_MIX_MAXVOLUME as an integer (what Mix_Volume and Mix_VolumeMusic
    ///   take; the conversion of the C truncates)
    /// </summary>
    class function Mixer(AVolume: Integer): Integer; static;
  end;

implementation

uses
  System.Math;

class function TXcomVolume.Exponent(AVolume: Integer): Double;
begin
  Result := (Exp(Ln(GRADIENT + 1.0) * AVolume / MAX_VOLUME) - 1.0) / GRADIENT;
end;

class function TXcomVolume.Mixer(AVolume: Integer): Integer;
begin
  Result := Trunc(Exponent(AVolume) * MAX_VOLUME);
end;

end.
