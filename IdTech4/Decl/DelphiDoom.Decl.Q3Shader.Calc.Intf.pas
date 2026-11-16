{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - the shader catalog            }
{                                                                              }
{  What R_RemapShader (renderer\tr_shader.c of Quake III Arena, id Software,   }
{  GPL v2 or later) asks of the renderer's table of shaders. Based on the      }
{  Quake III Arena GPL Source Code (id Software).                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.Intf;

interface

type
  /// <summary>
  ///   The table of the shaders that the renderer keeps (<c>tr.shaders</c>, <c>hashTable</c>). A shader is a
  ///   handle (<c>shader_t::index</c>); handle 0 is the default shader (<c>tr.defaultShader</c>), which the
  ///   original also uses for "not found".
  /// </summary>
  IQ3ShaderCatalog = interface
    ['{5B6E2E0E-3C6A-4B63-9A57-6B1D8D0E4A11}']
    /// <summary>
    ///   R_FindShaderByName: the shader with that name (extension and case ignored), whatever its lightmap,
    ///   the most recently made first; also a shader made as the default one for a name that had no image
    ///   (it has its own handle). 0 if there is none or the name is empty.
    /// </summary>
    function FindShaderByName(const AName: AnsiString): Integer;
    /// <summary>
    ///   RE_RegisterShaderLightMap( name, 0 ): finds or makes the shader; 0 if it could not be loaded (the
    ///   renderer keeps a default shader under that name, found by the next <c>FindShaderByName</c>)
    /// </summary>
    function RegisterShader(const AName: AnsiString): Integer;
    /// <summary>Every shader whose name, without the extension, is <c>AStrippedName</c> (Q_stricmp), whatever the lightmap</summary>
    function ShadersNamed(const AStrippedName: AnsiString): TArray<Integer>;
  end;

implementation

end.
