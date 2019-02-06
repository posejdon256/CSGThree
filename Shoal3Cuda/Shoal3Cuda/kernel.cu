
#pragma region Includes

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
#include <utility>  

#pragma comment(lib, "glew32.lib")
#include <iostream>
#include <ctime>
#include <Windows.h>
#include<device_launch_parameters.h>
#include <algorithm>
#pragma endregion
using namespace std;
#define LEN 1000

#pragma region Structures
struct Position {
	float x;
	float y;
	float z;
};
struct Color {
	int r;
	int g;
	int b;
	int a;
};
struct Sphere
{
	int r;
	Position position;
	Color color;
};
enum Operation
{
	Sum = 0,
	Mul = 1,
	Diff = 2,
	None = 3
};
struct Line {
	Sphere* in;
	Position* inPosition;
	Sphere* out;
	Position* outPosition;

};
struct Node {
	Operation operation;
	Sphere* sphere;
	Node* left = NULL;
	Node* right = NULL;
	Node* parent = NULL;
	vector<Line*> lines;
};
Node * root;
unsigned char *data;
#pragma endregion
#pragma region CUDA

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
#pragma endregion
#pragma region  Helpers
Position* crossMultiply(Position* v1, Position* v2) {
	// [ a2 * b3 - a3 * b2, a3 * b1 - a1 * b3, a1 * b2 - a2 * b1 ]
	Position* newP = new Position();
	newP->x = v1->y * v2->z - v1->z * v2->y;
	newP->y = v1->z * v2->x - v1->x * v2->z;
	newP->z = v1->x * v2->y - v1->y * v2->x;
	return newP;
}
float dotMultiply(Position* v1, Position* v2) {
	return v1->x * v2->x + v1->y * v2->y + v1->z * v2->z;
}
unsigned char* prepareData() {
	unsigned char *data = new unsigned char[LEN * LEN * 4];
	for (int i = 0; i < LEN * LEN * 4; i++) {
		data[i] = 0;
	}

	return data;
}
Position* DiffPoints(Position* p1, Position* p2) {
	Position* p3 = new Position();
	p3->x = p1->x - p2->x;
	p3->y = p1->y - p2->y;
	p3->z = p1->z - p2->z;
	return p3;
}
Position* DividePoint(Position* p, float a) {
	Position* newP = new Position();
	newP->x = p->x / a;
	newP->y = p->y / a;
	newP->z = p->z / a;
	return newP;
}
Position* SumPoints(Position* p1, Position* p2) {
	Position* newP = new Position();
	newP->x = p1->x + p2->x;
	newP->y = p1->y + p2->y;
	newP->z = p1->z + p2->z;
	return newP;
}
Position* MulPoints(Position* p, float a) {
	Position* newP = new Position();
	newP->x = p->x * a;
	newP->y = p->y * a;
	newP->z = p->z *a;
	return newP;
}
float lengthBetweenTwoPoints(Position* p1, Position* p2) {
	return sqrt(pow(p1->x - p2->x, 2) + pow(p1->x - p2->y, 2) + pow(p1->z - p2->z, 2));
}
float vectorLength(Position* p) {
	return sqrt(pow(p->x, 2) + pow(p->y, 2) + pow(p->z, 2));
}
void setInd(unsigned char *data, int i, int j, int value) {
	data[((i + 500) * LEN + (j + 500)) * 4] = value;
	data[((i + 500) * LEN + (j + 500)) * 4 + 1] = value;
	data[((i + 500) * LEN + (j + 500)) * 4 + 2] = value;
	data[((i + 500) * LEN + (j + 500)) * 4 + 3] = value;
}
#pragma endregion
#pragma region Logic operations
vector<Line*> MulOperation(vector<Line*> lines1, vector<Line*> lines2) {
}
vector<Line*> SumOperation(vector<Line*> lines1, vector<Line*> lines2) {
	vector<Line*> ret;
	Line* last = lines1[lines1.size() - 1] < lines2[lines2.size() - 1] ? lines2[lines2.size() - 1] : lines1[lines1.size() - 1];
	while (ret.size() == 0 || ret[ret.size() - 1] != last) {

	}
}
vector<Line*> DiffOperation(vector<Line*> lines, vector<Line*> line3) {

}
#pragma endregion
#pragma region Engine
Line* countLine(Sphere* sphere, Position* camera) {
	Position* l = DiffPoints(&sphere->position, camera);
	Line* ret = new Line();
	l = DividePoint(l, vectorLength(l));
	Position* cameraToCenter = DiffPoints(camera, &sphere->position);
	float a = dotMultiply(l, l);
	float b = 2 * dotMultiply(l, cameraToCenter);
	float c = dotMultiply(cameraToCenter, cameraToCenter) - pow(sphere->r, 2);
	if (pow(b, 2) < 4 * a * c) {
		return NULL;
	}
	float d1 = (-b + sqrt(pow(b, 2) - 4 * a * c)) / (2 * a);
	float d2 = (-b - sqrt(pow(b, 2) - 4 * a * c)) / (2 * a);
	ret->in = sphere;
	ret->out = sphere;
	ret->inPosition = d1 < d2 ? SumPoints(MulPoints(l, d1), camera) : SumPoints(MulPoints(l, d2), camera);
	ret->outPosition = d1 < d2 ? SumPoints(MulPoints(l, d2), camera) : SumPoints(MulPoints(l, d1), camera);
	return ret;
}
void DrawElement(Node* node, unsigned char *data, Position* camera) {
	if (node->left != NULL) {
		DrawElement(node->left, data, camera);
	}
	if (node->right != NULL) {
		DrawElement(node->right, data, camera);
	}
	for (int i = 0; i < LEN; i++) {
		for (int j = 0; j < LEN; j++) {
			Position* place = new Position();
			if (node->sphere != NULL) {
				Line* sphereLine = countLine(node->sphere, camera);
				if (sphereLine != NULL) {
					node->lines.push_back(sphereLine);
				}
				else {
					node->left->lines.insert(node->left->lines.end(), node->right->lines.begin(), node->right->lines.end());
					node->lines = node->left->lines;
				}
			}
		}
	}
	if (node->parent == NULL) {
		for (int i = 0; i < LEN; i++) {
			for (int j = 0; j < LEN; j++) {
				setInd(data, i, j no)
			}
		}
	}
	glDrawPixels(LEN, LEN, GL_RGBA, GL_UNSIGNED_BYTE, data);
}
#pragma endregion
#pragma region THREE


Sphere* setSpherePosition(Sphere* sphere, int x, int y, int z) {
	sphere->position.x = x;
	sphere->position.y = y;
	sphere->position.z = z;
	return sphere;
}
Sphere* setSphereColor(Sphere* sphere, int r, int g, int b, int a) {
	sphere->color.r = r;
	sphere->color.g = g;
	sphere->color.b = b;
	sphere->color.a = a;
	return sphere;
}
void CreateRoot() {
	root = new Node();
	root->operation = Sum;

	Sphere* sphere1 = new Sphere();
	sphere1->r = 200;
	sphere1 = setSpherePosition(sphere1, 100, 100, 0);
	sphere1 = setSphereColor(sphere1, 255, 0, 255, 255);

	Sphere* sphere3 = new Sphere();
	sphere3->r = 100;
	sphere3 = setSpherePosition(sphere3, -50, -50, 0);
	sphere3 = setSphereColor(sphere3, 0, 255, 0, 255);

	Sphere* sphere2 = new Sphere();
	sphere2->r = 100;
	sphere2 = setSpherePosition(sphere2, -120, -120, 0);
	sphere2 = setSphereColor(sphere2, 0, 0, 255, 255);

	Sphere* sphere4 = new Sphere();
	sphere4->r = 50;
	sphere4 = setSpherePosition(sphere4, 50, -50, 0);
	sphere4 = setSphereColor(sphere4, 100, 100, 100, 255);

	Node* left1 = new Node();
	left1->operation = Diff;
	left1->parent = root;

	Node* right2 = new Node();
	right2->operation = None;
	right2->sphere = sphere2;
	right2->parent = left1;

	Node* left2 = new Node();
	left2->operation = Sum;
	left2->parent = left1;

	left1->right = right2;
	left1->left = left2;

	Node* right3 = new Node();
	right3->operation = None;
	right3->sphere = sphere4;
	right3->parent = left2;

	Node* left3 = new Node();
	left3->operation = None;
	left3->sphere = sphere3;
	left3->parent = left2;

	left2->left = left3;
	left2->right = right3;

	Node* right = new Node();
	right->sphere = sphere1;
	right->operation = None;
	right->parent = root;
	root->right = right;
	root->left = left1;
}
#pragma endregion
#pragma region Render
void renderCpu() {
}
void renderGpu()
{
}
void render()
{
	Position* camera = new Position();
	camera->x = 0;
	camera->y = 0;
	camera->z = 200;
	glClearColor(0.0 / 255.0, 0.0 / 255.0, 0.0 / 225.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	DrawElement(root, prepareData(), camera);


	renderGpu();
	renderCpu();
	glutSwapBuffers();
	//glutPostRedisplay();
}
#pragma endregion
int main(int argc, char* argv[])
{
	// Initialize GLUTx
	glutInit(&argc, argv);
	// Set up some memory buffers for our display
	glutInitDisplayMode(GLUT_RGBA | GLUT_DOUBLE);
	// Set the window size
	glutInitWindowSize(LEN, LEN);
	// Create the window with the title "Hello,GL"
	glutCreateWindow("CSGThree");
	CreateRoot();
	glutDisplayFunc(render);
	glutMainLoop();

	GLenum err = glewInit();
	if (GLEW_OK != err) {
		fprintf(stderr, "GLEW error");
		return 1;
	}

	return 0;
}