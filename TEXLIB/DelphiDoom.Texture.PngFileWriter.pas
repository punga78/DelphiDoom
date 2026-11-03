{******************************************************************************}
{                                                                              }
{  DelphiDoom: writes screen captures as PNG files                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Texture.PngFileWriter;

{$POINTERMATH ON}

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Encodes the pixels of a screen capture with the PNG library and saves
  ///   them to a file. The methods return False instead of raising when the
  ///   image cannot be encoded or the file cannot be written
  /// </summary>
  TPngFileWriter = class
  private
    class function WriteFile(const AFileName: string;
      const AContent: TBytes): Boolean; static;
  public
    /// <summary>
    ///   APixels holds AHeight rows of AWidth pixels of 4 bytes (B, G, R and
    ///   one that is ignored), as the screen readers of the engine give them.
    ///   With AFlipVertical the last row is written first (OpenGL reads the
    ///   screen from the bottom)
    /// </summary>
    class function SaveBgrx(const AFileName: string; APixels: Pointer;
      AWidth, AHeight: Integer; AFlipVertical: Boolean): Boolean; static;

    /// <summary>
    ///   APixels holds AHeight rows of AWidth bytes: a grayscale image
    /// </summary>
    class function SaveGray(const AFileName: string; APixels: Pointer;
      AWidth, AHeight: Integer): Boolean; static;
  end;

implementation

uses
  System.Classes, DelphiDoom.Png.Intf, DelphiDoom.Png.Provider;

{ TPngFileWriter }

class function TPngFileWriter.WriteFile(const AFileName: string;
  const AContent: TBytes): Boolean;
var
  LFile: TFileStream;
begin
  try
    LFile := TFileStream.Create(AFileName, fmCreate);
    try
      LFile.WriteBuffer(AContent[0], Length(AContent));
    finally
      LFile.Free;
    end;
    Result := True;
  except
    on EStreamError do
      Result := False;
    on EInOutError do
      Result := False;
  end;
end;

class function TPngFileWriter.SaveBgrx(const AFileName: string;
  APixels: Pointer; AWidth, AHeight: Integer; AFlipVertical: Boolean): Boolean;
var
  LRowSize: Integer;
  LFlipped: TBytes;
  LRow: Integer;
  LContent: TBytes;
begin
  Result := False;
  if (APixels = nil) or (AWidth < 1) or (AHeight < 1) then
    Exit;

  LRowSize := AWidth * 4;
  try
    if AFlipVertical then
    begin
      SetLength(LFlipped, LRowSize * AHeight);
      for LRow := 0 to AHeight - 1 do
        Move(PByte(APixels)[(AHeight - 1 - LRow) * LRowSize],
          LFlipped[LRow * LRowSize], LRowSize);
      LContent := TPngProvider.Client.Encode(LFlipped, AWidth, AHeight,
        DDPNG_FORMAT_BGRX);
    end
    else
      LContent := TPngProvider.Client.Encode(APixels, AWidth, AHeight,
        DDPNG_FORMAT_BGRX);
  except
    on EPngException do
      Exit;
  end;

  Result := WriteFile(AFileName, LContent);
end;

class function TPngFileWriter.SaveGray(const AFileName: string;
  APixels: Pointer; AWidth, AHeight: Integer): Boolean;
var
  LContent: TBytes;
begin
  Result := False;
  if (APixels = nil) or (AWidth < 1) or (AHeight < 1) then
    Exit;

  try
    LContent := TPngProvider.Client.Encode(APixels, AWidth, AHeight,
      DDPNG_FORMAT_GRAY);
  except
    on EPngException do
      Exit;
  end;

  Result := WriteFile(AFileName, LContent);
end;

end.
