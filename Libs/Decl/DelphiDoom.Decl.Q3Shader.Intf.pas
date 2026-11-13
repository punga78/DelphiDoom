{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - IDeclQ3Shader, what a shader declaration    }
{  gives to the ones that use it                                               }
{                                                                              }
{  Written from the description of the data (issue #119); the data are those   }
{  of shader_t of Quake III Arena. Licensed under the GNU General Public       }
{  License, version 2 or later.                                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Intf;

interface

uses
  DelphiDoom.Decl.Q3Shader.Types;

type
  /// <summary>
  ///   The data of a Quake III shader. Ask a declaration of the type "shader" for it with
  ///   <c>Supports(Decl, IDeclQ3Shader, Shader)</c>. Images are names, never loaded.
  /// </summary>
  IDeclQ3Shader = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0119}']
    /// <summary>The whole shader, a copy (the data do not change until the next parse)</summary>
    function GetData: TQ3ShaderData;
    /// <summary>numUnfoggedPasses: how many stages the shader has</summary>
    function GetStageCount: Integer;
    /// <summary>A stage, 0 to <c>GetStageCount - 1</c>; an <c>ERangeError</c> outside them</summary>
    function GetStage(const AIndex: Integer): TQ3ShaderStage;
    /// <summary>
    ///   True if the shader was not defined (no text, an error, no stage): the original keeps a shader with the
    ///   data it had read and this flag set, and the renderer shows the default shader instead
    /// </summary>
    function IsDefaultShader: Boolean;
    /// <summary>True if the text of the shader was read without an error (<c>explicitlyDefined</c>)</summary>
    function IsExplicitlyDefined: Boolean;
  end;

implementation

end.
