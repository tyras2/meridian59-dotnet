uniform sampler2D RT : register(s0);

struct VOut
{
	float4 p	: POSITION;
	float2 uv	: TEXCOORD0;
};

VOut Compositor_vs(
	float4 iPosition : POSITION,
	float2 iUV0 : TEXCOORD0,
	uniform float4x4 cWorldViewProj)
{
	VOut OUT;

    OUT.p = mul(cWorldViewProj, iPosition);
    OUT.uv = iUV0;
	
	return OUT;
}

// examplecompositor
float4 BlackAndWhite_ps(float2 iTexCoord : TEXCOORD0) : COLOR
{
    float3 greyscale = dot(tex2D(RT, iTexCoord).rgb, float3(0.3, 0.59, 0.11));
	return float4(greyscale, 1.0);
}

// blendcompositor (used by blind, whiteout, pain and others)
float4 Blend_ps(
	VOut vsout,
	uniform float4 blendcolor) : COLOR0
{
	// get pixelcolor
	const float4 color = tex2D(RT, vsout.uv);

	// get the weight of the base-color
	const float oneminusa = 1.0 - blendcolor.a;
	
	// apply the weights on base and blend color
	// and combine them
	const float4 blend = blendcolor.a * blendcolor;
	const float4 base  = oneminusa * color;
	const float4 comb  = blend + base;

	return comb;
}

// invert compositor
float4 Invert_ps(float2 iTexCoord : TEXCOORD0) : COLOR
{
	// get pixelcolor and inverted color
	float3 color = tex2D(RT, iTexCoord).rgb;
	
    return float4(
		1.0 - color.r, 
		1.0 - color.g, 
		1.0 - color.b, 
		1.0);
}

// Blur stuff
static const float samples[10] =
{
-0.08,
-0.05,
-0.03,
-0.02,
-0.01,
0.01,
0.02,
0.03,
0.05,
0.08
};

float4 Blur_ps(float4 Pos : POSITION,
            float2 texCoord: TEXCOORD0,
            uniform float sampleDist,
            uniform float sampleStrength
           ) : COLOR
{
   //Vector from pixel to the center of the screen
   float2 dir = 0.5 - texCoord;

   //Distance from pixel to the center (distant pixels have stronger effect)
   //float dist = distance( float2( 0.5, 0.5 ), texCoord );
   float dist = sqrt( dir.x*dir.x + dir.y*dir.y );


   //Now that we have dist, we can normlize vector
   dir = normalize( dir );

   //Save the color to be used later
   float4 color = tex2D( RT, texCoord );
   //Average the pixels going along the vector
   float4 sum = color;
   for (int i = 0; i < 10; i++)
   {
      float4 res=tex2D( RT, texCoord + dir * samples[i] * sampleDist );
      sum += res;
   }
   sum /= 11;

   //Calculate amount of blur based on
   //distance and a strength parameter
   float t = dist * sampleStrength;
   t = saturate( t );//We need 0 <= t <= 1

   //Blend the original color with the averaged pixels
   return lerp( color, sum, t );
}
