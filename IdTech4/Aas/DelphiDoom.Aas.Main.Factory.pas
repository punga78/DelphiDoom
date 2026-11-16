{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the factory of the AAS system                      }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Main.Factory;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Aas.Move.Intf,
  DelphiDoom.Aas.Route.Intf, DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Main.Intf, DelphiDoom.Aas.Main.System;

type
  /// <summary>
  ///   The composition root of the AAS system of Quake III: the one place that joins the reader, the reachability
  ///   calculation, the clustering, the routing and the entities. The game gives the BSP (the world and the models)
  /// </summary>
  TAasSystemFactory = class
  public
    /// <summary>
    ///   The AAS system (call Setup, then LoadMap and StartFrame); the caller frees it. The memory and the clock
    ///   may be nil. The files give the .aas, the variables give max_aaslinks, maxentities and the other settings
    /// </summary>
    class function CreateSystem(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVars;
      const AWorld: IAasBspWorld; const AModels: IAasBspModels; const AMemory: IAasRoutingMemory;
      const AClock: TAasMilliseconds; const ADeveloper: Boolean): TAasSystem; static;
  end;

implementation

uses
  DelphiDoom.Aas.Factory, DelphiDoom.Aas.Reach.Intf, DelphiDoom.Aas.Main.MapBuilder, DelphiDoom.Aas.Entity.Table;

class function TAasSystemFactory.CreateSystem(const AImport: IBotImport; const AFiles: IBotFileSource;
  const ALibVars: IBotLibVars; const AWorld: IAasBspWorld; const AModels: IAasBspModels;
  const AMemory: IAasRoutingMemory; const AClock: TAasMilliseconds; const ADeveloper: Boolean): TAasSystem;
var
  LBuilder: TAasMapBuilder;
  LBuilderIntf: IAasMapBuilder;
begin
  LBuilder := TAasMapBuilder.Create(AImport, ALibVars, AWorld, AModels, AMemory, AClock, ADeveloper);
  LBuilderIntf := LBuilder;
  // the system keeps the builder (an interface) and the functions only reach it through that reference
  Result := TAasSystem.Create(AImport, ALibVars, TAasFactory.CreateReader(AImport, AFiles, ALibVars), AModels,
    LBuilderIntf,
    function(const AHead: Integer): Integer
    begin
      Result := LBuilder.BestReachableLinkArea(AHead);
    end,
    function: IAasBestReachable
    begin
      Result := LBuilder.BestReachable;
    end, ADeveloper);
end;

end.
