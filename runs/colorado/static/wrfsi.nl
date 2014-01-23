&project_id
  SIMULATION_NAME      = 'My STRC WRF EMS Run'
  USER_DESC            = 'An intelligent and good looking STRC WRF package user'
/
&filetimespec
  START_YEAR           =  2014
  START_MONTH          =  01
  START_DAY            =  17
  START_HOUR           =  12
  START_MINUTE         =  00
  START_SECOND         =  00
  END_YEAR             =  2014
  END_MONTH            =  01
  END_DAY              =  18
  END_HOUR             =  18
  END_MINUTE           =  00
  END_SECOND           =  00
  INTERVAL             =  10800
/
&hgridspec
  NUM_DOMAINS          =  1
  XDIM                 =  101
  YDIM                 =  155
  PARENT_ID            =  1
  RATIO_TO_PARENT      =  1
  DOMAIN_ORIGIN_LLI    =  1
  DOMAIN_ORIGIN_LLJ    =  1
  DOMAIN_ORIGIN_URI    =  101
  DOMAIN_ORIGIN_URJ    =  155
  MAP_PROJ_NAME        =  'rotlat'
  MOAD_KNOWN_LAT       =  40.035
  MOAD_KNOWN_LON       =  -105.2436
  MOAD_STAND_LATS      =  40.035, 40.035 
  MOAD_STAND_LONS      =  -105.2436
  MOAD_DELTA_X         =  6000
  MOAD_DELTA_Y         =  6000
  SILAVWT_PARM_WRF     =  0.
  TOPTWVL_PARM_WRF     =  2.
/
&sfcfiles
  TOPO_30S             =  '/machine/gempak/wrf/data/geog/topo_30s'
  LANDUSE_30S          =  '/machine/gempak/wrf/data/geog/landuse_30s'
  SOILTYPE_TOP_30S     =  '/machine/gempak/wrf/data/geog/soiltype_top_30s'
  SOILTYPE_BOT_30S     =  '/machine/gempak/wrf/data/geog/soiltype_bot_30s'
  GREENFRAC            =  '/machine/gempak/wrf/data/geog/greenfrac'
  SOILTEMP_1DEG        =  '/machine/gempak/wrf/data/geog/soiltemp_1deg'
  ALBEDO_NCEP          =  '/machine/gempak/wrf/data/geog/albedo_ncep'
  MAXSNOWALB           =  '/machine/gempak/wrf/data/geog/maxsnowalb'
  ISLOPE               =  '/machine/gempak/wrf/data/geog/islope'
/
&interp_control
  NUM_ACTIVE_SUBNESTS  = 0
  ACTIVE_SUBNESTS      = 2,3,4
  PTOP_PA              = 5000
  HINTERP_METHOD       = 2
  LSM_HINTERP_METHOD   = 1
  NUM_INIT_TIMES       =  1, 
  INIT_ROOT            =  'ETA'
  LBC_ROOT             =  'ETA'
  LSM_ROOT             =  ''
  CONSTANTS_FULL_NAME  =  ''
  VERBOSE_LOG          = .false.
  OUTPUT_COORD         =  'NMMH'
  LEVELS               =  1.000000, 0.993000, 0.980000, 0.966000, 0.950000, 
0.933000, 0.913000, 0.892000, 0.869000, 0.844000, 
0.816000, 0.786000, 0.753000, 0.718000, 0.680000, 
0.639000, 0.596000, 0.550000, 0.501000, 0.451000, 
0.398000, 0.345000, 0.290000, 0.236000, 0.188000, 
0.145000, 0.108000, 0.075000, 0.046000, 0.021000, 
0.000000
/
&si_paths
  ANALPATH             =  '/machine/gempak/wrf_2.1.2.2/wrf/extprd'
  LBCPATH              =  '/machine/gempak/wrf_2.1.2.2/wrf/extprd'
  LSMPATH              =  '/machine/gempak/wrf_2.1.2.2/wrf/extprd'
  CONSTANTS_PATH       =  '/machine/gempak/wrf_2.1.2.2/wrf/extprd'
/
