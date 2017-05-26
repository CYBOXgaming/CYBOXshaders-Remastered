	
	#define WAVING_TERRAIN
	#define WAVING_LEAVES_TALLFLOWERS
	#define WAVING_PLANTS
	#define WAVING_VINES
	#define WAVING_COBWEB
	
	#ifdef WAVING_TERRAIN
	
		float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
		
		float underCover = lmcoord.t;
			underCover = clamp(pow(underCover, 15.0) * 2.0,0.0,1.0);
		
		float wavyMult = 1.0 - time[1].y * 0.5;
			wavyMult *= 1.0 + rainStrength;
			
			#ifdef WAVING_LEAVES_TALLFLOWERS
				vec3 waving1 = calcMove(worldpos.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.8,0.0,0.48)) * underCover * wavyMult;
			#endif
			
			#if defined WAVING_VINES || defined WAVING_COBWEB || defined WAVING_PLANTS
				vec3 waving2 = calcMove(worldpos.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(1.0,0.2,1.0), vec3(0.5,0.1,0.5)) * underCover * wavyMult;
			#endif
		
			#ifdef WAVING_LEAVES_TALLFLOWERS
				if ( mc_Entity.x == ENTITY_LEAVES || mc_Entity.x == ENTITY_LEAVES2 || mc_Entity.x == ENTITY_NEWFLOWERS ) 
					{
						position.xyz += waving1;
					}
			#endif
			
			#ifdef WAVING_VINES
				if ( mc_Entity.x == ENTITY_VINES )
					{
						position.xyz += waving2;
					}
			#endif

			#ifdef WAVING_COBWEB
				if ( mc_Entity.x == ENTITY_COBWEB ) 
					{
						position.xyz += waving2 * 0.1;
					}
			#endif

			#ifdef WAVING_PLANTS
				if (istopv > 0.9) {

				if ( mc_Entity.x == ENTITY_TALLGRASS || mc_Entity.x == ENTITY_DANDELION || mc_Entity.x == ENTITY_ROSE || mc_Entity.x == ENTITY_WHEAT || mc_Entity.x == ENTITY_FIRE ||
					 mc_Entity.x == ENTITY_NETHER_WART || mc_Entity.x == ENTITY_DEAD_BUSH || mc_Entity.x == ENTITY_CARROT || mc_Entity.x == ENTITY_POTATO)
					{
						position.xyz += waving2;
					}

				}
			#endif
			
		#endif