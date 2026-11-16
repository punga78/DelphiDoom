unit UState;
{$IMPORTEDDATA OFF}
interface
var
  GlobalA: Integer;
  GlobalArr: array[0..3] of Integer;
type
  TSt = class sealed
  public
    class var A: Integer;
    class var Arr: array[0..3] of Integer;
  end;
implementation
end.
