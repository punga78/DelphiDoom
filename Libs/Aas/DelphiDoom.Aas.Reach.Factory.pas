{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the objects of the reachability calculation       }
{                                                                              }
{  Written for this library. Based on the Quake III Arena GPL Source Code (id  }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. Licensed under the     }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Factory;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Intf, DelphiDoom.Aas.Move.Types, DelphiDoom.Aas.Move.Intf,
  DelphiDoom.Aas.Bsp.Intf, DelphiDoom.Aas.Links, DelphiDoom.Aas.Reach.Types, DelphiDoom.Aas.Reach.Intf;

type
  /// <summary>Makes the objects of the reachability calculation; the rest of the code knows only the interfaces</summary>
  TAasReachFactory = class
  public
    class function CreateGeometry(const AFile: IAasFile): IAasReachGeometry; static;
    class function CreatePhysics(const ASettings: TAasMoveSettings): IAasReachPhysics; static;
    /// <summary>
    ///   The entities of the map, from the entity string of the BSP models (be_aas_bspq3.c AAS_ParseBSPEntities)
    /// </summary>
    class function CreateEntities(const AImport: IBotImport; const AModels: IAasBspModels): IAasBspEntities; static;
    /// <summary>
    ///   The calculation of the reachabilities of a file that can take them (TAasFile). The object also implements
    ///   <c>IAasBestReachable</c> (use Supports). The links are the entities linked to the areas, which the caller owns and
    ///   keeps alive as long as the object; the variables give grapplereach and forcereachability and may be nil; the
    ///   clock is Sys_MilliSeconds and may be nil
    /// </summary>
    class function CreateInitializer(const AFile: IAasFile; const ASampler: IAasSampler; const ATracer: IAasTracer;
      const AFaces: IAasFaceTester; const AMovement: IAasMovement; const AWorld: IAasBspWorld;
      const AModels: IAasBspModels; const AEntities: IAasBspEntities; const ALinks: TAasEntityLinks;
      const AImport: IBotImport; const ALibVars: IBotLibVars; const AClock: TAasMilliseconds = nil): IAasReachInitializer;
      static;
  end;

implementation

uses
  DelphiDoom.Aas.Bsp.Entities, DelphiDoom.Aas.Reach.Geometry, DelphiDoom.Aas.Reach.Physics,
  DelphiDoom.Aas.Reach.Calculator;

{ TAasReachFactory }

class function TAasReachFactory.CreateGeometry(const AFile: IAasFile): IAasReachGeometry;
begin
  Result := TAasReachGeometry.Create(AFile);
end;

class function TAasReachFactory.CreatePhysics(const ASettings: TAasMoveSettings): IAasReachPhysics;
begin
  Result := TAasReachPhysics.Create(ASettings);
end;

class function TAasReachFactory.CreateEntities(const AImport: IBotImport;
  const AModels: IAasBspModels): IAasBspEntities;
begin
  Result := TAasBspEntities.Create(AImport, AModels.EntityData);
end;

class function TAasReachFactory.CreateInitializer(const AFile: IAasFile; const ASampler: IAasSampler;
  const ATracer: IAasTracer; const AFaces: IAasFaceTester; const AMovement: IAasMovement; const AWorld: IAasBspWorld;
  const AModels: IAasBspModels; const AEntities: IAasBspEntities; const ALinks: TAasEntityLinks;
  const AImport: IBotImport; const ALibVars: IBotLibVars; const AClock: TAasMilliseconds): IAasReachInitializer;
begin
  Result := TAasReachCalculator.Create(AFile, ASampler, ATracer, AFaces, AMovement, AWorld, AModels, AEntities, ALinks,
    AImport, ALibVars, TAasReachFactory.CreateGeometry(AFile), TAasReachFactory.CreatePhysics(AMovement.Settings), AClock);
end;

end.
