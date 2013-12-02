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

unit FourCC;

// -----------------------------------------------------------------------------

interface

function FFourCCDesc(FourCC: String): String;
function VFourCCDesc(FourCC: String): String;
function AFourCCDesc(Tag:WORD): String;

// -----------------------------------------------------------------------------

implementation

uses SysUtils;

function FFourCCDesc;
begin
  if FourCC = 'AAC'  then Result := 'Advanced Audio Coding' else
  if FourCC = 'AC3'  then Result := 'Dolby AC3 Sound' else
  if FourCC = 'AIFC' then Result := 'Apple Audio' else
  if FourCC = 'AIFF' then Result := 'Apple Audio' else
  if FourCC = 'APE'  then Result := 'Monkey’s Audio' else
  if FourCC = 'ASF'  then Result := 'Advanced Streaming Format' else
  if FourCC = 'AT3'  then Result := 'Adaptive Transform Acoustic Coding' else
  if FourCC = 'AU'   then Result := 'Sun Audio' else
  if FourCC = 'AVI'  then Result := 'Audio-Video Interleaved' else
  if FourCC = 'BDMV' then Result := 'Blu-ray Information File' else
  if FourCC = 'CDA'  then Result := 'CD Audio' else
  if FourCC = 'CDXA' then Result := 'CD Video' else
  if FourCC = 'FLAC' then Result := 'Free Lossless Audio Codec' else
  if FourCC = 'FLIC' then Result := 'Autodesk Animator format' else
  if FourCC = 'FLV'  then Result := 'Flash Video' else
  if FourCC = 'IFO'  then Result := 'DVD Index File' else
  if FourCC = 'IT'   then Result := 'Impulse Tracker Module' else
  if FourCC = 'MIDI' then Result := 'Musical Interface Digital Instruments' else
  if FourCC = 'MKV'  then Result := 'Matroska' else
  if FourCC = 'MOD'  then Result := 'Tracker Module' else
  if FourCC = 'MP3'  then Result := 'Audio MPEG1 Layer-3' else
  if FourCC = 'MP4'  then Result := 'MPEG-4' else
  if FourCC = 'MPC'  then Result := 'Musepack' else
  if FourCC = 'MPG1' then Result := 'Moving Picture Experts Group' else
  if FourCC = 'MPG2' then Result := 'Moving Picture Experts Group' else
  if FourCC = 'MPLS' then Result := 'Blu-ray Movie Playlist File' else
  if FourCC = 'MTS'  then Result := 'MPEG transport stream' else
  if FourCC = 'OGG'  then Result := 'Ogg Audio' else
  if FourCC = 'OGM'  then Result := 'Ogg Media' else
  if FourCC = 'QT'   then Result := 'Quick Time Movie' else
  if FourCC = 'RLMD' then Result := 'RealMedia' else
  if FourCC = 'S3M'  then Result := 'Scream Tracker Module' else
  if FourCC = 'TS'   then Result := 'MPEG Transport Stream' else
  if FourCC = 'WAV'  then Result := 'Windows Wave PCM Audio' else
  if FourCC = 'WEBM' then Result := 'WebM Container' else
  if FourCC = 'WVPK'  then Result := 'WavePack Audio' else
  if FourCC = 'XM'   then Result := 'Fast Tracker Moduleelse' else
    Result := 'n/a';
end;

function VFourCCDesc;
begin
  FourCC := UpperCase(FourCC);
  if FourCC = '1978' then Result := 'A.M.Paredes predictor (LossLess)' else
  if FourCC = '2VUY' then Result := 'Optibase VideoPump 8-bit 4:2:2 Component' else
  if FourCC = '3IV0' then Result := '3ivx MPEG4-based codec' else
  if FourCC = '3IV1' then Result := '3ivx MPEG4-based codec' else
  if FourCC = '3IV2' then Result := '3ivx MPEG4-based codec' else
  if FourCC = '3IVD' then Result := '3ivx MPEG4-based codec DivX Doctored' else
  if FourCC = '3IVX' then Result := '3ivx MPEG4-based codec' else
  if FourCC = '8BPS' then Result := 'Planar RGB w/alpha' else
  if FourCC = 'AAS4' then Result := 'Autodesk Animator codec (RLE)' else
  if FourCC = 'AASC' then Result := 'Autodesk Animator codec' else
  if FourCC = 'ABYR' then Result := 'Kensington codec' else
  if FourCC = 'ACTL' then Result := 'Streambox ACT-L2' else
  if FourCC = 'ADV1' then Result := 'Loronix WaveCodec (used in various CCTV products)' else
  if FourCC = 'ADVJ' then Result := 'Avid M-JPEG Avid Technology Also known as AVRn' else
  if FourCC = 'AEIK' then Result := 'Intel Indeo Video 3.2 (Vector Quantization)' else
  if FourCC = 'AEMI' then Result := 'Array VideoONE MPEG1-I Capture' else
  if FourCC = 'AFLC' then Result := 'Autodesk Animator codec' else
  if FourCC = 'AFLI' then Result := 'Autodesk Animator codec' else
  if FourCC = 'AHDV' then Result := 'CineForm 10-bit Visually Perfect HD (Wavelet)' else
  if FourCC = 'AJPG' then Result := '22fps JPEG-based codec for digital cameras' else
  if FourCC = 'AMPG' then Result := 'Array VideoONE MPEG' else
  if FourCC = 'ANIM' then Result := 'Intel RDX' else
  if FourCC = 'AP41' then Result := 'AngelPotion Definitive (hack MS MP43)' else
  if FourCC = 'AP42' then Result := 'AngelPotion Definitive (hack MS MP43)' else
  if FourCC = 'ASLC' then Result := 'AlparySoft Lossless Codec' else
  if FourCC = 'ASV1' then Result := 'Asus Video V1' else
  if FourCC = 'ASV2' then Result := 'Asus Video V2' else
  if FourCC = 'ASVX' then Result := 'Asus Video 2.0' else
  if FourCC = 'ATM4' then Result := 'Ahead Nero Digital MPEG-4 Codec' else
  if FourCC = 'AUR2' then Result := 'Aura 2 Codec - YUV 422' else
  if FourCC = 'AURA' then Result := 'Aura 1 Codec - YUV 411' else
  if FourCC = 'AV1X' then Result := 'Avid 1:1x (Quick Time)' else
  if FourCC = 'AVC1' then Result := 'H.264/MPEG-4 AVC' else
  if FourCC = 'AVD1' then Result := 'Avid DV (Quick Time)' else
  if FourCC = 'AVDJ' then Result := 'Avid Meridien JFIF with Alpha-channel' else
  if FourCC = 'AVDN' then Result := 'Avid DNxHD (Quick Time)' else
  if FourCC = 'AVDV' then Result := 'Avid DV' else
  if FourCC = 'AVI1' then Result := 'MainConcept Motion JPEG Codec' else
  if FourCC = 'AVI2' then Result := 'MainConcept Motion JPEG Codec' else
  if FourCC = 'AVID' then Result := 'Avid Motion JPEG' else
  if FourCC = 'AVIS' then Result := 'Wrapper for AviSynth (Dummy codec)' else
  if FourCC = 'AVMP' then Result := 'Avid IMX (Quick Time)' else
  if FourCC = 'AVR'  then Result := 'Avid ABVB/NuVista MJPEG with Alpha-channel' else
  if FourCC = 'AVRN' then Result := 'Avid Motion JPEG' else
  if FourCC = 'AVUP' then Result := 'Avid 10bit Packed (Quick Time)' else
  if FourCC = 'AYUV' then Result := '4:4:4 YUV' else
  if FourCC = 'AZPR' then Result := 'Quicktime Apple Video' else
  if FourCC = 'AZRP' then Result := 'Quicktime Apple Video' else
  if FourCC = 'BGR'  then Result := 'Uncompressed BGR32 8:8:8:8' else
  if FourCC = 'BGR(15)' then Result := 'Uncompressed BGR15 5:5:5' else
  if FourCC = 'BGR(16)' then Result := 'Uncompressed BGR16 5:6:5' else
  if FourCC = 'BGR(24)' then Result := 'Uncompressed BGR24 8:8:8' else
  if FourCC = 'BHIV' then Result := 'BeHere iVideo' else
  if FourCC = 'BINK' then Result := 'Bink Video (RAD Game Tools)' else
  if FourCC = 'BIT'  then Result := 'BI_BITFIELDS (Raw RGB)' else
  if FourCC = 'BITM' then Result := 'Microsoft H.261' else
  if FourCC = 'BLOX' then Result := 'Jan Jezabek BLOX MPEG Codec' else
  if FourCC = 'BLZ0' then Result := 'DivX for Blizzard Decoder Filter' else
  if FourCC = 'BT20' then Result := 'Conexant ProSummer MediaStream' else
  if FourCC = 'BTCV' then Result := 'Conexant Composite Video' else
  if FourCC = 'BTVC' then Result := 'Conexant Composite Video' else
  if FourCC = 'BW00' then Result := 'BergWave (Wavelet)' else
  if FourCC = 'BW10' then Result := 'Data Translation Broadway MPEG Capture/Compression' else
  if FourCC = 'BXBG' then Result := 'BOXX BGR' else
  if FourCC = 'BXRG' then Result := 'BOXX RGB' else
  if FourCC = 'BXY2' then Result := 'BOXX 10-bit YUV' else
  if FourCC = 'BXYV' then Result := 'BOXX YUV' else
  if FourCC = 'CAVS' then Result := 'Audio Video Standard' else
  if FourCC = 'CC12' then Result := 'YUV12 Codec' else
  if FourCC = 'CDV5' then Result := 'Canopus SD50/DVHD' else
  if FourCC = 'CDVC' then Result := 'Canopus DV Codec' else
  if FourCC = 'CDVH' then Result := 'Canopus SD50/DVHD' else
  if FourCC = 'CFCC' then Result := 'DPS Perception Motion JPEG' else
  if FourCC = 'CFHD' then Result := 'CineForm 10-bit Visually Perfect HD (Wavelet)' else
  if FourCC = 'CGDI' then Result := 'Camcorder Video (MS Office 97)' else
  if FourCC = 'CHAM' then Result := 'WinNow Caviara Champagne' else
  if FourCC = 'CJPG' then Result := 'Creative Video Blaster Webcam Go JPEG' else
  if FourCC = 'CLJR' then Result := 'Cirrus Logic YUV 4:1:1' else
  if FourCC = 'CLLC' then Result := 'Canopus LossLess' else
  if FourCC = 'CLPL' then Result := 'YV12 including a level of indirection' else
  if FourCC = 'CMYK' then Result := 'Common Data Format in Printing' else
  if FourCC = 'COL0' then Result := 'FFmpeg DivX ;-) (MS MPEG-4 v3)' else
  if FourCC = 'COL1' then Result := 'FFmpeg DivX ;-) (MS MPEG-4 v3)' else
  if FourCC = 'CPLA' then Result := 'Weitek YUV 4:2:0 Planar' else
  if FourCC = 'CRAM' then Result := 'Microsoft Video 1' else
  if FourCC = 'CSCD' then Result := 'RenderSoft CamStudio lossless Codec (LZO & GZIP compression)' else
  if FourCC = 'CTRX' then Result := 'Citrix Scalable Video Codec' else
  if FourCC = 'CUVC' then Result := 'Canopus HQ' else
  if FourCC = 'CVID' then Result := 'Cinepak by CTi Vector Quantization' else
  if FourCC = 'CWLT' then Result := 'Microsoft Color WLT DIB' else
  if FourCC = 'CYUV' then Result := 'Creative Labs YUV 4:2:2' else
  if FourCC = 'CYUY' then Result := 'ATI Proprietary YUV compression' else
  if FourCC = 'D261' then Result := 'DEC H.261' else
  if FourCC = 'D263' then Result := 'DEC H.263' else
  if FourCC = 'DAVC' then Result := 'Dicas MPEGable H.264/MPEG-4 AVC base profile codec' else
  if FourCC = 'DC25' then Result := 'MainConcept ProDV Codec' else
  if FourCC = 'DCAP' then Result := 'Pinnacle DV25 Codec' else
  if FourCC = 'DCL1' then Result := 'Data Connection Conferencing Codec' else
  if FourCC = 'DCT0' then Result := 'WniWni Codec' else
  if FourCC = 'DFSC' then Result := 'DebugMode FrameServer VFW Codec' else
  if FourCC = 'DIB'  then Result := 'Uncompressed Full Frames' else
  if FourCC = 'DIV1' then Result := 'FFmpeg-4 V1' else
  if FourCC = 'DIV2' then Result := 'MS MPEG-4 V2' else
  if FourCC = 'DIV3' then Result := 'Low motion DivX MPEG-4' else
  if FourCC = 'DIV4' then Result := 'Fast motion DivX MPEG-4' else
  if FourCC = 'DIV5' then Result := 'DivX MPEG-4' else
  if FourCC = 'DIV6' then Result := 'DivX MPEG-4' else
  if FourCC = 'DIVX' then Result := 'DivX 4.0 and later' else
  if FourCC = 'DM4V' then Result := 'Dicas MPEGable MPEG-4' else
  if FourCC = 'DMB1' then Result := 'Matrox Rainbow Runner hardware compression (Motion JPEG)' else
  if FourCC = 'DMB2' then Result := 'Motion JPEG codec used by Paradigm' else
  if FourCC = 'DMK2' then Result := 'ViewSonic V36 PDA Video' else
  if FourCC = 'DP02' then Result := 'DynaPel MPEG-4' else
  if FourCC = 'DPS0' then Result := 'DPS Reality Motion JPEG' else
  if FourCC = 'DPSC' then Result := 'DPS PAR Motion JPEG' else
  if FourCC = 'DRWX' then Result := 'Pinnacle DV25 Codec' else
  if FourCC = 'DSVD' then Result := 'Microsoft DirectShow DV' else
  if FourCC = 'DTMT' then Result := 'Media-100 Codec' else
  if FourCC = 'DTNT' then Result := 'Media-100 Codec' else
  if FourCC = 'DUCK' then Result := 'True Motion 1.0' else
  if FourCC = 'DV10' then Result := 'BlueFish444 (lossless RGBA, YUV 10-bit)' else
  if FourCC = 'DV25' then Result := 'Matrox DVCPRO codec' else
  if FourCC = 'DV50' then Result := 'Matrox DVCPRO50 codec' else
  if FourCC = 'DVAN' then Result := 'Pinnacle miroVideo DV300 SW only codec' else
  if FourCC = 'DVC'  then Result := 'Apple QuickTime DV (DVCPRO NTSC)' else
  if FourCC = 'DVCP' then Result := 'Apple QuickTime DV (DVCPRO PAL)' else
  if FourCC = 'DVCS' then Result := 'MainConcept DV Codec' else
  if FourCC = 'DVE2' then Result := 'InSoft DVE-2 Videoconferencing Codec' else
  if FourCC = 'DVH1' then Result := 'Pinnacle DVHD100' else
  if FourCC = 'DVHD' then Result := 'DV 1125 lines at 30.00 Hz or 1250 lines at 25.00 Hz' else
  if FourCC = 'DVIS' then Result := 'VSYNC DualMoon Iris DV codec' else
  if FourCC = 'DVL'  then Result := 'Radius SoftDV 16:9 NTSC' else
  if FourCC = 'DVLP' then Result := 'Radius SoftDV 16:9 PAL' else
  if FourCC = 'DVMA' then Result := 'Darim Vision DVMPEG' else
  if FourCC = 'DVOR' then Result := 'BlueFish444 (lossless RGBA, YUV 10-bit)' else
  if FourCC = 'DVPN' then Result := 'Apple QuickTime DV (DV NTSC)' else
  if FourCC = 'DVPP' then Result := 'Apple QuickTime DV (DV PAL)' else
  if FourCC = 'DVR1' then Result := 'TARGA2000 Codec' else
  if FourCC = 'DVRS' then Result := 'VSYNC DualMoon Iris DV codec' else
  if FourCC = 'DVSD' then Result := 'Sony Digital Video (DV) 525 lines at 29.97 Hz or 625 lines at 25.00 Hz' else
  if FourCC = 'DVSL' then Result := 'DV compressed in SD (SDL)' else
  if FourCC = 'DVX1' then Result := 'Lucent DVX1000SP Video Decoder' else
  if FourCC = 'DVX2' then Result := 'Lucent DVX2000S Video Decoder' else
  if FourCC = 'DVX3' then Result := 'Lucent DVX3000S Video Decoder' else
  if FourCC = 'DX50' then Result := 'DivX 5.x / 6.x codec' else
  if FourCC = 'DXGM' then Result := 'Electronic Arts Game Video codec' else
  if FourCC = 'DXSB' then Result := 'DivX Subtitles Codec' else
  if FourCC = 'DXT1' then Result := 'DirectX Compressed Texture (1bit alpha channel)' else
  if FourCC = 'DXT2' then Result := 'DirectX Compressed Texture' else
  if FourCC = 'DXT3' then Result := 'DirectX Compressed Texture (4bit alpha channel)' else
  if FourCC = 'DXT4' then Result := 'DirectX Compressed Texture' else
  if FourCC = 'DXT5' then Result := 'DirectX Compressed Texture (3bit alpha channel with interpolation)' else
  if FourCC = 'DXTC' then Result := 'DirectX Texture Compression' else
  if FourCC = 'DXTN' then Result := 'Microsoft DirectX Compressed Texture (DXTn)' else
  if FourCC = 'EKQ0' then Result := 'Elsa graphics card quick codec' else
  if FourCC = 'ELK0' then Result := 'Elsa graphics card codec' else
  if FourCC = 'EM2V' then Result := 'Etymonix MPEG-2 I-frame' else
  if FourCC = 'EQK0' then Result := 'Elsa graphics card quick codec' else
  if FourCC = 'ESCP' then Result := 'Eidos Technologies Escape codec' else
  if FourCC = 'ETV1' then Result := 'eTreppid Video Codec' else
  if FourCC = 'ETV2' then Result := 'eTreppid Video Codec' else
  if FourCC = 'ETVC' then Result := 'eTreppid Video Codec' else
  if FourCC = 'FFDS' then Result := 'FFDShow Lossless Video' else
  if FourCC = 'FFV1' then Result := 'FFDShow supported' else
  if FourCC = 'FFVH' then Result := 'FFVH codec' else
  if FourCC = 'FLIC' then Result := 'Autodesk FLI/FLC Animation' else
  if FourCC = 'FLJP' then Result := 'D-Vision Field Encoded MJPEG with LSI' else
  if FourCC = 'FLV1' then Result := 'FLV1 codec' else
  if FourCC = 'FMJP' then Result := 'D-Vision fieldbased ISO MJPEG' else
  if FourCC = 'FRLE' then Result := 'SoftLab-NSK Y16 + Alpha RLE' else
  if FourCC = 'FRWA' then Result := 'SoftLab-NSK Vision Forward Motion JPEG with Alpha-channel' else
  if FourCC = 'FRWD' then Result := 'SoftLab-NSK Vision Forward Motion JPEG' else
  if FourCC = 'FRWT' then Result := 'SoftLab-NSK Vision Forward Motion JPEG with Alpha-channel' else
  if FourCC = 'FRWU' then Result := 'SoftLab-NSK Vision Forward Uncompressed' else
  if FourCC = 'FVF1' then Result := 'Iterated Systems Fractal Video Frame' else
  if FourCC = 'FVFW' then Result := 'ff MPEG-4 based on XviD codec' else
  if FourCC = 'GEPJ' then Result := 'White Pine Motion JPEG Codec' else
  if FourCC = 'GJPG' then Result := 'Grand Tech GT891x Codec' else
  if FourCC = 'GLCC' then Result := 'GigaLink AV Capture codec' else
  if FourCC = 'GLZW' then Result := 'Motion LZW by gabest@freemail.hu' else
  if FourCC = 'GPEG' then Result := 'Motion JPEG by gabest@freemail.hu (with floating point)' else
  if FourCC = 'GPJM' then Result := 'Pinnacle ReelTime MJPEG Codec' else
  if FourCC = 'GREY' then Result := 'Apparently a duplicate of Y800' else
  if FourCC = 'GWLT' then Result := 'Microsoft Greyscale WLT DIB' else
  if FourCC = 'H260' then Result := 'Intel ITU H.260' else
  if FourCC = 'H261' then Result := 'Intel ITU H.261' else
  if FourCC = 'H262' then Result := 'H.262' else
  if FourCC = 'H263' then Result := 'H.263' else
  if FourCC = 'H264' then Result := 'H.264/MPEG-4 AVC' else
  if FourCC = 'h264' then Result := 'H.264/MPEG-4 AVC' else
  if FourCC = 'H265' then Result := 'Intel ITU H.265' else
  if FourCC = 'H266' then Result := 'Intel ITU H.266' else
  if FourCC = 'H267' then Result := 'Intel ITU H.267' else
  if FourCC = 'H268' then Result := 'Intel ITU H.268' else
  if FourCC = 'H269' then Result := 'Intel ITU H.263 for POTS-based videoconferencing' else
  if FourCC = 'HD10' then Result := 'BlueFish444 (lossless RGBA, YUV 10-bit)' else
  if FourCC = 'HDX4' then Result := 'Jomigo HDX4' else
  if FourCC = 'HFYU' then Result := 'Huffyuv Lossless Codec' else
  if FourCC = 'HMCR' then Result := 'Rendition Motion Compensation Format' else
  if FourCC = 'HMRR' then Result := 'Rendition Motion Compensation Format' else
  if FourCC = 'I263' then Result := 'Intel ITU H.263' else
  if FourCC = 'I420' then Result := 'Intel Indeo 4 H.263' else
  if FourCC = 'IAN'  then Result := 'Indeo 4 (RDX) Codec' else
  if FourCC = 'ICLB' then Result := 'InSoft CellB Videoconferencing Codec' else
  if FourCC = 'IDM0' then Result := 'IDM Motion Wavelets 2.0' else
  if FourCC = 'IF09' then Result := 'Microsoft H.261' else
  if FourCC = 'IGOR' then Result := 'Power DVD' else
  if FourCC = 'IJPG' then Result := 'Intergraph JPEG' else
  if FourCC = 'ILVC' then Result := 'Intel Layered Video' else
  if FourCC = 'ILVR' then Result := 'ITU H.263+ Codec' else
  if FourCC = 'IMC1' then Result := 'As YV12, except the U and V planes each have the same stride as the Y plane' else
  if FourCC = 'IMC2' then Result := 'Similar to IMC1, except that the U and V lines are interleaved at half stride boundaries' else
  if FourCC = 'IMC3' then Result := 'As IMC1, except that U and V are swapped' else
  if FourCC = 'IMC4' then Result := 'As IMC2, except that U and V are swapped' else
  if FourCC = 'IMJG' then Result := 'Accom SphereOUS MJPEG with Alpha-channel' else
  if FourCC = 'IPDV' then Result := 'Giga AVI DV Codec' else
  if FourCC = 'IPJ2' then Result := 'Image Power JPEG2000' else
  if FourCC = 'IR21' then Result := 'Intel Indeo 2.1' else
  if FourCC = 'IRAW' then Result := 'Intel YUV Uncompressed' else
  if FourCC = 'IUYV' then Result := 'Interlaced version of UYVY (line order 0,2,4 then 1,3,5 etc)' else
  if FourCC = 'IV30' then Result := 'Intel Indeo Video 3' else
  if FourCC = 'IV31' then Result := 'Intel Indeo Video 3.1' else
  if FourCC = 'IV32' then Result := 'Intel Indeo Video 3.2' else
  if FourCC = 'IV33' then Result := 'Intel Indeo Video 3.3' else
  if FourCC = 'IV34' then Result := 'Intel Indeo Video 3.4' else
  if FourCC = 'IV35' then Result := 'Intel Indeo Video 3.5' else
  if FourCC = 'IV36' then Result := 'Intel Indeo Video 3.6' else
  if FourCC = 'IV37' then Result := 'Intel Indeo Video 3.7' else
  if FourCC = 'IV38' then Result := 'Intel Indeo Video 3.8' else
  if FourCC = 'IV39' then Result := 'Intel Indeo Video 3.9' else
  if FourCC = 'IV40' then Result := 'Intel Indeo Video 4.0' else
  if FourCC = 'IV41' then Result := 'Intel Indeo Video 4.1' else
  if FourCC = 'IV42' then Result := 'Intel Indeo Video 4.2' else
  if FourCC = 'IV43' then Result := 'Intel Indeo Video 4.3' else
  if FourCC = 'IV44' then Result := 'Intel Indeo Video 4.4' else
  if FourCC = 'IV45' then Result := 'Intel Indeo Video 4.5' else
  if FourCC = 'IV46' then Result := 'Intel Indeo Video 4.6' else
  if FourCC = 'IV47' then Result := 'Intel Indeo Video 4.7' else
  if FourCC = 'IV48' then Result := 'Intel Indeo Video 4.8' else
  if FourCC = 'IV49' then Result := 'Intel Indeo Video 4.9' else
  if FourCC = 'IV50' then Result := 'Intel Indeo Video 5.0 Wavelet' else
  if FourCC = 'IY41' then Result := 'Interlaced version of Y41P (line order 0,2,4,...,1,3,5...)' else
  if FourCC = 'IYU1' then Result := '12 bit format used in mode 2 of the IEEE 1394 Digital Camera 1.04 spec' else
  if FourCC = 'IYU2' then Result := '24 bit format used in mode 2 of the IEEE 1394 Digital Camera 1.04 spec' else
  if FourCC = 'IYUV' then Result := 'Intel Indeo iYUV 4:2:0' else
  if FourCC = 'JBYR' then Result := 'Kensington Video Codec' else
  if FourCC = 'JFIF' then Result := 'Motion JPEG (FFmpeg)' else
  if FourCC = 'JPEG' then Result := 'Still Image JPEG DIB' else
  if FourCC = 'JPG'  then Result := 'JPEG compressed' else
  if FourCC = 'JPGL' then Result := 'DIVIO JPEG Light for WebCams (Pegasus Lossless JPEG)' else
  if FourCC = 'KMVC' then Result := 'Karl Morton Video Codec' else
  if FourCC = 'KPCD' then Result := 'Kodak Photo CD' else
  if FourCC = 'L261' then Result := 'Lead Technologies H.261' else
  if FourCC = 'L263' then Result := 'Lead Technologies H.263' else
  if FourCC = 'LAGS' then Result := 'Lagarith LossLess' else
  if FourCC = 'LBYR' then Result := 'Creative WebCam codec' else
  if FourCC = 'LCMW' then Result := 'Lead Technologies Motion CMW Codec' else
  if FourCC = 'LCW2' then Result := 'LEADTools MCMW 9Motion Wavelet)' else
  if FourCC = 'LEAD' then Result := 'LEAD Video Codec' else
  if FourCC = 'LGRY' then Result := 'Lead Technologies Grayscale Image' else
  if FourCC = 'LJ2K' then Result := 'LEADTools JPEG2000' else
  if FourCC = 'LJPG' then Result := 'LEAD Motion JPEG Codec' else
  if FourCC = 'LMP2' then Result := 'LEADTools MPEG2' else
  if FourCC = 'LOCO' then Result := 'LOCO Lossless Codec' else
  if FourCC = 'LSCR' then Result := 'LEAD Screen Capture' else
  if FourCC = 'LSVM' then Result := 'Vianet Lighting Strike Vmail (Streaming)' else
  if FourCC = 'LZO1' then Result := 'LZO compressed' else
  if FourCC = 'M261' then Result := 'Microsoft H.261' else
  if FourCC = 'M263' then Result := 'Microsoft H.263' else
  if FourCC = 'M4CC' then Result := 'ESS MPEG4 Divio codec' else
  if FourCC = 'M4S2' then Result := 'Microsoft MPEG-4 (hacked MS MPEG-4)' else
  if FourCC = 'MC12' then Result := 'ATI Motion Compensation Format' else
  if FourCC = 'MC24' then Result := 'MainConcept Motion JPEG Codec' else
  if FourCC = 'MCAM' then Result := 'ATI Motion Compensation Format' else
  if FourCC = 'MCZM' then Result := 'Theory MicroCosm Lossless 64bit RGB with Alpha-channel' else
  if FourCC = 'MDVD' then Result := 'Alex MicroDVD Video (hacked MS MPEG-4)' else
  if FourCC = 'MDVF' then Result := 'Pinnacle DV/DV50/DVHD100' else
  if FourCC = 'MHFY' then Result := 'A.M.Paredes mhuffyYUV' else
  if FourCC = 'MJ2C' then Result := 'Morgan Multimedia JPEG2000 Compression' else
  if FourCC = 'MJPA' then Result := 'Pinnacle ReelTime MJPG hardware codec' else
  if FourCC = 'MJPB' then Result := 'Motion JPEG codec' else
  if FourCC = 'MJPG' then Result := 'Motion JPEG including Huffman Tables' else
  if FourCC = 'MJPX' then Result := 'Pegasus PICVideo Motion JPEG' else
  if FourCC = 'MMES' then Result := 'Matrox MPEG-2 I-frame' else
  if FourCC = 'MNVD' then Result := 'MindBend MindVid LossLess' else
  if FourCC = 'MP2A' then Result := 'Media Excel MPEG-2 Audio' else
  if FourCC = 'MP2T' then Result := 'Media Excel MPEG-2 Transport Stream' else
  if FourCC = 'MP2V' then Result := 'Media Excel MPEG-2 Video' else
  if FourCC = 'MP41' then Result := 'Microsoft MPEG-4 V1 (enhansed H263)' else
  if FourCC = 'MP42' then Result := 'Microsoft MPEG-4 V2' else
  if FourCC = 'MP43' then Result := 'Microsoft MPEG-4 V3' else
  if FourCC = 'MP4A' then Result := 'Media Excel MPEG-4 Audio' else
  if FourCC = 'MP4S' then Result := 'Microsoft MPEG-4 (Windows Media 7.0)' else
  if FourCC = 'MP4T' then Result := 'Media Excel MPEG-4 Transport Stream' else
  if FourCC = 'MP4V' then Result := 'Apple QuickTime MPEG-4 native' else
  if FourCC = 'MPEG' then Result := 'Chromatic MPEG 1 Video I Frame' else
  if FourCC = 'MPG1' then Result := 'MPEG-1' else
  if FourCC = 'MPG2' then Result := 'MPEG-2' else
  if FourCC = 'MPG3' then Result := 'Same as Low motion DivX MPEG-4' else
  if FourCC = 'MPG4' then Result := 'Microsoft MPEG-4 V1' else
  if FourCC = 'MPGI' then Result := 'Sigma Design MPEG-1 I-frame' else
  if FourCC = 'MPNG' then Result := 'Motion PNG codec' else
  if FourCC = 'MRCA' then Result := 'FAST Multimedia MR Codec' else
  if FourCC = 'MRLE' then Result := 'Microsoft Run Length Encoding' else
  if FourCC = 'MSS1' then Result := 'Windows Screen Video' else
  if FourCC = 'MSS2' then Result := 'Windows Media 9' else
  if FourCC = 'MSUC' then Result := 'MSU LossLess' else
  if FourCC = 'MSVC' then Result := 'Microsoft Video 1' else
  if FourCC = 'MSZH' then Result := 'Lossless codec (ZIP compression)' else
  if FourCC = 'MTGA' then Result := 'Motion TGA images (24, 32 bpp)' else
  if FourCC = 'MTX1' then Result := 'Matrox Motion-JPEG codec' else
  if FourCC = 'MTX2' then Result := 'Matrox Motion-JPEG codec' else
  if FourCC = 'MTX3' then Result := 'Matrox Motion-JPEG codec' else
  if FourCC = 'MTX4' then Result := 'Matrox Motion-JPEG codec' else
  if FourCC = 'MTX5' then Result := 'Matrox Motion-JPEG codec' else
  if FourCC = 'MTX6' then Result := 'Matrox Motion-JPEG codec' else
  if FourCC = 'MTX7' then Result := 'Matrox Motion-JPEG codec' else
  if FourCC = 'MTX8' then Result := 'Matrox Motion-JPEG codec' else
  if FourCC = 'MTX9' then Result := 'Matrox Motion-JPEG codec' else
  if FourCC = 'MV12' then Result := 'Motion Pixels Codec (old)' else
  if FourCC = 'MVI1' then Result := 'Motion Pixels MVI' else
  if FourCC = 'MVI2' then Result := 'Motion Pixels MVI' else
  if FourCC = 'MWV1' then Result := 'Aware Motion Wavelets' else
  if FourCC = 'MYUV' then Result := 'Media-100 844/X Uncompressed' else
  if FourCC = 'NAVI' then Result := 'nAVI video codec (hacked MS MPEG-4)' else
  if FourCC = 'NDIG' then Result := 'Ahead Nero Digital MPEG-4 Codec' else
  if FourCC = 'NHVU' then Result := 'NVidia Texture Format (GEForce 3)' else
  if FourCC = 'NO16' then Result := 'Theory None16 64bit uncompressed RAW' else
  if FourCC = 'NT00' then Result := 'NewTek LigtWave HDTV YUV with Alpha-channel' else
  if FourCC = 'NTN1' then Result := 'Nogatech Video Compression 1' else
  if FourCC = 'NTN2' then Result := 'Nogatech Video Compression 2 (GrabBee hardware coder)' else
  if FourCC = 'NUV1' then Result := 'NuppelVideo' else
  if FourCC = 'NV12' then Result := '8-bit Y plane followed by an interleaved U/V plane with 2x2 subsampling' else
  if FourCC = 'NV21' then Result := 'As NV12 with U and V reversed in the interleaved plane' else
  if FourCC = 'NVDS' then Result := 'nVidia Texture Format' else
  if FourCC = 'NVHS' then Result := 'NVidia Texture Format (GEForce 3)' else
  if FourCC = 'NVS0' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'NVS1' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'NVS2' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'NVS3' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'NVS4' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'NVS5' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'NVT0' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'NVT1' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'NVT2' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'NVT3' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'NVT4' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'NVT5' then Result := 'nVidia Texture Compression Format' else
  if FourCC = 'PDVC' then Result := 'Panasonic DV codec' else
  if FourCC = 'PGVV' then Result := 'Radius Video Vision Telecast (adaptive JPEG)' else
  if FourCC = 'PHMO' then Result := 'IBM Photomotion' else
  if FourCC = 'PIM1' then Result := 'Pinnacle DC1000 hardware codec (MPEG compression)' else
  if FourCC = 'PIM2' then Result := 'Pegasus Imaging codec' else
  if FourCC = 'PIMJ' then Result := 'Pegasus Imaging PICvideo Lossless JPEG' else
  if FourCC = 'PIXL' then Result := 'MiroVideo XL (Motion JPEG)' else
  if FourCC = 'PNG'  then Result := 'Apple PNG' else
  if FourCC = 'PNG1' then Result := 'Corecodec.org CorePNG Codec' else
  if FourCC = 'PVEZ' then Result := 'Horizons Technology PowerEZ codec' else
  if FourCC = 'PVMM' then Result := 'PacketVideo Corporation MPEG-4' else
  if FourCC = 'PVW2' then Result := 'Pegasus Imaging Wavelet 2000' else
  if FourCC = 'PVWV' then Result := 'Pegasus Imaging Wavelet 2000' else
  if FourCC = 'PXLT' then Result := 'Apple Pixlet (Wavelet)' else
  if FourCC = 'Q1.0' then Result := 'Q-Team QPEG 1.0 (www.q-team.de)' else
  if FourCC = 'Q1.1' then Result := 'Q-Team QPEG 1.1 (www.q-team.de)' else
  if FourCC = 'QDGX' then Result := 'Apple QuickDraw GX' else
  if FourCC = 'QPEG' then Result := 'Q-Team QPEG 1.1' else
  if FourCC = 'QPEQ' then Result := 'Q-Team QPEG 1.1' else
  if FourCC = 'R210' then Result := 'BlackMagic YUV (Quick Time)' else
  if FourCC = 'R411' then Result := 'Radius DV NTSC YUV' else
  if FourCC = 'R420' then Result := 'Radius DV PAL YUV' else
  if FourCC = 'RAV_' then Result := 'GroupTRON ReferenceAVI codec' else
  if FourCC = 'RAVI' then Result := 'GroupTRON ReferenceAVI codec' else
  if FourCC = 'RAW'  then Result := 'Uncompressed Full Frames' else
  if FourCC = 'RGB'  then Result := 'Uncompressed Full Frames' else
  if FourCC = 'RGB(15)' then Result := 'Uncompressed RGB15 5:5:5' else
  if FourCC = 'RGB(16)' then Result := 'Uncompressed RGB16 5:6:5' else
  if FourCC = 'RGB(24)' then Result := 'Uncompressed RGB24 8:8:8' else
  if FourCC = 'RGB1' then Result := 'Uncompressed RGB332 3:3:2' else
  if FourCC = 'RGBA' then Result := 'Raw RGB with alpha' else
  if FourCC = 'RGBO' then Result := 'Uncompressed RGB555 5:5:5' else
  if FourCC = 'RGBP' then Result := 'Uncompressed RGB565 5:6:5' else
  if FourCC = 'RGBQ' then Result := 'Uncompressed RGB555X 5:5:5 BE' else
  if FourCC = 'RGBR' then Result := 'Uncompressed RGB565X 5:6:5 BE' else
  if FourCC = 'RGBT' then Result := 'Uncompressed RGB with transparency' else
  if FourCC = 'RL4'  then Result := 'RLE 4bpp RGB' else
  if FourCC = 'RL8'  then Result := 'RLE 8bpp RGB' else
  if FourCC = 'RLE'  then Result := 'Raw RGB with arbitrary sample packing within a pixel' else
  if FourCC = 'RLE4' then Result := 'Run length encoded 4bpp RGB image' else
  if FourCC = 'RLE8' then Result := 'Run length encoded 8bpp RGB image' else
  if FourCC = 'RMP4' then Result := 'REALmagic MPEG-4 Video Codec' else
  if FourCC = 'ROQV' then Result := 'Id RoQ File Video Decoder' else
  if FourCC = 'RPZA' then Result := 'Apple Video 16 bit "road pizza"' else
  if FourCC = 'RT21' then Result := 'Intel Real Time Video 2.1' else
  if FourCC = 'RTV0' then Result := 'NewTek VideoToaster' else
  if FourCC = 'RUD0' then Result := 'Rududu video codec' else
  if FourCC = 'RV10' then Result := 'RealVideo 1' else
  if FourCC = 'RV13' then Result := 'RealVideo 1.3' else
  if FourCC = 'RV20' then Result := 'RealVideo G2' else
  if FourCC = 'RV30' then Result := 'RealVideo 3' else
  if FourCC = 'RV40' then Result := 'RealVideo 9/10' else
  if FourCC = 'RVX'  then Result := 'Intel RDX' else
  if FourCC = 'S263' then Result := 'S263 codec' else
  if FourCC = 'S422' then Result := 'VideoCap C210 YUV Codec' else
  if FourCC = 'SAN3' then Result := 'MPEG-4 codec (direct copy of DivX 3.11a)' else
  if FourCC = 'SDCC' then Result := 'Sun Digital Camera Codec' else
  if FourCC = 'SEDG' then Result := 'Samsung MPEG-4 codec' else
  if FourCC = 'SMP4' then Result := 'Samsung MPEG-4 codec' else  
  if FourCC = 'SFMC' then Result := 'Crystal Net SFM (Surface Fitting Method) Codec' else
  if FourCC = 'SHR0' then Result := 'BitJazz SheerVideo (realtime lossless)' else
  if FourCC = 'SHR1' then Result := 'BitJazz SheerVideo (realtime lossless)' else
  if FourCC = 'SHR2' then Result := 'BitJazz SheerVideo (realtime lossless)' else
  if FourCC = 'SHR3' then Result := 'BitJazz SheerVideo (realtime lossless)' else
  if FourCC = 'SHR4' then Result := 'BitJazz SheerVideo (realtime lossless)' else
  if FourCC = 'SHR5' then Result := 'BitJazz SheerVideo (realtime lossless)' else
  if FourCC = 'SHR6' then Result := 'BitJazz SheerVideo (realtime lossless)' else
  if FourCC = 'SHR7' then Result := 'BitJazz SheerVideo (realtime lossless)' else
  if FourCC = 'SJPG' then Result := 'CUseeMe Networks Codec' else
  if FourCC = 'SL25' then Result := 'SoftLab-NSK DVCPRO' else
  if FourCC = 'SL50' then Result := 'SoftLab-NSK DVCPRO50' else
  if FourCC = 'SLDV' then Result := 'SoftLab-NSK Forward DV Draw codec' else
  if FourCC = 'SLIF' then Result := 'SoftLab-NSK MPEG2 I-frames' else
  if FourCC = 'SLMJ' then Result := 'SoftLab-NSK Forward MJPEG' else
  if FourCC = 'SMC'  then Result := 'Apple Graphics (SMC) codec (256 color)' else
  if FourCC = 'SMSC' then Result := 'Radius proprietary codec' else
  if FourCC = 'SMSD' then Result := 'Radius proprietary codec' else
  if FourCC = 'SMSV' then Result := 'WorldConnect Wavelet Streaming Video' else
  if FourCC = 'SNOW' then Result := 'SNOW codec' else
  if FourCC = 'SP40' then Result := 'SunPlus YUV' else
  if FourCC = 'SP44' then Result := 'SunPlus Aiptek MegaCam Codec' else
  if FourCC = 'SP53' then Result := 'SunPlus Aiptek MegaCam Codec' else
  if FourCC = 'SP54' then Result := 'SunPlus Aiptek MegaCam Codec' else
  if FourCC = 'SP55' then Result := 'SunPlus Aiptek MegaCam Codec' else
  if FourCC = 'SP56' then Result := 'SunPlus Aiptek MegaCam Codec' else
  if FourCC = 'SP57' then Result := 'SunPlus Aiptek MegaCam Codec' else
  if FourCC = 'SP58' then Result := 'SunPlus Aiptek MegaCam Codec' else
  if FourCC = 'SPIG' then Result := 'Radius Spigot' else
  if FourCC = 'SPLC' then Result := 'Splash Studios ACM Audio Codec' else
  if FourCC = 'SPRK' then Result := 'Sorenson Spark' else
  if FourCC = 'SQZ2' then Result := 'Microsoft VXTreme Video Codec V2' else
  if FourCC = 'STVA' then Result := 'ST CMOS Imager Data (Bayer)' else
  if FourCC = 'STVB' then Result := 'ST CMOS Imager Data (Nudged Bayer)' else
  if FourCC = 'STVC' then Result := 'ST CMOS Imager Data (Bunched)' else
  if FourCC = 'STVX' then Result := 'ST CMOS Imager Data (Extended)' else
  if FourCC = 'STVY' then Result := 'ST CMOS Imager Data (Extended with Correction Data)' else
  if FourCC = 'SV10' then Result := 'Sorenson Media Video R1' else
  if FourCC = 'SVQ1' then Result := 'Sorenson Video (Apple Quicktime 3)' else
  if FourCC = 'SVQ3' then Result := 'Sorenson Video 3 (Apple Quicktime 5)' else
  if FourCC = 'SWC1' then Result := 'MainConcept Motion JPEG Codec' else
  if FourCC = 'T420' then Result := 'Toshiba YUV 4:2:0' else
  if FourCC = 'TGA'  then Result := 'Apple TGA (with Alpha-channel)' else
  if FourCC = 'THEO' then Result := 'Theora (free, reworked VP3)' else
  if FourCC = 'TIFF' then Result := 'Apple TIFF (with Alpha-channel)' else
  if FourCC = 'TIM2' then Result := 'Pinnacle RAL DVI' else
  if FourCC = 'TLMS' then Result := 'TeraLogic Motion Infraframe Codec A' else
  if FourCC = 'TLST' then Result := 'TeraLogic Motion Infraframe Codec B' else
  if FourCC = 'TM20' then Result := 'Duck TrueMotion 2.0' else
  if FourCC = 'TM2A' then Result := 'Duck TrueMotion Archiver 2.0' else
  if FourCC = 'TM2X' then Result := 'Duck TrueMotion 2X' else
  if FourCC = 'TMIC' then Result := 'TeraLogic Motion Intraframe Codec 2' else
  if FourCC = 'TMOT' then Result := 'TrueMotion Video Compression' else
  if FourCC = 'TR20' then Result := 'Duck TrueMotion RT 2.0' else
  if FourCC = 'TRLE' then Result := 'Akula Alpha Pro Custom AVI (LossLess)' else
  if FourCC = 'TSCC' then Result := 'TechSmith Screen Capture Codec' else
  if FourCC = 'TV10' then Result := 'Tecomac Low-Bit Rate Codec' else
  if FourCC = 'TVJP' then Result := 'TrueVision Field Encoded Motion JPEG (Targa emulation)' else
  if FourCC = 'TVMJ' then Result := 'Truevision TARGA MJPEG Hardware Codec (or Targa emulation)' else
  if FourCC = 'TY0N' then Result := 'Trident Decompression Driver' else
  if FourCC = 'TY2C' then Result := 'Trident Decompression Driver' else
  if FourCC = 'TY2N' then Result := 'Trident Decompression Driver' else
  if FourCC = 'U<Y'  then Result := 'Discreet UC YUV 4:2:2:4 10 bit' else
  if FourCC = 'U<YA' then Result := 'Discreet UC YUV 4:2:2:4 10 bit (with Alpha-channel)' else
  if FourCC = 'U263' then Result := 'UB Video StreamForce H.263' else
  if FourCC = 'UCOD' then Result := 'ClearVideo (fractal compression-based codec)' else
  if FourCC = 'ULTI' then Result := 'IBM Corp. Ultimotion' else
  if FourCC = 'UMP4' then Result := 'UB Video MPEG 4' else
  if FourCC = 'UYNV' then Result := 'A direct copy of UYVY registered by nVidia' else
  if FourCC = 'UYVP' then Result := 'YCbCr 4:2:2 extended precision 10-bits per component in U0Y0V0Y1 order' else
  if FourCC = 'UYVU' then Result := 'SoftLab-NSK Forward YUV codec' else
  if FourCC = 'UYVY' then Result := 'YUV 4:2:2 (Y sample at every pixel, U and V sampled at every second pixel horizontally on each line)' else
  if FourCC = 'V210' then Result := 'Optibase VideoPump 10-bit 4:2:2 Component YCbCr' else
  if FourCC = 'V261' then Result := 'Lucent elemedia VX3000S' else
  if FourCC = 'V422' then Result := 'Vitec Multimedia YUV 4:2:2 as for UYVY' else
  if FourCC = 'V655' then Result := 'Vitec Multimedia 16 bit YUV 4:2:2 (6:5:5) format' else
  if FourCC = 'VBLE' then Result := 'MarcFD VBLE Lossless Codec' else
  if FourCC = 'VCR1' then Result := 'ATI VCR 1.0' else
  if FourCC = 'VCR2' then Result := 'ATI VCR 2.0 (MPEG YV12)' else
  if FourCC = 'VCR3' then Result := 'ATI VCR 3.0' else
  if FourCC = 'VCR4' then Result := 'ATI VCR 4.0' else
  if FourCC = 'VCR5' then Result := 'ATI VCR 5.0' else
  if FourCC = 'VCR6' then Result := 'ATI VCR 6.0' else
  if FourCC = 'VCR7' then Result := 'ATI VCR 7.0' else
  if FourCC = 'VCR8' then Result := 'ATI VCR 8.0' else
  if FourCC = 'VCR9' then Result := 'ATI VCR 9.0' else
  if FourCC = 'VDCT' then Result := 'Video Maker Pro DIB' else
  if FourCC = 'VDOM' then Result := 'VDOnet VDOWave' else
  if FourCC = 'VDOW' then Result := 'VDOLive (H.263)' else
  if FourCC = 'VDST' then Result := 'VirtualDub remote frameclient ICM driver' else
  if FourCC = 'VDTZ' then Result := 'Darim Vision VideoTizer YUV' else
  if FourCC = 'VGPX' then Result := 'Alaris VideoGramPixel Codec' else
  if FourCC = 'VIDM' then Result := 'DivX 5.0 Pro Supported Codec' else
  if FourCC = 'VIDS' then Result := 'Vitec Multimedia YUV 4:2:2 codec' else
  if FourCC = 'VIFP' then Result := 'Virtual Frame API codec' else
  if FourCC = 'VIV1' then Result := 'Vivo H.263' else
  if FourCC = 'VIV2' then Result := 'Vivo H.263' else
  if FourCC = 'VIVO' then Result := 'Vivo H.263' else
  if FourCC = 'VIXL' then Result := 'MiroVideo XL (Motion JPEG)' else
  if FourCC = 'VLV1' then Result := 'VideoLogic codec' else
  if FourCC = 'VP30' then Result := 'On2 VP3' else
  if FourCC = 'VP31' then Result := 'On2 VP3' else
  if FourCC = 'VP40' then Result := 'On2 TrueCast VP4' else
  if FourCC = 'VP50' then Result := 'On2 TrueCast VP5' else
  if FourCC = 'VP60' then Result := 'On2 TrueCast VP6' else
  if FourCC = 'VP61' then Result := 'On2 TrueCast VP6.1' else
  if FourCC = 'VP62' then Result := 'On2 TrueCast VP6.2' else
  if FourCC = 'VP70' then Result := 'On2 TrueMotion VP7' else
  if FourCC = 'VP80' then Result := 'On2 / Google VP8' else
  if FourCC = 'VQC1' then Result := 'Vector-quantised codec 1 (high compression)' else
  if FourCC = 'VQC2' then Result := 'Vector-quantised codec 2 (high robustness against channel errors)' else
  if FourCC = 'VR21' then Result := 'BlackMagic YUV (Quick Time)' else
  if FourCC = 'VSSH' then Result := 'Videosoft H.264 Codec' else
  if FourCC = 'VSSV' then Result := 'Vanguard Software Solutions Video Codec' else
  if FourCC = 'VSSW' then Result := 'Vanguard VSS H.264' else
  if FourCC = 'VTLP' then Result := 'Alaris VideoGramPixel Codec' else
  if FourCC = 'VX1K' then Result := 'Lucent VX1000S Video Codec' else
  if FourCC = 'VX2K' then Result := 'Lucent VX2000S Video Codec' else
  if FourCC = 'VXSP' then Result := 'Lucent VX1000SP Video Codec' else
  if FourCC = 'VYU9' then Result := 'ATI Technologies YUV' else
  if FourCC = 'VYUY' then Result := 'ATI Packed YUV Data' else
  if FourCC = 'WBVC' then Result := 'Winbond W9960 codec' else
  if FourCC = 'WHAM' then Result := 'Microsoft Video 1' else
  if FourCC = 'WINX' then Result := 'Winnov Software Compression' else
  if FourCC = 'WJPG' then Result := 'Winbond JPEG (AverMedia USB devices)' else
  if FourCC = 'WMV1' then Result := 'Windows Media Video V7' else
  if FourCC = 'WMV2' then Result := 'Windows Media Video V8' else
  if FourCC = 'WMV3' then Result := 'Windows Media Video V9' else
  if FourCC = 'WMVA' then Result := 'WMVA codec' else
  if FourCC = 'WMVP' then Result := 'Windows Media Video V9' else
  if FourCC = 'WNIX' then Result := 'WniWni Codec' else
  if FourCC = 'WNV1' then Result := 'WinNow Videum Hardware Compression' else
  if FourCC = 'WNVA' then Result := 'Winnov hw compress' else
  if FourCC = 'WRLE' then Result := 'Apple QuickTime BMP Codec' else
  if FourCC = 'WRPR' then Result := 'VideoTools VideoServer Client Codec (wrapper for AviSynth)' else
  if FourCC = 'WV1F' then Result := 'WV1F codec' else
  if FourCC = 'WVLT' then Result := 'IllusionHope Wavelet 9/7' else
  if FourCC = 'WVP2' then Result := 'WVP2 codec' else
  if FourCC = 'X263' then Result := 'Xirlink H.263' else
  if FourCC = 'X264' then Result := 'x264 GNU GPL H.264/MPEG-4 AVC' else
  if FourCC = 'x264' then Result := 'x264 GNU GPL H.264/MPEG-4 AVC' else
  if FourCC = 'XLV0' then Result := 'NetXL Inc. XL Video Decoder' else
  if FourCC = 'XMPG' then Result := 'XING MPEG (I frame only)' else
  if FourCC = 'XVID' then Result := 'XviD MPEG-4 codec' else
  if FourCC = 'XVIX' then Result := 'Based on XviD MPEG-4 codec' else
  if FourCC = 'XWV0' then Result := 'XiWave Video Codec' else
  if FourCC = 'XWV1' then Result := 'XiWave Video Codec' else
  if FourCC = 'XWV2' then Result := 'XiWave Video Codec' else
  if FourCC = 'XWV3' then Result := 'XiWave Video Codec (Xi-3 Video)' else
  if FourCC = 'XWV4' then Result := 'XiWave Video Codec' else
  if FourCC = 'XWV5' then Result := 'XiWave Video Codec' else
  if FourCC = 'XWV6' then Result := 'XiWave Video Codec' else
  if FourCC = 'XWV7' then Result := 'XiWave Video Codec' else
  if FourCC = 'XWV8' then Result := 'XiWave Video Codec' else
  if FourCC = 'XWV9' then Result := 'XiWave Video Codec' else
  if FourCC = 'XXAN' then Result := 'Origin Video Codec (used in Wing Commander 3 and 4)' else
  if FourCC = 'XYZP' then Result := 'Extended PAL format XYZ palette' else
  if FourCC = 'Y211' then Result := 'Packed YUV format with Y' else
  if FourCC = 'Y216' then Result := 'Pinnacle TARGA CineWave YUV (Quick Time)' else
  if FourCC = 'Y411' then Result := 'YUV 4:1:1 Packed' else
  if FourCC = 'Y41B' then Result := 'YUV 4:1:1 Planar' else
  if FourCC = 'Y41P' then Result := 'Conexant (ex Brooktree) YUV 4:1:1 Raw' else
  if FourCC = 'Y41T' then Result := 'Format as for Y41P' else
  if FourCC = 'Y422' then Result := 'Direct copy of UYVY as used by ADS Technologies Pyro WebCam firewire camera' else
  if FourCC = 'Y42B' then Result := 'YUV 4:2:2 Planar' else
  if FourCC = 'Y42T' then Result := 'Format as for UYVY' else
  if FourCC = 'Y444' then Result := 'IYU2 (iRez Stealth Fire camera)' else
  if FourCC = 'Y8'   then Result := 'Simple grayscale video' else
  if FourCC = 'Y800' then Result := 'Simple grayscale video' else
  if FourCC = 'YC12' then Result := 'Intel YUV12 Codec' else
  if FourCC = 'YMPG' then Result := 'YMPEG Alpha' else
  if FourCC = 'YU12' then Result := 'ATI YV12 4:2:0 Planar' else
  if FourCC = 'YU92' then Result := 'Intel - YUV' else
  if FourCC = 'YUNV' then Result := 'A direct copy of YUY2 registered by nVidia' else
  if FourCC = 'YUV2' then Result := 'Apple Component Video (YUV 4:2:2)' else
  if FourCC = 'YUV8' then Result := 'Winnov Caviar YUV8' else
  if FourCC = 'YUV9' then Result := 'Intel YUV9' else
  if FourCC = 'YUVP' then Result := 'YCbCr 4:2:2 extended precision 10-bits per component in Y0U0Y1V0 order' else
  if FourCC = 'YUY2' then Result := 'YUV 4:2:2 as for UYVY' else
  if FourCC = 'YUYV' then Result := 'Canopus YUV format' else
  if FourCC = 'YV12' then Result := 'ATI YVU12 4:2:0 Planar' else
  if FourCC = 'YV16' then Result := 'Elecard YUV 4:2:2 Planar' else
  if FourCC = 'YV92' then Result := 'Intel Smart Video Recorder YVU9' else
  if FourCC = 'YVU9' then Result := 'Brooktree YVU9 Raw (YVU9 Planar)' else
  if FourCC = 'YVYU' then Result := 'YUV 4:2:2 as for UYVY' else
  if FourCC = 'ZLIB' then Result := 'Lossless codec (ZIP compression)' else
  if FourCC = 'ZPEG' then Result := 'Metheus Video Zipper' else
  if FourCC = 'ZYGO' then Result := 'ZyGo Video Codec' else
    Result := 'Unknown yet';
end;

function AFourCCDesc;
begin
  Result:='Unknown';
  case Tag of
    $0000:Result:='<Unknown>';
    $0001:Result:='Microsoft PCM';
    $0002:Result:='Microsoft ADPCM';
    $0003:Result:='IEEE Float';
    $0004:Result:='Compaq Computer''s VSELP';
    $0005:Result:='IBM CVSD';
    $0006:Result:='Microsoft ALAW';
    $0007:Result:='Microsoft MULAW';
    $0008:Result:='Microsoft DTS';
    $0009:Result:='Microsoft DRM';
    $000A:Result:='WMSpeech';
    $000B:Result:='Windows Media RT Voice';
    $0010:Result:='OKI ADPCM';
    $0011:Result:='Intel DVI ADPCM';
    $0012:Result:='Videologic MediaSpace ADPCM';
    $0013:Result:='Sierra Semiconductor ADPCM';
    $0014:Result:='Antex Electronics G.723 ADPCM';
    $0015:Result:='DSP Solution DIGISTD';
    $0016:Result:='DSP Solution DIGIFIX';
    $0017:Result:='Dialogic OKI ADPCM';
    $0018:Result:='MediaVision ADPCM';
    $0019:Result:='HP CU';
    $001A:Result:='HP DYNAMIC VOICE';
    $0020:Result:='Yamaha ADPCM';
    $0021:Result:='Speech Compression''s Sonarc';
    $0022:Result:='DSP Group True Speech';
    $0023:Result:='Echo Speech EchoSC1';
    $0024:Result:='Audiofile AF36';
    $0025:Result:='APTX';
    $0026:Result:='AudioFile AF10';
    $0027:Result:='Prosody 1612';
    $0028:Result:='Merging Technologies S.A. LRC';
    $0030:Result:='Dolby AC2';
    $0031:Result:='Microsoft GSM 6.10';
    $0032:Result:='MSNAudio';
    $0033:Result:='Antex ADPCME';
    $0034:Result:='Control Resources VQLPC';
    $0035:Result:='DSP Solutions Digireal';
    $0036:Result:='DSP Solutions DigiADPCM';
    $0037:Result:='Control Resources Ltd CR10';
    $0038:Result:='Natural MicroSystems VBXADPCM';
    $0039:Result:='Roland RDAC';
    $003A:Result:='Echo Speech EchoSC3';
    $003B:Result:='Rockwell ADPCM';
    $003C:Result:='Rockwell Digit LK';
    $003D:Result:='Xebec Multimedia Solutions';
    $0040:Result:='Antex Electronics G.721 ADPCM';
    $0041:Result:='Antex Electronics G.728 CELP';
    $0042:Result:='Microsoft MSG723';
    $0043:Result:='IBM AVC ADPCM';
    $0044:Result:='MSG729 Microsoft';
    $0045:Result:='Microsoft MSG726';
    $0050:Result:='Microsoft MPEG-1 layer 1, 2';
    $0052:Result:='InSoft RT24';
    $0053:Result:='InSoft PAC';
    $0055:Result:='MPEG-1 Layer 3';
    $0059:Result:='Lucent G.723';
    $0060:Result:='Cirrus Logic';
    $0061:Result:='ESS Technology ESPCM / Duck DK4 ADPCM';
    $0062:Result:='Voxware file-mode codec / Duck DK3 ADPCM';
    $0063:Result:='Canopus Atrac';
    $0064:Result:='APICOM G.726 ADPCM';
    $0065:Result:='APICOM G.722 ADPCM';
    $0066:Result:='Microsoft DSAT';
    $0067:Result:='Microsoft DSAT Display';
    $0069:Result:='Voxware Byte Aligned';
    $0070:Result:='Voxware AC8';
    $0071:Result:='Voxware AC10';
    $0072:Result:='Voxware AC16';
    $0073:Result:='Voxware AC20';
    $0074:Result:='Voxware MetaVoice';
    $0075:Result:='Voxware MetaSound';
    $0076:Result:='Voxware RT29HW';
    $0077:Result:='Voxware VR12';
    $0078:Result:='Voxware VR18';
    $0079:Result:='Voxware TQ40';
    $007A:Result:='Voxware SC3';
    $007B:Result:='Voxware SC3';
    $0080:Result:='Softsound';
    $0081:Result:='Voxware TQ60';
    $0082:Result:='Microsoft MSRT24 ';
    $0083:Result:='AT&T Labs G.729A';
    $0084:Result:='Motion Pixels MVI MV12';
    $0085:Result:='DataFusion Systems G.726';
    $0086:Result:='DataFusion Systems GSM610';
    $0088:Result:='Iterated Systems ISIAudio';
    $0089:Result:='Onlive';
    $008A:Result:='Multitude FT SX20';
    $008B:Result:='G.721 ADPCM Infocom ITS A/S';
    $008C:Result:='Convedia G729';
    $008D:Result:='Congruency';
    $0091:Result:='Siemens Business Communications SBC24';
    $0092:Result:='Sonic Foundry Dolby AC3 SPDIF';
    $0093:Result:='MediaSonic G.723';
    $0094:Result:='Aculab 8KBPS';
    $0097:Result:='ZyXEL ADPCM';
    $0098:Result:='Philips LPCBB';
    $0099:Result:='Studer Professional Audio AG Packed';
    $00A0:Result:='Malden Electronics PHONYTALK';
    $00A1:Result:='Racal Recorder GSM';
    $00A2:Result:='Racal Recorder G720.a';
    $00A3:Result:='Racal G723.1';
    $00A4:Result:='Racal Tetra ACELP';
    $00B0:Result:='NEC AAC';
    $00FF:Result:='Advanced Audio Codec';
    $0100:Result:='Rhetorex ADPCM';
    $0101:Result:='BeCubed Software IRAT';
    $0102:Result:='ALAW IBM a-law';
    $0103:Result:='ADPCM IBM AVC Adaptive Differential Pulse Code Modulation';
    $0111:Result:='Vivo G.723';
    $0112:Result:='Vivo Siren';
    $0120:Result:='Philips CELP';
    $0121:Result:='Philips GRUNDIG';
    $0123:Result:='Digital G.723';
    $0125:Result:='Sanyo ADPCM';
    $0130:Result:='Sipro Lab Telecom ACELP.net';
    $0131:Result:='Sipro Lab Telecom ACELP.4800';
    $0132:Result:='Sipro Lab Telecom ACELP.8V3';
    $0133:Result:='Sipro Lab Telecom ACELP.G.729';
    $0134:Result:='Sipro Lab Telecom ACELP.G.729A';
    $0135:Result:='Sipro Lab Telecom ACELP.KELVIN';
    $0136:Result:='VoiceAge AMR';
    $0140:Result:='Dictaphone G.726 ADPCM';
    $0141:Result:='CELP68 Dictaphone Corporation';
    $0142:Result:='CELP54 Dictaphone Corporation';
    $0150:Result:='Qualcomm PUREVOICE';
    $0151:Result:='Qualcomm HALFRATE';
    $0155:Result:='Ring Zero Systems TUBGSM';
    $0160:Result:='Windows Media Audio V7 / DivX audio (WMA)';
    $0161:Result:='Windows Media Audio V8 / DivX audio (WMA)';
    $0162:Result:='Windows Media Audio V9 Professional';
    $0163:Result:='Windows Media Audio V9 Lossless';
    $0164:Result:='WMA Pro over S/PDIF';
    $0170:Result:='UNISYS NAP ADPCM';
    $0171:Result:='UNISYS NAP ULAW';
    $0172:Result:='UNISYS NAP ALAW';
    $0173:Result:='UNISYS NAP 16K';
    $0174:Result:='MM SYCOM ACM SYC008';
    $0175:Result:='MM SYCOM ACM SYC701 G726L';
    $0176:Result:='MM SYCOM ACM SYC701 CELP54';
    $0177:Result:='MM SYCOM ACM SYC701 CELP68';
    $0178:Result:='KNOWLEDGE ADVENTURE ADPCM';
    $0180:Result:='MPEG2AAC Fraunhofer IIS';
    $0190:Result:='DTS DS';
    $0200:Result:='Creative Labs ADPCM';
    $0202:Result:='Creative Labs FastSpeech8';
    $0203:Result:='Creative Labs FastSpeech10';
    $0210:Result:='UHER informatic GmbH ADPCM';
    $0215:Result:='Ulead DV Audio';
    $0216:Result:='Ulead DV ACM';
    $0220:Result:='Quarterdeck';
    $0230:Result:='I-link Worldwide ILINK VC';
    $0240:Result:='Aureal Semiconductor RAW SPORT';
    $0241:Result:='ESST AC3 ESS Technology';
    $0250:Result:='Interactive Products HSX';
    $0251:Result:='Interactive Products RPELP';
    $0260:Result:='Consistent Software CS2';
    $0270:Result:='Sony ATRAC3 (SCX, MiniDisk LP2)';
    $0271:Result:='SONY SCY';
    $0272:Result:='SONY ATRAC3';
    $0273:Result:='SONY SPC';
    $0280:Result:='TELUM';
    $0281:Result:='TELUMIA';
    $0285:Result:='Norcom Voice Systems ADPCM';
    $0300:Result:='Fujitsu TOWNS SND';
    $0350:Result:='DEVELOPMENT Micronas Semiconductors';
    $0351:Result:='CELP833 Micronas Semiconductors';
    $0400:Result:='BTV Digital (Booktree)';
    $0401:Result:='Intel Music Coder';
    $0402:Result:='Intel Music Coder';
    $0450:Result:='QDesign Music';
    $0500:Result:='On2 VP7';
    $0501:Result:='On2 VP6';
    $0680:Result:='AT&T Labs VME VMPCM';
    $0681:Result:='AT&T Labs TPC';
    $0700:Result:='YMPEG MPEG1/2';
    $08AE:Result:='Lightwave Lossless';
    $0AAC:Result:='HDX4 AAC Jomigo GmbH';
    $1000:Result:='Olivetti GSM';
    $1001:Result:='Olivetti ADPCM';
    $1002:Result:='Olivetti CELP';
    $1003:Result:='Olivetti SBC';
    $1004:Result:='Olivetti OPR';
    $1100:Result:='Lernout & Hauspie';
    $1101:Result:='Lernout & Hauspie CELP';
    $1102:Result:='Lernout & Hauspie SBC';
    $1103:Result:='Lernout & Hauspie SBC';
    $1104:Result:='Lernout & Hauspie SBC';
    $1400:Result:='Norris Communication';
    $1401:Result:='ISIAudio';
    $1500:Result:='AT&T Labs Soundspace Music Compression';
    $181C:Result:='VoxWare RT24 speech codec';
    $181E:Result:='Lucent elemedia AX24000P Music codec';
    $1971:Result:='SONICFOUNDRY LOSSLESS';
    $1979:Result:='INNINGS ADPCM';
    $1C07:Result:='Lucent SX8300P speech codec';
    $1C0C:Result:='Lucent SX5363S G.723 compliant codec';
    $1F03:Result:='CUseeMe DigiTalk (ex-Rocwell)';
    $1FC4:Result:='NTC ALF2CD ACM';
    $2000:Result:='AC3 DVM';
    $2001:Result:='AC3 DTS';
    $2002:Result:='RealAudio 1 / 2 14.4';
    $2003:Result:='RealAudio 1 / 2 28.8';
    $2004:Result:='RealAudio G2 / 8 Cook (low bitrate)';
    $2005:Result:='RealAudio 3 / 4 / 5 Music (DNET)';
    $2006:Result:='RealAudio 10 AAC (RAAC)';
    $2007:Result:='RealAudio 10 AAC+ (RACP)';
    $3313:Result:='makeAVIS (ffvfw fake AVI sound from AviSynth scripts)';
    $4143:Result:='Divio MPEG-4 AAC audio';
    $4201:Result:='Nokia adaptive multirate';
    $4243:Result:='Divio''s G726';
    $434C:Result:='LEAD Speech';
    $4451:Result:='Qdesign 2';
    $5346:Result:='ADPCM ShockWave';
    $5756:Result:='WavePack Hybrid Lossless Audio codec';
    $6171:Result:='PCM raw';
    $6172:Result:='PCM raw';
    $6173:Result:='Adaptive Multi-Rate';
    $674F:Result:='OGG Vorbis (mode 1)';
    $676F:Result:='OGG Vorbis (mode 1+)';
    $6750:Result:='OGG Vorbis (mode 2)';
    $6770:Result:='OGG Vorbis (mode 2+)';
    $6751:Result:='OGG Vorbis (mode 3)';
    $6771:Result:='OGG Vorbis (mode 3+)';
    $6C75:Result:='ADPCM U-Law';
    $7000:Result:='3COM NBX';
    $706D:Result:='FAAD AAC';
    $7774:Result:='PCM twos';
    $77A1:Result:='True Audio (TTA)';
    $7A21:Result:='GSM-AMR fixed bitrate';
    $7A22:Result:='GSM-AMR variable bitrate';
    $8000:Result:='MPEG-1 Audio Layer I';
    $8001:Result:='MPEG-1 Audio Layer II';
    $8002:Result:='MPEG-1 Audio Layer III';
    $8003:Result:='MPEG-2 Audio';
    $8004:Result:='MPEG-2 Audio Layer I';
    $8005:Result:='MPEG-2 Audio Layer II';
    $8006:Result:='MPEG-2 Audio Layer III';
    $8007:Result:='MPEG-2.5 Audio';
    $8008:Result:='MPEG-2.5 Audio Layer I';
    $8009:Result:='MPEG-2.5 Audio Layer II';
    $8010:Result:='MPEG-2.5 Audio Layer III';
    $8020:Result:='OGG Media File';
    $8030:Result:='Microsoft WAV';
    $8031:Result:='Microsoft WAV (based on MP3)';
    $A005:Result:='Nellymoser';
    $A006:Result:='Nellymoser';
    $A100:Result:='COMVERSEINFOSYS G723 1';
    $A101:Result:='COMVERSEINFOSYS AVQSBC';
    $A102:Result:='COMVERSEINFOSYS OLDSBC';
    $A103:Result:='Symbol Technology''s G729A';
    $A104:Result:='VOICEAGE AMR WB';
    $A105:Result:='Ingenient''s G726';
    $A106:Result:='ISO/MPEG-4 advanced audio Coding AAC';
    $A107:Result:='Encore Software Ltd''s G726';
    $A109:Result:='Speex ACM Codec';
    $DFAC:Result:='DebugMode SonicFoundry Vegas FrameServer ACM Codec';
    $AEEF:Result:='Monkey''s Audio';
    $EACC:Result:='MusePack';
    $F1AC:Result:='Free Lossless Audio Codec (FLAC)';
    $FFFE:Result:='Extensible format';
    $FFFF:Result:='Illegal codec';
  end;
end;

end.
