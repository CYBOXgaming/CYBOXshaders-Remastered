
	sunlight = vec3(1.0, 0.6, 0.5) * time[0].x, 2.0; //Sunrise colouring
	sunlight = mix(sunlight, vec3(1.0, 1.0, 1.0), sqrt(time[0].y)); //Midday colouring
	sunlight = mix(sunlight, vec3(1.2, 0.6, 0.5), pow(time[1].x, 2.0)); //Sunset colouring
	sunlight = mix(sunlight, vec3(1.0, 0.3, 0.01), time[1].y); //Night colouring
	sunlight = clamp(sunlight, 0.0, 1.0);

	ambientColor = vec3( 0.058, 0.11, 0.42) * time[0].x; //Sunrise ambient
	ambientColor = mix(ambientColor, vec3( 0.058, 0.11, 0.42), time[0].y); //Midday ambient
	ambientColor = mix(ambientColor, vec3( 0.058, 0.11, 0.42), time[1].x); //Sunset ambient
	ambientColor /= ambientColor.b;
	ambientColor = mix(ambientColor, vec3(0.3, 0.4, 0.6) * 0.1, time[1].y); //Night ambient
	ambientColor = clamp(ambientColor, 0.0, 1.0);

	moonlight = vec3(0.3, 0.55, 1.0) * 0.0656;
	moonlight = clamp(moonlight, 0.0, 1.0);

	ambientColor = mix(ambientColor, vec3(dot(ambientColor, vec3(0.3333))), 0.2 * time[1].y);
	moonlight = mix(moonlight, vec3(dot(moonlight, vec3(0.3333))), 0.6 * time[1].y);
