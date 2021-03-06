&time_control
  RUN_DAYS             = 0
  RUN_HOURS            = 24
  RUN_MINUTES          = 0
  RUN_SECONDS          = 0
  START_YEAR           = 2005
  START_MONTH          = 01
  START_DAY            = 23
  START_HOUR           = 00
  START_MINUTE         = 00
  START_SECOND         = 00
  END_YEAR             = 2005
  END_MONTH            = 01
  END_DAY              = 24
  END_HOUR             = 00
  END_MINUTE           = 00
  END_SECOND           = 00
  INTERVAL_SECONDS     = 10800
  INPUT_FROM_FILE      = .true.,.true.,.true.
  HISTORY_INTERVAL     = 180
  FRAMES_PER_OUTFILE   = 1
  RESTART              = .false.
  RESTART_INTERVAL     = 10000
  IO_FORM_HISTORY      = 2
  IO_FORM_RESTART      = 2
  IO_FORM_INPUT        = 2
  IO_FORM_BOUNDARY     = 2
  DEBUG_LEVEL          = 0
/
&domains
  TIME_STEP            = 36
  TIME_STEP_FRACT_NUM  = 0
  TIME_STEP_FRACT_DEN  = 1
  MAX_DOM              = 1
  S_WE                 = 1, 
  E_WE                 = 56
  S_SN                 = 1, 
  E_SN                 = 92
  S_VERT               = 1, 
  E_VERT               = 45, 
  DX                   = 0.0975
  DY                   = 0.09606
  GRID_ID              = 1, 
  PARENT_ID            = 1, 
  I_PARENT_START       = 0, 
  J_PARENT_START       = 0, 
  PARENT_GRID_RATIO    = 1, 
  PARENT_TIME_STEP_RATIO = 1, 
  FEEDBACK             = 0
  SMOOTH_OPTION        = 1
  NPROC_X              = -1
  NPROC_Y              = -1
/
&physics
  MP_PHYSICS           = 5, 5, 5, 5
  RA_LW_PHYSICS        = 99
  RA_SW_PHYSICS        = 99
  RADT                 = 10
  NRADL                = 40
  NRADS                = 40
  CO2TF                = 1
  SF_SFCLAY_PHYSICS    = 2, 2, 2, 2
  SF_SURFACE_PHYSICS   = 99
  BL_PBL_PHYSICS       = 2, 2, 2, 2
  BLDT                 = 5, 5, 5, 5
  NPHS                 = 4
  CU_PHYSICS           = 1, 1, 1, 1
  NTSBD                = 300
  CUDT                 = 5, 5, 5, 5
  NCNVC                = 6
  ISFFLX               = 1
  IFSNOW               = 1
  ICLOUD               = 1
  SURFACE_INPUT_SOURCE = 1
  NUM_SOIL_LAYERS      = 4
  MP_ZERO_OUT          = 0
  MAXIENS              = 1
  MAXENS               = 3
  MAXENS2              = 3
  MAXENS3              = 16
  ENSDIM               = 144
/
&dynamics
  DYN_OPT              = 4
  RK_ORD               = 3
  W_DAMPING            = 1
  DIFF_OPT             = 1
  KM_OPT               = 4
  DAMP_OPT             = 0
  ZDAMP                = 5000.
  DAMPCOEF             = 0.05
  KHDIF                = 0
  KVDIF                = 0
  SMDIV                = 0.1
  EMDIV                = 0.01
  EPSSM                = 0.1,    0.1,    0.1
  NON_HYDROSTATIC      = .true., .true., .true.
  TIME_STEP_SOUND      = 4,      4,      4
  H_MOM_ADV_ORDER      = 5,      5,      5
  V_MOM_ADV_ORDER      = 3,      3,      3
  H_SCA_ADV_ORDER      = 5,      5,      5
  V_SCA_ADV_ORDER      = 3,      3,      3
/
&bdy_control
  SPEC_BDY_WIDTH       = 1
  SPEC_ZONE            = 1
  RELAX_ZONE           = 4
  SPECIFIED            = .true., .true.,.true.
  PERIODIC_X           = .false.,.false.,.false.
  SYMMETRIC_XS         = .false.,.false.,.false.
  SYMMETRIC_XE         = .false.,.false.,.false.
  OPEN_XS              = .false.,.false.,.false.
  OPEN_XE              = .false.,.false.,.false.
  PERIODIC_Y           = .false.,.false.,.false.
  SYMMETRIC_YS         = .false.,.false.,.false.
  SYMMETRIC_YE         = .false.,.false.,.false.
  OPEN_YS              = .false.,.false.,.false.
  OPEN_YE              = .false.,.false.,.false.
  NESTED               = .false., .true., .true.
/
&namelist_quilt
  NIO_TASKS_PER_GROUP  = 0
  NIO_GROUPS           = 1
/
