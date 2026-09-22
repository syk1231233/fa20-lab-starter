PART A1:
imageloader.c 图像加载器
完成转换后的结构体与ppm文件转化组件
    readData: 从ppm文件读取一个image结构体
    freeImage: 释放一个image结构体
    writeData: 将一个image结构体以ppm格式写入标准输出流
wirteData格式要求：
    输出数据格式     前三行固定格式， 像素点格式 r g b，颜色值之间间隔一个空格， 一个颜色值3字符占位
P3                                  像素之间3空格间隔， 行尾换行符
[cols] [rows]                       文件末尾需要有一个换行符
255
  0   0   0     0   0   0     0   0   0     0   0   0
255 255 255   255 255 255   255 255 255     0   0   0
  0   0   0     0   0   0     0   0   0     0   0   0
  0   0   0     0   0   0     0   0   0     0   0   0
  0   0   0     0   0   0     0   0   0     0   0   0

PART A2:
steganography.c 图像解码器
接受一个.ppm 文件作为输入，然后输出一个对应的“解码后”的图像。
将彩色图映射为黑白图，规定颜色值b最低位0为黑色（0，0，0）， 1为白色（255，255，255）
    evaluateOnePixel:
    steganography:
    main:

PART B:
    