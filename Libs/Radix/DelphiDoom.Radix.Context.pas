{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - the state of a translation                      }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  What the fields of TRadixToWADConverter held between the steps              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Context;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Types, DelphiDoom.Radix.Intf;

type
  /// <summary>
  ///   What the steps of the translation share: the container to read, the WAD to fill, the
  ///   palette that the first step finds and the lists that the later steps use (the aliases of
  ///   the PK3 entry, the names and sizes of the textures, the walls that are flats too)
  /// </summary>
  TRadixTranslationContext = class
  strict private
    FContainer: IRadixContainer;
    FWad: IGameWadComposer;
    FPatches: IGamePatchBuilder;
    FPalette: TBytes;
    FPaletteColors: TArray<Cardinal>;
    FAliases: TList<string>;
    FTextureNames: TList<string>;
    FPakEntries: TList<TRadixPakEntry>;
    FMarkFlats: TArray<Boolean>;
    FTextureWidths: TArray<Integer>;
    FTextureHeights: TArray<Integer>;
  public
    constructor Create(const AContainer: IRadixContainer; const AWad: IGameWadComposer;
      const APatches: IGamePatchBuilder);
    destructor Destroy; override;
    /// <summary>The 768 bytes of the base palette, already scaled to 0..255; empty before the palette step</summary>
    procedure SetPalette(const APalette: TBytes);
    /// <summary>"RDXW0001=name" lines: the PK3 entry that says which lump is which picture</summary>
    procedure AddAlias(const ALump, AName: string);
    procedure SetTextureSlots(ACount: Integer);
    property Container: IRadixContainer read FContainer;
    property Wad: IGameWadComposer read FWad;
    property Patches: IGamePatchBuilder read FPatches;
    property Palette: TBytes read FPalette;
    /// <summary>The palette as $00RRGGBB, 256 colors</summary>
    property PaletteColors: TArray<Cardinal> read FPaletteColors;
    property Aliases: TList<string> read FAliases;
    property TextureNames: TList<string> read FTextureNames;
    property PakEntries: TList<TRadixPakEntry> read FPakEntries;
    property MarkFlats: TArray<Boolean> read FMarkFlats write FMarkFlats;
    property TextureWidths: TArray<Integer> read FTextureWidths write FTextureWidths;
    property TextureHeights: TArray<Integer> read FTextureHeights write FTextureHeights;
  end;

  /// <summary>One step of the translation: it reads some lumps and adds some others to the WAD</summary>
  IRadixPart = interface
    ['{5C83D1E7-0B42-4A96-8E3F-71A9D6C20B58}']
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

{ TRadixTranslationContext }

constructor TRadixTranslationContext.Create(const AContainer: IRadixContainer;
  const AWad: IGameWadComposer; const APatches: IGamePatchBuilder);
begin
  inherited Create;
  if not Assigned(AContainer) then
    raise EArgumentNilException.Create('AContainer');
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  if not Assigned(APatches) then
    raise EArgumentNilException.Create('APatches');
  FContainer := AContainer;
  FWad := AWad;
  FPatches := APatches;
  FAliases := TList<string>.Create;
  FTextureNames := TList<string>.Create;
  FPakEntries := TList<TRadixPakEntry>.Create;
end;

destructor TRadixTranslationContext.Destroy;
begin
  FPakEntries.Free;
  FTextureNames.Free;
  FAliases.Free;
  inherited Destroy;
end;

procedure TRadixTranslationContext.SetPalette(const APalette: TBytes);
var
  LColor: Integer;
begin
  FPalette := Copy(APalette, 0, 768);
  SetLength(FPaletteColors, 256);
  for LColor := 0 to 255 do
    FPaletteColors[LColor] := (Cardinal(FPalette[LColor * 3]) shl 16) or
      (Cardinal(FPalette[LColor * 3 + 1]) shl 8) or Cardinal(FPalette[LColor * 3 + 2]);
end;

procedure TRadixTranslationContext.AddAlias(const ALump, AName: string);
begin
  FAliases.Add(ALump + '=' + AName);
end;

procedure TRadixTranslationContext.SetTextureSlots(ACount: Integer);
begin
  SetLength(FMarkFlats, ACount);
  SetLength(FTextureWidths, ACount);
  SetLength(FTextureHeights, ACount);
end;

end.
