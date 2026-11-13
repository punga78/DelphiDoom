{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the model manager: loader of md5mesh files  }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_md5.cpp   }
{  (idRenderModelMD5::InitFromFile). Copyright (C) 1999-2011 id Software LLC,  }
{  a ZeniMax Media company. This unit is derived from the Doom 3 GPL source    }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Libs\IdLib); the repository as a whole is GPL v2 or       }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Manager.Md5Loader;

interface

uses
  System.SysUtils,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Models.Source.Intf,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Manager.Intf;

type
  /// <summary>
  ///   Loads md5mesh files. The original does not default an md5 model (a damaged file is a
  ///   fatal error of the engine): here the file that is missing or damaged is a warning and
  ///   the data is marked as defaulted, with the default cube as its surfaces, so that a
  ///   definition that uses it can say so ("Model defaulted").
  /// </summary>
  TMd5RenderModelLoader = class(TInterfacedObject, IRenderModelLoader)
  strict private
    FSource: IModelFileSource;
    FParser: IMd5ModelParser;
    FLog: IIdLibLog;
    function MakeDefaulted(const AName: AnsiString; const AReason: string): TRenderModelData;
  public
    /// <summary>The log is optional</summary>
    constructor Create(const ASource: IModelFileSource; const AParser: IMd5ModelParser; const ALog: IIdLibLog);
    function GetKind: TRenderModelKind;
    function Load(const AName: AnsiString): TRenderModelData;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Exceptions,
  DelphiDoom.Models.Types,
  DelphiDoom.Models.Static.DefaultModel;

{ TMd5RenderModelLoader }

constructor TMd5RenderModelLoader.Create(const ASource: IModelFileSource; const AParser: IMd5ModelParser;
  const ALog: IIdLibLog);
begin
  inherited Create;
  FSource := ASource;
  FParser := AParser;
  FLog := ALog;
end;

function TMd5RenderModelLoader.GetKind: TRenderModelKind;
begin
  Result := rmkMd5;
end;

function TMd5RenderModelLoader.MakeDefaulted(const AName: AnsiString; const AReason: string): TRenderModelData;
begin
  if Assigned(FLog) then
    FLog.Warning(Format('Couldn''t load model: ''%s'' (%s)', [string(AName), AReason]));
  Result := Default(TRenderModelData);
  Result.Static := TStaticDefaultModel.Build(string(AName));
  Result.Defaulted := True;
end;

function TMd5RenderModelLoader.Load(const AName: AnsiString): TRenderModelData;
var
  LData: AnsiString;
  LTimeStamp: Int64;
begin
  if not FSource.ReadFile(AName, LData, LTimeStamp) then
    Exit(MakeDefaulted(AName, 'file not found'));
  try
    Result := Default(TRenderModelData);
    Result.Md5 := FParser.Parse(LData, AName);
    Result.TimeStamp := LTimeStamp;
  except
    on E: EIdLibException do
      Exit(MakeDefaulted(AName, E.Message));
    on E: EModelsException do
      Exit(MakeDefaulted(AName, E.Message));
  end;
end;

end.
