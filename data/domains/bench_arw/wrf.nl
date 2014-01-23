 &time_control
 RUN_DAYS = 0,
 RUN_HOURS = 12,
 RUN_MINUTES = 0,
 RUN_SECONDS = 0,
 START_YEAR = 2001, 2001, 2001,
 START_MONTH = 06,   06,   06,
 START_DAY = 11,   11,   11,
 START_HOUR = 12,   12,   12,
 START_MINUTE = 00,   00,   00,
 START_SECOND = 00,   00,   00,
 END_YEAR = 2001, 2001, 2001,
 END_MONTH = 06,   06,   06,
 END_DAY = 12,   12,   12,
 END_HOUR = 12,   12,   12,
 END_MINUTE = 00,   00,   00,
 END_SECOND = 00,   00,   00,
 INTERVAL_SECONDS = 10800
 INPUT_FROM_FILE = .true.,.true.,.true.,
 HISTORY_INTERVAL = 180
 FRAMES_PER_OUTFILE = 1, 1, 1,
 RESTART = .false.,
 RESTART_INTERVAL = 10000,
 IO_FORM_HISTORY = 2
 IO_FORM_RESTART = 2
 IO_FORM_INPUT = 2
 IO_FORM_BOUNDARY = 2
 DEBUG_LEVEL = 0
/
 &domains
 TIME_STEP = 30,
 TIME_STEP_FRACT_NUM = 0,
 TIME_STEP_FRACT_DEN = 1,
 max_dom = 1
 s_we           =   1, 
 e_we           = 77, 
 s_sn           =   1, 
 e_sn           = 65, 
 s_vert         =   1, 
 e_vert         = 45, 
 dx             = 15000, 
 dy             = 15000, 
 grid_id        = 1, 
 parent_id      = 1, 
 i_parent_start = 0, 
 j_parent_start = 0, 
 parent_grid_ratio = 1, 
 parent_time_step_ratio = 1, 
 FEEDBACK = 1,
 SMOOTH_OPTION = 2
 NPROC_X = -1
 NPROC_Y = -1
/
 &physics
 MP_PHYSICS = 5,     5,     5,
 RA_LW_PHYSICS = 1,     1,     1,
 RA_SW_PHYSICS = 1,     1,     1,
 RADT = 10,    10,    10,
 NRADL = 30
 NRADS = 30
 CO2TF = 1
 SF_SFCLAY_PHYSICS = 1,     1,     1,
 SF_SURFACE_PHYSICS = 1,     1,     1,
 BL_PBL_PHYSICS = 1,     1,     1,
 BLDT = 5,     5,     3,
 NPHS = 10 
 CU_PHYSICS = 1,     1,     1,
 CUDT = 5,     5,     5,
 NTSBD = 100
 NCNVC = 10
 ISFFLX = 1,
 IFSNOW = 1,
 ICLOUD = 1,
 SURFACE_INPUT_SOURCE = 1,
 NUM_SOIL_LAYERS = 5,
 MP_ZERO_OUT     = 0
 MAXIENS = 1,
 MAXENS = 3,
 MAXENS2 = 3,
 MAXENS3 = 16,
 ENSDIM = 144,
/
 &dynamics
 DYN_OPT = 2,
 RK_ORD = 3,
 W_DAMPING = 0,
 DIFF_OPT = 1,
 KM_OPT = 4,
 DAMP_OPT = 0,
 ZDAMP = 5000.,  5000.,  5000.,
 DAMPCOEF = 0.2,    0.2,    0.2
 KHDIF = 0,      0,      0,
 KVDIF = 0,      0,      0,
 SMDIV = 0.1,    0.1,    0.1,
 EMDIV = 0.01,   0.01,   0.01,
 EPSSM = 0.1,    0.1,    0.1
 NON_HYDROSTATIC = .true., .true., .true.,
 TIME_STEP_SOUND = 4,      4,      4,
 H_MOM_ADV_ORDER = 5,      5,      5,
 V_MOM_ADV_ORDER = 3,      3,      3,
 H_SCA_ADV_ORDER = 5,      5,      5,
 V_SCA_ADV_ORDER = 3,      3,      3,
/
 &bdy_control
 SPEC_BDY_WIDTH = 5,
 SPEC_ZONE = 1,
 RELAX_ZONE = 4,
 SPECIFIED = .true., .true.,.true.,
 PERIODIC_X = .false.,.false.,.false.,
 SYMMETRIC_XS = .false.,.false.,.false.,
 SYMMETRIC_XE = .false.,.false.,.false.,
 OPEN_XS = .false.,.false.,.false.,
 OPEN_XE = .false.,.false.,.false.,
 PERIODIC_Y = .false.,.false.,.false.,
 SYMMETRIC_YS = .false.,.false.,.false.,
 SYMMETRIC_YE = .false.,.false.,.false.,
 OPEN_YS = .false.,.false.,.false.,
 OPEN_YE = .false.,.false.,.false.,
 NESTED = .false., .true., .true.,
/
 &namelist_quilt
 NIO_TASKS_PER_GROUP = 0,
 NIO_GROUPS = 1,
/
