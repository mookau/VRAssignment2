// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "UI/CustomAnimated"
{
    Properties
    {
        [PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)

        _StencilComp("Stencil Comparison", Float) = 8
        _Stencil("Stencil ID", Float) = 0
        _StencilOp("Stencil Operation", Float) = 0
        _StencilWriteMask("Stencil Write Mask", Float) = 255
        _StencilReadMask("Stencil Read Mask", Float) = 255

        _ColorMask("Color Mask", Float) = 15

        [Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
    }

        SubShader
        {
            Tags
            {
                "Queue" = "Transparent"
                "IgnoreProjector" = "True"
                "RenderType" = "Transparent"
                "PreviewType" = "Plane"
                "CanUseSpriteAtlas" = "True"
            }

            Stencil
            {
                Ref[_Stencil]
                Comp[_StencilComp]
                Pass[_StencilOp]
                ReadMask[_StencilReadMask]
                WriteMask[_StencilWriteMask]
            }

            Cull Off
            Lighting Off
            ZWrite Off
            ZTest[unity_GUIZTestMode]
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask[_ColorMask]

            Pass
            {
                Name "Default"
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma target 2.0

                #include "UnityCG.cginc"
                #include "UnityUI.cginc"

                #pragma multi_compile_local _ UNITY_UI_CLIP_RECT
                #pragma multi_compile_local _ UNITY_UI_ALPHACLIP

                struct appdata_t
                {
                    float4 vertex   : POSITION;
                    float4 color    : COLOR;
                    float2 texcoord : TEXCOORD0;
                    uint vid : SV_VertexID; //added
                    UNITY_VERTEX_INPUT_INSTANCE_ID
                };

                struct v2f
                {
                    float4 vertex   : SV_POSITION;
                    fixed4 color : COLOR;
                    float2 texcoord  : TEXCOORD0;
                    float4 worldPosition : TEXCOORD1;
                    UNITY_VERTEX_OUTPUT_STEREO
                };

                float _AnimateVerts[16]; //added
                float3 _TrackedPosition;

                sampler2D _MainTex;
                fixed4 _Color;
                fixed4 _TextureSampleAdd;
                float4 _ClipRect;
                float4 _MainTex_ST;

                v2f vert(appdata_t v)
                {
                    v2f OUT;
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
                    OUT.worldPosition = v.vertex;
                    OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

                    OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);

                    OUT.color = v.color * _Color;

                    // Check this vertex against all valid animation data to see if this vertex should be animated.
                    for (uint av = 0; av < _AnimateVerts.Length - 1; av += 2)
                    {
                        if (_AnimateVerts[av] < 0 || _AnimateVerts[av + 1] <= 0) // -1 is used to indicate the end of valid data. Also, no valid end index could possibly be 0, though a start index could.
                            break;
                        if (v.vid >= _AnimateVerts[av] && v.vid <= _AnimateVerts[av + 1])
                        {                            
                            //Default wave animation from shader tutorial
                            //OUT.vertex.y += 2 * (cos(OUT.worldPosition.x / 4 * 80 + _Time * -120) / 80); // Vertical wave. The exact values used are arbitrary; tinker with them to suit your needs.                            
                            
                            //Wobble based on time
                            /*
                            
                            OUT.vertex.y -= sin(_Time * 140) / 100;
                            OUT.vertex.x += sin(_Time * 150) / 100;
                            
                            */
                            
                            
                            //Wobble based on tracked position                            
                            /*
                            
                            OUT.vertex.y -= sin(_TrackedPosition.y) / 20;
                            OUT.vertex.x += sin(_TrackedPosition.x) / 20;

                            */

                            //Random Colour based on depth of tracker, just for testing
                            /*

                            //float t = (_Time + v.vid / 4 * 2.0) * 100; // Rainbow timing. The values are also arbitrary. This uses v.vid so each character is entirely one color.
                            float t = _TrackedPosition.z;

                            float r = cos(t) * 0.5 + 0.5; // 0 * pi
                            float g = cos(t + 2.094395) * 0.5 + 0.5; // 2/3 * pi
                            float b = cos(t + 4.188790) * 0.5 + 0.5; // 4/3 * pi
                            OUT.color.rgba = float4(r, g, b, 1);
                            
                            */
                        }
                    }
                    return OUT;
                }

                fixed4 frag(v2f IN) : SV_Target
                {
                    half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;



                    #ifdef UNITY_UI_CLIP_RECT
                    color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
                    #endif

                    #ifdef UNITY_UI_ALPHACLIP
                    clip(color.a - 0.001);
                    #endif

                    return color;
                }
            ENDCG
            }
        }
}