{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the light specials of the scripts                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The Light_* functions of the scripts (PS_Light_* of psi_map.pas).           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Lights;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Base,
  DelphiDoom.ScriptHost.SectorSpecials.Types;

type
  /// <summary>The lights that a script can start</summary>
  TScriptLightSpecials = class(TScriptSectorSpecialsBase)
  strict private
    function Start(const AKind: TScriptLightKind; const ATag, AFirst, ASecond, AThird,
      AFourth: Integer): Boolean;
  public
    function ChangeToValue(const ATag, AValue: Integer): Boolean;
    function Fade(const ATag, AValue, ATics: Integer): Boolean;
    function Flicker(const ATag, AUpper, ALower: Integer): Boolean;
    function ForceLightning: Boolean;
    function ForceLightningTics(const ATics: Integer): Boolean;
    function Glow(const ATag, AUpper, ALower, ATics: Integer): Boolean;
    function LowerByValue(const ATag, AValue: Integer): Boolean;
    function MaxNeighbor(const ATag: Integer): Boolean;
    function MinNeighbor(const ATag: Integer): Boolean;
    /// <remarks>
    ///   The value is not passed to the special (it was never written to the arguments by
    ///   PS_Light_RaiseByValue): the light is raised by 0. The behaviour is kept as it was
    /// </remarks>
    function RaiseByValue(const ATag, AValue: Integer): Boolean;
    function Strobe(const ATag, AUpper, ALower, AUpperTics, ALowerTics: Integer): Boolean;
    function StrobeDoom(const ATag, AUpperTics, ALowerTics: Integer): Boolean;
  end;

implementation

{ TScriptLightSpecials }

function TScriptLightSpecials.Start(const AKind: TScriptLightKind; const ATag, AFirst, ASecond,
  AThird, AFourth: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, AFirst);
  SetByte(LArguments, 2, ASecond);
  SetByte(LArguments, 3, AThird);
  SetByte(LArguments, 4, AFourth);
  Result := Specials.SpawnLight(LArguments, AKind);
end;

function TScriptLightSpecials.ChangeToValue(const ATag, AValue: Integer): Boolean;
begin
  Result := Start(slkChangeToValue, ATag, AValue, 0, 0, 0);
end;

function TScriptLightSpecials.Fade(const ATag, AValue, ATics: Integer): Boolean;
begin
  Result := Start(slkFade, ATag, AValue, ATics, 0, 0);
end;

function TScriptLightSpecials.Flicker(const ATag, AUpper, ALower: Integer): Boolean;
begin
  Result := Start(slkFlicker, ATag, AUpper, ALower, 0, 0);
end;

function TScriptLightSpecials.ForceLightning: Boolean;
begin
  Specials.ForceLightning(0);
  Result := True;
end;

function TScriptLightSpecials.ForceLightningTics(const ATics: Integer): Boolean;
begin
  Specials.ForceLightning(ATics);
  Result := True;
end;

function TScriptLightSpecials.Glow(const ATag, AUpper, ALower, ATics: Integer): Boolean;
begin
  Result := Start(slkGlow, ATag, AUpper, ALower, ATics, 0);
end;

function TScriptLightSpecials.LowerByValue(const ATag, AValue: Integer): Boolean;
begin
  Result := Start(slkLowerByValue, ATag, AValue, 0, 0, 0);
end;

function TScriptLightSpecials.MaxNeighbor(const ATag: Integer): Boolean;
begin
  Result := Start(slkMaxNeighbor, ATag, 0, 0, 0, 0);
end;

function TScriptLightSpecials.MinNeighbor(const ATag: Integer): Boolean;
begin
  Result := Start(slkMinNeighbor, ATag, 0, 0, 0, 0);
end;

function TScriptLightSpecials.RaiseByValue(const ATag, AValue: Integer): Boolean;
begin
  Result := Start(slkRaiseByValue, ATag, 0, 0, 0, 0);
end;

function TScriptLightSpecials.Strobe(const ATag, AUpper, ALower, AUpperTics, ALowerTics: Integer): Boolean;
begin
  Result := Start(slkStrobe, ATag, AUpper, ALower, AUpperTics, ALowerTics);
end;

function TScriptLightSpecials.StrobeDoom(const ATag, AUpperTics, ALowerTics: Integer): Boolean;
begin
  Result := Start(slkStrobeDoom, ATag, AUpperTics, ALowerTics, 0, 0);
end;

end.
