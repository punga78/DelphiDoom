{******************************************************************************}
{                                                                              }
{  DelphiDoom: dynamic lights library - the words of a light definition       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DynLights.Tokens;

interface

{$SCOPEDENUMS ON}

type
  TDynLightToken = (
    Unknown,
    PointLight,
    FlickerLight,
    PulseLight,
    ObjectKeyword,
    Color,
    SecondaryColor,
    Size,
    SecondarySize,
    Interval,
    ColorInterval,
    Chance,
    ColorChance,
    Offset,
    SecondaryOffset,
    RandomOffset
  );

  /// <summary>Tells which word of a light definition a text is (the text in upper case)</summary>
  TDynLightTokens = class
  public
    class function Classify(const AUpperWord: string): TDynLightToken; static;
  end;

implementation

{ TDynLightTokens }

class function TDynLightTokens.Classify(const AUpperWord: string): TDynLightToken;
begin
  if AUpperWord = 'POINTLIGHT' then
    Result := TDynLightToken.PointLight
  else if (AUpperWord = 'FLICKERLIGHT') or (AUpperWord = 'FLICKERLIGHT2') then
    Result := TDynLightToken.FlickerLight
  else if AUpperWord = 'PULSELIGHT' then
    Result := TDynLightToken.PulseLight
  else if AUpperWord = 'OBJECT' then
    Result := TDynLightToken.ObjectKeyword
  else if (AUpperWord = 'COLOR') or (AUpperWord = 'COLOR1') or (AUpperWord = 'PRIMARYCOLOR') then
    Result := TDynLightToken.Color
  else if (AUpperWord = 'COLOR2') or (AUpperWord = 'SECONDARYCOLOR') then
    Result := TDynLightToken.SecondaryColor
  else if (AUpperWord = 'SIZE') or (AUpperWord = 'SIZE1') or (AUpperWord = 'PRIMARYSIZE') then
    Result := TDynLightToken.Size
  else if (AUpperWord = 'SIZE2') or (AUpperWord = 'SECONDARYSIZE') then
    Result := TDynLightToken.SecondarySize
  else if AUpperWord = 'INTERVAL' then
    Result := TDynLightToken.Interval
  else if AUpperWord = 'COLORINTERVAL' then
    Result := TDynLightToken.ColorInterval
  else if AUpperWord = 'CHANCE' then
    Result := TDynLightToken.Chance
  else if AUpperWord = 'COLORCHANCE' then
    Result := TDynLightToken.ColorChance
  else if (AUpperWord = 'OFFSET') or (AUpperWord = 'OFFSET1') or (AUpperWord = 'PRIMARYOFFSET') then
    Result := TDynLightToken.Offset
  else if (AUpperWord = 'OFFSET2') or (AUpperWord = 'SECONDARYOFFSET') then
    Result := TDynLightToken.SecondaryOffset
  else if AUpperWord = 'RANDOMOFFSET' then
    Result := TDynLightToken.RandomOffset
  else
    Result := TDynLightToken.Unknown;
end;

end.
