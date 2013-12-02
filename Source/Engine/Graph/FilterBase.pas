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
unit FilterBase;

interface

const
  // Decreased values!
  SplittersCount = 9;
  AudioSourceCount = 13;
  VideoSourceCount = 20;
  AudioDecodersCount  = 13;
  VideoDecodersCount  = 28;
  AudioRenderersCount = 1;
  VideoRenderersCount = 6;
  AdvancedFiltersCount= 1;

  vrDef:   Byte = 0;
  vrVR:    Byte = 1;
  vrVMR7:  Byte = 2;
  vrVMR9:  Byte = 3;
  vrEVR:   Byte = 4;
  vrHaali: Byte = 5;
  vrMadVR: Byte = 6;  

type
  TFilterInf = record
    FCC:      String;
    NAME:     String;
    FILENAME: String;
    CLSID:    TGUID;
    PRIORITY: Shortint;
    LOCALPATH:String;
  end;

  TSplitters = array [0..SplittersCount] of TFilterInf;

  TAudioSource = array [0..AudioSourceCount] of TFilterInf;
  TVideoSource = array [0..VideoSourceCount] of TFilterInf;

  TAudioDecoders = array [0..AudioDecodersCount] of TFilterInf;
  TVideoDecoders = array [0..VideoDecodersCount] of TFilterInf;

  TAudioRenderers = array [0..AudioRenderersCount] of TFilterInf;
  TVideoRenderers = array [0..VideoRenderersCount] of TFilterInf;

  TAdvancedFilters = array [0..AdvancedFiltersCount] of TFilterInf;

const
  // Splitters //
  Splitters: TSplitters = (
    (FCC:     '/AVI/MKV/MP4/FLV/WMV/TS/RM/RLMD/ASF/QT/MPG1/MPG2/WEBM/MTS/BDMV/MPLS/';
     Name:    'LAV Splitter';
     FileName:'LAVSplitter.ax';
     CLSID:   '{171252A0-8820-4AFE-9DF8-5C92B2D66B04}';),

    (FCC:     '/MKV/MKA/AVI/QT/MP4/TS/WEBM/';
     Name:    'Haali Media Splitter';
     FileName:'splitter.ax';
     CLSID:   '{564FD788-86C9-4444-971E-CC4A243DA150}';),

    (FCC:     '/AVI/';
     Name:    'AVI Splitter';
     FileName:'AviSplitter.ax';
     CLSID:   '{9736D831-9D6C-4E72-B6E7-560EF9181001}';),

    (FCC:     '/FLV/';
     Name:    'FLV Splitter';
     FileName:'FLVSplitter.ax';
     CLSID:   '{47E792CF-0BBE-4F7A-859C-194B0768650A}';),

    (FCC:     '/MKV/MKA/';
     Name:    'Matroska Splitter';
     FileName:'MatroskaSplitter.ax';
     CLSID:   '{149D2E01-C32E-4939-80F6-C07B81015A7A}';),

    (FCC:     '/MP4/QT/';
     Name:    'MP4 Splitter';
     FileName:'MP4Splitter.ax';
     CLSID:   '{61F47056-E400-43D3-AF1E-AB7DFFD4C4AD}';),

    (FCC:     '/MTS/TS/MPG1/MPG2/';
     Name:    'MPEG Splitter';
     FileName:'MpegSplitter.ax';
     CLSID:   '{DC257063-045F-4BE2-BD5B-E12279C464F0}';),

    (FCC:     '/MP4/QT/';
     Name:    'MPC MP4 Splitter';
     FileName:'MP4Splitter.ax';
     CLSID:   '{D3D9D58B-45B5-48AB-B199-B8C40560AEC7}';),

    (FCC:     '/OGG/OGM/';
     Name:    'OGG Splitter';
     FileName:'OggSplitter.ax';
     CLSID:   '{9FF48807-E133-40AA-826F-9B2959E5232D}';),

    (FCC:     '/RM/RLMD/';
     Name:    'MPC RealMedia Splitter';
     FileName:'RealMediaSplitter.ax';
     CLSID:   '{E21BE468-5C18-43EB-B0CC-DB93A847D769}';)
  );

  // Audio Source //
  AudioSource: TAudioSource = (
    (FCC:     '/MP3/AAC/APE/FLAC/OGG/MOD/XM/S3M/SHOUTCAST/';
     Name:    'DC-Bass Source';
     FileName:'DCBassSource.ax';
     CLSID:   '{ABE7B1D9-4B3E-4ACD-A0D1-92611D3A4492}';),

    (FCC:     '/MP3/AAC/APE/FLAC/OGG/MOD/XM/S3M/SHOUTCAST/';
     Name:    'DC-Bass Source';
     FileName:'DCBassSourceMod.ax';
     CLSID:   '{ABE7B1D9-4B3E-4ACD-A0D1-92611D3A4492}';),

    (FCC:     '/MP2/MP3/';
     Name:    'MP3 Parser Filter';
     FileName:'mp3parse.ax';
     CLSID:   '{13CEBFE0-256B-44BA-A27B-9F85CBDB972D}';),

    (FCC:     '/FLAC/';
     Name:    'MPC FLAC Source';
     FileName:'FLACSource.ax';
     CLSID:   '{1930D8FF-4739-4E42-9199-3B2EDEAA3BF2}';),

    (FCC:     '/FLAC/';
     Name:    'madFlac Source';
     FileName:'madFlac.ax';
     CLSID:   '{C52908F0-1C06-4C0D-A4CD-3D10EA51C757}';),

    (FCC:     '/AC3/';
     Name:    'AC3File';
     FileName:'ac3file.ax';
     CLSID:   '{F7380D4C-DE45-4F03-9209-15EBA8552463}';),

    (FCC:     '/WAV/';
     Name:    'Wave Parser';
     FileName:'quartz.dll';
     CLSID:   '{D51BD5A1-7548-11CF-A520-0080C77EF58A}';),

    (FCC:     '/CDA/';
     Name:    'CDDA Reader';
     FileName:'cddareader.ax';
     CLSID:   '{54A35221-2C8D-4A31-A5DF-6D809847E393}';),

    (FCC:     '/CDA/';
     Name:    'BTCDAKReader';
     FileName:'BTCDAKReader.ax';
     CLSID:   '{2527BF5E-EC96-4B43-BDFB-6326DDF3CE36}';),

    (FCC:     '/OGG/OGM/';
     Name:    'Ogg Splitter';
     FileName:'oggds.dll';
     CLSID:   '{F07E245F-5A1F-4D1E-8BFF-DC31D84A55AB}';),

    (FCC:     '/DTS/AC3/DD+/';
     Name:    'DTS/AC3/DD+ Source';
     FileName:'dtsac3source.ax';
     CLSID:   '{B4A7BE85-551D-4594-BDC7-832B09185041}';),

    (FCC:     '/FLAC/OGG/AAC/AC3/AT3/AIFF/AIFC/MPC/';
     Name:    'LAV Source';
     FileName:'LAVSplitter.ax';
     CLSID:   '{B98D13E7-55DB-4385-A33D-09FD1BA26338}';),

    (FCC:     '/MPC/';
     Name:    'MONOGRAM Musepack Splitter';
     FileName:'mmmpcdmx.ax';
     CLSID:   '{C3E2E983-0198-4F73-9E5C-8365BB4C4131}';),

    (FCC:     '/MOD/XM/IT/';
     Name:    'File Source (MO3/XM/IT)';
     FileName:'MODSource.ax';
     CLSID:   '{C5C8E44B-19D1-4AAD-91C5-4903867F71DA}';)
  );

  // Video Source //
  VideoSource: TVideoSource = (
    (FCC:     '/AVI/';
     Name:    'AVI Source';
     FileName:'AviSplitter.ax';
     CLSID:   '{CEA8DEFF-0AF7-4DB9-9A38-FB3C3AEFC0DE}';),

    (FCC:     '/MTS/TS/MPG1/MPG2/';
     Name:    'MPEG Source';
     FileName:'MpegSplitter.ax';
     CLSID:   '{1365BE7A-C86A-473C-9A41-C0A6E82C9FA3}';),

    (FCC:     '/MPG1/MPG2/CDXA/';
     Name:    'Ligos MPEG Splitter';
     FileName:'lmpgspl.ax';
     CLSID:   '{CB51EFC1-40D6-11D3-B265-00A0C9A3A56F}'),

    (FCC:     '/CDXA/';
     Name:    'CDXA Reader';
     FileName:'cdxareader.ax';
     CLSID:   '{D367878E-F3B8-4235-A968-F378EF1B9A44}'),

    (FCC:     '/3GP/3G2/';
     Name:    'ArcSoft 3GP Source';
     FileName:'3GPSplitter.ax';
     CLSID:   '{F710DD5E-3ED7-442F-BA31-4BD2DF7F4366}';),

    (FCC:     '/DRC/';
     Name:    'Dirac Source';
     FileName:'DiracSplitter.ax';
     CLSID:   '{09E7F58E-71A1-419D-B0A0-E524AE1454A9}';),

    (FCC:     '/OGG/OGM/';
     Name:    'OGG Source';
     FileName:'OggSplitter.ax';
     CLSID:   '{6D3688CE-3E9D-42F4-92CA-8A11119D25CD}';),

    (FCC:     '/RM/RLMD/';
     Name:    'RealMedia Source';
     FileName:'RealMediaSplitter.ax';
     CLSID:   '{E21BE468-5C18-43EB-B0CC-DB93A847D769}';),

    (FCC:     '/RM/RLMD/';
     Name:    'MPC RealMedia Source';
     FileName:'RealMediaSplitter.ax';
     CLSID:   '{765035B3-5944-4A94-806B-20EE3415F26F}';),

    (FCC:     '/ROQ/';
     Name:    'RoQ Source';
     FileName:'RoQSplitter.ax';
     CLSID:   '{02B8E5C2-4E1F-45D3-9A8E-B8F1EDE6DE09}';),

    (FCC:     '/MKV/MKA/';
     Name:    'Matroska Source';
     FileName:'MatroskaSplitter.ax';
     CLSID:   '{0A68C3B5-9164-4A54-AFAF-995B2FF0E0D4}';),

    (FCC:     '/MP4/QT/';
     Name:    'MP4 Source';
     FileName:'MP4Splitter.ax';
     CLSID:   '{3CCC052E-BDEE-408A-BEA7-90914EF2964B}';),

    (FCC:     '/MP4/QT/';
     Name:    'MPC MP4 Source';
     FileName:'MP4Splitter.ax';
     CLSID:   '{E2B98EEA-EE55-4E9B-A8C1-6E5288DF785A}';),

    (FCC:     '/AVI/MKV/MP4/FLV/WMV/TS/RM/RLMD/ASF/QT/MPG1/MPG2/WEBM/MTS/BDMV/MPLS/';
     Name:    'LAV Source';
     FileName:'LAVSplitter.ax';
     CLSID:   '{B98D13E7-55DB-4385-A33D-09FD1BA26338}';),

    (FCC:     '/MPG1/CDXA/';
     Name:    'MPEG-I Stream Splitter';
     FileName:'quartz.dll';
     CLSID:   '{336475D0-942A-11CE-A870-00AA002FEAB5}';),

    (FCC:     '/MPG2/';
     Name:    'MPEG-2 Splitter';
     FileName:'mpg2splt.ax';
     CLSID:   '{3AE86B20-7BE8-11D1-ABE6-00A0C905F375}'),

    (FCC:     '/MPG2/';
     Name:    'MPEG-2 Demultiplexer';
     FileName:'mpg2splt.ax';
     CLSID:   '{AFB6C280-2C41-11D3-8A60-0000F81E0E4A}'),     

    (FCC:     '/MKV/MKA/AVI/QT/MP4/TS/WEBM/';
     Name:    'Haali Media Splitter';
     FileName:'splitter.ax';
     CLSID:   '{55DA30FC-F16B-49FC-BAA5-AE59FC65F82D}';),

    (FCC:     '/QT/';
     Name:    'QuickTime Movie Parser';
     FileName:'quartz.dll';
     CLSID:   '{D51BD5A0-7548-11CF-A520-0080C77EF58A}';),

    (FCC:     '/FLV/';
     Name:    'FLV Source';
     FileName:'FLVSplitter.ax';
     CLSID:   '{C9ECE7B3-1D8E-41F5-9F24-B255DF16C087}';),

    (FCC:     '/FLIC/';
     Name:    'FLICSource';
     FileName:'flicsource.ax';
     CLSID:   '{17DB5CF6-39BB-4D5B-B0AA-BEBA44673AD4}')
  );

  // Audio Decoders //
  AudioDecoders: TAudioDecoders = (
    (FCC:     '/2000/2001/';
     Name:    'AC3Filter';
     FileName:'ac3filter.ax';
     CLSID:   '{A753A1EC-973E-4718-AF8E-A3F554D45C44}';),

    (FCC:     '/2000/2001/';
     Name:    'Cyberlink Audio Decoder';
     FileName:'claud.ax';
     CLSID:   '{9BC1B780-85E3-11D2-98D0-0080C84E9C39}';),

    (FCC:     '/2000/2001/';
     Name:    'InterVideo Audio Decoder';
     FileName:'iviaudio.ax';
     CLSID:   '{7E2E0DC1-31FD-11D2-9C21-00104B3801F6}';),

    (FCC:     '/00FF/01FF/';
     Name:    'MONOGRAM AAC Decoder';
     FileName:'mmaacd.ax';
     CLSID:   '{3FC3DBBF-9D37-4CE0-8689-653FE8BAB9B3}';),

    (FCC:     '/0075/';
     Name:    'Voxware MetaSound Codec';
     FileName:'voxmsdec.ax';
     CLSID:   '{73F7A062-8829-11D1-B550-006097242D8D}';),

    (FCC:     '/674F/676F/6750/6770/6751/6771/';
     Name:    'Vorbis Decoder';
     FileName:'OggDS.dll';
     CLSID:   '{02391F44-2767-4E6A-A484-9B47B506F3A4}';),

    (FCC:     '/0270/';
     Name:    'OMG TRANSFORM';
     FileName:'omgtrans.ax';
     CLSID:   '{98660581-C9A8-4C92-B480-F27DE3C3AAB4}';),

    (FCC:     '/EACC/';
     Name:    'MONOGRAM Musepack Decoder';
     FileName:'mmmpcdec.ax';
     CLSID:   '{555C4774-101E-49D7-8EEC-B9B87F8E1905}';),

    (FCC:     '/0161/0162/0163/';
     Name:    'WMAudio Decoder DMO';
     FileName:'qasf.dll';
     CLSID:   '{94297043-BD82-4DFD-B0DE-8177739C6D20}';),

    (FCC:     '/ANY/';
     Name:    'ffdshow Audio Decoder';
     FileName:'ffdshow.ax';
     CLSID:   '{0F40E1E5-4F79-4988-B1A9-CC98794E6B55}';),

    (FCC:     '/ANY/';
     Name:    'LAV Audio Decoder';
     FileName:'LAVAudio.ax';
     CLSID:   '{E8E73B6B-4CB3-44A4-BE99-4F7BCB96E491}';),

    (FCC:     '/ANY/';
     Name:    'MPA Decoder Filter';
     FileName:'MpaDecFilter.ax';
     CLSID:   '{3D446B6F-71DE-4437-BE15-8CE47174340F}';),

    (FCC:     '/0050/';
     Name:    'MPEG Audio Codec';
     FileName:'quartz.dll';
     CLSID:   '{4A2286E0-7BEF-11CE-9BD9-0000E202599C}';),     

    (FCC:     '/0055/';
     Name:    'Fraunhofer MPEG Layer-3 Audio Decoder';
     FileName:'L3CODECX.1.9.AX';
     CLSID:   '{38BE3000-DBF4-11D0-860E-00A024CFEF6D}';)
  );

  // Video Decoders //
  VideoDecoders: TVideoDecoders = (
    (FCC:     '/DIVX/DVX1/DIV3/DIV4/DIV5/DX50/DIV6/';
     Name:    'DivX Decoder';
     FileName:'divxdec.ax';
     CLSID:   '{78766964-0000-0010-8000-00AA00389B71}';),

    (FCC:     '/DIV1/DIV2/DIV3/MP4S/';
     Name:    'DivX MPEG-4 DVD Video Decompressor';
     FileName:'DivX_c32.ax';
     CLSID:   '{82CCD3E0-F71A-11D0-9FE5-00609778AAAA}';),

    (FCC:     '/H264/X264/DAVC/AVC1/';
     Name:    'DivX H.264 Decoder';
     FileName:'DivXDecH264.ax';
     CLSID:   '{6F513D27-97C3-453C-87FE-B24AE50B1601}';),

    (FCC:     '/FLV1/FLV4/VP62/';
     Name:    'FLV Video Decoder';
     FileName:'FLVSplitter.ax';
     CLSID:   '{7CEEEECF-3FEE-4548-B529-C254CAF4D182}';),

    (FCC:     '/IV50/';
     Name:    'Intel Video Decoder 5.0';
     FileName:'ir50_32.dll';
     CLSID:   '{30355649-0000-0010-8000-00AA00389B71}';),

    (FCC:     '/IV41/';
     Name:    'Intel Video Decoder 4.1';
     FileName:'ir41_32.ax';
     CLSID:   '{31345649-0000-0010-8000-00AA00389B71}';),

    (FCC:     '/COL1/';
     Name:    'MPEG-4 Video Decompressor';
     FileName:'ool1c32.ax';
     CLSID:   '{058C4840-3D73-11D4-8C05-006067438E34}';),

    (FCC:     '/MPG1/MPG2/';
     Name:    'Cyberlink Video Decoder';
     FileName:'clvsd.ax';
     CLSID:   '{9BC1B781-85E3-11D2-98D0-0080C84E9C39}'),

    (FCC:     '/MPG1/MPG2/';
     Name:    'Cyberlink Video Decoder';
     FileName:'clvsd.ax';
     CLSID:   '{516F1EFA-42F4-436E-801C-B752EB9343EB}'),

    (FCC:     '/MPG1/MPG2/';
     Name:    'DScaler Mpeg2 Video Decoder';
     FileName:'MpegVideo.dll';
     CLSID:   '{F8904F1F-0371-4471-8866-90E6281ABDB6}'),

    (FCC:     '/MPG1/MPG2/';
     Name:    'MPV Decoder Filter';
     FileName:'Mpeg2DecFilter.ax';
     CLSID:   '{39F498AF-1A09-4275-B193-673B0BA3D478}'),

    (FCC:     '/MPG1/MPG2/';
     Name:    'Elecard MPEG2 Video Decoder';
     FileName:'mpgdec.ax';
     CLSID:   '{F50B3F13-19C4-11CF-AA9A-02608C9BABA2}'),

    (FCC:     '/MPG1/MPG2/';
     Name:    'Ligos MPEG Video Decoder';
     FileName:'lmpgvd.ax';
     CLSID:   '{CB51EFC2-40D6-11D3-B265-00A0C9A3A56F}'),

    (FCC:     '/MPG2/';
     Name:    'InterVideo Video Decoder';
     FileName:'ivivideo.ax';
     CLSID:   '{0246CA20-776D-11D2-8010-00104B9B8592}';),

    (FCC:     '/RV20/RV30/RV40/RV41/';
     Name:    'RealMediaSplitter';
     FileName:'RealMediaSplitter.ax';
     CLSID:   '{238D0F23-5DC9-45A6-9BE2-666160C324DD}';),

    (FCC:     '/MJPG/DMB1/';
     Name:    'Morgan MJPEG Decompressor';
     FileName:'m3jpegdec.ax';
     CLSID:   '{6988B440-8352-11D3-9BDA-CA86737C7168}';),

    (FCC:     '/AVC1/H264/X264/VSSH/CCV1/';
     Name:    'CoreAVC Video Decoder';
     FileName:'coreavcdecoder.ax';
     CLSID:   '{09571A4B-F1FE-4C60-9760-DE6D310C7C31}';),

    (FCC:     '/VCRD/';
     Name:    'Dirac Video Decoder';
     FileName:'DiracSplitter.ax';
     CLSID:   '{F78CF248-180E-4713-B107-B13F7B5C31E1}';),

    (FCC:     '/TM20/';
     Name:    'TrueMotion 2.0 Decompressor';
     FileName:'tm20dec.ax';
     CLSID:   '{4CB63E61-C611-11D0-83AA-000092900184}';),

    (FCC:     '/ROQV/';
     Name:    'RoQ Video Decoder';
     FileName:'RoQSplitter.ax';
     CLSID:   '{FBEFC5EC-ABA0-4E6C-ACA3-D05FDFEFB853}';),

    (FCC:     '/VP60/VP61/VP62/';
     Name:    'VP6 Decompressor';
     FileName:'vp6dec.ax';
     CLSID:   '{01CFC007-C263-420A-80DC-2988DA4C6105}';),

    (FCC:     '/VP70/VP71/';
     Name:    'VP7 Decompressor';
     FileName:'vp7dec.ax';
     CLSID:   '{C204438D-6E1A-4309-B09C-0C0F749863AF}';),

    (FCC:     '/AVC1/WVC1/XVID/FLV1/FLV4/DIVX/DIV3/DIV4/DX50/DIV6/H264/H263/CCV1'+'/MP43/MP42/MP41/MP4V/MP4S/SEDG/SMP4/MPG2/WMV1/WMV2/WMV3/WVC1/VP50/VP60/VP61/VP62/VP6F/HFYU/3IV2/3IVX/MPG1/MPG2/MPEG/EM2V/MMES/VP31/TSCC/CRAM/AVRN/FPS1/WMVP/WVP2/MJPG/MJPA/AMVV/SP5X/DVSD/DV25/DV50/CDVC/CDV5/DVIS/PDVC/YV12/IYUV/YUY2/UYVY/JPEG/CAVS/';
     Name:    'ffdshow Video Decoder';
     FileName:'ffdshow.ax';
     CLSID:   '{04FE9017-F873-410E-871E-AB91661A4EF7}';),

    (FCC:     '/H264/X264/AVC1/CCV1/MPG1/MPG2/MJPG/WVC1/WMVA/WMV1/WMV2/WMV3/VP80'+'/XVID/DIVX/DX50/MP4V/M4S2/MP4S/FMP4/MPG4/MP41/DIV1/MP42/DIV2/MP43/DIV3/MPG3/DIV4/DIV5/DIV6/DVX3/FLV1/VP60/VP61/VP62/VP6A/VP6F/RV10/RV20/RV30/RV40/DVSD/CDVH/DV25/DV50/DVCP/SVQ1/SVQ3/H261/H263/S263/THEO/TSCC/IV50/IV31/IV32/FPS1/HFYU/LAGS/CVID/VP30/VP31'+'/CSCD/QPEG/MSZH/ZLIB/BIKI/BIKB/SMK2/SMK4/CRAM/';
     Name:    'LAV Video Decoder';
     FileName:'LAVVideo.ax';
     CLSID:   '{EE30215D-164F-4A92-A4EB-9D4C13390F9F}';),

    (FCC:     '/FLV1/FLV4/VP6F/VP50/VP60/VP61/VP62/VP6A/VP80/XVID/XVIX/DX50/DIVX'+'/WMV1/WMV2/WMV3/MPEG2/DIV3/DVX3/DIV4/DIV5/DIV6/MP43/COL1/AP41/MPG3/DIV2/MP42/MPG4/DIV1/MP41/AMVV/H264/X264/VSSH/DAVC/PAVC/AVC1/SVQ3/SVQ1/H263/S263/RV10/RV20/RV30/RV40/THEO/WVC1/MP4V/M4S2/MP4S/SEDG/SMP4/3IV1/3IV2/3IVX/BLZ0/DM4V/FFDS/FVFW/DXGM/FMP4/HDX4'+'/LMP4/';
     Name:    'MPC - Video decoder';
     FileName:'MPCVideoDec.ax';
     CLSID:   '{008BAC12-FBAF-497B-9670-BC6F6FBAE2C4}';),

    (FCC:     '/MPG2/';
     Name:    'MPEG Video Decoder';
     FileName:'quartz.dll';
     CLSID:   '{FEB50740-7BEF-11CE-9BD9-0000E202599C}';),     

    (FCC:     '/MPG1/MPG2/DVSD/H264/X264/AVC1/WMV3/WMVA/WVC1/XVID/DIVX/DX50/MP4V/FLV1/S263/';
     Name:    'ArcSoft Video Decoder';
     FileName:'asvid.ax';
     CLSID:   '{B793E9A8-C53E-4845-9DE9-C32326EACCAD}';),

    (FCC:     '/MJPG/';
     Name:    'MJPEG Decompressor';
     FileName:'quartz.dll';
     CLSID:   '{301056D0-6DFF-11D2-9EEB-006008039E37}';),

    (FCC:     '/XVID/';
     Name:    'XviD Decoder';
     FileName:'XviD.ax';
     CLSID:   '{64697678-0000-0010-8000-00AA00389B71}';)
  );

  // Audio Renderers //
  AudioRenderers: TAudioRenderers = (
    (Name:    'MPC AudioRenderer';
     FileName:'MpcAudioRendererFilter.ax';
     CLSID:   '{601D2A2B-9CDE-40BD-8650-0485E3522727}';),

    (Name:    'DC CrossFade Renderer';
     FileName:'DCCrossRenderer.ax';
     CLSID:   '{C70BD94C-ABB7-409B-B95A-EC0285FF3D8C}';)
  );

  // Video Renderers //
  VideoRenderers: TVideoRenderers = (
    (Name:    'Default Renderer';
     FileName:'quartz.dll';
     CLSID:   '{6BC1CFFA-8FC1-4261-AC22-CFB4CC38DB50}'),

    (Name:    'Video Renderer';
     FileName:'quartz.dll';
     CLSID:   '{70E102B0-5556-11CE-97C0-00AA0055595A}'),

    (Name:    'Video Mixing Renderer 7';
     FileName:'quartz.dll';
     CLSID:   '{B87BEB7B-8D29-423F-AE4D-6582C10175AC}'),

    (Name:    'Video Mixing Renderer 9';
     FileName:'quartz.dll';
     CLSID:   '{51b4abf3-748f-4e3b-a276-c828330e926a}'),

    (Name:    'Enhanced Video Renderer';
     FileName:'evr.dll';
     CLSID:   '{FA10746C-9B63-4B6C-BC49-FC300EA5F256}'),

    (Name:    'Haali Video Renderer';
     FileName:'dxr.dll';
     CLSID:   '{760A8F35-97E7-479D-AAF5-DA9EFF95D751}'),

    (Name:    'Mad VR';
     FileName:'madVR.ax';
     CLSID:   '{E1A8B82A-32CE-4B0D-BE0D-AA68C772E423}')
  );

  // Advanced Filters //
  AdvancedFilters: TAdvancedFilters = (
    (FCC:     '/SUBS/';
     Name:    'DirectVobSub (auto load)';
     FileName:'vsfilter.dll';
     CLSID:   '{93A22E7A-5091-45EF-BA61-6DA26156A5D0}';),

    (FCC:     '/SUBS/';
     Name:    'DirectVobSub';
     FileName:'vsfilter.dll';
     CLSID:   '{9852A670-F845-491B-9BE6-EBD841B8A613}';)
  );

implementation

end.
