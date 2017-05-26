#define STARS

#ifdef STARS
	vec3 getStars(vec3 color, vec3 fpos, float land){
		if (land < 0.9) {
			vec4 fposition = normalize(vec4(fpos,0.0));
			vec3 tPos = getWorldSpace(fposition).rgb;
			vec3 wVec = normalize(tPos);
			
			const float moonAngularDiameterCos = 0.99833194915;

			float cosViewSunAngle = dot(normalize(fposition.rgb), moonVec);
			float moondisk = smoothstep(moonAngularDiameterCos,moonAngularDiameterCos+0.001,cosViewSunAngle);

			float cosT = max(dot(fposition.rgb,upVec),0.0);

			vec3 starCoord = wVec*(50.0/(wVec.y));
			vec2 coord = (starCoord.xz)/256.0 + 0.1;

				float noise = texture2D(noisetex,fract(coord.xy/2.0)).x;
				noise += texture2D(noisetex,fract(coord.xy)).x/2.0;

			float star = max(noise- 1.3,0.0);

			return mix(color, vec3(3.0),star * cosT * time[1].y * (1.0 - rainStrength) * (1.0 - moondisk));
		} else {
			return color;
		}
	}
#endif