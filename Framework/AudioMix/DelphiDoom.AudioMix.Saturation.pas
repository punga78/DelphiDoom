{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio mix library - sum of samples that saturates at 16 bits    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.AudioMix.Saturation;

{$Q-}
{$R-}
// the sums are done in 32 bits and cut back to 16: nothing here depends on the overflow checks

interface

type
  /// <summary>The cut at 16 bits that a mixer does when it adds a voice to what is already in the output</summary>
  TPcmSaturation = class
  public
    /// <summary>AValue limited to -32768..32767</summary>
    class function Clamp(AValue: Integer): SmallInt; static; inline;
    /// <summary>
    ///   ADestination[i] = Clamp(ADestination[i] + ASource[i]) for ACount samples: a call per block, not per sample
    /// </summary>
    class procedure AddSaturated(ADestination, ASource: PSmallInt; ACount: Integer); static;
  end;

implementation

class function TPcmSaturation.Clamp(AValue: Integer): SmallInt;
begin
  if AValue > 32767 then
    Result := 32767
  else if AValue < -32768 then
    Result := -32768
  else
    Result := SmallInt(AValue);
end;

class procedure TPcmSaturation.AddSaturated(ADestination, ASource: PSmallInt; ACount: Integer);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ACount - 1 do
  begin
    ADestination^ := Clamp(Integer(ADestination^) + Integer(ASource^));
    Inc(ADestination);
    Inc(ASource);
  end;
end;

end.
