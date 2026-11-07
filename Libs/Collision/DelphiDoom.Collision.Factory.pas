{******************************************************************************}
{                                                                              }
{  DelphiDoom: collision library - the factory                                 }
{                                                                              }
{  Derived from Doom 3 GPL Source Code (Copyright (C) 1999-2011 id Software    }
{  LLC, a ZeniMax Media company; GPL v3 with additional terms). Delphi         }
{  composition code, GPL v3 as the work it belongs to.                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Collision.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Collision.Intf, DelphiDoom.Collision.Builder;

type
  /// <summary>The only place that knows the concrete classes of the collision library</summary>
  TCollisionFactory = class sealed
  public
    /// <summary>A manager with no model; ALog may be nil</summary>
    class function CreateManager(const ACatalog: ICollisionMaterialCatalog;
      const ALog: ILog): ICollisionModelManager; static;
    /// <summary>A builder of models from brushes and polygons; ALog may be nil. The caller frees it</summary>
    class function CreateBuilder(const ALog: ILog): TCollisionModelBuilder; static;
  end;

implementation

uses
  DelphiDoom.Collision.Manager;

{ TCollisionFactory }

class function TCollisionFactory.CreateManager(const ACatalog: ICollisionMaterialCatalog;
  const ALog: ILog): ICollisionModelManager;
begin
  Result := TCollisionModelManager.Create(ACatalog, ALog);
end;

class function TCollisionFactory.CreateBuilder(const ALog: ILog): TCollisionModelBuilder;
begin
  Result := TCollisionModelBuilder.Create(ALog);
end;

end.
