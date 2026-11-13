{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the model of a .proc file                    }
{                                                                              }
{  Model of what idRenderWorldLocal::InitFromMap reads (RenderWorld_load.cpp), }
{  Doom 3 GPL Source Code.                                                     }
{  Based on the Doom 3 GPL Source Code (id Software). Copyright (C) 1999-2011  }
{  id Software LLC, a ZeniMax Media company. This unit is derived from the     }
{  Doom 3 GPL source code and is therefore available under the GNU General     }
{  Public License, version 3, with the additional terms of the Doom 3 Source   }
{  Code License (see README.md of Libs\IdLib); the repository as a whole is    }
{  GPL v2 or later.                                                            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Proc.ProcFile;

interface

uses
  System.Generics.Collections, DelphiDoom.MapFile.Proc.Types, DelphiDoom.MapFile.Proc.Model,
  DelphiDoom.MapFile.Proc.ShadowModel, DelphiDoom.MapFile.Proc.Portal;

type
  /// <summary>
  ///   The content of a .proc file: the models and the shadow models (the original keeps one
  ///   list; here the two kinds are apart and each keeps the order of the file), the number of
  ///   areas and the portals of the "interAreaPortals" section, and the "nodes" section. All
  ///   the objects belong to the file. A file without "interAreaPortals" is a world of a single
  ///   area for the renderer: <c>HasPortalSection</c> and <c>HasNodeSection</c> tell whether the
  ///   sections were there
  /// </summary>
  TProcFile = class
  strict private
    FName: AnsiString;
    FModels: TObjectList<TProcModel>;
    FShadowModels: TObjectList<TProcShadowModel>;
    FPortals: TObjectList<TProcPortal>;
    FNodes: TList<TProcNode>;
    FNumAreas: Integer;
    FHasPortalSection: Boolean;
    FHasNodeSection: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    property Name: AnsiString read FName write FName;
    property Models: TObjectList<TProcModel> read FModels;
    property ShadowModels: TObjectList<TProcShadowModel> read FShadowModels;
    property Portals: TObjectList<TProcPortal> read FPortals;
    property Nodes: TList<TProcNode> read FNodes;
    /// <summary>numPortalAreas</summary>
    property NumAreas: Integer read FNumAreas write FNumAreas;
    property HasPortalSection: Boolean read FHasPortalSection write FHasPortalSection;
    property HasNodeSection: Boolean read FHasNodeSection write FHasNodeSection;
    /// <summary>The model with the name, compared without regard to case (the model manager does so); nil if none</summary>
    function FindModel(const AName: AnsiString): TProcModel;
    function FindShadowModel(const AName: AnsiString): TProcShadowModel;
  end;

implementation

uses
  System.SysUtils;

{ TProcFile }

constructor TProcFile.Create;
begin
  inherited Create;
  FModels := TObjectList<TProcModel>.Create(True);
  FShadowModels := TObjectList<TProcShadowModel>.Create(True);
  FPortals := TObjectList<TProcPortal>.Create(True);
  FNodes := TList<TProcNode>.Create;
end;

destructor TProcFile.Destroy;
begin
  FNodes.Free;
  FPortals.Free;
  FShadowModels.Free;
  FModels.Free;
  inherited Destroy;
end;

function TProcFile.FindModel(const AName: AnsiString): TProcModel;
var
  LModel: TProcModel;
begin
  for LModel in FModels do
    if SameText(string(LModel.Name), string(AName)) then
      Exit(LModel);
  Result := nil;
end;

function TProcFile.FindShadowModel(const AName: AnsiString): TProcShadowModel;
var
  LModel: TProcShadowModel;
begin
  for LModel in FShadowModels do
    if SameText(string(LModel.Name), string(AName)) then
      Exit(LModel);
  Result := nil;
end;

end.
