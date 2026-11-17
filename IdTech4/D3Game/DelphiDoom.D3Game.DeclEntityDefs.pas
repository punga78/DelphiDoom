{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the entityDefs of the declaration manager }
{                                                                              }
{  Written for this repository (the game of the original reaches declManager   }
{  through a global: here it is an adapter over IDeclManager).                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.DeclEntityDefs;

interface

uses
  System.SysUtils, DelphiDoom.Decl.Intf, DelphiDoom.D3Game.Intf;

type
  /// <summary>
  ///   <c>ID3EntityDefs</c> over the declaration manager: <c>FindType( DECL_ENTITYDEF, name, false )</c> and
  ///   <c>DeclByIndex( DECL_ENTITYDEF, index, false )</c>. The manager owns the declarations; the entityDefs given out
  ///   only hold the declaration.
  /// </summary>
  TD3DeclEntityDefs = class(TInterfacedObject, ID3EntityDefs)
  strict private
    FManager: IDeclManager;
    function Wrap(const ADecl: IDecl): ID3EntityDef;
  public
    constructor Create(const AManager: IDeclManager);
    function FindEntityDef(const AName: AnsiString): ID3EntityDef;
    function FindEntityDefByIndex(const AIndex: Integer): ID3EntityDef;
  end;

implementation

uses
  DelphiDoom.Scanner.IdDict, DelphiDoom.Decl.Types, DelphiDoom.Decl.EntityDef;

type
  /// <summary>An <c>idDeclEntityDef</c> as the game sees it: name, index and the dictionary of defaults</summary>
  TD3DeclEntityDef = class(TInterfacedObject, ID3EntityDef)
  strict private
    FDecl: IDecl;
    FEntityDef: IDeclEntityDef;
  public
    constructor Create(const ADecl: IDecl; const AEntityDef: IDeclEntityDef);
    function GetName: AnsiString;
    function GetIndex: Integer;
    function GetDict: TIdDict;
  end;

{ TD3DeclEntityDef }

constructor TD3DeclEntityDef.Create(const ADecl: IDecl; const AEntityDef: IDeclEntityDef);
begin
  inherited Create;
  FDecl := ADecl;
  FEntityDef := AEntityDef;
end;

function TD3DeclEntityDef.GetName: AnsiString;
begin
  Result := FDecl.GetName;
end;

function TD3DeclEntityDef.GetIndex: Integer;
begin
  Result := FDecl.GetIndex;
end;

function TD3DeclEntityDef.GetDict: TIdDict;
begin
  Result := FEntityDef.GetDict;
end;

{ TD3DeclEntityDefs }

constructor TD3DeclEntityDefs.Create(const AManager: IDeclManager);
begin
  inherited Create;
  FManager := AManager;
end;

function TD3DeclEntityDefs.Wrap(const ADecl: IDecl): ID3EntityDef;
var
  LEntityDef: IDeclEntityDef;
begin
  if Assigned(ADecl) and Supports(ADecl, IDeclEntityDef, LEntityDef) then
    Result := TD3DeclEntityDef.Create(ADecl, LEntityDef)
  else
    Result := nil;
end;

function TD3DeclEntityDefs.FindEntityDef(const AName: AnsiString): ID3EntityDef;
begin
  Result := Wrap(FManager.FindType(DECL_ENTITYDEF, AName, False));
end;

function TD3DeclEntityDefs.FindEntityDefByIndex(const AIndex: Integer): ID3EntityDef;
begin
  Result := Wrap(FManager.DeclByIndex(DECL_ENTITYDEF, AIndex, False));
end;

end.
