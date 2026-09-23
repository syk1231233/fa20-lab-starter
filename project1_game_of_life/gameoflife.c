/************************************************************************
**
** NAME:        gameoflife.c
**
** DESCRIPTION: CS61C Fall 2020 Project 1
**
** AUTHOR:      Justin Yokota - Starter Code
**				YOUR NAME HERE
**
**
** DATE:        2020-08-23
**
**************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include "imageloader.h"

int upgrade(uint8_t alive,uint8_t neighbors[8], uint32_t rule){
	int sumn = 0;
	for(int i = 0; i < 8; i++) sumn+=neighbors[i];
	int next = ((alive ? rule >> 9 : rule) >> sumn) & 0x1;
	return next;
}

//Determines what color the cell at the given row/col should be. This function allocates space for a new Color.
//Note that you will need to read the eight neighbors of the cell in question. The grid "wraps", so we treat the top row as adjacent to the bottom row
//and the left column as adjacent to the right column.
Color *evaluateOneCell(Image *image, int row, int col, uint32_t rule)
{
	if(image == NULL || image->image == NULL || row >= image->rows || col >= image->cols) return NULL;

	Color* pixel = (Color*)malloc(sizeof(Color));
	if(pixel == NULL) return NULL;
	pixel->R = 0; pixel->G = 0; pixel->B = 0;

	for(int bit = 0; bit < 8; bit++){
		//查看自己生死状态
		uint8_t r = (image->image[row][col].R >> bit) & 0x1;
		uint8_t g = (image->image[row][col].G >> bit) & 0x1;
		uint8_t b = (image->image[row][col].B >> bit) & 0x1;
		// 查看周围邻居数
		uint8_t nr[8], ng[8], nb[8];
		int count = 0;
		for(int dr = -1; dr <= 1; dr++){
			for(int dc = -1; dc <= 1; dc++){
				if(dr == 0 && dr == dc) continue;

				int nrow = (row + dr + image->rows) % image->rows;
				int ncol = (col + dc + image->cols) % image->cols;

				nr[count] = (image->image[nrow][ncol].R >> bit) & 0x1;
				ng[count] = (image->image[nrow][ncol].G >> bit) & 0x1;
				nb[count] = (image->image[nrow][ncol].B >> bit) & 0x1;
				count++;
			}
		}
		pixel->R |= (upgrade(r,nr,rule) << bit);
		pixel->G |= (upgrade(g,ng,rule) << bit);
		pixel->B |= (upgrade(b,nb,rule) << bit);
	}
	return pixel;
}

//The main body of Life; given an image and a rule, computes one iteration of the Game of Life.
//You should be able to copy most of this from steganography.c
Image *life(Image *image, uint32_t rule)
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
			Color* pixel = evaluateOneCell(image,y,x,rule);
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
Loads a .ppm from a file, computes the next iteration of the game of life, then prints to stdout the new image.

argc stores the number of arguments.
argv stores a list of arguments. Here is the expected input:
argv[0] will store the name of the program (this happens automatically).
argv[1] should contain a filename, containing a .ppm.
argv[2] should contain a hexadecimal number (such as 0x1808). Note that this will be a string.
You may find the function strtol useful for this conversion.
If the input is not correct, a malloc fails, or any other error occurs, you should exit with code -1.
Otherwise, you should return from main with code 0.
Make sure to free all memory before returning!

You may find it useful to copy the code from steganography.c, to start.
*/
int main(int argc, char **argv)
{	
	if (argc != 3) {
    printf("usage: %s filename rule\n", argv[0]);
    printf("filename is an ASCII PPM file (type P3) with maximum value 255.\n");
    printf("rule is a hex number beginning with 0x; Life is 0x1808.\n");
    return -1;
	}

	// 读取ppm文件
	Image* image = readData(argv[1]);
	if(image == NULL) return -1;

	// 读取规则
	uint32_t rule = (uint32_t)strtol(argv[2], NULL, 16);

	// 解码ppm文件
	Image* convert_image = life(image,rule);
	if(convert_image == NULL){
		freeImage(image);
		return -1;
	};
	freeImage(image);

	writeData(convert_image);
	freeImage(convert_image);

	return 0;
}
