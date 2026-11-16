{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the providers of constants, one after the other   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Constants.Chain;

interface

uses
  System.Generics.Collections,
  DelphiDoom.ScriptHost.Constants.Intf;

type
  /// <summary>A provider that asks other providers, in the order they were given</summary>
  TScriptConstantChain = class(TInterfacedObject, IScriptConstantProvider)
  strict private
    FProviders: TList<IScriptConstantProvider>;
  public
    constructor Create(const AProviders: array of IScriptConstantProvider);
    destructor Destroy; override;
    procedure Describe(const ATable: IScriptConstantTable);
  end;

implementation

uses
  System.SysUtils;

{ TScriptConstantChain }

constructor TScriptConstantChain.Create(const AProviders: array of IScriptConstantProvider);
var
  LProvider: IScriptConstantProvider;
begin
  inherited Create;
  FProviders := TList<IScriptConstantProvider>.Create;
  for LProvider in AProviders do
  begin
    if not Assigned(LProvider) then
      raise EArgumentNilException.Create('AProviders');
    FProviders.Add(LProvider);
  end;
end;

destructor TScriptConstantChain.Destroy;
begin
  FProviders.Free;
  inherited Destroy;
end;

procedure TScriptConstantChain.Describe(const ATable: IScriptConstantTable);
var
  LProvider: IScriptConstantProvider;
begin
  for LProvider in FProviders do
    LProvider.Describe(ATable);
end;

end.
