///////////////////////////////////////////////////////////////////////////////
// Light Alloy                           Copyright(c) 2006-2013, Vortex Team //
//---------------------------------------------------------------------------//
// Filename                                                                  //
// Description.                                                              //
// ---------------                                                           //
// Author : Dmitry «Vortex» Koteroff                                         //
// E-mail : vortex@light-alloy.ru                                            //
// WWW    : http://light-alloy.ru                                            //
//---------------------------------------------------------------------------//
//   Date    Ver   Who  Comment                                              //
// --------  ---   ---  -------                                              //
// xx.xx.07  1.0   VtX  Created                                              //
///////////////////////////////////////////////////////////////////////////////
unit Subtitles;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, VCL2Model,
  Buttons, DShowHlp;

type
  TfrSubtitles = class(TForm)
    gbSubs1: TGroupBox;
    cbSub1: TCheckBox;
    GroupBox3: TGroupBox;
    tbPos1: TTrackBar;
    GroupBox4: TGroupBox;
    pnPrv1: TPanel;
    gbSubs2: TGroupBox;
    cbSub2: TCheckBox;
    GroupBox5: TGroupBox;
    tbPos2: TTrackBar;
    GroupBox7: TGroupBox;
    pnPrv2: TPanel;
    tbShift1: TTrackBar;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    btLoad1: TBitBtn;
    sbColor1: TShape;
    bbReset1: TBitBtn;
    edShift1: TEdit;
    udShift1: TUpDown;
    btLoad2: TBitBtn;
    sbColor2: TShape;
    bbReset2: TBitBtn;
    edShift2: TEdit;
    udShift2: TUpDown;
    tbShift2: TTrackBar;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure bbReset1Click(Sender: TObject);
    procedure edShift1Change(Sender: TObject);
    procedure bbReset2Click(Sender: TObject);
    procedure pnPrv1Click(Sender: TObject);
    procedure sbColor1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pnPrv2Click(Sender: TObject);
    procedure sbColor2MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    V2M:TVCL2Model;
    procedure SetLang;
    procedure OnFileName;
    procedure OnShift0;
    procedure OnShift1;
    procedure UpdateOSD;
  public
  end;

var
  frSubtitles: TfrSubtitles;

implementation

uses
  LACore, MainUnit;

{$R *.DFM}

procedure TfrSubtitles.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_ESCAPE) then Close;
end;

procedure TfrSubtitles.FormCreate(Sender: TObject);
begin
  V2M:=TVCL2Model.Create(Core.MdlMgr);
  with V2M do begin
    CurModel:='App.Subs';

    Link('Enabled0',cbSub1);
    Link('Enabled1',cbSub2);

    Link('VPos0',tbPos1);
    Link('VPos1',tbPos2);

    Link('Load0',btLoad1);
    Link('Load1',btLoad2);

    Link('Shift0',tbShift1);
    Link('Shift1',tbShift2);

    Link('Shift0',udShift1);
    Link('Shift1',udShift2);
  end;
  Core.MdlMgr.AttachWithState('App.Subs.Title0',OnFileName);
  Core.MdlMgr.AttachWithState('App.Subs.Title1',OnFileName);

  Core.MdlMgr.AttachWithState('App.Subs.Shift0',OnShift0);
  Core.MdlMgr.AttachWithState('App.Subs.Shift1',OnShift1);
  OnFileName;

  pnPrv1.Font.Name:=Core.Prefs.Str['Subtitles.Font'];
  pnPrv1.Font.Size:=Core.Prefs.Int['Subtitles.Size'];
  pnPrv1.Font.Charset:=Core.Prefs.Int['Subtitles.Charset'];
  pnPrv1.Font.Color:=Core.Prefs.Int['Subtitles.Color'];
  pnPrv1.Font.Style:=[];
  if Core.Prefs.Bool['Subtitles.Bold'] then
    pnPrv1.Font.Style:=[fsBold];
  Core.FntHlp.CopyFont(pnPrv1.Font,pnPrv2.Font);
  sbColor1.Brush.Color:=pnPrv1.Font.Color;
  sbColor2.Brush.Color:=pnPrv2.Font.Color;
end;

procedure TfrSubtitles.FormDestroy(Sender: TObject);
begin
  Core.MdlMgr.DetachWithState('App.Subs.Shift0',OnShift0);
  Core.MdlMgr.DetachWithState('App.Subs.Shift1',OnShift1);

  Core.MdlMgr.DetachWithState('App.Subs.Title1',OnFileName);
  Core.MdlMgr.DetachWithState('App.Subs.Title0',OnFileName);
  V2M.Free;
end;

procedure TfrSubtitles.FormActivate(Sender: TObject);
begin
  SetLang;
  if DSH.HasVideo and (DSH<>nil) then
    begin
      btLoad1.Enabled := True;
      btLoad2.Enabled := True;
    end
  else
    begin
      btLoad1.Enabled := False;
      btLoad2.Enabled := False;
    end;
end;

procedure TfrSubtitles.SetLang;
begin
  Caption:=MS('Command.352');

  btLoad1.Caption:=MS('Command.350')+' 1';
  btLoad2.Caption:=MS('Command.350')+' 2';
end;

procedure TfrSubtitles.OnFileName;
var
  B:Boolean;
  S:String;
begin
  S:=Core.MdlMgr.GetString('App.Subs.Title0');
  gbSubs1.Caption:='       1: '+S;
  B:=(S<>'');
  bbReset1.Enabled:=B;
  edShift1.Enabled:=B;
  sbColor1.Enabled:=B;
  pnPrv1.Enabled:=B;

  S:=Core.MdlMgr.GetString('App.Subs.Title1');
  gbSubs2.Caption:='       2: '+S;
  B:=(S<>'');
  bbReset2.Enabled:=B;
  edShift2.Enabled:=B;
  pnPrv2.Enabled:=B;
  sbColor2.Enabled:=B;
end;

procedure TfrSubtitles.bbReset1Click(Sender: TObject);
begin
  Core.MdlMgr.SetSInt32('App.Subs.Shift0',0);
end;

procedure TfrSubtitles.OnShift0;
var
  l:LongInt;
  S:String;
begin
  l:=Core.MdlMgr.getSInt32('App.Subs.Shift0');
  S:=Format('%2.1f',[l/10]);
  if (Copy(S,1,1)<>'-') then S:='+'+S;
  edShift1.Text:=S;
end;

procedure TfrSubtitles.edShift1Change(Sender: TObject);
var
  l:LongInt;
begin
  try
    l:=Trunc(StrToFloat(edShift1.Text)*10);
    Core.MdlMgr.setSInt32('App.Subs.Shift0',l);
  except
  end;
end;

procedure TfrSubtitles.OnShift1;
var
  l:LongInt;
  S:String;
begin
  l:=Core.MdlMgr.getSInt32('App.Subs.Shift1');
  S:=Format('%2.1f',[l/10]);
  if (Copy(S,1,1)<>'-') then S:='+'+S;
  edShift2.Text:=S;
end;

procedure TfrSubtitles.bbReset2Click(Sender: TObject);
begin
  Core.MdlMgr.SetSInt32('App.Subs.Shift1',0);
end;

procedure TfrSubtitles.UpdateOSD;
begin
  Core.FntHlp.CopyFont(pnPrv1.Font,frMain.pnSubs1.Font);
  Core.FntHlp.CopyFont(pnPrv2.Font,frMain.pnSubs2.Font);
  frMain.pnSubs1.Invalidate;
  frMain.pnSubs2.Invalidate;
end;

procedure TfrSubtitles.pnPrv1Click(Sender: TObject);
var
  FD:TFontDialog;
begin
  FD:=TFontDialog.Create(Self);
  Core.FntHlp.CopyFont(pnPrv1.Font,FD.Font);
  if FD.Execute then begin
    Core.FntHlp.CopyFont(FD.Font,pnPrv1.Font);
    UpdateOSD;
  end;
  FD.Free;
end;

procedure TfrSubtitles.sbColor1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CD:TColorDialog;
begin
  CD:=TColorDialog.Create(Self);
  CD.Color:=pnPrv1.Font.Color;
  if CD.Execute then begin
    pnPrv1.Font.Color:=CD.Color;
    //bbColor1.Font.Color:=pnPrv1.Font.Color;
    sbColor1.Brush.Color:=pnPrv1.Font.Color;
    UpdateOSD;
  end;
  CD.Free;
end;

procedure TfrSubtitles.pnPrv2Click(Sender: TObject);
var
  FD:TFontDialog;
begin
  FD:=TFontDialog.Create(Self);
  Core.FntHlp.CopyFont(pnPrv2.Font,FD.Font);
  if FD.Execute then begin
    Core.FntHlp.CopyFont(FD.Font,pnPrv2.Font);
    UpdateOSD;
  end;
  FD.Free;
end;

procedure TfrSubtitles.sbColor2MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  CD:TColorDialog;
begin
  CD:=TColorDialog.Create(Self);
  CD.Color:=pnPrv2.Font.Color;
  if CD.Execute then begin
    pnPrv2.Font.Color:=CD.Color;
    sbColor2.Brush.Color:=pnPrv2.Font.Color;
    UpdateOSD;
  end;
  CD.Free;
end;

end.
