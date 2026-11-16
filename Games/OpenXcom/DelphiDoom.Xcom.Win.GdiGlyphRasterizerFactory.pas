{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - opens the fonts of Windows, installed or from a file    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.Win.GdiGlyphRasterizerFactory;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, DelphiDoom.XcomSurface.Glyph.Types,
  DelphiDoom.XcomSurface.GlyphRasterizer.Intf;

type
  /// <summary>
  ///   IXcomGlyphRasterizerFactory on GDI. A font given as a file is registered for this process only
  ///   (AddFontResourceEx, FR_PRIVATE) the first time it is asked for and removed when the factory goes; its
  ///   family name is read from the file when the options do not say it. GDI gives another font when the one
  ///   asked for is not there: that is a font not found
  /// </summary>
  TXcomGdiGlyphRasterizerFactory = class(TInterfacedObject, IXcomGlyphRasterizerFactory)
  strict private
    FRegistered: TStringList;
    function Register(const AFileName: string; out AReason: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function CreateRasterizer(const AFace: TXcomFontFace; AScale: Integer; out AReason: string): IXcomGlyphRasterizer;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.XcomSurface.TtfFamilyName, DelphiDoom.Xcom.Win.GdiGlyphRasterizer;

const
  SFileNotFound = 'the file %s is not there';
  SNotRegistered = 'Windows does not take %s as a font';
  SNoFamily = 'no family name in %s: give it with "name"';
  SNotInstalled = 'Windows has no font with this name and gives "%s"';
  SBadSize = 'the size must be more than 0';

constructor TXcomGdiGlyphRasterizerFactory.Create;
begin
  inherited Create;
  FRegistered := TStringList.Create;
end;

destructor TXcomGdiGlyphRasterizerFactory.Destroy;
var
  LFile: string;
begin
  if Assigned(FRegistered) then
    for LFile in FRegistered do
      RemoveFontResourceEx(PChar(LFile), FR_PRIVATE, nil);
  FRegistered.Free;
  inherited Destroy;
end;

function TXcomGdiGlyphRasterizerFactory.Register(const AFileName: string; out AReason: string): Boolean;
begin
  AReason := '';
  if FRegistered.IndexOf(AFileName) >= 0 then
    Exit(True);
  if not TFile.Exists(AFileName) then
  begin
    AReason := Format(SFileNotFound, [AFileName]);
    Exit(False);
  end;
  if AddFontResourceEx(PChar(AFileName), FR_PRIVATE, nil) = 0 then
  begin
    AReason := Format(SNotRegistered, [AFileName]);
    Exit(False);
  end;
  FRegistered.Add(AFileName);
  Result := True;
end;

function TXcomGdiGlyphRasterizerFactory.CreateRasterizer(const AFace: TXcomFontFace; AScale: Integer;
  out AReason: string): IXcomGlyphRasterizer;
var
  LName: string;
  LRasterizer: TXcomGdiGlyphRasterizer;
begin
  Result := nil;
  AReason := '';
  if (AFace.Size <= 0) or (AScale <= 0) then
  begin
    AReason := SBadSize;
    Exit;
  end;
  LName := AFace.Name;
  if AFace.FileName <> '' then
  begin
    if not Register(AFace.FileName, AReason) then
      Exit;
    // a collection (.ttc) is registered whole; without a name the family of the font Index of the file is asked
    if (LName = '') and not TXcomTtfFamilyName.TryRead(TFile.ReadAllBytes(AFace.FileName), AFace.FaceIndex, LName) then
    begin
      AReason := Format(SNoFamily, [AFace.FileName]);
      Exit;
    end;
  end;
  LRasterizer := TXcomGdiGlyphRasterizer.Create(LName, AFace.Size * AScale, AFace.Bold, AFace.Antialias);
  // from here the interface owns the object
  Result := LRasterizer;
  if not SameText(LRasterizer.FaceName, LName) then
  begin
    AReason := Format(SNotInstalled, [LRasterizer.FaceName]);
    Result := nil;
  end;
end;

end.
