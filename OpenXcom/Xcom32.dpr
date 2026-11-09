{******************************************************************************}
{                                                                              }
{  Xcom32: the data files of UFO: Enemy Unknown and Terror from the Deep        }
{  (Microprose 1994/1995) read with the formats of OpenXcom. For now a program  }
{  that decodes a picture, a set of sprites or a block of the battlescape and   }
{  saves them as a PNG (a proof of the data layer, first slice of the issue     }
{  176): no window, no game yet                                                 }
{                                                                              }
{  Usage:  Xcom32 [-data <folder>]... [-pal <n>] [-png <file>]                  }
{                 -pck <file> [-tab <file>] [-w <n>] [-h <n>] [-columns <n>]   }
{               | -dat <file> [-w <n>] [-h <n>] [-columns <n>]                  }
{               | -scr <file> [-w <n>] [-h <n>]     (.SCR, .SPK or .BDY)        }
{               | -map <file> [-rmp <file>] [-z <n>]                            }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this program                   }
{                                                                              }
{******************************************************************************}
program Xcom32;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DelphiDoom.Xcom.Types in '..\Libs\XcomFormats\DelphiDoom.Xcom.Types.pas',
  DelphiDoom.Xcom.Palette in '..\Libs\XcomFormats\DelphiDoom.Xcom.Palette.pas',
  DelphiDoom.Xcom.Image in '..\Libs\XcomFormats\DelphiDoom.Xcom.Image.pas',
  DelphiDoom.Xcom.Map in '..\Libs\XcomFormats\DelphiDoom.Xcom.Map.pas',
  DelphiDoom.Xcom.Intf in '..\Libs\XcomFormats\DelphiDoom.Xcom.Intf.pas',
  DelphiDoom.Xcom.SpriteSheet in '..\Libs\XcomFormats\DelphiDoom.Xcom.SpriteSheet.pas',
  DelphiDoom.Xcom.MapPicture in '..\Libs\XcomFormats\DelphiDoom.Xcom.MapPicture.pas',
  DelphiDoom.Xcom.ImageExporter in '..\Libs\XcomFormats\DelphiDoom.Xcom.ImageExporter.pas',
  DelphiDoom.Xcom.BattlescapePalette in '..\Libs\XcomFormats\DelphiDoom.Xcom.BattlescapePalette.pas',
  DelphiDoom.Xcom.Composition in 'DelphiDoom.Xcom.Composition.pas';

type
  TXcomMode = (xmNone, xmPck, xmDat, xmScr, xmMap);

  TXcomArguments = record
    Folders: TArray<string>;
    Mode: TXcomMode;
    InputFile: string;
    TabFile: string;
    RouteFile: string;
    PngFile: string;
    PaletteIndex: Integer;
    Width: Integer;
    Height: Integer;
    Columns: Integer;
    Layer: Integer;
  end;

procedure ShowUsage;
begin
  Writeln('Xcom32 [-data <folder>]... [-pal <n>] [-png <file>] <what>');
  Writeln('  -data     a folder of the game (the one that has GEODATA\PALETTES.DAT), default: the current one');
  Writeln('  -pal      the palette of GEODATA\PALETTES.DAT (0 geoscape, 1 basescape, 2 graphs, 3 ufopaedia, 4 battlescape), default 0;');
  Writeln('            4..7 are the battlescape palettes of UFOGRAPH\D0..D3.LBM when the game has them (TFTD)');
  Writeln('  -png      the file to write (default xcom.png)');
  Writeln('  -pck      the sprites of a .PCK with its .TAB (-tab, default the same name); -w and -h are the size of a frame (32 x 40)');
  Writeln('  -dat      the frames of a .DAT of raw pictures; -w and -h are the size of a frame');
  Writeln('  -scr      a full picture: .SCR, .SPK or .BDY by the extension; -w and -h default 320 x 200');
  Writeln('  -map      a block of the battlescape (.MAP, with -rmp the routes of it): its cells are written, and a picture');
  Writeln('            of the layer -z (default 0, the lowest) goes into the PNG');
  Writeln('  -columns  frames in a row of the sheet of sprites (default 16)');
end;

function ParseArguments(out AArguments: TXcomArguments): Boolean;
var
  LIndex: Integer;
  LName: string;

  function NextValue: string;
  begin
    if LIndex >= ParamCount then
      raise Exception.CreateFmt('%s needs a value', [LName]);
    Inc(LIndex);
    Result := ParamStr(LIndex);
  end;

begin
  AArguments := Default(TXcomArguments);
  AArguments.Width := 0;
  AArguments.Columns := 16;
  AArguments.PngFile := 'xcom.png';
  LIndex := 1;
  while LIndex <= ParamCount do
  begin
    LName := ParamStr(LIndex).ToLowerInvariant;
    if LName = '-data' then
    begin
      SetLength(AArguments.Folders, Length(AArguments.Folders) + 1);
      AArguments.Folders[High(AArguments.Folders)] := NextValue;
    end
    else if LName = '-pal' then
      AArguments.PaletteIndex := StrToInt(NextValue)
    else if LName = '-png' then
      AArguments.PngFile := NextValue
    else if LName = '-tab' then
      AArguments.TabFile := NextValue
    else if LName = '-rmp' then
      AArguments.RouteFile := NextValue
    else if LName = '-w' then
      AArguments.Width := StrToInt(NextValue)
    else if LName = '-h' then
      AArguments.Height := StrToInt(NextValue)
    else if LName = '-columns' then
      AArguments.Columns := StrToInt(NextValue)
    else if LName = '-z' then
      AArguments.Layer := StrToInt(NextValue)
    else if LName = '-pck' then
    begin
      AArguments.Mode := xmPck;
      AArguments.InputFile := NextValue;
    end
    else if LName = '-dat' then
    begin
      AArguments.Mode := xmDat;
      AArguments.InputFile := NextValue;
    end
    else if LName = '-scr' then
    begin
      AArguments.Mode := xmScr;
      AArguments.InputFile := NextValue;
    end
    else if LName = '-map' then
    begin
      AArguments.Mode := xmMap;
      AArguments.InputFile := NextValue;
    end
    else
      Exit(False);
    Inc(LIndex);
  end;
  Result := AArguments.Mode <> xmNone;
  if Length(AArguments.Folders) = 0 then
    AArguments.Folders := [GetCurrentDir];
end;

procedure WriteMap(const AMap: TXcomMap; const ARecords: TArray<TXcomRmpRecord>; const AResolver: IXcomRouteReader);
var
  LX: Integer;
  LY: Integer;
  LZ: Integer;
  LCell: TXcomMapCell;
  LNodes: TArray<TXcomRouteNode>;
  LCulled: TArray<Integer>;
  LNode: TXcomRouteNode;
begin
  Writeln(Format('Map %d x %d x %d (x, y, layers); %d cells in the file', [AMap.SizeX, AMap.SizeY, AMap.SizeZ,
    Length(AMap.Cells)]));
  Writeln('x   y   z   floor west north object');
  for LZ := 0 to AMap.SizeZ - 1 do
    for LY := 0 to AMap.SizeY - 1 do
      for LX := 0 to AMap.SizeX - 1 do
      begin
        LCell := AMap.CellAt(LX, LY, LZ);
        if (LCell.Floor or LCell.WestWall or LCell.NorthWall or LCell.Obj) <> 0 then
          Writeln(Format('%-3d %-3d %-3d %-5d %-4d %-5d %d', [LX, LY, LZ, LCell.Floor, LCell.WestWall,
            LCell.NorthWall, LCell.Obj]));
      end;
  if Assigned(AResolver) then
  begin
    LNodes := AResolver.Resolve(ARecords, AMap.SizeX, AMap.SizeY, AMap.SizeZ, 0, 0, 0, LCulled);
    Writeln(Format('%d nodes (%d outside the block)', [Length(LNodes), Length(LCulled)]));
    for LNode in LNodes do
      if LNode.IsDummy then
        Writeln(Format('node %d: outside the block', [LNode.Index]))
      else
        Writeln(Format('node %d: (%d, %d, %d) type %d rank %d flags %d priority %d links %d %d %d %d %d',
          [LNode.Index, LNode.X, LNode.Y, LNode.Z, LNode.NodeType, LNode.Rank, LNode.Flags, LNode.Priority,
          LNode.Links[0], LNode.Links[1], LNode.Links[2], LNode.Links[3], LNode.Links[4]]));
  end;
end;

var
  LArguments: TXcomArguments;
  LData: IXcomGameData;
  LPalette: TXcomPalette;
  LImage: TXcomImage;
  LFrames: TArray<TXcomImage>;
  LMap: TXcomMap;
  LRoute: TArray<TXcomRmpRecord>;
  LRouteReader: IXcomRouteReader;
  LExporter: TXcomImageExporter;

begin
  try
    if not ParseArguments(LArguments) then
    begin
      ShowUsage;
      System.ExitCode := 2;
      Exit;
    end;
    LData := TXcomComposition.OpenGameData(LArguments.Folders);
    if (LArguments.PaletteIndex < 4) or (LArguments.PaletteIndex > 4 + TXcomBattlescapePalette.COUNT - 1) then
      LPalette := LData.LoadPalette(LArguments.PaletteIndex)
    else if not TXcomBattlescapePalette.TryLoad(LData.Files, TXcomComposition.CreateLbmReader,
      LArguments.PaletteIndex - 4, LPalette) then
    begin
      // no UFOGRAPH\D0.LBM (UFO: Enemy Unknown): the battlescape palette of PALETTES.DAT, as Mod does
      if LArguments.PaletteIndex <> 4 then
        raise EXcomFileNotFoundException.CreateFmt(SXcomFileMissing, [TXcomBattlescapePalette.FileName(
          LArguments.PaletteIndex - 4)]);
      LPalette := LData.LoadPalette(4);
      LPalette.ApplyBattlescapeGradient;
    end;
    if LPalette.Count = 0 then
      raise EXcomDataException.CreateFmt(SXcomPaletteBadCount, [0, XCOM_PALETTE_COLORS]);
    LExporter := TXcomComposition.CreateImageExporter;
    try
      case LArguments.Mode of
        xmPck, xmDat:
          begin
            if LArguments.Width = 0 then
              LArguments.Width := 32;
            if LArguments.Height = 0 then
              LArguments.Height := 40;
            LFrames := LData.LoadImageSet(LArguments.InputFile, LArguments.TabFile, LArguments.Width,
              LArguments.Height, LPalette);
            LImage := TXcomSpriteSheet.Compose(LFrames, LArguments.Columns);
            Writeln(Length(LFrames), ' frames of ', LArguments.Width, ' x ', LArguments.Height);
            LExporter.Save(LImage, LArguments.PngFile, True);
          end;
        xmScr:
          begin
            if LArguments.Width = 0 then
              LArguments.Width := 320;
            if LArguments.Height = 0 then
              LArguments.Height := 200;
            LImage := LData.LoadImage(LArguments.InputFile, LArguments.Width, LArguments.Height, LPalette);
            LExporter.Save(LImage, LArguments.PngFile, False);
          end;
        xmMap:
          begin
            LMap := LData.LoadMap(LArguments.InputFile);
            LRouteReader := nil;
            LRoute := nil;
            if LArguments.RouteFile <> '' then
            begin
              LRoute := LData.LoadRoute(LArguments.RouteFile);
              LRouteReader := TXcomComposition.CreateRouteReader;
            end;
            WriteMap(LMap, LRoute, LRouteReader);
            LImage := TXcomMapPicture.Render(LMap, LArguments.Layer);
            LImage.Palette := LPalette;
            LImage.HasPalette := True;
            LExporter.Save(LImage, LArguments.PngFile, False);
          end;
      end;
    finally
      LExporter.Free;
    end;
    Writeln('Saved in ', LArguments.PngFile);
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.
