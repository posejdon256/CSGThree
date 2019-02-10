
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
#define LEN 500

unsigned char ddata[LEN * LEN * 4];
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
	float position[3];
	int color[4];
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
	float inPosition;
	Sphere* out;
	float outPosition;

};
struct Node {
	Operation operation;
	Sphere* sphere;
	Node* left = NULL;
	Node* right = NULL;
	Node* parent = NULL;
	Line* lines;
};
Node* root;
Sphere** spheres = new Sphere*[4];
Node** nodes = new Node*[7];
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
__device__ __host__
float dotMultiply(Position v1, Position v2) {
	return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z;
}
__device__ __host__
Position DiffPoints(Position p1, Position p2) {
	Position p3 = Position();
	p3.x = p1.x - p2.x;
	p3.y = p1.y - p2.y;
	p3.z = p1.z - p2.z;
	return p3;
}
__device__ __host__
Position DividePoint(Position p, float a) {
	Position newP = Position();
	newP.x = p.x / a;
	newP.y = p.y / a;
	newP.z = p.z / a;
	return newP;
}
__device__ __host__
Position SumPoints(Position p1, Position p2) {
	Position newP = Position();
	newP.x = p1.x + p2.x;
	newP.y = p1.y + p2.y;
	newP.z = p1.z + p2.z;
	return newP;
}
__device__ __host__
Position MulPoints(Position p, float a) {
	Position newP = Position();
	newP.x = p.x * a;
	newP.y = p.y * a;
	newP.z = p.z *a;
	return newP;
}
float lengthBetweenTwoPoints(Position* p1, Position* p2) {
	return sqrt(pow(p1->x - p2->x, 2) + pow(p1->x - p2->y, 2) + pow(p1->z - p2->z, 2));
}
__device__ __host__
float vectorLength(Position p) {
	return sqrt(p.x * p.x + p.y * p.y + p.z * p.z);
}
#pragma endregion
#pragma region Logic operations
vector<Line*> MulOperation(vector<Line*> lines1, vector<Line*> lines2) {
	vector<Line*> ret;
	return ret;
}
vector<Line*> SumOperation(vector<Line*> lines1, vector<Line*> lines2) {
	vector<Line*> ret;
	Line* last = lines1[lines1.size() - 1] < lines2[lines2.size() - 1] ? lines2[lines2.size() - 1] : lines1[lines1.size() - 1];
	while (ret.size() == 0 || ret[ret.size() - 1] != last) {

	}
	return ret;
}
vector<Line*> DiffOperation(vector<Line*> lines, vector<Line*> line3) {
	vector<Line*> ret;
	return ret;
}
#pragma endregion
#pragma region Engine

__device__
void testUpdate(int i, unsigned char* d_data, int value, int* color) {
	d_data[i * 4] = color[0] * value;
	d_data[i * 4 + 1] = color[1] * value;
	d_data[i * 4 + 2] = color[2] * value;
	d_data[i * 4 + 3] = 255;
}
__host__ __device__
Line countLine(Sphere* sphere, Position* camera, int x, int y, int z) {
	Position place = Position();
	place.x = x;
	place.y = y;
	place.z = z;

	Position spherePosition = Position();
	spherePosition.x = sphere->position[0];
	spherePosition.y = sphere->position[1];
	spherePosition.z = sphere->position[2];

	Position v = DividePoint(DiffPoints(place, *camera), vectorLength(DiffPoints(place, *camera)));
	Position dv = DiffPoints(*camera, spherePosition);
	float a = dotMultiply(v, v);
	float b = 2 * dotMultiply(v, dv);
	float c = dotMultiply(dv, dv) - sphere->r * sphere->r;

	Line ret = Line();
	ret.in = sphere;
	ret.out = sphere;
	//Range result = { false, 0,0, sphere_id };

	float delta = b * b - 4 * a*c;

	if (delta < 0) {
		ret.inPosition = 0;
		return ret;
	}
	else {
		if (delta == 0)
		{
			float t = -b / (2 * a);
			ret.inPosition = t;
			ret.outPosition = t;
		}
		else
		{
			float sdelta = sqrt(delta);
			float t1 = (-b + sdelta) / (2 * a);
			float t2 = (-b - sdelta) / (2 * a);
			if (t1 < t2)
			{
				ret.inPosition = t1;
				ret.outPosition = t2;
			}
			else
			{
				ret.inPosition = t2;
				ret.outPosition = t1;
			}
		}
	}
	return ret;

}
__host__ __device__
void concatTwoNodes(Node* ret, int i) {
	Node* left = ret->left;
	Node* right = ret->right;
	if (left->lines[i * 8].inPosition != 0) {
		ret->lines[i * 8] = left->lines[i * 8];
		//ret->lines[i * 8].inPosition = 255;
	}
	else {
		ret->lines[i * 8] = right->lines[i * 8];
		//ret->lines[i * 8].inPosition = 255;
	}
}
__device__
void DrawElement(Node* node, Position* camera, unsigned char *d_data, int i) {
	if (node->left != NULL) {
		DrawElement(node->left, camera, d_data, i);
	}
	if (node->right != NULL) {
		DrawElement(node->right, camera, d_data, i);
	}
	if (node->sphere == NULL) {
		concatTwoNodes(node, i);
	}
	else {
		int y = i;
		while (y >= LEN) y -= LEN;
		Line sphereLine = countLine(node->sphere, camera, (int)(i / LEN), i % LEN, 0);
		node->lines[i * 8] = sphereLine;
	}
	if (node->parent == NULL) {
		testUpdate(i, d_data, (int)node->lines[i * 8].inPosition < 0 ? 0 : (int)node->lines[i * 8].inPosition, node->lines[i * 8].in->color);
	}
}
#pragma endregion
#pragma region THREE

__host__
Sphere* setSpherePosition(Sphere* sphere, int x, int y, int z) {
	sphere->position[0] = x;
	sphere->position[1] = y;
	sphere->position[2] = z;
	return sphere;
}
__host__
Sphere* setSphereColor(Sphere* sphere, int r, int g, int b, int a) {
	sphere->color[0] = r;
	sphere->color[1] = g;
	sphere->color[2] = b;
	sphere->color[3] = a;
	return sphere;
}
__host__
void CreateRoot() {
	cudaMallocManaged((void **)&root, sizeof(Node*));
	//new Line*[LEN * LEN]
	cudaMallocManaged((void **)&root->lines, sizeof(Line) * LEN * LEN * 8);
	root->parent = NULL;
	root->operation = Sum;

	Sphere* sphere1;
	cudaMallocManaged((void **)&sphere1, sizeof(Sphere*));
	sphere1->r = 50;
	sphere1 = setSpherePosition(sphere1, 100, 100, 0);
	sphere1 = setSphereColor(sphere1, 255, 0, 255, 255);

	Sphere* sphere3;
	cudaMallocManaged((void **)&sphere3, sizeof(Sphere*));
	sphere3->r = 70;
	sphere3 = setSpherePosition(sphere3, 150, 150, 0);
	sphere3 = setSphereColor(sphere3, 0, 255, 0, 255);

	Sphere* sphere2;
	cudaMallocManaged((void **)&sphere2, sizeof(Sphere*));
	sphere2->r = 100;
	sphere2 = setSpherePosition(sphere2, 170, 140, 0);
	sphere2 = setSphereColor(sphere2, 0, 0, 255, 255);

	Sphere* sphere4;
	cudaMallocManaged((void **)&sphere4, sizeof(Sphere*));
	sphere4->r = 50;
	sphere4 = setSpherePosition(sphere4, 600, 600, 0);
	sphere4 = setSphereColor(sphere4, 255, 0, 0, 255);

	Node* left1;
	cudaMallocManaged((void **)&left1, sizeof(Node*));
	cudaMallocManaged((void **)&left1->lines, sizeof(Line) * LEN * LEN * 8);
	left1->operation = Diff;
	left1->parent = root;

	Node* right2;
	cudaMallocManaged((void **)&right2, sizeof(Node*));
	cudaMallocManaged((void **)&right2->lines, sizeof(Line) * LEN * LEN * 8);
	right2->operation = None;
	right2->sphere = sphere2;
	right2->parent = left1;

	Node* left2;
	cudaMallocManaged((void **)&left2, sizeof(Node*));
	cudaMallocManaged((void **)&left2->lines, sizeof(Line) * 8 * LEN * LEN);
	left2->operation = Sum;
	left2->parent = left1;

	left1->right = right2;
	left1->left = left2;

	Node* right3;
	cudaMallocManaged((void **)&right3, sizeof(Node*));
	cudaMallocManaged((void **)&right3->lines, sizeof(Line) * 8 * LEN * LEN);
	right3->operation = None;
	right3->sphere = sphere4;
	right3->parent = left2;

	Node* left3;
	cudaMallocManaged((void **)&left3, sizeof(Node*));
	cudaMallocManaged((void **)&left3->lines, sizeof(Line)* 8 * LEN * LEN);
	left3->operation = None;
	left3->sphere = sphere3;
	left3->parent = left2;

	left2->left = left3;
	left2->right = right3;

	Node* right;
	cudaMallocManaged((void **)&right, sizeof(Node*));
	cudaMallocManaged((void **)&right->lines, sizeof(Line) * 8 * LEN * LEN);
	right->sphere = sphere1;
	right->operation = None;
	right->parent = root;

	root->right = right;
	root->left = left1;
}
#pragma endregion
#pragma region Render
__global__
void drawElements(unsigned char *d_data, Node* root, Position* camera) {

	const long numThreads = blockDim.x * gridDim.x;
	const long threadID = (blockIdx.x * blockDim.x + threadIdx.x);

	int i = threadID % (LEN * LEN);
	DrawElement(root, camera, d_data, i);

}
void renderGpu()
{
	unsigned char *d_data;

	Position* camera;
	cudaMallocManaged((void**)&camera, sizeof(Position*));
	camera->x = 0;
	camera->y = 0;
	camera->z = 1000;

	cudaMalloc((void**)&d_data, LEN * LEN * 4 * sizeof(unsigned char));
	cudaDeviceSynchronize();
	drawElements << < 1024, 1024 >> > (d_data, root, camera);
	cudaDeviceSynchronize();
	cudaMemcpy(ddata, d_data, LEN * LEN * 4 * sizeof(unsigned char), cudaMemcpyDeviceToHost);
	cudaFree(d_data);

	glDrawPixels(LEN, LEN, GL_RGBA, GL_UNSIGNED_BYTE, ddata);

}
void render()
{
	glClearColor(0.0 / 255.0, 0.0 / 255.0, 0.0 / 225.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	renderGpu();
	//renderCpu();
	glutSwapBuffers();
	glutPostRedisplay();

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