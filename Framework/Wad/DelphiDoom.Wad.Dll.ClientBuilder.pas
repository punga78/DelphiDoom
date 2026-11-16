{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - a builder of the DLL seen as IWadBuilder          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.ClientBuilder;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf, DelphiDoom.Wad.Dll.Intf;

type
  /// <summary>IWadBuilder on top of an IWadDllBuilder</summary>
  TWadDllClientBuilder = class(TInterfacedObject, IWadBuilder)
  private
    FDll: IWadDll;
    FBuilder: IWadDllBuilder;
  public
    constructor Create(const ADll: IWadDll; const ABuilder: IWadDllBuilder);
    function GetKind: TWadKind;
    procedure SetKind(AValue: TWadKind);
    function GetCount: Integer;
    function GetLumpName(AIndex: Integer): string;
    function GetLumpData(AIndex: Integer): TBytes;
    function AddLump(const AName: string; const AData: TBytes): Integer;
    procedure InsertLump(AIndex: Integer; const AName: string; const AData: TBytes);
    procedure ReplaceLump(AIndex: Integer; const AData: TBytes);
    procedure RenameLump(AIndex: Integer; const AName: string);
    procedure DeleteLump(AIndex: Integer);
    procedure MoveLump(AFromIndex, AToIndex: Integer);
    function IndexOf(const AName: string): Integer;
    procedure LoadFrom(const ASource: IWadSource);
    procedure Clear;
    function ToBytes: TBytes;
    procedure SaveToStream(AStream: TStream);
    procedure SaveToFile(const AFileName: string);
  end;

implementation

uses
  DelphiDoom.Wad.Dll.ClientCheck, DelphiDoom.Wad.Dll.ClientSource;

function PointerOf(const AData: TBytes): Pointer;
begin
  if Length(AData) > 0 then
    Result := @AData[0]
  else
    Result := nil;
end;

{ TWadDllClientBuilder }

constructor TWadDllClientBuilder.Create(const ADll: IWadDll; const ABuilder: IWadDllBuilder);
begin
  inherited Create;
  FDll := ADll;
  FBuilder := ABuilder;
end;

function TWadDllClientBuilder.GetKind: TWadKind;
begin
  Result := TWadKind(FBuilder.GetKind);
end;

procedure TWadDllClientBuilder.SetKind(AValue: TWadKind);
begin
  TWadDllClientCheck.Check(FDll, FBuilder.SetKind(Ord(AValue)));
end;

function TWadDllClientBuilder.GetCount: Integer;
begin
  Result := FBuilder.GetCount;
end;

function TWadDllClientBuilder.GetLumpName(AIndex: Integer): string;
begin
  Result := TWadDllClientCheck.Text(FDll,
    function(ABuffer: PAnsiChar; ABufferSize: Cardinal; out ALength: Cardinal): Integer
    begin
      Result := FBuilder.GetLumpName(AIndex, ABuffer, ABufferSize, ALength);
    end);
end;

function TWadDllClientBuilder.GetLumpData(AIndex: Integer): TBytes;
var
  LSize: Integer;
begin
  TWadDllClientCheck.Check(FDll, FBuilder.GetLumpSize(AIndex, LSize));
  SetLength(Result, LSize);
  TWadDllClientCheck.Check(FDll, FBuilder.ReadLump(AIndex, PointerOf(Result), Cardinal(LSize)));
end;

function TWadDllClientBuilder.AddLump(const AName: string; const AData: TBytes): Integer;
var
  LName: UTF8String;
begin
  LName := UTF8String(AName);
  TWadDllClientCheck.Check(FDll, FBuilder.AddLump(PAnsiChar(LName), PointerOf(AData),
    Cardinal(Length(AData)), Result));
end;

procedure TWadDllClientBuilder.InsertLump(AIndex: Integer; const AName: string; const AData: TBytes);
var
  LName: UTF8String;
begin
  LName := UTF8String(AName);
  TWadDllClientCheck.Check(FDll, FBuilder.InsertLump(AIndex, PAnsiChar(LName), PointerOf(AData),
    Cardinal(Length(AData))));
end;

procedure TWadDllClientBuilder.ReplaceLump(AIndex: Integer; const AData: TBytes);
begin
  TWadDllClientCheck.Check(FDll, FBuilder.ReplaceLump(AIndex, PointerOf(AData), Cardinal(Length(AData))));
end;

procedure TWadDllClientBuilder.RenameLump(AIndex: Integer; const AName: string);
var
  LName: UTF8String;
begin
  LName := UTF8String(AName);
  TWadDllClientCheck.Check(FDll, FBuilder.RenameLump(AIndex, PAnsiChar(LName)));
end;

procedure TWadDllClientBuilder.DeleteLump(AIndex: Integer);
begin
  TWadDllClientCheck.Check(FDll, FBuilder.DeleteLump(AIndex));
end;

procedure TWadDllClientBuilder.MoveLump(AFromIndex, AToIndex: Integer);
begin
  TWadDllClientCheck.Check(FDll, FBuilder.MoveLump(AFromIndex, AToIndex));
end;

function TWadDllClientBuilder.IndexOf(const AName: string): Integer;
var
  LName: UTF8String;
begin
  LName := UTF8String(AName);
  TWadDllClientCheck.Check(FDll, FBuilder.IndexOf(PAnsiChar(LName), Result));
end;

procedure TWadDllClientBuilder.LoadFrom(const ASource: IWadSource);
begin
  if not (ASource is TWadDllClientSource) then
    raise EWadException.Create('The source was not made by the WAD DLL client');
  TWadDllClientCheck.Check(FDll, FBuilder.LoadFrom((ASource as TWadDllClientSource).DllSource));
end;

procedure TWadDllClientBuilder.Clear;
begin
  TWadDllClientCheck.Check(FDll, FBuilder.Clear);
end;

function TWadDllClientBuilder.ToBytes: TBytes;
var
  LSize, LWritten: Cardinal;
begin
  TWadDllClientCheck.Check(FDll, FBuilder.GetSerializedSize(LSize));
  SetLength(Result, LSize);
  TWadDllClientCheck.Check(FDll, FBuilder.Serialize(PointerOf(Result), LSize, LWritten));
  SetLength(Result, LWritten);
end;

procedure TWadDllClientBuilder.SaveToStream(AStream: TStream);
var
  LBytes: TBytes;
begin
  LBytes := ToBytes;
  AStream.WriteBuffer(LBytes[0], Length(LBytes));
end;

procedure TWadDllClientBuilder.SaveToFile(const AFileName: string);
var
  LPath: UTF8String;
begin
  LPath := UTF8String(AFileName);
  TWadDllClientCheck.Check(FDll, FBuilder.SaveToFile(PAnsiChar(LPath)));
end;

end.
