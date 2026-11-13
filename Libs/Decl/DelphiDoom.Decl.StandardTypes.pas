{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclStandardTypes, the types of Doom 3   }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclManager.cpp (idDeclManagerLocal::Init). Copyright (C)         }
{  1999-2011 id Software LLC, a ZeniMax Media company.                         }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.StandardTypes;

interface

uses
  System.SysUtils, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Material.Types;

type
  /// <summary>
  ///   What <c>idDeclManagerLocal::Init</c> registers, as a class that works on any registry. The types that are
  ///   ported (table, skin, material, entityDef, mapDef, pda, email, video, audio, fx, particle) get their class; the others
  ///   (sound, articulatedFigure) get the base <c>TDecl</c>, which keeps the text and
  ///   skips it, so a skin or a video can find its sounds. A library that ports one of them registers
  ///   its own type <b>before</b> calling <c>RegisterTypes</c> (a type number already in use is ignored with a warning,
  ///   which is silenced here by passing it in <c>ASkip</c>).
  /// </summary>
  TDeclStandardTypes = class sealed
  public
    /// <summary>Registers the types (the materials with the standard options); the numbers in <c>ASkip</c> are left to the caller</summary>
    class procedure RegisterTypes(const ARegistry: IDeclRegistry; const ASkip: array of Integer); overload; static;
    /// <summary>As above, with the options the materials are read with (cvars of the renderer)</summary>
    class procedure RegisterTypes(const ARegistry: IDeclRegistry; const ASkip: array of Integer;
      const AMaterialOptions: TMaterialOptions); overload; static;
    /// <summary>
    ///   Registers the type <c>material</c> as the base <c>TDecl</c> that only keeps the text (what the library had
    ///   before the material was ported). For a caller that does not want the text of its materials read; pass
    ///   <c>DECL_MATERIAL</c> in <c>ASkip</c> of <c>RegisterTypes</c> first.
    /// </summary>
    class procedure RegisterPlaceholderMaterial(const ARegistry: IDeclRegistry); static;
    /// <summary>Registers the folders of Init (materials, skins, sound) and loads their files</summary>
    class procedure RegisterFolders(const ARegistry: IDeclRegistry); static;
  end;

implementation

uses
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Base, DelphiDoom.Decl.Table, DelphiDoom.Decl.Skin,
  DelphiDoom.Decl.EntityDef, DelphiDoom.Decl.Pda, DelphiDoom.Decl.Email, DelphiDoom.Decl.Video,
  DelphiDoom.Decl.Audio, DelphiDoom.Decl.Material, DelphiDoom.Decl.Material.Intf,
  DelphiDoom.Decl.Material.ImageNamer, DelphiDoom.Decl.Fx.Registration, DelphiDoom.Decl.Particle.Registration;

{ TDeclStandardTypes }

class procedure TDeclStandardTypes.RegisterTypes(const ARegistry: IDeclRegistry; const ASkip: array of Integer);
begin
  RegisterTypes(ARegistry, ASkip, TMaterialOptions.Standard);
end;

class procedure TDeclStandardTypes.RegisterPlaceholderMaterial(const ARegistry: IDeclRegistry);
begin
  ARegistry.RegisterDeclType('material', DECL_MATERIAL, function: IDecl begin Result := TDecl.Create; end);
end;

class procedure TDeclStandardTypes.RegisterTypes(const ARegistry: IDeclRegistry; const ASkip: array of Integer;
  const AMaterialOptions: TMaterialOptions);
var
  LMaterialOptions: TMaterialOptions;

  function Skipped(const AType: Integer): Boolean;
  var
    LSkipped: Integer;
  begin
    for LSkipped in ASkip do
      if LSkipped = AType then
        Exit(True);
    Result := False;
  end;

  procedure Add(const AName: AnsiString; const AType: Integer; const AAllocator: TDeclAllocator);
  begin
    if not Skipped(AType) then
      ARegistry.RegisterDeclType(AName, AType, AAllocator);
  end;

begin
  LMaterialOptions := AMaterialOptions;
  // decls used throughout the engine
  Add('table', DECL_TABLE, function: IDecl begin Result := TDeclTable.Create; end);
  // a reader of image programs for each material: it keeps the text of the last program it read
  Add('material', DECL_MATERIAL,
    function: IDecl
    begin
      Result := TDeclMaterial.Create(TMaterialImageProgramNamer.Create, LMaterialOptions);
    end);
  Add('skin', DECL_SKIN, function: IDecl begin Result := TDeclSkin.Create; end);
  Add('sound', DECL_SOUND, function: IDecl begin Result := TDecl.Create; end);

  Add('entityDef', DECL_ENTITYDEF, function: IDecl begin Result := TDeclEntityDef.Create; end);
  Add('mapDef', DECL_MAPDEF, function: IDecl begin Result := TDeclEntityDef.Create; end);
  if not Skipped(DECL_FX) then
    TDeclFxRegistration.Register(ARegistry);
  if not Skipped(DECL_PARTICLE) then
    TDeclParticleRegistration.Register(ARegistry);
  Add('articulatedFigure', DECL_AF, function: IDecl begin Result := TDecl.Create; end);
  Add('pda', DECL_PDA, function: IDecl begin Result := TDeclPda.Create; end);
  Add('email', DECL_EMAIL, function: IDecl begin Result := TDeclEmail.Create; end);
  Add('video', DECL_VIDEO, function: IDecl begin Result := TDeclVideo.Create; end);
  Add('audio', DECL_AUDIO, function: IDecl begin Result := TDeclAudio.Create; end);
end;

class procedure TDeclStandardTypes.RegisterFolders(const ARegistry: IDeclRegistry);
begin
  ARegistry.RegisterDeclFolder('materials', '.mtr', DECL_MATERIAL);
  ARegistry.RegisterDeclFolder('skins', '.skin', DECL_SKIN);
  ARegistry.RegisterDeclFolder('sound', '.sndshd', DECL_SOUND);
end;

end.
