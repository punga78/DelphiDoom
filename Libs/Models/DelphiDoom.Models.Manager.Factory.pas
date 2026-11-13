{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the model manager: the factory              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Manager.Factory;

interface

uses
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Models.Source.Intf,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Ase.Types,
  DelphiDoom.Models.Static.MaterialInfo.Intf,
  DelphiDoom.Models.Anim.Intf,
  DelphiDoom.Models.Manager.Intf,
  DelphiDoom.Models.Manager.DefSource;

type
  /// <summary>The only place that knows the classes behind the contracts of the model manager</summary>
  TRenderModelManagerFactory = class
  public
    /// <summary>An empty table of loaders</summary>
    class function CreateLoaderTable: IRenderModelLoaderTable; static;
    /// <summary>
    ///   The table with the formats of the library: ase, lwo, ma and md3 as static models (the
    ///   resolver names the pictures, the materials answer for two sided and unsmoothed
    ///   surfaces, nil for none) and md5mesh. prt, liquid and flt are not read here.
    /// </summary>
    class function CreateStandardLoaders(const ASource: IModelFileSource; const AOptions: TStaticLoadOptions;
      const AResolver: TStaticPathResolver; const AMaterials: IStaticMaterialInfo;
      const ALog: IIdLibLog): IRenderModelLoaderTable; static;
    /// <summary>The manager (call Init before use)</summary>
    class function CreateManager(const ASource: IModelFileSource; const ALoaders: IRenderModelLoaderTable;
      const ALog: IIdLibLog): IRenderModelManager; static;
    /// <summary>The models of a MODELDEF from the manager; the finder gives the definitions to inherit (may be nil)</summary>
    class function CreateModelDefSource(const AManager: IRenderModelManager;
      const AFinder: TModelDefFinder): IModelDefSource; static;
  end;

implementation

uses
  DelphiDoom.Models.Md5.Factory,
  DelphiDoom.Models.Manager.LoaderTable,
  DelphiDoom.Models.Manager.StaticLoader,
  DelphiDoom.Models.Manager.Md5Loader,
  DelphiDoom.Models.Manager.Manager;

{ TRenderModelManagerFactory }

class function TRenderModelManagerFactory.CreateLoaderTable: IRenderModelLoaderTable;
begin
  Result := TRenderModelLoaderTable.Create;
end;

class function TRenderModelManagerFactory.CreateStandardLoaders(const ASource: IModelFileSource;
  const AOptions: TStaticLoadOptions; const AResolver: TStaticPathResolver; const AMaterials: IStaticMaterialInfo;
  const ALog: IIdLibLog): IRenderModelLoaderTable;
var
  LStatic: IRenderModelLoader;
begin
  Result := CreateLoaderTable;
  LStatic := TStaticRenderModelLoader.Create(ASource, AOptions, AResolver, AMaterials, ALog);
  Result.Register('ase', LStatic);
  Result.Register('lwo', LStatic);
  Result.Register('ma', LStatic);
  Result.Register('md3', LStatic);
  Result.Register('md5mesh', TMd5RenderModelLoader.Create(ASource, TMd5Factory.CreateModelParser, ALog));
end;

class function TRenderModelManagerFactory.CreateManager(const ASource: IModelFileSource;
  const ALoaders: IRenderModelLoaderTable; const ALog: IIdLibLog): IRenderModelManager;
begin
  Result := TRenderModelManager.Create(ASource, ALoaders, ALog);
end;

class function TRenderModelManagerFactory.CreateModelDefSource(const AManager: IRenderModelManager;
  const AFinder: TModelDefFinder): IModelDefSource;
begin
  Result := TRenderModelDefSource.Create(AManager, AFinder);
end;

end.
