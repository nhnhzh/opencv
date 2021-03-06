/*M///////////////////////////////////////////////////////////////////////////////////////
//
//  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.
//
//  By downloading, copying, installing or using the software you agree to this license.
//  If you do not agree to this license, do not download, install,
//  copy or use the software.
//
//
//                           License Agreement
//                For Open Source Computer Vision Library
//
// Copyright (C) 2010-2012, Multicoreware, Inc., all rights reserved.
// Copyright (C) 2010-2012, Advanced Micro Devices, Inc., all rights reserved.
// Third party copyrights are property of their respective owners.
//
// @Authors
//    Peng Xiao, pengxiao@multicorewareinc.com
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
//   * Redistribution's of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//   * Redistribution's in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other oclMaterials provided with the distribution.
//
//   * The name of the copyright holders may not be used to endorse or promote products
//     derived from this software without specific prior written permission.
//
// This software is provided by the copyright holders and contributors as is and
// any express or implied warranties, including, but not limited to, the implied
// warranties of merchantability and fitness for a particular purpose are disclaimed.
// In no event shall the Intel Corporation or contributors be liable for any direct,
// indirect, incidental, special, exemplary, or consequential damages
// (including, but not limited to, procurement of substitute goods or services;
// loss of use, data, or profits; or business interruption) however caused
// and on any theory of liability, whether in contract, strict liability,
// or tort (including negligence or otherwise) arising in any way out of
// the use of this software, even if advised of the possibility of such damage.
//
//M*/

#pragma OPENCL EXTENSION cl_khr_global_int32_base_atomics : enable
#pragma OPENCL EXTENSION cl_khr_local_int32_base_atomics : enable

// specialized for non-image2d_t supported platform, intel HD4000, for example
#ifdef DISABLE_IMAGE2D
#define IMAGE_INT32 __global uint  *
#define IMAGE_INT8  __global uchar *
#else
#define IMAGE_INT32 image2d_t
#define IMAGE_INT8  image2d_t
#endif

uint read_sumTex(IMAGE_INT32 img, sampler_t sam, int2 coord, int rows, int cols, int elemPerRow)
{
#ifdef DISABLE_IMAGE2D
    int x = clamp(coord.x, 0, cols);
    int y = clamp(coord.y, 0, rows);
    return img[elemPerRow * y + x];
#else
    return read_imageui(img, sam, coord).x;
#endif
}
uchar read_imgTex(IMAGE_INT8 img, sampler_t sam, float2 coord, int rows, int cols, int elemPerRow)
{
#ifdef DISABLE_IMAGE2D
    int x = clamp(convert_int_rte(coord.x), 0, cols - 1);
    int y = clamp(convert_int_rte(coord.y), 0, rows - 1);
    return img[elemPerRow * y + x];
#else
    return (uchar)read_imageui(img, sam, coord).x;
#endif
}

// dynamically change the precision used for floating type

#if defined (__ATI__) || defined (__NVIDIA__)
#define F double
#else
#define F float
#endif

// Image read mode
__constant sampler_t sampler    = CLK_NORMALIZED_COORDS_FALSE | CLK_ADDRESS_CLAMP_TO_EDGE | CLK_FILTER_NEAREST;

#ifndef FLT_EPSILON
#define FLT_EPSILON (1e-15)
#endif

#ifndef CV_PI_F
#define CV_PI_F 3.14159265f
#endif

// Use integral image to calculate haar wavelets.
// N = 2
// for simple haar paatern
float icvCalcHaarPatternSum_2(
    IMAGE_INT32 sumTex,
    __constant float src[2][5],
    int oldSize,
    int newSize,
    int y, int x,
    int rows, int cols, int elemPerRow)
{

    float ratio = (float)newSize / oldSize;

    F d = 0;

#pragma unroll
    for (int k = 0; k < 2; ++k)
    {
        int dx1 = convert_int_rte(ratio * src[k][0]);
        int dy1 = convert_int_rte(ratio * src[k][1]);
        int dx2 = convert_int_rte(ratio * src[k][2]);
        int dy2 = convert_int_rte(ratio * src[k][3]);

        F t = 0;
        t += read_sumTex( sumTex, sampler, (int2)(x + dx1, y + dy1), rows, cols, elemPerRow );
        t -= read_sumTex( sumTex, sampler, (int2)(x + dx1, y + dy2), rows, cols, elemPerRow );
        t -= read_sumTex( sumTex, sampler, (int2)(x + dx2, y + dy1), rows, cols, elemPerRow );
        t += read_sumTex( sumTex, sampler, (int2)(x + dx2, y + dy2), rows, cols, elemPerRow );
        d += t * src[k][4] / ((dx2 - dx1) * (dy2 - dy1));
    }

    return (float)d;
}

// N = 3
float icvCalcHaarPatternSum_3(
    IMAGE_INT32 sumTex,
    __constant float src[2][5],
    int oldSize,
    int newSize,
    int y, int x,
    int rows, int cols, int elemPerRow)
{

    float ratio = (float)newSize / oldSize;

    F d = 0;

#pragma unroll
    for (int k = 0; k < 3; ++k)
    {
        int dx1 = convert_int_rte(ratio * src[k][0]);
        int dy1 = convert_int_rte(ratio * src[k][1]);
        int dx2 = convert_int_rte(ratio * src[k][2]);
        int dy2 = convert_int_rte(ratio * src[k][3]);

        F t = 0;
        t += read_sumTex( sumTex, sampler, (int2)(x + dx1, y + dy1), rows, cols, elemPerRow );
        t -= read_sumTex( sumTex, sampler, (int2)(x + dx1, y + dy2), rows, cols, elemPerRow );
        t -= read_sumTex( sumTex, sampler, (int2)(x + dx2, y + dy1), rows, cols, elemPerRow );
        t += read_sumTex( sumTex, sampler, (int2)(x + dx2, y + dy2), rows, cols, elemPerRow );
        d += t * src[k][4] / ((dx2 - dx1) * (dy2 - dy1));
    }

    return (float)d;
}

// N = 4
float icvCalcHaarPatternSum_4(
    IMAGE_INT32 sumTex,
    __constant float src[2][5],
    int oldSize,
    int newSize,
    int y, int x,
    int rows, int cols, int elemPerRow)
{

    float ratio = (float)newSize / oldSize;

    F d = 0;

#pragma unroll
    for (int k = 0; k < 4; ++k)
    {
        int dx1 = convert_int_rte(ratio * src[k][0]);
        int dy1 = convert_int_rte(ratio * src[k][1]);
        int dx2 = convert_int_rte(ratio * src[k][2]);
        int dy2 = convert_int_rte(ratio * src[k][3]);

        F t = 0;
        t += read_sumTex( sumTex, sampler, (int2)(x + dx1, y + dy1), rows, cols, elemPerRow );
        t -= read_sumTex( sumTex, sampler, (int2)(x + dx1, y + dy2), rows, cols, elemPerRow );
        t -= read_sumTex( sumTex, sampler, (int2)(x + dx2, y + dy1), rows, cols, elemPerRow );
        t += read_sumTex( sumTex, sampler, (int2)(x + dx2, y + dy2), rows, cols, elemPerRow );
        d += t * src[k][4] / ((dx2 - dx1) * (dy2 - dy1));
    }

    return (float)d;
}

////////////////////////////////////////////////////////////////////////
// Hessian

__constant float c_DX [3][5] = { {0, 2, 3, 7, 1}, {3, 2, 6, 7, -2}, {6, 2, 9, 7, 1} };
__constant float c_DY [3][5] = { {2, 0, 7, 3, 1}, {2, 3, 7, 6, -2}, {2, 6, 7, 9, 1} };
__constant float c_DXY[4][5] = { {1, 1, 4, 4, 1}, {5, 1, 8, 4, -1}, {1, 5, 4, 8, -1}, {5, 5, 8, 8, 1} };

__inline int calcSize(int octave, int layer)
{
    /* Wavelet size at first layer of first octave. */
    const int HAAR_SIZE0 = 9;

    /* Wavelet size increment between layers. This should be an even number,
    such that the wavelet sizes in an octave are either all even or all odd.
    This ensures that when looking for the neighbours of a sample, the layers
    above and below are aligned correctly. */
    const int HAAR_SIZE_INC = 6;

    return (HAAR_SIZE0 + HAAR_SIZE_INC * layer) << octave;
}


//calculate targeted layer per-pixel determinant and trace with an integral image
__kernel void icvCalcLayerDetAndTrace(
    IMAGE_INT32 sumTex, // input integral image
    __global float * det,      // output Determinant
    __global float * trace,    // output trace
    int det_step,     // the step of det in bytes
    int trace_step,   // the step of trace in bytes
    int c_img_rows,
    int c_img_cols,
    int c_nOctaveLayers,
    int c_octave,
    int c_layer_rows,
    int sumTex_step
    )
{
    det_step   /= sizeof(*det);
    trace_step /= sizeof(*trace);
    sumTex_step/= sizeof(uint);
    // Determine the indices
    const int gridDim_y  = get_num_groups(1) / (c_nOctaveLayers + 2);
    const int blockIdx_y = get_group_id(1) % gridDim_y;
    const int blockIdx_z = get_group_id(1) / gridDim_y;

    const int j = get_local_id(0) + get_group_id(0) * get_local_size(0);
    const int i = get_local_id(1) + blockIdx_y * get_local_size(1);
    const int layer = blockIdx_z;

    const int size = calcSize(c_octave, layer);

    const int samples_i = 1 + ((c_img_rows - size) >> c_octave);
    const int samples_j = 1 + ((c_img_cols - size) >> c_octave);

    // Ignore pixels where some of the kernel is outside the image
    const int margin = (size >> 1) >> c_octave;

    if (size <= c_img_rows && size <= c_img_cols && i < samples_i && j < samples_j)
    {
        const float dx  = icvCalcHaarPatternSum_3(sumTex, c_DX , 9, size, i << c_octave, j << c_octave, c_img_rows, c_img_cols, sumTex_step);
        const float dy  = icvCalcHaarPatternSum_3(sumTex, c_DY , 9, size, i << c_octave, j << c_octave, c_img_rows, c_img_cols, sumTex_step);
        const float dxy = icvCalcHaarPatternSum_4(sumTex, c_DXY, 9, size, i << c_octave, j << c_octave, c_img_rows, c_img_cols, sumTex_step);

        det  [j + margin + det_step   * (layer * c_layer_rows + i + margin)] = dx * dy - 0.81f * dxy * dxy;
        trace[j + margin + trace_step * (layer * c_layer_rows + i + margin)] = dx + dy;
    }
}


////////////////////////////////////////////////////////////////////////
// NONMAX

__constant float c_DM[5] = {0, 0, 9, 9, 1};

bool within_check(IMAGE_INT32 maskSumTex, int sum_i, int sum_j, int size, int rows, int cols, int step)
{
    float ratio = (float)size / 9.0f;

    float d = 0;

    int dx1 = convert_int_rte(ratio * c_DM[0]);
    int dy1 = convert_int_rte(ratio * c_DM[1]);
    int dx2 = convert_int_rte(ratio * c_DM[2]);
    int dy2 = convert_int_rte(ratio * c_DM[3]);

    float t = 0;

    t += read_sumTex(maskSumTex, sampler, (int2)(sum_j + dx1, sum_i + dy1), rows, cols, step);
    t -= read_sumTex(maskSumTex, sampler, (int2)(sum_j + dx1, sum_i + dy2), rows, cols, step);
    t -= read_sumTex(maskSumTex, sampler, (int2)(sum_j + dx2, sum_i + dy1), rows, cols, step);
    t += read_sumTex(maskSumTex, sampler, (int2)(sum_j + dx2, sum_i + dy2), rows, cols, step);

    d += t * c_DM[4] / ((dx2 - dx1) * (dy2 - dy1));

    return (d >= 0.5f);
}

// Non-maximal suppression to further filtering the candidates from previous step
__kernel
    void icvFindMaximaInLayer_withmask(
    __global const float * det,
    __global const float * trace,
    __global int4 * maxPosBuffer,
    volatile __global unsigned int* maxCounter,
    int counter_offset,
    int det_step,     // the step of det in bytes
    int trace_step,   // the step of trace in bytes
    int c_img_rows,
    int c_img_cols,
    int c_nOctaveLayers,
    int c_octave,
    int c_layer_rows,
    int c_layer_cols,
    int c_max_candidates,
    float c_hessianThreshold,
    IMAGE_INT32 maskSumTex,
    int mask_step
    )
{
    volatile __local  float N9[768]; // threads.x * threads.y * 3

    det_step   /= sizeof(*det);
    trace_step /= sizeof(*trace);
    maxCounter += counter_offset;
    mask_step  /= sizeof(uint);

    // Determine the indices
    const int gridDim_y  = get_num_groups(1) / c_nOctaveLayers;
    const int blockIdx_y = get_group_id(1)   % gridDim_y;
    const int blockIdx_z = get_group_id(1)   / gridDim_y;

    const int layer = blockIdx_z + 1;

    const int size = calcSize(c_octave, layer);

    // Ignore pixels without a 3x3x3 neighbourhood in the layer above
    const int margin = ((calcSize(c_octave, layer + 1) >> 1) >> c_octave) + 1;

    const int j = get_local_id(0) + get_group_id(0) * (get_local_size(0) - 2) + margin - 1;
    const int i = get_local_id(1) + blockIdx_y * (get_local_size(1) - 2) + margin - 1;

    // Is this thread within the hessian buffer?
    const int zoff = get_local_size(0) * get_local_size(1);
    const int localLin = get_local_id(0) + get_local_id(1) * get_local_size(0) + zoff;
    N9[localLin - zoff] =
        det[det_step *
        (c_layer_rows * (layer - 1) + min(max(i, 0), c_img_rows - 1)) // y
        + min(max(j, 0), c_img_cols - 1)];                            // x
    N9[localLin       ] =
        det[det_step *
        (c_layer_rows * (layer    ) + min(max(i, 0), c_img_rows - 1)) // y
        + min(max(j, 0), c_img_cols - 1)];                            // x
    N9[localLin + zoff] =
        det[det_step *
        (c_layer_rows * (layer + 1) + min(max(i, 0), c_img_rows - 1)) // y
        + min(max(j, 0), c_img_cols - 1)];                            // x

    barrier(CLK_LOCAL_MEM_FENCE);

    if (i < c_layer_rows - margin
        && j < c_layer_cols - margin
        && get_local_id(0) > 0
        && get_local_id(0) < get_local_size(0) - 1
        && get_local_id(1) > 0
        && get_local_id(1) < get_local_size(1) - 1 // these are unnecessary conditions ported from CUDA
        )
    {
        float val0 = N9[localLin];

        if (val0 > c_hessianThreshold)
        {
            // Coordinates for the start of the wavelet in the sum image. There
            // is some integer division involved, so don't try to simplify this
            // (cancel out sampleStep) without checking the result is the same
            const int sum_i = (i - ((size >> 1) >> c_octave)) << c_octave;
            const int sum_j = (j - ((size >> 1) >> c_octave)) << c_octave;

            if (within_check(maskSumTex, sum_i, sum_j, size, c_img_rows, c_img_cols, mask_step))
            {
                // Check to see if we have a max (in its 26 neighbours)
                const bool condmax = val0 > N9[localLin - 1 - get_local_size(0) - zoff]
                &&                   val0 > N9[localLin     - get_local_size(0) - zoff]
                &&                   val0 > N9[localLin + 1 - get_local_size(0) - zoff]
                &&                   val0 > N9[localLin - 1                     - zoff]
                &&                   val0 > N9[localLin                         - zoff]
                &&                   val0 > N9[localLin + 1                     - zoff]
                &&                   val0 > N9[localLin - 1 + get_local_size(0) - zoff]
                &&                   val0 > N9[localLin     + get_local_size(0) - zoff]
                &&                   val0 > N9[localLin + 1 + get_local_size(0) - zoff]

                &&                   val0 > N9[localLin - 1 - get_local_size(0)]
                &&                   val0 > N9[localLin     - get_local_size(0)]
                &&                   val0 > N9[localLin + 1 - get_local_size(0)]
                &&                   val0 > N9[localLin - 1                    ]
                &&                   val0 > N9[localLin + 1                    ]
                &&                   val0 > N9[localLin - 1 + get_local_size(0)]
                &&                   val0 > N9[localLin     + get_local_size(0)]
                &&                   val0 > N9[localLin + 1 + get_local_size(0)]

                &&                   val0 > N9[localLin - 1 - get_local_size(0) + zoff]
                &&                   val0 > N9[localLin     - get_local_size(0) + zoff]
                &&                   val0 > N9[localLin + 1 - get_local_size(0) + zoff]
                &&                   val0 > N9[localLin - 1                     + zoff]
                &&                   val0 > N9[localLin                         + zoff]
                &&                   val0 > N9[localLin + 1                     + zoff]
                &&                   val0 > N9[localLin - 1 + get_local_size(0) + zoff]
                &&                   val0 > N9[localLin     + get_local_size(0) + zoff]
                &&                   val0 > N9[localLin + 1 + get_local_size(0) + zoff]
                ;

                if(condmax)
                {
                    unsigned int ind = atomic_inc(maxCounter);

                    if (ind < c_max_candidates)
                    {
                        const int laplacian = (int) copysign(1.0f, trace[trace_step* (layer * c_layer_rows + i) + j]);

                        maxPosBuffer[ind] = (int4)(j, i, layer, laplacian);
                    }
                }
            }
        }
    }
}

__kernel
    void icvFindMaximaInLayer(
    __global float * det,
    __global float * trace,
    __global int4 * maxPosBuffer,
    volatile __global unsigned int* maxCounter,
    int counter_offset,
    int det_step,     // the step of det in bytes
    int trace_step,   // the step of trace in bytes
    int c_img_rows,
    int c_img_cols,
    int c_nOctaveLayers,
    int c_octave,
    int c_layer_rows,
    int c_layer_cols,
    int c_max_candidates,
    float c_hessianThreshold
    )
{
    volatile __local  float N9[768]; // threads.x * threads.y * 3

    det_step   /= sizeof(float);
    trace_step /= sizeof(float);
    maxCounter += counter_offset;

    // Determine the indices
    const int gridDim_y  = get_num_groups(1) / c_nOctaveLayers;
    const int blockIdx_y = get_group_id(1)   % gridDim_y;
    const int blockIdx_z = get_group_id(1)   / gridDim_y;

    const int layer = blockIdx_z + 1;

    const int size = calcSize(c_octave, layer);

    // Ignore pixels without a 3x3x3 neighbourhood in the layer above
    const int margin = ((calcSize(c_octave, layer + 1) >> 1) >> c_octave) + 1;

    const int j = get_local_id(0) + get_group_id(0) * (get_local_size(0) - 2) + margin - 1;
    const int i = get_local_id(1) + blockIdx_y      * (get_local_size(1) - 2) + margin - 1;

    // Is this thread within the hessian buffer?
    const int zoff     = get_local_size(0) * get_local_size(1);
    const int localLin = get_local_id(0) + get_local_id(1) * get_local_size(0) + zoff;

    int l_x = min(max(j, 0), c_img_cols - 1);
    int l_y = c_layer_rows * layer + min(max(i, 0), c_img_rows - 1);

    N9[localLin - zoff] =
        det[det_step * (l_y - c_layer_rows) + l_x];
    N9[localLin       ] =
        det[det_step * (l_y               ) + l_x];
    N9[localLin + zoff] =
        det[det_step * (l_y + c_layer_rows) + l_x];
    barrier(CLK_LOCAL_MEM_FENCE);

    if (i < c_layer_rows - margin
        && j < c_layer_cols - margin
        && get_local_id(0) > 0
        && get_local_id(0) < get_local_size(0) - 1
        && get_local_id(1) > 0
        && get_local_id(1) < get_local_size(1) - 1 // these are unnecessary conditions ported from CUDA
        )
    {
        float val0 = N9[localLin];
        if (val0 > c_hessianThreshold)
        {
            // Coordinates for the start of the wavelet in the sum image. There
            // is some integer division involved, so don't try to simplify this
            // (cancel out sampleStep) without checking the result is the same

            // Check to see if we have a max (in its 26 neighbours)
            const bool condmax = val0 > N9[localLin - 1 - get_local_size(0) - zoff]
            &&                   val0 > N9[localLin     - get_local_size(0) - zoff]
            &&                   val0 > N9[localLin + 1 - get_local_size(0) - zoff]
            &&                   val0 > N9[localLin - 1                     - zoff]
            &&                   val0 > N9[localLin                         - zoff]
            &&                   val0 > N9[localLin + 1                     - zoff]
            &&                   val0 > N9[localLin - 1 + get_local_size(0) - zoff]
            &&                   val0 > N9[localLin     + get_local_size(0) - zoff]
            &&                   val0 > N9[localLin + 1 + get_local_size(0) - zoff]

            &&                   val0 > N9[localLin - 1 - get_local_size(0)]
            &&                   val0 > N9[localLin     - get_local_size(0)]
            &&                   val0 > N9[localLin + 1 - get_local_size(0)]
            &&                   val0 > N9[localLin - 1                    ]
            &&                   val0 > N9[localLin + 1                    ]
            &&                   val0 > N9[localLin - 1 + get_local_size(0)]
            &&                   val0 > N9[localLin     + get_local_size(0)]
            &&                   val0 > N9[localLin + 1 + get_local_size(0)]

            &&                   val0 > N9[localLin - 1 - get_local_size(0) + zoff]
            &&                   val0 > N9[localLin     - get_local_size(0) + zoff]
            &&                   val0 > N9[localLin + 1 - get_local_size(0) + zoff]
            &&                   val0 > N9[localLin - 1                     + zoff]
            &&                   val0 > N9[localLin                         + zoff]
            &&                   val0 > N9[localLin + 1                     + zoff]
            &&                   val0 > N9[localLin - 1 + get_local_size(0) + zoff]
            &&                   val0 > N9[localLin     + get_local_size(0) + zoff]
            &&                   val0 > N9[localLin + 1 + get_local_size(0) + zoff]
            ;

            if(condmax)
            {
                unsigned int ind = atomic_inc(maxCounter);

                if (ind < c_max_candidates)
                {
                    const int laplacian = (int) copysign(1.0f, trace[trace_step* (layer * c_layer_rows + i) + j]);

                    maxPosBuffer[ind] = (int4)(j, i, layer, laplacian);
                }
            }
        }
    }
}

// solve 3x3 linear system Ax=b for floating point input
inline bool solve3x3_float(volatile __local  const float A[3][3], volatile __local  const float b[3], volatile __local  float x[3])
{
    float det = A[0][0] * (A[1][1] * A[2][2] - A[1][2] * A[2][1])
        - A[0][1] * (A[1][0] * A[2][2] - A[1][2] * A[2][0])
        + A[0][2] * (A[1][0] * A[2][1] - A[1][1] * A[2][0]);

    if (det != 0)
    {
        F invdet = 1.0 / det;

        x[0] = invdet *
            (b[0]    * (A[1][1] * A[2][2] - A[1][2] * A[2][1]) -
            A[0][1] * (b[1]    * A[2][2] - A[1][2] * b[2]   ) +
            A[0][2] * (b[1]    * A[2][1] - A[1][1] * b[2]   ));

        x[1] = invdet *
            (A[0][0] * (b[1]    * A[2][2] - A[1][2] * b[2]   ) -
            b[0]    * (A[1][0] * A[2][2] - A[1][2] * A[2][0]) +
            A[0][2] * (A[1][0] * b[2]    - b[1]    * A[2][0]));

        x[2] = invdet *
            (A[0][0] * (A[1][1] * b[2]    - b[1]    * A[2][1]) -
            A[0][1] * (A[1][0] * b[2]    - b[1]    * A[2][0]) +
            b[0]    * (A[1][0] * A[2][1] - A[1][1] * A[2][0]));

        return true;
    }
    return false;
}

#define X_ROW          0
#define Y_ROW          1
#define LAPLACIAN_ROW  2
#define OCTAVE_ROW     3
#define SIZE_ROW       4
#define ANGLE_ROW      5
#define HESSIAN_ROW    6
#define ROWS_COUNT     7

////////////////////////////////////////////////////////////////////////
// INTERPOLATION
__kernel
    void icvInterpolateKeypoint(
    __global const float * det,
    __global const int4 * maxPosBuffer,
    __global float * keypoints,
    volatile __global unsigned int * featureCounter,
    int det_step,
    int keypoints_step,
    int c_img_rows,
    int c_img_cols,
    int c_octave,
    int c_layer_rows,
    int c_max_features
    )
{
    det_step /= sizeof(*det);
    keypoints_step /= sizeof(*keypoints);
    __global float * featureX       = keypoints + X_ROW * keypoints_step;
    __global float * featureY       = keypoints + Y_ROW * keypoints_step;
    __global int * featureLaplacian = (__global int *)keypoints + LAPLACIAN_ROW * keypoints_step;
    __global int * featureOctave    = (__global int *)keypoints + OCTAVE_ROW * keypoints_step;
    __global float * featureSize    = keypoints + SIZE_ROW * keypoints_step;
    __global float * featureHessian = keypoints + HESSIAN_ROW * keypoints_step;

    const int4 maxPos = maxPosBuffer[get_group_id(0)];

    const int j = maxPos.x - 1 + get_local_id(0);
    const int i = maxPos.y - 1 + get_local_id(1);
    const int layer = maxPos.z - 1 + get_local_id(2);

    volatile __local  float N9[3][3][3];

    N9[get_local_id(2)][get_local_id(1)][get_local_id(0)] =
        det[det_step * (c_layer_rows * layer + i) + j];
    barrier(CLK_LOCAL_MEM_FENCE);

    if (get_local_id(0) == 0 && get_local_id(1) == 0 && get_local_id(2) == 0)
    {
        volatile __local  float dD[3];

        //dx
        dD[0] = -0.5f * (N9[1][1][2] - N9[1][1][0]);
        //dy
        dD[1] = -0.5f * (N9[1][2][1] - N9[1][0][1]);
        //ds
        dD[2] = -0.5f * (N9[2][1][1] - N9[0][1][1]);

        volatile __local  float H[3][3];

        //dxx
        H[0][0] = N9[1][1][0] - 2.0f * N9[1][1][1] + N9[1][1][2];
        //dxy
        H[0][1]= 0.25f * (N9[1][2][2] - N9[1][2][0] - N9[1][0][2] + N9[1][0][0]);
        //dxs
        H[0][2]= 0.25f * (N9[2][1][2] - N9[2][1][0] - N9[0][1][2] + N9[0][1][0]);
        //dyx = dxy
        H[1][0] = H[0][1];
        //dyy
        H[1][1] = N9[1][0][1] - 2.0f * N9[1][1][1] + N9[1][2][1];
        //dys
        H[1][2]= 0.25f * (N9[2][2][1] - N9[2][0][1] - N9[0][2][1] + N9[0][0][1]);
        //dsx = dxs
        H[2][0] = H[0][2];
        //dsy = dys
        H[2][1] = H[1][2];
        //dss
        H[2][2] = N9[0][1][1] - 2.0f * N9[1][1][1] + N9[2][1][1];

        volatile __local  float x[3];

        if (solve3x3_float(H, dD, x))
        {
            if (fabs(x[0]) <= 1.f && fabs(x[1]) <= 1.f && fabs(x[2]) <= 1.f)
            {
                // if the step is within the interpolation region, perform it

                const int size = calcSize(c_octave, maxPos.z);

                const int sum_i = (maxPos.y - ((size >> 1) >> c_octave)) << c_octave;
                const int sum_j = (maxPos.x - ((size >> 1) >> c_octave)) << c_octave;

                const float center_i = sum_i + (float)(size - 1) / 2;
                const float center_j = sum_j + (float)(size - 1) / 2;

                const float px = center_j + x[0] * (1 << c_octave);
                const float py = center_i + x[1] * (1 << c_octave);

                const int ds = size - calcSize(c_octave, maxPos.z - 1);
                const float psize = round(size + x[2] * ds);

                /* The sampling intervals and wavelet sized for selecting an orientation
                and building the keypoint descriptor are defined relative to 's' */
                const float s = psize * 1.2f / 9.0f;

                /* To find the dominant orientation, the gradients in x and y are
                sampled in a circle of radius 6s using wavelets of size 4s.
                We ensure the gradient wavelet size is even to ensure the
                wavelet pattern is balanced and symmetric around its center */
                const int grad_wav_size = 2 * convert_int_rte(2.0f * s);

                // check when grad_wav_size is too big
                if ((c_img_rows + 1) >= grad_wav_size && (c_img_cols + 1) >= grad_wav_size)
                {
                    // Get a new feature index.
                    unsigned int ind = atomic_inc(featureCounter);

                    if (ind < c_max_features)
                    {
                        featureX[ind] = px;
                        featureY[ind] = py;
                        featureLaplacian[ind] = maxPos.w;
                        featureOctave[ind] = c_octave;
                        featureSize[ind] = psize;
                        featureHessian[ind] = N9[1][1][1];
                    }
                } // grad_wav_size check
            } // If the subpixel interpolation worked
        }
    } // If this is thread 0.
}

////////////////////////////////////////////////////////////////////////
// Orientation

#define ORI_SEARCH_INC 5
#define ORI_WIN        60
#define ORI_SAMPLES    113

__constant float c_aptX[ORI_SAMPLES] = {-6, -5, -5, -5, -5, -5, -5, -5, -4, -4, -4, -4, -4, -4, -4, -4, -4, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 6};
__constant float c_aptY[ORI_SAMPLES] = {0, -3, -2, -1, 0, 1, 2, 3, -4, -3, -2, -1, 0, 1, 2, 3, 4, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, -6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, -4, -3, -2, -1, 0, 1, 2, 3, 4, -3, -2, -1, 0, 1, 2, 3, 0};
__constant float c_aptW[ORI_SAMPLES] = {0.001455130288377404f, 0.001707611023448408f, 0.002547456417232752f, 0.003238451667129993f, 0.0035081731621176f,
    0.003238451667129993f, 0.002547456417232752f, 0.001707611023448408f, 0.002003900473937392f, 0.0035081731621176f, 0.005233579315245152f,
    0.00665318313986063f, 0.00720730796456337f, 0.00665318313986063f, 0.005233579315245152f, 0.0035081731621176f,
    0.002003900473937392f, 0.001707611023448408f, 0.0035081731621176f, 0.006141661666333675f, 0.009162282571196556f,
    0.01164754293859005f, 0.01261763460934162f, 0.01164754293859005f, 0.009162282571196556f, 0.006141661666333675f,
    0.0035081731621176f, 0.001707611023448408f, 0.002547456417232752f, 0.005233579315245152f, 0.009162282571196556f,
    0.01366852037608624f, 0.01737609319388866f, 0.0188232995569706f, 0.01737609319388866f, 0.01366852037608624f,
    0.009162282571196556f, 0.005233579315245152f, 0.002547456417232752f, 0.003238451667129993f, 0.00665318313986063f,
    0.01164754293859005f, 0.01737609319388866f, 0.02208934165537357f, 0.02392910048365593f, 0.02208934165537357f,
    0.01737609319388866f, 0.01164754293859005f, 0.00665318313986063f, 0.003238451667129993f, 0.001455130288377404f,
    0.0035081731621176f, 0.00720730796456337f, 0.01261763460934162f, 0.0188232995569706f, 0.02392910048365593f,
    0.02592208795249462f, 0.02392910048365593f, 0.0188232995569706f, 0.01261763460934162f, 0.00720730796456337f,
    0.0035081731621176f, 0.001455130288377404f, 0.003238451667129993f, 0.00665318313986063f, 0.01164754293859005f,
    0.01737609319388866f, 0.02208934165537357f, 0.02392910048365593f, 0.02208934165537357f, 0.01737609319388866f,
    0.01164754293859005f, 0.00665318313986063f, 0.003238451667129993f, 0.002547456417232752f, 0.005233579315245152f,
    0.009162282571196556f, 0.01366852037608624f, 0.01737609319388866f, 0.0188232995569706f, 0.01737609319388866f,
    0.01366852037608624f, 0.009162282571196556f, 0.005233579315245152f, 0.002547456417232752f, 0.001707611023448408f,
    0.0035081731621176f, 0.006141661666333675f, 0.009162282571196556f, 0.01164754293859005f, 0.01261763460934162f,
    0.01164754293859005f, 0.009162282571196556f, 0.006141661666333675f, 0.0035081731621176f, 0.001707611023448408f,
    0.002003900473937392f, 0.0035081731621176f, 0.005233579315245152f, 0.00665318313986063f, 0.00720730796456337f,
    0.00665318313986063f, 0.005233579315245152f, 0.0035081731621176f, 0.002003900473937392f, 0.001707611023448408f,
    0.002547456417232752f, 0.003238451667129993f, 0.0035081731621176f, 0.003238451667129993f, 0.002547456417232752f,
    0.001707611023448408f, 0.001455130288377404f};

__constant float c_NX[2][5] = {{0, 0, 2, 4, -1}, {2, 0, 4, 4, 1}};
__constant float c_NY[2][5] = {{0, 0, 4, 2, 1}, {0, 2, 4, 4, -1}};

void reduce_32_sum(volatile __local  float * data, float partial_reduction, int tid)
{
#define op(A, B) (A)+(B)
    data[tid] = partial_reduction;
    barrier(CLK_LOCAL_MEM_FENCE);

    if (tid < 16)
    {
        data[tid] = partial_reduction = op(partial_reduction, data[tid + 16]);
        data[tid] = partial_reduction = op(partial_reduction, data[tid + 8 ]);
        data[tid] = partial_reduction = op(partial_reduction, data[tid + 4 ]);
        data[tid] = partial_reduction = op(partial_reduction, data[tid + 2 ]);
        data[tid] = partial_reduction = op(partial_reduction, data[tid + 1 ]);
    }
#undef op
}

__kernel
    void icvCalcOrientation(
    IMAGE_INT32 sumTex,
    __global float * keypoints,
    int keypoints_step,
    int c_img_rows,
    int c_img_cols,
    int sum_step
    )
{
    keypoints_step /= sizeof(*keypoints);
    sum_step       /= sizeof(uint);
    __global float* featureX    = keypoints + X_ROW * keypoints_step;
    __global float* featureY    = keypoints + Y_ROW * keypoints_step;
    __global float* featureSize = keypoints + SIZE_ROW * keypoints_step;
    __global float* featureDir  = keypoints + ANGLE_ROW * keypoints_step;


    volatile __local  float s_X[128];
    volatile __local  float s_Y[128];
    volatile __local  float s_angle[128];

    volatile __local  float s_sumx[32 * 4];
    volatile __local  float s_sumy[32 * 4];

    /* The sampling intervals and wavelet sized for selecting an orientation
    and building the keypoint descriptor are defined relative to 's' */
    const float s = featureSize[get_group_id(0)] * 1.2f / 9.0f;


    /* To find the dominant orientation, the gradients in x and y are
    sampled in a circle of radius 6s using wavelets of size 4s.
    We ensure the gradient wavelet size is even to ensure the
    wavelet pattern is balanced and symmetric around its center */
    const int grad_wav_size = 2 * convert_int_rte(2.0f * s);

    // check when grad_wav_size is too big
    if ((c_img_rows + 1) < grad_wav_size || (c_img_cols + 1) < grad_wav_size)
        return;

    // Calc X, Y, angle and store it to shared memory
    const int tid = get_local_id(1) * get_local_size(0) + get_local_id(0);

    float X = 0.0f, Y = 0.0f, angle = 0.0f;

    if (tid < ORI_SAMPLES)
    {
        const float margin = (float)(grad_wav_size - 1) / 2.0f;
        const int x = convert_int_rte(featureX[get_group_id(0)] + c_aptX[tid] * s - margin);
        const int y = convert_int_rte(featureY[get_group_id(0)] + c_aptY[tid] * s - margin);

        if (y >= 0 && y < (c_img_rows + 1) - grad_wav_size &&
            x >= 0 && x < (c_img_cols + 1) - grad_wav_size)
        {
            X = c_aptW[tid] * icvCalcHaarPatternSum_2(sumTex, c_NX, 4, grad_wav_size, y, x, c_img_rows, c_img_cols, sum_step);
            Y = c_aptW[tid] * icvCalcHaarPatternSum_2(sumTex, c_NY, 4, grad_wav_size, y, x, c_img_rows, c_img_cols, sum_step);

            angle = atan2(Y, X);

            if (angle < 0)
                angle += 2.0f * CV_PI_F;
            angle *= 180.0f / CV_PI_F;

        }
    }
    s_X[tid] = X;
    s_Y[tid] = Y;
    s_angle[tid] = angle;
    barrier(CLK_LOCAL_MEM_FENCE);

    float bestx = 0, besty = 0, best_mod = 0;

#pragma unroll
    for (int i = 0; i < 18; ++i)
    {
        const int dir = (i * 4 + get_local_id(1)) * ORI_SEARCH_INC;

        float sumx = 0.0f, sumy = 0.0f;
        int d = abs(convert_int_rte(s_angle[get_local_id(0)]) - dir);
        if (d < ORI_WIN / 2 || d > 360 - ORI_WIN / 2)
        {
            sumx = s_X[get_local_id(0)];
            sumy = s_Y[get_local_id(0)];
        }
        d = abs(convert_int_rte(s_angle[get_local_id(0) + 32]) - dir);
        if (d < ORI_WIN / 2 || d > 360 - ORI_WIN / 2)
        {
            sumx += s_X[get_local_id(0) + 32];
            sumy += s_Y[get_local_id(0) + 32];
        }
        d = abs(convert_int_rte(s_angle[get_local_id(0) + 64]) - dir);
        if (d < ORI_WIN / 2 || d > 360 - ORI_WIN / 2)
        {
            sumx += s_X[get_local_id(0) + 64];
            sumy += s_Y[get_local_id(0) + 64];
        }
        d = abs(convert_int_rte(s_angle[get_local_id(0) + 96]) - dir);
        if (d < ORI_WIN / 2 || d > 360 - ORI_WIN / 2)
        {
            sumx += s_X[get_local_id(0) + 96];
            sumy += s_Y[get_local_id(0) + 96];
        }
        reduce_32_sum(s_sumx + get_local_id(1) * 32, sumx, get_local_id(0));
        reduce_32_sum(s_sumy + get_local_id(1) * 32, sumy, get_local_id(0));

        const float temp_mod = sumx * sumx + sumy * sumy;
        if (temp_mod > best_mod)
        {
            best_mod = temp_mod;
            bestx = sumx;
            besty = sumy;
        }
        barrier(CLK_LOCAL_MEM_FENCE);
    }
    if (get_local_id(0) == 0)
    {
        s_X[get_local_id(1)] = bestx;
        s_Y[get_local_id(1)] = besty;
        s_angle[get_local_id(1)] = best_mod;
    }
    barrier(CLK_LOCAL_MEM_FENCE);

    if (get_local_id(1) == 0 && get_local_id(0) == 0)
    {
        int bestIdx = 0;

        if (s_angle[1] > s_angle[bestIdx])
            bestIdx = 1;
        if (s_angle[2] > s_angle[bestIdx])
            bestIdx = 2;
        if (s_angle[3] > s_angle[bestIdx])
            bestIdx = 3;

        float kp_dir = atan2(s_Y[bestIdx], s_X[bestIdx]);
        if (kp_dir < 0)
            kp_dir += 2.0f * CV_PI_F;
        kp_dir *= 180.0f / CV_PI_F;

        kp_dir = 360.0f - kp_dir;
        if (fabs(kp_dir - 360.f) < FLT_EPSILON)
            kp_dir = 0.f;

        featureDir[get_group_id(0)] = kp_dir;
    }
}

#undef ORI_SEARCH_INC
#undef ORI_WIN
#undef ORI_SAMPLES

////////////////////////////////////////////////////////////////////////
// Descriptors

#define PATCH_SZ 20

__constant float c_DW[PATCH_SZ * PATCH_SZ] =
{
    3.695352233989979e-006f, 8.444558261544444e-006f, 1.760426494001877e-005f, 3.34794785885606e-005f, 5.808438800158911e-005f, 9.193058212986216e-005f, 0.0001327334757661447f, 0.0001748319627949968f, 0.0002100782439811155f, 0.0002302826324012131f, 0.0002302826324012131f, 0.0002100782439811155f, 0.0001748319627949968f, 0.0001327334757661447f, 9.193058212986216e-005f, 5.808438800158911e-005f, 3.34794785885606e-005f, 1.760426494001877e-005f, 8.444558261544444e-006f, 3.695352233989979e-006f,
    8.444558261544444e-006f, 1.929736572492402e-005f, 4.022897701361217e-005f, 7.650675252079964e-005f, 0.0001327334903180599f, 0.0002100782585330308f, 0.0003033203829545528f, 0.0003995231236331165f, 0.0004800673632416874f, 0.0005262381164357066f, 0.0005262381164357066f, 0.0004800673632416874f, 0.0003995231236331165f, 0.0003033203829545528f, 0.0002100782585330308f, 0.0001327334903180599f, 7.650675252079964e-005f, 4.022897701361217e-005f, 1.929736572492402e-005f, 8.444558261544444e-006f,
    1.760426494001877e-005f, 4.022897701361217e-005f, 8.386484114453197e-005f, 0.0001594926579855382f, 0.0002767078403849155f, 0.0004379475140012801f, 0.0006323281559161842f, 0.0008328808471560478f, 0.001000790391117334f, 0.001097041997127235f, 0.001097041997127235f, 0.001000790391117334f, 0.0008328808471560478f, 0.0006323281559161842f, 0.0004379475140012801f, 0.0002767078403849155f, 0.0001594926579855382f, 8.386484114453197e-005f, 4.022897701361217e-005f, 1.760426494001877e-005f,
    3.34794785885606e-005f, 7.650675252079964e-005f, 0.0001594926579855382f, 0.0003033203247468919f, 0.0005262380582280457f, 0.0008328807889483869f, 0.001202550483867526f, 0.001583957928232849f, 0.001903285388834775f, 0.002086334861814976f, 0.002086334861814976f, 0.001903285388834775f, 0.001583957928232849f, 0.001202550483867526f, 0.0008328807889483869f, 0.0005262380582280457f, 0.0003033203247468919f, 0.0001594926579855382f, 7.650675252079964e-005f, 3.34794785885606e-005f,
    5.808438800158911e-005f, 0.0001327334903180599f, 0.0002767078403849155f, 0.0005262380582280457f, 0.0009129836107604206f, 0.001444985857233405f, 0.002086335094645619f, 0.002748048631474376f, 0.00330205773934722f, 0.003619635012000799f, 0.003619635012000799f, 0.00330205773934722f, 0.002748048631474376f, 0.002086335094645619f, 0.001444985857233405f, 0.0009129836107604206f, 0.0005262380582280457f, 0.0002767078403849155f, 0.0001327334903180599f, 5.808438800158911e-005f,
    9.193058212986216e-005f, 0.0002100782585330308f, 0.0004379475140012801f, 0.0008328807889483869f, 0.001444985857233405f, 0.002286989474669099f, 0.00330205773934722f, 0.004349356517195702f, 0.00522619066759944f, 0.005728822201490402f, 0.005728822201490402f, 0.00522619066759944f, 0.004349356517195702f, 0.00330205773934722f, 0.002286989474669099f, 0.001444985857233405f, 0.0008328807889483869f, 0.0004379475140012801f, 0.0002100782585330308f, 9.193058212986216e-005f,
    0.0001327334757661447f, 0.0003033203829545528f, 0.0006323281559161842f, 0.001202550483867526f, 0.002086335094645619f, 0.00330205773934722f, 0.004767658654600382f, 0.006279794964939356f, 0.007545807864516974f, 0.008271530270576477f, 0.008271530270576477f, 0.007545807864516974f, 0.006279794964939356f, 0.004767658654600382f, 0.00330205773934722f, 0.002086335094645619f, 0.001202550483867526f, 0.0006323281559161842f, 0.0003033203829545528f, 0.0001327334757661447f,
    0.0001748319627949968f, 0.0003995231236331165f, 0.0008328808471560478f, 0.001583957928232849f, 0.002748048631474376f, 0.004349356517195702f, 0.006279794964939356f, 0.008271529339253902f, 0.009939077310264111f, 0.01089497376233339f, 0.01089497376233339f, 0.009939077310264111f, 0.008271529339253902f, 0.006279794964939356f, 0.004349356517195702f, 0.002748048631474376f, 0.001583957928232849f, 0.0008328808471560478f, 0.0003995231236331165f, 0.0001748319627949968f,
    0.0002100782439811155f, 0.0004800673632416874f, 0.001000790391117334f, 0.001903285388834775f, 0.00330205773934722f, 0.00522619066759944f, 0.007545807864516974f, 0.009939077310264111f, 0.01194280479103327f, 0.01309141051024199f, 0.01309141051024199f, 0.01194280479103327f, 0.009939077310264111f, 0.007545807864516974f, 0.00522619066759944f, 0.00330205773934722f, 0.001903285388834775f, 0.001000790391117334f, 0.0004800673632416874f, 0.0002100782439811155f,
    0.0002302826324012131f, 0.0005262381164357066f, 0.001097041997127235f, 0.002086334861814976f, 0.003619635012000799f, 0.005728822201490402f, 0.008271530270576477f, 0.01089497376233339f, 0.01309141051024199f, 0.01435048412531614f, 0.01435048412531614f, 0.01309141051024199f, 0.01089497376233339f, 0.008271530270576477f, 0.005728822201490402f, 0.003619635012000799f, 0.002086334861814976f, 0.001097041997127235f, 0.0005262381164357066f, 0.0002302826324012131f,
    0.0002302826324012131f, 0.0005262381164357066f, 0.001097041997127235f, 0.002086334861814976f, 0.003619635012000799f, 0.005728822201490402f, 0.008271530270576477f, 0.01089497376233339f, 0.01309141051024199f, 0.01435048412531614f, 0.01435048412531614f, 0.01309141051024199f, 0.01089497376233339f, 0.008271530270576477f, 0.005728822201490402f, 0.003619635012000799f, 0.002086334861814976f, 0.001097041997127235f, 0.0005262381164357066f, 0.0002302826324012131f,
    0.0002100782439811155f, 0.0004800673632416874f, 0.001000790391117334f, 0.001903285388834775f, 0.00330205773934722f, 0.00522619066759944f, 0.007545807864516974f, 0.009939077310264111f, 0.01194280479103327f, 0.01309141051024199f, 0.01309141051024199f, 0.01194280479103327f, 0.009939077310264111f, 0.007545807864516974f, 0.00522619066759944f, 0.00330205773934722f, 0.001903285388834775f, 0.001000790391117334f, 0.0004800673632416874f, 0.0002100782439811155f,
    0.0001748319627949968f, 0.0003995231236331165f, 0.0008328808471560478f, 0.001583957928232849f, 0.002748048631474376f, 0.004349356517195702f, 0.006279794964939356f, 0.008271529339253902f, 0.009939077310264111f, 0.01089497376233339f, 0.01089497376233339f, 0.009939077310264111f, 0.008271529339253902f, 0.006279794964939356f, 0.004349356517195702f, 0.002748048631474376f, 0.001583957928232849f, 0.0008328808471560478f, 0.0003995231236331165f, 0.0001748319627949968f,
    0.0001327334757661447f, 0.0003033203829545528f, 0.0006323281559161842f, 0.001202550483867526f, 0.002086335094645619f, 0.00330205773934722f, 0.004767658654600382f, 0.006279794964939356f, 0.007545807864516974f, 0.008271530270576477f, 0.008271530270576477f, 0.007545807864516974f, 0.006279794964939356f, 0.004767658654600382f, 0.00330205773934722f, 0.002086335094645619f, 0.001202550483867526f, 0.0006323281559161842f, 0.0003033203829545528f, 0.0001327334757661447f,
    9.193058212986216e-005f, 0.0002100782585330308f, 0.0004379475140012801f, 0.0008328807889483869f, 0.001444985857233405f, 0.002286989474669099f, 0.00330205773934722f, 0.004349356517195702f, 0.00522619066759944f, 0.005728822201490402f, 0.005728822201490402f, 0.00522619066759944f, 0.004349356517195702f, 0.00330205773934722f, 0.002286989474669099f, 0.001444985857233405f, 0.0008328807889483869f, 0.0004379475140012801f, 0.0002100782585330308f, 9.193058212986216e-005f,
    5.808438800158911e-005f, 0.0001327334903180599f, 0.0002767078403849155f, 0.0005262380582280457f, 0.0009129836107604206f, 0.001444985857233405f, 0.002086335094645619f, 0.002748048631474376f, 0.00330205773934722f, 0.003619635012000799f, 0.003619635012000799f, 0.00330205773934722f, 0.002748048631474376f, 0.002086335094645619f, 0.001444985857233405f, 0.0009129836107604206f, 0.0005262380582280457f, 0.0002767078403849155f, 0.0001327334903180599f, 5.808438800158911e-005f,
    3.34794785885606e-005f, 7.650675252079964e-005f, 0.0001594926579855382f, 0.0003033203247468919f, 0.0005262380582280457f, 0.0008328807889483869f, 0.001202550483867526f, 0.001583957928232849f, 0.001903285388834775f, 0.002086334861814976f, 0.002086334861814976f, 0.001903285388834775f, 0.001583957928232849f, 0.001202550483867526f, 0.0008328807889483869f, 0.0005262380582280457f, 0.0003033203247468919f, 0.0001594926579855382f, 7.650675252079964e-005f, 3.34794785885606e-005f,
    1.760426494001877e-005f, 4.022897701361217e-005f, 8.386484114453197e-005f, 0.0001594926579855382f, 0.0002767078403849155f, 0.0004379475140012801f, 0.0006323281559161842f, 0.0008328808471560478f, 0.001000790391117334f, 0.001097041997127235f, 0.001097041997127235f, 0.001000790391117334f, 0.0008328808471560478f, 0.0006323281559161842f, 0.0004379475140012801f, 0.0002767078403849155f, 0.0001594926579855382f, 8.386484114453197e-005f, 4.022897701361217e-005f, 1.760426494001877e-005f,
    8.444558261544444e-006f, 1.929736572492402e-005f, 4.022897701361217e-005f, 7.650675252079964e-005f, 0.0001327334903180599f, 0.0002100782585330308f, 0.0003033203829545528f, 0.0003995231236331165f, 0.0004800673632416874f, 0.0005262381164357066f, 0.0005262381164357066f, 0.0004800673632416874f, 0.0003995231236331165f, 0.0003033203829545528f, 0.0002100782585330308f, 0.0001327334903180599f, 7.650675252079964e-005f, 4.022897701361217e-005f, 1.929736572492402e-005f, 8.444558261544444e-006f,
    3.695352233989979e-006f, 8.444558261544444e-006f, 1.760426494001877e-005f, 3.34794785885606e-005f, 5.808438800158911e-005f, 9.193058212986216e-005f, 0.0001327334757661447f, 0.0001748319627949968f, 0.0002100782439811155f, 0.0002302826324012131f, 0.0002302826324012131f, 0.0002100782439811155f, 0.0001748319627949968f, 0.0001327334757661447f, 9.193058212986216e-005f, 5.808438800158911e-005f, 3.34794785885606e-005f, 1.760426494001877e-005f, 8.444558261544444e-006f, 3.695352233989979e-006f
};

// utility for linear filter
inline uchar readerGet(
    IMAGE_INT8 src,
    const float centerX, const float centerY, const float win_offset, const float cos_dir, const float sin_dir,
    int i, int j, int rows, int cols, int elemPerRow
    )
{
    float pixel_x = centerX + (win_offset + j) * cos_dir + (win_offset + i) * sin_dir;
    float pixel_y = centerY - (win_offset + j) * sin_dir + (win_offset + i) * cos_dir;
    return read_imgTex(src, sampler, (float2)(pixel_x, pixel_y), rows, cols, elemPerRow);
}

inline float linearFilter(
    IMAGE_INT8 src,
    const float centerX, const float centerY, const float win_offset, const float cos_dir, const float sin_dir,
    float y, float x, int rows, int cols, int elemPerRow
    )
{
    x -= 0.5f;
    y -= 0.5f;

    float out = 0.0f;

    const int x1 = convert_int_rtn(x);
    const int y1 = convert_int_rtn(y);
    const int x2 = x1 + 1;
    const int y2 = y1 + 1;

    uchar src_reg = readerGet(src, centerX, centerY, win_offset, cos_dir, sin_dir, y1, x1, rows, cols, elemPerRow);
    out = out + src_reg * ((x2 - x) * (y2 - y));

    src_reg = readerGet(src, centerX, centerY, win_offset, cos_dir, sin_dir, y1, x2, rows, cols, elemPerRow);
    out = out + src_reg * ((x - x1) * (y2 - y));

    src_reg = readerGet(src, centerX, centerY, win_offset, cos_dir, sin_dir, y2, x1, rows, cols, elemPerRow);
    out = out + src_reg * ((x2 - x) * (y - y1));

    src_reg = readerGet(src, centerX, centerY, win_offset, cos_dir, sin_dir, y2, x2, rows, cols, elemPerRow);
    out = out + src_reg * ((x - x1) * (y - y1));

    return out;
}

void calc_dx_dy(
    IMAGE_INT8 imgTex,
    volatile __local  float s_dx_bin[25],
    volatile __local  float s_dy_bin[25],
    volatile __local  float s_PATCH[6][6],
    __global const float* featureX,
    __global const float* featureY,
    __global const float* featureSize,
    __global const float* featureDir,
    int rows,
    int cols,
    int elemPerRow
    )
{
    const float centerX = featureX[get_group_id(0)];
    const float centerY = featureY[get_group_id(0)];
    const float size = featureSize[get_group_id(0)];
    float descriptor_dir = 360.0f - featureDir[get_group_id(0)];
    if (fabs(descriptor_dir - 360.f) < FLT_EPSILON)
        descriptor_dir = 0.f;
    descriptor_dir *= (float)(CV_PI_F / 180.0f);

    /* The sampling intervals and wavelet sized for selecting an orientation
    and building the keypoint descriptor are defined relative to 's' */
    const float s = size * 1.2f / 9.0f;

    /* Extract a window of pixels around the keypoint of size 20s */
    const int win_size = (int)((PATCH_SZ + 1) * s);

    float sin_dir;
    float cos_dir;
    sin_dir = sincos(descriptor_dir, &cos_dir);

    /* Nearest neighbour version (faster) */
    const float win_offset = -(float)(win_size - 1) / 2;

    // Compute sampling points
    // since grids are 2D, need to compute xBlock and yBlock indices
    const int xBlock = (get_group_id(1) & 3);  // get_group_id(1) % 4
    const int yBlock = (get_group_id(1) >> 2); // floor(get_group_id(1)/4)
    const int xIndex = xBlock * 5 + get_local_id(0);
    const int yIndex = yBlock * 5 + get_local_id(1);

    const float icoo = ((float)yIndex / (PATCH_SZ + 1)) * win_size;
    const float jcoo = ((float)xIndex / (PATCH_SZ + 1)) * win_size;

    s_PATCH[get_local_id(1)][get_local_id(0)] = linearFilter(imgTex, centerX, centerY, win_offset, cos_dir, sin_dir, icoo, jcoo, rows, cols, elemPerRow);

    barrier(CLK_LOCAL_MEM_FENCE);

    if (get_local_id(0) < 5 && get_local_id(1) < 5)
    {
        const int tid = get_local_id(1) * 5 + get_local_id(0);

        const float dw = c_DW[yIndex * PATCH_SZ + xIndex];

        const float vx = (
            s_PATCH[get_local_id(1)    ][get_local_id(0) + 1] -
            s_PATCH[get_local_id(1)    ][get_local_id(0)    ] +
            s_PATCH[get_local_id(1) + 1][get_local_id(0) + 1] -
            s_PATCH[get_local_id(1) + 1][get_local_id(0)    ])
            * dw;
        const float vy = (
            s_PATCH[get_local_id(1) + 1][get_local_id(0)    ] -
            s_PATCH[get_local_id(1)    ][get_local_id(0)    ] +
            s_PATCH[get_local_id(1) + 1][get_local_id(0) + 1] -
            s_PATCH[get_local_id(1)    ][get_local_id(0) + 1])
            * dw;
        s_dx_bin[tid] = vx;
        s_dy_bin[tid] = vy;
    }
}
void reduce_sum25(
    volatile __local  float* sdata1,
    volatile __local  float* sdata2,
    volatile __local  float* sdata3,
    volatile __local  float* sdata4,
    int tid
    )
{
    // first step is to reduce from 25 to 16
    if (tid < 9) // use 9 threads
    {
        sdata1[tid] += sdata1[tid + 16];
        sdata2[tid] += sdata2[tid + 16];
        sdata3[tid] += sdata3[tid + 16];
        sdata4[tid] += sdata4[tid + 16];
    }

    // sum (reduce) from 16 to 1 (unrolled - aligned to a half-warp)
    if (tid < 8)
    {
        sdata1[tid] += sdata1[tid + 8];
        sdata1[tid] += sdata1[tid + 4];
        sdata1[tid] += sdata1[tid + 2];
        sdata1[tid] += sdata1[tid + 1];

        sdata2[tid] += sdata2[tid + 8];
        sdata2[tid] += sdata2[tid + 4];
        sdata2[tid] += sdata2[tid + 2];
        sdata2[tid] += sdata2[tid + 1];

        sdata3[tid] += sdata3[tid + 8];
        sdata3[tid] += sdata3[tid + 4];
        sdata3[tid] += sdata3[tid + 2];
        sdata3[tid] += sdata3[tid + 1];

        sdata4[tid] += sdata4[tid + 8];
        sdata4[tid] += sdata4[tid + 4];
        sdata4[tid] += sdata4[tid + 2];
        sdata4[tid] += sdata4[tid + 1];
    }
}

__kernel
    void compute_descriptors64(
    IMAGE_INT8 imgTex,
    volatile __global float * descriptors,
    __global const float * keypoints,
    int descriptors_step,
    int keypoints_step,
    int rows,
    int cols,
    int img_step
    )
{
    descriptors_step /= sizeof(float);
    keypoints_step   /= sizeof(float);
    __global const float * featureX    = keypoints + X_ROW * keypoints_step;
    __global const float * featureY    = keypoints + Y_ROW * keypoints_step;
    __global const float * featureSize = keypoints + SIZE_ROW * keypoints_step;
    __global const float * featureDir  = keypoints + ANGLE_ROW * keypoints_step;

    // 2 floats (dx,dy) for each thread (5x5 sample points in each sub-region)
    volatile __local  float sdx[25];
    volatile __local  float sdy[25];
    volatile __local  float sdxabs[25];
    volatile __local  float sdyabs[25];
    volatile __local  float s_PATCH[6][6];

    calc_dx_dy(imgTex, sdx, sdy, s_PATCH, featureX, featureY, featureSize, featureDir, rows, cols, img_step);
    barrier(CLK_LOCAL_MEM_FENCE);

    const int tid = get_local_id(1) * get_local_size(0) + get_local_id(0);

    if (tid < 25)
    {
        sdxabs[tid] = fabs(sdx[tid]); // |dx| array
        sdyabs[tid] = fabs(sdy[tid]); // |dy| array
        //barrier(CLK_LOCAL_MEM_FENCE);

        reduce_sum25(sdx, sdy, sdxabs, sdyabs, tid);
        //barrier(CLK_LOCAL_MEM_FENCE);

        volatile __global float* descriptors_block = descriptors + descriptors_step * get_group_id(0) + (get_group_id(1) << 2);

        // write dx, dy, |dx|, |dy|
        if (tid == 0)
        {
            descriptors_block[0] = sdx[0];
            descriptors_block[1] = sdy[0];
            descriptors_block[2] = sdxabs[0];
            descriptors_block[3] = sdyabs[0];
        }
    }
}
__kernel
    void compute_descriptors128(
    IMAGE_INT8 imgTex,
    __global volatile float * descriptors,
    __global float * keypoints,
    int descriptors_step,
    int keypoints_step,
    int rows,
    int cols,
    int img_step
    )
{
    descriptors_step /= sizeof(*descriptors);
    keypoints_step   /= sizeof(*keypoints);

    __global float * featureX   = keypoints + X_ROW * keypoints_step;
    __global float * featureY   = keypoints + Y_ROW * keypoints_step;
    __global float* featureSize = keypoints + SIZE_ROW * keypoints_step;
    __global float* featureDir  = keypoints + ANGLE_ROW * keypoints_step;

    // 2 floats (dx,dy) for each thread (5x5 sample points in each sub-region)
    volatile __local  float sdx[25];
    volatile __local  float sdy[25];

    // sum (reduce) 5x5 area response
    volatile __local  float sd1[25];
    volatile __local  float sd2[25];
    volatile __local  float sdabs1[25];
    volatile __local  float sdabs2[25];
    volatile __local  float s_PATCH[6][6];

    calc_dx_dy(imgTex, sdx, sdy, s_PATCH, featureX, featureY, featureSize, featureDir, rows, cols, img_step);
    barrier(CLK_LOCAL_MEM_FENCE);

    const int tid = get_local_id(1) * get_local_size(0) + get_local_id(0);

    if (tid < 25)
    {
        if (sdy[tid] >= 0)
        {
            sd1[tid] = sdx[tid];
            sdabs1[tid] = fabs(sdx[tid]);
            sd2[tid] = 0;
            sdabs2[tid] = 0;
        }
        else
        {
            sd1[tid] = 0;
            sdabs1[tid] = 0;
            sd2[tid] = sdx[tid];
            sdabs2[tid] = fabs(sdx[tid]);
        }
        //barrier(CLK_LOCAL_MEM_FENCE);

        reduce_sum25(sd1, sd2, sdabs1, sdabs2, tid);
        //barrier(CLK_LOCAL_MEM_FENCE);

        volatile __global float* descriptors_block = descriptors + descriptors_step * get_group_id(0) + (get_group_id(1) << 3);

        // write dx (dy >= 0), |dx| (dy >= 0), dx (dy < 0), |dx| (dy < 0)
        if (tid == 0)
        {
            descriptors_block[0] = sd1[0];
            descriptors_block[1] = sdabs1[0];
            descriptors_block[2] = sd2[0];
            descriptors_block[3] = sdabs2[0];
        }

        if (sdx[tid] >= 0)
        {
            sd1[tid] = sdy[tid];
            sdabs1[tid] = fabs(sdy[tid]);
            sd2[tid] = 0;
            sdabs2[tid] = 0;
        }
        else
        {
            sd1[tid] = 0;
            sdabs1[tid] = 0;
            sd2[tid] = sdy[tid];
            sdabs2[tid] = fabs(sdy[tid]);
        }
        //barrier(CLK_LOCAL_MEM_FENCE);

        reduce_sum25(sd1, sd2, sdabs1, sdabs2, tid);
        //barrier(CLK_LOCAL_MEM_FENCE);

        // write dy (dx >= 0), |dy| (dx >= 0), dy (dx < 0), |dy| (dx < 0)
        if (tid == 0)
        {
            descriptors_block[4] = sd1[0];
            descriptors_block[5] = sdabs1[0];
            descriptors_block[6] = sd2[0];
            descriptors_block[7] = sdabs2[0];
        }
    }
}

__kernel
    void normalize_descriptors128(__global float * descriptors, int descriptors_step)
{
    descriptors_step /= sizeof(*descriptors);
    // no need for thread ID
    __global float* descriptor_base = descriptors + descriptors_step * get_group_id(0);

    // read in the unnormalized descriptor values (squared)
    volatile __local  float sqDesc[128];
    const float lookup = descriptor_base[get_local_id(0)];
    sqDesc[get_local_id(0)] = lookup * lookup;
    barrier(CLK_LOCAL_MEM_FENCE);

    if (get_local_id(0) < 64)
        sqDesc[get_local_id(0)] += sqDesc[get_local_id(0) + 64];
    barrier(CLK_LOCAL_MEM_FENCE);

    // reduction to get total
    if (get_local_id(0) < 32)
    {
        volatile __local  float* smem = sqDesc;

        smem[get_local_id(0)] += smem[get_local_id(0) + 32];
        smem[get_local_id(0)] += smem[get_local_id(0) + 16];
        smem[get_local_id(0)] += smem[get_local_id(0) + 8];
        smem[get_local_id(0)] += smem[get_local_id(0) + 4];
        smem[get_local_id(0)] += smem[get_local_id(0) + 2];
        smem[get_local_id(0)] += smem[get_local_id(0) + 1];
    }

    // compute length (square root)
    volatile __local  float len;
    if (get_local_id(0) == 0)
    {
        len = sqrt(sqDesc[0]);
    }
    barrier(CLK_LOCAL_MEM_FENCE);

    // normalize and store in output
    descriptor_base[get_local_id(0)] = lookup / len;
}
__kernel
    void normalize_descriptors64(__global float * descriptors, int descriptors_step)
{
    descriptors_step /= sizeof(*descriptors);
    // no need for thread ID
    __global float* descriptor_base = descriptors + descriptors_step * get_group_id(0);

    // read in the unnormalized descriptor values (squared)
    volatile __local  float sqDesc[64];
    const float lookup = descriptor_base[get_local_id(0)];
    sqDesc[get_local_id(0)] = lookup * lookup;
    barrier(CLK_LOCAL_MEM_FENCE);

    // reduction to get total
    if (get_local_id(0) < 32)
    {
        volatile __local  float* smem = sqDesc;

        smem[get_local_id(0)] += smem[get_local_id(0) + 32];
        smem[get_local_id(0)] += smem[get_local_id(0) + 16];
        smem[get_local_id(0)] += smem[get_local_id(0) + 8];
        smem[get_local_id(0)] += smem[get_local_id(0) + 4];
        smem[get_local_id(0)] += smem[get_local_id(0) + 2];
        smem[get_local_id(0)] += smem[get_local_id(0) + 1];
    }

    // compute length (square root)
    volatile __local  float len;
    if (get_local_id(0) == 0)
    {
        len = sqrt(sqDesc[0]);
    }
    barrier(CLK_LOCAL_MEM_FENCE);

    // normalize and store in output
    descriptor_base[get_local_id(0)] = lookup / len;
}
