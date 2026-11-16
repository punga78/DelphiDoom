{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - registration of the "particle" type       }
{                                                                              }
{  Not derived from Doom 3 code: written for this repository (GPL v2 or        }
{  later). It is the composition root of the particle declaration: the only    }
{  place that knows its concrete classes.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Particle.Registration;

interface

uses
  DelphiDoom.Decl.Intf;

type
  /// <summary>Registers <c>particle</c> (DECL_PARTICLE) with the real class</summary>
  TDeclParticleRegistration = class sealed
  public
    class procedure Register(const ARegistry: IDeclRegistry); static;
  end;

implementation

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Types, DelphiDoom.Decl.Particle, DelphiDoom.Decl.Particle.Intf,
  DelphiDoom.Decl.Particle.Generator;

{ TDeclParticleRegistration }

class procedure TDeclParticleRegistration.Register(const ARegistry: IDeclRegistry);
begin
  ARegistry.RegisterDeclType('particle', DECL_PARTICLE,
    function: IDecl
    begin
      Result := TDeclParticle.Create(
        function(const ALog: IIdLibLog): IParticleGenerator
        begin
          Result := TParticleGenerator.Create(ALog);
        end);
    end);
end;

end.
