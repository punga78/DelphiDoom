{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - TImagingProgramOperations, the operations of  }
{  the image program of idTech 4 (heightmap, addnormals, smoothnormals, add,   }
{  scale, invertAlpha, invertColor, makeIntensity, makeAlpha)                  }
{                                                                              }
{  Port of renderer\Image_program.cpp (id Software, Doom 3, GPL v3):           }
{  R_HeightmapToNormalMap, R_ImageScale, R_InvertAlpha, R_InvertColor,         }
{  R_AddNormalMaps, R_SmoothNormalMap, R_ImageAdd and the two loops that       }
{  R_ParseImageProgram_r has inline (makeIntensity, makeAlpha).                }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.ImageProgram.Operations;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Rgba.Image;

type
  /// <summary>
  ///   The pixel operations of the image program. Each works in place on its first image. The
  ///   float arithmetic is kept at 32 bits step by step as in the C++ (the normals are built
  ///   with idVec3 and the fast and the table based inverse square roots of idMath)
  /// </summary>
  /// <remarks>
  ///   Conversions of a float to a byte, <c>(byte)(x)</c> in the C++, are undefined when x is
  ///   out of 0..255; the compilers for x86 truncate to an int and keep the low byte, so a
  ///   result of 256 becomes 0 and -1 becomes 255. That is what ToByte does, and it is what makes
  ///   <c>scale</c> wrap instead of clamp (the clamp that follows in R_ImageScale never fires)
  /// </remarks>
  TImagingProgramOperations = class sealed
  strict private
    class function ToByte(const AValue: Single): Byte; static;
  public
    /// <summary>
    ///   R_HeightmapToNormalMap: the grey level (mean of R, G, B) is a height; the normal comes
    ///   from the differences with the right and lower neighbours (wrapping, the sides must be
    ///   powers of two) seen from two corners, then averaged. Alpha becomes 255
    /// </summary>
    class procedure HeightmapToNormalMap(var AImage: TImagingRgbaImage; const AScale: Single); static;
    /// <summary>
    ///   R_ImageScale: each channel times AScale[channel] (R, G, B, A), as a byte that wraps
    /// </summary>
    class procedure Scale(var AImage: TImagingRgbaImage; const AScale: array of Single); static;
    /// <summary>R_InvertAlpha</summary>
    class procedure InvertAlpha(var AImage: TImagingRgbaImage); static;
    /// <summary>R_InvertColor (alpha unchanged)</summary>
    class procedure InvertColor(var AImage: TImagingRgbaImage); static;
    /// <summary>
    ///   R_AddNormalMaps: adds the xy of the second normal map to the first and renormalizes.
    ///   The second one is first dropsampled to the size of the first when they differ
    /// </summary>
    class procedure AddNormalMaps(var AImage: TImagingRgbaImage; const AOther: TImagingRgbaImage); static;
    /// <summary>R_SmoothNormalMap: each normal is the normalized sum of the 3x3 neighbourhood (wrapping), without the 0,0,0 and 128,128,128 texels</summary>
    class procedure SmoothNormalMap(var AImage: TImagingRgbaImage); static;
    /// <summary>R_ImageAdd: saturating sum of every byte; the second image is dropsampled when its size differs</summary>
    class procedure Add(var AImage: TImagingRgbaImage; const AOther: TImagingRgbaImage); static;
    /// <summary>makeIntensity: red copied into green, blue and alpha</summary>
    class procedure MakeIntensity(var AImage: TImagingRgbaImage); static;
    /// <summary>makeAlpha: the mean of R, G, B into alpha, then R, G, B = 255</summary>
    class procedure MakeAlpha(var AImage: TImagingRgbaImage); static;
  end;

implementation

uses
  DelphiDoom.Imaging.Rgba.Sampler, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Math.Vec3;

{ TImagingProgramOperations }

class function TImagingProgramOperations.ToByte(const AValue: Single): Byte;
var
  LInt: Integer;
begin
  if (AValue >= 2147483648.0) or (AValue < -2147483648.0) or (AValue <> AValue) then
    LInt := Low(Integer)
  else
    LInt := Trunc(AValue);
  Result := Byte(LInt and $FF);
end;

class procedure TImagingProgramOperations.HeightmapToNormalMap(var AImage: TImagingRgbaImage;
  const AScale: Single);
var
  LDepth: TBytes;
  LScale: Single;
  LCount, LI, LJ, LWidth, LHeight: Integer;
  LD1, LD2, LD3, LD4, LA1, LA4, LA3, LOffset: Integer;
  LDir, LDir2: TIdVec3;
  LValue: Single;
begin
  LWidth := AImage.Width;
  LHeight := AImage.Height;
  LScale := AScale / 256;
  LCount := LWidth * LHeight;
  SetLength(LDepth, LCount);
  for LI := 0 to LCount - 1 do
    LDepth[LI] := Byte((AImage.Pixels[LI * 4] + AImage.Pixels[LI * 4 + 1]
      + AImage.Pixels[LI * 4 + 2]) div 3);

  for LI := 0 to LHeight - 1 do
    for LJ := 0 to LWidth - 1 do
    begin
      LD1 := LDepth[LI * LWidth + LJ];
      LD2 := LDepth[LI * LWidth + ((LJ + 1) and (LWidth - 1))];
      LD3 := LDepth[((LI + 1) and (LHeight - 1)) * LWidth + LJ];
      LD4 := LDepth[((LI + 1) and (LHeight - 1)) * LWidth + ((LJ + 1) and (LWidth - 1))];
      LA1 := LD1;
      LA3 := LD3;
      LA4 := LD4;

      LD2 := LD2 - LD1;
      LD3 := LD3 - LD1;

      LValue := -LD2;
      LDir[0] := LValue * LScale;
      LValue := -LD3;
      LDir[1] := LValue * LScale;
      LDir[2] := 1;
      LDir.NormalizeFast;

      LA1 := LA1 - LA3;
      LA4 := LA4 - LA3;

      LValue := -LA4;
      LDir2[0] := LValue * LScale;
      LValue := LA1;
      LDir2[1] := LValue * LScale;
      LDir2[2] := 1;
      LDir2.NormalizeFast;

      LDir := LDir + LDir2;
      LDir.NormalizeFast;

      LOffset := (LI * LWidth + LJ) * 4;
      LValue := LDir[0] * 127;
      LValue := LValue + 128;
      AImage.Pixels[LOffset] := ToByte(LValue);
      LValue := LDir[1] * 127;
      LValue := LValue + 128;
      AImage.Pixels[LOffset + 1] := ToByte(LValue);
      LValue := LDir[2] * 127;
      LValue := LValue + 128;
      AImage.Pixels[LOffset + 2] := ToByte(LValue);
      AImage.Pixels[LOffset + 3] := 255;
    end;
end;

class procedure TImagingProgramOperations.Scale(var AImage: TImagingRgbaImage;
  const AScale: array of Single);
var
  LI: Integer;
  LValue: Single;
begin
  for LI := 0 to Length(AImage.Pixels) - 1 do
  begin
    LValue := AImage.Pixels[LI];
    LValue := LValue * AScale[LI and 3];
    AImage.Pixels[LI] := ToByte(LValue);
  end;
end;

class procedure TImagingProgramOperations.InvertAlpha(var AImage: TImagingRgbaImage);
var
  LI: Integer;
begin
  for LI := 0 to AImage.Width * AImage.Height - 1 do
    AImage.Pixels[LI * 4 + 3] := 255 - AImage.Pixels[LI * 4 + 3];
end;

class procedure TImagingProgramOperations.InvertColor(var AImage: TImagingRgbaImage);
var
  LI, LChannel: Integer;
begin
  for LI := 0 to AImage.Width * AImage.Height - 1 do
    for LChannel := 0 to 2 do
      AImage.Pixels[LI * 4 + LChannel] := 255 - AImage.Pixels[LI * 4 + LChannel];
end;

class procedure TImagingProgramOperations.AddNormalMaps(var AImage: TImagingRgbaImage;
  const AOther: TImagingRgbaImage);
var
  LOther: TImagingRgbaImage;
  LI, LJ, LOffset: Integer;
  LN: TIdVec3;
  LLength, LValue, LProduct0, LProduct1: Single;
  LDouble: Double;
begin
  if (AOther.Width <> AImage.Width) or (AOther.Height <> AImage.Height) then
    LOther := TImagingRgbaSampler.Dropsample(AOther, AImage.Width, AImage.Height)
  else
    LOther := AOther;

  for LI := 0 to AImage.Height - 1 do
    for LJ := 0 to AImage.Width - 1 do
    begin
      LOffset := (LI * AImage.Width + LJ) * 4;
      LN[0] := (AImage.Pixels[LOffset] - 128) / 127.0;
      LN[1] := (AImage.Pixels[LOffset + 1] - 128) / 127.0;
      LN[2] := (AImage.Pixels[LOffset + 2] - 128) / 127.0;

      // some normal maps blend to 0,0,0 at the edges: fade them to 0,0,1 instead
      LLength := LN.LengthFast;
      if LLength < 1.0 then
      begin
        LProduct0 := LN[0] * LN[0];
        LProduct1 := LN[1] * LN[1];
        LDouble := 1.0 - LProduct0;
        LDouble := LDouble - LProduct1;
        LN[2] := TIdMath.Sqrt(LDouble);
      end;

      LDouble := LN[0] + (LOther.Pixels[LOffset] - 128) / 127.0;
      LN[0] := LDouble;
      LDouble := LN[1] + (LOther.Pixels[LOffset + 1] - 128) / 127.0;
      LN[1] := LDouble;
      LN.Normalize;

      LValue := LN[0] * 127;
      LValue := LValue + 128;
      AImage.Pixels[LOffset] := ToByte(LValue);
      LValue := LN[1] * 127;
      LValue := LValue + 128;
      AImage.Pixels[LOffset + 1] := ToByte(LValue);
      LValue := LN[2] * 127;
      LValue := LValue + 128;
      AImage.Pixels[LOffset + 2] := ToByte(LValue);
      AImage.Pixels[LOffset + 3] := 255;
    end;
end;

class procedure TImagingProgramOperations.SmoothNormalMap(var AImage: TImagingRgbaImage);
var
  LOriginal: TBytes;
  LWidth, LHeight, LI, LJ, LK, LL, LIn, LOut: Integer;
  LNormal: TIdVec3;
  LValue, LProduct: Single;
begin
  LWidth := AImage.Width;
  LHeight := AImage.Height;
  LOriginal := Copy(AImage.Pixels);
  for LI := 0 to LWidth - 1 do
    for LJ := 0 to LHeight - 1 do
    begin
      LNormal.Zero;
      for LK := -1 to 1 do
        for LL := -1 to 1 do
        begin
          LIn := (((LJ + LL) and (LHeight - 1)) * LWidth + ((LI + LK) and (LWidth - 1))) * 4;
          // ignore 000 and 128 128 128
          if (LOriginal[LIn] = 0) and (LOriginal[LIn + 1] = 0) and (LOriginal[LIn + 2] = 0) then
            Continue;
          if (LOriginal[LIn] = 128) and (LOriginal[LIn + 1] = 128) and (LOriginal[LIn + 2] = 128) then
            Continue;
          // factors[][] are all 1.0f
          LProduct := 1.0 * (LOriginal[LIn] - 128);
          LValue := LNormal[0] + LProduct;
          LNormal[0] := LValue;
          LProduct := 1.0 * (LOriginal[LIn + 1] - 128);
          LValue := LNormal[1] + LProduct;
          LNormal[1] := LValue;
          LProduct := 1.0 * (LOriginal[LIn + 2] - 128);
          LValue := LNormal[2] + LProduct;
          LNormal[2] := LValue;
        end;
      LNormal.Normalize;
      LOut := (LJ * LWidth + LI) * 4;
      LProduct := 127 * LNormal[0];
      LValue := 128 + LProduct;
      AImage.Pixels[LOut] := ToByte(LValue);
      LProduct := 127 * LNormal[1];
      LValue := 128 + LProduct;
      AImage.Pixels[LOut + 1] := ToByte(LValue);
      LProduct := 127 * LNormal[2];
      LValue := 128 + LProduct;
      AImage.Pixels[LOut + 2] := ToByte(LValue);
    end;
end;

class procedure TImagingProgramOperations.Add(var AImage: TImagingRgbaImage;
  const AOther: TImagingRgbaImage);
var
  LOther: TImagingRgbaImage;
  LI, LSum: Integer;
begin
  if (AOther.Width <> AImage.Width) or (AOther.Height <> AImage.Height) then
    LOther := TImagingRgbaSampler.Dropsample(AOther, AImage.Width, AImage.Height)
  else
    LOther := AOther;
  for LI := 0 to AImage.Width * AImage.Height * 4 - 1 do
  begin
    LSum := AImage.Pixels[LI] + LOther.Pixels[LI];
    if LSum > 255 then
      LSum := 255;
    AImage.Pixels[LI] := Byte(LSum);
  end;
end;

class procedure TImagingProgramOperations.MakeIntensity(var AImage: TImagingRgbaImage);
var
  LI: Integer;
begin
  for LI := 0 to AImage.Width * AImage.Height - 1 do
  begin
    AImage.Pixels[LI * 4 + 3] := AImage.Pixels[LI * 4];
    AImage.Pixels[LI * 4 + 2] := AImage.Pixels[LI * 4];
    AImage.Pixels[LI * 4 + 1] := AImage.Pixels[LI * 4];
  end;
end;

class procedure TImagingProgramOperations.MakeAlpha(var AImage: TImagingRgbaImage);
var
  LI: Integer;
begin
  for LI := 0 to AImage.Width * AImage.Height - 1 do
  begin
    AImage.Pixels[LI * 4 + 3] := Byte((AImage.Pixels[LI * 4] + AImage.Pixels[LI * 4 + 1]
      + AImage.Pixels[LI * 4 + 2]) div 3);
    AImage.Pixels[LI * 4] := 255;
    AImage.Pixels[LI * 4 + 1] := 255;
    AImage.Pixels[LI * 4 + 2] := 255;
  end;
end;

end.
