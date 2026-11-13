{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound - the engine in Pascal as the provider's default          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.EngineFactory;

interface

uses
  DelphiDoom.Sndfile.Intf, DelphiDoom.Sndfile.Factory.Intf;

type
  /// <summary>
  ///   ISndfileFactory over TSoundFactory: the decoders in Pascal with all the formats
  /// </summary>
  TSoundEngineFactory = class(TInterfacedObject, ISndfileFactory)
  public
    function CreateEngine: ISndfile;
  end;

implementation

uses
  DelphiDoom.Sndfile.Provider, DelphiDoom.Sound.Factory;

{ TSoundEngineFactory }

function TSoundEngineFactory.CreateEngine: ISndfile;
begin
  Result := TSoundFactory.CreateEngine;
end;

initialization
  // Sound depends on Sndfile (never the opposite): linking this unit makes the
  // Pascal engine the default of the provider, as it was before the split
  TSndfileProvider.UseFactory(TSoundEngineFactory.Create);

end.