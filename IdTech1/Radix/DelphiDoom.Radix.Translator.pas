{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixTranslator                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of TRadixToWADConverter.Convert_Game of radix_xlat_wad.pas             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Translator;

interface

uses
  System.SysUtils,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Types, DelphiDoom.Radix.Intf, DelphiDoom.Radix.Context;

type
  /// <summary>Makes an empty WAD in memory</summary>
  TRadixWadFactory = reference to function: IGameWadComposer;

  /// <summary>
  ///   Runs the steps of the translation one after the other on a WAD that it makes, then writes
  ///   the lump with the aliases (the PK3 entry RADIXINF). The steps are given by the factory, in
  ///   the order of the old converter
  /// </summary>
  TRadixTranslator = class(TInterfacedObject, IRadixTranslator)
  strict private
    FParts: TArray<IRadixPart>;
    FPatches: IGamePatchBuilder;
    FWadFactory: TRadixWadFactory;
    FPakEntries: TArray<TRadixPakEntry>;
    FTextureNames: TArray<string>;
  public
    /// <param name="AParts">The steps, in order</param>
    /// <param name="APatches">Makes patches; EArgumentNilException when nil</param>
    /// <param name="AWadFactory">Makes the WAD to fill; EArgumentNilException when nil</param>
    constructor Create(const AParts: TArray<IRadixPart>; const APatches: IGamePatchBuilder;
      const AWadFactory: TRadixWadFactory);
    function Translate(const AContainer: IRadixContainer): IGameWadComposer;
    function GetPakEntries: TArray<TRadixPakEntry>;
    function GetTextureNames: TArray<string>;
  end;

implementation

{ TRadixTranslator }

constructor TRadixTranslator.Create(const AParts: TArray<IRadixPart>;
  const APatches: IGamePatchBuilder; const AWadFactory: TRadixWadFactory);
begin
  inherited Create;
  if not Assigned(APatches) then
    raise EArgumentNilException.Create('APatches');
  if not Assigned(AWadFactory) then
    raise EArgumentNilException.Create('AWadFactory');
  FParts := AParts;
  FPatches := APatches;
  FWadFactory := AWadFactory;
end;

function TRadixTranslator.Translate(const AContainer: IRadixContainer): IGameWadComposer;
var
  LContext: TRadixTranslationContext;
  LPart: IRadixPart;
  LText: string;
  LAlias: string;
begin
  if not Assigned(AContainer) then
    raise EArgumentNilException.Create('AContainer');
  Result := FWadFactory();
  LContext := TRadixTranslationContext.Create(AContainer, Result, FPatches);
  try
    for LPart in FParts do
      LPart.Build(LContext);
    // the file says which lump of the WAD is which picture of the DAT, one line each
    if LContext.Aliases.Count > 0 then
    begin
      LText := '';
      for LAlias in LContext.Aliases do
        LText := LText + LAlias + #13#10;
      Result.AddText(RADIX_ALIASES_LUMP, LText);
    end;
    FPakEntries := LContext.PakEntries.ToArray;
    FTextureNames := LContext.TextureNames.ToArray;
  finally
    LContext.Free;
  end;
end;

function TRadixTranslator.GetPakEntries: TArray<TRadixPakEntry>;
begin
  Result := FPakEntries;
end;

function TRadixTranslator.GetTextureNames: TArray<string>;
begin
  Result := FTextureNames;
end;

end.
