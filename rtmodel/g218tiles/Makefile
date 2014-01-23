include $(CONFIGDIR)/Makeinc.common

all: tile_calc

tile_calc: tile_calc.c lccbnd.f
	$(COMPILE.c) tile_calc.c
	$(COMPILE.f) lccbnd.f
	$(LINK.f) -o $@ tile_calc.o lccbnd.o $(GEMLIB) $(GPLT_NC) $(GPLT) $(DEVICE) $(GN) $(CGEMLIB) $(GEMLIB) -lm

tile_calc_new: tile_calc_new.c lccbnd.f
	$(COMPILE.c) tile_calc_new.c
	$(COMPILE.f) lccbnd.f
	$(LINK.f) -o $@ tile_calc_new.o lccbnd.o $(GEMLIB) $(GPLT_NC) $(GPLT) $(DEVICE) $(GN) $(CGEMLIB) $(GEMLIB) -lm
