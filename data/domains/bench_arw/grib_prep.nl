&filetimespec
 START_YEAR = 2001
 START_MONTH = 07
 START_DAY = 09
 START_HOUR = 12
 START_MINUTE = 00
 START_SECOND = 00
 END_YEAR = 2001
 END_MONTH = 07
 END_DAY = 10
 END_HOUR = 12
 END_MINUTE = 00
 END_SECOND = 00
 INTERVAL = 10800
/
&gpinput_defs
 SRCNAME = 'ETA', 'GFS', 'AVN', 'RUCH', 'NNRP', 'NNRPSFC', 'SST'
 SRCVTAB = 'ETA', 'GFS', 'AVN', 'RUCH', 'NNRPSFC', 'NNRPSFC', 'SST'
 SRCPATH = '/public/data/grids/eta/40km_eta212_isobaric/grib', 
		'/public/data/grids/gfs/0p5deg/grib', 
		'/public/data/grids/avn/global-65160/grib', 
		'/rt0/rucdev/nrelwind/run/maps_fcst', 
		'/path/to/nnrp/grib', 
		'/path/to/nnrp/sfc/grib', 
		'/public/data/grids/ncep/sst/grib'
 SRCCYCLE = 6, 6, 6, 6, 12, 12, 24
 SRCDELAY = 3, 4, 4, 3, 0, 0, 12
/
