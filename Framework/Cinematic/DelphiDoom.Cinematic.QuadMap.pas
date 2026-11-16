{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the blocks of a RoQ frame                   }
{                                                                              }
{  Port of recurseQuad and setupQuad of the RoQ decoder of Quake III Arena     }
{  (cl_cin.c, GPL v2 or later, Copyright (C) 1999-2005 Id Software, Inc.) and  }
{  of Doom 3 (Cinematic.cpp, GPL v3 with the additional terms of the Doom 3    }
{  Source Code License, Copyright (C) 1999-2011 id Software LLC). Based on     }
{  the Doom 3 GPL Source Code (id Software).                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.QuadMap;

interface

type
  /// <summary>
  ///   Where the blocks of a frame start in the buffer of the image, in pixels, in the order
  ///   that the VQ data follow: for every 16x16 macroblock and every 8x8 block in it, the
  ///   8x8 block and then its four 4x4 ones (qStatus of the original)
  /// </summary>
  TRoqQuadMap = class
  strict private
    FOffsets: TArray<Integer>;
    FCount: Integer;
    FWidth: Integer;
    FHeight: Integer;
    procedure RecurseQuad(AStartX, AStartY, ASize: Integer);
  public
    constructor Create(AWidth, AHeight: Integer);
    /// <summary>Offset in pixels of the block with this number (from the start of the buffer of one frame)</summary>
    function Offset(AIndex: Integer): Integer; inline;
    property Count: Integer read FCount;
  end;

implementation

uses
  DelphiDoom.Cinematic.Types;

{ TRoqQuadMap }

constructor TRoqQuadMap.Create(AWidth, AHeight: Integer);
var
  LX, LY: Integer;
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
  SetLength(FOffsets, (AWidth * AHeight) div 16 * 5 div 4 + 64);
  LY := 0;
  while LY < AHeight do
  begin
    LX := 0;
    while LX < AWidth do
    begin
      RecurseQuad(LX, LY, ROQ_MACROBLOCK);
      Inc(LX, ROQ_MACROBLOCK);
    end;
    Inc(LY, ROQ_MACROBLOCK);
  end;
end;

procedure TRoqQuadMap.RecurseQuad(AStartX, AStartY, ASize: Integer);
begin
  if (AStartX >= 0) and (AStartX + ASize <= FWidth) and (AStartY + ASize <= FHeight) and
    (AStartY >= 0) and (ASize <= ROQ_MAX_BLOCK) then
  begin
    FOffsets[FCount] := AStartY * FWidth + AStartX;
    Inc(FCount);
  end;
  if ASize <> ROQ_MIN_BLOCK then
  begin
    ASize := ASize shr 1;
    RecurseQuad(AStartX, AStartY, ASize);
    RecurseQuad(AStartX + ASize, AStartY, ASize);
    RecurseQuad(AStartX, AStartY + ASize, ASize);
    RecurseQuad(AStartX + ASize, AStartY + ASize, ASize);
  end;
end;

function TRoqQuadMap.Offset(AIndex: Integer): Integer;
begin
  Result := FOffsets[AIndex];
end;

end.
