{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - static models: the factory                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Static.Factory;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Ase.Types;

type
  /// <summary>The only place that knows the classes behind the contracts of the static models</summary>
  TStaticModelFactory = class
  public
    /// <summary>The loader of LightWave 6 objects (.lwo)</summary>
    class function CreateLwoLoader(const AOptions: TStaticLoadOptions): IStaticModelLoader; overload; static;
    class function CreateLwoLoader: IStaticModelLoader; overload; static;
    /// <summary>The loader of 3D Studio Max ASCII exports (.ase); the resolver names the materials</summary>
    class function CreateAseLoader(const AOptions: TStaticLoadOptions;
      const AResolver: TStaticPathResolver = nil): IStaticModelLoader; overload; static;
    class function CreateAseLoader: IStaticModelLoader; overload; static;
    /// <summary>The loader for a file name by its extension (.lwo, .ase); nil for the others</summary>
    class function CreateLoaderFor(const AFileName: string; const AOptions: TStaticLoadOptions): IStaticModelLoader; static;
  end;

implementation

uses
  DelphiDoom.Models.Static.Lwo.Loader,
  DelphiDoom.Models.Static.Ase.Loader;

{ TStaticModelFactory }

class function TStaticModelFactory.CreateLwoLoader(const AOptions: TStaticLoadOptions): IStaticModelLoader;
begin
  Result := TLwoModelLoader.Create(AOptions);
end;

class function TStaticModelFactory.CreateLwoLoader: IStaticModelLoader;
begin
  Result := CreateLwoLoader(TStaticLoadOptions.Default);
end;

class function TStaticModelFactory.CreateAseLoader(const AOptions: TStaticLoadOptions;
  const AResolver: TStaticPathResolver): IStaticModelLoader;
begin
  Result := TAseModelLoader.Create(AOptions, AResolver);
end;

class function TStaticModelFactory.CreateAseLoader: IStaticModelLoader;
begin
  Result := CreateAseLoader(TStaticLoadOptions.Default);
end;

class function TStaticModelFactory.CreateLoaderFor(const AFileName: string;
  const AOptions: TStaticLoadOptions): IStaticModelLoader;
var
  LExtension: string;
begin
  LExtension := ExtractFileExt(AFileName);
  if SameText(LExtension, '.lwo') then
    Result := CreateLwoLoader(AOptions)
  else if SameText(LExtension, '.ase') then
    Result := CreateAseLoader(AOptions)
  else
    Result := nil;
end;

end.
