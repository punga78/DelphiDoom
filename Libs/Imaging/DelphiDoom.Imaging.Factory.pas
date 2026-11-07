{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - the factory: the composition root             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.Factory;

interface

uses
  DelphiDoom.Imaging.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the library</summary>
  TImagingFactory = class sealed
  public
    class function CreateColumnPainter: IImagingColumnPainter; static;
    class function CreateColumnRebuilder: IImagingColumnRebuilder; static;
    class function CreateFixedColumnBuilder: IImagingFixedColumnBuilder; static;
    /// <summary>A patch reader that paints with the painter that it gets (nil: the standard one)</summary>
    class function CreatePatchReader(const APainter: IImagingColumnPainter = nil): IImagingPatchReader; static;
    class function CreateFlatReader: IImagingFlatReader; static;
    class function CreateFlatShrinker: IImagingFlatShrinker; static;
    class function CreateSpanGrower: IImagingSpanGrower; static;
    class function CreateColumnExpander: IImagingColumnExpander; static;
    class function CreateHiResTableBuilder: IImagingHiResTableBuilder; static;
    /// <param name="ARandom">The random numbers that decide when each column starts</param>
    class function CreateMeltWipe(const ARandom: IImagingRandom): IImagingMeltWipe; static;
    /// <summary>The table of the sines that the engine has, computed</summary>
    class function CreateSineTable: IImagingSineTable; static;
    /// <param name="ASines">The sines to use (nil: the computed table of the engine)</param>
    class function CreateWallScale(const ASines: IImagingSineTable = nil): IImagingWallScale; static;
    /// <param name="AColors">The search of the nearest color of the palette</param>
    class function CreateThumbnailBuilder(const AColors: IImagingColorIndex): IImagingThumbnailBuilder; static;
  end;

implementation

uses
  DelphiDoom.Imaging.ColumnPainter, DelphiDoom.Imaging.ColumnRebuilder,
  DelphiDoom.Imaging.FixedColumn, DelphiDoom.Imaging.PatchReader,
  DelphiDoom.Imaging.FlatReader, DelphiDoom.Imaging.FlatShrinker,
  DelphiDoom.Imaging.SpanGrower, DelphiDoom.Imaging.ColumnExpander,
  DelphiDoom.Imaging.HiResTables, DelphiDoom.Imaging.MeltWipe,
  DelphiDoom.Imaging.SineTable, DelphiDoom.Imaging.WallScale,
  DelphiDoom.Imaging.ThumbnailBuilder;

{ TImagingFactory }

class function TImagingFactory.CreateColumnPainter: IImagingColumnPainter;
begin
  Result := TImagingColumnPainter.Create;
end;

class function TImagingFactory.CreateColumnRebuilder: IImagingColumnRebuilder;
begin
  Result := TImagingColumnRebuilder.Create;
end;

class function TImagingFactory.CreateFixedColumnBuilder: IImagingFixedColumnBuilder;
begin
  Result := TImagingFixedColumnBuilder.Create;
end;

class function TImagingFactory.CreatePatchReader(
  const APainter: IImagingColumnPainter): IImagingPatchReader;
begin
  if Assigned(APainter) then
    Result := TImagingPatchReader.Create(APainter)
  else
    Result := TImagingPatchReader.Create(TImagingColumnPainter.Create);
end;

class function TImagingFactory.CreateFlatReader: IImagingFlatReader;
begin
  Result := TImagingFlatReader.Create;
end;

class function TImagingFactory.CreateFlatShrinker: IImagingFlatShrinker;
begin
  Result := TImagingFlatShrinker.Create;
end;

class function TImagingFactory.CreateSpanGrower: IImagingSpanGrower;
begin
  Result := TImagingSpanGrower.Create;
end;

class function TImagingFactory.CreateColumnExpander: IImagingColumnExpander;
begin
  Result := TImagingColumnExpander.Create;
end;

class function TImagingFactory.CreateHiResTableBuilder: IImagingHiResTableBuilder;
begin
  Result := TImagingHiResTableBuilder.Create;
end;

class function TImagingFactory.CreateMeltWipe(const ARandom: IImagingRandom): IImagingMeltWipe;
begin
  Result := TImagingMeltWipe.Create(ARandom);
end;

class function TImagingFactory.CreateSineTable: IImagingSineTable;
begin
  Result := TImagingFixedSineTable.Create;
end;

class function TImagingFactory.CreateWallScale(const ASines: IImagingSineTable): IImagingWallScale;
begin
  if Assigned(ASines) then
    Result := TImagingWallScale.Create(ASines)
  else
    Result := TImagingWallScale.Create(TImagingFixedSineTable.Create);
end;

class function TImagingFactory.CreateThumbnailBuilder(
  const AColors: IImagingColorIndex): IImagingThumbnailBuilder;
begin
  Result := TImagingThumbnailBuilder.Create(AColors);
end;

end.
