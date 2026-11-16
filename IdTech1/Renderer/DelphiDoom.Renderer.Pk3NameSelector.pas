{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the images of a PK3 that become textures     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of R_AddTextureFileName of r_pk3textures.pas                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.Pk3NameSelector;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Renderer.Types,
  DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   Looks at the names of the files of a PK3 and tells which are textures and which flats.
  ///   It is done once, when the PK3 is loaded
  /// </summary>
  TRendererPk3NameSelector = class(TInterfacedObject, IRendererPk3NameSelector)
  strict private
    class function UpperCase(const AText: string): string; static;
    class function FixPathName(const AText: string): string; static;
    class function Contains(const AList: TList<string>; const AName: string): Boolean; static;
    class procedure Consider(const AFileName: string; const ACatalog: IRendererPk3Catalog;
      const ATextures, AFlats: TList<string>); static;
  public
    function Select(const AEntryNames: TArray<string>;
      const ACatalog: IRendererPk3Catalog): TRendererPk3Names;
  end;

implementation

uses
  System.Generics.Defaults;

const
  SNoCatalog = 'The catalog of the images of the PK3 is missing';

{ TRendererPk3NameSelector }

class function TRendererPk3NameSelector.UpperCase(const AText: string): string;
var
  LIndex: Integer;
begin
  // only the letters a to z, as the strupper of the engine did
  Result := AText;
  for LIndex := 1 to Length(Result) do
    if (Result[LIndex] >= 'a') and (Result[LIndex] <= 'z') then
      Result[LIndex] := Char(Ord(Result[LIndex]) - 32);
end;

class function TRendererPk3NameSelector.FixPathName(const AText: string): string;
var
  LIndex: Integer;
  LLast: Char;
  LText: string;
begin
  LText := AText;
  for LIndex := 1 to Length(LText) do
    if LText[LIndex] = '/' then
      LText[LIndex] := '\';
  Result := '';
  LLast := #0;
  for LIndex := 1 to Length(LText) do
  begin
    if (LLast <> '\') or (LText[LIndex] <> '\') then
      Result := Result + LText[LIndex];
    LLast := LText[LIndex];
  end;
end;

class function TRendererPk3NameSelector.Contains(const AList: TList<string>;
  const AName: string): Boolean;
var
  LIndex: Integer;
begin
  // the list of the engine compared without caring for the case
  for LIndex := 0 to AList.Count - 1 do
    if AnsiCompareText(AList[LIndex], AName) = 0 then
      Exit(True);
  Result := False;
end;

class procedure TRendererPk3NameSelector.Consider(const AFileName: string;
  const ACatalog: IRendererPk3Catalog; const ATextures, AFlats: TList<string>);
var
  LCheck: string;
  LName: string;
  LExtension: string;
  LPath: string;
  LIsTexture: Boolean;
  LIsFlat: Boolean;
  LDot: Integer;
begin
  LCheck := UpperCase(AFileName);
  LExtension := ExtractFileExt(LCheck); // includes the dot ('.PNG')
  if not ACatalog.IsTextureExtension(LExtension) then
    Exit;

  LPath := FixPathName(LCheck);
  LIsTexture := Pos(RENDERER_PK3_TEXTURE_PATH, LPath) > 0;
  LIsFlat := Pos(RENDERER_PK3_FLAT_PATH, LPath) > 0;
  if not (LIsTexture or LIsFlat) then
    Exit;

  LCheck := ExtractFileName(LCheck);
  LDot := Pos('.', LCheck);
  if LDot = 0 then
    LName := LCheck
  else
    LName := Copy(LCheck, 1, LDot - 1);
  // only one dot (the extension has its own)
  if LName + LExtension <> LCheck then
    Exit;
  if Length(LName) > RENDERER_PK3_MAX_NAME_LENGTH then
    Exit;
  if ACatalog.HasLump(LName) then
    Exit;

  // the images of flats\ are only flats; the ones of textures\ are textures and flats
  if LIsTexture then
    if not Contains(ATextures, LName) then
      if ACatalog.TextureNumber(LName) <= 0 then
      begin
        ATextures.Add(LName);
        AFlats.Add(LName);
        Exit;
      end;
  if not Contains(AFlats, LName) then
    AFlats.Add(LName);
end;

function TRendererPk3NameSelector.Select(const AEntryNames: TArray<string>;
  const ACatalog: IRendererPk3Catalog): TRendererPk3Names;
var
  LTextures: TList<string>;
  LFlats: TList<string>;
  LIndex: Integer;
  LComparer: IComparer<string>;
begin
  if not Assigned(ACatalog) then
    raise ERendererException.Create(SNoCatalog);
  LTextures := TList<string>.Create;
  LFlats := TList<string>.Create;
  try
    for LIndex := 0 to High(AEntryNames) do
      Consider(AEntryNames[LIndex], ACatalog, LTextures, LFlats);
    // sorted as the strings compare in the engine (by code)
    LComparer := TStringComparer.Ordinal;
    LTextures.Sort(LComparer);
    LFlats.Sort(LComparer);
    Result.Textures := LTextures.ToArray;
    Result.Flats := LFlats.ToArray;
  finally
    LFlats.Free;
    LTextures.Free;
  end;
end;

end.
