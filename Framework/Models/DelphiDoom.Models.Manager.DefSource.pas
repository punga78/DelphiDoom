{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the models of a MODELDEF come from the      }
{  model manager                                                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Manager.DefSource;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Anim.Intf,
  DelphiDoom.Models.Manager.Intf;

type
  /// <summary>A function that finds a definition by its name (the declaration manager of the game)</summary>
  TModelDefFinder = reference to function(const AName: AnsiString; out ADefaulted: Boolean): IModelDef;

  /// <summary>
  ///   What <c>idDeclModelDef::Parse</c> asks for models: <c>renderModelManager->FindModel</c> for
  ///   the md5mesh of <c>mesh</c>, and the declaration manager (the finder given) for the
  ///   definition of <c>inherit</c>. Without a finder no definition is known.
  /// </summary>
  TRenderModelDefSource = class(TInterfacedObject, IModelDefSource)
  strict private
    FManager: IRenderModelManager;
    FFinder: TModelDefFinder;
  public
    constructor Create(const AManager: IRenderModelManager; const AFinder: TModelDefFinder);
    function FindMd5Model(const AName: AnsiString; out ADefaulted: Boolean): IMd5Model;
    function FindModelDef(const AName: AnsiString; out ADefaulted: Boolean): IModelDef;
  end;

implementation

{ TRenderModelDefSource }

constructor TRenderModelDefSource.Create(const AManager: IRenderModelManager; const AFinder: TModelDefFinder);
begin
  inherited Create;
  FManager := AManager;
  FFinder := AFinder;
end;

function TRenderModelDefSource.FindMd5Model(const AName: AnsiString; out ADefaulted: Boolean): IMd5Model;
var
  LModel: IRenderModel;
begin
  Result := nil;
  ADefaulted := False;
  LModel := FManager.FindModel(AName);
  if LModel = nil then
    Exit;
  ADefaulted := LModel.IsDefaultModel;
  if not ADefaulted then
    Result := LModel.Md5;
end;

function TRenderModelDefSource.FindModelDef(const AName: AnsiString; out ADefaulted: Boolean): IModelDef;
begin
  ADefaulted := False;
  if Assigned(FFinder) then
    Result := FFinder(AName, ADefaulted)
  else
    Result := nil;
end;

end.
