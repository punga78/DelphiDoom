//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - external textures of the full screen pages
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------
{$I Doom32.inc}

{$I Doom32.inc}

unit DelphiDoom.Engine.Texture.DrawTextures;

interface

uses
  d_delphi,
  DelphiDoom.Engine.Texture.Item,
  DelphiDoom.Engine.Texture.Intf;

type
  /// <summary>
  ///   IEngineDrawTextures on the texture files of the engine (the old t_draw): the texture of
  ///   each page is loaded the first time the page is drawn and kept until ShutDown; a page
  ///   without an external texture is remembered, so it is looked for only once
  /// </summary>
  TEngineDrawTextures = class(TInterfacedObject, IEngineDrawTextures)
  strict private
    type
      TDrawTexture = record
        Texture: PTexture;
        Lump: Integer;
        Failed: Boolean;
      end;
  strict private
    const
      SFilesMissing = 'The texture files are missing';
  strict private
    FFiles: IEngineTextureFiles;
    FTextures: TArray<TDrawTexture>;
    function IndexOfLump(const AName: string): Integer;
    function DrawIndex(AIndex: Integer; const ADest: PLongWordArray): Boolean;
  public
    constructor Create(const AFiles: IEngineTextureFiles);
    destructor Destroy; override;
    procedure Initialize;
    procedure ShutDown;
    function Draw(const AName: string; const ADest: PLongWordArray): Boolean;
  end;

implementation

uses
  System.SysUtils,
  doomdef,
  m_fixed,
  r_hires,
  r_mmx,
  v_video,
{$IFDEF OPENGL}
  v_data,
{$ENDIF}
  w_wad;

{ TEngineDrawTextures }

constructor TEngineDrawTextures.Create(const AFiles: IEngineTextureFiles);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create(SFilesMissing);
  FFiles := AFiles;
end;

destructor TEngineDrawTextures.Destroy;
begin
  ShutDown;
  inherited Destroy;
end;

procedure TEngineDrawTextures.Initialize;
begin
  ShutDown;
end;

procedure TEngineDrawTextures.ShutDown;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FTextures) do
    if Assigned(FTextures[LIndex].Texture) then
      Dispose(FTextures[LIndex].Texture, Destroy);
  FTextures := nil;
end;

function TEngineDrawTextures.IndexOfLump(const AName: string): Integer;
var
  LLump: Integer;
  LIndex: Integer;
begin
  LLump := W_GetNumForName(AName);
  for LIndex := 0 to High(FTextures) do
    if FTextures[LIndex].Lump = LLump then
    begin
      Result := LIndex;
      Exit;
    end;

  Result := Length(FTextures);
  SetLength(FTextures, Result + 1);
  FTextures[Result].Texture := nil;
  FTextures[Result].Lump := LLump;
  FTextures[Result].Failed := False;
end;

function TEngineDrawTextures.Draw(const AName: string; const ADest: PLongWordArray): Boolean;
begin
  Result := DrawIndex(IndexOfLump(AName), ADest);
end;

function TEngineDrawTextures.DrawIndex(AIndex: Integer; const ADest: PLongWordArray): Boolean;
var
  LTexture: PTexture;
  LRow: TArray<LongWord>;
  LSource: PLongWordArray;
  LTarget: PLongWord;
  LRowIndex, LColumn: Integer;
  LFracRow, LFracColumn: fixed_t;
  LFracRowStep, LFracColumnStep: fixed_t;
  LRed, LGreen, LBlue: Byte;
  LColor: LongWord;
  LGamma: PByteArray;
  LWidth: Integer;
begin
  if FTextures[AIndex].Failed then
  begin
    Result := False;
    Exit;
  end;

  if FTextures[AIndex].Texture = nil then
  begin
    LTexture := FFiles.LoadTexture(W_GetNameForNum(FTextures[AIndex].Lump));
    if LTexture = nil then
    begin
      FTextures[AIndex].Failed := True;
      Result := False;
      Exit;
    end;
    FTextures[AIndex].Texture := LTexture;
  end
  else
    LTexture := FTextures[AIndex].Texture;

  LWidth := LTexture.GetWidth;
  SetLength(LRow, LWidth);
  LSource := PLongWordArray(@LRow[0]);

  LTarget := @ADest[0];

  LFracRowStep := LTexture.GetHeight * FRACUNIT div
{$IFDEF OPENGL}V_GetScreenHeight(SCN_FG){$ELSE}SCREENHEIGHT{$ENDIF};
  LFracColumnStep := LWidth * FRACUNIT div
{$IFDEF OPENGL}V_GetScreenWidth(SCN_FG){$ELSE}SCREENWIDTH{$ENDIF};

  if (pal_color = 0) and (usegamma = 0) then
    LColor := 0
  else
  begin
    LGamma := @gammatable[usegamma]; // To Adjust gamma
    LRed := pal_color;
    LGreen := pal_color shr 8;
    LBlue := pal_color shr 16;
    LColor := LGamma[LRed] + LGamma[LGreen] shl 8 + LGamma[LBlue] shl 16;
  end;

  LFracRow := 0;
  for LRowIndex := 0 to {$IFDEF OPENGL}V_GetScreenHeight(SCN_FG){$ELSE}SCREENHEIGHT{$ENDIF} - 1 do
  begin
    LFracColumn := 0;

    // Adjust gamma
    if LTexture.GetBytesPerPixel = 1 then
      LTexture.GetPalettedRow32(LFracRow shr FRACBITS, LWidth, LSource, LColor)
    else
    begin
      LTexture.GetRow32(LFracRow shr FRACBITS, LWidth, LSource);
      if not R_BatchColorAdd32_MMX(@LSource[0], LColor, LWidth) then
      begin
        for LColumn := 0 to LWidth - 1 do
          LSource[LColumn] := R_ColorAdd(LSource[LColumn], LColor);
      end;
    end;

    for LColumn := 0 to {$IFDEF OPENGL}V_GetScreenWidth(SCN_FG){$ELSE}SCREENWIDTH{$ENDIF} - 1 do
    begin
      LTarget^ := LSource[LFracColumn shr FRACBITS]{$IFDEF OPENGL} or $FF000000{$ENDIF};
      Inc(LTarget);
      Inc(LFracColumn, LFracColumnStep);
    end;
    Inc(LFracRow, LFracRowStep);
  end;

  Result := True;
end;

end.