{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the model manager: table of loaders         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Manager.LoaderTable;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Models.Manager.Intf;

type
  /// <summary>
  ///   The loader of every extension of file that the manager reads (what the chain of
  ///   <c>if ( extension.Icmp( ... ) )</c> of <c>GetModel</c> is in the original): ase, lwo, ma
  ///   and md3 for the static models, md5mesh for the skeletal ones. A game adds the types the
  ///   library does not read (prt, liquid, flt) with <c>Register</c>.
  /// </summary>
  TRenderModelLoaderTable = class(TInterfacedObject, IRenderModelLoaderTable)
  strict private
    FLoaders: TDictionary<string, IRenderModelLoader>;
    class function Normalize(const AExtension: string): string; static;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Register(const AExtension: string; const ALoader: IRenderModelLoader);
    function Find(const AExtension: string): IRenderModelLoader;
  end;

implementation

{ TRenderModelLoaderTable }

constructor TRenderModelLoaderTable.Create;
begin
  inherited Create;
  FLoaders := TDictionary<string, IRenderModelLoader>.Create;
end;

destructor TRenderModelLoaderTable.Destroy;
begin
  FLoaders.Free;
  inherited Destroy;
end;

class function TRenderModelLoaderTable.Normalize(const AExtension: string): string;
begin
  Result := LowerCase(AExtension);
  if (Result <> '') and (Result[1] = '.') then
    Delete(Result, 1, 1);
end;

procedure TRenderModelLoaderTable.Register(const AExtension: string; const ALoader: IRenderModelLoader);
begin
  FLoaders.AddOrSetValue(Normalize(AExtension), ALoader);
end;

function TRenderModelLoaderTable.Find(const AExtension: string): IRenderModelLoader;
begin
  if not FLoaders.TryGetValue(Normalize(AExtension), Result) then
    Result := nil;
end;

end.
