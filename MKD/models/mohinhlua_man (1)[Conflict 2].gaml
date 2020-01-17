/**
* Name: mohinhluaman
* Author: Truong Chi Quang, Huynh Quang Nghi
* Description: Describe here the model and its experiments
* Tags: Tag1, Tag2, TagN
*/
model mohinhluaman


global
{
/** Insert the global definitions, variables and actions here */
//	file lua_file <- grid_file("../includes/lua2014_asc.asc");
	file lua_file <- shape_file("../includes/bandolua_2014.shp");
	//	file lua_file_nb <- shape_file("../includes/bandolua_2014_nb.shp");
	file river_file <- shape_file("../includes/SONG_TN106_region.shp");
	//	file diked_file <- shape_file("../includes/vungngapman_region.shp");
	file vungthuyloi_file <- shape_file("../includes/vungngapman_region.shp");
	map<int, string> legend_map <- [2::"Lúa 2 vụ", 3::"Lúa-màu"];
	map<int, rgb> legend_color <- [2::# yellow, 3::# green, 0::# white];
	map<int, rgb> color_man <- [0::# white, 4::# yellow, 8::# yellowgreen, 15::# lightcoral];
	geometry shape <- envelope(vungthuyloi_file);
	float step <- 1 # week;
	date starting_date <- date([2016, 1, 1, 0, 0, 0]);
	bool rain_season <- false update: current_date.month >= 6 and current_date.month < 11;
	river the_main_river;
	list<cell_lua> parcels_not_diked update: cell_lua where (not each.diked);
	list<int> idx <- [346, 347, 348, 349, 350, 351, 352, 353, 354, 355, 356, 357, 358];
	init
	{
		create vungngapman from: vungthuyloi_file with: [cao2016::int(read("cao2016")), thuongnien::int(read("thuongnien"))]
		{
		//			write cao2016;
		}

		create cell_lua from: lua_file with: [loaidat201::string(read("loaidat201")), code::int(read("code"))]
		{
		//			write loaidat201;
			if (code = 2)
			{
				do die;
			}

		}

		ask cell_lua
		{
			neighborhood <- cell_lua at_distance (10);
		}

		//		save cell_lua type: shp to: "../includes/bandolua_2014_nb.shp" rewrite: true
		//		attributes:["loaidat201"::loaidat201 , "code"::code, "neighbors"::neighborhood] ;
		ask vungngapman
		{
			list<cell_lua> ss <- cell_lua where (each.shape intersects self.shape);
			ask ss
			{
				current_salinity <- float(myself.thuongnien);
				priority_salt <- current_salinity;
			}

		}
		//		create vungngapman from:diked_file;
		create river from: river_file;
		the_main_river <- river at 356;
		the_main_river.is_main_river <- true;
		loop i over: idx
		{
			river[i].diked <- false;
		}

	}

	reflex salinity_diffusion
	{
		ask river
		{
			do diffusion;
		}

		ask river
		{
			do apply_diffusion;
		}

		if ((river at 72).river_salt_level > 20)
		{
		//			write (river at 72).river_salt_level;
			ask river where ((each.diked))
			{
				do salt_intrusion;
			}

			ask parcels_not_diked
			{
				do diffusion;
			}

			ask parcels_not_diked
			{
				do update_salinity;
			}

		}

	}

	reflex salt_intrusion
	{
		if (not rain_season)
		{
			the_main_river.river_salt_level <- 30.0;
			the_main_river.river_salt_level_tmp <- 30.0;
		} else
		{
			if (the_main_river.river_salt_level > 3)
			{
				the_main_river.river_salt_level <- the_main_river.river_salt_level - 1;
				the_main_river.river_salt_level_tmp <- the_main_river.river_salt_level - 1;
			}

		}

	}

	reflex end_simulation when: current_date.year = 2016 and current_date.month = 12 and current_date.day >= 23
	{
		do pause;
	}

}

species river
{
	rgb color <- # blue;
	string type;
	bool diked <- true;
	list<cell_lua> contactParcel <- cell_lua at_distance 100; // overlapping (self);
	list<cell_lua> availableParcel -> { contactParcel where (not each.diked) };
	list neighborhood <- river overlapping (self);
	list availableNeighbours -> { self.neighborhood where (not each.diked) };
	float river_salt_level <- 0.0;
	float river_salt_level_tmp <- 0.0;
	bool is_main_river <- false;
	action diffusion
	{
		if (is_main_river = false)
		{
			ask (availableNeighbours)
			{
				myself.river_salt_level_tmp <- myself.river_salt_level_tmp + river_salt_level;
			}

		}

	}

	action apply_diffusion
	{
		river_salt_level <- river_salt_level_tmp;
		if (river_salt_level > 30)
		{
			river_salt_level <- 30.0;
		}

		river_salt_level_tmp <- 0.0;
	}

	action salt_intrusion
	{
		ask (availableParcel)
		{
			current_salinity_tmp <- current_salinity_tmp + myself.river_salt_level;
		}

	}

	aspect default
	{
	//		draw shape color: rgb(rnd(255), rnd(255), rnd(255)); // border: color;
		draw shape color: hsb(0.6 - 0.1 * (30 - min([1.0, (max([0.0, river_salt_level - 2])) / 30])), 1.0, 1.0);

		//		draw shape color: hsb(0.4 - 0.4 * (min([1.0, (max([0.0, self.river_salt_level - 2])) / 30])), 1.0, 1.0) border:#black;

	}

}

species vungngapman
{
	rgb color <- # red;
	int thuongnien <- 0;
	int cao2016 <- 0;
	aspect cao2016
	{
		draw shape color: hsb(0.6 - 0.1 * (30 - min([1.0, (max([0.0, cao2016 - 2])) / 30])), 1.0, 1.0);
	}

	aspect thuongnien
	{
		draw shape color: hsb(0.6 - 0.1 * (30 - min([1.0, (max([0.0, thuongnien - 2])) / 30])), 1.0, 1.0);
	}

}

//species vungthuyloi
//{
//	rgb color <- # red;
//	aspect default
//	{
//		draw shape color: color border: # white;
//	}
//
//}
species canals
{
	rgb color <- # blue;
	aspect default
	{
		draw shape color: color border: color;
	}

}

species cell_lua
{
	string loaidat201 <- "";
	int code <- 0;
	//	float salt_level <- 0.0;
	float priority_salt <- 0.0;
	float current_salinity max: 30.0;
	float current_salinity_tmp;
	bool diked <- false;
	bool disableByDrain <- false;
	list<cell_lua> neighborhood;
	list<cell_lua> availableNeighbors -> { [] + self + self.neighborhood where (not each.diked) };
	action diffusion
	{
		current_salinity_tmp <- current_salinity_tmp + min([30, mean((availableNeighbors) collect (each.current_salinity))]);
	}

	action update_salinity
	{
		current_salinity <- (priority_salt / 10) + current_salinity_tmp;
		current_salinity_tmp <- 0.0;
	}

	reflex doing
	{
		if (code = 3)
		{
			if (current_salinity > 20)
			{
				if (flip(0.1))
				{
					code <- 0;
				}

			}

		}

	}

	aspect default
	{
		draw shape color: legend_color[code] border: legend_color[code] - 50;
	}

	aspect thuongnien
	{
		draw shape color: hsb(0.6 - 0.1 * (30 - min([1.0, (max([0.0, current_salinity - 2])) / 30])), 1.0, 1.0);
	}

}
//grid cell_lua file: lua_file use_individual_shapes: false use_regular_agents: false neighbors: 8{
//	init{
//		if(grid_value=0){
//			do die;
//		}
//	}
//	int landuse<- int(grid_value);
//	rgb color <- legend_color[int(grid_value)];
//}
experiment mohinhluaman type: gui
{
/** Insert here the definition of the input and output of the model */
	output
	{
		display "Hien trang lua 2016" //type: opengl

		{
			overlay position: { 5, 5 } size: { 300 # px, (40) # px } background: # black transparency: 0.5 border: # black rounded: true
			{
				draw "Date: " + current_date.day + " - " + current_date.month + " - " + current_date.year at: { 20 # px, 30 # px } color: # white font: font("SansSerif", 24, # bold);
			}

			//			species vungngapman aspect: thuongnien;
			species river aspect: default;
			species cell_lua aspect: default;
		}

		display "Hien trang ngap man" //type: opengl

		{
			overlay position: { 5, 5 } size: { 300 # px, (40) # px } background: # black transparency: 0.5 border: # black rounded: true
			{
				draw "Date: " + current_date.day + " - " + current_date.month + " - " + current_date.year at: { 20 # px, 30 # px } color: # white font: font("SansSerif", 24, # bold);
			}

			species vungngapman aspect: cao2016 transparency: 0.78;
			//			species vungngapman aspect: thuongnien;
			species river aspect: default;
			species cell_lua aspect: thuongnien;
		}

	}

}
