/*
* starter_video.cpp
*
*  Created on: Nov 23, 2010
*      Author: Ethan Rublee
*
* A starter sample for using opencv, get a video stream and display the images
* easy as CV_PI right?
*/
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/core/core.hpp"
#include <iostream>
#include <vector>
#include <stdio.h>

using namespace cv;
using namespace std;

const int FRAME_COUNT = 25;

int main(int ac, char** av) {
    std::string arg = av[1];
    VideoCapture capture(arg); //try to open string, this will attempt to open it as a video file
    if (!capture.isOpened()) //if this fails, try to open as a video camera, through the use of an integer param
        capture.open(atoi(arg.c_str()));
    if (!capture.isOpened()) {
        cerr << "Failed to open a video device or video file!\n" << endl;
        return 1;
    }
    else
    {
        printf("VideoCapture opened successfuly\n");
    }

    Mat frame;

    for (int i = 0; i < 10; i++)
        capture >> frame;
    
    imwrite("d:\\test.jpg", frame);

    int64 before = getTickCount();
    for (int i = 0; i < FRAME_COUNT; i++)
    {
        capture >> frame;
    }

    int64 after = getTickCount();
    if (getTickFrequency() != 0)
        printf("Frame count: %d\n FPS: %f\n", FRAME_COUNT, 1.f*FRAME_COUNT*getTickFrequency()/((float)(after-before)));
    else
        printf("getTickFrequency returns zero\n");

    return 0;
}
