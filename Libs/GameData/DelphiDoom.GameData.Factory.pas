{******************************************************************************}
{                                                                              }
{  DelphiDoom: game data library - the factory: the composition root           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameData.Factory;

interface

uses
  DelphiDoom.Palette.Intf, DelphiDoom.GameData.Types, DelphiDoom.GameData.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the library</summary>
  TGameDataFactory = class
  public
    /// <summary>A patch builder that matches colors with AMatcher</summary>
    class function CreatePatchBuilder(const AOptions: TGamePatchOptions;
      const AMatcher: IColorMatcher): IGamePatchBuilder; overload; static;
    /// <summary>A patch builder with the standard color matcher of Libs\Palette</summary>
    class function CreatePatchBuilder(const AOptions: TGamePatchOptions): IGamePatchBuilder; overload; static;
    /// <summary>An empty WAD in memory (a PWAD)</summary>
    class function CreateWadComposer: IGameWadComposer; static;
  end;

implementation

uses
  DelphiDoom.Palette.Factory, DelphiDoom.Wad.Factory, DelphiDoom.Wad.Types,
  DelphiDoom.GameData.PatchBuilder, DelphiDoom.GameData.WadComposer;

{ TGameDataFactory }

class function TGameDataFactory.CreatePatchBuilder(const AOptions: TGamePatchOptions;
  const AMatcher: IColorMatcher): IGamePatchBuilder;
begin
  Result := TGamePatchBuilder.Create(AOptions, AMatcher);
end;

class function TGameDataFactory.CreatePatchBuilder(const AOptions: TGamePatchOptions): IGamePatchBuilder;
begin
  Result := TGamePatchBuilder.Create(AOptions, TPaletteFactory.CreateColorMatcher);
end;

class function TGameDataFactory.CreateWadComposer: IGameWadComposer;
begin
  Result := TGameWadComposer.Create(TWadFactory.CreateBuilder(TWadKind.PWad));
end;

end.
