{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - the string pool of the menus                      }
{                                                                              }
{  Port of String_Alloc of ui_shared.c (Quake III Arena, id Software, GPL v2   }
{  or later). Based on the Quake III Arena GPL Source Code (id Software).      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.StringPool;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Gui.Types;

type
  /// <summary>
  ///   The 384 KB pool of strings that menus share (strPool, strHandle of ui_shared.c). Strings are values here:
  ///   what is kept from the original is the budget. A string that is already in the pool costs nothing, a new
  ///   one costs its length and a terminator, and one that does not fit is not stored: the original gives NULL
  ///   (with success), here the empty string.
  /// </summary>
  TGuiStringPool = class
  strict private
    FSize: Integer;
    FUsed: Integer;
    FStored: TDictionary<AnsiString, Boolean>;
    FRefused: Integer;
  public
    constructor Create(const ASize: Integer = GUI_STRING_POOL_SIZE);
    destructor Destroy; override;
    /// <summary>String_Alloc; the empty string when the pool is full</summary>
    function Alloc(const AText: AnsiString): AnsiString;
    /// <summary>String_Init: empties the pool</summary>
    procedure Clear;
    /// <summary>Bytes in use (strPoolIndex)</summary>
    property Used: Integer read FUsed;
    /// <summary>Strings that did not fit</summary>
    property Refused: Integer read FRefused;
  end;

implementation

constructor TGuiStringPool.Create(const ASize: Integer);
begin
  inherited Create;
  FSize := ASize;
  FStored := TDictionary<AnsiString, Boolean>.Create;
end;

destructor TGuiStringPool.Destroy;
begin
  FStored.Free;
  inherited Destroy;
end;

function TGuiStringPool.Alloc(const AText: AnsiString): AnsiString;
begin
  if AText = '' then
    Exit('');
  if FStored.ContainsKey(AText) then
    Exit(AText);
  if Length(AText) + FUsed + 1 < FSize then
  begin
    Inc(FUsed, Length(AText) + 1);
    FStored.Add(AText, True);
    Exit(AText);
  end;
  Inc(FRefused);
  Result := '';
end;

procedure TGuiStringPool.Clear;
begin
  FStored.Clear;
  FUsed := 0;
  FRefused := 0;
end;

end.
