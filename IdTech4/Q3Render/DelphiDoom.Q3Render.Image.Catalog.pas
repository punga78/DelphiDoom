{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - image table      }
{                                                                              }
{  The part of R_FindImageFile of renderer\tr_image.c that is not OpenGL: a    }
{  name is loaded once and found again by name. Based on the Quake III Arena  }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Image.Catalog;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Intf;

type
  /// <summary>
  ///   Finds images by name through an IQ3ImageLoader. The names compare without regard to case and a
  ///   backslash is a slash (the file system does the same). A name that does not load is remembered, so it is not
  ///   read again (the C does read again: R_FindImageFile keeps nothing for a missing image). The pixels are kept
  ///   only if AKeepPixels is true: the widths and heights of a game's images add up to hundreds of megabytes
  /// </summary>
  TQ3ImageCatalog = class(TInterfacedObject, IQ3ImageCatalog)
  strict private
    FLoader: IQ3ImageLoader;
    FKeepPixels: Boolean;
    FHandles: TDictionary<string, Integer>;
    FImages: TList<TQ3RenderImage>;
    FMissing: TList<string>;
    class function Key(const AName: AnsiString): string; static;
  public
    constructor Create(const ALoader: IQ3ImageLoader; AKeepPixels: Boolean = False);
    destructor Destroy; override;
    function Find(const AName: AnsiString): Integer;
    function GetImage(AHandle: Integer; out AImage: TQ3RenderImage): Boolean;
    function LoadedCount: Integer;
    function MissingNames: TArray<string>;
  end;

implementation

constructor TQ3ImageCatalog.Create(const ALoader: IQ3ImageLoader; AKeepPixels: Boolean);
begin
  inherited Create;
  if not Assigned(ALoader) then
    raise EArgumentNilException.Create('ALoader');
  FLoader := ALoader;
  FKeepPixels := AKeepPixels;
  FHandles := TDictionary<string, Integer>.Create;
  FImages := TList<TQ3RenderImage>.Create;
  FMissing := TList<string>.Create;
end;

destructor TQ3ImageCatalog.Destroy;
begin
  FHandles.Free;
  FImages.Free;
  FMissing.Free;
  inherited Destroy;
end;

class function TQ3ImageCatalog.Key(const AName: AnsiString): string;
begin
  Result := LowerCase(StringReplace(string(AName), '\', '/', [rfReplaceAll]));
end;

function TQ3ImageCatalog.Find(const AName: AnsiString): Integer;
var
  LKey: string;
  LImage: TQ3RenderImage;
  LLoaded: Boolean;
begin
  LKey := Key(AName);
  if FHandles.TryGetValue(LKey, Result) then
    Exit;
  try
    LLoaded := FLoader.Load(AName, LImage);
  except
    on EQ3RenderException do
      LLoaded := False;
  end;
  if not LLoaded then
  begin
    FHandles.Add(LKey, 0);
    FMissing.Add(string(AName));
    Exit(0);
  end;
  if not FKeepPixels then
    LImage.Pixels := nil;
  FImages.Add(LImage);
  Result := FImages.Count;
  FHandles.Add(LKey, Result);
end;

function TQ3ImageCatalog.GetImage(AHandle: Integer; out AImage: TQ3RenderImage): Boolean;
begin
  Result := (AHandle >= 1) and (AHandle <= FImages.Count);
  if Result then
    AImage := FImages[AHandle - 1]
  else
    AImage := Default(TQ3RenderImage);
end;

function TQ3ImageCatalog.LoadedCount: Integer;
begin
  Result := FImages.Count;
end;

function TQ3ImageCatalog.MissingNames: TArray<string>;
begin
  Result := FMissing.ToArray;
end;

end.
