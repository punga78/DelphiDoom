{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the PNG textures of the cars of Speed Haste            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Speed.TextureFiles;

interface

uses
  System.SysUtils, DelphiDoom.Speed.Intf;

type
  /// <summary>
  ///   The PNG files of a folder (TEXTURES\ beside SPEEDH.JCL: the textures of the cars of the fork,
  ///   f_1_4_01_03.png...) read with the PNG library of the engine
  /// </summary>
  TEngineSpeedTextureFiles = class(TInterfacedObject, ISpeedTextureSource)
  strict private
    FFolder: string;
  public
    /// <param name="AFolder">The folder of the files; it need not exist</param>
    constructor Create(const AFolder: string);
    function TryLoad(const AFileName: string; out AWidth, AHeight: Integer; out ARgba: TBytes): Boolean;
    /// <summary>True when the folder exists and has at least one PNG file</summary>
    function HasFiles: Boolean;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Png.Intf, DelphiDoom.Png.Client, DelphiDoom.Png.Provider;

{ TEngineSpeedTextureFiles }

constructor TEngineSpeedTextureFiles.Create(const AFolder: string);
begin
  inherited Create;
  FFolder := AFolder;
end;

function TEngineSpeedTextureFiles.HasFiles: Boolean;
begin
  Result := TDirectory.Exists(FFolder) and (Length(TDirectory.GetFiles(FFolder, '*.png')) > 0);
end;

function TEngineSpeedTextureFiles.TryLoad(const AFileName: string; out AWidth, AHeight: Integer;
  out ARgba: TBytes): Boolean;
var
  LPath: string;
  LImage: TPngImage;
  LIndex: Integer;
  LBlue: Byte;
begin
  Result := False;
  AWidth := 0;
  AHeight := 0;
  ARgba := nil;
  LPath := TPath.Combine(FFolder, AFileName);
  if not TFile.Exists(LPath) then
    Exit;
  try
    LImage := TPngProvider.Client.Decode(TFile.ReadAllBytes(LPath));
  except
    on EPngException do
      Exit;
  end;
  // the engine gives B, G, R, A: the pictures of the library are R, G, B, A
  ARgba := LImage.Pixels;
  for LIndex := 0 to LImage.Info.Width * LImage.Info.Height - 1 do
  begin
    LBlue := ARgba[LIndex * 4];
    ARgba[LIndex * 4] := ARgba[LIndex * 4 + 2];
    ARgba[LIndex * 4 + 2] := LBlue;
  end;
  AWidth := LImage.Info.Width;
  AHeight := LImage.Info.Height;
  Result := True;
end;

end.
