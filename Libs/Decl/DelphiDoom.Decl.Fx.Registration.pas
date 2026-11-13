{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - registration of the "fx" type             }
{                                                                              }
{  Not derived from Doom 3 code: written for this repository (GPL v2 or        }
{  later). It is the composition root of the effect declaration.               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Fx.Registration;

interface

uses
  DelphiDoom.Decl.Intf;

type
  /// <summary>Registers <c>fx</c> (DECL_FX) with the real class</summary>
  TDeclFxRegistration = class sealed
  public
    class procedure Register(const ARegistry: IDeclRegistry); static;
  end;

implementation

uses
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Fx;

{ TDeclFxRegistration }

class procedure TDeclFxRegistration.Register(const ARegistry: IDeclRegistry);
begin
  ARegistry.RegisterDeclType('fx', DECL_FX, function: IDecl begin Result := TDeclFx.Create; end);
end;

end.
