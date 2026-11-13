{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, loading            }
{  animation.cfg                                                               }
{                                                                              }
{  The file reading of CG_ParseAnimationFile (trap_FS_FOpenFile and            }
{  trap_FS_Read) on an injected source. Based on the Quake III Arena GPL       }
{  Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc. This   }
{  unit is derived from the Quake III Arena source code and is therefore       }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.AnimationLoader;

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Intf;

type
  /// <summary>Reads animation.cfg from a text source and hands it to the parser</summary>
  TQ3AnimationLoader = class(TInterfacedObject, IQ3AnimationLoader)
  strict private
    FSource: IQ3TextSource;
    FParser: IQ3AnimationParser;
  public
    constructor Create(const ASource: IQ3TextSource; const AParser: IQ3AnimationParser);
    function Load(const AFileName: string): IQ3AnimationConfig;
  end;

implementation

constructor TQ3AnimationLoader.Create(const ASource: IQ3TextSource; const AParser: IQ3AnimationParser);
begin
  inherited Create;
  FSource := ASource;
  FParser := AParser;
end;

function TQ3AnimationLoader.Load(const AFileName: string): IQ3AnimationConfig;
var
  LText: AnsiString;
begin
  LText := FSource.ReadText(AFileName);
  Result := FParser.Parse(LText, AFileName);
end;

end.
