{******************************************************************************}
{                                                                              }
{  Warcraft32: Warcraft: Orcs & Humans in the class system of DelphiDoom       }
{                                                                              }
{  A port to classes of the remake in C war1 (acoto87/war1, zlib License) that  }
{  plays the DOS game from its DATA.WAR: the title, the menus, the briefings    }
{  and the missions of the campaigns, in a window of 320 x 200 pixels times a   }
{  scale. The data of the game are not in the repository: -data says where      }
{  they are. Libs\War has the game; this folder has the program                 }
{                                                                              }
{  Usage:  Warcraft32 [-data <folder>] [-fonts <folder>] [-scale <1..8>]        }
{                     [-play human|orc <1..12>] [-load <file>] [-save <file>]   }
{                     [-headless] [-script <file>] [-shot <file>] [-seed <n>]   }
{                     [-quitafter <frames>] [-audiostats] [-nosound] [-nointro] }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program Warcraft32;

{$APPTYPE CONSOLE}

{$R 'Warcraft32_Icon.res' 'Warcraft32_Icon.rc'}

uses
  System.SysUtils,
  DelphiDoom.War.App.Options in '..\Libs\War\DelphiDoom.War.App.Options.pas',
  DelphiDoom.War.App.OptionsParser in '..\Libs\War\DelphiDoom.War.App.OptionsParser.pas',
  DelphiDoom.War.Composition in 'DelphiDoom.War.Composition.pas';

procedure ShowUsage;
begin
  Writeln('Warcraft32               the game: the title, the menus and the campaigns, with DATA.WAR of the DOS game');
  Writeln('Warcraft32 [-data <folder>] [-fonts <folder>] [-scale <n>] [-play human|orc <n>] [-nosound]');
  Writeln('  -data    the folder with DATA.WAR (or with its folder DATA); default the folder of the program');
  Writeln('  -fonts   the folder with war1_font_1.png and war1_font_2.png of the remake; default the data folder, and');
  Writeln('           Reference\war1\assets of a folder above it');
  Writeln('  -scale   the window is that many times 320 x 200 (1..8, default 3)');
  Writeln('  -play    goes at once to the mission of a campaign (human or orc, 1..12) instead of the title');
  Writeln('  -nosound no sound device');
  Writeln('  -nointro no introduction (the animations CAVE1..TITLE after the logo)');
  Writeln('  keys     F10 menu of the map (Save and Load there), F5 saves and F9 loads the quick slot,');
  Writeln('           Ctrl+P pauses; the quick slot is the file SAVES\quick.war1sav next to the program;');
  Writeln('           Warcraft32.ini next to the program keeps the volumes');
  Writeln('Warcraft32 -load <file> | -save <file>     starts from a saved game | writes one when the program ends');
  Writeln('Warcraft32 -headless [-quitafter <frames>] [-seed <n>] [-shot <file>] [-audiostats] [-play ...] [-script <file>]');
  Writeln('  -headless   no window, no sound device and no clock: a frame is always 1/60 of a second, as fast as the');
  Writeln('              machine goes, and the same options always give the same game (default 1800 frames)');
  Writeln('  -script     a file of the commands of Tools\Verifica\197 and 200 (scene, campaign, move, key, text, run ...):');
  Writeln('              writes a line "H n hash" for each picture the script asks for');
  Writeln('  -shot       saves the last picture as a PNG when the program ends');
  Writeln('  -seed       where the generator of random numbers of the game starts (default 1)');
  Writeln('  -quitafter  the program ends after that number of frames');
  Writeln('  -audiostats writes at the end what the sound did');
end;

var
  LArguments: TArray<string>;
  LOptions: TWarAppOptions;
  LError: string;
  LIndex: Integer;
  LFrames: Integer;

begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}
  try
    SetLength(LArguments, ParamCount);
    for LIndex := 1 to ParamCount do
      LArguments[LIndex - 1] := ParamStr(LIndex);
    if not TWarAppOptionsParser.TryParse(LArguments, LOptions, LError) then
    begin
      Writeln(ErrOutput, LError);
      ShowUsage;
      System.ExitCode := 2;
      Exit;
    end;
    if LOptions.ShowHelp then
    begin
      ShowUsage;
      Exit;
    end;
    LFrames := TWarComposition.Run(LOptions, ExtractFilePath(ParamStr(0)),
      procedure(AText: string)
      begin
        Writeln(AText);
      end);
    Writeln('Ran ', LFrames, ' frames');
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName, ': ', E.Message);
      System.ExitCode := 1;
    end;
  end;
end.
