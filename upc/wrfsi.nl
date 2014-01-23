/
&filetimespec
  START_YEAR           = @YYYY_START@
  START_MONTH          = @MONTH_START@
  START_DAY            = @DAY_START@
  START_HOUR           = @HOUR_START@
  START_MINUTE         = 00
  START_SECOND         = 00
  END_YEAR             = @YYYY_STOP@
  END_MONTH            = @MONTH_STOP@
  END_DAY              = @DAY_STOP@
  END_HOUR             = @HOUR_STOP@
  END_MINUTE           = 00
  END_SECOND           = 00
  INTERVAL             = 10800
/
&hgridspec
  XDIM                 = 101
  YDIM                 = 155
  DOMAIN_ORIGIN_URI    = 101
  DOMAIN_ORIGIN_URJ    = 155
  MAP_PROJ_NAME        = 'rotlat'
  MOAD_KNOWN_LAT       = @CLAT@
  MOAD_KNOWN_LON       = @CLON@
  MOAD_STAND_LATS      = @CLAT@, @CLAT@ 
  MOAD_STAND_LONS      = @CLON@
  MOAD_DELTA_X         = 6000
  MOAD_DELTA_Y         = 6000
/
&sfcfiles
  TOPO_30S             = '/machine/gempak/wrf/data/geog/topo_30s'
  LANDUSE_30S          = '/machine/gempak/wrf/data/geog/landuse_30s'
  SOILTYPE_TOP_30S     = '/machine/gempak/wrf/data/geog/soiltype_top_30s'
  SOILTYPE_BOT_30S     = '/machine/gempak/wrf/data/geog/soiltype_bot_30s'
  GREENFRAC            = '/machine/gempak/wrf/data/geog/greenfrac'
  SOILTEMP_1DEG        = '/machine/gempak/wrf/data/geog/soiltemp_1deg'
  ALBEDO_NCEP          = '/machine/gempak/wrf/data/geog/albedo_ncep'
  MAXSNOWALB           = '/machine/gempak/wrf/data/geog/maxsnowalb'
  ISLOPE               = '/machine/gempak/wrf/data/geog/islope'
/
&interp_control
  OUTPUT_COORD = 'NMMH'
  LEVELS = 1.000000, 0.993000, 0.980000, 0.966000, 0.950000, 
	0.933000, 0.913000, 0.892000, 0.869000, 0.844000, 
	0.816000, 0.786000, 0.753000, 0.718000, 0.680000, 
	0.639000, 0.596000, 0.550000, 0.501000, 0.451000, 
	0.398000, 0.345000, 0.290000, 0.236000, 0.188000, 
	0.145000, 0.108000, 0.075000, 0.046000, 0.021000, 
	0.000000
/
