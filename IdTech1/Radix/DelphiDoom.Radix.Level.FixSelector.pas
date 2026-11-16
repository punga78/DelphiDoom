{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixLevelFixSelector                          }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Level.FixSelector;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Level.Intf;

type
  /// <summary>Chooses the corrections by the version that the checksum of the level says</summary>
  TRadixLevelFixSelector = class(TInterfacedObject, IRadixLevelFixSelector)
  public
    function Select(const AName: string; ACrc: Cardinal): IRadixLevelFix;
  end;

implementation

uses
  DelphiDoom.Radix.Level.Versions, DelphiDoom.Radix.Level.FixNone, DelphiDoom.Radix.Level.FixV10,
  DelphiDoom.Radix.Level.FixV11, DelphiDoom.Radix.Level.FixV2;

{ TRadixLevelFixSelector }

function TRadixLevelFixSelector.Select(const AName: string; ACrc: Cardinal): IRadixLevelFix;
begin
  case TRadixLevelVersions.Identify(AName, ACrc) of
    rlvV2: Result := TRadixLevelFixV2.Create;
    rlvV11: Result := TRadixLevelFixV11.Create;
    rlvV10: Result := TRadixLevelFixV10.Create;
  else
    Result := TRadixLevelFixNone.Create;
  end;
end;

end.
