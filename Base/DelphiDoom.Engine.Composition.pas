{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - composition root                                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Composition;

interface

/// <summary>
///   The one place that chooses the classes behind the interfaces of the engine and
///   gives them to the units that use them. Call it first thing in the program, before
///   anything opens a WAD or a PAK
/// </summary>
procedure ComposeEngine;

implementation

uses
  DelphiDoom.Configuration.Factory,
  DelphiDoom.CommandLine.Factory,
  DelphiDoom.IdTech.Intf,
  DelphiDoom.IdTech.Factory,
  DelphiDoom.Engine.Wad.Intf,
  DelphiDoom.Engine.Wad.Services,
  w_wad,
  w_wadreader,
  w_wadwriter,
  w_pak,
  doomdef,
  d_main,
  m_argv,
  m_misc;

procedure ComposeEngine;
var
  LWadServices: IEngineWadServices;
  LEngine: IIdTechEngine;
begin
  // DelphiDoom is a port of the Doom engine: id Tech 1, at the version of doomdef
  LEngine := TIdTechFactory.CreateDelphiDoom(VERSION);
  D_Configure(LEngine);
  M_ConfigureArgv(TCommandLineFactory.CreateBuilder);
  M_ConfigureDefaults(TConfigurationFactory.CreateFormat);

  LWadServices := TEngineWadServices.Create;
  W_Configure(LWadServices);
  TWadReader.Configure(LWadServices);
  TWadWriter.Configure(LWadServices);
  PAK_Configure(LWadServices);
end;

end.
