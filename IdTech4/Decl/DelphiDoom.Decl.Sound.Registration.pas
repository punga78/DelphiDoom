{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - registration of the "sound" type          }
{                                                                              }
{  Not derived from Doom 3 code: written for this repository (GPL v2 or        }
{  later). It is the composition root of the sound shader declaration.         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Sound.Registration;

interface

uses
  DelphiDoom.Decl.Intf, DelphiDoom.Decl.Sound.Types, DelphiDoom.Decl.Sound.Intf;

type
  /// <summary>Registers <c>sound</c> (DECL_SOUND) with the real class</summary>
  TDeclSoundRegistration = class sealed
  public
    /// <summary>The shaders only name their samples (<c>TSoundSampleNameCatalog</c>) and use the standard options</summary>
    class procedure Register(const ARegistry: IDeclRegistry); overload; static;
    /// <summary>
    ///   The shaders find their samples in <c>ACatalog</c> (the sound cache), look for the language folders with
    ///   <c>AFiles</c> (may be nil) and read their cvars from <c>AOptions</c>
    /// </summary>
    class procedure Register(const ARegistry: IDeclRegistry; const ACatalog: ISoundSampleCatalog;
      const AFiles: ISoundFileProbe; const AOptions: TSoundShaderOptions); overload; static;
  end;

implementation

uses
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Sound, DelphiDoom.Decl.Sound.NameCatalog;

{ TDeclSoundRegistration }

class procedure TDeclSoundRegistration.Register(const ARegistry: IDeclRegistry);
begin
  Register(ARegistry, TSoundSampleNameCatalog.Create, nil, TSoundShaderOptions.Standard);
end;

class procedure TDeclSoundRegistration.Register(const ARegistry: IDeclRegistry; const ACatalog: ISoundSampleCatalog;
  const AFiles: ISoundFileProbe; const AOptions: TSoundShaderOptions);
begin
  ARegistry.RegisterDeclType('sound', DECL_SOUND,
    function: IDecl
    begin
      Result := TDeclSound.Create(ACatalog, AFiles, AOptions);
    end);
end;

end.
