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
  DelphiDoom.Logging.Intf, DelphiDoom.Radix.Editions, DelphiDoom.Engine.Wad.Converter.Intf,
  DelphiDoom.Engine.Radix.Edition.Intf;

type
  /// <summary>
  ///   The converter of Radix: a file with the signature of RADIX.DAT is translated by the library
  ///   Libs\Radix into the lumps of a WAD (Radix2WAD_Game of the old fork)
  /// </summary>
  TEngineRadixDataConverter = class(TInterfacedObject, IEngineWadConverter, IEngineRadixEdition)
  strict private
    FLog: ILog;
    FCrc32: Cardinal;
    FEdition: TRadixEdition;
    function FileCrc32(const AFileName: string): Cardinal;
  public
    /// <param name="ALog">Where the problems of the file go; EArgumentNilException when nil</param>
    constructor Create(const ALog: ILog);
    function TryConvert(const AFileName: string; out AWad: TBytes): Boolean;
    function GetEdition: TRadixEdition;
    function GetCrc32: Cardinal;
  end;

implementation

uses
  System.Classes,
  DelphiDoom.MathCore.Crc32, DelphiDoom.GameData.Intf, DelphiDoom.Radix.Types, DelphiDoom.Radix.Intf, DelphiDoom.Radix.Factory;

{ TEngineRadixDataConverter }

constructor TEngineRadixDataConverter.Create(const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLog := ALog;
  FEdition := reUnknown;
end;

function TEngineRadixDataConverter.FileCrc32(const AFileName: string): Cardinal;
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Result := TCrc32.CalculateStream(LStream);
  finally
    LStream.Free;
  end;
end;

function TEngineRadixDataConverter.GetEdition: TRadixEdition;
begin
  Result := FEdition;
end;

function TEngineRadixDataConverter.GetCrc32: Cardinal;
begin
  Result := FCrc32;
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
  FCrc32 := FileCrc32(AFileName);
  FEdition := TRadixEditions.FromCrc32(FCrc32);
  FLog.Info(Format('RADIX.DAT: %d lumps translated, CRC32 %s (%s)'#13#10,
    [LWad.Count, IntToHex(FCrc32, 8), TRadixEditions.Title(FEdition)]));
  Result := True;
end;

end.

