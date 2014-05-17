/*
   File : GAUSS_VOL.C
   Date : Jan 96, Nov 98

   Ulrik Kjems
   Claus Svarer

   Modified by CS, Nov. 1998 from warp_funs.c
   
-----------------------------------------------------------------------------
1997 Ulrik Kjems, DSP/IMM, Technical University of Denmark, uk@imm.dtu.dk
-----------------------------------------------------------------------------
 This software is FREE for non-commercial use, but the author holds all
 rights, and any use of the software should clearly indicate the author.
-----------------------------------------------------------------------------
 */
#include <stdarg.h>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <float.h>
#include <time.h>
#include <memory.h>

#include "mex.h"

#define	vol_in prhs[0]
#define	vox_size_in prhs[1]
#define	filt_size_in prhs[2]
#define	mult_filt_dim_in prhs[3]
#define	vol_out plhs[0]

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

#define MAX_IMAGE_DIM 1024
#define MAX_GAUSS_KERNEL_DIM 100
#define MAX_N_ITERATIONS 40
#define ODD 1
#define EVEN 0

#ifdef MAX
#undef MAX
#endif
#ifdef MIN
#undef MIN
#endif
#ifdef SQR
#undef SQR
#endif
#define MAX(a,b)     ((a>b)?(a):(b))
#define MIN(a,b)     ((b>a)?(a):(b))
#define SQR(x) ((x)*(x))

#define WARNING 16
#define PANIC 32

enum error_signals {OK, ERROR};

void
compute_gauss (int n, double *g, double fwhm)
{
  /*
    Compute a normalized gaussian blob, length n, centered
    fwhm is measured in pixels

         fwhm = sqrt(8*log(2))*sigma   =  2.3548200*sigma
         sigma = 0.42466090*fwhm
	 sigma^2 = 0.18033688011112*fwhm^2;
    */
  double sum, tmp, sigmapix2;
  int i;
  sum = 0;  sigmapix2 = 0.18033688011112*SQR(fwhm);
  if (sigmapix2 < 0.0001) 
    sigmapix2 = 0.0001;
  for (i = 0; i < n; i++)
    {
      tmp = (i - (n - 1) / 2.);
      g[i] = exp (-SQR (tmp) / (2 * sigmapix2));
      sum += g[i];
    }				/*  Normalize */
  for (i = 0; i < n; i++)
    g[i] /= sum;
}				/*  compute_gauss() */


void 
filter_1d( double *x,  double *res,  int nx,  double *kernel,  int nk) {
  /*
    Filter x length nx into res using kernel length nk
    */
  int i, n;
  double *ii, *iii, *rr;
  double sum, fsum, *k;
  int k_half;
  k_half = nk/2;
  if (nk > nx)
    mexErrMsgTxt("filter_1d(): Error nk > nx!");
  ii = x;
  rr = res;
  for (n = 0; n < k_half; n++) {
    sum = fsum = 0;
    k = kernel+k_half-n;
    iii = ii;
    for (i = 0; i < k_half+n+1; i++) {
      fsum += *k;
      sum += *k++**iii++;
    }
    *rr++ = sum/fsum;
  }
  for (; n < nx-k_half; n++) {
    sum = 0;
    k = kernel;
    iii = ii++;
    for (i = 0; i < nk; i++) 
      sum += *k++**iii++;
    *rr++ = sum;
  }
  for (; n < nx; n++) {
    sum = fsum = 0;
    k = kernel;
    iii = ii++;
    for (i = 0; i < k_half+(nx-n); i++) {
      fsum += *k;
      sum += *k++**iii++;
    }
    *rr++ = sum/fsum; 
  }
  
} /* filter_1d */

int 
gauss_filter( double *im,  double *result,  int *size, double *fwhm_pix,
	      int gamma_d) {
  /*
	Compute the lowpass filtered image result, convolution im with a gauss
	with fwhm = fwhm_pix[0..2]
	gamma_d is the truncation size of the convolution kernel
	fwhm_pix*gamma_d pixels.

	Uses that the Gaussian is separable.
	Edge : No kernel / modified
	*/
  double kernel[MAX_GAUSS_KERNEL_DIM];
  double store1[MAX_IMAGE_DIM], store2[MAX_IMAGE_DIM];
  char   ErrTxt [128];

  double *ii, *bbb, *rr, *iii, fwhm;

  int ks, i, x, y, z, k_size[3], stepz, stepy, index;
  int total, perc, prevperc;

  stepy = size[0];
  stepz = size[1]*stepy;

  if (MAX(MAX(size[0],size[1]),size[2]) >= MAX_IMAGE_DIM) {
    sprintf(ErrTxt,"gauss_filter(): Image dimension %d > %d", (int)(MAX(MAX(size[0],size[1]),size[2])),
            MAX_IMAGE_DIM);
    mexErrMsgTxt(ErrTxt);
    return ERROR;
  }
  
  /* Compute fwhms */

  for (i = 0; i < 3; i++) {
    fwhm = fwhm_pix[i];
    k_size[i] = (int)(fwhm*gamma_d+0.5);
    if (k_size[i] < 3) k_size[i] = 3;
    if (!(k_size[i] & 1)) k_size[i]++;
    if (k_size[i] > size[i]) 
      if (size[i] & 1) k_size[i] = size[i]; else k_size[i] = size[i]-1;
    if (k_size[i] > MAX_GAUSS_KERNEL_DIM) {
      sprintf(ErrTxt,"WARNING gauss_filter(): Large kernel truncated ( %d > %d voxels)\n", 
	      k_size[i],MAX_GAUSS_KERNEL_DIM);
      mexErrMsgTxt(ErrTxt);
      k_size[i] = MAX_GAUSS_KERNEL_DIM;
      if (!(k_size[i] & 1)) k_size[i]--;
    }
  }

  printf("Filter kernel size (%d, %d, %d voxels)\n",k_size[0],k_size[1],k_size[2]);

  /* Do X */
  ks = k_size[0];
  total = size[2]*2+size[1];
  compute_gauss(ks, kernel, fwhm_pix[0]);
  for (z = 0; z < size[2]; z++) {
    index = z*stepz;
    rr = result+index;
    ii = im+index;
    for (y = 0; y < size[1]; y++) {
      filter_1d(ii, rr, size[0], kernel, ks);
      ii += stepy;
      rr += stepy;
    }
  } /*   for z  */

  /* Do Y */
  ks = k_size[1];
  compute_gauss(ks, kernel, fwhm_pix[1]);
  for (z = 0; z < size[2]; z++) {
    for (x = 0; x < size[0]; x++) {
      index = z*stepz+x;
      /* Copy image vector to buffer */
      iii = result+index;
      bbb = store1;
      for (y = 0; y< size[1]; y++) {
	*bbb++ = *iii;
	iii += stepy;
      }
      /*  Filter image into second buffer  */
      filter_1d(store1, store2, size[1], kernel, ks);
      /* Copy back into result  */
      iii = result+index;
      bbb = store2;
      for (y = 0; y< size[1]; y++) {
	*iii = *bbb++;
	iii += stepy;
      }
    }  /*  for x */
  } /*   for z  */
  
  /* Do Z */
  ks = k_size[2];
  compute_gauss(ks, kernel, fwhm_pix[2]);
  for (y = 0; y < size[1]; y++) {
    for (x = 0; x < size[0]; x++) {
      index = y*stepy+x;
      /* Copy image vector to buffer */
      iii = result+index;
      bbb = store1;
      for (z = 0; z< size[2]; z++) {
	*bbb++ = *iii;
	iii += stepz;
      }
      filter_1d(store1, store2, size[2], kernel, ks);
      iii = result+index;
      bbb = store2;
      for (z = 0; z < size[2]; z++) {
	*iii = *bbb++;
	iii += stepz;
      }
    }  /*  for x */
  } /*   for y  */
    
  return OK;
} /*  void gauss_filter() */


void mexFunction(
                 int nlhs,       mxArray *plhs[],
                 int nrhs, const mxArray *prhs[]
		 )
{
  int *dimensions, ndims, mult_filt_dim;
  double *vol_outp, *vol_inp, *vox_size_inp; 
  double *filt_size_inp, *mult_filt_dim_inp;
  double fwhm_size_pix [3];
  unsigned char vox_size_def;

  if ((nrhs != 4) && (nrhs != 3))
    mexErrMsgTxt("gauss_vol: No of input arguments should be 3 or 4\n");

  ndims=mxGetNumberOfDimensions(vox_size_in);
  dimensions = (int *)mxGetDimensions(vox_size_in);
  if ((ndims!=2) ||
      ((MAX(dimensions[0],dimensions[1])!=3) &&
       (MAX(dimensions[0],dimensions[1])!=0)))
    mexErrMsgTxt("gauss_vol: Voxel size should have dimension 3 or []\n");
  else
    if (MAX(dimensions[0],dimensions[1])==3) 
      vox_size_def = 1;
    else
      vox_size_def = 0;
    
  ndims=mxGetNumberOfDimensions(filt_size_in);
  dimensions = (int *)mxGetDimensions(filt_size_in); 
  if ((ndims!=2) ||
      (MAX(dimensions[0],dimensions[1])!=3))
    mexErrMsgTxt("gauss_vol: Filter size should have dimension 3\n");

  if (nrhs == 4) {
    ndims=mxGetNumberOfDimensions(mult_filt_dim_in);
    dimensions = (int *)mxGetDimensions(mult_filt_dim_in); 
    if ((ndims!=2) ||
	((MAX(dimensions[0],dimensions[1])!=1) && 
	 (MAX(dimensions[0],dimensions[1])!=0)))
      mexErrMsgTxt("gauss_vol: Multiplication factor for filter dimension should have dimension 1 or []\n");
    else
      if (MAX(dimensions[0],dimensions[1])==1) 
	mult_filt_dim = 0;
      else
	mult_filt_dim = 4;
  }
  else
    mult_filt_dim = 4;

  ndims=mxGetNumberOfDimensions(vol_in);
  if (ndims!=3) 
    mexErrMsgTxt("gauss_vol: Input volume is not a volume\n");
  dimensions = (int *)mxGetDimensions(vol_in); 
  printf("GaussFiltering (Image volume: %d x %d x %d)\n",dimensions[0],dimensions[1],dimensions[2]);

  vol_out = mxCreateNumericArray(ndims,dimensions,mxDOUBLE_CLASS,mxREAL);
  vol_outp=(double *)mxGetPr(vol_out); 

  vol_inp=(double *)mxGetPr(vol_in);
  vox_size_inp=(double *)mxGetPr(vox_size_in);
  filt_size_inp=(double *)mxGetPr(filt_size_in);
  mult_filt_dim_inp=(double *)mxGetPr(mult_filt_dim_in);

  if (vox_size_def) {
    fwhm_size_pix[0] = filt_size_inp[0]/vox_size_inp[0];
    fwhm_size_pix[1] = filt_size_inp[1]/vox_size_inp[1];
    fwhm_size_pix[2] = filt_size_inp[2]/vox_size_inp[2];
  }
  else {
    fwhm_size_pix[0] = filt_size_inp[0];
    fwhm_size_pix[1] = filt_size_inp[1];
    fwhm_size_pix[2] = filt_size_inp[2];
  }

  if (mult_filt_dim == 0)
    mult_filt_dim=(int)(*mult_filt_dim_inp+0.5);
  
  if (gauss_filter(vol_inp,vol_outp,dimensions,fwhm_size_pix,mult_filt_dim) != OK)
     mexErrMsgTxt("gauss_vol: Problems in gauss_filter subroutine");
}





