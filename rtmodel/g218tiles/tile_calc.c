#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "geminc.h"
#include "gemprm.h"

#ifdef UNDERSCORE
#define lccbnd lccbnd_
#define gr_snav	gr_snav_
#endif

#define NCOL  9
#define NROW  6

#define MAXI 614
#define MAXJ 428

char proj[]="LCC";
int  kx=MAXI, ky=MAXJ;
float latll = 12.18992;
float lonll = -133.45898;
float latur = 57.32832;
float lonur = -49.41534;
float angl1 = 25;
float angl2 = -95;
float angl3 = 25;
int angflg = 1;

int main(int argc, char *argv[])
{
int i, ii, jj, ier, ioff=0, joff=0;
int igpt, jgpt, icnt, row, col, tilelist[NCOL*NROW];
float x, y, clat, clon, dx, dy, dlat, dlon, mini,maxi,minj,maxj;
int tilenum[MAXI][MAXJ];
float ftilelat[MAXI][MAXJ], ftilelon[MAXI][MAXJ];
int navsz, nx, ny, imjmf ;
float rnvblk[LLNNAV], *xin, *yin, *xout, *yout, *glat, *glon;
char fname[40], line[81];
FILE *fp;
int TILEDOMAIN=0;
static char msys[]="M", gsys[]="G";

if ( argc != 7 )
   {
   printf("usage: %s clat clon nx ny dx dy\n",argv[0]);
   exit(-1);
   }

sscanf ( argv[1], "%f", &clat);
sscanf ( argv[2], "%f", &clon);
sscanf ( argv[3], "%d", &nx);
sscanf ( argv[4], "%d", &ny);
sscanf ( argv[5], "%f", &dx);
sscanf ( argv[6], "%f", &dy);
dx = sqrt(dx*dx*2); /* calculate native grid resolution */

/* need 4 rows on all sides of domain for boundary */
nx += 2;
ny += 4;

in_bdta ( &ier );

for ( i=0; i<(NROW*NCOL); i++) tilelist[i] = 0;


/* get grid point lats lons of model domain */
imjmf = nx*ny-ny/2;
glat = (float *)malloc(imjmf * sizeof(float));
glon = (float *)malloc(imjmf * sizeof(float));
lccbnd ( &clat, &clon, &nx, &ny, &dx, &dy, glat, glon );

/* create Grid 218 navigation */
gr_mnav ( proj, &kx, &ky, &latll, &lonll, &latur, &lonur,
	&angl1, &angl2, &angl3, &angflg, rnvblk, &ier,
	strlen(proj));

navsz = LLNNAV;
gr_snav ( &navsz, rnvblk, &ier);


/* get row & column corners of model domain points in grid 218 domain */
i = 4;
xin = (float *)malloc(i * sizeof(float));
yin = (float *)malloc(i * sizeof(float));
xout = (float *)malloc(i * sizeof(float));
yout = (float *)malloc(i * sizeof(float));

xin[0] = glat[0];
yin[0] = glon[0];
xin[1] = glat[nx-1];
yin[1] = glon[nx-1];
xin[2] = glat[imjmf-nx];
yin[2] = glon[imjmf-nx];
xin[3] = glat[imjmf-1];
yin[3] = glon[imjmf-1];

gtrans ( msys, gsys, &i, xin, yin, xout, yout, &ier, strlen(msys), strlen(gsys));

/*printf("%f %f     %f %f     %f %f    %f %f\n",
	xout[0]/69, yout[0] / 72,	
	xout[1]/69, yout[1] / 72,	
	xout[2]/69, yout[2] / 72,	
	xout[3]/69, yout[3] / 72);
printf("%f %f     %f %f     %f %f    %f %f\n",
	xin[0], yin[0],	
	xin[1], yin[1],	
	xin[2], yin[2],	
	xin[3], yin[3]);*/

for ( i=0; i < NROW*NCOL ; i++)
   {
   tilelist[i] = 0;
   }

for ( jj =  (int)(yout[0]/72.0); jj <= (int)(yout[3]/72.0); jj++)
   for ( ii = (int)(xout[0]/69.0); ii<= (int)(xout[3]/69.0); ii++)
   {
      i = NCOL * jj + ii;
   
      if ( tilelist[i]  == 0 ) TILEDOMAIN++;
      tilelist[i] = 1;
   }


if ( TILEDOMAIN > 0 )
   {
   printf("--tiles ");
   for ( i = 0; i < (NROW*NCOL); i++)
      {
      if ( tilelist[i] > 0 )
         {
         printf("%d",i+1);
         TILEDOMAIN--;
         if ( TILEDOMAIN > 0 ) printf(",");
         }
      }
   printf("\n");
   }

}
