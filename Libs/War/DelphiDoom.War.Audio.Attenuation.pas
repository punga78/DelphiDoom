{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - volume of a sound that has a place on the map     }
{                                                                              }
{  Port of the positional volume of audioDataCallback (war_audio.c) and of     }
{  rect_containsf, rect_center, vec2_distance of war_math.c, war1              }
{  (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib License (see        }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.Attenuation;

interface

type
  /// <summary>
  ///   Inside the viewport a sound is heard at the volume of the sounds; outside, between 120 and 200 pixels from
  ///   the center of the viewport the volume goes from 0.75 to 0, and farther away there is silence
  /// </summary>
  TWarSoundAttenuation = class
  public
    /// <summary>
    ///   The volume of the original: ABaseVolume inside the viewport; outside, 0.75 * (1 - (distance - 120) / 80)
    ///   and not less than 0, whatever the base volume (the original does not scale it by the sound volume)
    /// </summary>
    class function Volume(AViewportX, AViewportY, AViewportWidth, AViewportHeight, AX, AY,
      ABaseVolume: Single): Single; static;
    /// <summary>The same, as a factor between 0 and 1 of the sound volume (1 inside the viewport)</summary>
    class function Factor(AViewportX, AViewportY, AViewportWidth, AViewportHeight, AX, AY: Single): Single; static;
  end;

implementation

{ TWarSoundAttenuation }

class function TWarSoundAttenuation.Volume(AViewportX, AViewportY, AViewportWidth, AViewportHeight, AX, AY,
  ABaseVolume: Single): Single;
var
  LRight, LBottom, LCenterX, LCenterY, LDX, LDY, LDistanceSquared, LDistance, LRatio: Single;
begin
  LRight := AViewportX + AViewportWidth;
  LBottom := AViewportY + AViewportHeight;
  // each operation is stored in a Single, as the float of the C is rounded after each one
  if (AX >= AViewportX) and (AX <= LRight) and (AY >= AViewportY) and (AY <= LBottom) then
    Exit(ABaseVolume);
  LCenterX := 0.5 * AViewportWidth;
  LCenterX := AViewportX + LCenterX;
  LCenterY := 0.5 * AViewportHeight;
  LCenterY := AViewportY + LCenterY;
  LDX := AX - LCenterX;
  LDY := AY - LCenterY;
  LDistanceSquared := LDX * LDX;
  LDistanceSquared := LDistanceSquared + LDY * LDY;
  LDistance := Sqrt(LDistanceSquared);
  LRatio := LDistance - 120;
  LRatio := LRatio / 80;
  LRatio := 1 - LRatio;
  Result := 0.75 * LRatio;
  if Result < 0 then
    Result := 0;
end;

class function TWarSoundAttenuation.Factor(AViewportX, AViewportY, AViewportWidth, AViewportHeight, AX,
  AY: Single): Single;
begin
  Result := Volume(AViewportX, AViewportY, AViewportWidth, AViewportHeight, AX, AY, 1);
end;

end.
