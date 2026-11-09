{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL call recorder - the client arrays (glVertexPointer...)   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.OpenGl.Recorder.ClientArrays;

interface

type
  /// <summary>The client arrays the recorder follows</summary>
  TGlClientArrayKind = (cakVertex, cakTexCoord);

  /// <summary>
  ///   Follows glVertexPointer, glTexCoordPointer and glEnable/DisableClientState, so that a
  ///   glDrawArrays can be written with a hash of the elements it draws. The pointers themselves
  ///   change from a run to the next and are never written.
  /// </summary>
  TGlClientArrays = class
  strict private
    type
      TArrayState = record
        Enabled: Boolean;
        Size: Integer;
        DataType: Cardinal;
        Stride: Integer;
        Data: Pointer;
      end;
  strict private
    FArrays: array[TGlClientArrayKind] of TArrayState;
  public
    /// <summary>Sets what glVertexPointer or glTexCoordPointer gave</summary>
    procedure SetPointer(const AKind: TGlClientArrayKind; const ASize: Integer; const ADataType: Cardinal;
      const AStride: Integer; const AData: Pointer);
    /// <summary>Follows glEnableClientState and glDisableClientState (a capability that is not followed is ignored)</summary>
    procedure SetCapability(const ACapability: Cardinal; const AEnabled: Boolean);
    /// <summary>
    ///   What to write for the elements AFirst..AFirst + ACount - 1 of an array: empty if the array is
    ///   not enabled, 'unknown' if its pointer or type are not known, otherwise a hash of the bytes of
    ///   the elements (without the padding between them) and the number of bytes.
    /// </summary>
    function Describe(const AKind: TGlClientArrayKind; const AFirst, ACount: Integer): string;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.OpenGl.Recorder.Fnv,
  DelphiDoom.OpenGl.Recorder.PixelFormats,
  DelphiDoom.OpenGl.Recorder.Types;

{ TGlClientArrays }

procedure TGlClientArrays.SetPointer(const AKind: TGlClientArrayKind; const ASize: Integer;
  const ADataType: Cardinal; const AStride: Integer; const AData: Pointer);
begin
  FArrays[AKind].Size := ASize;
  FArrays[AKind].DataType := ADataType;
  FArrays[AKind].Stride := AStride;
  FArrays[AKind].Data := AData;
end;

procedure TGlClientArrays.SetCapability(const ACapability: Cardinal; const AEnabled: Boolean);
begin
  case ACapability of
    GLR_VERTEX_ARRAY: FArrays[cakVertex].Enabled := AEnabled;
    GLR_TEXTURE_COORD_ARRAY: FArrays[cakTexCoord].Enabled := AEnabled;
  end;
end;

function TGlClientArrays.Describe(const AKind: TGlClientArrayKind; const AFirst, ACount: Integer): string;
var
  LState: TArrayState;
  LElementBytes: Int64;
  LStride: Int64;
  LHash: UInt64;
  LIndex: Integer;
  LElement: PByte;
begin
  LState := FArrays[AKind];
  if not LState.Enabled then
    Exit('');
  LElementBytes := Int64(LState.Size) * TGlPixelFormats.TypeSize(LState.DataType);
  if (LState.Data = nil) or (LElementBytes <= 0) or (AFirst < 0) or (ACount < 0) or (ACount > 16777216) then
    Exit('unknown');
  LStride := LState.Stride;
  if LStride <= 0 then
    LStride := LElementBytes;
  LHash := TGlFnv.Start;
  LElement := PByte(LState.Data) + Int64(AFirst) * LStride;
  for LIndex := 0 to ACount - 1 do
  begin
    LHash := TGlFnv.UpdateBuffer(LHash, LElement, LElementBytes);
    Inc(LElement, LStride);
  end;
  Result := 'h:' + TGlFnv.ToHex(LHash) + '/' + IntToStr(LElementBytes * ACount);
end;

end.
