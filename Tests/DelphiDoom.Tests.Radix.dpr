{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the radix library (DUnitX)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Radix;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.GameData.Types in '..\Libs\GameData\DelphiDoom.GameData.Types.pas',
  DelphiDoom.GameData.Intf in '..\Libs\GameData\DelphiDoom.GameData.Intf.pas',
  DelphiDoom.GameData.PatchBuilder in '..\Libs\GameData\DelphiDoom.GameData.PatchBuilder.pas',
  DelphiDoom.GameData.WadComposer in '..\Libs\GameData\DelphiDoom.GameData.WadComposer.pas',
  DelphiDoom.GameData.Factory in '..\Libs\GameData\DelphiDoom.GameData.Factory.pas',
  DelphiDoom.Radix.Types in '..\Libs\Radix\DelphiDoom.Radix.Types.pas',
  DelphiDoom.Radix.Intf in '..\Libs\Radix\DelphiDoom.Radix.Intf.pas',
  DelphiDoom.Radix.Container in '..\Libs\Radix\DelphiDoom.Radix.Container.pas',
  DelphiDoom.Radix.PaletteBuilder in '..\Libs\Radix\DelphiDoom.Radix.PaletteBuilder.pas',
  DelphiDoom.Radix.Context in '..\Libs\Radix\DelphiDoom.Radix.Context.pas',
  DelphiDoom.Radix.BitmapTable in '..\Libs\Radix\DelphiDoom.Radix.BitmapTable.pas',
  DelphiDoom.Radix.PalettePart in '..\Libs\Radix\DelphiDoom.Radix.PalettePart.pas',
  DelphiDoom.Radix.TexturePart in '..\Libs\Radix\DelphiDoom.Radix.TexturePart.pas',
  DelphiDoom.Radix.FlatPart in '..\Libs\Radix\DelphiDoom.Radix.FlatPart.pas',
  DelphiDoom.Radix.GraphicsPart in '..\Libs\Radix\DelphiDoom.Radix.GraphicsPart.pas',
  DelphiDoom.Radix.SmallFontPart in '..\Libs\Radix\DelphiDoom.Radix.SmallFontPart.pas',
  DelphiDoom.Radix.LumpGroupPart in '..\Libs\Radix\DelphiDoom.Radix.LumpGroupPart.pas',
  DelphiDoom.Radix.Bitmap in '..\Libs\Radix\DelphiDoom.Radix.Bitmap.pas',
  DelphiDoom.Radix.BitmapOps in '..\Libs\Radix\DelphiDoom.Radix.BitmapOps.pas',
  DelphiDoom.Radix.FontData in '..\Libs\Radix\DelphiDoom.Radix.FontData.pas',
  DelphiDoom.Radix.PerlinNoise in '..\Libs\Radix\DelphiDoom.Radix.PerlinNoise.pas',
  DelphiDoom.Radix.FontTinter in '..\Libs\Radix\DelphiDoom.Radix.FontTinter.pas',
  DelphiDoom.Radix.BigFontPart in '..\Libs\Radix\DelphiDoom.Radix.BigFontPart.pas',
  DelphiDoom.Radix.DosFontPart in '..\Libs\Radix\DelphiDoom.Radix.DosFontPart.pas',
  DelphiDoom.Radix.MenuTranslationPart in '..\Libs\Radix\DelphiDoom.Radix.MenuTranslationPart.pas',
  DelphiDoom.Radix.CockpitPart in '..\Libs\Radix\DelphiDoom.Radix.CockpitPart.pas',
  DelphiDoom.Radix.SoundPart in '..\Libs\Radix\DelphiDoom.Radix.SoundPart.pas',
  DelphiDoom.Radix.SpriteData in '..\Libs\Radix\DelphiDoom.Radix.SpriteData.pas',
  DelphiDoom.Radix.Things in '..\Libs\Radix\DelphiDoom.Radix.Things.pas',
  DelphiDoom.Radix.SpriteList in '..\Libs\Radix\DelphiDoom.Radix.SpriteList.pas',
  DelphiDoom.Radix.SpriteCatalog in '..\Libs\Radix\DelphiDoom.Radix.SpriteCatalog.pas',
  DelphiDoom.Radix.SpritePart in '..\Libs\Radix\DelphiDoom.Radix.SpritePart.pas',
  DelphiDoom.Radix.Level.Converter in '..\Libs\Radix\DelphiDoom.Radix.Level.Converter.pas',
  DelphiDoom.Radix.Level.Coordinates in '..\Libs\Radix\DelphiDoom.Radix.Level.Coordinates.pas',
  DelphiDoom.Radix.Level.Data in '..\Libs\Radix\DelphiDoom.Radix.Level.Data.pas',
  DelphiDoom.Radix.Level.DoomMap in '..\Libs\Radix\DelphiDoom.Radix.Level.DoomMap.pas',
  DelphiDoom.Radix.Level.Factory in '..\Libs\Radix\DelphiDoom.Radix.Level.Factory.pas',
  DelphiDoom.Radix.Level.FixNone in '..\Libs\Radix\DelphiDoom.Radix.Level.FixNone.pas',
  DelphiDoom.Radix.Level.FixOps in '..\Libs\Radix\DelphiDoom.Radix.Level.FixOps.pas',
  DelphiDoom.Radix.Level.FixSelector in '..\Libs\Radix\DelphiDoom.Radix.Level.FixSelector.pas',
  DelphiDoom.Radix.Level.FixV10 in '..\Libs\Radix\DelphiDoom.Radix.Level.FixV10.pas',
  DelphiDoom.Radix.Level.FixV11 in '..\Libs\Radix\DelphiDoom.Radix.Level.FixV11.pas',
  DelphiDoom.Radix.Level.FixV2 in '..\Libs\Radix\DelphiDoom.Radix.Level.FixV2.pas',
  DelphiDoom.Radix.Level.Intf in '..\Libs\Radix\DelphiDoom.Radix.Level.Intf.pas',
  DelphiDoom.Radix.Level.Reader in '..\Libs\Radix\DelphiDoom.Radix.Level.Reader.pas',
  DelphiDoom.Radix.Level.Table in '..\Libs\Radix\DelphiDoom.Radix.Level.Table.pas',
  DelphiDoom.Radix.Level.Types in '..\Libs\Radix\DelphiDoom.Radix.Level.Types.pas',
  DelphiDoom.Radix.Level.Versions in '..\Libs\Radix\DelphiDoom.Radix.Level.Versions.pas',
  DelphiDoom.Radix.Editions in '..\Libs\Radix\DelphiDoom.Radix.Editions.pas',
  DelphiDoom.Radix.LumpAliases in '..\Libs\Radix\DelphiDoom.Radix.LumpAliases.pas',
  DelphiDoom.Radix.LevelPart in '..\Libs\Radix\DelphiDoom.Radix.LevelPart.pas',
  DelphiDoom.Radix.Translator in '..\Libs\Radix\DelphiDoom.Radix.Translator.pas',
  DelphiDoom.Radix.Factory in '..\Libs\Radix\DelphiDoom.Radix.Factory.pas',
  DelphiDoom.Tests.GameData.Scenarios in 'Source\DelphiDoom.Tests.GameData.Scenarios.pas',
  DelphiDoom.Tests.Radix.DatBuilder in 'Source\DelphiDoom.Tests.Radix.DatBuilder.pas',
  DelphiDoom.Tests.Radix.Container in 'Source\DelphiDoom.Tests.Radix.Container.pas',
  DelphiDoom.Tests.Radix.PaletteBuilder in 'Source\DelphiDoom.Tests.Radix.PaletteBuilder.pas',
  DelphiDoom.Tests.Radix.TexturePart in 'Source\DelphiDoom.Tests.Radix.TexturePart.pas',
  DelphiDoom.Tests.Radix.FlatPart in 'Source\DelphiDoom.Tests.Radix.FlatPart.pas',
  DelphiDoom.Tests.Radix.GraphicsPart in 'Source\DelphiDoom.Tests.Radix.GraphicsPart.pas',
  DelphiDoom.Tests.Radix.SmallFontPart in 'Source\DelphiDoom.Tests.Radix.SmallFontPart.pas',
  DelphiDoom.Tests.Radix.LumpGroupPart in 'Source\DelphiDoom.Tests.Radix.LumpGroupPart.pas',
  DelphiDoom.Tests.Radix.Bitmap in 'Source\DelphiDoom.Tests.Radix.Bitmap.pas',
  DelphiDoom.Tests.Radix.BitmapOps in 'Source\DelphiDoom.Tests.Radix.BitmapOps.pas',
  DelphiDoom.Tests.Radix.FontParts in 'Source\DelphiDoom.Tests.Radix.FontParts.pas',
  DelphiDoom.Tests.Radix.CockpitSoundParts in 'Source\DelphiDoom.Tests.Radix.CockpitSoundParts.pas',
  DelphiDoom.Tests.Radix.SpriteList in 'Source\DelphiDoom.Tests.Radix.SpriteList.pas',
  DelphiDoom.Tests.Radix.SpritePart in 'Source\DelphiDoom.Tests.Radix.SpritePart.pas',
  DelphiDoom.Tests.Radix.LevelBuilder in 'Source\DelphiDoom.Tests.Radix.LevelBuilder.pas',
  DelphiDoom.Tests.Radix.LevelConverter in 'Source\DelphiDoom.Tests.Radix.LevelConverter.pas',
  DelphiDoom.Tests.Radix.LevelCoordinates in 'Source\DelphiDoom.Tests.Radix.LevelCoordinates.pas',
  DelphiDoom.Tests.Radix.LevelDoomMap in 'Source\DelphiDoom.Tests.Radix.LevelDoomMap.pas',
  DelphiDoom.Tests.Radix.LevelPart in 'Source\DelphiDoom.Tests.Radix.LevelPart.pas',
  DelphiDoom.Tests.Radix.LevelReader in 'Source\DelphiDoom.Tests.Radix.LevelReader.pas',
  DelphiDoom.Tests.Radix.LevelVersions in 'Source\DelphiDoom.Tests.Radix.LevelVersions.pas',
  DelphiDoom.Tests.Shared.Skip in 'Source\DelphiDoom.Tests.Shared.Skip.pas',
  DelphiDoom.Tests.Radix.Editions in 'Source\DelphiDoom.Tests.Radix.Editions.pas',
  DelphiDoom.Tests.Radix.LumpAliases in 'Source\DelphiDoom.Tests.Radix.LumpAliases.pas',
  DelphiDoom.Radix.MapInfo.Types in '..\Libs\Radix\DelphiDoom.Radix.MapInfo.Types.pas',
  DelphiDoom.Radix.MapInfo.Reader in '..\Libs\Radix\DelphiDoom.Radix.MapInfo.Reader.pas',
  DelphiDoom.Radix.SlopePlanes in '..\Libs\Radix\DelphiDoom.Radix.SlopePlanes.pas',
  DelphiDoom.Tests.Radix.MapInfo in 'Source\DelphiDoom.Tests.Radix.MapInfo.pas',
  DelphiDoom.Engine.Wad.Lumps.Intf in '..\Base\DelphiDoom.Engine.Wad.Lumps.Intf.pas',
  DelphiDoom.Engine.Wad.Aliases.Intf in '..\Base\DelphiDoom.Engine.Wad.Aliases.Intf.pas',
  DelphiDoom.Engine.Radix.LumpAliases in '..\Base\DelphiDoom.Engine.Radix.LumpAliases.pas',
  DelphiDoom.Tests.Radix.EngineLumpAliases in 'Source\DelphiDoom.Tests.Radix.EngineLumpAliases.pas',
  DelphiDoom.Radix.Hud.Gauges in '..\Libs\Radix\DelphiDoom.Radix.Hud.Gauges.pas',
  DelphiDoom.Tests.Radix.HudGauges in 'Source\DelphiDoom.Tests.Radix.HudGauges.pas',
  DelphiDoom.Radix.Flight.Model in '..\Libs\Radix\DelphiDoom.Radix.Flight.Model.pas',
  DelphiDoom.Radix.Debriefing in '..\Libs\Radix\DelphiDoom.Radix.Debriefing.pas',
  DelphiDoom.Tests.Radix.FlightModel in 'Source\DelphiDoom.Tests.Radix.FlightModel.pas',
  DelphiDoom.Radix.Control.Rules in '..\Libs\Radix\DelphiDoom.Radix.Control.Rules.pas',
  DelphiDoom.Tests.Radix.ControlRules in 'Source\DelphiDoom.Tests.Radix.ControlRules.pas',
  DelphiDoom.ActorDef.Types in '..\Libs\ActorDef\DelphiDoom.ActorDef.Types.pas',
  DelphiDoom.Dehacked.Types in '..\Libs\Dehacked\DelphiDoom.Dehacked.Types.pas',
  DelphiDoom.Dehacked.Section in '..\Libs\Dehacked\DelphiDoom.Dehacked.Section.pas',
  DelphiDoom.Dehacked.Intf in '..\Libs\Dehacked\DelphiDoom.Dehacked.Intf.pas',
  DelphiDoom.Tests.Radix.ActorThingFields in 'Source\DelphiDoom.Tests.Radix.ActorThingFields.pas',
  DelphiDoom.Radix.ActorProperties in '..\Libs\Radix\DelphiDoom.Radix.ActorProperties.pas',
  DelphiDoom.Tests.Radix.ActorProperties in 'Source\DelphiDoom.Tests.Radix.ActorProperties.pas',
  DelphiDoom.Radix.Pilot.Rules in '..\Libs\Radix\DelphiDoom.Radix.Pilot.Rules.pas',
  DelphiDoom.Tests.Radix.PilotRules in 'Source\DelphiDoom.Tests.Radix.PilotRules.pas',
  DelphiDoom.Radix.Weapon.Rules in '..\Libs\Radix\DelphiDoom.Radix.Weapon.Rules.pas',
  DelphiDoom.Tests.Radix.WeaponRules in 'Source\DelphiDoom.Tests.Radix.WeaponRules.pas',
  DelphiDoom.Radix.LevelLogic.Types in '..\Libs\Radix\DelphiDoom.Radix.LevelLogic.Types.pas',
  DelphiDoom.Radix.LevelLumps.Reader in '..\Libs\Radix\DelphiDoom.Radix.LevelLumps.Reader.pas',
  DelphiDoom.Radix.TriggerGrid in '..\Libs\Radix\DelphiDoom.Radix.TriggerGrid.pas',
  DelphiDoom.Radix.TriggerLogic in '..\Libs\Radix\DelphiDoom.Radix.TriggerLogic.pas',
  DelphiDoom.Radix.Action.Rules in '..\Libs\Radix\DelphiDoom.Radix.Action.Rules.pas',
  DelphiDoom.Radix.Messages in '..\Libs\Radix\DelphiDoom.Radix.Messages.pas',
  DelphiDoom.Radix.Thing.Spawn in '..\Libs\Radix\DelphiDoom.Radix.Thing.Spawn.pas',
  DelphiDoom.Tests.Radix.LevelLumps in 'Source\DelphiDoom.Tests.Radix.LevelLumps.pas',
  DelphiDoom.Tests.Radix.TriggerGrid in 'Source\DelphiDoom.Tests.Radix.TriggerGrid.pas',
  DelphiDoom.Tests.Radix.TriggerLogic in 'Source\DelphiDoom.Tests.Radix.TriggerLogic.pas',
  DelphiDoom.Radix.SaveGame.Types in '..\Libs\Radix\DelphiDoom.Radix.SaveGame.Types.pas',
  DelphiDoom.Radix.SaveGame.Codec in '..\Libs\Radix\DelphiDoom.Radix.SaveGame.Codec.pas',
  DelphiDoom.Tests.Radix.SaveGameCodec in 'Source\DelphiDoom.Tests.Radix.SaveGameCodec.pas',
  DelphiDoom.Tests.Radix.ActionRules in 'Source\DelphiDoom.Tests.Radix.ActionRules.pas',
  DelphiDoom.Tests.Radix.Debriefing in 'Source\DelphiDoom.Tests.Radix.Debriefing.pas',
  DelphiDoom.Tests.Radix.Translator in 'Source\DelphiDoom.Tests.Radix.Translator.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NUnitLogger: ITestLogger;

begin
  try
    TDUnitX.CheckCommandLine;
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.FailsOnNoAsserts := False;

    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);
    NUnitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NUnitLogger);

    Results := Runner.Execute;
    if not Results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.



