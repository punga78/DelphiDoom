{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the OLD MODELDEF parser        }
{                                                                              }
{  The text of SC_DoParseModelDefinition of gl_models.pas as it was before     }
{  issue #177 (slice 3), with shims at the places where it touched the engine  }
{  (the token list, the warnings, gld_AddModel, gld_AddModelState and          }
{  gld_AddModelTexture): it is the reference of the parity tests.              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.OldModelDefinition;

interface

uses
  DelphiDoom.Logging.Intf,
  DelphiDoom.Models.Definition.Intf;

/// <summary>The old parser; the results go to the sink and the problems to the log</summary>
procedure OldParseModelDefinition(const in_text: string; const ASink: IModelDefinitionSink;
  const ALookup: IModelDefinitionLookup; const ALog: ILog);

implementation

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Scanner.Scanner,
  DelphiDoom.Models.Definition.Types;

type
  // shim of TTokenList (sc_tokens.pas): the same IndexOfToken on a TStringList
  TTokenList = class(TStringList)
  public
    function IndexOfToken(const S: string): Integer;
  end;

  TDStringList = TStringList;

  modelstate_t = record
    modelidx: integer;
    texture: integer;
    startframe,
    endframe: integer;
    nextframe: integer;
    state: integer;
    transparency: single;
  end;

  modelmanageritem_t = record
    name: string;
    proc: string;
    xoffset: single;
    yoffset: single;
    zoffset: single;
    xscale: single;
    yscale: single;
    zscale: single;
    framemerge: TDStringList;
  end;

var
  OldSink: IModelDefinitionSink;
  OldLookup: IModelDefinitionLookup;
  OldLog: ILog;

function TTokenList.IndexOfToken(const S: string): Integer;
var
  i, j: integer;
  list: TStringList;
  stmp: string;
begin
  result := IndexOf(S);
  if result > -1 then
    exit;

  list := TStringList.Create;
  try
    for i := 0 to Count - 1 do
    begin
      stmp := Strings[i];
      if Pos(',', stmp) > 0 then
      begin
        list.Clear;
        list.Delimiter := ',';
        list.StrictDelimiter := True;
        list.DelimitedText := stmp;
        for j := 0 to list.Count - 1 do
          list[j] := Trim(list[j]);
        if list.IndexOf(S) > -1 then
        begin
          result := i;
          exit;
        end;
      end;
    end;
  finally
    list.Free;
  end;
end;

procedure I_Warning(const fmt: string; const args: array of const);
begin
  OldLog.Warning(Format(fmt, args));
end;

function strupper(const s: string): string;
begin
  result := UpperCase(s);
end;

function gld_AddModel(const item: modelmanageritem_t): integer;
var
  LItem: TModelDefinitionItem;
  i: integer;
begin
  LItem.Name := item.name;
  LItem.Proc := item.proc;
  LItem.XOffset := item.xoffset;
  LItem.YOffset := item.yoffset;
  LItem.ZOffset := item.zoffset;
  LItem.XScale := item.xscale;
  LItem.YScale := item.yscale;
  LItem.ZScale := item.zscale;
  SetLength(LItem.FrameMerge, item.framemerge.Count);
  for i := 0 to item.framemerge.Count - 1 do
    LItem.FrameMerge[i] := item.framemerge[i];
  Result := OldSink.AddModel(LItem);
end;

procedure gld_AddModelState(const item: modelstate_t);
var
  LState: TModelDefinitionState;
begin
  LState.ModelIndex := item.modelidx;
  LState.Texture := item.texture;
  LState.StartFrame := item.startframe;
  LState.EndFrame := item.endframe;
  LState.NextFrame := item.nextframe;
  LState.State := item.state;
  LState.Transparency := item.transparency;
  OldSink.AddState(LState);
end;

function gld_AddModelTexture(const texturename: string): integer;
begin
  Result := OldSink.AddTexture(texturename);
end;

// ------------------------- the old text starts here ---------------------------

procedure OldParseModelDefinition(const in_text: string; const ASink: IModelDefinitionSink;
  const ALookup: IModelDefinitionLookup; const ALog: ILog);
var
  sc: TScriptScanner;
  tokens: TTokenList;
  token: string;
  token_idx: integer;
  modelstate: modelstate_t;
  modelitem: modelmanageritem_t;
  modelpending: boolean;
  statepending: boolean;
begin
  OldSink := ASink;
  OldLookup := ALookup;
  OldLog := ALog;
  tokens := TTokenList.Create;
  modelitem.framemerge := TDStringList.Create;
  tokens.Add('MODELDEF, MODELDEFINITION');
  tokens.Add('STATE');
  tokens.Add('OFFSET, ZOFFSET, OFFSETZ');
  tokens.Add('SCALE');
  tokens.Add('TEXTURE');
  tokens.Add('FRAME, FRAME1, STARTFRAME');
  tokens.Add('FRAME2, ENDFRAME, NEXTFRAME'); // JVAL: used from version 2.0.3.706 and up
  tokens.Add('MODEL');
  tokens.Add('FRAMEMERGE');
  tokens.Add('TRANSPARENCY');
  tokens.Add('XOFFSET, OFFSETX'); // 10
  tokens.Add('YOFFSET, OFFSETY'); // 11
  tokens.Add('XSCALE, SCALEX');   // 12
  tokens.Add('YSCALE, SCALEY');   // 13
  tokens.Add('ZSCALE, SCALEZ');   // 14
  tokens.Add('PROC');             // 15

  sc := TScriptScanner.Create(in_text, ALog);

  modelpending := false;
  statepending := false;
  // the old code left these fields with the content of the stack
  modelitem.name := '';
  modelitem.proc := '';
  modelitem.xoffset := 0.0;
  modelitem.yoffset := 0.0;
  modelitem.zoffset := 0.0;
  modelitem.xscale := 1.0;
  modelitem.yscale := 1.0;
  modelitem.zscale := 1.0;
  FillChar(modelstate, SizeOf(modelstate), 0);

  while sc.GetString do
  begin
    token := strupper(sc.AsString);
    token_idx := tokens.IndexOfToken(token);
    case token_idx of
      0: // MODEL DEFINITION
        begin
          modelpending := true;
          modelitem.name := '';
          modelitem.proc := '';
          modelitem.xoffset := 0.0;
          modelitem.yoffset := 0.0;
          modelitem.zoffset := 0.0;
          modelitem.xscale := 1.0;
          modelitem.yscale := 1.0;
          modelitem.zscale := 1.0;
          modelitem.framemerge.Clear;
          if not sc.GetString then
          begin
            I_Warning('SC_ParseModelDefinition(): Token expected at line %d'#13#10, [sc.Line]);
            break;
          end;
          modelitem.name := strupper(sc.AsString);

          while sc.GetString do
          begin
            token := strupper(sc.AsString);
            token_idx := tokens.IndexOfToken(token);
            case token_idx of
              2:  // Offset / zoffset
                begin
                  sc.MustGetFloat;
                  modelitem.zoffset := sc.AsFloat;
                end;
             10:  // xoffset
                begin
                  sc.MustGetFloat;
                  modelitem.xoffset := sc.AsFloat;
                end;
             11:  // yoffset
                begin
                  sc.MustGetFloat;
                  modelitem.xoffset := sc.AsFloat;
                end;
              3:  // Scale
                begin
                  sc.MustGetFloat;
                  modelitem.xscale := sc.AsFloat;
                  modelitem.yscale := sc.AsFloat;
                  modelitem.zscale := sc.AsFloat;
                end;
             12:  // xscale
                begin
                  sc.MustGetFloat;
                  modelitem.xscale := sc.AsFloat;
                end;
             13:  // yscale
                begin
                  sc.MustGetFloat;
                  modelitem.yscale := sc.AsFloat;
                end;
             14:  // zscale
                begin
                  sc.MustGetFloat;
                  modelitem.zscale := sc.AsFloat;
                end;
              8:  // FRAMEMERGE
                begin
                  sc.MustGetString;
                  modelitem.framemerge.Add(strupper(sc.AsString));
                end;
             15:  // PROC
                begin
                  sc.MustGetString;
                  modelitem.proc := sc.AsString;
                end;
            else
              begin
                gld_AddModel(modelitem);
                modelpending := false;
                sc.UnGet;
                break;
              end;
            end;
          end;
        end;

      1: // STATE DEFINITION
        begin
          statepending := true;
          FillChar(modelstate, SizeOf(modelstate_t), 0);
          modelitem.xoffset := 0.0;
          modelitem.yoffset := 0.0;
          modelitem.zoffset := 0.0;
          modelitem.xscale := 1.0;
          modelitem.yscale := 1.0;
          modelitem.zscale := 1.0;
          modelitem.framemerge.Clear;

          modelstate.modelidx := -1;
          modelstate.texture := -1;
          modelstate.startframe := -1;
          modelstate.endframe := -1;
          modelstate.nextframe := -1; // JVAL: runtime only!
          modelstate.transparency := 1.0;
          if not sc.GetString then
          begin
            I_Warning('SC_ParseModelDefinition(): Token expected at line %d'#13#10, [sc.Line]);
            break;
          end;
          modelstate.state := OldLookup.FindState(strupper(sc.AsString));
          if modelstate.state < 0 then
          begin
            I_Warning('SC_ParseModelDefinition(): Unknown state "%s" at line %d'#13#10, [sc.AsString, sc.Line]);
            modelstate.state := 0; // S_NULL
          end;

          while sc.GetString do
          begin
            token := strupper(sc.AsString);
            token_idx := tokens.IndexOfToken(token);
            case token_idx of
              7:  // Model
                begin
                  sc.MustGetString;
                  modelitem.name := strupper(sc.AsString);
                  modelitem.proc := '';
                  modelitem.xoffset := 0.0;
                  modelitem.yoffset := 0.0;
                  modelitem.zoffset := 0.0;
                  modelitem.xscale := 1.0;
                  modelitem.yscale := 1.0;
                  modelitem.zscale := 1.0;
                  modelstate.modelidx := gld_AddModel(modelitem);
                end;
              4:  // Texture
                begin
                  sc.MustGetString;
                  modelstate.texture := gld_AddModelTexture(strupper(sc.AsString));
                end;
              5:  // startframe
                begin
                  sc.MustGetInteger;
                  modelstate.startframe := sc.AsInteger;
                  if modelstate.endframe < 0 then
                    modelstate.endframe := modelstate.startframe;
                end;
              6:  // endframe
                begin
                  sc.MustGetInteger;
                  modelstate.endframe := sc.AsInteger;
                end;
              9:  // transparency
                begin
                  sc.MustGetFloat;
                  modelstate.transparency := sc.AsFloat;
                end;
            else
              begin
                gld_AddModelState(modelstate);
                statepending := false;
                sc.UnGet;
                break;
              end;
            end;
          end;
        end;

      else
        begin
          I_Warning('SC_ParseModelDefinition(): Unknown token "%s" at line %d'#13#10, [token, sc.Line]);
        end;
    end;
  end;

  if modelpending then
    gld_AddModel(modelitem);
  if statepending then
    gld_AddModelState(modelstate);

  sc.Free;
  tokens.Free;
  modelitem.framemerge.Free;
end;

end.
