//Jeff Chastine
#include <Windows.h>
#include <GL\glew.h>
#include <GL\freeglut.h>
#include <iostream>
#include "Fish.h"
#include <ctime>

using namespace std;

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
	float scale = 0.03;
	int  numberOfFishesInRow = 10;
	fish* fishes = getArrayOfFishes();
	for (int i = 0; i < numberOfFishesInRow * numberOfFishesInRow; i++) {

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
	glFlush();
}

void render()
{	for (int i = 0; i < 1000; i++) {
		glClearColor(64.0 / 255.0, 164.0 / 255.0, 223.0 / 225.0, 1.0);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		const clock_t begin_time = clock();
		while (clock() - begin_time < 10);

		updateShoal();
		renderShoal();
		glutSwapBuffers();
	}
}


int main(int argc, char* argv[]) {

	// Initialize GLUT
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

	// Very important!  This initializes the entry points in the OpenGL driver so we can 
	// call all the functions in the API.
	GLenum err = glewInit();
	if (GLEW_OK != err) {
		fprintf(stderr, "GLEW error");
		return 1;
	}


	glutMainLoop();
	return 0;
}