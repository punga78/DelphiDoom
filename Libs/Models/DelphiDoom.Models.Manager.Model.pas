{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - a model of the manager                      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): renderer\Model_local.h   }
{  and Model.cpp (idRenderModelStatic: InitEmpty, InitFromFile, PurgeModel,    }
{  LoadModel). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media        }
{  company. This unit is derived from the Doom 3 GPL source code and is        }
{  therefore available under the GNU General Public License, version 3, with   }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Manager.Model;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Static.Intf,
  DelphiDoom.Models.Manager.Intf;

type
  /// <summary>
  ///   A model that the manager keeps: the name, the data a loader gave and the flags of a
  ///   level load. A model made by hand (the default, beam and sprite models, the stand-in for an
  ///   unknown type) has no loader: it is not reloadable and a purge does not remove it.
  /// </summary>
  TRenderModel = class(TInterfacedObject, IRenderModel)
  strict private
    FName: AnsiString;
    FKind: TRenderModelKind;
    FLoader: IRenderModelLoader;
    FData: TRenderModelData;
    FFixed: IStaticModel;
    FDefaulted: Boolean;
    FLoaded: Boolean;
    FLevelLoadReferenced: Boolean;
  public
    /// <summary>A model made by hand: no loader; AStatic is its data (nil for beam and sprite)</summary>
    constructor CreateFixed(const AName: AnsiString; const AKind: TRenderModelKind; const AStatic: IStaticModel;
      const ADefaulted: Boolean);
    /// <summary>A model read from a file: it is loaded at once (InitFromFile)</summary>
    constructor Create(const AName: AnsiString; const ALoader: IRenderModelLoader);
    function GetName: AnsiString;
    function GetKind: TRenderModelKind;
    function GetStatic: IStaticModel;
    function GetMd5: IMd5Model;
    function GetIsDefaultModel: Boolean;
    function GetIsLoaded: Boolean;
    function GetIsReloadable: Boolean;
    function GetTimeStamp: Int64;
    function GetLevelLoadReferenced: Boolean;
    procedure SetLevelLoadReferenced(const AValue: Boolean);
    procedure LoadModel;
    procedure PurgeModel;
  end;

implementation

{ TRenderModel }

constructor TRenderModel.CreateFixed(const AName: AnsiString; const AKind: TRenderModelKind;
  const AStatic: IStaticModel; const ADefaulted: Boolean);
begin
  inherited Create;
  FName := AName;
  FKind := AKind;
  FFixed := AStatic;
  FDefaulted := ADefaulted;
  FLoaded := True;
end;

constructor TRenderModel.Create(const AName: AnsiString; const ALoader: IRenderModelLoader);
begin
  inherited Create;
  FName := AName;
  FKind := ALoader.Kind;
  FLoader := ALoader;
  LoadModel;
end;

function TRenderModel.GetName: AnsiString;
begin
  Result := FName;
end;

function TRenderModel.GetKind: TRenderModelKind;
begin
  Result := FKind;
end;

function TRenderModel.GetStatic: IStaticModel;
begin
  if not FLoaded then
    Result := nil
  else if Assigned(FLoader) then
    Result := FData.Static
  else
    Result := FFixed;
end;

function TRenderModel.GetMd5: IMd5Model;
begin
  if FLoaded and Assigned(FLoader) then
    Result := FData.Md5
  else
    Result := nil;
end;

function TRenderModel.GetIsDefaultModel: Boolean;
begin
  if Assigned(FLoader) then
    Result := FData.Defaulted
  else
    Result := FDefaulted;
end;

function TRenderModel.GetIsLoaded: Boolean;
begin
  Result := FLoaded;
end;

function TRenderModel.GetIsReloadable: Boolean;
begin
  Result := Assigned(FLoader);
end;

function TRenderModel.GetTimeStamp: Int64;
begin
  if Assigned(FLoader) then
    Result := FData.TimeStamp
  else
    Result := 0;
end;

function TRenderModel.GetLevelLoadReferenced: Boolean;
begin
  Result := FLevelLoadReferenced;
end;

procedure TRenderModel.SetLevelLoadReferenced(const AValue: Boolean);
begin
  FLevelLoadReferenced := AValue;
end;

procedure TRenderModel.LoadModel;
begin
  if not Assigned(FLoader) then
    Exit;
  FData := FLoader.Load(FName);
  FLoaded := True;
end;

procedure TRenderModel.PurgeModel;
begin
  if not Assigned(FLoader) then
    Exit;
  FData := Default(TRenderModelData);
  FLoaded := False;
end;

end.
