{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the DDVOX format (text)                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.Format.Ddvox;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>
  ///   A DDVOX file is a text: the side of the cube, then the voxels column by column (x, then
  ///   y, then z) as numbers that are colors, or "skip n" for n empty voxels. The colors are
  ///   written as blue-green-red and are swapped.
  /// </summary>
  TVoxelDdvoxFormat = class(TInterfacedObject, IVoxelFormat)
  strict private
    FLog: ILog;
  public
    constructor Create(const ALog: ILog);
    function Handles(const AExtension: string): Boolean;
    function Locate(const ASource: IVoxelFileSource; const AName: string; out ABytes: TBytes): Boolean;
    function Decode(const ABytes: TBytes): IVoxelModel;
  end;

implementation

uses
  DelphiDoom.Scanner.Scanner,
  DelphiDoom.Voxel.Colors,
  DelphiDoom.Voxel.Model;

{ TVoxelDdvoxFormat }

constructor TVoxelDdvoxFormat.Create(const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FLog := ALog;
end;

function TVoxelDdvoxFormat.Handles(const AExtension: string): Boolean;
begin
  Result := AExtension = '.DDVOX';
end;

function TVoxelDdvoxFormat.Locate(const ASource: IVoxelFileSource; const AName: string;
  out ABytes: TBytes): Boolean;
begin
  Result := ASource.TryReadFile(AName, ABytes);
end;

function TVoxelDdvoxFormat.Decode(const ABytes: TBytes): IVoxelModel;
var
  LText: string;
  LScanner: TScriptScanner;
  LSide: Integer;
  LCells: TArray<Cardinal>;
  LX, LY, LZ: Integer;
  LIndex: Integer;
begin
  // the file is text of one byte per character
  SetLength(LText, Length(ABytes));
  for LIndex := 0 to High(ABytes) do
    LText[LIndex + 1] := Char(ABytes[LIndex]);

  LScanner := TScriptScanner.Create(LText, FLog);
  try
    LScanner.MustGetInteger;
    LSide := LScanner.AsInteger;
    if (LSide < 1) or (LSide > VOXEL_MAX_SIZE) then
      raise EVoxelException.CreateFmt(SVoxelDdvoxSize, [LSide]);
    SetLength(LCells, LSide * LSide * LSide);

    LX := 0;
    LY := 0;
    LZ := 0;
    while LScanner.GetString do
    begin
      if LScanner.MatchString('skip') then
      begin
        LScanner.MustGetInteger;
        Inc(LZ, LScanner.AsInteger);
      end
      else
      begin
        LScanner.UnGet;
        LScanner.MustGetInteger;
        if LZ > LSide - 1 then
          raise EVoxelException.CreateFmt(SVoxelDdvoxOverrun, [LSide]);
        LCells[(LX * LSide + LY) * LSide + LZ] := TVoxelColors.SwapRgb(Cardinal(LScanner.AsInteger));
        Inc(LZ);
      end;
      if (LZ < 0) or (LZ > LSide) then
        raise EVoxelException.CreateFmt(SVoxelDdvoxOverrun, [LSide]);
      if LZ = LSide then
      begin
        LZ := 0;
        Inc(LY);
        if LY = LSide then
        begin
          LY := 0;
          Inc(LX);
          if LX = LSide then
            Break;
        end;
      end;
    end;
  finally
    LScanner.Free;
  end;

  Result := TVoxelModel.Create(vfDdvox, LSide, LSide, LSide, 0, 0, 0, LCells, nil);
end;

end.
