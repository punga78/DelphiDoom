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
  System.SysUtils, DelphiDoom.Decl.Intf;

type
  /// <summary>
  ///   What <c>idDeclManagerLocal::Init</c> registers, as a class that works on any registry. The types that are
  ///   ported (table, skin, entityDef, mapDef, pda, email, video, audio) get their class; the others (material,
  ///   sound, fx, particle, articulatedFigure) get the base <c>TDecl</c>, which keeps the text and
  ///   skips it, so a skin or a video can find its materials and sounds. A library that ports one of them registers
  ///   its own type <b>before</b> calling <c>RegisterTypes</c> (a type number already in use is ignored with a warning,
  ///   which is silenced here by passing it in <c>ASkip</c>).
  /// </summary>
  TDeclStandardTypes = class sealed
  public
    /// <summary>Registers the types; the numbers in <c>ASkip</c> are left to the caller</summary>
    class procedure RegisterTypes(const ARegistry: IDeclRegistry; const ASkip: array of Integer); static;
    /// <summary>Registers the folders of Init (materials, skins, sound) and loads their files</summary>
    class procedure RegisterFolders(const ARegistry: IDeclRegistry); static;
  end;

implementation

uses
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Base, DelphiDoom.Decl.Table, DelphiDoom.Decl.Skin,
  DelphiDoom.Decl.EntityDef, DelphiDoom.Decl.Pda, DelphiDoom.Decl.Email, DelphiDoom.Decl.Video,
  DelphiDoom.Decl.Audio;

{ TDeclStandardTypes }

class procedure TDeclStandardTypes.RegisterTypes(const ARegistry: IDeclRegistry; const ASkip: array of Integer);

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
  // decls used throughout the engine
  Add('table', DECL_TABLE, function: IDecl begin Result := TDeclTable.Create; end);
  Add('material', DECL_MATERIAL, function: IDecl begin Result := TDecl.Create; end);
  Add('skin', DECL_SKIN, function: IDecl begin Result := TDeclSkin.Create; end);
  Add('sound', DECL_SOUND, function: IDecl begin Result := TDecl.Create; end);

  Add('entityDef', DECL_ENTITYDEF, function: IDecl begin Result := TDeclEntityDef.Create; end);
  Add('mapDef', DECL_MAPDEF, function: IDecl begin Result := TDeclEntityDef.Create; end);
  Add('fx', DECL_FX, function: IDecl begin Result := TDecl.Create; end);
  Add('particle', DECL_PARTICLE, function: IDecl begin Result := TDecl.Create; end);
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
