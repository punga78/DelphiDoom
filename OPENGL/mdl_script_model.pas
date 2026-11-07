//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
//  DESCRIPTION:
//  DDMODEL script host: the functions that a model script calls (PascalScript)
//  add commands to the list of Libs\Models (IModelCommandStream).
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit mdl_script_model;

interface

uses
  d_delphi,
  dglOpenGL,
  DelphiDoom.Models.Intf;

//==============================================================================
//
// MDL_AppendFromScript
//
//==============================================================================
function MDL_AppendFromScript(const AStream: IModelCommandStream; const AScript: string): boolean;

//==============================================================================
//
// MDLS_glBegin
//
//==============================================================================
procedure MDLS_glBegin(const mode: GLenum);

//==============================================================================
//
// MDLS_glEnd
//
//==============================================================================
procedure MDLS_glEnd;

//==============================================================================
//
// MDLS_glTexCoord2f
//
//==============================================================================
procedure MDLS_glTexCoord2f(const s, t: GLfloat);

//==============================================================================
//
// MDLS_glVertex3f
//
//==============================================================================
procedure MDLS_glVertex3f(const x, y, z: GLfloat);

//==============================================================================
//
// MDLS_glColor3f
//
//==============================================================================
procedure MDLS_glColor3f(const r, g, b: GLfloat);

//==============================================================================
//
// MDLS_glColor4f
//
//==============================================================================
procedure MDLS_glColor4f(const r, g, b, a: GLfloat);

//==============================================================================
//
// MDLS_glNormal3f
//
//==============================================================================
procedure MDLS_glNormal3f(const nx, ny, nz: GLfloat);

//==============================================================================
//
// MDLS_glMatrixMode
//
//==============================================================================
procedure MDLS_glMatrixMode(const mode: LongWord);

//==============================================================================
//
// MDLS_glPushMatrix
//
//==============================================================================
procedure MDLS_glPushMatrix;

//==============================================================================
//
// MDLS_glPopMatrix
//
//==============================================================================
procedure MDLS_glPopMatrix;

//==============================================================================
//
// MDLS_glTranslatef
//
//==============================================================================
procedure MDLS_glTranslatef(const x, y, z: GLfloat);

//==============================================================================
//
// MDLS_glRotatef
//
//==============================================================================
procedure MDLS_glRotatef(const a, x, y, z: GLfloat);

//==============================================================================
//
// MDLS_glLoadIdentity
//
//==============================================================================
procedure MDLS_glLoadIdentity;

//==============================================================================
//
// MDLS_glScalef
//
//==============================================================================
procedure MDLS_glScalef(const x, y, z: GLfloat);

//==============================================================================
//
// MDLS_SetFrame
//
//==============================================================================
procedure MDLS_SetFrame(const frm: integer);

//==============================================================================
//
// MDLS_CallFrame
//
//==============================================================================
procedure MDLS_CallFrame(const frm: integer);

implementation

uses
  DelphiDoom.Models.Types,
  mdl_script,
  mdl_script_functions;

var
  currentcommandstream: IModelCommandStream;

//==============================================================================
//
// MDL_AppendFromScript
//
// Runs the script: its calls fill the list of commands, then the frames are found.
//
//==============================================================================
function MDL_AppendFromScript(const AStream: IModelCommandStream; const AScript: string): boolean;
begin
  currentcommandstream := AStream;
  try
    Result := MDL_ExecuteScript(AScript);
    AStream.IdentifyFrames;
  finally
    currentcommandstream := nil;
  end;
end;

//==============================================================================
//
// MDLS_HasStream
//
//==============================================================================
function MDLS_HasStream(const procname: string): boolean;
begin
  Result := Assigned(currentcommandstream);
  if not Result then
    printf('%s(): No model loader available'#13#10, [procname]);
end;

//==============================================================================
// MDLS_glBegin
//
//-------------------------- PascalScript Functions ----------------------------
//
//==============================================================================
procedure MDLS_glBegin(const mode: GLenum);
begin
  if not MDLS_HasStream('MDLS_glBegin') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_BEGIN, mode);
end;

//==============================================================================
//
// MDLS_glEnd
//
//==============================================================================
procedure MDLS_glEnd;
begin
  if not MDLS_HasStream('MDLS_glEnd') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_END);
end;

//==============================================================================
//
// MDLS_glTexCoord2f
//
//==============================================================================
procedure MDLS_glTexCoord2f(const s, t: GLfloat);
begin
  if not MDLS_HasStream('MDLS_glTexCoord2f') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_TEXCOORD2F, s, t);
end;

//==============================================================================
//
// MDLS_glVertex3f
//
//==============================================================================
procedure MDLS_glVertex3f(const x, y, z: GLfloat);
begin
  if not MDLS_HasStream('MDLS_glVertex3f') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_VERTEX3F, x, y, z);
end;

//==============================================================================
//
// MDLS_glColor3f
//
//==============================================================================
procedure MDLS_glColor3f(const r, g, b: GLfloat);
begin
  if not MDLS_HasStream('MDLS_glColor3f') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_COLOR3F, r, g, b);
end;

//==============================================================================
//
// MDLS_glColor4f
//
//==============================================================================
procedure MDLS_glColor4f(const r, g, b, a: GLfloat);
begin
  if not MDLS_HasStream('MDLS_glColor4f') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_COLOR4F, r, g, b, a);
end;

//==============================================================================
//
// MDLS_glNormal3f
//
//==============================================================================
procedure MDLS_glNormal3f(const nx, ny, nz: GLfloat);
begin
  if not MDLS_HasStream('MDLS_glNormal3f') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_NORMAL3F, nx, ny, nz);
end;

//==============================================================================
//
// MDLS_glMatrixMode
//
//==============================================================================
procedure MDLS_glMatrixMode(const mode: LongWord);
begin
  if not MDLS_HasStream('MDLS_glMatrixMode') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_MATRIXMODE, mode);
end;

//==============================================================================
//
// MDLS_glPushMatrix
//
//==============================================================================
procedure MDLS_glPushMatrix;
begin
  if not MDLS_HasStream('MDLS_glPushMatrix') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_PUSHMATRIX);
end;

//==============================================================================
//
// MDLS_glPopMatrix
//
//==============================================================================
procedure MDLS_glPopMatrix;
begin
  if not MDLS_HasStream('MDLS_glPopMatrix') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_POPMATRIX);
end;

//==============================================================================
//
// MDLS_glTranslatef
//
//==============================================================================
procedure MDLS_glTranslatef(const x, y, z: GLfloat);
begin
  if not MDLS_HasStream('MDLS_glTranslatef') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_TRANSLATEF, x, y, z);
end;

//==============================================================================
//
// MDLS_glRotatef
//
//==============================================================================
procedure MDLS_glRotatef(const a, x, y, z: GLfloat);
begin
  if not MDLS_HasStream('MDLS_glRotatef') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_ROTATEF, a, x, y, z);
end;

//==============================================================================
//
// MDLS_glLoadIdentity
//
//==============================================================================
procedure MDLS_glLoadIdentity;
begin
  if not MDLS_HasStream('MDLS_glLoadIdentity') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_LOADIDENTITY);
end;

//==============================================================================
//
// MDLS_glScalef
//
//==============================================================================
procedure MDLS_glScalef(const x, y, z: GLfloat);
begin
  if not MDLS_HasStream('MDLS_glScalef') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_SCALEF, x, y, z);
end;

//==============================================================================
//
// MDLS_SetFrame
//
//==============================================================================
procedure MDLS_SetFrame(const frm: integer);
begin
  if not MDLS_HasStream('MDLS_SetFrame') then
    Exit;
  currentcommandstream.CurrentFrame := frm;
  currentcommandstream.AddCommand(MODEL_CMD_SETFRAME, frm);
end;

//==============================================================================
//
// MDLS_CallFrame
//
//==============================================================================
procedure MDLS_CallFrame(const frm: integer);
begin
  if not MDLS_HasStream('MDLS_CallFrame') then
    Exit;
  currentcommandstream.AddCommand(MODEL_CMD_CALLFRAME, frm);
end;

end.
