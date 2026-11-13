{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TMaterialImageProgramNamer                }
{                                                                              }
{  Written for this repository (GPL v2 or later): it only connects the         }
{  material to the image program interpreter of Libs\Imaging, which is the     }
{  port of renderer\Image_program.cpp.                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Material.ImageNamer;

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Lexer, DelphiDoom.Imaging.ImageProgram.Interpreter,
  DelphiDoom.Decl.Material.Intf;

type
  /// <summary>
  ///   <c>R_ParsePastImageProgram</c> for the materials: reads an image program ("_white", "a/b.tga",
  ///   "addnormals( a, heightmap( b, 4 ) )") from the lexer of a material and gives its canonical text, with
  ///   <c>TImagingImageProgram.SkipProgram</c>. No image is loaded.
  /// </summary>
  TMaterialImageProgramNamer = class(TInterfacedObject, IMaterialImageNamer)
  strict private
    FProgram: TImagingImageProgram;
  public
    constructor Create;
    destructor Destroy; override;
    function ParsePastImageProgram(const ALexer: TIdLexer): AnsiString;
  end;

implementation

{ TMaterialImageProgramNamer }

constructor TMaterialImageProgramNamer.Create;
begin
  inherited Create;
  // the interpreter never asks its source for an image when it only skips
  FProgram := TImagingImageProgram.Create(nil);
end;

destructor TMaterialImageProgramNamer.Destroy;
begin
  FProgram.Free;
  inherited Destroy;
end;

function TMaterialImageProgramNamer.ParsePastImageProgram(const ALexer: TIdLexer): AnsiString;
begin
  FProgram.SkipProgram(ALexer);
  Result := FProgram.CanonicalName;
end;

end.
