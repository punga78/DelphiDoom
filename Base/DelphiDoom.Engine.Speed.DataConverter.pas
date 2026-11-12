{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - SPEEDH.JCL as a WAD in memory                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Speed.DataConverter;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf, DelphiDoom.Speed.Types, DelphiDoom.Engine.Wad.Converter.Intf;

type
  /// <summary>
  ///   The converter of Speed Haste: a file with the signature of SPEEDH.JCL is translated by the
  ///   library Libs\Speed into the lumps of a WAD (SH_ConvertSpeedDataToWAD of the old fork)
  /// </summary>
  TEngineSpeedDataConverter = class(TInterfacedObject, IEngineWadConverter)
  strict private
    FLog: ILog;
    FModels: TArray<TSpeedPakEntry>;
  public
    /// <param name="ALog">Where the problems of the file go; EArgumentNilException when nil</param>
    constructor Create(const ALog: ILog);
    function TryConvert(const AFileName: string; out AWad: TBytes): Boolean;
    /// <summary>
    ///   The 3D models (MODELS\name.I3D) of the last container converted: where they lie inside the
    ///   file. The OpenGL adapter of the models reads them from there; nothing reads them yet
    /// </summary>
    property Models: TArray<TSpeedPakEntry> read FModels;
  end;

implementation

uses
  DelphiDoom.GameData.Intf, DelphiDoom.GameData.Factory, DelphiDoom.Speed.Intf,
  DelphiDoom.Speed.DoomFontAliases,
  DelphiDoom.Speed.Factory;

{ TEngineSpeedDataConverter }

constructor TEngineSpeedDataConverter.Create(const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLog := ALog;
end;

function TEngineSpeedDataConverter.TryConvert(const AFileName: string; out AWad: TBytes): Boolean;
var
  LContainer: ISpeedContainer;
  LWad: IGameWadComposer;
begin
  AWad := nil;
  try
    LContainer := TSpeedFactory.OpenContainer(AFileName);
  except
    on E: ESpeedException do
      Exit(False);
  end;
  LWad := TGameDataFactory.CreateWadComposer;
  FModels := TSpeedFactory.CreateTranslator(FLog).Translate(LContainer, LWad);
  // the messages of the engine are written with the font of the game
  TSpeedDoomFontAliases.Append(LWad);
  AWad := LWad.ToBytes;
  FLog.Info(Format('SPEEDH.JCL: %d lumps translated, %d models'#13#10, [LWad.Count, Length(FModels)]));
  Result := True;
end;

end.
