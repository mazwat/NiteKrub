Shader "Custom/OnlyShadowsAndAtten"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        // Forward rendering base (main directional light) pass.
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // Want regular shader variants for ForwardBase pass, but don't care about
            // lightmaps, dynamic GI etc. Just shadows/no-shadows
            #pragma multi_compile_fwdbase nolightmap nodynlightmap novertexlight
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                SHADOW_COORDS(0) // shadow parameters to pass from vertex
            };

            v2f vert (appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos (v.vertex);
                TRANSFER_SHADOW(o); // pass shadow coordinates to pixel shader
                return o;
            }

            fixed4 frag (v2f IN) : SV_Target
            {
                // will put attenuation+shadows into "atten" variable
                // world position not needed in directional lights case, pass zero
                UNITY_LIGHT_ATTENUATION(atten, IN, 0)
                fixed4 c = atten;

                // might want to take light color into account?
                // otherwise with no directional light at all, for example, everything will be lit
                // (since ForwardBase will still be rendered, just with black light color)
                c.rgb *= _LightColor0.rgb;
                return c;
            }

            ENDCG

        }

        // Forward additive pass (only needed if you care about more lights than 1 directional).
        // Can remove if no point/spot light support needed.
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardAdd" }
            ZWrite Off Blend One One

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // Include shadowing support for point/spot
            #pragma multi_compile_fwdadd_fullshadows
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                SHADOW_COORDS(1)
            };

            v2f vert (appdata_full v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos (v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                TRANSFER_SHADOW(o); // pass shadow coordinates to pixel shader
                return o;
            }

            fixed4 frag (v2f IN) : SV_Target
            {
                UNITY_LIGHT_ATTENUATION(atten, IN, IN.worldPos)
                fixed4 c = atten;
                // might want to take light color into account?
                c.rgb *= _LightColor0.rgb;
                return c;
            }

            ENDCG
        }

        // Support for casting shadows from this shader. Remove if not needed.
        UsePass "VertexLit/SHADOWCASTER"
    }
}