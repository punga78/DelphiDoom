{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclSkin, the "skin" declaration         }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclSkin.h, DeclSkin.cpp. Copyright (C) 1999-2011 id Software     }
{  LLC, a ZeniMax Media company.                                               }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Skin;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Base;

type
  /// <summary>A skin: which material replaces which (idDeclSkin)</summary>
  IDeclSkin = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0011}']
    function GetNumModelAssociations: Integer;
    /// <summary>The model name at the index, '' if out of range</summary>
    function GetAssociatedModel(const AIndex: Integer): AnsiString;
    function GetNumMappings: Integer;
    /// <summary>The material replaced by mapping <c>AIndex</c>; nil is the wildcard "*"</summary>
    function GetMappingFrom(const AIndex: Integer): IDecl;
    function GetMappingTo(const AIndex: Integer): IDecl;
    /// <summary>
    ///   The material that stands for <c>AShader</c> (the first mapping whose "from" is it or the wildcard);
    ///   the shader itself when none matches or when it is not drawn (<c>AIsDrawn</c> is
    ///   <c>idMaterial::IsDrawn</c>, which the material declaration of another library answers); nil for nil.
    /// </summary>
    function RemapShaderBySkin(const AShader: IDecl; const AIsDrawn: Boolean = True): IDecl;
  end;

  /// <summary>
  ///   <c>skin name { model "x"  "from" "to"  "*" "to" }</c>. The materials are declarations of type DECL_MATERIAL
  ///   found through the manager: they must be a registered type (a placeholder is enough).
  /// </summary>
  TDeclSkin = class(TDecl, IDeclSkin)
  strict private
    FAssociatedModels: TArray<AnsiString>;
    FFrom: TArray<IDecl>;
    FTo: TArray<IDecl>;
  public
    function GetNumModelAssociations: Integer;
    function GetAssociatedModel(const AIndex: Integer): AnsiString;
    function GetNumMappings: Integer;
    function GetMappingFrom(const AIndex: Integer): IDecl;
    function GetMappingTo(const AIndex: Integer): IDecl;
    function RemapShaderBySkin(const AShader: IDecl; const AIsDrawn: Boolean = True): IDecl;
    /// <summary>A skin with the name of a material gets the text "_default name" (the implicit skin)</summary>
    function SetDefaultText: Boolean; override;
    function DefaultDefinition: AnsiString; override;
    function Parse(const AText: AnsiString): Boolean; override;
    procedure FreeData; override;
    function Size: NativeInt; override;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Decl.Types;

{ TDeclSkin }

function TDeclSkin.GetNumModelAssociations: Integer;
begin
  Result := Length(FAssociatedModels);
end;

function TDeclSkin.GetAssociatedModel(const AIndex: Integer): AnsiString;
begin
  if (AIndex >= 0) and (AIndex < Length(FAssociatedModels)) then
    Result := FAssociatedModels[AIndex]
  else
    Result := '';
end;

function TDeclSkin.GetNumMappings: Integer;
begin
  Result := Length(FTo);
end;

function TDeclSkin.GetMappingFrom(const AIndex: Integer): IDecl;
begin
  Result := FFrom[AIndex];
end;

function TDeclSkin.GetMappingTo(const AIndex: Integer): IDecl;
begin
  Result := FTo[AIndex];
end;

function TDeclSkin.RemapShaderBySkin(const AShader: IDecl; const AIsDrawn: Boolean): IDecl;
var
  LIndex: Integer;
begin
  if not Assigned(AShader) then
    Exit(nil);

  // never remap surfaces that were originally nodraw, like collision hulls
  if not AIsDrawn then
    Exit(AShader);

  for LIndex := 0 to High(FTo) do
    // nil = wildcard match
    if (not Assigned(FFrom[LIndex])) or (FFrom[LIndex] = AShader) then
      Exit(FTo[LIndex]);

  // didn't find a match or wildcard, so stay the same
  Result := AShader;
end;

procedure TDeclSkin.FreeData;
begin
  FFrom := nil;
  FTo := nil;
end;

function TDeclSkin.Size: NativeInt;
begin
  Result := InstanceSize;
end;

function TDeclSkin.SetDefaultText: Boolean;
begin
  // if there exists a material with the same name
  if Assigned(GetFinder.FindType(DECL_MATERIAL, GetName, False)) then
  begin
    SetText(AnsiString(Format('skin %s // IMPLICITLY GENERATED'#10'{'#10'_default %s'#10'}'#10,
      [string(GetName), string(GetName)])));
    Result := True;
  end
  else
    Result := False;
end;

function TDeclSkin.DefaultDefinition: AnsiString;
begin
  Result := '{'#10#9'"*"'#9'"_default"'#10'}';
end;

function TDeclSkin.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
  LToken, LToken2: TIdToken;
  LFinder: IDeclFinder;
begin
  LSource := OpenLexer(AText);
  try
    LFinder := GetFinder;
    FAssociatedModels := nil;
    while True do
    begin
      if not LSource.ReadToken(LToken) then
        Break;
      if TIdStrings.Icmp(LToken.Text, '}') = 0 then
        Break;
      if not LSource.ReadToken(LToken2) then
      begin
        LSource.Warning('Unexpected end of file', []);
        MakeDefault;
        Exit(False);
      end;

      if TIdStrings.Icmp(LToken.Text, 'model') = 0 then
      begin
        SetLength(FAssociatedModels, Length(FAssociatedModels) + 1);
        FAssociatedModels[High(FAssociatedModels)] := LToken2.Text;
        Continue;
      end;

      SetLength(FFrom, Length(FFrom) + 1);
      SetLength(FTo, Length(FTo) + 1);
      if TIdStrings.Icmp(LToken.Text, '*') = 0 then
        // wildcard
        FFrom[High(FFrom)] := nil
      else
        FFrom[High(FFrom)] := LFinder.FindType(DECL_MATERIAL, LToken.Text);
      FTo[High(FTo)] := LFinder.FindType(DECL_MATERIAL, LToken2.Text);
    end;
  finally
    LSource.Free;
  end;
  // the original returns false here although nothing went wrong; the manager ignores the result
  Result := True;
end;

end.
