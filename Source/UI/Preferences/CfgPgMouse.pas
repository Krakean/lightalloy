unit CfgPgMouse;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ConfigPage, StdCtrls, ExtCtrls, ComCtrls;

type
  TCPMouse = class(TConfigPageForm)
    cbMouseWheelInvert: TCheckBox;
    lbHideMouse: TLabel;
    lbMouseInactivity: TLabel;
    edMouseTimeout: TEdit;
    udMouseTimeout: TUpDown;
    cbHoverCPanel: TCheckBox;
    cbAdditionalkeys: TComboBox;
    cbMouseRight: TComboBox;
    cbMouseLeft: TComboBox;
    cbMouseMiddle: TComboBox;
    cbMouseLeftDbl: TComboBox;
    gbMouseLeft: TGroupBox;
    gbMouseRight: TGroupBox;
    gbMouseMiddle: TGroupBox;
    gbMouseLeftDbl: TGroupBox;
    gbAdditionalKeys: TGroupBox;
    gbMouseWheel: TGroupBox;
    cbMouseWheel: TComboBox;
  private
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

implementation

{$R *.dfm}

uses
  LACore;

procedure TCPMouse.ApplyChanges;
begin
  with Core.Prefs do begin
    WriteInteger('Mouse.Left',cbMouseLeft.ItemIndex);
    WriteInteger('Mouse.LeftDbl',cbMouseLeftDbl.ItemIndex);
    WriteInteger('Mouse.Middle',cbMouseMiddle.ItemIndex);
    WriteInteger('Mouse.Wheel',cbMouseWheel.ItemIndex);
    WriteBool('Mouse.WheelInvert',cbMouseWheelInvert.Checked);
    WriteInteger('Mouse.Right',cbMouseRight.ItemIndex);
    Int['Mouse.TimeOut']:=udMouseTimeout.Position;
    Bool['Mouse.HoverCPanel']:=cbHoverCPanel.Checked;
    WriteInteger('Mouse.Additional', cbAdditionalkeys.ItemIndex);
  end;
end;

procedure TCPMouse.ReadPrefs;
begin
  with Core.Prefs do begin
    cbMouseLeft.ItemIndex:=ReadInteger('Mouse.Left');
    cbMouseLeftDbl.ItemIndex:=ReadInteger('Mouse.LeftDbl');
    cbMouseMiddle.ItemIndex:=ReadInteger('Mouse.Middle');
    cbMouseWheel.ItemIndex:=ReadInteger('Mouse.Wheel');
    cbMouseWheelInvert.Checked:=ReadBool('Mouse.WheelInvert');
    cbMouseRight.ItemIndex:=ReadInteger('Mouse.Right');
    udMouseTimeout.Position:=Int['Mouse.TimeOut'];
    cbHoverCPanel.Checked:=ReadBool('Mouse.HoverCPanel');
    cbAdditionalkeys.ItemIndex:=ReadInteger('Mouse.Additional');
  end;
end;

procedure TCPMouse.UpdateLang;
begin
  gbMouseLeft.Caption:=' '+MS('Config.Mouse.Left')+' ';
  cbMouseLeft.Items[0]:=MS('Config.Mouse.Left.0');
  cbMouseLeft.Items[1]:=MS('Config.Mouse.Left.1');
  cbMouseLeft.Items[2]:=MS('Config.Mouse.Left.2');
  cbMouseLeft.Items[3]:=MS('Config.Mouse.Left.3');
  cbMouseLeft.Items[4]:=MS('Config.Mouse.Left.4');

  gbMouseLeftDbl.Caption:=' '+MS('Config.Mouse.LeftDbl')+' ';
  cbMouseLeftDbl.Items[0]:=MS('Config.Mouse.LeftDbl.0');
  cbMouseLeftDbl.Items[1]:=MS('Config.Mouse.LeftDbl.1');
  cbMouseLeftDbl.Items[2]:=MS('Config.Mouse.LeftDbl.2');

  gbMouseMiddle.Caption:=' '+MS('Config.Mouse.Middle')+' ';
  cbMouseMiddle.Items[0]:=MS('Config.Mouse.Middle.0');
  cbMouseMiddle.Items[1]:=MS('Config.Mouse.Middle.1');
  cbMouseMiddle.Items[2]:=MS('Config.Mouse.Middle.2');
  cbMouseMiddle.Items[3]:=MS('Config.Mouse.Middle.3');  

  gbMouseWheel.Caption:=' '+MS('Config.Mouse.Wheel')+' ';
  cbMouseWheel.Items[0]:=MS('Config.Mouse.Wheel.0');
  cbMouseWheel.Items[1]:=MS('Config.Mouse.Wheel.1');
  cbMouseWheel.Items[2]:=MS('Config.Mouse.Wheel.2');
  cbMouseWheel.Items[3]:=MS('Config.Mouse.Wheel.3');
  cbMouseWheel.Items[4]:=MS('Config.Mouse.Wheel.4');
  cbMouseWheel.Items[5]:=MS('Config.Mouse.Wheel.5');
  cbMouseWheel.Items[6]:=MS('Config.Mouse.Wheel.6');

  gbAdditionalKeys.Caption:=' '+MS('Config.Mouse.AdditionalKeys')+' ';
  cbAdditionalkeys.Items[0]:=MS('Config.Mouse.AdditionalKeys.0');
  cbAdditionalkeys.Items[1]:=MS('Config.Mouse.AdditionalKeys.1');
  cbAdditionalkeys.Items[2]:=MS('Config.Mouse.AdditionalKeys.2');
  cbAdditionalkeys.Items[3]:=MS('Config.Mouse.AdditionalKeys.3');

  cbMouseWheelInvert.Caption:=MS('Config.Mouse.Wheel.Invert');
  gbMouseRight.Caption:=' '+MS('Config.Mouse.Right')+' ';
  cbMouseRight.Items[0]:=MS('Config.Mouse.Right.0');
  cbMouseRight.Items[1]:=MS('Config.Mouse.Right.1');
  cbMouseRight.Items[2]:=MS('Config.Mouse.Right.2');
  lbHideMouse.Caption:=MS('Config.Mouse.HideMouse');
  lbMouseInactivity.Caption:=MS('Config.Mouse.Inactivity');

  cbHoverCPanel.Caption:=MS('Config.Mouse.HoverCPanel');
end;

end.
