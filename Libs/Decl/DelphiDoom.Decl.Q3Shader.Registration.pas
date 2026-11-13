{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - registration                                }
{                                                                              }
{  Written from the description of the contract of Libs\Decl (issue #119).     }
{  Licensed under the GNU General Public License, version 2 or later.          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Registration;

interface

uses
  DelphiDoom.Decl.Intf, DelphiDoom.Decl.Q3Shader.Types;

type
  /// <summary>What a manager needs to read the shaders of Quake III</summary>
  TQ3ShaderRegistration = class sealed
  public
    /// <summary>Registers the type "shader" (number <c>DECL_Q3SHADER</c>); the number in <c>ASkip</c> is left to the caller</summary>
    class procedure RegisterType(const ARegistry: IDeclRegistry; const ASkip: array of Integer); overload; static;
    class procedure RegisterType(const ARegistry: IDeclRegistry; const ASkip: array of Integer;
      const AOptions: TQ3ShaderOptions); overload; static;
    /// <summary>
    ///   Registers the folder <c>scripts</c> and reads its <c>.shader</c> files, as R_InitShaders does: needs the
    ///   type registered. Not part of the standard folders: a Doom 3 game has no such files.
    /// </summary>
    class procedure RegisterFolder(const ARegistry: IDeclRegistry); static;
  end;

implementation

uses
  DelphiDoom.Decl.Q3Shader.DeclType;

{ TQ3ShaderRegistration }

class procedure TQ3ShaderRegistration.RegisterType(const ARegistry: IDeclRegistry; const ASkip: array of Integer);
begin
  RegisterType(ARegistry, ASkip, TQ3ShaderOptions.Standard);
end;

class procedure TQ3ShaderRegistration.RegisterType(const ARegistry: IDeclRegistry; const ASkip: array of Integer;
  const AOptions: TQ3ShaderOptions);
var
  LSkipped: Integer;
begin
  for LSkipped in ASkip do
    if LSkipped = DECL_Q3SHADER then
      Exit;
  ARegistry.RegisterDeclType(TQ3ShaderDeclType.Create(AOptions));
end;

class procedure TQ3ShaderRegistration.RegisterFolder(const ARegistry: IDeclRegistry);
begin
  ARegistry.RegisterDeclFolder('scripts', '.shader', DECL_Q3SHADER);
end;

end.
