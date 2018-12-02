

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "device_functions.h"

#include <string>
#include <cstdio>
#include <iterator>
#include <iostream>
#include <random>
#include <chrono>
#include <memory>
#include <functional>
#include<cuda.h>
#include<cuda_runtime.h>
#include <gl/glew.h>
#include <gl/GL.h>
#include <gl/freeglut.h>

#pragma comment(lib, "glew32.lib")
#include <iostream>
#include <ctime>
#include <Windows.h>
#include<device_launch_parameters.h>


using namespace std;

#define LEN 40


float arrayOfFishes[5 * LEN * LEN];

using namespace std;

__host__ __device__
float getAngle(float x1, float y1, float x2, float y2) {
	float value = x1 * x2 + y1 * y2;
	value = value != 0 ? value / sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2)) : 0;
	return 180 - atan2(-y1, x1) * 57.0;
}

__host__ __device__
float vectorMultiply(float x1, float y1, float x2, float y2) {
	float value = x1 * x2 + y1 * y2;
	value = value != 0 ? value / sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2)) : 0;
	return value;
}

__host__ __device__
float getVectorLength(float x1, float y1, float x2, float y2) {
	return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
}

void defineFishes() {
	int numberOfFishesInRow = LEN;
	for (int i = 0; i < numberOfFishesInRow; i++) {
		for (int j = 0; j < numberOfFishesInRow * 5; j += 5) {
			arrayOfFishes[i * numberOfFishesInRow * 5 + j] = i * numberOfFishesInRow * 5 + j;
			arrayOfFishes[i * numberOfFishesInRow * 5 + j + 1] = -1.0f;
			arrayOfFishes[i * numberOfFishesInRow * 5 + j + 2] = 0.0f;
			arrayOfFishes[i * numberOfFishesInRow * 5 + j + 3] = 0.9f + i * -0.1f;
			arrayOfFishes[i * numberOfFishesInRow * 5 + j + 4] = 0.9f + j * -0.1f;
		}
	}
}
float* getArrayOfFishes() {
	return arrayOfFishes;
}
__host__
void updateInNeighborhoud(int x, int y) {
	float nei = 0.2;
	float neiClose = 0.1;
	int friends[LEN * LEN];
	int toClose[LEN * LEN];
	int friendsInd = 0;
	int toCloseInd = 0;
	float currentId = arrayOfFishes[x * LEN * 5 + y];
	float currentDirX = arrayOfFishes[x * LEN * 5 + y + 1];
	float currentDirY = arrayOfFishes[x * LEN * 5 + y + 2];
	float currentX = arrayOfFishes[x * LEN * 5 + y + 3];
	float currentY = arrayOfFishes[x * LEN * 5 + y + 4];

	for (int i = 0; i < LEN; i++) {
		for (int j = 0; j < 5 * LEN; j += 5) {
			float sFishId = arrayOfFishes[i * LEN * 5 + j];
			float sFishDirX = arrayOfFishes[i * LEN * 5 + j + 1];
			float sFishDirY = arrayOfFishes[i * LEN * 5 + j + 2];
			float sFishX = arrayOfFishes[i * LEN * 5 + j + 3];
			float sFishY = arrayOfFishes[i * LEN * 5 + j + 4];

			if (getVectorLength(sFishX, sFishY, currentX, currentY) < nei
				&& currentId != sFishId
				&& vectorMultiply(sFishX - currentX, sFishY - currentY, currentDirX, currentDirY) > 0) {
				friends[friendsInd++] = (i * LEN * 5 + j);
			}
			if (getVectorLength(sFishX, sFishY, currentX, currentY) < neiClose
				&& currentId != sFishId
				&& vectorMultiply(sFishX - currentX, sFishY - currentY, currentDirX, currentDirY) > 0) {
				toClose[toCloseInd++] = (i * LEN * 5 + j);
			}
		}
	}
	float dirXNew = 0.0;
	float posNewX = 0.0;
	float posNewY = 0.0;
	float dirYNew = 0.0;
	float awayFromX = 0.0;
	float awayFromY = 0.0;
	for (int i = 0; i < friendsInd; i++) {
		dirXNew += arrayOfFishes[friends[i] + 1];
		dirYNew += arrayOfFishes[friends[i] + 2];

		posNewX += arrayOfFishes[friends[i] + 3];
		posNewY += arrayOfFishes[friends[i] + 4];

	}
	for (int i = 0; i < toCloseInd; i++) {
		awayFromX += currentX - arrayOfFishes[friends[i] + 3];
		awayFromY += currentY - arrayOfFishes[friends[i] + 4];
	}
	if (friendsInd == 0) {
		return;
	}
	if (toCloseInd == 0) {
		currentDirX += (dirXNew / (float)friendsInd) * 0.1;
		currentDirY += (dirYNew / (float)friendsInd) * 0.1;
		currentDirX += (posNewX / (float)friendsInd) * 0.05;
		currentDirY += (posNewY / (float)friendsInd) * 0.05;
	}
	else {
		currentDirX += (awayFromX / (float)friendsInd) * 5;
		currentDirY += (awayFromY / (float)friendsInd) * 5;
	}
	float vecLen = sqrt(pow(currentDirX, 2) + pow(currentDirY, 2));
	currentDirX /= vecLen;
	currentDirY /= vecLen;
	/*if (toClose.size() != 0) {
		current.x += current.dirX * 0.005;
		current.y += current.dirY * 0.005;
	}*/
	arrayOfFishes[x * LEN * 5 + y] = currentId;
	arrayOfFishes[x * LEN * 5 + y + 1] = currentDirX;
	arrayOfFishes[x * LEN * 5 + y + 2] = currentDirY;
	arrayOfFishes[x * LEN * 5 + y + 3] = currentX;
	arrayOfFishes[x * LEN * 5 + y + 4] = currentY;

}

__device__
void updateInNeighborhoudGpu(float *d_arrayOfFishes, int ind) {
	float nei = 0.2;
	float neiClose = 0.1;
	int friends[LEN * LEN];
	int toClose[LEN * LEN];
	int friendsInd = 0;
	int toCloseInd = 0;
	float currentId = d_arrayOfFishes[ind];
	float currentDirX = d_arrayOfFishes[ind + 1];
	float currentDirY = d_arrayOfFishes[ind + 2];
	float currentX = d_arrayOfFishes[ind + 3];
	float currentY = d_arrayOfFishes[ind + 4];

	for (int i = 0; i < LEN; i++) {
		for (int j = 0; j < 5 * LEN; j += 5) {
			float sFishId = d_arrayOfFishes[i * LEN * 5 + j];
			float sFishDirX = d_arrayOfFishes[i * LEN * 5 + j + 1];
			float sFishDirY = d_arrayOfFishes[i * LEN * 5 + j + 2];
			float sFishX = d_arrayOfFishes[i * LEN * 5 + j + 3];
			float sFishY = d_arrayOfFishes[i * LEN * 5 + j + 4];

			if (getVectorLength(sFishX, sFishY, currentX, currentY) < nei
				&& currentId != sFishId
				&& vectorMultiply(sFishX - currentX, sFishY - currentY, currentDirX, currentDirY) > 0) {
				friends[friendsInd++] = (i * LEN * 5 + j);
			}
			if (getVectorLength(sFishX, sFishY, currentX, currentY) < neiClose
				&& currentId != sFishId
				&& vectorMultiply(sFishX - currentX, sFishY - currentY, currentDirX, currentDirY) > 0) {
				toClose[toCloseInd++] = (i * LEN * 5 + j);
			}
		}
	}
	float dirXNew = 0.0;
	float posNewX = 0.0;
	float posNewY = 0.0;
	float dirYNew = 0.0;
	float awayFromX = 0.0;
	float awayFromY = 0.0;
	for (int i = 0; i < friendsInd; i++) {
		dirXNew += d_arrayOfFishes[friends[i] + 1];
		dirYNew += d_arrayOfFishes[friends[i] + 2];

		posNewX += d_arrayOfFishes[friends[i] + 3];
		posNewY += d_arrayOfFishes[friends[i] + 4];

	}
	for (int i = 0; i < toCloseInd; i++) {
		awayFromX += currentX - d_arrayOfFishes[friends[i] + 3];
		awayFromY += currentY - d_arrayOfFishes[friends[i] + 4];
	}
	if (friendsInd == 0) {
		return;
	}
	if (toCloseInd == 0) {
		currentDirX += (dirXNew / (float)friendsInd) * 0.1;
		currentDirY += (dirYNew / (float)friendsInd) * 0.1;
		currentDirX += (posNewX / (float)friendsInd) * 0.05;
		currentDirY += (posNewY / (float)friendsInd) * 0.05;
	}
	else {
		currentDirX += (awayFromX / (float)friendsInd) * 5;
		currentDirY += (awayFromY / (float)friendsInd) * 5;
	}
	float vecLen = sqrt(pow(currentDirX, 2) + pow(currentDirY, 2));
	currentDirX /= vecLen;
	currentDirY /= vecLen;
	/*if (toClose.size() != 0) {
		current.x += current.dirX * 0.005;
		current.y += current.dirY * 0.005;
	}*/
	d_arrayOfFishes[ind] = currentId;
	d_arrayOfFishes[ind + 1] = currentDirX;
	d_arrayOfFishes[ind + 2] = currentDirY;
	d_arrayOfFishes[ind + 3] = currentX;
	d_arrayOfFishes[ind + 4] = currentY;

}

__global__
void updateShoalGpu(float *d_arrayOfFishes ) {
	const long numThreads = blockDim.x * gridDim.x;
	const long threadID = blockIdx.x * blockDim.x + threadIdx.x;

	for (int i = threadID; i < LEN * LEN * 5; i += numThreads + 5) {
		float sFishId = d_arrayOfFishes[i];
		float sFishDirX = d_arrayOfFishes[i + 1];
		float sFishDirY = d_arrayOfFishes[i + 2];
		float sFishX = d_arrayOfFishes[i + 3];
		float sFishY = d_arrayOfFishes[i + 4];


		if (sFishX <= -0.9 && sFishDirX < 0) {
			sFishDirX = -sFishDirX;
			sFishX += sFishDirX * 0.01;
			sFishY += sFishDirY * 0.01;
			//sFishdirY = 1.0;
		}
		if (sFishX >= 0.9 && sFishDirX > 0) {
			sFishDirX = -sFishDirX;
			sFishX += sFishDirX * 0.01;
			sFishY += sFishDirY * 0.01;
			//sFishdirY = -1.0;
		}
		if (sFishY <= -0.9 && sFishDirY < 0) {
			//sFishdirX = -1.0;
			sFishDirY = -sFishDirY;
			sFishX += sFishDirX * 0.01;
			sFishY += sFishDirY * 0.01;
		}
		if (sFishY >= 0.9 && sFishDirY > 0) {
			//sFishdirX = 1.0;
			sFishDirY = -sFishDirY;
			sFishX += sFishDirX * 0.01;
			sFishY += sFishDirY * 0.01;
		}
		sFishX += sFishDirX * 0.005;
		sFishY += sFishDirY * 0.005;

		d_arrayOfFishes[i] = sFishId;
		d_arrayOfFishes[i + 1] = sFishDirX;
		d_arrayOfFishes[i + 2] = sFishDirY;
		d_arrayOfFishes[i + 3] = sFishX;
		d_arrayOfFishes[i + 4] = sFishY;

	}
	for (int i = threadID; i < LEN * LEN * 5; i += numThreads + 5) 
	{
		updateInNeighborhoudGpu(d_arrayOfFishes, i);
	}
}


void updateShoal() {
	for (int i = 0; i < LEN * LEN * 5; i += 5) {
		float sFishId = arrayOfFishes[i];
		float sFishDirX = arrayOfFishes[i + 1];
		float sFishDirY = arrayOfFishes[i + 2];
		float sFishX = arrayOfFishes[i + 3];
		float sFishY = arrayOfFishes[i + 4];


		if (sFishX <= -0.9 && sFishDirX < 0) {
			sFishDirX = -sFishDirX;
			sFishX += sFishDirX * 0.01;
			sFishY += sFishDirY * 0.01;
			//sFishdirY = 1.0;
		}
		if (sFishX >= 0.9 && sFishDirX > 0) {
			sFishDirX = -sFishDirX;
			sFishX += sFishDirX * 0.01;
			sFishY += sFishDirY * 0.01;
			//sFishdirY = -1.0;
		}
		if (sFishY <= -0.9 && sFishDirY < 0) {
			//sFishdirX = -1.0;
			sFishDirY = -sFishDirY;
			sFishX += sFishDirX * 0.01;
			sFishY += sFishDirY * 0.01;
		}
		if (sFishY >= 0.9 && sFishDirY > 0) {
			//sFishdirX = 1.0;
			sFishDirY = -sFishDirY;
			sFishX += sFishDirX * 0.01;
			sFishY += sFishDirY * 0.01;
		}
		sFishX += sFishDirX * 0.005;
		sFishY += sFishDirY * 0.005;

		arrayOfFishes[i] = sFishId;
		arrayOfFishes[i + 1] = sFishDirX;
		arrayOfFishes[i + 2] = sFishDirY;
		arrayOfFishes[i + 3] = sFishX;
		arrayOfFishes[i + 4] = sFishY;

	}
	for (int i = 0; i < LEN; i++) {
		for (int j = 0; j < 5 * LEN; j += 5) {
			int place = i * LEN * 5 + j;
			updateInNeighborhoud(i, j);
		}
	}
}

void changeViewPort(int w, int h)
{
	glViewport(0, 0, w, h);
}

void renderTriangle() {

	glColor3f(255.0 / 255.0, 204.0 / 255.0, 0.0 / 255.0);

	glVertex3f(-0.75, 0.5, 0.0);
	glVertex3f(1.0, 0.0, 0.0);
	glVertex3f(1.0, 1.0, 0.0);

}

void renderShoal() {
	float scale = 0.015;
	int  numberOfFishesInRow = LEN;
	float* fishes = getArrayOfFishes();
	for (int i = 0; i < LEN * LEN * 5; i += 5) {

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glTranslatef(fishes[i + 3], fishes[i + 4], 0.0);
		float angle = getAngle(fishes[i + 1], fishes[i + 2], 1, 0);
		glRotatef(angle, 0, 0, 1);
		glScalef(scale, scale, scale);

		glBegin(GL_POLYGON);
		renderTriangle();
		glEnd();
	}
	//glFlush();
}//
void renderGpu()
{
	float *d_fishes;
	cudaMalloc((void**)&d_fishes, 5 * LEN * LEN * sizeof(float));
	cudaMemcpy(d_fishes, arrayOfFishes, LEN * LEN * 5 * sizeof(float), cudaMemcpyHostToDevice);
	cudaDeviceSynchronize();
	updateShoalGpu << <1024, 1024 >> > (d_fishes);
	cudaDeviceSynchronize();
	cudaMemcpy(arrayOfFishes, d_fishes, LEN * LEN * 5 * sizeof(float), cudaMemcpyDeviceToHost);

}

void render()
{	//while(true) {
	glClearColor(64.0 / 255.0, 164.0 / 255.0, 223.0 / 225.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	//const clock_t begin_time = clock();
	//while (clock() - begin_time < 10);
	
	renderGpu();
	//updateShoal();
	renderShoal();
	glutSwapBuffers();
	glutPostRedisplay();
	//}
}



int main(int argc, char* argv[])
{
	// Initialize GLUTx
	glutInit(&argc, argv);
	// Set up some memory buffers for our display
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_DEPTH);
	// Set the window size
	glutInitWindowSize(1000, 800);
	// Create the window with the title "Hello,GL"
	glutCreateWindow("Shoal");
	defineFishes();
	// Bind the two functions (above) to respond when necessary
	glutReshapeFunc(changeViewPort);
	glutDisplayFunc(render);
	glutMainLoop();
	//glutMainLoop();

	// Very important!  This initializes the entry points in the OpenGL driver so we can 
	// call all the functions in the API.
	GLenum err = glewInit();
	if (GLEW_OK != err) {
		fprintf(stderr, "GLEW error");
		return 1;
	}

	return 0;
}