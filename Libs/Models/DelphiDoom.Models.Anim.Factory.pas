{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - animations: the factory                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.Factory;

interface

uses
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Source.Intf,
  DelphiDoom.Models.Anim.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the animations</summary>
  TAnimFactory = class
  public
    /// <summary>The cache of the md5anims on a file source (idAnimManager)</summary>
    class function CreateManager(const ASource: IModelFileSource; const ALog: IIdLibLog): IAnimManager; static;
    /// <summary>
    ///   The reader of MODELDEF declarations. ALookup nil is the permissive lookup (no game).
    /// </summary>
    class function CreateModelDefParser(const ASource: IModelDefSource; const AAnims: IAnimManager;
      const ALookup: IModelDefGameLookup; const ALog: IIdLibLog): IModelDefParser; static;
    /// <summary>idAnim::SetAnim: an animation on the md5anims given, counted in the manager</summary>
    class function CreateAnim(const AManager: IAnimManager; const AFullName, AName: AnsiString;
      const AAnims: TArray<IMd5Anim>): IAnim; static;
    /// <summary>A lookup that accepts everything</summary>
    class function CreatePermissiveLookup: IModelDefGameLookup; static;
  end;

implementation

uses
  DelphiDoom.Models.Md5.Factory,
  DelphiDoom.Models.Anim.Anim,
  DelphiDoom.Models.Anim.Manager,
  DelphiDoom.Models.Anim.ModelDefParser,
  DelphiDoom.Models.Anim.PermissiveLookup;

{ TAnimFactory }

class function TAnimFactory.CreateManager(const ASource: IModelFileSource; const ALog: IIdLibLog): IAnimManager;
begin
  Result := TAnimManager.Create(ASource, TMd5Factory.CreateAnimParser, ALog);
end;

class function TAnimFactory.CreateModelDefParser(const ASource: IModelDefSource; const AAnims: IAnimManager;
  const ALookup: IModelDefGameLookup; const ALog: IIdLibLog): IModelDefParser;
var
  LLookup: IModelDefGameLookup;
begin
  LLookup := ALookup;
  if LLookup = nil then
    LLookup := CreatePermissiveLookup;
  Result := TModelDefParser.Create(ASource, AAnims, LLookup, ALog);
end;

class function TAnimFactory.CreateAnim(const AManager: IAnimManager; const AFullName, AName: AnsiString;
  const AAnims: TArray<IMd5Anim>): IAnim;
begin
  Result := TAnim.Create(AManager, AFullName, AName, AAnims);
end;

class function TAnimFactory.CreatePermissiveLookup: IModelDefGameLookup;
begin
  Result := TModelDefPermissiveLookup.Create;
end;

end.
