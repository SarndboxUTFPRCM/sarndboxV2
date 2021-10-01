﻿//  
//  SandboxShaderWind.shader
//
//	Copyright 2021 SensiLab, Monash University <sensilab@monash.edu>
//
//  This file is part of sensilab-ar-sandbox.
//
//  sensilab-ar-sandbox is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
// 
//  sensilab-ar-sandbox is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with sensilab-ar-sandbox.  If not, see <https://www.gnu.org/licenses/>.
//

Shader "Unlit/SandboxShaderProcedural"
{
	Properties
	{
		_HeightTex("Height Texture", 2D) = "white" {}
		_WindColourMap("Wind Colour Map Texture", 2D) = "white" {}
		_WindParticleTex("Wind Particle Texture", 2D) = "white" {}
		_LabelMaskTex("Label Mask Texture", 2D) = "white" {}
		_ContourStride("Contour Stride (mm)", float) = 20
		_ContourWidth("Contour Width", float) = 1
		_MinorContours("Minor Contours", float) = 0
		_MinDepth("Min Depth (mm)", float) = 1000
		_MaxDepth("Max Depth (mm)", float) = 2000
		_WindEnabled("Wind Enabled", int) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv_HeightTex : TEXCOORD0;
				float2 uv_LabelMaskTex : TEXCOORD1;
				float2 uv_WindParticleTex : TEXCOORD2;
				float4 vertex : SV_POSITION;
			};

			#include "SandboxShaderHelper.cginc"

			int _WindEnabled;

			sampler2D _WindColourMap;
			float4 _WindColourMap_ST;

			sampler2D _WindParticleTex;
			float4 _WindParticleTex_ST;

			v2f vert (uint id : SV_VertexID)
			{
				v2f o;
				uint vIndex = GetVertexID(id);

				o.vertex = mul(UNITY_MATRIX_VP, mul(Mat_Object2World, float4(VertexBuffer[vIndex], 1.0f)));
				o.uv_HeightTex = TRANSFORM_TEX(UVBuffer[vIndex], _HeightTex);
				o.uv_LabelMaskTex = TRANSFORM_TEX(UVBuffer[vIndex], _LabelMaskTex);
				o.uv_WindParticleTex = TRANSFORM_TEX(UVBuffer[vIndex], _WindParticleTex);

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				ContourMapFrag contourMapFrag = GetContourMap(i);
				
				int onText = contourMapFrag.onText == 1 || contourMapFrag.onTextMask == 1;
				int drawMajorContourLine = contourMapFrag.onMajorContourLine == 1 && onText == 0;
				int drawMinorContourLine = contourMapFrag.onMinorContourLine == 1 && onText == 0;

				fixed4 finalColor;
				if (_WindEnabled) {
					fixed4 particleTexSample = tex2D(_WindParticleTex, i.uv_WindParticleTex);

					fixed4 colorScaleSample = tex2D(_WindColourMap, contourMapFrag.normalisedHeight);
					fixed4 textColor = (1 - contourMapFrag.textIntensity) * particleTexSample +
						contourMapFrag.textIntensity * colorScaleSample;

					finalColor = drawMajorContourLine == 1 ? colorScaleSample : particleTexSample;
					finalColor = drawMinorContourLine == 1 ? colorScaleSample : finalColor;
					finalColor = contourMapFrag.onText == 1 ? textColor : finalColor;
				}
				else {
					fixed4 colorScaleSample = tex2D(_WindColourMap, contourMapFrag.discreteNormalisedHeight);
					fixed4 textColor = (1 - contourMapFrag.textIntensity) * colorScaleSample +
						contourMapFrag.textIntensity * fixed4(0, 0, 0, 1);

					finalColor = drawMajorContourLine == 1 ? MAJOR_CONTOUR_COLOUR : colorScaleSample;
					finalColor = drawMinorContourLine == 1 ? MINOR_CONTOUR_COLOUR : finalColor;
					finalColor = contourMapFrag.onText == 1 ? textColor : finalColor;
				}

				return finalColor;
			}
			ENDCG
		}
	}
}
