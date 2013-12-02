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
unit AudioProps;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, VCL2Model, Buttons;

type
  TfrAudioProps = class(TForm)
    gb1: TGroupBox;
    gb2: TGroupBox;
    gb3: TGroupBox;
    gb4: TGroupBox;
    gb5: TGroupBox;
    tb1: TTrackBar;
    tb2: TTrackBar;
    tb3: TTrackBar;
    tb4: TTrackBar;
    tb5: TTrackBar;
    bt1: TButton;
    bt2: TButton;
    bt3: TButton;
    bt4: TButton;
    bt5: TButton;
    tbBal1: TTrackBar;
    tbBal2: TTrackBar;
    tbBal3: TTrackBar;
    tbbal4: TTrackBar;
    tbbal5: TTrackBar;
    cb1: TCheckBox;
    cb2: TCheckBox;
    cb3: TCheckBox;
    cb4: TCheckBox;
    cb5: TCheckBox;

    {EQ}
    gbEQ: TGroupBox;
    tbEq0: TTrackBar;
    tbEq1: TTrackBar;
    tbEq2: TTrackBar;
    tbEq3: TTrackBar;
    tbEq4: TTrackBar;
    tbEq5: TTrackBar;
    tbEq6: TTrackBar;
    tbeq7: TTrackBar;
    tbEq8: TTrackBar;
    tbEq9: TTrackBar;
    lbl0: TLabel;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    lbl4: TLabel;
    lbl5: TLabel;
    lbl6: TLabel;
    lbl7: TLabel;
    lbl8: TLabel;
    lbl9: TLabel;
    btEqReset: TButton;
    tbAmplify: TTrackBar;
    lblAmplify: TLabel;
    cbNormalization: TCheckBox;
    tbDynAmp: TTrackBar;
    gbNormalization: TGroupBox;
    procedure cb1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure cb2MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure cb3MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure cb4MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure cb5MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure bt1Click(Sender: TObject);
    procedure bt2Click(Sender: TObject);
    procedure bt3Click(Sender: TObject);
    procedure bt4Click(Sender: TObject);
    procedure bt5Click(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormActivate(Sender: TObject);
    procedure EQTune(Sender: TObject);
    procedure btEqResetClick(Sender: TObject);
    procedure tbChange(Sender: TObject);
    procedure tbBalChange(Sender: TObject);
    procedure tbAmplifyChange(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure cbNormalizationClick(Sender: TObject);
    procedure tbDynAmpChange(Sender: TObject);
  private
    HintDelay: Integer;
    V2M:TVCL2Model;
    procedure TuneLang;
    procedure UpdateCtrls;
  end;

var
  frAudioProps: TfrAudioProps;
  FirstActivate: Integer = 1;
  FirstActivateEq: Integer = 1;

implementation

uses MainUnit, LACore;

{$R *.dfm}

{ TfrAudioProps }

procedure TfrAudioProps.FormCreate(Sender: TObject);
begin
  V2M:=TVCL2Model.Create(Core.MdlMgr);
  if not frMain.AudioModel.AlternativeEngine then begin
    with V2M do begin
      CurModel:='App.AudioProps';
      Link('Enabled0',cb1);
      Link('Enabled1',cb2);
      Link('Enabled2',cb3);
      Link('Enabled3',cb4);
      Link('Enabled4',cb5);
      Link('Balance0',tbBal1);
      Link('Balance1',tbBal2);
      Link('Balance2',tbBal3);
      Link('Balance3',tbBal4);
      Link('Balance4',tbBal5);
      Link('Volume0',tb1);
      Link('Volume1',tb2);
      Link('Volume2',tb3);
      Link('Volume3',tb4);
      Link('Volume4',tb5);
      Link('Decoder0',bt1);
      Link('Decoder1',bt2);
      Link('Decoder2',bt3);
      Link('Decoder3',bt4);
      Link('Decoder4',bt5);
    end;
  end;
end;

procedure TfrAudioProps.FormDestroy(Sender: TObject);
begin
  V2M.Free;
end;

procedure TfrAudioProps.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_ESCAPE) then Close;
end;

procedure TfrAudioProps.TuneLang;
begin
  Caption:=MS('Command.400');

  cb1.Caption:=MS('Audio.Channel')+' 1';
  cb2.Caption:=MS('Audio.Channel')+' 2';
  cb3.Caption:=MS('Audio.Channel')+' 3';
  cb4.Caption:=MS('Audio.Channel')+' 4';
  cb5.Caption:=MS('Audio.Channel')+' 5';

  bt1.Caption:=MS('Audio.Decoder');
  bt2.Caption:=MS('Audio.Decoder');
  bt3.Caption:=MS('Audio.Decoder');
  bt4.Caption:=MS('Audio.Decoder');
  bt5.Caption:=MS('Audio.Decoder');
end;

procedure TfrAudioProps.FormActivate(Sender: TObject);
var
  i: Byte;
  cb: TCheckBox;
  tb: TTrackbar;
  tbbal: TTrackbar;
  bt: TButton;
begin
  HintDelay:=Application.HintPause;
  Application.HintPause:=0;
  TuneLang;

  for i := 0 to 9 do begin
    tb := FindComponent('tbEq' + IntToStr(i)) as TTrackBar;
    tb.Position := frMain.EQModel.EQBands[i];
    if frMain.EQModel.EQEnabled then begin
      tb.Hint := IntToStr(-tb.Position);
      tb.ShowHint:=True;
    end
    else
      tb.ShowHint:=False;
    tb.Enabled := frMain.EQModel.EQEnabled;
  end;
  btEQreset.Enabled := frMain.EQModel.EQEnabled;
  tbAmplify.Enabled := frMain.EQModel.EQEnabled;
  cbNormalization.Enabled := frMain.EQModel.EQEnabled;
  if tbAmplify.Enabled then begin
    tbAmplify.ShowHint:=True;;
    tbAmplify.Hint:=IntToStr(tbAmplify.Position);
  end
  else
    tbAmplify.ShowHint:=False;

  tbAmplify.Position := frMain.EQModel.EQPreAmp;
  cbNormalization.Checked := frMain.DAModel.DAEnabled;
  tbDynAmp.Enabled := cbNormalization.Enabled and cbNormalization.Checked;
  if frMain.DAModel.MaxAmp=0 then
    tbDynAmp.Position := 10
  else
    tbDynAmp.Position := -(frMain.DAModel.MaxAmp -10);


  if not frMain.AudioModel.AlternativeEngine then Exit;
  for i := 1 to 5 do begin
    with frMain.AudioModel.AltChans[i] do begin
      cb := FindComponent('cb' + IntToStr(i)) as TCheckBox;
      tb := FindComponent('tb' + IntToStr(i)) as TTrackBar;
      tbbal := FindComponent('tbbal' + IntToStr(i)) as TTrackBar;
      bt := FindComponent('bt' + IntToStr(i)) as TButton;
      cb.Enabled:=Enabled;
      cb.Checked:=Selected;
      tb.Enabled:=Enabled;
      tb.Position:=100-Volume;
      tb.OnChange:=tbChange;
      tbbal.Enabled:=Enabled;
      tbbal.Position:=Balance;
      tbbal.OnChange:=tbbalChange;
      bt.Enabled:=Enabled;
    end;
    bt1.OnClick:=bt1Click;
    bt2.OnClick:=bt2Click;
    bt3.OnClick:=bt3Click;
    bt4.OnClick:=bt4Click;
    bt5.OnClick:=bt5Click;
  end;
  UpdateCtrls;
end;

procedure TfrAudioProps.EQTune(Sender: TObject);
var
  i: Byte;
  tb: TTrackBar;
begin
  if (FirstActivateEq<10) then begin Inc(FirstActivateEq); Exit; end;
  if not Core.Prefs.ReadBool('Sound.Equalizer.Enabled')
    or not Assigned(frMain.EQModel)
  then Exit;
  for i:=0 to 9 do begin
    tb := FindComponent('tbEq' + IntToStr(i)) as TTrackBar;
    frMain.EQModel.EQBands[i]:=tb.Position;
    tb.Hint:=IntToStr(-tb.Position);
  end;
end;

procedure TfrAudioProps.btEqResetClick(Sender: TObject);
var
  i: Byte;
  tb: TTrackBar;
begin
  frMain.EQModel.ResetBands;
  for i:=0 to 9 do begin
    tb := FindComponent('tbEq' + IntToStr(i)) as TTrackBar;
    tb.Position := 0;
  end;
  tbAmplify.Position:=0;
  tbDynAmp.Position:=0;
end;

procedure TfrAudioProps.tbChange(Sender: TObject);
var
  i: Byte;
  tb: TTrackBar;
begin
  If FirstActivate<frMain.AudioModel.AudioStreamsCount then Begin
    Inc(FirstActivate);
    Exit;
  end;

  for i:=1 to 5 do begin
    tb := FindComponent('tb' + IntToStr(i)) as TTrackBar;
    frMain.AudioModel.AltChans[i].Volume:=100-tb.Position;
  end;
  frMain.AudioModel.UpdateVolume;
end;

procedure TfrAudioProps.tbBalChange(Sender: TObject);
var
  i: Byte;
  tbbal: TTrackBar;
begin
  for i:=1 to 5 do begin
    tbbal := FindComponent('tbbal' + IntToStr(i)) as TTrackBar;
    frMain.AudioModel.AltChans[i].Balance := tbbal.Position;
  end;
  frMain.AudioModel.UpdateVolume;
end;

procedure TfrAudioProps.UpdateCtrls;
var
  i: Byte;
  cb: TCheckBox;
  tb: TTrackBar;
  tbbal: TTrackBar;
begin
  for i := 1 to frMain.AudioModel.AudioStreamsCount+1 do begin
    cb := FindComponent('cb' + IntToStr(i)) as TCheckBox;
    tb := FindComponent('tb' + IntToStr(i)) as TTrackBar;
    tbbal := FindComponent('tbbal' + IntToStr(i)) as TTrackBar;

    with frMain.AudioModel.AltChans[i] do begin
      cb.Checked:=Selected;
      tb.Enabled:=Selected;
      tb.Position:=100-Volume;
      tbbal.Enabled:=Selected;
      tbbal.Position:=Balance;
    end;
  end;
end;

procedure TfrAudioProps.cb1MouseUp;
begin
  if not frMain.AudioModel.AlternativeEngine then Exit;
  frMain.AudioModel.SetStream(1);
  cb1.Checked:=True;
  UpdateCtrls;
end;

procedure TfrAudioProps.cb2MouseUp;
begin
  if not frMain.AudioModel.AlternativeEngine then Exit;
  frMain.AudioModel.SetStream(2);
  cb2.Checked:=True;
  UpdateCtrls;
end;

procedure TfrAudioProps.cb3MouseUp;
begin
  if not frMain.AudioModel.AlternativeEngine then Exit;
  frMain.AudioModel.SetStream(3);
  cb3.Checked:=True;
  UpdateCtrls;
end;

procedure TfrAudioProps.cb4MouseUp;
begin
  if not frMain.AudioModel.AlternativeEngine then Exit;
  frMain.AudioModel.SetStream(4);
  cb4.Checked:=True;
  UpdateCtrls;
end;

procedure TfrAudioProps.cb5MouseUp;
begin
  if not frMain.AudioModel.AlternativeEngine then Exit;
  frMain.AudioModel.SetStream(5);
  cb5.Checked:=True;
  UpdateCtrls;
end;

procedure TfrAudioProps.bt1Click(Sender: TObject);
begin
  frMain.AudioModel.OnDecoder(1);
end;

procedure TfrAudioProps.bt2Click(Sender: TObject);
begin
  frMain.AudioModel.OnDecoder(2);
end;

procedure TfrAudioProps.bt3Click(Sender: TObject);
begin
  frMain.AudioModel.OnDecoder(3);
end;

procedure TfrAudioProps.bt4Click(Sender: TObject);
begin
  frMain.AudioModel.OnDecoder(4);
end;

procedure TfrAudioProps.bt5Click(Sender: TObject);
begin
  frMain.AudioModel.OnDecoder(5);
end;

procedure TfrAudioProps.tbAmplifyChange(Sender: TObject);
begin
  if not Core.Prefs.ReadBool('Sound.Equalizer.Enabled')
    or not Assigned(frMain.EQModel)
  then Exit;
  frMain.EQModel.EQPreAmp:=tbAmplify.Position;
  tbAmplify.Hint:=IntToStr(-tbAmplify.Position);
end;

procedure TfrAudioProps.FormDeactivate(Sender: TObject);
begin
  Application.HintPause:=HintDelay;
end;

procedure TfrAudioProps.cbNormalizationClick(Sender: TObject);
begin
  frMain.DAModel.DAEnabled:=cbNormalization.Checked;
  tbDynAmp.Enabled:=cbNormalization.Checked;
end;

procedure TfrAudioProps.tbDynAmpChange(Sender: TObject);
begin
  if not Core.Prefs.ReadBool('Sound.Equalizer.Enabled')
    or not Assigned(frMain.EQModel)
  then Exit;
  frMain.DAModel.MaxAmp:= -(tbDynAmp.Position -10);
end;

end.
