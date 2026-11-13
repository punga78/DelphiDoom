{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the model manager: loader of static models  }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model.cpp       }
{  (idRenderModelStatic::InitFromFile, LoadASE, LoadLWO, LoadMA).              }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company. This unit }
{  is derived from the Doom 3 GPL source code and is therefore available       }
{  under the GNU General Public License, version 3, with the additional terms  }
{  of the Doom 3 Source Code License (see README.md of Libs\IdLib); the        }
{  repository as a whole is GPL v2 or later.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Manager.StaticLoader;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Models.Source.Intf,
  DelphiDoom.Models.Static.Types,
  DelphiDoom.Models.Static.Ase.Types,
  DelphiDoom.Models.Static.MaterialInfo.Intf,
  DelphiDoom.Models.Manager.Intf;

type
  /// <summary>
  ///   Loads ASE, LWO, MA and MD3 files as static models: the bytes come from the file source,
  ///   the format is chosen by the extension, the surfaces are finished (cleaned, normals and
  ///   tangents derived). A file that is missing, damaged or of a format the loaders do not
  ///   read gives the default cube and a warning, as InitFromFile does.
  /// </summary>
  TStaticRenderModelLoader = class(TInterfacedObject, IRenderModelLoader)
  strict private
    FSource: IModelFileSource;
    FOptions: TStaticLoadOptions;
    FResolver: TStaticPathResolver;
    FMaterials: IStaticMaterialInfo;
    FLog: IIdLibLog;
    function MakeDefaulted(const AName: AnsiString): TRenderModelData;
  public
    /// <summary>
    ///   The resolver names the pictures of ASE and MA materials, the materials answer for the
    ///   two sided and unsmoothed surfaces; the log gets the warnings. All optional except the source.
    /// </summary>
    constructor Create(const ASource: IModelFileSource; const AOptions: TStaticLoadOptions;
      const AResolver: TStaticPathResolver; const AMaterials: IStaticMaterialInfo; const ALog: IIdLibLog);
    function GetKind: TRenderModelKind;
    function Load(const AName: AnsiString): TRenderModelData;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Static.Factory,
  DelphiDoom.Models.Static.DefaultModel,
  DelphiDoom.Models.Static.ModelFinisher;

{ TStaticRenderModelLoader }

constructor TStaticRenderModelLoader.Create(const ASource: IModelFileSource; const AOptions: TStaticLoadOptions;
  const AResolver: TStaticPathResolver; const AMaterials: IStaticMaterialInfo; const ALog: IIdLibLog);
begin
  inherited Create;
  FSource := ASource;
  FOptions := AOptions;
  FResolver := AResolver;
  FMaterials := AMaterials;
  FLog := ALog;
end;

function TStaticRenderModelLoader.GetKind: TRenderModelKind;
begin
  Result := rmkStatic;
end;

function TStaticRenderModelLoader.MakeDefaulted(const AName: AnsiString): TRenderModelData;
begin
  if Assigned(FLog) then
    FLog.Warning(Format('Couldn''t load model: ''%s''', [string(AName)]));
  Result := Default(TRenderModelData);
  Result.Static := TStaticDefaultModel.Build(string(AName));
  Result.Defaulted := True;
end;

function TStaticRenderModelLoader.Load(const AName: AnsiString): TRenderModelData;
var
  LData: AnsiString;
  LTimeStamp: Int64;
  LBytes: TBytes;
  LExtension: string;
  LLoader: IStaticModelLoader;
  LModel: IStaticModel;
  LWarning: string;
begin
  if not FSource.ReadFile(AName, LData, LTimeStamp) then
    Exit(MakeDefaulted(AName));
  LExtension := LowerCase(ExtractFileExt(string(AName)));
  if LExtension = '.ase' then
    LLoader := TStaticModelFactory.CreateAseLoader(FOptions, FResolver)
  else if LExtension = '.ma' then
    LLoader := TStaticModelFactory.CreateMaLoader(FOptions, FResolver)
  else
    LLoader := TStaticModelFactory.CreateLoaderFor(string(AName), FOptions);
  if LLoader = nil then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format('idRenderModelStatic::InitFromFile: unknown type for model: ''%s''', [string(AName)]));
    Exit(MakeDefaulted(AName));
  end;
  SetLength(LBytes, Length(LData));
  if Length(LData) > 0 then
    Move(LData[1], LBytes[0], Length(LData));
  try
    LModel := LLoader.Load(LBytes, string(AName));
    if Assigned(FLog) then
      for LWarning in LModel.Warnings do
        FLog.Warning(LWarning);
    LModel := TStaticModelFinisher.Finish(LModel, FMaterials, FOptions.FastLoad);
  except
    on E: EStaticModelException do
    begin
      if Assigned(FLog) then
        FLog.Warning(E.Message);
      Exit(MakeDefaulted(AName));
    end;
    on E: EIdLibException do
    begin
      if Assigned(FLog) then
        FLog.Warning(E.Message);
      Exit(MakeDefaulted(AName));
    end;
  end;
  Result := Default(TRenderModelData);
  Result.Static := LModel;
  Result.TimeStamp := LTimeStamp;
end;

end.
