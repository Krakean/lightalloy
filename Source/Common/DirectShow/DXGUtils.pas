// Contains code of D3DUtil.cpp (DX7 Framework) & Direct3D.pas (DX7 Header)
// Put together by Ludwig Hähne (whiskex@gmx.net)

unit DXGUtils;

interface

uses
  Windows, DirectXGraphics;

///////////////////////////////////////////////////////////////////////////////
// Vector Operations
///////////////////////////////////////////////////////////

function D3DVector(x, y, z: Single): TD3DVector;
// Addition and subtraction
function VectorAdd(const v1, v2: TD3DVector) : TD3DVector;
function VectorSub(const v1, v2: TD3DVector) : TD3DVector;
// Scalar multiplication and division
function VectorMulS(const v: TD3DVector; s: Single) : TD3DVector;
function VectorDivS(const v: TD3DVector; s: Single) : TD3DVector;
// Memberwise multiplication and division
function VectorMul(const v1, v2: TD3DVector) : TD3DVector;
function VectorDiv(const v1, v2: TD3DVector) : TD3DVector;
// Vector dominance
function VectorSmaller(v1, v2: TD3DVector) : boolean;
function VectorSmallerEquel(v1, v2: TD3DVector) : boolean;
// Bitwise equality
function VectorEquel(v1, v2: TD3DVector) : boolean;
// Length-related functions
function VectorSquareMagnitude(v: TD3DVector) : Single;
function VectorMagnitude(v: TD3DVector) : Single;
// Returns vector with same direction and unit length
function VectorNormalize(const v: TD3DVector) : TD3DVector;
// Return min/max component of the input vector
function VectorMin(v: TD3DVector) : Single;
function VectorMax(v: TD3DVector) : Single;
// Return memberwise min/max of input vectors
function VectorMinimize(const v1, v2: TD3DVector) : TD3DVector;
function VectorMaximize(const v1, v2: TD3DVector) : TD3DVector;
// Dot and cross product
function VectorDotProduct(v1, v2: TD3DVector) : Single;
function VectorCrossProduct(const v1, v2: TD3DVector) : TD3DVector;

///////////////////////////////////////////////////////////////////////////////
// Matrix Operations
///////////////////////////////////////////////////////////

function MatrixMul(const a, b: TD3DMatrix) : TD3DMatrix;
procedure MatrixAppend(var a: TD3DMatrix; const b: TD3DMatrix);
function MatrixVectorMul(const vec: TD3DVector; const mat: TD3DMatrix): TD3DVector;
function MatrixInvert(var q: TD3DMatrix; const a: TD3DMatrix): HResult;

///////////////////////////////////////////////////////////////////////////////
// Matrix Transformations
///////////////////////////////////////////////////////////

function SetViewMatrix(var MatrixView: TD3DMatrix; From, At, Worldup: TD3DVector): HResult;
function SetProjectionMatrix(var mat: TD3DMatrix; fFOV, fAspect, fNearPlane, fFarPlane: Single): HResult;
procedure SetIdentityMatrix(var mat: TD3DMatrix);
procedure SetTranslateMatrix(var mat: TD3DMatrix; tx, ty, tz: Single); overload;
procedure SetTranslateMatrix(var mat: TD3DMatrix; vec: TD3DVector); overload;
procedure SetScaleMatrix(var mat: TD3DMatrix; sx, sy, sz: Single); overload;
procedure SetScaleMatrix(var mat: TD3DMatrix; vec: TD3DVector); overload;
procedure SetRotateXMatrix(var mat: TD3DMatrix; fRads: Single);
procedure SetRotateYMatrix(var mat: TD3DMatrix; fRads: Single);
procedure SetRotateZMatrix(var mat: TD3DMatrix; fRads: Single);
procedure SetRotationMatrix(var mat: TD3DMatrix; vDir: TD3DVector; fRads: Single);

///////////////////////////////////////////////////////////////////////////////
// Misc Operations
///////////////////////////////////////////////////////////

function InitMaterial( r, g, b, a : Single ): TD3DMaterial8;
function InitDirectionalLight( Direction: TD3DVector; r, g, b, Range: Single ): TD3DLight8;


const
  IdentityMatrix : TD3DMatrix = (
    _11: 1; _12: 0; _13: 0; _14: 0;
    _21: 0; _22: 1; _23: 0; _24: 0;
    _31: 0; _32: 0; _33: 1; _34: 0;
    _41: 0; _42: 0; _43: 0; _44: 1 );
  ZeroMatrix : TD3DMatrix = (
    _11: 0; _12: 0; _13: 0; _14: 0;
    _21: 0; _22: 0; _23: 0; _24: 0;
    _31: 0; _32: 0; _33: 0; _34: 0;
    _41: 0; _42: 0; _43: 0; _44: 0 );
  PIover180 = PI / 180;

implementation

function D3DVector(x, y, z: Single): TD3DVector;
begin
  Result.x := x;
  Result.y := y;
  Result.z := z;
end;

function VectorAdd(const v1, v2: TD3DVector) : TD3DVector;
begin
  result.x := v1.x+v2.x;
  result.y := v1.y+v2.y;
  result.z := v1.z+v2.z;
end;

function VectorSub(const v1, v2: TD3DVector) : TD3DVector;
begin
  result.x := v1.x-v2.x;
  result.y := v1.y-v2.y;
  result.z := v1.z-v2.z;
end;

function VectorMulS(const v: TD3DVector; s: Single) : TD3DVector;
begin
  result.x := v.x*s;
  result.y := v.y*s;
  result.z := v.z*s;
end;

function VectorDivS(const v: TD3DVector; s: Single) : TD3DVector;
begin
  result.x := v.x/s;
  result.y := v.y/s;
  result.z := v.z/s;
end;

function VectorMul(const v1, v2: TD3DVector) : TD3DVector;
begin
  result.x := v1.x*v2.x;
  result.y := v1.y*v2.y;
  result.z := v1.z*v2.z;
end;

function VectorDiv(const v1, v2: TD3DVector) : TD3DVector;
begin
  result.x := v1.x/v2.x;
  result.y := v1.y/v2.y;
  result.z := v1.z/v2.z;
end;

function VectorSmaller(v1, v2: TD3DVector) : boolean;
begin
  result := (v1.x < v2.x) and (v1.y < v2.y) and (v1.z < v2.z);
end;

function VectorSmallerEquel(v1, v2: TD3DVector) : boolean;
begin
  result := (v1.x <= v2.x) and (v1.y <= v2.y) and (v1.z <= v2.z);
end;

function VectorEquel(v1, v2: TD3DVector) : boolean;
begin
  result := (v1.x = v2.x) and (v1.y = v2.y) and (v1.z = v2.z);
end;

function VectorSquareMagnitude(v: TD3DVector) : Single;
begin
  result := (v.x*v.x) + (v.y*v.y) + (v.z*v.z);
end;

function VectorMagnitude(v: TD3DVector) : Single;
begin
  result := sqrt((v.x*v.x) + (v.y*v.y) + (v.z*v.z));
end;

function VectorNormalize(const v: TD3DVector) : TD3DVector;
begin
  result := VectorDivS(v,VectorMagnitude(v));
end;

function VectorMin(v: TD3DVector) : Single;
var
  ret : Single;
begin
  ret := v.x;
  if (v.y < ret) then ret := v.y;
  if (v.z < ret) then ret := v.z;
  result := ret;
end;

function VectorMax(v: TD3DVector) : Single;
var
  ret : Single;
begin
  ret := v.x;
  if (ret < v.y) then ret := v.y;
  if (ret < v.z) then ret := v.z;
  result := ret;
end;

function VectorMinimize(const v1, v2: TD3DVector) : TD3DVector;
begin
  if v1.x < v2.x then result.x := v1.x else result.x := v2.x;
  if v1.y < v2.y then result.y := v1.y else result.y := v2.y;
  if v1.z < v2.z then result.z := v1.z else result.z := v2.z;
end;

function VectorMaximize(const v1, v2: TD3DVector) : TD3DVector;
begin
  if v1.x > v2.x then result.x := v1.x else result.x := v2.x;
  if v1.y > v2.y then result.y := v1.y else result.y := v2.y;
  if v1.z > v2.z then result.z := v1.z else result.z := v2.z;
end;

function VectorDotProduct(v1, v2: TD3DVector) : Single;
begin
  result := (v1.x*v2.x) + (v1.y * v2.y) + (v1.z*v2.z);
end;

function VectorCrossProduct(const v1, v2: TD3DVector) : TD3DVector;
begin
  result.x := (v1.y*v2.z) - (v1.z*v2.y);
  result.y := (v1.z*v2.x) - (v1.x*v2.z);
  result.z := (v1.x*v2.y) - (v1.y*v2.x);
end;

function MatrixMul(const a, b: TD3DMatrix) : TD3DMatrix;
var
  i,j,k : Integer;
begin
  Result := ZeroMatrix;
  for i := 0 to 3 do
    for j := 0 to 3 do
      for k := 0 to 3 do
        Result.m[i,j] := Result.m[i,j] + (a.m[k,j] * b.m[i,k]);
end;

procedure MatrixAppend(var a: TD3DMatrix; const b: TD3DMatrix);
var
  i,j,k : Integer;
  mat: TD3DMatrix;
begin
  mat := ZeroMatrix;
  for i := 0 to 3 do
    for j := 0 to 3 do
      for k := 0 to 3 do
        mat.m[i,j] := mat.m[i,j] + (a.m[k,j] * b.m[i,k]);
  a := mat;
end;

function MatrixVectorMul(const vec: TD3DVector; const mat: TD3DMatrix): TD3DVector;
begin
  Result.x := mat._11*vec.x + mat._12*vec.y + mat._13*vec.z + mat._14;
  Result.y := mat._21*vec.x + mat._22*vec.y + mat._23*vec.z + mat._24;
  Result.z := mat._31*vec.x + mat._32*vec.y + mat._33*vec.z + mat._34;
end;

function MatrixInvert(var q: TD3DMatrix; const a: TD3DMatrix): HResult;
var
  DetInv: Single;
begin
  Result := E_INVALIDARG;
  if (abs(a._44 - 1) > 0.001) or
     (abs(a._14) > 0.001) or
     (abs(a._24) > 0.001) or
     (abs(a._34) > 0.001) then Exit;
  DetInv := 1 /( a._11 * ( a._22 * a._33 - a._23 * a._32 ) -
                 a._12 * ( a._21 * a._33 - a._23 * a._31 ) +
                 a._13 * ( a._21 * a._32 - a._22 * a._31 ) );

  q._11 :=  DetInv * ( a._22 * a._33 - a._23 * a._32 );
  q._12 := -DetInv * ( a._12 * a._33 - a._13 * a._32 );
  q._13 :=  DetInv * ( a._12 * a._23 - a._13 * a._22 );
  q._14 := 0;

  q._21 := -DetInv * ( a._21 * a._33 - a._23 * a._31 );
  q._22 :=  DetInv * ( a._11 * a._33 - a._13 * a._31 );
  q._23 := -DetInv * ( a._11 * a._23 - a._13 * a._21 );
  q._24 := 0;

  q._31 :=  DetInv * ( a._21 * a._32 - a._22 * a._31 );
  q._32 := -DetInv * ( a._11 * a._32 - a._12 * a._31 );
  q._33 :=  DetInv * ( a._11 * a._22 - a._12 * a._21 );
  q._34 := 0;

  q._41 := -( a._41 * q._11 + a._42 * q._21 + a._43 * q._31 );
  q._42 := -( a._41 * q._12 + a._42 * q._22 + a._43 * q._32 );
  q._43 := -( a._41 * q._13 + a._42 * q._23 + a._43 * q._33 );
  q._44 := 1;

  Result := S_OK;
end;

function SetViewMatrix(var MatrixView: TD3DMatrix; From, At, Worldup: TD3DVector): HResult;
var
  View: TD3DVector;
  Length: Single;
  DotProduct: Single;
  Up: TD3DVector;
  Right: TD3DVector;
begin
  // Get the z basis vector, which points straight ahead. This is the
  // difference from the eyepoint to the lookat point.
  View := VectorSub(At,From);
  Length := VectorMagnitude(View);
  if (Length < 1e-6) then
  begin
    Result := E_INVALIDARG;
    Exit;
  end;
  // Normalize the z basis vector
  View := VectorDivS(View,Length);
  // Get the dot product, and calculate the projection of the z basis
  // vector onto the up vector. The projection is the y basis vector.
  DotProduct := VectorDotProduct(WorldUp,View);
  Up := VectorSub(WorldUp,VectorMulS(View,DotProduct));
  // If this vector has near-zero length because the input specified a
  // bogus up vector, let's try a default up vector
  Length := VectorMagnitude(Up);
  if (Length < 1e-6) then
  begin
    Up := VectorSub(D3DVector(0,1,0),VectorMulS(View,View.y));
    // If we still have near-zero length, resort to a different axis.
    Length := VectorMagnitude(Up);
    if (Length < 1e-6) then
    begin
      Up := VectorSub(D3DVector(0,0,1),VectorMulS(View,View.z));
      Length := VectorMagnitude(Up);
      if (Length < 1e-6) then
      begin
        Result := E_INVALIDARG;
        Exit;
      end;
    end;
  end;
  // Normalize the y basis vector
  Up := VectorDivS(Up,Length);
  // The x basis vector is found simply with the cross product of the y
  // and z basis vectors
  Right := VectorCrossProduct(Up,View);
  // Start building the matrix. The first three rows contains the basis
  // vectors used to rotate the view to point at the lookat point
  MatrixView._11 := Right.x;  MatrixView._12 := Up.x;  MatrixView._13 := View.x;  MatrixView._14 := 0;
  MatrixView._21 := Right.y;  MatrixView._22 := Up.y;  MatrixView._23 := View.y;  MatrixView._24 := 0;
  MatrixView._31 := Right.z;  MatrixView._32 := Up.z;  MatrixView._33 := View.z;  MatrixView._34 := 0;
  // Do the translation values (rotations are still about the eyepoint)
  MatrixView._41 := - VectorDotProduct(From,Right );
  MatrixView._42 := - VectorDotProduct(From,Up );
  MatrixView._43 := - VectorDotProduct(From,View );
  MatrixView._44 := 1;
  Result := S_OK;
end;

function SetProjectionMatrix(var mat: TD3DMatrix; fFOV, fAspect, fNearPlane, fFarPlane: Single): HResult;
var
  w, h, q: Single;
begin
  if (abs(fFarPlane-fNearPlane) < 0.01) or (abs(sin(fFOV/2)) < 0.01) then
  begin
    Result := E_INVALIDARG;
    Exit;
  end;
  h := (cos(fFOV/2)/sin(fFOV/2));
  w := fAspect * h;
  Q := fFarPlane / (fFarPlane - fNearPlane);
  ZeroMemory(@mat, SizeOf(mat));
  mat._11 := w;
  mat._22 := h;
  mat._33 := Q;
  mat._34 := 1.0;
  mat._43 := -Q*fNearPlane;
  Result := S_OK;
end;

procedure SetIdentityMatrix(var mat: TD3DMatrix);
begin
  mat := IdentityMatrix;
end;

procedure SetTranslateMatrix(var mat: TD3DMatrix; tx, ty, tz: Single); overload;
begin
  mat := IdentityMatrix;
  mat._41 := tx;
  mat._42 := ty;
  mat._43 := tz;
end;

procedure SetTranslateMatrix(var mat: TD3DMatrix; vec: TD3DVector); overload;
begin
  mat := IdentityMatrix;
  mat._41 := vec.x;
  mat._42 := vec.y;
  mat._43 := vec.z;
end;

procedure SetScaleMatrix(var mat: TD3DMatrix; sx, sy, sz: Single); overload;
begin
  mat := IdentityMatrix;
  mat._11 := sx;
  mat._22 := sy;
  mat._33 := sz;
end;

procedure SetScaleMatrix(var mat: TD3DMatrix; vec: TD3DVector); overload;
begin
  mat := IdentityMatrix;
  mat._11 := vec.x;
  mat._22 := vec.y;
  mat._33 := vec.z;
end;

procedure SetRotateXMatrix(var mat: TD3DMatrix; fRads: Single);
begin
  mat := IdentityMatrix;
  mat._22 :=  cos( fRads );
  mat._23 :=  sin( fRads );
  mat._32 := -sin( fRads );
  mat._33 :=  cos( fRads );
end;

procedure SetRotateYMatrix(var mat: TD3DMatrix; fRads: Single);
begin
  mat := IdentityMatrix;
  mat._11 :=  cos( fRads );
  mat._13 := -sin( fRads );
  mat._31 :=  sin( fRads );
  mat._33 :=  cos( fRads );
end;

procedure SetRotateZMatrix(var mat: TD3DMatrix; fRads: Single);
begin
  mat := IdentityMatrix;
  mat._11 :=  cos( fRads );
  mat._12 :=  sin( fRads );
  mat._21 := -sin( fRads );
  mat._22 :=  cos( fRads );
end;

procedure SetRotationMatrix(var mat: TD3DMATRIX; vDir: TD3DVECTOR; fRads: Single);
var
  fCos, fSin : Single;
  v          : TD3DVector;
begin
  fCos := cos( fRads );
  fSin := sin( fRads );
  v := VectorNormalize(vDir);
  mat := ZeroMatrix;
  mat._11 := ( v.x * v.x ) * ( 1.0 - fCos ) + fCos;
  mat._12 := ( v.x * v.y ) * ( 1.0 - fCos ) - (v.z * fSin);
  mat._13 := ( v.x * v.z ) * ( 1.0 - fCos ) + (v.y * fSin);

  mat._21 := ( v.y * v.x ) * ( 1.0 - fCos ) + (v.z * fSin);
  mat._22 := ( v.y * v.y ) * ( 1.0 - fCos ) + fCos ;
  mat._23 := ( v.y * v.z ) * ( 1.0 - fCos ) - (v.x * fSin);

  mat._31 := ( v.z * v.x ) * ( 1.0 - fCos ) - (v.y * fSin);
  mat._32 := ( v.z * v.y ) * ( 1.0 - fCos ) + (v.x * fSin);
  mat._33 := ( v.z * v.z ) * ( 1.0 - fCos ) + fCos;

  mat._44 := 1.0;
end;

function InitMaterial( r, g, b, a: Single ): TD3DMaterial8;
begin
  ZeroMemory( @Result , SizeOf(Result) );
  // Set Diffuse Color
  Result.Diffuse.r := r;
  Result.Diffuse.g := g;
  Result.Diffuse.b := b;
  Result.Diffuse.a := a;
  // Use the same color components for the Ambient one
  Result.Ambient := Result.Diffuse;
end;

function InitDirectionalLight( Direction: TD3DVector; r, g, b, Range: Single ): TD3DLight8;
begin
  ZeroMemory( @Result , SizeOf(Result) );
  Result._Type := D3DLIGHT_DIRECTIONAL;
  Result.Diffuse.r := r;
  Result.Diffuse.g := g;
  Result.Diffuse.b := b;
  Result.Direction := VectorNormalize(Direction);
  Result.Range := Range;
end;

end.
