{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the types of the OpenGL shader files       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Shader.Types;

interface

type
  /// <summary>
  ///   What a .OpenGL.shader file of the Shaders folder says (the document that OpenGL::set_shader reads). The two
  ///   programs are the bytes of the file, as the compiler of the driver wants them; an empty one is not compiled
  /// </summary>
  TXcomShaderSource = record
    /// <summary>The value of "language" as it is written</summary>
    Language: string;
    /// <summary>The language is "GLSL", the only one that is compiled</summary>
    IsGlsl: Boolean;
    /// <summary>"linear": the texture of the picture is sampled with the linear filter (false when the file does not say)</summary>
    Linear: Boolean;
    Fragment: RawByteString;
    Vertex: RawByteString;
  end;

implementation

end.
