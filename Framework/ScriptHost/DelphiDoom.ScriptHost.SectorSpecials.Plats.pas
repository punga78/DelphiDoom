{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the platform specials of the scripts              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The Plat_* functions of the scripts (PS_Plat_* of psi_map.pas).             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.SectorSpecials.Plats;

interface

uses
  DelphiDoom.ScriptHost.SectorSpecials.Base,
  DelphiDoom.ScriptHost.SectorSpecials.Types;

type
  /// <summary>The platforms that a script can start</summary>
  TScriptPlatSpecials = class(TScriptSectorSpecialsBase)
  strict private
    function Start(const AKind: TScriptPlatKind; const ATag, ASpeed, ADelay, AFourth: Integer): Boolean;
  public
    function DownByValue(const ATag, ASpeed, ADelay, AHeight: Integer): Boolean;
    function DownWaitUpStay(const ATag, ASpeed, ADelay: Integer): Boolean;
    function DownWaitUpStayLip(const ATag, ASpeed, ADelay, ALip: Integer): Boolean;
    function PerpetualRaise(const ATag, ASpeed, ADelay: Integer): Boolean;
    function PerpetualRaiseLip(const ATag, ASpeed, ADelay, ALip: Integer): Boolean;
    function UpByValue(const ATag, ASpeed, ADelay, AHeight: Integer): Boolean;
    function UpNearestWaitDownStay(const ATag, ASpeed, ADelay: Integer): Boolean;
    function UpWaitDownStay(const ATag, ASpeed, ADelay: Integer): Boolean;
  end;

implementation

{ TScriptPlatSpecials }

function TScriptPlatSpecials.Start(const AKind: TScriptPlatKind; const ATag, ASpeed, ADelay,
  AFourth: Integer): Boolean;
var
  LArguments: TScriptSpecialArguments;
begin
  LArguments := NewArguments;
  SetByte(LArguments, 0, ATag);
  SetByte(LArguments, 1, ASpeed);
  SetByte(LArguments, 2, ADelay);
  SetByte(LArguments, 3, AFourth);
  Result := Specials.DoPlat(LArguments, AKind);
end;

function TScriptPlatSpecials.DownByValue(const ATag, ASpeed, ADelay, AHeight: Integer): Boolean;
begin
  Result := Start(spkDownByValueWaitUpStay, ATag, ASpeed, ADelay, AHeight);
end;

function TScriptPlatSpecials.DownWaitUpStay(const ATag, ASpeed, ADelay: Integer): Boolean;
begin
  Result := Start(spkDownWaitUpStay, ATag, ASpeed, ADelay, 0);
end;

function TScriptPlatSpecials.DownWaitUpStayLip(const ATag, ASpeed, ADelay, ALip: Integer): Boolean;
begin
  Result := Start(spkDownWaitUpStayLip, ATag, ASpeed, ADelay, ALip);
end;

function TScriptPlatSpecials.PerpetualRaise(const ATag, ASpeed, ADelay: Integer): Boolean;
begin
  Result := Start(spkPerpetualRaise, ATag, ASpeed, ADelay, 0);
end;

function TScriptPlatSpecials.PerpetualRaiseLip(const ATag, ASpeed, ADelay, ALip: Integer): Boolean;
begin
  Result := Start(spkPerpetualRaiseLip, ATag, ASpeed, ADelay, ALip);
end;

function TScriptPlatSpecials.UpByValue(const ATag, ASpeed, ADelay, AHeight: Integer): Boolean;
begin
  Result := Start(spkUpByValueWaitDownStay, ATag, ASpeed, ADelay, AHeight);
end;

function TScriptPlatSpecials.UpNearestWaitDownStay(const ATag, ASpeed, ADelay: Integer): Boolean;
begin
  Result := Start(spkUpNearestWaitDownStay, ATag, ASpeed, ADelay, 0);
end;

function TScriptPlatSpecials.UpWaitDownStay(const ATag, ASpeed, ADelay: Integer): Boolean;
begin
  Result := Start(spkUpWaitDownStay, ATag, ASpeed, ADelay, 0);
end;

end.
