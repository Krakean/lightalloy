unit CfgPgSound;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ConfigPage, StdCtrls, SoundOut;

type
  TCPSound = class(TConfigPageForm)
    gbVolumeControl: TGroupBox;
    cbVolumeWave: TCheckBox;
    cbVolumeMaster: TCheckBox;
    cbAddSound: TCheckBox;
    cbForce44: TCheckBox;
    gbSoundOut: TGroupBox;
    cbSoundDevice: TComboBox;
    cbEqualizer: TCheckBox;
    cbDefAudioStream: TComboBox;
  private
    procedure FillSoundDevices;
  public
    procedure ReadPrefs; override;
    procedure UpdateLang; override;
    procedure ApplyChanges; override;
  end;

implementation

{$R *.dfm}

uses
  LACore;

procedure TCPSound.ApplyChanges;
begin
  with Core.Prefs do begin
    WriteBool('Sound.VolumeWave',cbVolumeWave.Checked);
    WriteBool('Sound.VolumeMaster',cbVolumeMaster.Checked);
 //   WriteBool('Sound.FirstStreamSolo',cbFirstStreamSolo.Checked);
    WriteBool('Sound.AddSound',cbAddSound.Checked);
    WriteBool('Sound.Force44',cbForce44.Checked);
 //   WriteBool('Sound.Equalizer.Enabled',cbEqualizer.Checked);
    WriteInteger('Sound.DefaultStream', cbDefAudioStream.ItemIndex);
  end;

  if (INI.Str['Sound.OutDevice']<>cbSoundDevice.Text) then begin
    INI.Str['Sound.OutDevice']:=cbSoundDevice.Text;
    NeedReloadMedia := TRUE;
  end;
  if Core.Prefs.ReadBool('Sound.Equalizer.Enabled')<>cbEqualizer.Checked then begin
    Core.Prefs.WriteBool('Sound.Equalizer.Enabled',cbEqualizer.Checked);
    NeedReloadMedia := True;
  end;  
end;

procedure TCPSound.FillSoundDevices;
var
  l:LongInt;
  SO:TSoundOut;
  S:String;
begin
  SO:=TSoundOut.Create;
  SO.EnumSoundDevices(cbSoundDevice.Items);
  try
    cbSoundDevice.ItemIndex:=0;

    S:=Core.Prefs.ReadString('Sound.OutDevice');
    for l:=0 to cbSoundDevice.Items.Count-1 do
      if SameText(cbSoundDevice.Items[l],S) then
        cbSoundDevice.ItemIndex:=l;
  except
  end;
  SO.Free;
end;

procedure TCPSound.ReadPrefs;
begin
  with Core.Prefs do begin
    cbVolumeWave.Checked:=ReadBool('Sound.VolumeWave');
    cbVolumeMaster.Checked:=ReadBool('Sound.VolumeMaster');
 //   cbFirstStreamSolo.Checked:=ReadBool('Sound.FirstStreamSolo');
    cbAddSound.Checked:=ReadBool('Sound.AddSound');
    cbForce44.Checked:=ReadBool('Sound.Force44');
    cbDefAudioStream.ItemIndex := ReadInteger('Sound.DefaultStream');
    cbEqualizer.Checked:=ReadBool('Sound.Equalizer.Enabled');
    FillSoundDevices;
  end;
end;

procedure TCPSound.UpdateLang;
begin
  gbVolumeControl.Caption:=' '+MS('Config.Sound.VolumeControl')+' ';
  cbVolumeWave.Caption:=MS('Config.Sound.VolumeControl.Wave');
  cbVolumeMaster.Caption:=MS('Config.Sound.VolumeControl.Master');
  gbSoundOut.Caption:=' '+MS('Config.Sound.DeviceDefaultTrack')+' ';
  cbAddSound.Caption:=MS('Config.Sound.AddSound');
  cbForce44.Caption:=MS('Config.Sound.Force44KHz');
  cbEqualizer.Caption:=MS('Config.Sound.UseEqualizer');
end;

end.
