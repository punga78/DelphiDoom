{******************************************************************************}
{                                                                              }
{  DelphiDoom: game data library - TGameWadComposer                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  The TWadWriter of the forks (AddData, AddString, AddSeparator), on top of   }
{  the WAD builder of Libs\Wad                                                 }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameData.WadComposer;

interface

uses
  System.SysUtils,
  DelphiDoom.Wad.Intf, DelphiDoom.GameData.Types, DelphiDoom.GameData.Intf;

type
  /// <summary>The lumps that a converter makes, kept in an IWadBuilder</summary>
  TGameWadComposer = class(TInterfacedObject, IGameWadComposer)
  strict private
    FBuilder: IWadBuilder;
  public
    /// <param name="ABuilder">Where the lumps go; EArgumentNilException when nil</param>
    constructor Create(const ABuilder: IWadBuilder);
    function GetCount: Integer;
    function GetLumpName(AIndex: Integer): string;
    function GetLumpData(AIndex: Integer): TBytes;
    function AddLump(const AName: string; const AData: TBytes): Integer;
    function AddMarker(const AName: string): Integer;
    function AddText(const AName, AText: string): Integer;
    function IndexOf(const AName: string): Integer;
    function ToBytes: TBytes;
    procedure SaveToFile(const AFileName: string);
  end;

implementation

uses
  DelphiDoom.Wad.Types;

{ TGameWadComposer }

constructor TGameWadComposer.Create(const ABuilder: IWadBuilder);
begin
  inherited Create;
  if not Assigned(ABuilder) then
    raise EArgumentNilException.Create('ABuilder');
  FBuilder := ABuilder;
end;

function TGameWadComposer.GetCount: Integer;
begin
  Result := FBuilder.Count;
end;

function TGameWadComposer.GetLumpName(AIndex: Integer): string;
begin
  Result := FBuilder.LumpNames[AIndex];
end;

function TGameWadComposer.GetLumpData(AIndex: Integer): TBytes;
begin
  Result := FBuilder.LumpData[AIndex];
end;

function TGameWadComposer.AddLump(const AName: string; const AData: TBytes): Integer;
begin
  try
    Result := FBuilder.AddLump(AName, AData);
  except
    on E: EWadException do
      raise EGameDataException.CreateFmt(SGameDataBadLumpName, [AName]);
  end;
end;

function TGameWadComposer.AddMarker(const AName: string): Integer;
begin
  Result := AddLump(AName, nil);
end;

function TGameWadComposer.AddText(const AName, AText: string): Integer;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, Length(AText));
  for LIndex := 1 to Length(AText) do
    LBytes[LIndex - 1] := Byte(Ord(AText[LIndex]) and $FF);
  Result := AddLump(AName, LBytes);
end;

function TGameWadComposer.IndexOf(const AName: string): Integer;
begin
  Result := FBuilder.IndexOf(AName);
end;

function TGameWadComposer.ToBytes: TBytes;
begin
  Result := FBuilder.ToBytes;
end;

procedure TGameWadComposer.SaveToFile(const AFileName: string);
begin
  FBuilder.SaveToFile(AFileName);
end;

end.
