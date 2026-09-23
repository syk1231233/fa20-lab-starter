/************************************************************************
**
** NAME:        imageloader.c
**
** DESCRIPTION: CS61C Fall 2020 Project 1
**
** AUTHOR:      Dan Garcia  -  University of California at Berkeley
**              Copyright (C) Dan Garcia, 2020. All rights reserved.
**              Justin Yokota - Starter Code
**				leo			  
**
**
** DATE:        2020-08-15
**
**************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <string.h>
#include "imageloader.h"

/* pmm文件格式
    输出数据格式     前三行固定格式， 像素点格式 r g b，颜色值之间间隔一个空格， 一个颜色值3字符占位
P3                                  像素之间3空格间隔， 行尾换行符
[cols] [rows]                       文件末尾需要有一个换行符
255
  0   0   0     0   0   0     0   0   0     0   0   0
255 255 255   255 255 255   255 255 255     0   0   0
  0   0   0     0   0   0     0   0   0     0   0   0
  0   0   0     0   0   0     0   0   0     0   0   0
  0   0   0     0   0   0     0   0   0     0   0   0
*/
/* typedef struct Color 
{
	uint8_t R;
	uint8_t G;
	uint8_t B;
} Color;

typedef struct Image
{
	Color **image;
	uint32_t rows;
	uint32_t cols;
} Image;
*/
//读取一个ppm文件， 构建一个image结构体
//fscanf(buf,&num) to store in buf
//Make sure that you close the file with fclose before returning.

Image *readData(char *filename) 
{	
	char buf[20];
	FILE* fp = fopen(filename,"r");
	if(fp == NULL) return NULL;

	// 检察文件类型是否为p3
	if(fscanf(fp,"%19s", buf) != 1){
		fclose(fp);
		return NULL;
	}
	if(strcmp(buf, "P3") != 0){
		fclose(fp);
		return NULL;
	}
	
	Image* image = (Image*)malloc(sizeof(struct Image));
	if(image == NULL){
		fclose(fp);
		return NULL;
	}

	//获取图片大小并分配内存
	if(fscanf(fp,"%u %u",&image->cols,&image->rows) != 2){
		free(image);
		fclose(fp);
		return NULL;
	}
	image->image = (Color**)malloc(image->rows * sizeof(struct Color*));
	if(image->image == NULL){
		free(image);
		fclose(fp);
		return NULL;
	}for(int i = 0; i < image->rows; i++){
		image->image[i] = (Color*)malloc(image->cols * sizeof(Color));
		if(image->image[i] == NULL){
			while(i > 0){
				i--;
				free(image->image[i]);
			}
			free(image->image);
			free(image);
			fclose(fp);
			return NULL;
		}
	}

	//检察灰度范围
	int scale;
	if((fscanf(fp, "%d", &scale) != 1) || scale != 255){
		freeImage(image);
		fclose(fp);
		return NULL;
	}

	for(int y = 0; y < image->rows; y++){
		for(int x = 0; x < image->cols; x++){
			if(fscanf(fp,"%hhu %hhu %hhu",&image->image[y][x].R,&image->image[y][x].G,&image->image[y][x].B) != 3){
				freeImage(image);
				fclose(fp);
				return NULL;
			}
		}
	}

	fclose(fp);
	return image;
}

//Given an image, prints to stdout (e.g. with printf) a .ppm P3 file with the image's data.
//将一个image结构体以ppm格式写入标准输出流
void writeData(Image *image)
{
	if(image == NULL || image->image == NULL) return ;
	for(int i = 0; i < image->rows; i++){
		if(image->image[i] == NULL) return ;
	}

	//输出文件格式
	printf("P3\n");
	//输出列数行数
	printf("%u %u\n",image->cols, image->rows);
	//输出灰度值范围
	printf("255\n");
	//输出颜色值
	for(int y = 0; y < image->rows; y++){
		for(int x = 0; x < image->cols; x++){
			printf("%3u %3u %3u",image->image[y][x].R,image->image[y][x].G,image->image[y][x].B);
			if(x != image->cols - 1) printf("   ");
		}
		printf("\n");
	}
}

//Frees an image
void freeImage(Image *image)
{	
	if(image == NULL) return ;

	if(image->image == NULL){
		free(image);
		return ;
	}

	for(int i = 0; i < image->rows; i++){
    	free(image->image[i]);
	}
	free(image->image);
	free(image);
}