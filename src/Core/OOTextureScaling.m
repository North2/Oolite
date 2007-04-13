/*

OOTextureScaling.m

Oolite
Copyright (C) 2004-2007 Giles C Williams and contributors

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301, USA.

*/


#import "OOTextureScaling.h"
#import "OOFunctionAttributes.h"
#import <math.h>
#import <stdlib.h>
#import "OOLogging.h"


uint8_t *ScaleUpPixMap(uint8_t *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcBytesPerRow, unsigned planes, unsigned dstWidth, unsigned dstHeight)
{
	uint8_t			*texBytes;
	int				x, y, n;
	float			texel_w, texel_h;
	float			y_lo, y_hi, x_lo, x_hi;
	int				y0, y1, x0, x1, acc;
	float			py0, py1, px0, px1;
	int				xy00, xy01, xy10, xy11;
	int				texi = 0;
	
	if (EXPECT_NOT(srcPixels == NULL)) return NULL;
	texBytes = malloc(dstWidth * dstHeight * planes);
	if (EXPECT_NOT(texBytes == NULL)) return NULL;
	
//	OOLog(@"image.scale.up", @"Scaling up %u planes from %ux%u to %ux%u", planes, srcWidth, srcHeight, dstWidth, dstHeight);

	// do bilinear scaling
	texel_w = (float)srcWidth / (float)dstWidth;
	texel_h = (float)srcHeight / (float)dstHeight;

	for ( y = 0; y < dstHeight; y++)
	{
		y_lo = texel_h * y;
		y_hi = y_lo + texel_h - 0.001f;
		y0 = floor(y_lo);
		y1 = floor(y_hi);

		py0 = 1.0f;
		py1 = 0.0f;
		if (y1 > y0)
		{
			py0 = (y1 - y_lo) / texel_h;
			py1 = 1.0f - py0;
		}

		for ( x = 0; x < dstWidth; x++)
		{
			x_lo = texel_w * x;
			x_hi = x_lo + texel_w - 0.001f;
			x0 = floor(x_lo);
			x1 = floor(x_hi);
			acc = 0;

			px0 = 1.0f;
			px1 = 0.0f;
			if (x1 > x0)
			{
				px0 = (x1 - x_lo) / texel_w;
				px1 = 1.0f - px0;
			}

			xy00 = y0 * srcBytesPerRow + planes * x0;
			xy01 = y0 * srcBytesPerRow + planes * x1;
			xy10 = y1 * srcBytesPerRow + planes * x0;
			xy11 = y1 * srcBytesPerRow + planes * x1;
			
			// SLOW_CODE This is a bottleneck. Should be reimplemented without float maths or, better, using an optimized library. -- ahruman
			for (n = 0; n < planes; n++)
			{
				acc = py0 * (px0 * srcPixels[ xy00 + n] + px1 * srcPixels[ xy10 + n])
					+ py1 * (px0 * srcPixels[ xy01 + n] + px1 * srcPixels[ xy11 + n]);
				texBytes[texi++] = (char)acc;	// float -> char
			}
		}
	}
	
	return texBytes;
}


static void ScaleUpHorizontally(const uint8_t *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, uint8_t *dstPixels, unsigned dstWidth);
static void ScaleDownHorizontally(const uint8_t *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, uint8_t *dstPixels, unsigned dstWidth);
static void ScaleUpVertically(const uint8_t *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, uint8_t *dstPixels, unsigned dstHeight);
static void ScaleDownVertically(const uint8_t *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, uint8_t *dstPixels, unsigned dstHeight);
static void CopyRows(const uint8_t *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, uint8_t *dstPixels);


void ScalePixMap(void *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, void *dstPixels, unsigned dstWidth, unsigned dstHeight)
{
	// Divide and conquer - handle horizontal and vertical resizing in separate passes.
	
	void			*interData;
	unsigned		interWidth, interHeight, interRowBytes;
	
	// Sanity checks
	if (EXPECT_NOT(srcWidth == 0 || srcHeight == 0 || srcPixels == NULL || dstPixels == NULL || srcRowBytes < srcWidth * 4)) return;
	
	// Scale horizontally, if needed
	if (srcWidth < dstWidth)
	{
		ScaleUpHorizontally(srcPixels, srcWidth, srcHeight, srcRowBytes, dstPixels, dstWidth);
		interData = dstPixels;
		interWidth = dstWidth;
		interHeight = dstHeight;
		interRowBytes = interWidth * 4;
	}
	else if (dstWidth < srcWidth)
	{
		ScaleDownHorizontally(srcPixels, srcWidth, srcHeight, srcRowBytes, dstPixels, dstWidth);
		interData = dstPixels;
		interWidth = dstWidth;
		interHeight = dstHeight;
		interRowBytes = interWidth * 4;
	}
	else
	{
		interData = srcPixels;
		interWidth = srcWidth;
		interHeight = srcHeight;
		interRowBytes = srcRowBytes;
	}
	
	// Scale vertically, if needed.
	if (srcHeight < dstHeight)
	{
		ScaleUpVertically(interData, interWidth, interHeight, interRowBytes, dstPixels, dstHeight);
	}
	else if (dstHeight < srcHeight)
	{
		ScaleDownVertically(interData, interWidth, interHeight, interRowBytes, dstPixels, dstHeight);
	}
	else
	{
		// This handles the no-scaling case as well as the horizontal-scaling-only case.
		CopyRows(interData, interWidth, interHeight, interRowBytes, dstPixels);
	}
}


void ScaleNormalMap(void *srcTexels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, void *dstTexels, unsigned dstWidth, unsigned dstHeight)
{
	ScalePixMap(srcTexels, srcWidth, srcHeight, srcRowBytes, dstTexels, dstWidth, dstHeight);
}


void GenerateMipMaps(void *textureBytes, unsigned width, unsigned height)
{
	
}


void GenerateNormalMapMipMaps(void *textureBytes, unsigned width, unsigned height)
{
	
}


static void ScaleUpHorizontally(const uint8_t *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, uint8_t *dstPixels, unsigned dstWidth)
{
	// TODO
}


static void ScaleDownHorizontally(const uint8_t *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, uint8_t *dstPixels, unsigned dstWidth)
{
	// TODO
}


static void ScaleUpVertically(const uint8_t *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, uint8_t *dstPixels, unsigned dstHeight)
{
	// TODO
}


static void ScaleDownVertically(const uint8_t *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, uint8_t *dstPixels, unsigned dstHeight)
{
	// TODO
}


static void CopyRows(const uint8_t *srcPixels, unsigned srcWidth, unsigned srcHeight, unsigned srcRowBytes, uint8_t *dstPixels)
{
	unsigned			y;
	unsigned			rowBytes;
	
	rowBytes = srcWidth * 4;
	
	if (rowBytes == srcRowBytes)
	{
		memcpy(dstPixels, srcPixels, srcHeight * rowBytes);
		return;
	}
	
	for (y = 0; y != srcHeight; ++y)
	{
		__builtin_memcpy(dstPixels, srcPixels, rowBytes);
		dstPixels += rowBytes;
		srcPixels += rowBytes;
	}
}
