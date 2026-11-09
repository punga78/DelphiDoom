{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - RADIX.DAT as a WAD in memory                           }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Radix.DataConverter;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf, DelphiDoom.Engine.Wad.Converter.Intf;

type
  /// <summary>
  ///   The converter of Radix: a file with the signature of RADIX.DAT is translated by the library
  ///   Libs\Radix into the lumps of a WAD (Radix2WAD_Game of the old fork)
  /// </summary>
  TEngineRadixDataConverter = class(TInterfacedObject, IEngineWadConverter)
  strict private
    FLog: ILog;
  public
    /// <param name="ALog">Where the problems of the file go; EArgumentNilException when nil</param>
    constructor Create(const ALog: ILog);
    function TryConvert(const AFileName: string; out AWad: TBytes): Boolean;
  end;

implementation

uses
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Types, DelphiDoom.Radix.Intf, DelphiDoom.Radix.Factory;

{ TEngineRadixDataConverter }

constructor TEngineRadixDataConverter.Create(const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLog := ALog;
end;

function TEngineRadixDataConverter.TryConvert(const AFileName: string; out AWad: TBytes): Boolean;
var
  LContainer: IRadixContainer;
  LWad: IGameWadComposer;
begin
  AWad := nil;
  try
    LContainer := TRadixFactory.OpenContainer(AFileName);
  except
    on E: ERadixException do
      Exit(False);
  end;
  LWad := TRadixFactory.CreateTranslator(TRadixLumpNames.Doom).Translate(LContainer);
  AWad := LWad.ToBytes;
  FLog.Info(Format('RADIX.DAT: %d lumps translated'#13#10, [LWad.Count]));
  Result := True;
end;

end.

