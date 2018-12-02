

#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include "device_functions.h"

#include <string>
#include <cstdio>
#include <vector>
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

#define LEN 10

struct  fish
{
	int id;
	float dirX;
	float dirY;
	float x;
	float y;
};

fish arrayOfFishes[LEN * LEN];

using namespace std;

float getAngle(float x1, float y1, float x2, float y2) {
	float value = x1 * x2 + y1 * y2;
	value = value != 0 ? value / sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2)) : 0;
	return 180 - atan2(-y1, x1) * 57.0;
}
float vectorMultiply(float x1, float y1, float x2, float y2) {
	float value = x1 * x2 + y1 * y2;
	value = value != 0 ? value / sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2)) : 0;
	return value;
}
float getVectorLength(float x1, float y1, float x2, float y2) {
	return sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2));
}

void defineFishes() {
	int numberOfFishesInRow = LEN;
	for (int i = 0; i < numberOfFishesInRow; i++) {
		for (int j = 0; j < numberOfFishesInRow; j++) {
			fish f;
			f.id = i * numberOfFishesInRow + j;
			f.dirX = -1.0;
			f.dirY = 0.0;
			f.x = 0.9 + i * -0.1;
			f.y = 0.9 + j * -0.1;

			arrayOfFishes[i * numberOfFishesInRow + j] = f;
		}
	}
}
fish* getArrayOfFishes() {
	return arrayOfFishes;
}

void updateInNeighborhoud(int x, int y) {
	float nei = 0.2;
	float neiClose = 0.1;
	vector<fish> friends;
	vector<fish> toClose;
	fish current = arrayOfFishes[x * LEN + y];
	for (int i = 0; i < LEN; i++) {
		for (int j = 0; j < LEN; j++) {
			fish sFish = arrayOfFishes[i * LEN + j];
			if (getVectorLength(sFish.x, sFish.y, current.x, current.y) < nei
				&& current.id != sFish.id
				&& vectorMultiply(sFish.x - current.x, sFish.y - current.y, current.dirX, current.dirY) > 0) {
				friends.push_back(sFish);
			}
			if (getVectorLength(sFish.x, sFish.y, current.x, current.y) < neiClose
				&& current.id != sFish.id
				&& vectorMultiply(sFish.x - current.x, sFish.y - current.y, current.dirX, current.dirY) > 0) {
				toClose.push_back(sFish);
			}
		}
	}
	float dirXNew = 0.0;
	float posNewX = 0.0;
	float posNewY = 0.0;
	float dirYNew = 0.0;
	float awayFromX = 0.0;
	float awayFromY = 0.0;
	for (int i = 0; i < friends.size(); i++) {
		dirXNew += friends[i].dirX;
		dirYNew += friends[i].dirY;

		posNewX += friends[i].x;
		posNewY += friends[i].y;

	}
	for (int i = 0; i < toClose.size(); i++) {
		awayFromX += (current.x - toClose[i].x);
		awayFromY += (current.y - toClose[i].y);
	}
	if (friends.size() == 0) {
		return;
	}
	if (toClose.size() == 0) {
		current.dirX += (dirXNew / (float)friends.size()) * 0.1;
		current.dirY += (dirYNew / (float)friends.size()) *0.1;
		current.dirX += (posNewX / (float)friends.size()) * 0.05;
		current.dirY += (posNewY / (float)friends.size()) * 0.05;
	}
	else {
		current.dirX += (awayFromX / (float)friends.size()) * 5;
		current.dirY += (awayFromY / (float)friends.size()) * 5;
	}
	float vecLen = sqrt(pow(current.dirX, 2) + pow(current.dirY, 2));
	current.dirX = current.dirX / vecLen;
	current.dirY = current.dirY / vecLen;
	/*if (toClose.size() != 0) {
		current.x += current.dirX * 0.005;
		current.y += current.dirY * 0.005;
	}*/
	arrayOfFishes[x * LEN + y] = current;
}

void updateShoal() {
	for (int i = 0; i < LEN * LEN; i++) {
		if (arrayOfFishes[i].x <= -0.9 && arrayOfFishes[i].dirX < 0) {
			arrayOfFishes[i].dirX = -arrayOfFishes[i].dirX;
			arrayOfFishes[i].x += arrayOfFishes[i].dirX * 0.01;
			arrayOfFishes[i].y += arrayOfFishes[i].dirY * 0.01;
			//arrayOfFishes[i].dirY = 1.0;
		}
		if (arrayOfFishes[i].x >= 0.9 && arrayOfFishes[i].dirX > 0) {
			arrayOfFishes[i].dirX = -arrayOfFishes[i].dirX;
			arrayOfFishes[i].x += arrayOfFishes[i].dirX * 0.01;
			arrayOfFishes[i].y += arrayOfFishes[i].dirY * 0.01;
			//arrayOfFishes[i].dirY = -1.0;
		}
		if (arrayOfFishes[i].y <= -0.9 && arrayOfFishes[i].dirY < 0) {
			//arrayOfFishes[i].dirX = -1.0;
			arrayOfFishes[i].dirY = -arrayOfFishes[i].dirY;
			arrayOfFishes[i].x += arrayOfFishes[i].dirX * 0.01;
			arrayOfFishes[i].y += arrayOfFishes[i].dirY * 0.01;
		}
		if (arrayOfFishes[i].y >= 0.9 && arrayOfFishes[i].dirY > 0) {
			//arrayOfFishes[i].dirX = 1.0;
			arrayOfFishes[i].dirY = -arrayOfFishes[i].dirY;
			arrayOfFishes[i].x += arrayOfFishes[i].dirX * 0.01;
			arrayOfFishes[i].y += arrayOfFishes[i].dirY * 0.01;
		}
		arrayOfFishes[i].x += arrayOfFishes[i].dirX * 0.005;
		arrayOfFishes[i].y += arrayOfFishes[i].dirY * 0.005;
	}
	for (int i = 0; i < LEN; i++) {
		for (int j = 0; j < LEN; j++) {
			int place = i * LEN + j;
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
	int  numberOfFishesInRow = 10;
	fish* fishes = getArrayOfFishes();
	for (int i = 0; i < 100; i++) {

		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glTranslatef(fishes[i].x, fishes[i].y, 0.0);
		float angle = getAngle(fishes[i].dirX, fishes[i].dirY, 1, 0);
		glRotatef(angle, 0, 0, 1);
		glScalef(scale, scale, scale);

		glBegin(GL_POLYGON);
		renderTriangle();
		glEnd();
	}
	//glFlush();
}//

void render()
{	//while(true) {
	glClearColor(64.0 / 255.0, 164.0 / 255.0, 223.0 / 225.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	//const clock_t begin_time = clock();
	//while (clock() - begin_time < 10);

	updateShoal();
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