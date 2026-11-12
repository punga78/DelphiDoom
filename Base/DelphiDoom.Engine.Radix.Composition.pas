{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - composition of the Radix game                          }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Radix.Composition;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Engine.Wad.Lumps.Intf;

/// <summary>
///   The part of the composition root that only the Radix game has: ComposeEngine calls it (under
///   the define RADIX) where the WAD services are given to w_wad.pas. It builds the converter of
///   RADIX.DAT, which also tells the release of the file, and the table of the names of RADIX.DAT,
///   and gives them to the historical units (W_ConfigureConverter, W_ConfigureAliases,
///   RX_ConfigureVersion)
/// </summary>
procedure ComposeRadix(const ALog: ILog; const ALumps: IEngineLumps);

implementation

uses
  System.SysUtils,
  DelphiDoom.Radix.Intf, DelphiDoom.Radix.Factory,
  DelphiDoom.Engine.Wad.Converter.Intf, DelphiDoom.Engine.Wad.Aliases.Intf,
  DelphiDoom.Engine.Radix.Edition.Intf, DelphiDoom.Engine.Radix.DataConverter,
  DelphiDoom.Engine.Radix.LumpAliases,
  w_wad, radix_version;

procedure ComposeRadix(const ALog: ILog; const ALumps: IEngineLumps);
var
  LConverter: IEngineWadConverter;
  LAliases: IEngineLumpAliases;
begin
  LConverter := TEngineRadixDataConverter.Create(ALog);
  W_ConfigureConverter(LConverter);
  RX_ConfigureVersion(LConverter as IEngineRadixEdition);

  LAliases := TEngineRadixLumpAliases.Create(ALumps,
    function: IRadixLumpAliases
    begin
      Result := TRadixFactory.CreateLumpAliases;
    end);
  W_ConfigureAliases(LAliases);
end;

end.
