/************************************************************************
**
** NAME:        steganography.c
**
** DESCRIPTION: CS61C Fall 2020 Project 1
**
** AUTHOR:      Dan Garcia  -  University of California at Berkeley
**              Copyright (C) Dan Garcia, 2020. All rights reserved.
**				Justin Yokota - Starter Code
**				YOUR NAME HERE
**
** DATE:        2020-08-23
**
**************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include "imageloader.h"

//Determines what color the cell at the given row/col should be. This should not affect Image, and should allocate space for a new Color.
Color *evaluateOnePixel(Image *image, int row, int col)
{	
	// 异常值检查
	if(image == NULL || image->image == NULL || row >= image->rows || col >= image->cols || image->image[row] == NULL) return NULL;

	Color* pixel = (Color*)malloc(sizeof(Color));
	if(pixel == NULL) return NULL;

	if(image->image[row][col].B & 0x1){ // 最低位为1， 全部改为白色
		pixel->R = 255;
		pixel->G = 255;
		pixel->B = 255;
	}else{
		pixel->R = 0;
		pixel->G = 0;
		pixel->B = 0;
	}
	return pixel;
}

//Given an image, creates a new image extracting the LSB of the B channel.
Image *steganography(Image *image)
{	
	if(image == NULL || image->image == NULL) return NULL;

	Image* new_image = (Image*)malloc(sizeof(struct Image));
	if(new_image == NULL) return NULL;

	new_image->cols = image->cols;
	new_image->rows = image->rows;

	new_image->image = (Color**)malloc(new_image->rows * sizeof(struct Color*));
	if(new_image->image == NULL){
		free(new_image);
		return NULL;
	}for(int i = 0; i < new_image->rows; i++){
		new_image->image[i] = (Color*)malloc(new_image->cols * sizeof(Color));
		if(new_image->image[i] == NULL){
			while(i > 0){
				i--;
				free(new_image->image[i]);
			}
			free(new_image->image);
			free(new_image);
			return NULL;
		}
	}

	for(int y = 0; y < new_image->rows; y++){
		for(int x = 0; x < new_image->cols; x++){
			Color* pixel = evaluateOnePixel(image,y,x);
			if(pixel == NULL){
				freeImage(new_image);
				return NULL;
			}
			new_image->image[y][x] = *pixel;
			free(pixel);
		}
	}

	return new_image;
}	

/*
Loads a file of ppm P3 format from a file, and prints to stdout (e.g. with printf) a new image, 
where each pixel is black if the LSB of the B channel is 0, 
and white if the LSB of the B channel is 1.

argc stores the number of arguments.
argv stores a list of arguments. Here is the expected input:
argv[0] will store the name of the program (this happens automatically).
argv[1] should contain a filename, containing a file of ppm P3 format (not necessarily with .ppm file extension).
If the input is not correct, a malloc fails, or any other error occurs, you should exit with code -1.
Otherwise, you should return from main with code 0.
Make sure to free all memory before returning!
*/
int main(int argc, char **argv)
{	
	if(argc != 2 || argv[1] == NULL) return -1;

	// 读取ppm文件
	Image* image = readData(argv[1]);
	if(image == NULL) return -1;

	// 解码ppm文件
	Image* convert_image = steganography(image);
	if(convert_image == NULL){
		freeImage(image);
		return -1;
	};
	freeImage(image);

	writeData(convert_image);
	freeImage(convert_image);

	return 0;
}
